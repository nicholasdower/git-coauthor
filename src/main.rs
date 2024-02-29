use clap::Parser;
use git2::{Error, Repository};
use std::collections::{HashMap, HashSet};

use std::process::Command;

const VERSION: &str = env!("CARGO_PKG_VERSION");

const SHORT_HELP: &str = "\
usage: git coauthor [-d] [<alias>...]

List, add or delete Git coauthors

Description

    Git coauthor manages \"Co-authored-by\" lines on the HEAD commit. Coauthors
    may be specified as name or email details from the repository's commit history
    or as aliases configured via Git config.

Options

    -d, --delete    Delete coauthors.
    -h, --help      Print help.
    -v, --version   Print version.

Configuration

    Optionally, coauthor aliases can be added to the Git config:

        git config --add coauthor.joe 'Joe Blow <foo@foo.com>'

    To remove a coauthor from the Git config:

        git config --unset coauthor.joe

Examples

    List coauthors on the HEAD commit:

        git coauthor

    Add coauthors to the HEAD commit:

        git coauthor Joe
        git coauthor Joe Jim
        git coauthor 'Joe Blow' 'Jim Bob'

    Delete coauthors from the HEAD commit:

        git coauthor -d Joe
        git coauthor -d Joe Jim
        git coauthor -d 'Joe Blow' 'Jim Bob'

    Delete all coauthors from the HEAD commit:

        git coauthor -d\
";

#[derive(Parser)]
#[command(disable_help_flag = true)]
struct Cli {
    aliases: Vec<String>,

    #[arg(short = 'h')]
    short_help: bool,

    #[arg(long = "help")]
    long_help: bool,

    #[arg(short, long)]
    version: bool,

    #[arg(short, long)]
    delete: bool,
}

struct CoauthorParts {
    name: String,
    name_parts: Vec<String>,
    email: String,
    email_local: String,
}

impl CoauthorParts {
    fn matches(&self, alias: &String) -> bool {
        self.name_parts.contains(alias)
            || self.name.eq(alias)
            || self.email_local.eq(alias)
            || self.email.eq(alias)
    }
}

fn main() {
    match run() {
        Ok(Some(output)) => println!("{}", output),
        Ok(None) => (),
        Err(e) => {
            eprintln!("error: {}", e);
            std::process::exit(1);
        }
    }
    std::process::exit(0);
}

fn run() -> Result<Option<String>, String> {
    let args = Cli::try_parse().map_err(|e| format!("{}\n{}", e.kind(), SHORT_HELP))?;
    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;

    let aliases = without_duplicates(
        args.aliases
            .iter()
            .map(|alias| alias.to_lowercase())
            .collect(),
    );

    if args.short_help {
        Ok(Some(SHORT_HELP.to_string()))
    } else if args.long_help {
        Command::new("man")
            .arg("git-coauthor")
            .status()
            .map_err(|_| "failed to execute man".to_string())?;
        Ok(None)
    } else if args.version {
        Ok(Some(format!("git-coauthor {}", VERSION)))
    } else if args.delete {
        let coauthors = delete_from_commit(&repo, aliases)?;
        if coauthors.is_empty() {
            Ok(Some("no coauthors".to_string()))
        } else {
            Ok(Some(coauthors.join("\n")))
        }
    } else if !args.aliases.is_empty() {
        let coauthors = add_to_commit(&repo, aliases)?.join("\n");
        Ok(Some(coauthors))
    } else {
        let coauthors = read_from_commit()?;
        if coauthors.is_empty() {
            Ok(Some("no coauthors".to_string()))
        } else {
            Ok(Some(coauthors.join("\n")))
        }
    }
}

fn get_config(repo: &Repository) -> Result<HashMap<String, String>, String> {
    let cfg = repo.config().unwrap();

    let entries = cfg
        .entries(Some("coauthor"))
        .map_err(|_| "failed to read git config".to_string())?;
    let mut config_map = HashMap::new();
    entries
        .for_each(|entry| {
            if let (Some(name), Some(value)) = (entry.name(), entry.value()) {
                if let Some(alias) = name.strip_prefix("coauthor.") {
                    config_map.insert(alias.to_string(), value.to_string());
                }
            }
        })
        .map_err(|_| "failed to read git config".to_string())?;

    Ok(config_map)
}

fn read_from_commit() -> Result<Vec<String>, String> {
    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let commit = head_commit(&repo)?;
    match commit.message() {
        Some(message) => {
            let coauthors: Vec<String> = message
                .lines()
                .filter(|line| line.starts_with("Co-authored-by:"))
                .map(|line| line.to_string())
                .collect();
            Ok(coauthors)
        }
        None => Err("failed to read commit message".to_string()),
    }
}

fn get_coauthors(repo: &Repository, aliases: &[String]) -> Result<Vec<String>, String> {
    let mut remaining_aliases = aliases.to_vec();
    let mut alias_to_coauthor = HashMap::new();

    get_coauthors_from_config(repo, &mut remaining_aliases, &mut alias_to_coauthor)?;
    if !remaining_aliases.is_empty() {
        get_coauthors_from_log(repo, &mut remaining_aliases, &mut alias_to_coauthor)
            .map_err(|_| "failed to read log".to_string())?;
    }

    match remaining_aliases.len() {
        0 => Ok(aliases
            .iter()
            .map(|alias| alias_to_coauthor.get(alias).unwrap().to_string())
            .collect()),
        1 => Err(format!("coauthor not found: {}", remaining_aliases[0])),
        _ => Err(format!(
            "coauthors not found: {}",
            remaining_aliases.join(",")
        )),
    }
}

fn get_coauthors_from_config(
    repo: &Repository,
    remaining_aliases: &mut Vec<String>,
    alias_to_coauthor: &mut HashMap<String, String>,
) -> Result<(), String> {
    let config = get_config(repo)?;
    remaining_aliases.retain(|alias| match config.get(alias) {
        Some(coauthor) => {
            alias_to_coauthor.insert(alias.clone(), format!("Co-authored-by: {}", coauthor));
            false
        }
        None => true,
    });
    Ok(())
}

fn get_coauthors_from_log(
    repo: &Repository,
    remaining_aliases: &mut Vec<String>,
    alias_to_coauthor: &mut HashMap<String, String>,
) -> Result<(), Error> {
    let mut revwalk = repo.revwalk()?;
    revwalk.push_head()?;
    revwalk.set_sorting(git2::Sort::TIME)?;

    for rev in revwalk {
        if remaining_aliases.is_empty() {
            break;
        };

        let commit = repo.find_commit(rev?)?;
        let signature = commit.author();
        let email = String::from_utf8_lossy(signature.email_bytes());
        let name = String::from_utf8_lossy(signature.name_bytes());
        let coauthor_parts = parse_name_and_email(&name, &email);
        if coauthor_parts.is_some() {
            let coauthor_parts = coauthor_parts.unwrap();
            remaining_aliases.retain(|alias| {
                let found = coauthor_parts.matches(alias);
                if found {
                    alias_to_coauthor.insert(
                        alias.clone(),
                        format!("Co-authored-by: {} <{}>", name, email),
                    );
                }

                !found
            });
        }

        let message = commit.message();
        if message.is_none() {
            continue;
        }

        let lines: Vec<&str> = message.unwrap().lines().collect();
        lines
            .iter()
            .filter(|&line| line.starts_with("Co-authored-by:"))
            .for_each(|line| {
                let coauthor_parts = parse_coauthor(&line[15..]);
                if coauthor_parts.is_some() {
                    let coauthor_parts = coauthor_parts.unwrap();
                    remaining_aliases.retain(|alias| {
                        let found = coauthor_parts.matches(alias);
                        if found {
                            alias_to_coauthor.insert(alias.clone(), line.to_string());
                        }

                        !found
                    });
                }
            });
    }
    Ok(())
}

fn add_to_commit(repo: &Repository, aliases: Vec<String>) -> Result<Vec<String>, String> {
    let coauthors = get_coauthors(repo, &aliases)?;

    let commit = head_commit(repo)?;
    let tree = commit
        .tree()
        .map_err(|_| "failed to find tree".to_string())?;

    let message: Result<&str, String> = match commit.message() {
        Some(message) => Ok(message),
        None => return Err("failed to read commit message".to_string()),
    };
    let mut lines: Vec<String> = message?.lines().map(|line| line.to_string()).collect();
    let mut existing: Vec<String> = lines
        .iter()
        .filter(|&line| line.starts_with("Co-authored-by:"))
        .map(|line| line.to_string())
        .collect();
    let new_coauthors: Vec<String> = coauthors
        .iter()
        .filter(|&coauthor| !existing.contains(coauthor))
        .map(|coauthor| coauthor.to_string())
        .collect();
    if (lines.len() == 1)
        || (lines.len() > 2 && !lines.last().unwrap().starts_with("Co-authored-by:"))
    {
        lines.push("".to_string());
    }
    lines.extend(new_coauthors.clone());
    existing.extend(new_coauthors);
    let new_message = format!("{}\n", lines.join("\n"));

    commit
        .amend(
            Some("HEAD"),
            None,
            None,
            None,
            Some(new_message.as_str()),
            Some(&tree),
        )
        .map_err(|_| "failed to amend commit".to_string())?;

    Ok(existing)
}

fn delete_from_commit(repo: &Repository, aliases: Vec<String>) -> Result<Vec<String>, String> {
    let coauthors = get_coauthors(repo, &aliases)?;

    let commit = head_commit(repo)?;
    let tree = commit
        .tree()
        .map_err(|_| "failed to find tree".to_string())?;

    if commit.message().is_none() {
        return Err("failed to read commit message".to_string());
    }
    let message: Result<&str, String> = match commit.message() {
        Some(message) => Ok(message),
        None => return Err("failed to read commit message".to_string()),
    };
    let mut lines: Vec<String> = message?.lines().map(|line| line.to_string()).collect();
    lines = lines
        .iter()
        .filter(|&line| {
            if aliases.is_empty() {
                !line.starts_with("Co-authored-by:")
            } else {
                !coauthors.contains(line)
            }
        })
        .map(|line| line.to_string())
        .collect();
    let new_coauthors: Vec<String> = lines
        .iter()
        .filter(|&line| line.starts_with("Co-authored-by:"))
        .map(|coauthor| coauthor.to_string())
        .collect();
    if lines.len() == 1 {
        lines.push("".to_string());
    }
    let new_message = format!("{}\n", lines.join("\n"));

    commit
        .amend(
            Some("HEAD"),
            None,
            None,
            None,
            Some(new_message.as_str()),
            Some(&tree),
        )
        .map_err(|_| "failed to amend commit".to_string())?;

    Ok(new_coauthors)
}

fn head_commit(repo: &Repository) -> Result<git2::Commit<'_>, String> {
    let head = repo.head().map_err(|_| "failed to find head".to_string())?;
    let commit = head
        .peel_to_commit()
        .map_err(|_| "failed to find commit".to_string())?;
    Ok(commit)
}

fn without_duplicates(vec: Vec<String>) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut result = Vec::new();
    for item in vec {
        if seen.insert(item.clone()) {
            result.push(item);
        }
    }
    result
}

fn parse_coauthor(input: &str) -> Option<CoauthorParts> {
    let parts: Vec<&str> = input.split('<').collect();
    if parts.len() != 2 {
        return None;
    }

    let name = parts[0].trim().to_string();
    let email = parts[1].trim_end_matches('>').to_string();
    parse_name_and_email(&name, &email)
}

fn parse_name_and_email(name: &str, email: &str) -> Option<CoauthorParts> {
    let name = name.to_lowercase();
    let email = email.to_lowercase();
    let name_parts = name
        .split_whitespace()
        .map(|s| s.to_lowercase().to_string())
        .collect();

    let email_parts: Vec<&str> = email.split('@').collect();
    if email_parts.len() != 2 {
        return None;
    }

    let email_local = email_parts[0].to_string();

    Some(CoauthorParts {
        name,
        name_parts,
        email,
        email_local,
    })
}

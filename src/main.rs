use clap::Parser;
use git2::Repository;
use std::collections::HashMap;

use std::process::Command;

const VERSION: &str = env!("CARGO_PKG_VERSION");

const SHORT_HELP: &str = "\
usage: git coauthor [-d] [<alias>...]

List, add or delete Git coauthors

Options

    -d, --delete    Delete coauthors.
    -h, --help      Print help.
    -v, --version   Print version.

Configuration

    Add a coauthor to the Git configuration:

        git config --add coauthor.foo 'Foo <foo@foo.com>'

    Remove a coauthor from the Git configuration:

        git config --unset coauthor.foo

Examples

    List coauthors on the HEAD commit:

        git coauthor

    Add coauthors to the HEAD commit:

        git coauthor foo bar

    Delete coauthors from the HEAD commit:

        git coauthor -d foo bar

    Delete all coauthors from the HEAD commit:

        git coauthor -d

Installation

    Install:

        brew install nicholasdower/tap/git-coauthor

    Uninstall:

        brew uninstall git-coauthor
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

fn main() {
    match run() {
        Ok(Some(output)) => println!("{}", output),
        Ok(None) => (),
        Err(e) => {
            eprintln!("error: {}", e);
            std::process::exit(1);
        },
    }
    std::process::exit(0);
}

fn run() -> Result<Option<String>, String> {
    let args = Cli::try_parse().map_err(|e| format!("{}\n{}", e.kind(), SHORT_HELP))?;

    if args.short_help {
        Ok(Some(SHORT_HELP.to_string()))
    } else if args.long_help {
        Command::new("man")
            .arg("git-coauthor")
            .status()
            .map_err(|_| "failed to execute man".to_string())?;
        return Ok(None); // todo
    } else if args.version {
        Ok(Some(format!("git-coauthor {}", VERSION)))
    } else if args.delete {
        let coauthors = delete_from_commit(args.aliases)?;
        if coauthors.is_empty() {
            Ok(Some("no coauthors".to_string()))
        } else {
            Ok(Some(coauthors.join("\n")))
        }
    } else if !args.aliases.is_empty() {
        let coauthors = add_to_commit(args.aliases)?.join("\n");
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

fn get_config() -> Result<HashMap<String, String>, String> {
    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let cfg = repo.config().unwrap();

    let entries = cfg.entries(Some("coauthor")).map_err(|_| "failed to read git config".to_string())?;
    let mut config_map = HashMap::new();
    entries.for_each(|entry| {
        if let (Some(name), Some(value)) = (entry.name(), entry.value()) {
            if let Some(alias) = name.strip_prefix("coauthor.") {
                config_map.insert(alias.to_string(), value.to_string());
            }
        }
    }).map_err(|_| "failed to read git config".to_string())?;

    Ok(config_map)
}

fn read_from_commit() -> Result<Vec<String>, String> {
    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let head = repo.head().map_err(|_| "failed to find head".to_string())?;
    let commit = head.peel_to_commit().map_err(|_| "failed to find commit".to_string())?;
    return match commit.message() {
        Some(message) => {
            let coauthors: Vec<String> = message
                .lines()
                .filter(|line| line.starts_with("Co-authored-by:"))
                .map(|line| line.to_string())
                .collect();
            Ok(coauthors)
        },
        None => Err("failed to read commit message".to_string()),
    };
}

fn get_coauthors(aliases: Vec<String>) -> Result<Vec<String>, String> {
    let config = get_config()?;
    let coauthors: Result<Vec<String>, String> = aliases.iter().map(|alias| {
        let coauthor = config.get(alias).ok_or("coauthor not found".to_string())?;
        Ok(format!("Co-authored-by: {}", coauthor))
    }).collect();

    coauthors
}

fn add_to_commit(aliases: Vec<String>) -> Result<Vec<String>, String> {
    let coauthors = get_coauthors(aliases.clone())?;

    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let head = repo.head().map_err(|_| "failed to find head".to_string())?;
    let commit = head.peel_to_commit().map_err(|_| "failed to find commit".to_string())?;
    let tree = commit.tree().map_err(|_| "failed to find tree".to_string())?;

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
    if lines.len() == 1 {
        lines.push("".to_string());
    }
    lines.extend(new_coauthors.clone());
    existing.extend(new_coauthors);
    let new_message = format!("{}\n", lines.join("\n"));

    commit.amend(
        Some("HEAD"),
        None,
        None,
        None,
        Some(new_message.as_str()),
        Some(&tree),
    ).map_err(|_| "failed to amend commit".to_string())?;

    Ok(existing)
}

fn delete_from_commit(aliases: Vec<String>) -> Result<Vec<String>, String> {
    let coauthors = get_coauthors(aliases.clone())?;

    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let head = repo.head().map_err(|_| "failed to find head".to_string())?;
    let commit = head.peel_to_commit().map_err(|_| "failed to find commit".to_string())?;
    let tree = commit.tree().map_err(|_| "failed to find tree".to_string())?;

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

    commit.amend(
        Some("HEAD"),
        None,
        None,
        None,
        Some(new_message.as_str()),
        Some(&tree),
    ).map_err(|_| "failed to amend commit".to_string())?;

    Ok(new_coauthors)
}
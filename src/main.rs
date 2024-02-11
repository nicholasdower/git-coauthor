use clap::Parser;
use git2::{Commit, ObjectType, Repository};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
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

    Create a file like:

        foo = \"Foo <foo@baz.com>\"
        bar = \"Bar <bar@baz.com>\"

    Place the file in any of the following locations:

        <home>/.gitcoauthors
        <repo>/.gitcoauthors
        <repo>/.git/coauthors

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
    let output = run().unwrap_or_else(|e| {
        eprintln!("error: {}", e);
        std::process::exit(1);
    });
    if output.is_some() {
        println!("{}", output.unwrap());
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

fn get_config_for(path: &Path) -> Result<HashMap<String, String>, String> {
    let file = match std::fs::read_to_string(path) {
        Ok(file) => toml::from_str(file.as_str()),
        Err(_) => Ok(HashMap::new()),
    };
    file.map_err(|_| "failed to read configuration".to_string())
}

fn get_user_config() -> Result<HashMap<String, String>, String> {
    let home_dir: Option<PathBuf> = home::home_dir();
    if home_dir.is_some() {
        let mut user_path_buf = home_dir.unwrap();
        user_path_buf.push(Path::new(".gitcoauthors"));
        return get_config_for(user_path_buf.as_path());
    } else {
        Ok(HashMap::new())
    }
}

fn get_repo_config() -> Result<HashMap<String, String>, String> {
    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let mut path_buf = repo.path().to_path_buf();
    path_buf.push("..");
    path_buf.push(".gitcoauthors");
    return get_config_for(path_buf.as_path());
}

fn get_repo_git_config() -> Result<HashMap<String, String>, String> {
    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let mut path_buf = repo.path().to_path_buf();
    path_buf.push("coauthors");
    return get_config_for(path_buf.as_path());
}

fn get_config() -> Result<HashMap<String, String>, String> {
    let mut config = HashMap::new();
    config.extend(get_user_config()?);
    config.extend(get_repo_git_config()?);
    config.extend(get_repo_config()?);
    Ok(config)
}

fn get_commit(repo: &Repository) -> Result<Commit, git2::Error> {
    let obj = repo.head()?.resolve()?.peel(ObjectType::Commit)?;
    obj.into_commit()
        .map_err(|_| git2::Error::from_str("error: couldn't find commit"))
}

fn read_from_commit() -> Result<Vec<String>, String> {
    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let commit = get_commit(&repo).map_err(|_| "failed to get commit".to_string())?;
    if commit.message().is_none() {
        return Err("failed to read commit message".to_string());
    }
    let message = commit.message().unwrap();
    let coauthors: Vec<String> = message
        .lines()
        .filter(|line| line.starts_with("Co-authored-by:"))
        .map(|line| line.to_string())
        .collect();
    Ok(coauthors)
}

fn add_to_commit(aliases: Vec<String>) -> Result<Vec<String>, String> {
    let config = get_config()?;
    let contains_all_keys = aliases.iter().all(|key| config.contains_key(key));
    if !contains_all_keys {
        return Err("coauthor not found".to_string());
    }
    let coauthors: Vec<String> = aliases.iter().map(|alias| {
        let coauthor = config.get(alias).unwrap();
        format!("Co-authored-by: {}", coauthor)
    }).collect();

    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let head = repo.head().map_err(|_| "failed to find head".to_string())?;
    let commit = head.peel_to_commit().map_err(|_| "failed to find commit".to_string())?;
    let tree = commit.tree().map_err(|_| "failed to find tree".to_string())?;

    if commit.message().is_none() {
        return Err("failed to read commit message".to_string());
    }
    let message = commit.message().unwrap();
    let mut lines: Vec<String> = message.lines().map(|line| line.to_string()).collect();
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
    let config = get_config()?;
    let contains_all_keys = aliases.iter().all(|key| config.contains_key(key));
    if !contains_all_keys {
        return Err("coauthor not found".to_string());
    }
    let coauthors: Vec<String> = aliases.iter().map(|alias| {
        let coauthor = config.get(alias).unwrap();
        format!("Co-authored-by: {}", coauthor)
    }).collect();

    let repo = Repository::open_from_env().map_err(|_| "failed to find repository".to_string())?;
    let head = repo.head().map_err(|_| "failed to find head".to_string())?;
    let commit = head.peel_to_commit().map_err(|_| "failed to find commit".to_string())?;
    let tree = commit.tree().map_err(|_| "failed to find tree".to_string())?;

    if commit.message().is_none() {
        return Err("failed to read commit message".to_string());
    }
    let message = commit.message().unwrap();
    let mut lines: Vec<String> = message.lines().map(|line| line.to_string()).collect();
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
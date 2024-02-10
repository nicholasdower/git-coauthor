use clap::Parser;
use git2::{Commit, ObjectType, Repository};
use std::collections::HashMap;
use std::fs::File;
use std::path::{Path, PathBuf};
use std::{os::unix::process::ExitStatusExt, process::Command};

const VERSION: &str = env!("CARGO_PKG_VERSION");

const SHORT_HELP: &str = "\
usage: git coauthor [<alias>...]

List or add Git coauthors

Configuration

    Git coauthor is configured by creating a file like:

        <alias>: <name> <email>
        <alias>: <name> <email>

    The file can be placed in either or both of the following locations:

        <home>/.gitcoauthors
        <repo>/.git/coauthors
    
    If both files exist and contain the same alias, the alias in the repository file overrides the alias in the user file.

Examples

    Given a configuration file like:

        foo: Foo Foo <foo@foo.foo>
        bar: Bar Bar <bar@bar.bar>

    List coauthors on the HEAD commit:
    
        git coauthor

    Add a coauthor to the HEAD commit:

        git coauthor foo
    
    Add multiple coauthors to the HEAD commit:
    
        git coauthor foo bar

Install

    brew tap nicholasdower/formulas
    brew install git-coauthor

Uninstall

    brew uninstall git-coauthor
    brew untap nicholasdower/formulas
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
}

fn main() {
    let args = Cli::try_parse().unwrap_or_else(|e| parse_error(e));

    if args.short_help {
        short_help();
    } else if args.long_help {
        long_help();
    } else if args.version {
        version();
    } else if !args.aliases.is_empty() {
        add(args.aliases);
    } else {
        list();
    }
}

fn parse_error(error: clap::Error) -> ! {
    eprintln!("error: {}", error.kind());
    eprintln!("{}", SHORT_HELP);
    std::process::exit(1);
}

fn error(message: &str) -> ! {
    eprintln!("error: {}", message);
    std::process::exit(1);
}

fn short_help() {
    print!("{}", SHORT_HELP);
    std::process::exit(0);
}

fn long_help() {
    let status = Command::new("man")
        .arg("git-coauthor")
        .status()
        .unwrap_or_else(|_| error("failed to execute man"));
    std::process::exit(status.into_raw());
}

fn version() {
    println!("git-coauthor {}", VERSION);
    std::process::exit(0);
}

fn add(aliases: Vec<String>) {
    let config = get_config();
    let coauthors: Vec<String> = aliases.iter().map(|alias| {
        let coauthor = config.get(alias);
        let mut line = coauthor.unwrap_or_else(|| error("coauthor not found")).to_string();
        line = format!("Co-authored-by: {}", line);
        line
    }).collect();
    let new_coauthors = add_to_commit(coauthors);
    new_coauthors.iter().for_each(|line| println!("{}", line));
}

fn list() {
    let repo = Repository::open_from_env().unwrap_or_else(|_| error("failed to find repository"));
    let commit = get_commit(&repo).unwrap_or_else(|_| error("failed to get commit"));
    let message = commit
        .message()
        .unwrap_or_else(|| error("failed to get commit message"));
    let coauthors: Vec<&str> = message
        .lines()
        .filter(|line| line.starts_with("Co-authored-by:"))
        .collect();
    if coauthors.is_empty() {
        println!("no coauthors found");
    }
    coauthors.iter().for_each(|&line| println!("{}", line));
    std::process::exit(0);
}

fn get_config_for(path: &Path) -> HashMap<String, String> {
    let file = File::open(path);
    if file.is_err() {
        return HashMap::new();
    }
    let config: Result<HashMap<String, String>, serde_yaml::Error> =
        serde_yaml::from_reader(file.unwrap());
    config.unwrap_or_else(|_| error("failed to read configuration"))
}

fn get_user_config() -> HashMap<String, String> {
    let home_dir: Option<PathBuf> = home::home_dir();
    if home_dir.is_some() {
        let mut user_path_buf = home_dir.unwrap();
        user_path_buf.push(Path::new(".gitcoauthors"));
        return get_config_for(user_path_buf.as_path());
    } else {
        HashMap::new()
    }
}

fn get_repo_config() -> HashMap<String, String> {
    let repo = Repository::open_from_env().unwrap_or_else(|_| error("failed to find repository"));
    let mut path_buf = repo.path().to_path_buf();
    path_buf.push("coauthors");
    return get_config_for(path_buf.as_path());
}

fn get_config() -> HashMap<String, String> {
    let mut config = HashMap::new();
    config.extend(get_user_config());
    config.extend(get_repo_config());
    config
}

fn get_commit(repo: &Repository) -> Result<Commit, git2::Error> {
    let obj = repo.head()?.resolve()?.peel(ObjectType::Commit)?;
    obj.into_commit()
        .map_err(|_| git2::Error::from_str("error: couldn't find commit"))
}

fn add_to_commit(coauthors: Vec<String>) -> Vec<String> {
    let repo = Repository::open_from_env().unwrap_or_else(|_| error("failed to find repository"));
    let head = repo.head().unwrap_or_else(|_| error("failed to find head"));
    let commit = head.peel_to_commit().unwrap_or_else(|_| error("failed to find commit"));
    let tree = commit.tree().unwrap_or_else(|_| error("failed to find tree"));

    let message = commit.message().unwrap_or_else(|| error("failed to read commit message")).to_string();
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
    ).unwrap_or_else(|_| error("failed to amend commit"));

    existing
}

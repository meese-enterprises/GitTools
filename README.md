 [![GitHub stars](https://img.shields.io/github/stars/internetwache/GitTools.svg)](https://github.com/internetwache/GitTools/stargazers)
 [![GitHub license](https://img.shields.io/github/license/internetwache/GitTools.svg)](https://github.com/internetwache/GitTools/blob/master/LICENSE.md)


# GitTools

This repository contains three small python/bash scripts used for the Git research. [Read about it here](https://en.internetwache.org/dont-publicly-expose-git-or-how-we-downloaded-your-websites-sourcecode-an-analysis-of-alexas-1m-28-07-2015/).

## Finder

You can use this tool to find websites with their `.git` repository available to the public.

### Usage

This python script identifies websites with publicly accessible `.git` repositories.
It checks if the `.git/HEAD` file contains `refs/heads`.

```sh
$ ./gitfinder.py -h

###########
# Finder is part of https://github.com/internetwache/GitTools
#
# Developed and maintained by @gehaxelt from @internetwache
#
# Use at your own risk. Usage might be illegal in certain circumstances.
# Only for educational purposes!
###########

usage: gitfinder.py [-h] [-i INPUTFILE] [-o OUTPUTFILE] [-t THREADS]

optional arguments:
  -h, --help            show this help message and exit
  -i INPUTFILE, --inputfile INPUTFILE
                        input file
  -o OUTPUTFILE, --outputfile OUTPUTFILE
                        output file
  -t THREADS, --threads THREADS
                        threads
```

The input file should contain the targets one per line.
The script will output discovered domains in the form of `[*] Found: DOMAIN` to stdout.

#### Scanning Alexa’s Top 1M

```sh
wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
unzip top-1m.csv.zip
sed -i.bak 's/.*,//' top-1m.csv
./gitfinder.py -i top-1m.csv
```

## Dumper

This tool can be used to download as much as possible from the found .git repository from webservers which do not have directory listing enabled.

### Usage

```sh
bash gitdumper.sh http://target.tld/.git/ dest-dir [--git-dir=otherdir] [--user-agent="CustomUserAgent"]
```

### Options
- `--git-dir=otherdir`
  - Change the git folder name.
  - **Default:** `.git`
- `--user-agent="CustomUserAgent"`
  - Customize the User-Agent for HTTP requests.
  - **Default:** `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36`

### Default Behavior
If no `dest-dir` is provided, the script will create a `data` directory and within it a subdirectory named after the target domain.

**Example:**

```sh
bash gitdumper.sh http://example.com/.git/
```

This will create the following structure:

```
data/
└── example.com/
└── .git/
```

> **Note:** This tool has no 100% guarantee to completely recover the `.git` repository. Especially if the repository has been compressed into `pack`-files, it may fail.

## Extractor

A small bash script to extract commits and their content from a broken repository.

This script tries to recover incomplete git repositories:

- Iterate through all commit-objects of a repository
- Try to restore the contents of the commit
- Commits are *not* sorted by date

### Usage

```sh
./extractor.sh /path/to/gitrepo [dest-dir]
```

Where:

- `/path/to/gitrepo` contains a `.git` directory
- `dest-dir` is the destination directory (optional)

### Default Behavior

If no dest-dir is provided, the script will create a data directory and within it a subdirectory named after the target domain.

**Example:**

```sh
bash extractor.sh /path/to/gitrepo
```

This will create the following structure:

```
data/
└── gitrepo_domain/
    ├── 0-commit_hash/
    ├── 1-commit_hash/
    └── ...
```

> **Note:** This can be used in combination with the Git Dumper in case the downloaded repository is incomplete.

## Demo

Here's a small demo of the **Dumper** tool:

[![asciicast](https://asciinema.org/a/24072.png)](https://asciinema.org/a/24072)

## Proxy support

The `urllib` and `curl` should support proxy configuration through environment variables:

In Bash, set:

```sh
export HTTP_PROXY=http://proxy_url:proxy_port
export HTTPS_PROXY=http://proxy_url:proxy_port
```

In Windows CMD, use:

```sh
set HTTP_PROXY=http://proxy_url:proxy_port
set HTTPS_PROXY=http://proxy_url:proxy_port
```

Basic auth should be supported with:

```sh
http://username:password@proxy_url:proxy_port
```

## Requirements
* git
* Python 3+
* curl
* bash
* sed
* binutils (strings)

# License

All tools are licensed using the MIT license. See [LICENSE.md](LICENSE.md)

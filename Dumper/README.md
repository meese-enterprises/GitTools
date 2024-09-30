# GitDumper
=================

This is a tool for downloading `.git `repositories from webservers which do not have directory listing enabled.

## Requirements
- git
- curl
- bash
- sed

## Usage

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

### Example

```sh
bash gitdumper.sh http://example.com/.git/ /path/to/destination --user-agent="MyCustomAgent/1.0"
```

> **Note:**   This tool has no 100% guarantee to completely recover the `.git` repository. Especially if the repository has been compressed into `pack`-files, it may fail.

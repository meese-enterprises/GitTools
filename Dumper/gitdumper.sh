#!/bin/bash
#$1 : URL to download .git from (http://target.com/.git/)
#$2 : Folder where the .git-directory will be created (optional)
# Optional:
# --user-agent="CustomUserAgent"

DEFAULT_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
USER_AGENT="$DEFAULT_USER_AGENT"

function init_header() {
    cat <<EOF
###########
# GitDumper is part of https://github.com/meese-enterprises/GitTools
#
# Developed and maintained by @gehaxelt from @internetwache
#
# Use at your own risk. Usage might be illegal in certain circumstances.
# Only for educational purposes!
###########

EOF
}

function get_git_dir() {
    local FLAG="--git-dir="
    local ARGS=${@}

    for arg in $ARGS; do
        if [[ $arg == $FLAG* ]]; then
            echo "${arg#$FLAG}"
            return
        fi
    done

    echo ".git"
}

init_header

# Default positional arguments
BASEURL=""
BASEDIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --user-agent=*)
            USER_AGENT="${1#*=}"
            shift # past argument=value
            ;;
        --user-agent)
            USER_AGENT="$2"
            shift # past argument
            shift # past value
            ;;
        *)
        if [[ -z "$BASEURL" ]]; then
            BASEURL="$1"
        elif [[ -z "$BASEDIR" ]]; then
            BASEDIR="$1"
        else
            echo -e "\033[31m[-] Unknown argument: $1\033[0m"
            echo -e "\033[33m[*] USAGE: http://target.tld/.git/ [dest-dir] [--git-dir=otherdir] [--user-agent=\"CustomUserAgent\"]\033[0m"
            exit 1
        fi
        shift # past argument
        ;;
    esac
done

# Extract domain name from BASEURL
DOMAIN=$(echo "$BASEURL" | awk -F[/:] '{print $4}')

# Set default BASEDIR if not provided
if [[ -z "$BASEDIR" ]]; then
    BASEDIR="data/$DOMAIN"
fi

GITDIR=$(get_git_dir "$@")
BASEGITDIR="$BASEDIR/$GITDIR/"

if [ -z "$BASEURL" ]; then
    echo -e "\033[33m[*] USAGE: http://target.tld/.git/ [dest-dir] [--git-dir=otherdir] [--user-agent=\"CustomUserAgent\"]\033[0m"
    echo -e "\t\t--git-dir=otherdir\t\tChange the git folder name. Default: .git"
    echo -e "\t\t--user-agent=\"CustomUserAgent\"\tCustomize the User-Agent. Default: \"$DEFAULT_USER_AGENT\""
    exit 1
fi

if [[ ! "$BASEURL" =~ /$GITDIR/$ ]]; then
    echo -e "\033[31m[-] /$GITDIR/ missing in url\033[0m"
    exit 0
fi

if [ ! -d "$BASEGITDIR" ]; then
    echo -e "\033[33m[*] Destination folder does not exist\033[0m"
    echo -e "\033[32m[+] Creating $BASEGITDIR\033[0m"
    mkdir -p "$BASEGITDIR"
fi

function start_download() {
    # Add initial/static git files
    QUEUE+=('HEAD')
    QUEUE+=('objects/info/packs')
    QUEUE+=('description')
    QUEUE+=('config')
    QUEUE+=('COMMIT_EDITMSG')
    QUEUE+=('index')
    QUEUE+=('packed-refs')
    QUEUE+=('refs/heads/master')
    QUEUE+=('refs/heads/main')
    QUEUE+=('refs/remotes/origin/HEAD')
    QUEUE+=('refs/stash')
    QUEUE+=('logs/HEAD')
    QUEUE+=('logs/refs/heads/master')
    QUEUE+=('logs/refs/heads/main')
    QUEUE+=('logs/refs/remotes/origin/HEAD')
    QUEUE+=('info/refs')
    QUEUE+=('info/exclude')
    QUEUE+=('/refs/wip/index/refs/heads/master')
    QUEUE+=('/refs/wip/index/refs/heads/main')
    QUEUE+=('/refs/wip/wtree/refs/heads/master')
    QUEUE+=('/refs/wip/wtree/refs/heads/main')

    # Iterate through QUEUE until there are no more files to download
    while [ ${#QUEUE[*]} -gt 0 ]; do
        download_item "${QUEUE[0]}"
        # Remove item from QUEUE
        QUEUE=("${QUEUE[@]:1}")
    done
}

function download_item() {
    local objname="$1"
    local url="$BASEURL$objname"
    local hashes=()
    local packs=()

    # Check if file has already been downloaded
    if [[ " ${DOWNLOADED[@]} " =~ " ${objname} " ]]; then
        return
    fi

    local target="$BASEGITDIR$objname"

    # Create folder if necessary
    if dir=$(echo "$objname" | grep -oE "^(.*)/"); then
        mkdir -p "$BASEGITDIR/$dir"
    fi

    # Download file with customizable User-Agent
    curl -L -A "$USER_AGENT" -f -k -s "$url" -o "$target"

    # Mark as downloaded and remove it from the queue
    DOWNLOADED+=("$objname")
    if [ ! -f "$target" ]; then
        echo -e "\033[31m[-] Downloaded: $objname\033[0m"
        return
    fi
    echo -e "\033[32m[+] Downloaded: $objname\033[0m"

    # Check if we have an object hash
    if [[ "$objname" =~ ^objects/[0-9a-f]{2}/[0-9a-f]{38}$ ]]; then
        # Switch into $BASEDIR and save current working directory
        cwd=$(pwd)
        cd "$BASEDIR"

        # Restore hash from $objectname
        hash=$(echo "$objname" | sed -e 's~objects~~g' | sed -e 's~/~~g')

        # Check if it's a valid git object
        if ! type=$(git cat-file -t "$hash" 2> /dev/null); then
            # Delete invalid file
            cd "$cwd"
            rm "$target"
            return
        fi

        # Parse output of git cat-file -p $hash. Use strings for blobs
        if [[ "$type" != "blob" ]]; then
            hashes+=($(git cat-file -p "$hash" | grep -oE "([a-f0-9]{40})"))
        else
            hashes+=($(git cat-file -p "$hash" | strings -a | grep -oE "([a-f0-9]{40})"))
        fi

        cd "$cwd"
    fi

    # Parse file for other objects
    hashes+=($(strings -a "$target" | grep -oE "([a-f0-9]{40})"))
    for hash in ${hashes[*]}; do
        QUEUE+=("objects/${hash:0:2}/${hash:2}")
    done

    # Parse file for packs
    packs+=($(strings -a "$target" | grep -oE "(pack\-[a-f0-9]{40})"))
    for pack in ${packs[*]}; do
        QUEUE+=("objects/pack/$pack.pack")
        QUEUE+=("objects/pack/$pack.idx")
    done
}

start_download

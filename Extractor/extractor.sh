#!/bin/bash
#$1 : Folder containing .git directory to scan
#$2 : Folder to put files to (optional)

function init_header() {
    cat <<EOF
###########
# Extractor is part of https://github.com/meese-enterprises/GitTools
#
# Developed and maintained by @gehaxelt from @internetwache
#
# Use at your own risk. Usage might be illegal in certain circumstances.
# Only for educational purposes!
###########

EOF
}

init_header

# Check arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo -e "\e[33m[*] USAGE: extractor.sh GIT-DIR [DEST-DIR]\e[0m"
    exit 1
fi

GIT_DIR="$1"
DEST_DIR="$2"

# Remove trailing slash from GIT_DIR if present
GIT_DIR="${GIT_DIR%/}"

# Extract domain name from GIT_DIR path
DOMAIN=$(basename "$GIT_DIR")

# Set default DEST_DIR if not provided
if [ -z "$DEST_DIR" ]; then
    DEST_DIR="data/$DOMAIN"
fi

# Current directory, as we'll switch into others and need to restore it
OLDDIR=$(pwd)

# Check if DEST_DIR is an absolute path; if not, prepend the current directory
if [ "${DEST_DIR:0:1}" != "/" ]; then
    TARGETDIR="$OLDDIR/$DEST_DIR"
else
    TARGETDIR="$DEST_DIR"
fi

# Ensure the DEST_DIR exists
if [ ! -d "$TARGETDIR" ]; then
    echo -e "\e[33m[*] Destination folder does not exist\e[0m"
    echo -e "\e[32m[*] Creating $TARGETDIR\e[0m"
    mkdir -p "$TARGETDIR"
fi

if [ ! -d "$GIT_DIR/.git" ]; then
    echo -e "\e[31m[-] There's no .git folder\e[0m"
    exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
    echo -e "\e[33m[*] Destination folder does not exist\e[0m"
    echo -e "\e[32m[*] Creating $DEST_DIR\e[0m"
    mkdir -p "$DEST_DIR"
fi

function traverse_tree() {
    local tree=$1
    local path=$2

    # Read blobs/tree information from root tree
    git ls-tree $tree |
    while read leaf; do
        type=$(echo $leaf | awk -F' ' '{print $2}') #grep -oP "^\d+\s+\K\w{4}");
        hash=$(echo $leaf | awk -F' ' '{print $3}') #grep -oP "^\d+\s+\w{4}\s+\K\w{40}");
        name=$(echo $leaf | awk '{$1=$2=$3=""; print substr($0,4)}') #grep -oP "^\d+\s+\w{4}\s+\w{40}\s+\K.*");

        # Get the blob data
        # Ignore invalid git objects (e.g. ones that are missing)
        if ! git cat-file -e $hash; then
            continue;
        fi

        if [ "$type" = "blob" ]; then
            echo -e "\e[32m[+] Found file: $path/$name\e[0m"
            mkdir -p "$(dirname "$path/$name")"
            git cat-file -p $hash > "$path/$name"
        else
            echo -e "\e[32m[+] Found folder: $path/$name\e[0m"
            mkdir -p "$path/$name"
            # Recursively traverse sub trees
            traverse_tree $hash "$path/$name"
        fi

    done;
}

function traverse_commit() {
    local base=$1
    local commit=$2
    local count=$3

    # Create folder for commit data
    echo -e "\e[32m[+] Found commit: $commit\e[0m"
    path="$base/$count-$commit"
    mkdir -p "$path"
    # Add meta information
    git cat-file -p "$commit" > "$path/commit-meta.txt"
    # Try to extract contents of root tree
    traverse_tree $commit $path
}

# Current directory, as we'll switch into others and need to restore it
OLDDIR=$(pwd)
TARGETDIR=$DEST_DIR
COMMITCOUNT=0

# If we don't have an absolute path, add the prepend the CWD
if [ "${TARGETDIR:0:1}" != "/" ]; then
    TARGETDIR="$OLDDIR/$DEST_DIR"
fi

cd "$GIT_DIR"

# Extract all object hashes
find ".git/objects" -type f |
    sed -e "s/\///g" |
    sed -e "s/\.gitobjects//g" |
    while read object; do
        type=$(git cat-file -t $object)

        # Only analyze commit objects
        if [ "$type" = "commit" ]; then
            CURDIR=$(pwd)
            traverse_commit "$TARGETDIR" $object $COMMITCOUNT
            cd $CURDIR

            COMMITCOUNT=$((COMMITCOUNT + 1))
        fi
    done

cd $OLDDIR

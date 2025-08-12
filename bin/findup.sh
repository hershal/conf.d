#!/usr/bin/env bash

show_help() {
    cat >&2 <<EOF
Usage: $0 [OPTIONS] <filename-or-dirname> [<filename-or-dirname> ...]

findup.sh -- Search for one or more files or directories by name, starting from the current directory and moving up the directory tree.

OPTIONS:
  -h, --help      Show this help message and exit.
  -q, --quiet     Don't print anything, just return the exit code.

ARGUMENTS:
  <filename-or-dirname>   One or more file or directory names to search for. For each name, the script will look in the current directory and then in each parent directory up to the root.

EXIT STATUS:
  0   All targets were found.
  N   N targets were NOT found (where N is the number of missing targets).

EXAMPLES:
  $0 .git
      # Find the nearest .git directory or file upwards from the current directory.

  $0 -q Makefile README.md
      # Quietly search for Makefile and README.md upwards, returning the exit code whether all targets were found.

EOF
}

targets=()
quiet=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help && exit 0
            ;;
        -q|--quiet)
            quiet=1
            shift
            ;;
        *)
            targets+=("$1")
            shift
            ;;
    esac
done

if [[ ${#targets[@]} -eq 0 ]]; then
    show_help && exit 1
fi

status=0

for target in "${targets[@]}"; do
    dir="$PWD"
    found=0
    while true; do
        if [[ -e "$dir/$target" ]]; then
            if [[ $quiet -eq 0 ]]; then
                echo "$dir/$target"
            fi
            found=1
            break
        fi
        if [[ "$dir" == "/" ]]; then
            break
        fi
        dir="$(dirname "$dir")"
    done
    if [[ $found -eq 0 ]]; then
        ((status++))
    fi
done

exit $status

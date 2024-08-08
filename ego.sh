#!/usr/bin/env bash

dirname=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
config_dir="$HOME/.config/alterego"

egos_dir="$config_dir/egos"
selected_file="$config_dir/current"

if [ ! -d "$egos_dir" ]; then mkdir -p "$egos_dir"; touch "$selected_file"; fi;

# Utils
grey() { echo -e "\x1B[90m$1\x1B[0m"; };
red() { echo -e "\x1B[31m$1\x1B[0m"; };
green() { echo -e "\x1B[32m$1\x1B[0m"; };
white() { echo -e "\x1B[37m$1\x1B[0m"; };
bold() { echo -e "\x1B[1m$1\x1B[0m"; };
error() { red "$@"; exit 1; };
info() { echo -e "$1"; };

# Actions
select_ego() { echo "$1" > "$config_dir/current"; }

# DOCUMENTATION
EGO="$([ -f "$config_dir/current" ] && cat "$config_dir/current" || echo "")";

CURRENT="$([ -z "$EGO" ] && echo "" || echo -e "$(green $EGO)")";

USAGE=$(
  cat <<-END
$(bold ego) $CURRENT

$(bold "commands")
    use <name> - $(grey "use an alter ego")
    list - $(grey "list alter egos")
    create <name> - $(grey "create a alter ego")
    remove <name> - $(grey "remove an alter ego")
    load <path> - $(grey "load a file to save to this ego")
    unload <path> - $(grey "unload a file from this ego")
    loaded - $(grey "list files loaded in this ego")
END
)

# CLI HANDLERS
command=("$1")
shift

case $command in
    'list')
        ls -1 "$egos_dir" | while read -r ego; do
            if [ "$EGO" == "$ego" ]; then echo "  $(green $ego)"; else echo "  $(white $ego)"; fi
        done
        ;;
    'create')
        if [ -z "$1" ]; then error "Missing ego name"; fi
        if [ -d "$egos_dir/$1" ]; then error "Alter ego $(white $1) $(red "already exists")"; fi
        info "Create alter ego $(green $1)"
        if [ -z "$EGO" ]; then select_ego "$1"; fi
        mkdir -p "$egos_dir/$1"
        exit 0;
        ;;
    'remove')
        if [ -z "$1" ]; then error "Missing ego name"; fi
        if [ ! -d "$egos_dir/$1" ]; then error "Alter ego $(white $1) $(red "does not exist")"; fi
        if [ "$EGO" == "$1" ]; then select_ego ""; fi
        info "Remove alter ego $(bold $1)"
        rm -rf "$egos_dir/$1"
        exit 0;
        ;;
    'use')
        if [ ! -d "$egos_dir/$1" ]; then error "Alter ego $(white $1) $(red "does not exist")"; fi
        info "Using alter ego $(green $1)"
        select_ego "$1"
        ls -1 "$egos_dir/$1" | while read -r local; do
            original="${local//_A_//}";
            cp "$egos_dir/$1/$local" "$original";
            info "Loaded $(bold $original)";
        done
        ;;
    'load')
        if [ -z "$EGO" ]; then error "No alter ego selected"; fi
        local="${1//\//_A_}";
        cp "$1" "$egos_dir/$EGO/$local";
        info "Saving $(bold $1) to $(bold $EGO)";
        ;;
    'unload')
        if [ -z "$EGO" ]; then error "No alter ego selected"; fi
        local="${1//\//_A_}";
        rm -f "$egos_dir/$EGO/$local";
        info "Removing $(bold $1) from $(bold $EGO)";
        ;;
    'loaded')
        if [ -z "$EGO" ]; then error "No alter ego selected"; fi
        ls -1 "$egos_dir/$EGO" | while read -r local; do
            original="${local//_A_//}";
            echo "  $(bold $original)";
        done
        ;;
    *)
        echo "$USAGE"
        exit 1
        ;;
esac
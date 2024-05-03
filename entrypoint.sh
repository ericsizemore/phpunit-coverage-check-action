#!/bin/sh -l
set -e

CLOVER_FILE=""
if [ ! -z "$INPUT_CLOVER_FILE" ]; then
    if test -f "$INPUT_CLOVER_FILE"; then
        CLOVER_FILE="$INPUT_CLOVER_FILE"
    else
        echo "clover.xml not found in repo"
    fi
fi

THRESHOLD="100"
if [ -n "$INPUT_THRESHOLD" ]; then
    if [ "$INPUT_THRESHOLD" -le "1" ] || [ "$INPUT_THRESHOLD" -ge "100" ]; then
        THRESHOLD="100"
    else
        THRESHOLD="$INPUT_THRESHOLD"
    fi
fi

SHOW_FILES=""
ONLY_PERCENTAGE=""
if [ -n "$INPUT_SHOW_FILES" ]; then
    if [ "$INPUT_SHOW_FILES" = "true" ]; then
        SHOW_FILES="--show-files"
    fi
fi

if [ -n "$INPUT_ONLY_PERCENTAGE" ]; then
    if [ "$INPUT_ONLY_PERCENTAGE" = "true" ]; then
        ONLY_PERCENTAGE="--only-percentage"
    fi
fi

if [ "$SHOW_FILES" = "--show-files" ] && [ "$ONLY_PERCENTAGE" = "--only-percentage" ]; then
    ONLY_PERCENTAGE=""
fi

# Code borrowed from psalm/psalm-github-actions

if [ -n "$INPUT_SSH_KEY" ]
then
    echo "::group::Keys setup for private repositories"

    echo "Keyscan:"
    mkdir -p /tmp/.ssh
    ssh-keyscan -t rsa github.com >> /tmp/.ssh/known_hosts
    ssh-keyscan -t rsa gitlab.com >> /tmp/.ssh/known_hosts
    ssh-keyscan -t rsa bitbucket.org >> /tmp/.ssh/known_hosts

    if [ -n "$INPUT_SSH_DOMAIN" ]
    then
      ssh-keyscan -t rsa "$INPUT_SSH_DOMAIN" >> /tmp/.ssh/known_hosts
    fi
    echo "Installing keys:"

    echo "$INPUT_SSH_KEY" > /tmp/.ssh/action_rsa
    echo "$INPUT_SSH_KEY_PUB" > /tmp/.ssh/action_rsa.pub
    chmod 600 /tmp/.ssh/action_rsa

    echo "Private key hash:"
    md5sum /tmp/.ssh/action_rsa
    echo "Public key hash:"
    md5sum /tmp/.ssh/action_rsa.pub

    echo "[core]" >> ~/.gitconfig
    echo "sshCommand = \"ssh -i /tmp/.ssh/action_rsa -o UserKnownHostsFile=/tmp/.ssh/known_hosts\"" >> ~/.gitconfig

    echo "OK"
    echo "::endgroup::"
else
	  echo "No private keys supplied"
fi

if [ -n "$INPUT_RELATIVE_DIR" ]
then
    if [ -d "$INPUT_RELATIVE_DIR" ]; then
        echo "changing directory into $INPUT_RELATIVE_DIR"
        cd "$INPUT_RELATIVE_DIR"
    else
    	echo "given relative_dir not existing"
	exit 1
    fi
fi

if test -f "composer.json"; then
    IGNORE_PLATFORM_REQS=""
    if [ "$CHECK_PLATFORM_REQUIREMENTS" = "false" ] || [ "$INPUT_COMPOSER_IGNORE_PLATFORM_REQS" = "true" ]; then
        IGNORE_PLATFORM_REQS="--ignore-platform-reqs"
    fi

    NO_DEV="--no-dev"
    if [ "$REQUIRE_DEV" = "true" ] || [ "$INPUT_COMPOSER_REQUIRE_DEV" = "true"  ]; then
        NO_DEV=""
    fi

    COMPOSER_COMMAND="composer install --no-scripts --no-progress $NO_DEV $IGNORE_PLATFORM_REQS"
    echo "::group::$COMPOSER_COMMAND"
    $COMPOSER_COMMAND
    echo "::endgroup::"
else 
    echo "composer.json not found in repo, skipping Composer installation"
fi

/composer/vendor/bin/coverage-check --version
echo "options: $CLOVER_FILE $THRESHOLD $ONLY_PERCENTAGE $SHOW_FILES"
/composer/vendor/bin/coverage-check $CLOVER_FILE $THRESHOLD $ONLY_PERCENTAGE $SHOW_FILES $*
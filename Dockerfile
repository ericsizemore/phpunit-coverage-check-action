FROM php:8.4-alpine

LABEL "com.github.actions.name"="PHPUnit Coverage Check"
LABEL "com.github.actions.description"="Check the code coverage using the clover report of PHPUnit."
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="green"

LABEL "org.opencontainers.image.source"="http://github.com/ericsizemore/phpunit-coverage-check-action"
LABEL "org.opencontainers.image.description"="Check the code coverage using the clover report of PHPUnit."
LABEL "org.opencontainers.image.licenses"="MIT"

LABEL "repository"="http://github.com/ericsizemore/phpunit-coverage-check-action"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="Eric Sizemore <admin@secondversion.com>"

# Code borrowed from psalm/psalm-github-actions which in turn borrowed from mickaelandrieu/psalm-ga which in turn borrowed from phpqa/psalm

# Install Tini - https://github.com/krallin/tini

RUN apk add --no-cache tini git openssh-client

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME="/composer" \
    composer global config minimum-stability dev

# This line invalidates cache when master branch change
ADD https://github.com/ericsizemore/phpunit-coverage-check/commits/master.atom /dev/null

RUN COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME="/composer" \
    composer global require esi/phpunit-coverage-check:2.0.0 --prefer-dist --no-progress --dev

ENV PATH /composer/vendor/bin:${PATH}

# composer autoloader (with a symlink that disappears once a volume is mounted at /app)
RUN mkdir /app && ln -s /composer/vendor/ /app/vendor

# Add entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Package container
WORKDIR "/app"
ENTRYPOINT ["/entrypoint.sh"]

# PHPUnit Coverage Check Github action

Run [PHPUnit Coverage Check](https://github.com/ericsizemore/phpunit-coverage-check) as a github action.

## Acknowledgements

This action makes use of code from [psalm/psalm-github-actions](https://github.com/psalm/psalm-github-actions). Without them, I admittedly would have been lost.
Much of the code being used from them are for the `Dockerfile`, `action.yml`, `entrypoint.sh`, and `.github/workflows/watch.yml` files.

## Version Information

Each [release](https://github.com/ericsizemore/phpunit-coverage-check-action/releases) will indicate which version of PHPUnit Coverage Check is being used.

## Basic Usage

You can use the Docker image directly:

```yaml
name: PHPUnit Coverage Check

on: [push, pull_request]

jobs:
  phpunit-coverage-check:
    name: PHPUnit Coverage Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # ... your steps to run PHPUnit and generate a clover file ...

      - name: Coverage Check
        uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action
        with:
          clover_file: 'build/logs/clover.xml'
          threshold: 100

```

Or, the GitHub marketplace action:

```diff
       - name: Coverage Check
-        uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action
+        uses: ericsizemore/phpunit-coverage-check-action@1.0.0
```

## Using a different version

You can also specify a specific PHPUnit Coverage Check version. Currently supports PHPUnit Coverage Check 2.0.0 and greater.

```diff
       - name: Coverage Check
-        uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action
+        uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action:2.0.0
```

## Detailed Usage

There are four main possible inputs, beyond [customizing Composer](#customizing-composer) and [ssh authentication](#auth-for-private-composer-repositories).

#### clover_file

The clover.xml file to be parsed. It must be a valid, PHPUnit generated, clover report.

#### threshold

The threshold that determines the acceptable amount of coverage. Must be at least `1` and no more than `100`.

#### only_percentage

Whether only the percentage of coverage is returned. Accepts boolean values (true or false).

#### show_files

Whether to process and display coverage for all files found within the clover report. Accepts boolean values (true or false)


### An example

Below is an example workflow that uses PHPUnit to run unit tests and generate the clover report, and ties in this action to parse it.

```yaml
name: PHPUnit Coverage Check

on: [push, pull_request]

jobs:
  phpunit-coverage-check:
    name: PHPUnit Coverage Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install PHP ${{ matrix.php }}
        uses: shivammathur/setup-php@master
        with:
           php-version: ${{ matrix.php }}
           extensions: mbstring, 
           coverage: xdebug, pcov
           tools: composer:v2

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: Run test suite
        run: ./vendor/bin/phpunit --coverage-clover clover.xml

      - name: Coverage Check
        uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action
        with:
          clover_file: 'clover.xml'
          threshold: 100

```

## Customising Composer

Specify `composer_require_dev: true` to install dev dependencies and `composer_ignore_platform_reqs: true` in order to ignore platform requirements.

These are both set to false by default.

```diff
       - name: Coverage Check
         uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action
+        with:
+          composer_require_dev: true
+          composer_ignore_platform_reqs: true
```

### Use relative dir

If your composer file is not in the directory, you can specify the relative directory.

Use the following config:

```diff
       - name: Coverage Check
         uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action
+        with:
+          relative_dir: ./subdir
```


Auth for private composer repositories
-------------------------------
If you have private composer dependencies, SSH authentication must be used. Generate an SSH key pair for this purpose and add it to your private repository's configuration, preferable with only read-only privileges. On Github for instance, this can be done by using [deploy keys][deploy-keys].

Add the key pair to your project using  [Github Secrets][secrets], and pass them into this action by using the `ssh_key` and `ssh_key_pub` inputs. If your private repository is stored on another server than github.com, you also need to pass the domain via `ssh_domain`.

Example:

```yaml
jobs:
  build:

    ...

    - name: Coverage Check
      uses: docker://ghcr.io/ericsizemore/phpunit-coverage-check-action
      with:
        ssh_key: ${{ secrets.SOME_PRIVATE_KEY }}
        ssh_key_pub: ${{ secrets.SOME_PUBLIC_KEY }}
        # Optional:
        ssh_domain: my-own-github.com 
```

github.com, gitlab.com and bitbucket.org are automatically added to the list of SSH known hosts. You can provide your own domain via `ssh_domain` input.

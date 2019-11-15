# NAME

git-codeowners - A tool for managing CODEOWNERS files

# VERSION

version 0.45

# SYNOPSIS

    git-codeowners [--version|--help|--manual]

    git-codeowners [show] [--format FORMAT] [--owner OWNER]...
                   [--pattern PATTERN]... [--[no-]patterns]
                   [--project PROJECT]... [--[no-]projects] [PATH...]

    git-codeowners owners [--format FORMAT] [--pattern PATTERN]

    git-codeowners patterns [--format FORMAT] [--owner OWNER]

    git-codeowners create|update [REPO_DIRPATH|CODEOWNERS_FILEPATH]

    # enable bash shell completion
    eval "$(git-codeowners --shell-completion)"

# DESCRIPTION

`git-codeowners` is yet another CLI tool for managing `CODEOWNERS` files in git repos. In
particular, it can be used to quickly find out who owns a particular file in a monorepo (or
monolith).

**THIS IS EXPERIMENTAL!** The interface of this tool and its modules will probably change as I field
test some things. Feedback welcome.

# INSTALL

There are several ways to install `git-codeowners` to your system.

## from CPAN

You can install `git-codeowners` using [cpanm](https://metacpan.org/pod/cpanm):

    cpanm App::Codeowners

## from GitHub

You can also choose to download `git-codeowners` as a self-contained executable:

    curl -OL https://raw.githubusercontent.com/chazmcgarvey/git-codeowners/solo/git-codeowners
    chmod +x git-codeowners

To hack on the code, clone the repo instead:

    git clone https://github.com/chazmcgarvey/git-codeowners.git
    cd git-codeowners
    make bootstrap      # installs dependencies; requires cpanm

# OPTIONS

## --version

Print the program name and version to `STDOUT`, and exit.

Alias: `-v`

## --help

Print the synopsis to `STDOUT`, and exit.

Alias: `-h`

You can also use `--manual` to print the full documentation.

## --color

Enable colorized output.

Color is ON by default on terminals; use `--no-color` to disable. Some environment variables may
also alter the behavior of colorizing output:

- `NO_COLOR` - Set to disable color (same as `--no-color`).
- `COLOR_DEPTH` - Set the number of supportable colors (e.g. 0, 16, 256, 16777216).

## --format

Specify the output format to use. See ["FORMAT"](#format).

Alias: `-f`

## --shell-completion

    eval "$(lintany --shell-completion)"

Print shell code to enable completion to `STDOUT`, and exit.

Does not yet support Zsh...

# COMMANDS

## show

    git-codeowners [show] [--format FORMAT] [--owner OWNER]...
                   [--pattern PATTERN]... [--[no-]patterns]
                   [--project PROJECT]... [--[no-]projects] [PATH...]

Show owners of one or more files in a repo.

If `--owner`, `--project`, `--pattern` are set, only show files with matching
criteria. These can be repeated.

Use `--patterns` to also show the matching pattern associated with each file.

By default the output might show associated projects if the `CODEOWNERS` file
defines them. You can control this by explicitly using `--projects` or
`--no-projects` to always show or always hide defined projects, respectively.

## owners

    git-codeowners owners [--format FORMAT] [--pattern PATTERN]

List all owners defined in the `CODEOWNERS` file.

## patterns

    git-codeowners patterns [--format FORMAT] [--owner OWNER]

List all patterns defined in the `CODEOWNERS` file.

## create

    git-codeowners create [REPO_DIRPATH|CODEOWNERS_FILEPATH]

Create a new `CODEOWNERS` file for a specified repo (or current directory).

## update

    git-codeowners update [REPO_DIRPATH|CODEOWNERS_FILEPATH]

Update the "unowned" list of an existing `CODEOWNERS` file for a specified
repo (or current directory).

# FORMAT

The `--format` argument can be one of:

- `csv` - Comma-separated values (requires [Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV))
- `json:pretty` - Pretty JSON (requires [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS))
- `json` - JSON (requires [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS))
- `table` - Table (requires [Text::Table::Any](https://metacpan.org/pod/Text%3A%3ATable%3A%3AAny))
- `tsv` - Tab-separated values (requires [Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV))
- `yaml` - YAML (requires [YAML](https://metacpan.org/pod/YAML))
- `FORMAT` - Custom format (see below)

## Format string

You can specify a custom format using printf-like format sequences. These are the items that can be
substituted:

- `%F` - Filename
- `%O` - Owner or owners
- `%P` - Project
- `%T` - Pattern
- `%n` - newline
- `%t` - tab
- `%%` - percent sign

The syntax also allows padding and some filters. Examples:

    git-codeowners show -f ' * %-50F %O'                # default for "show"
    git-codeowners show -f '%{quote}F,%{quote}O'        # ad hoc CSV
    git-codeowners patterns -f '--> %{color:0c0}T'      # whatever...

Available filters:

- `quote` - Quote the replacement string.
- `color:FFFFFF` - Colorize the replacement string (if color is ON).
- `nocolor` - Do not colorize replacement string.

## Format table

Table formatting can be done by one of several different modules, each with its own features and
bugs. The default module is [Text::Table::Tiny](https://metacpan.org/pod/Text%3A%3ATable%3A%3ATiny), but this can be overridden using the
`PERL_TEXT_TABLE` environment variable if desired, like this:

    PERL_TEXT_TABLE=Text::Table::HTML git-codeowners -f table

The list of available modules is at ["@BACKENDS" in Text::Table::Any](https://metacpan.org/pod/Text%3A%3ATable%3A%3AAny#BACKENDS).

# CAVEATS

- Some commands require `git` (at least version 1.8.5).

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/chazmcgarvey/git-codeowners/issues](https://github.com/chazmcgarvey/git-codeowners/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

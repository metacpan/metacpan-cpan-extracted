# yamltidy - Automatic cleanup of YAML files

This project is very new - a lot will change.

yamltidy is a formatter for YAML files.

It's is inspired by the great tools
[yamllint](https://yamllint.readthedocs.io/en/stable/) and
[perltidy](https://metacpan.org/pod/Perl::Tidy).

yamllint is based in PyYAML and checks indentation, trailing spaces
and more, based on your configuration.

perltidy takes perl programs and reformats the code.

yamltidy will take a configuration (YAML) file like yamllint, and fix
indentation inconsistencies, trailing spaces and more.

It is based on [C libyaml](https://github.com/yaml/libyaml) and
[perl YAML::LibYAML::API](https://metacpan.org/pod/YAML::LibYAML::API).

    % yamltidy foo.yaml
    ---
    a: # a comment
      b:
        c: d

    # inplace - directly write result into original file
    yamltidy --inplace foo.yaml

You can find results for several configurations here:
[perlpunk.github.io/yamltidy](https://perlpunk.github.io/yamltidy)

## Installation

If you don't have a Perl CPAN client to install modules, install cpanminus:

    # debian example
    % apt-get install cpanminus
    # openSUSE
    % zypper install perl-App-cpanminus

Install yamltidy

    % cpanm YAML::Tidy
    # faster without running tests
    % cpanm --notest YAML::Tidy

If you just want to play with it, but don't want to install it globally,
use this:

    % cpanm -l ~/localyamltidy YAML::Tidy
    % export PERL5LIB=~/localyamltidy/lib/perl5
    % PATH=~/localyamltidy/bin:$PATH

### Use Docker Image

    % docker pull perlpunk/yamltidy
    % docker run -i --rm perlpunk/yamltidy yamltidy - < in.yaml

## Config

The configuration is similar as for yamllint.

It's written in YAML, and it searches for it in these places:

* `$PWD/.yamltidy`
* `~/.config/yamltidy/config.yaml`
* `~/.yamltidy`

You can pass the configuration file via the `-c`/`--config-file` switch.

The default config: [.yamltidy](.yamltidy)

An indentation of two spaces is recommended.
Sequences will by default be zero-indented, because the hyphen `-` counts
as indentation.
The option `block-sequence-in-mapping` can influence that.

The best output for 4 spaces is subject to discussion for a lot of test cases.

## Usage

### Tidy a file and print to stdout

    % cat in.yaml
    ---
    a:
        b:
            c: d
    % yamltidy in.yaml
    ---
    a:
      b:
        c: d

### Tidy content from stdin

    % echo '---
    a:
        b:
            c: d' | yamltidy -
    ---
    a:
      b:
        c: d


### Tidy a file and save the result back

    % yamltidy --inplace in.yaml
    % cat in.yaml
    ---
    a:
      b:
        c: d

### Mappings for vim


    :noremap <leader>yt :%!yamltidy -<CR>

Type `<leader>yt` to tidy the whole buffer

    :vnoremap <leader>yt :!yamltidy --partial -<CR>

Visually select lines and type `<leader>yt`. The first level of indentation
spaces will be kept.

## Tests

yamltidy tests are using the [YAML Test
Suite](https://github.com/yaml/yaml-test-suite).

The tests currently make sure that at least the yamltidy output semantically
matches the input.


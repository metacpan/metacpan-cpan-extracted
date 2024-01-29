# yamltidy - Automatic cleanup of YAML files

yamltidy is a formatter for YAML files.

It's is inspired by the great tools
[yamllint](https://yamllint.readthedocs.io/en/stable/) and
[perltidy](https://metacpan.org/pod/Perl::Tidy).

* yamllint checks YAML files and reports errors and warnings.
* perltidy automatically reformats perl programs
* yamltidy automatically reformats YAML files

## Usage

```
    % yamltidy foo.yaml
    ---
    a: # a comment
      b:
        c: d

    # inplace - directly write result into original file
    yamltidy --inplace foo.yaml
```

Complete documentation of options: [yamltidy.pod](lib/yamltidy.pod)

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

### Local installation

If you just want to play with it, but don't want to install it globally on your
system, use this:

    % cpanm -l ~/localyamltidy YAML::Tidy
    % export PERL5LIB=~/localyamltidy/lib/perl5
    % PATH=~/localyamltidy/bin:$PATH

### Use Container Image

    % docker pull perlpunk/yamltidy
    % docker run -i --rm perlpunk/yamltidy yamltidy - < in.yaml

## Config

The configuration is similar as for yamllint.

It's written in YAML, and it searches for it in these places:

* `$PWD/.yamltidy`
* `~/.config/yamltidy/config.yaml`
* `~/.yamltidy`

You can pass the configuration file via the `-c`/`--config-file` switch.

The default config:

    ---
    v: v0.1
    indentation:
      spaces: 2
      block-sequence-in-mapping: 0
    trailing-spaces: fix
    header: true
    scalar-style:
      default: plain
    adjacency: 0

An indentation of two spaces is recommended.
Sequences will by default be zero-indented, because the hyphen `-` counts
as indentation.
The option `block-sequence-in-mapping` can influence that.

More detailed information on configuration will follow.

You can find examples for several configurations here:
[perlpunk.github.io/yamltidy](https://perlpunk.github.io/yamltidy)


## Utils

## Mappings for vim

Type `<leader>yt` to tidy the whole buffer:

    :noremap <leader>yt :%!yamltidy -<CR>

Visually select lines and type `<leader>yt`. The first level of indentation
spaces will be kept.

    :vnoremap <leader>yt :!yamltidy --partial -<CR>

## Tests

yamltidy tests are using the [YAML Test
Suite](https://github.com/yaml/yaml-test-suite).

The tests currently make sure that at least the yamltidy output semantically
matches the input.

## Implementation

yamltidy is based on [C libyaml](https://github.com/yaml/libyaml) and
[the perl binding YAML::LibYAML::API](https://metacpan.org/pod/YAML::LibYAML::API).


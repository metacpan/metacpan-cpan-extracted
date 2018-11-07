# Perl TDD Runner

This is a tool that runs your Perl tests continuouslly when files change, helping you to TDD. Differently from [provewatch](https://metacpan.org/pod/App::Prove::Watch), the `provetdd` holds all loaded modules in memory, and only reload what it needed, making it exponentially faster to run when testing a huge Perl codebase.

## How to use

```bash
provetdd t/path/to/Test.t
```

You can specify paths to add to INC and specific paths to watch

```bash
provetdd -Ilib --watch lib/path,lib/path2 t/path/to/Test.t
```

You can all run all tests in a folder

```bash
provetdd t/
```

## How to install it from source

First install cpanm and Dist::Zilla

```bash
sudo cpan install App::cpanminus Dist::Zilla
```

If it fails you can force it

```bash
sudo cpan

> force install Dist::Zilla
```

Then install the dzil deps:

```bash
dzil authordeps --missing | sudo cpanm
```

Now you can install it locally

```bash
sudo dzil install
```

## For development

You can run the examples with:

```bash
export PATH="$(pwd)/bin:$PATH"
export PERL5LIB="$PERL5LIB:$(pwd)/lib"

cd example
provetdd --watch lib t/Test.t
```

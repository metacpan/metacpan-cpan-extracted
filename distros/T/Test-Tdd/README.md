# Perl TDD Runner

This is a tool that runs your Perl tests continuouslly when files change, helping you to TDD. Differently from [provewatch](https://metacpan.org/pod/App::Prove::Watch), the `provetdd` holds all loaded modules in memory, and only reload what it needed, making it exponentially faster to run when testing a huge Perl codebase.

## How to use

Install it with `cpan install Test::Tdd` and then:

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

## Generating Tests

If you have existing code where inputs are very hard to be recreated and you want to start doing tests for it, you can use this library to generate a new test by adding this two lines to your function:

```diff
  sub untested_subroutine {
      my ($self, $weird_params) = @_;

+     use Test::Tdd::Generator;
+     Test::Tdd::Generator::create_test('<test description>');

      ...
  }
```

Now run your code as you would normally do to cause this function to be executed and watch the logs. This will save the inputs to a file and generate a test at the closest `t/` folder, it will look like this:

```perl
it '<test description>' => sub {
    my $input = Test::Tdd::Generator::load_input(dirname(__FILE__) . "/input/MyModule_does_something.dump");
    Test::Tdd::Generator::expand_globals($input->{globals});

    my $result = MyModule::untested_subroutine(@{$input->{args}});

    is($result, "fixme");
};
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

After installing, you can run the examples with:

```bash
export PATH="$(pwd)/bin:$PATH"
export PERL5LIB="$PERL5LIB:$(pwd)/lib"

cd example
provetdd --watch lib t/Test.t
```

And test with:

```bash
provetdd --watch lib,t,example/lib t/Test/Tdd/Generator.t
```

To release a new version, follow this tutorial:

http://dzil.org/tutorial/release.html

# ZuzuScript for Perl

This repository contains the Perl implementation of ZuzuScript: the parser,
runtime, tidy tool, and command-line programs used to run and work with
ZuzuScript from Perl.

ZuzuScript programs normally use `.zzs` files. Modules normally use `.zzm`
files. For the full language reference, standard library documentation,
examples, and project overview, see <https://zuzulang.org>.

## Using the language

A small ZuzuScript program can be as direct as:

```zuzu
say "Hello, ZuzuScript!";
```

Functions, lists, dictionaries, classes, traits, exceptions, modules, and the
standard library are covered in the main documentation. For example:

```zuzu
function greeting ( name ) {
	return `Hello, ${ name }`;
}

for ( let name in [ "Ada", "Grace", "Margaret" ] ) {
	say greeting(name);
}
```

This README is only a quick Perl-specific orientation. Use
<https://zuzulang.org> for the language guide and deeper examples.

## Important Perl modules

### Zuzu::Parser

`Zuzu::Parser` parses ZuzuScript source text into an abstract syntax tree.
This is useful for tooling, syntax checks, analysis, or embedding a parser in
another Perl program.

```perl
use Zuzu::Parser;

my $source = 'say "Hello from ZuzuScript";';
my $ast    = Zuzu::Parser->new->parse($source, 'hello.zzs');
```

The parser runs normal semantic hint visitors by default. Tooling that needs a
more direct parse tree can pass `disabled_visitors` to the constructor.

### Zuzu::Runtime

`Zuzu::Runtime` evaluates parsed programs and manages runtime state such as
module search paths, module denials, persistent AST caching, and access to
runtime-supported modules.

```perl
use Zuzu::Parser;
use Zuzu::Runtime;

my $source  = 'say "Hello from the Perl runtime";';
my $ast     = Zuzu::Parser->new->parse($source, 'inline.zzs');
my $runtime = Zuzu::Runtime->new( lib => ['modules'] );

$runtime->evaluate($ast);
$runtime->finish;
```

Most applications should prefer normal ZuzuScript module loading. Native Perl
support belongs in runtime-supported modules only when the language has no
general facility for the required behaviour.

### Zuzu::Tidy

`Zuzu::Tidy` formats ZuzuScript source while preserving comments and embedded
POD where possible. It is the module behind the command-line tidy tool.

```perl
use Zuzu::Tidy;

print Zuzu::Tidy->tidy('if(true){say"yes";}');
```

## Command-line scripts

The distribution installs several scripts:

- `zuzu.pl` runs ZuzuScript programs and is the main command-line entry point.
- `zuzu-tidy.pl` formats ZuzuScript source using `Zuzu::Tidy`.
- `zuzu-highlight.pl` produces syntax-highlighted output for ZuzuScript source.
- `zuzu-plackup.pl` Plack/PSGI wrapper for web apps written in ZuzuScript.
- `zuzudoc.pl` works with ZuzuScript documentation.
- `zuzuprove` runs ZuzuScript TAP-style tests.
- `zuzuzoo` works with ZuzuScript module distributions.

Run each script with its help option for command-specific usage. For broader
language documentation, examples, and project links, use
<https://zuzulang.org>.

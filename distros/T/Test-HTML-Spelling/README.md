# NAME

Test::HTML::Spelling - spelling of HTML documents

# VERSION

version v0.5.0

# SYNOPSIS

```perl
use Test::More;
use Test::HTML::Spelling;

use Test::WWW::Mechanize;

my $sc = Test::HTML::Spelling->new(
    ignore_classes   => [qw( no-spellcheck )],
    check_attributes => [qw( title alt )],
);

$sc->speller->set_option('lang','en_GB');
$sc->speller->set_option('sug-mode','fast');

my $mech = Test::WWW::Mechanize->new();

$mech->get_ok('http://www.example.com/');

$sc->spelling_ok($mech->content, "spelling");

done_testing;
```

# DESCRIPTION

This module parses an HTML document, and checks the spelling of the
text and some attributes (such as the `title` and `alt` attributes).

It will not spellcheck the attributes or contents of elements
(including the contents of child elements) with the class
`no-spellcheck`.  For example, elements that contain user input, or
placenames that are unlikely to be in a dictionary (such as timezones)
should be in this class.

It will fail when an HTML document is not well-formed.

# METHODS

## ignore\_classes

This is an accessor method for the names of element classes that will
not be spellchecked.  It is also a constructor parameter.

It defaults to `no-spellcheck`.

## check\_attributes

This is an accessor method for the names of element attributes that
will be spellchecked.  It is also a constructor parameter.

It defaults to `title` and `alt`.

## ignore\_words

This is an accessor method for setting a hash of words that will be
ignored by the spellchecker.  Use it to specify a custom dictionary,
e.g.

```perl
use File::Slurp;

my %dict = map { chomp($_); $_ => 1 } read_file('custom');

$sc->ignore_words( \%dict );
```

## speller

```perl
my $sc = $sc->speller($lang);
```

This is an accessor that gives you access to a spellchecker for a
particular language (where `$lang` is a two-letter ISO 639-1 language
code).  If the language is omitted, it returns the default
spellchecker:

```
$sc->speller->set_option('sug-mode','fast');
```

Note that options set for the default spellchecker will not be set for
other spellcheckers.  To ensure all spellcheckers have the same
options as the default, use something like the following:

```perl
foreach my $lang (qw( en es fs )) {
    $sc->speller($lang)->set_option('sug-mode',
        $sc->speller->get_option('sug-mode')
    )
}
```

## langs

```perl
my @langs = $sc->langs;
```

Returns a list of languages (as two-letter ISO 639-1 codes) that there
are spellcheckers for.

This can be checked _after_ testing a document to ensure that the
document does not contain markup in unexpected languages.

## check\_spelling

```
if ($sc->check_spelling( $content )) {
  ..
}
```

Check the spelling of a document, and return true if there are no
spelling errors.

## spelling\_ok

```
$sc->spelling_ok( $content, $message );
```

Parses the HTML file and checks the spelling of the document text and
selected attributes.

# KNOWN ISSUES

## Using Test::HTML::Spelling in a module

Suppose you subclass a module like [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize) and add a
`spelling_ok` method that calls ["spelling\_ok"](#spelling_ok).  This will work
fine, except that any errors will be reported as coming from your
module, rather than the test scripts that call your method.

To work around this, call the ["check\_spelling"](#check_spelling) method from within
your module.

# SEE ALSO

The following modules have similar functionality:

- [Apache::AxKit::Language::SpellCheck](https://metacpan.org/pod/Apache::AxKit::Language::SpellCheck)
- [HTML::Spelling::Site](https://metacpan.org/pod/HTML::Spelling::Site)

# SOURCE

The development version is on github at [https://github.com/robrwo/Test-HTML-Spelling](https://github.com/robrwo/Test-HTML-Spelling)
and may be cloned from [git://github.com/robrwo/Test-HTML-Spelling.git](git://github.com/robrwo/Test-HTML-Spelling.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Test-HTML-Spelling/issues](https://github.com/robrwo/Test-HTML-Spelling/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTORS

- Interactive Information, Ltd <cpan@interactive.co.uk>
- Murray Walker <perl@minty.org>
- Rusty Conover &lt;rusty+cpan@luckydinosaur.com>
- Shlomi Fish <shlomif@shlomifish.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2012-2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

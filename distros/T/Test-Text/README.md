Test::Text
=========

[![Build Status](https://travis-ci.org/JJ/Test-Text.svg?branch=master)](https://travis-ci.org/JJ/Test-Text)

Objective
---

A module for testing and doing other kind of metrics on regular text, as in books or
novels, or, for that matter, manuals. 

We're not there yet, but for the time being it is a pretty
good spelling checker that can be used *on the cloud* in continuous
integration literary environments. 

who is this module for?
---

People who write fiction or non-fiction using simple text, Markdown or
similar formats. You don't need to know Perl or continuous integration
or nothing more techie than clicking here and there and saving
files. You probably do know programming stuff, but it's not really needed for using it. 

what is this for?
---

Saves you time by checking spelling automatically. Also measures
progress by telling you how many words you have written so far and in
total, which is an intended side effect of counting the number of
tests == number of words. 

how can I use it in a CI pipeline?
---

1. Save the files you want to be tested to a single directory called,
for instance, `text`, using
`.markdown`, `.txt` or `.md` extensions. That directory will also hold
the `words.dic` where you will save real words that are not included
in the general dictionary. That's your personal dictionary, for short.

2. Sign up for [Travis CI](http://travis-ci.org). You can use your
GitHub account. Choose the repo where your text is hosted and enable it. You
might have to sync your account if the repo has been recently created.

3. Create a `.travis.yml` configuration file in the home directory of
your repo. There are a couple of examples (English and Spanish) in
this repo. You can also copy and paste this

```
branches:
  except:
    - gh-pages
language: perl
perl:
  - "5.16"
before_install:
  - sudo apt-get install libhunspell-1.3-0 libhunspell-dev
  - curl https://raw.githubusercontent.com/JJ/Test-Text/master/files/just_check_en.t -o just_check.t
  - sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en.UTF-8
install: cpanm Test::Text TAP::Harness
script: perl -MTAP::Harness -e 'use utf8; my $harness = TAP::Harness->new( { verbosity => 0} ); die "FAIL" if $harness->runtests( "just_check.t" )->failed;'
```

and save it to that file. You can also use examples
[like this one for a data science manual](https://github.com/JJ/aprende-datos/blob/master/.travis.yml)
directly:

```
wget https://github.com/JJ/aprende-datos/blob/master/.travis.yml
```

That's it. Every time you `push`, your text files will be checked and
it will return the words that it does not know about. You can them fix
them or enter them in your `words.dic` file, with this format

```
4
OneWord
AnotherWord
FooBar
Þor
```

Simple enough, ain't it?

it does not work!
---

You can raise [an issue](https://github.com/JJ/Test-Text/issues)
requesting help.

I'd like to help!
---

Help with other languages would be great. Adding tests other than pure
spell checking, like grammar, would be great too. Check out
the [issues](https://github.com/JJ/Test-Text/issues) and
the [TODO file](TODO.md) for ideas, or create your own issues. 

LICENSES
---

This distribution is licensed under the GPL. In includes
`Test::Text::Sentence`, originally `Text::Sentence`
from [`HTML::Summary`](https://metacpan.org/pod/HTML::Summary), (c) by
NEILB, initial copyright by CRE, and licensed under the Artistic license.

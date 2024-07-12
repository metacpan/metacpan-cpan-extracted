# NAME

Text::Schmutz - You̇r screen is quiṭe dirty, please cleȧn it.

# VERSION

version v0.1.1

# SYNOPSIS

```perl
use Text::Schmutz;

my $s = Text::Schmutz->new( prob => 0.1, use_small => 1 );

say $s->mangle($text);
```

# DESCRIPTION

"Th̔ough̜t̒s of ḍirt spill ̵ȯve̜r to ̜yo͘ur ̜u̒nico͘de̜ ͘enabled t̵ext"

This is a Perl adaptation of `schmutz.go` by Clemens Fries <github-schmutz@xenoworld.de>.

# ATTRIBUTES

## prob

This is the probability that a character will be dirty, between 0 and 1. It defaults to 0.1.

## use\_small

"spray dust on your text".

If ["use\_large"](#use_large) and ["strike\_out"](#strike_out) are not enabled, then this is enabled by default.

For example:

```
Ḷorem i̇ps̒um ̒doḷor sit amet, conse̒ctėṭur adipiscing eḷit̒, ̒se̒d ̒ḋo
eiusṃo̒d ̣tempor incịḍiḋunt ut lạbore ̣e̒t dolo̒re ̣ma̒gna̒ ̣aliq̒uȧ.
```

## use\_large

"a cookie got mangled in your typewriter"

For example, with ["prob"](#prob) set to 0.5:

```
L̔ore̔m ͓ipsum͘ dol͓or͓ sit am͓e͘t̔, ͓cons͓ectet̔ur ͘a̔d̵i̜pisc̔in̜g el̵i͓t͓,͓ s̵e͘d͘ do̔
ei͘usm͓od̜ ͓temp̜or ͓i̵n̔c͓idid̵u̜nt ut ̔la̔bo̜r̵e ̵et̵ ̵dolore̜ ma̵gn͓a͓ ͘al̵i̔qua͓.̵
```

## strike\_out

"this is unacceptable"

For example, with ["prob"](#prob) set to 1.0:

```
L⃫o⃓r⃫e̷m⃓ ⃒i⃥p⃓s̶u⃓m⃥ ⃫d⃒o⃥l⃒o̵r⃦ ̶s̶i⃫t̸ ̶a⃥m̶e⃒t̶,⃥ ̵c⃫o⃥n⃓s̷e⃓c̵t⃒e⃓t̶u̶r⃫ ⃥a⃒d⃥i̶p̵i̵s̷c̸i⃓n⃒g⃒ ̵e̸l⃦i⃓t⃒,̵ ⃥s̵e⃥d̸ ̵d̶o̶
̷e̵i⃥u̵s⃓m⃓o⃫d̶ ̸t̶e⃒m̸p⃓o⃦r⃒ ⃒i̷n⃥c⃫i⃓d⃥i̵d̷u̷n̶t̸ ̵u̷t⃥ ̶l̷a⃦b⃥o̵r⃓e⃒ ⃒e̵t̸ ̸d⃦o̸l̵o̵r⃓e̶ ⃒m̷a̷g̷n̵a̵ ̵a⃦l̷i̷q⃥u̸a̶.⃒
```

# METHODS

## mangle

```
$dirty = $s->mangle( $text, $prob );
```

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Text-Schmutz](https://github.com/robrwo/perl-Text-Schmutz)
and may be cloned from [git://github.com/robrwo/perl-Text-Schmutz.git](git://github.com/robrwo/perl-Text-Schmutz.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Text-Schmutz/issues](https://github.com/robrwo/perl-Text-Schmutz/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The original [schmutz](https://github.com/githubert/schmutz) was written by Clemens Fries <github-schmutz@xenoworld.de>.

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Robert Rothenberg.

This is free software, licensed under:

```
The GNU General Public License, Version 3, June 2007
```

#                              -*- Mode: Cperl -*- 
# $Basename: Filter.pm $
# $Revision: 1.9 $
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug 15 18:09:51 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:46 1998
# Language        : CPerl
# Update Count    : 105
# Status          : Unknown, Use with caution!
#
# Copyright (c) 1996-1997, Ulrich Pfeifer
#
package WAIT::Filter;
require WAIT;
use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK %STOP $SPLIT $AUTOLOAD);
use subs qw(grundform);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
                Stem
                Soundex
                Phonix
                Metaphone
                isolc disolc
                isouc disouc
                isotr disotr
                stop grundform
                utf8iso
               );
# (most implemented in WAIT.xs)

$VERSION = substr q$Revision: 1.9 $, 10;

sub split {
  map split(' ', $_), @_;
}

$SPLIT = q[
           sub splitXXX {
                          grep length($_)>=XXX, map split(' ', $_), @_;
                         }
          ];

sub AUTOLOAD {
  my $func = $AUTOLOAD; $func =~ s/.*:://;

  if ($func =~ /split(\d+)/) {
    my $num = $1;
    my $split = $SPLIT;

    $split =~ s/XXX/$num/g;
    eval $split;
    if ($@ eq '') {
      goto &$AUTOLOAD;
    }
  } elsif ($func eq 'grundform') {
    eval {require Text::German;};
    croak "You must have Text::German to use 'grundform'"
      if $@ ne '';
    *grundform = Text::German->can('reduce');
    goto &grundform;
  } elsif ($func eq 'date') {
    eval {require Time::ParseDate;};
    croak "You must have Time::ParseDate to use 'date'"
      if $@ ne '';
    *date = Time::ParseDate->can('parsedate');
    goto \&date;
  } elsif ($func eq 'decode_entities') {
    eval {require HTML::Entities;};
    croak "You must have HTML::Entities to use 'date'"
      if $@ ne '';
    *decode_entities = HTML::Entities->can('decode_entities');
    goto &decode_entities;
  } elsif ($func =~ /^d?utf8iso$/) {
    require WAIT::Filter::utf8iso;
    croak "Your perl version must at least be 5.00556 to use '$func'"
	if $] < 5.00556;
    no strict 'refs';
    *$func = \&{"WAIT::Filter::utf8iso::$func"};
    goto &utf8iso;
  }
  Carp::confess "Class WAIT::Filter::$func not found";
}

while (<DATA>) {
  chomp;
  last if /__END__/;
  next if /^\s*#/; # there's a comment
  $STOP{$_}++;
}

sub stop {
  if (exists $STOP{$_[0]}) {
    ''
  } else {
    $_[0];
  }
}

sub gdate {
  my $date = shift;

  $date =~ s:(\d+)\.(\d+)\.(d+):$2/$1/$3:;
  date($date);
}

1;
__DATA__
a
about
above
according
across
actually
adj
after
afterwards
again
against
all
almost
alone
along
already
also
although
always
among
amongst
an
and
another
any
anyhow
anyone
anything
anywhere
are
aren't
around
as
at
b
be
became
because
become
becomes
becoming
been
before
beforehand
begin
beginning
behind
being
below
beside
besides
between
beyond
billion
both
but
by
c
can
can't
cannot
caption
co
co.
could
couldn't
d
did
didn't
do
does
doesn't
don't
down
during
e
eg
eight
eighty
either
else
elsewhere
end
ending
enough
etc
even
ever
every
everyone
everything
everywhere
except
f
few
fifty
first
five
vfor
former
formerly
forty
found
four
from
further
g
h
had
has
hasn't
have
haven't
he
he'd
he'll
he's
hence
her
here
here's
hereafter
hereby
herein
hereupon
hers
herself
him
himself
his
how
however
hundred
i
i'd
i'll
i'm
i've
ie
if
in
inc.
indeed
instead
into
is
isn't
it
it's
its
itself
j
k
l
last
later
latter
latterly
least
less
let
let's
like
likely
ltd
m
made
make
makes
many
maybe
me
meantime
meanwhile
might
million
miss
more
moreover
most
mostly
mr
mrs
much
must
my
myself
n
namely
neither
never
nevertheless
next
nine
ninety
no
nobody
none
nonetheless
noone
nor
not
nothing
now
nowhere
o
of
off
often
on
once
one
one's
only
onto
or
other
others
otherwise
our
ours
ourselves
out
over
overall
own
p
per
perhaps
q
r
rather
recent
recently
s
same
seem
seemed
seeming
seems
seven
seventy
several
she
she'd
she'll
she's
should
shouldn't
since
six
sixty
so
some
somehow
someone
something
sometime
sometimes
somewhere
still
stop
such
t
taking
ten
than
that
that'll
that's
that've
the
their
them
themselves
then
thence
there
there'd
there'll
there're
there's
there've
thereafter
thereby
therefore
therein
thereupon
these
they
they'd
they'll
they're
they've
thirty
this
those
though
thousand
three
through
throughout
thru
thus
to
together
too
toward
towards
trillion
twenty
two
u
under
unless
unlike
unlikely
until
up
upon
us
used
using
v
very
via
w
was
wasn't
we
we'd
we'll
we're
we've
well
were
weren't
what
what'll
what's
what've
whatever
when
whence
whenever
where
where's
whereafter
whereas
whereby
wherein
whereupon
wherever
whether
which
while
whither
who
who'd
who'll
who's
whoever
whole
whom
whomever
whose
why
will
with
within
without
won't
would
wouldn't
x
y
yes
yet
you
you'd
you'll
you're
you've
your
yours
yourself
yourselves
z
# occuring in more than 100 files
acc
accent
accents
and
are
bell
can
character
corrections
crt
daisy
dash
date
defined
definitions
description
devices
diablo
dummy
factors
following
font
for
from
fudge
give
have
header
holds
log
logo
low
lpr
mark
name
nroff
out
output
pitch
put
rcsfile
reference
resolution
revision
see
set
simple
smi
some
string
synopsis
system
that
the
this
translation
troff
typewriter
ucb
unbreakable
use
used
user
vroff
wheel
will
with
you
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

WAIT::Filter - Perl extension providing the basic freeWAIS-sf reduction functions

=head1 SYNOPSIS

  use WAIT::Filter qw(Stem Soundex Phonix isolc disolc isouc disouc
                      isotr disotr stop grundform utf8iso);

  $stem   = Stem($word);
  $scode  = Soundex($word);
  $pcode  = Phonix($word);
  $lword  = isolc($word);
  disolc($word);
  $uword  = isouc($word);
  disouc($word);
  $trword = isotr($word);
  disotr($word);
  $word   = stop($word);
  $word   = grundform($word);

  @words = WAIT::Filter::split($word);
  @words = WAIT::Filter::split2($word);
  @words = WAIT::Filter::split3($word);
  @words = WAIT::Filter::split4($word); # arbitrary numbers allowed

=head1 DESCRIPTION

This tiny modules gives access to the basic reduction functions build
in B<freeWAIS-sf>.

=over 5

=item B<Stem>(I<word>)

reduces I<word> using the well know Porter algorithm.

  AU: Porter, M.F.
  TI: An Algorithm for Suffix Stripping
  JT: Program
  VO: 14
  PP: 130-137
  PY: 1980
  PM: JUL

=item B<Soundex>(I<word>)


computes the 4 byte B<Soundex> code for I<word>.

  AU: Gadd, T.N.
  TI: 'Fisching for Werds'. Phonetic Retrieval of written text in
      Information Retrieval Systems
  JT: Program
  VO: 22
  NO: 3
  PP: 222-237
  PY: 1988


=item B<Phonix>(I<word>)

computes the 8 byte B<Phonix> code for I<word>.

  AU: Gadd, T.N.
  TI: PHONIX: The Algorithm
  JT: Program
  VO: 24
  NO: 4
  PP: 363-366
  PY: 1990
  PM: OCT

=head1 ISO charcater case functions

There are some additional function which transpose some/most ISOlatin1
characters to upper and lower case. To allow for maximum speed there
are also I<destructive> versions which change the argument instead of
allocating a copy which is returned. For convenience, the destructive
version also B<returns> the argument. So all of the following is
valid and C<$word> will contain the lowercased string.

  $word = isolc($word);
  $word = disolc($word);
  disolc($word);

Here are the hardcoded characters which are recognized:

  abcdefghijklmnopqrstuvwxyz‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ¯˘˙˚¸˝ﬂ
  ABCDEFGHIJKLMNOPQRSTUVWXYZ¿¡¬√ƒ≈∆«»… ÀÃÕŒœ—“”‘’÷ÿŸ⁄€‹›ﬂ

=item C<$new = >B<isolc>C<($word)>

=item B<disolc>C<($word)>

transposes to lower case.

=item C<$new = >B<isouc>C<($word)>

=item  B<disouc>C<($word)>

transposes to upper case.

=item C<$new = >B<isotr>C<($word)>

=item  B<disotr>C<($word)>

Remove non-letters according to the above table.

=item C<$new = >B<stop>C<($word)>

Returns an empty string if $word is a stopword.

=item C<$new = >B<grundform>C<($word)>

Calls Text::German::reduce

=item C<$new = >B<utf8iso>C<($word)>

Convert UTF8 encoded strings to ISO-8859-1. WAIT currently is
internally based on the Latin1 character set, so if you process
anything in a different encoding, you should convert to Latin1 as the
first filter.

=item split, split2, split3, ...

The splitN funtions all take a scalar as input and return a list of
words. Split acts just like the perl split(' '). Split2 eliminates all
words from the list that are shorter than 2 characters (bytes), split3
eliminates those shorter than 3 characters (bytes) and so on.

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@ls6.informatik.uni-dortmund.de>E<gt>

=head1 SEE ALSO

perl(1).

=cut


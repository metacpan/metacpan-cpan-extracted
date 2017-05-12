#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-wrapper.t
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use Test::More;

# Load Test::Differences, if available:
BEGIN {
  # SUGGEST PREREQ: Test::Differences
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    *eq_or_diff = \&is;         # Just use "is" instead
  }
} # end BEGIN

use Text::Wrapper;

my $generate = (@ARGV and $ARGV[0] eq 'print');

if ($generate) {
  open(OUT, '>', '/tmp/10-wrapper.t') or die;
} else {
  plan tests => 7;
}

#=====================================================================
sub read_data
{
    my $text = '';
    while (<DATA>) {
        return ($1, $text) if /^\*\s*(.*)/;
        $text .= $_;
    }
    die "Unexpected end of file";
} # end read_data

#=====================================================================
# First, read the sample text, remove single line breaks, and condense
# double line breaks into one:

my $text = (read_data)[1];
$text =~ s/\n(?=\S)/ /g;
$text =~ s/\n /\n/g;

#---------------------------------------------------------------------
# Now try each set of parameters and compare it to the expected result:
#   (Or, if invoked as '10-wrapper.t print', print out the actual
#   results and parameters in the required format.)

my ($test,$args,$expect,$w,$result) = 1;
for (;;) {
    ($args,$expect) = read_data;
    last unless $expect;
    $w = Text::Wrapper->new(eval $args);
    $result = $w->wrap($text);
    if ($generate) { print OUT "$result* $args\n" }
    else {
      eq_or_diff($result, $expect, $args);
    }
} # end forever

#---------------------------------------------------------------------
# Here is the sample text followed by the test cases.  Each test case
# is terminated by a line beginning with *, followed by the parameters
# for that test.  The test cases are terminated by an empty case.
# Don't forget to change the count in the "plan tests" line.

__DATA__
Fourscore and seven years ago our fathers brought forth on this
continent a new nation, conceived in liberty and dedicated to the
proposition that all men are created equal.

Now we are engaged in a great civil war, testing whether that nation
or any nation so conceived and so dedicated can long endure. We are
met on a great battlefield of that war. We have come to dedicate a
portion of that field as a final resting-place for those who here gave
their lives that that nation might live. It is altogether fitting and
proper that we should do this.

But in a larger sense, we cannot dedicate, we cannot consecrate, we
cannot hallow this ground.  The brave men, living and dead who
struggled here have consecrated it far above our poor power to add or
detract. The world will little note nor long remember what we say
here, but it can never forget what they did here. It is for us the
living rather to be dedicated here to the unfinished work which they
who fought here have thus far so nobly advanced. It is rather for us
to be here dedicated to the great task remaining before us--that from
these honored dead we take increased devotion to that cause for which
they gave the last full measure of devotion--that we here highly
resolve that these dead shall not have died in vain, that this nation
under God shall have a new birth of freedom, and that government of
the people, by the people, for the people shall not perish from the
earth.
*
Fourscore and seven years ago our
fathers brought forth on this continent
a new nation, conceived in liberty and
dedicated to the proposition that all
men are created equal.
Now we are engaged in a great civil war,
testing whether that nation or any
nation so conceived and so dedicated can
long endure. We are met on a great
battlefield of that war. We have come to
dedicate a portion of that field as a
final resting-place for those who here
gave their lives that that nation might
live. It is altogether fitting and
proper that we should do this.
But in a larger sense, we cannot
dedicate, we cannot consecrate, we
cannot hallow this ground.  The brave
men, living and dead who struggled here
have consecrated it far above our poor
power to add or detract. The world will
little note nor long remember what we
say here, but it can never forget what
they did here. It is for us the living
rather to be dedicated here to the
unfinished work which they who fought
here have thus far so nobly advanced. It
is rather for us to be here dedicated to
the great task remaining before us--that
from these honored dead we take
increased devotion to that cause for
which they gave the last full measure of
devotion--that we here highly resolve
that these dead shall not have died in
vain, that this nation under God shall
have a new birth of freedom, and that
government of the people, by the people,
for the people shall not perish from the
earth.
* (columns => 40)
>  Fourscore and seven years ago our fathers
   brought forth on this continent a new nation,
   conceived in liberty and dedicated to the
   proposition that all men are created equal.
>  Now we are engaged in a great civil war,
   testing whether that nation or any nation so
   conceived and so dedicated can long endure. We
   are met on a great battlefield of that war. We
   have come to dedicate a portion of that field
   as a final resting-place for those who here
   gave their lives that that nation might live.
   It is altogether fitting and proper that we
   should do this.
>  But in a larger sense, we cannot dedicate, we
   cannot consecrate, we cannot hallow this
   ground.  The brave men, living and dead who
   struggled here have consecrated it far above
   our poor power to add or detract. The world
   will little note nor long remember what we say
   here, but it can never forget what they did
   here. It is for us the living rather to be
   dedicated here to the unfinished work which
   they who fought here have thus far so nobly
   advanced. It is rather for us to be here
   dedicated to the great task remaining before
   us--that from these honored dead we take
   increased devotion to that cause for which
   they gave the last full measure of devotion--
   that we here highly resolve that these dead
   shall not have died in vain, that this nation
   under God shall have a new birth of freedom,
   and that government of the people, by the
   people, for the people shall not perish from
   the earth.
* (par_start => '>  ', body_start => '   ', columns => 49)
>    Fourscore and seven years ago our fathers brought forth on this
 | continent a new nation, conceived in liberty and dedicated to the
 | proposition that all men are created equal.
>    Now we are engaged in a great civil war, testing whether that
 | nation or any nation so conceived and so dedicated can long endure.
 | We are met on a great battlefield of that war. We have come to
 | dedicate a portion of that field as a final resting-place for those
 | who here gave their lives that that nation might live. It is
 | altogether fitting and proper that we should do this.
>    But in a larger sense, we cannot dedicate, we cannot consecrate,
 | we cannot hallow this ground.  The brave men, living and dead who
 | struggled here have consecrated it far above our poor power to add
 | or detract. The world will little note nor long remember what we
 | say here, but it can never forget what they did here. It is for us
 | the living rather to be dedicated here to the unfinished work which
 | they who fought here have thus far so nobly advanced. It is rather
 | for us to be here dedicated to the great task remaining before us--
 | that from these honored dead we take increased devotion to that
 | cause for which they gave the last full measure of devotion--that
 | we here highly resolve that these dead shall not have died in vain,
 | that this nation under God shall have a new birth of freedom, and
 | that government of the people, by the people, for the people shall
 | not perish from the earth.
* (par_start => '>    ', body_start => ' | ')
Fourscore
and seven
years ago
our
fathers
brought
forth on
this
continent
a new
nation,
conceived
in liberty
and
dedicated
to the
proposition
that all
men are
created
equal.
Now we are
engaged in
a great
civil war,
testing
whether
that
nation or
any nation
so
conceived
and so
dedicated
can long
endure. We
are met on
a great
battlefield
of that
war. We
have come
to
dedicate a
portion of
that field
as a final
resting-
place for
those who
here gave
their
lives that
that
nation
might
live. It
is
altogether
fitting
and proper
that we
should do
this.
But in a
larger
sense, we
cannot
dedicate,
we cannot
consecrate,
we cannot
hallow
this
ground.
The brave
men,
living and
dead who
struggled
here have
consecrated
it far
above our
poor power
to add or
detract.
The world
will
little
note nor
long
remember
what we
say here,
but it can
never
forget
what they
did here.
It is for
us the
living
rather to
be
dedicated
here to
the
unfinished
work which
they who
fought
here have
thus far
so nobly
advanced.
It is
rather for
us to be
here
dedicated
to the
great task
remaining
before
us--that
from these
honored
dead we
take
increased
devotion
to that
cause for
which they
gave the
last full
measure of
devotion--
that we
here
highly
resolve
that these
dead shall
not have
died in
vain, that
this
nation
under God
shall have
a new
birth of
freedom,
and that
government
of the
people, by
the
people,
for the
people
shall not
perish
from the
earth.
* (columns => 10)
Fourscore and seven years ago our fathers
brought forth on this continent a new nation,
conceived in liberty and dedicated to the
proposition that all men are created equal.
Now we are engaged in a great civil war,
testing whether that nation or any nation so
conceived and so dedicated can long endure. We
are met on a great battlefield of that war. We
have come to dedicate a portion of that field
as a final resting-place for those who here
gave their lives that that nation might live.
It is altogether fitting and proper that we
should do this.
But in a larger sense, we cannot dedicate, we
cannot consecrate, we cannot hallow this
ground.  The brave men, living and dead who
struggled here have consecrated it far above
our poor power to add or detract. The world
will little note nor long remember what we say
here, but it can never forget what they did
here. It is for us the living rather to be
dedicated here to the unfinished work which
they who fought here have thus far so nobly
advanced. It is rather for us to be here
dedicated to the great task remaining before
us--that from these honored dead we take
increased devotion to that cause for which
they gave the last full measure of
devotion--that we here highly resolve that
these dead shall not have died in vain, that
this nation under God shall have a new birth
of freedom, and that government of the people,
by the people, for the people shall not perish
from the earth.
* (columns => 46, wrap_after => '')
Fourscore
and
seven
years
ago
our
fathers
brought
forth
on
this
continent
a
new
nation,
conceived
in
liberty
and
dedicated
to
the
proposition
that
all
men
are
created
equal.
Now
we
are
engaged
in
a
great
civil
war,
testing
whether
that
nation
or
any
nation
so
conceived
and
so
dedicated
can
long
endure.
We
are
met
on
a
great
battlefield
of
that
war.
We
have
come
to
dedicate
a
portion
of
that
field
as
a
final
resting-
place
for
those
who
here
gave
their
lives
that
that
nation
might
live.
It
is
altogether
fitting
and
proper
that
we
should
do
this.
But
in
a
larger
sense,
we
cannot
dedicate,
we
cannot
consecrate,
we
cannot
hallow
this
ground.
The
brave
men,
living
and
dead
who
struggled
here
have
consecrated
it
far
above
our
poor
power
to
add
or
detract.
The
world
will
little
note
nor
long
remember
what
we
say
here,
but
it
can
never
forget
what
they
did
here.
It
is
for
us
the
living
rather
to
be
dedicated
here
to
the
unfinished
work
which
they
who
fought
here
have
thus
far
so
nobly
advanced.
It
is
rather
for
us
to
be
here
dedicated
to
the
great
task
remaining
before
us--
that
from
these
honored
dead
we
take
increased
devotion
to
that
cause
for
which
they
gave
the
last
full
measure
of
devotion--
that
we
here
highly
resolve
that
these
dead
shall
not
have
died
in
vain,
that
this
nation
under
God
shall
have
a
new
birth
of
freedom,
and
that
government
of
the
people,
by
the
people,
for
the
people
shall
not
perish
from
the
earth.
* (columns => 1)

Fourscore
and
seven
years
ago
our
fathers
brought
forth
on
this
continent
a
new
nation,
conceived
in
liberty
and
dedicated
to
the
proposition
that
all
men
are
created
equal.

Now
we
are
engaged
in
a
great
civil
war,
testing
whether
that
nation
or
any
nation
so
conceived
and
so
dedicated
can
long
endure.
We
are
met
on
a
great
battlefield
of
that
war.
We
have
come
to
dedicate
a
portion
of
that
field
as
a
final
resting-place
for
those
who
here
gave
their
lives
that
that
nation
might
live.
It
is
altogether
fitting
and
proper
that
we
should
do
this.

But
in
a
larger
sense,
we
cannot
dedicate,
we
cannot
consecrate,
we
cannot
hallow
this
ground.
The
brave
men,
living
and
dead
who
struggled
here
have
consecrated
it
far
above
our
poor
power
to
add
or
detract.
The
world
will
little
note
nor
long
remember
what
we
say
here,
but
it
can
never
forget
what
they
did
here.
It
is
for
us
the
living
rather
to
be
dedicated
here
to
the
unfinished
work
which
they
who
fought
here
have
thus
far
so
nobly
advanced.
It
is
rather
for
us
to
be
here
dedicated
to
the
great
task
remaining
before
us--that
from
these
honored
dead
we
take
increased
devotion
to
that
cause
for
which
they
gave
the
last
full
measure
of
devotion--that
we
here
highly
resolve
that
these
dead
shall
not
have
died
in
vain,
that
this
nation
under
God
shall
have
a
new
birth
of
freedom,
and
that
government
of
the
people,
by
the
people,
for
the
people
shall
not
perish
from
the
earth.

* (columns => 1, par_start => "\n", wrap_after => '')
* This line marks the end of the test cases

Local Variables:
  compile-command: "perl 10-wrapper.t print"
  tmtrack-file-task: "Text::Wrapper: test.pl"
End:

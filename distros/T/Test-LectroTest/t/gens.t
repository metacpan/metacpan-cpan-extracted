#!/usr/bin/perl -w

use strict;
use Test::More tests => 248;

BEGIN { use_ok( 'Test::LectroTest::Generator', qw(:common :combinators) ) }


=head1 NAME

gens.t - Unit tests for Test::LectroTest::Generator

=head1 SYNOPSIS

    perl -Ilib t/gens.t

=head1 DESCRIPTION

B<Important:> This test suite relies upon a number of randomized tests
and statistical inferences.  As a result, there is a small probability
(about 1 in 200) that some part of the suite will fail even if
everything is working properly.  Therefore, if a test fails, re-run
the test suite to determine whether the supposed problem is real or
just a rare instance of the Fates poking fun at you.

This documentation is written mainly for programmers who maintain the
test suite.  If you are an end user of the LectroTest modules, you can
stop reading now because otherwise you will be bored to tears.

=cut


# set up warning net for errors in this test suite

BEGIN {
    no warnings 'redefine';
    my $ok = \&Test::Builder::ok;
    *Test::Builder::ok = sub { (my $r = $ok->(@_)) || emit_warning(); $r };
}


sub emit_warning {
    Test::Builder->new->diag(<<EOF);

============================================================

IMPORTANT!  A TEST FAILURE MAY NOT REPRESENT A REAL PROBLEM.

This test suite relies upon a number of randomized tests and
statistical inferences.  So, there is a small probability
that some part of the suite will fail even if everything is
actually fine.  Therefore, re-run the test suite.  You do
not have a problem unless the suite fails repeatably.

============================================================

EOF
}


#==============================================================================

=head1 Configuration

The $tsize variable determines how many trials to run durring the
collection of distribution stats, mainly for the Int generator.  The
more trials you run, the smaller the deviations from the expected
results you can detect.  It is suggested that you do not change this
value.

=cut

my $tsize = 10_000;



#==============================================================================
#==============================================================================
#==============================================================================

=head1 Fundamental tests

Here we sanity check that the fundamental object types can be created
and that they have the right base class.

=cut


for (qw/Int Bool Float Char String List Elements(1) Unit(1)
        Paste OneOf(Unit(0)) Each Map{} Concat Flatten
        ConcatMap{} FlattenMap{} /,
     'Hash(Unit(1),Unit(1))', 'Frequency([1,"a"])', 'Sized{1}Unit(0)') {
    my $g = eval $_ or die $@;
    ok(defined $g, "$_ constructor returns something");
    ok($g->isa('Test::LectroTest::Generator'),
       "$_ ctor returns a Test::LectroTest::Generator");
}


#==============================================================================
#==============================================================================
#==============================================================================
# Helpers

sub clipped_triangle_mean($$$) {
    my ($m,$s,$n) = @_;
    my $bot   = max($m,$s);
    my $mfrac = max(($m-$s)/($n-$s+1),0);
    return $m + (1-$mfrac) * (($bot-$m)/2+($n-$bot)/4);
}

sub max {
    my $max;
    foreach (@_) {
        $max = $_ if !defined($max) || $_ > $max;
    }
    $max;
}


#==============================================================================
#==============================================================================
#==============================================================================

=head1 Generator tests

Here we test the generators.  We perform the following tests. 

=cut

#==============================================================================

=pod

=head2 Bool

The Bool distribution is really an Int distribution over the
range [0,1].  Therefore, we make sure that it has a mean of 0.5.

=cut

dist_mean_ok("Bool", Bool, [1..$tsize], sub{$_[0]}, 0.5);

#==============================================================================

=pod 

=head2 Char

The Char distribution should return only the characters in the set we
give it, and all of the characters in the set should be possible
output values.  First, we test to see that a trivial Char generator
for a single character always returns that character.

=cut

{
    my $gstr = 'Char(charset=>"x")';
    my $gen  = eval $gstr;
    my @vals = map {$gen->generate($_)} 1..1000;
    is( scalar( grep { $_ eq "x" } @vals ), 1000,
        "$gstr generates only 'x' values" );
}

=pod

Next, we make sure that a Char generator with a ten-character
range generates all ten characters and does so with equal
probability.

=cut

{
    my $gstr = 'Char(charset=>"a-j")';
    my $gen  = eval $gstr;
    complete_and_uniform_ok($gen, $gstr, ["a".."j"]);
}

=pod

Next, we run a few tests to make sure that the parser for
character set specifications work.  We try the following:
"a", "-", "a-a", "-a", "a-", "aA-C", "A-Ca":

=cut

#     cset-spec    expected charset
for ( ["a"        ,"a"           ],
      ["-"        ,"-"           ],
      ["a-a"      ,"a"           ],
      ["-a"       ,"-a"          ],
      ["a-"       ,"-a"          ],
      ["aA-C"     ,"ABCa"        ],
      ["A-Ca"     ,"ABCa"        ],
      ["X-YaA-C"  ,"ABCXYa"      ],
      ["A-CaX-Y"  ,"ABCXYa"      ],
    )
{
    my ($cspec, $expected) = @$_;
    my @expected = split //, $expected;
    my $gstr = "Char(charset=>'$cspec')";
    my $gen  = eval $gstr;
    my @got = map { $gen->generate } 1..10_000;
    @got = sort keys %{{ map {($_,1)} @got }};  # uniq
    my $got = join '', @got;
    is ($got, $expected, "$gstr generated the char set '$expected'");
}

#==============================================================================

=pod 

=head2 Elements and OneOf

The Elements tests indirectly test OneOf, upon which the Elements
generator is built.  We ensure that the Elements distribution is
complete and uniform.

=cut

for ([0..9],["a".."j"])
{
    my $g = Elements(@$_);
    complete_and_uniform_ok($g, "Elements(@$_)", $_);
}

=pod

We must also test the pre-flight check.

=cut

like( eval { Elements() } || $@,
      qr/must be.*at least one element/,
      "pre-flight: Elements(<empty>) caught"
);



#==============================================================================

=pod

=head2 Float

The Float tests are modeled after the Int tests, but there are subtle
differences in order to accomodate the differences between the
underlying generators.  In particular, Float has an (approximately)
continuous distribution whereas Int has a discrete distribution.

First, we test seven Float generators having ranges 201 wide and
centered around -300, -200, ... 200, 300.  The generators are unsized
(B<sized=E<gt>0>) and thus should have means at the range centers.

=cut


for (-3..3) {
    my $center = $_ * 100;
    my ($m,$n) = ($center-100, $center+100);
    dist_mean_ok("Float(sized=>0,range=>[$m,$n])",
                 Float(sized=>0,range=>[$m,$n]),
                 [1..$tsize],sub{$_[0]}, $center);
}

=pod

Second, we test five more Float generators having ranges from [0,$span]
where $span becomes increasingly large, finally equaling the
configuration parameter $tsize.  These generators are sized, and so we
would expect the mean of their distributions to be equal to a weighted
average of X1 and X2, where X1 is the mean of the equivalent un-sized
distribution, and X2 is half of the mean of the sizing guidance over
the range of values for which the sizing constrains the range.

=cut


for (1..5) {
    my $span = $_ * $tsize/5;
    #                   Weights                  Means
    my $expected_mean = (($tsize-$span)/$tsize)* ($span/2)  # X1
                      + ($span/$tsize)         * ($span/4); # X2
    dist_mean_ok("Float(sized=>1,range=>[0,$span])",
                 Float(sized=>1,range=>[0,$span]),
                 [0..$tsize],sub{$_[0]}, $expected_mean);
}

=pod

Third, we repeat the above test, this time using balanced ranges
[-$span,$span] for the same increasing progression of $span values.
Because the range is balanced, as is the effect of sizing, the
mean of the distributions must be zero.

=cut

for (1..5) {
    my $span = $_ * $tsize/5;
    dist_mean_ok("Float(sized=>1,range=>[-$span,$span])",
                 Float(sized=>1,range=>[-$span,$span]),
                 [0..$tsize],sub{$_[0]}, 0);
}

=pod

Fourth, we run a series of unsized tests over 3-element ranges near
zero.  Because the ranges are so small, we expect that if there were
off-by-one errors in the code, they would stand out here.

=cut

for (-3..3) {
    my ($m,$n) = ($_-1,$_+1);
    dist_mean_ok("Float(sized=>0,range=>[$m,$n])",
                 Float(sized=>0,range=>[$m,$n]),
                 [0..$tsize],sub{$_[0]}, $_);
}

=pod

Fifth, we make sure that LectroTest prevents us from providing an
empty range.

=cut

for ( 'Float(range=>[1,0])', 'Float(range=>[0,-1])'  ) {

    like( eval $_ || $@,
          qr/is empty/,
          "$_ is caught as an empty range"  );
}

for ( 'Float(range=>[0,0])' ) {

    isa_ok( eval $_,
           'Test::LectroTest::Generator',
           "$_ is not wrongly caught as empty / "  );
}

=pod

Sixth, we test the case where the generator is called
without sizing guidance.  In this case the full range is
used.

=cut

for (-3..3) {
    my ($m,$n) = ($_ - 4, $_ + 4);
    my $g = Sized { undef } Float(range=>[$m,$n]);
    dist_mean_ok("Sized{undef} Float(range=>[$m,$n])",
                 $g, [(undef)x$tsize], sub{$_[0]}, $_);
}


=pod

Finally, we make sure that LectroTest prevents us from using a sized
generator with a given range that does not contain zero.

=cut

for ( 'Float(range=>[-10,-1])', 'Float(range=>[1,10])'  ) {

    like( eval $_ || $@,
          qr/does not contain zero/,
          "$_ is caught as incompatible with sizing"  );
}

for ( 'Float(range=>[-10,0])', 'Float(range=>[0,10])', 'Float' ) {

    isa_ok( eval $_,
           'Test::LectroTest::Generator',
           "$_ is not wrongly caught as incompatible with sizing /"  );
}

#==============================================================================
#==============================================================================

=pod

=head2 Int

We must test Int hardcore because it is the generator upon which
most others are built.

First, we test seven Int generators having ranges ten elements
wide and centered around -3000, -2000, ... 2000, 3000.
We ensure that each of the generators is complete and uniformly
distributed.

=cut

for (-3..3) {
    my $center = $_ * 1_000;
    my ($m,$n) = ($center-5, $center+4);
    my $g = Int(sized=>0,range=>[$m,$n]);
    complete_and_uniform_ok($g, "Int(sized=>0,range=>[$m,$n])",[$m..$n]);
}

=pod

Second, we test seven more Int generators having ranges 201 elements
wide and centered around -300, -200, ... 200, 300.  The generators
are unsized (B<sized=E<gt>0>) and thus should have means at the
range centers.

=cut


for (-3..3) {
    my $center = $_ * 100;
    my ($m,$n) = ($center-100, $center+100);
    dist_mean_ok("Int(sized=>0,range=>[$m,$n])",
                 Int(sized=>0,range=>[$m,$n]),
                 [1..$tsize],sub{$_[0]}, $center);
}

=pod

Third, we test five more Int generators having ranges from [0,$span]
where $span becomes increasingly large, finally equaling the
configuration parameter $tsize.  These generators are sized, and so we
would expect the mean of their distributions to be equal to a weighted
average of X1 and X2, where X1 is the mean of the equivalent un-sized
distribution, and X2 is half of the mean of the sizing guidance over
the range of values for which the sizing constrains the range.

=cut


for (1..5) {
    my $span = $_ * $tsize/5;
    #                   Weights                  Means
    my $expected_mean = (($tsize-$span)/$tsize)* ($span/2)  # X1
                      + ($span/$tsize)         * ($span/4); # X2
    dist_mean_ok("Int(sized=>1,range=>[0,$span])",
                 Int(sized=>1,range=>[0,$span]),
                 [0..$tsize],sub{$_[0]}, $expected_mean);
}

=pod

Fourth, we repeat the above test, this time using balanced ranges
[-$span,$span] for the same increasing progression of $span values.
Because the range is balanced, as is the effect of sizing, the
mean of the distributions must be zero.

=cut

for (1..5) {
    my $span = $_ * $tsize/5;
    dist_mean_ok("Int(sized=>1,range=>[-$span,$span])",
                 Int(sized=>1,range=>[-$span,$span]),
                 [0..$tsize],sub{$_[0]}, 0);
}

=pod

Fifth, we run a series of unsized tests over 3-element ranges near
zero.  Because the ranges are so small, we expect that if there were
off-by-one errors in the code, they would stand out here.

=cut

for (-3..3) {
    my ($m,$n) = ($_-1,$_+1);
    dist_mean_ok("Int(sized=>0,range=>[$m,$n])",
                 Int(sized=>0,range=>[$m,$n]),
                 [0..$tsize],sub{$_[0]}, $_);
}

=pod

Sixth, we make sure that LectroTest prevents us from providing an
empty range.

=cut

for ( 'Int(range=>[1,0])', 'Int(range=>[0,-1])'  ) {

    like( eval $_ || $@,
          qr/is empty/,
          "$_ is caught as an empty range"  );
}

for ( 'Int(range=>[0,0])' ) {

    isa_ok( eval $_,
           'Test::LectroTest::Generator',
           "$_ is not wrongly caught as empty / "  );
}


=pod

Seventh, we test the case where the generator is called
without sizing guidance.  In this case the full range is
used.

=cut

for (-3..3) {
    my ($m,$n) = ($_ - 5, $_ + 4);
    my $g = Sized { undef } Int(range=>[$m,$n]);
    complete_and_uniform_ok($g, "Sized{undef} Int(range=>[$m,$n])",[$m..$n]);
}


=pod

Finally, we make sure that LectroTest prevents us from using a sized
generator with a given range that does not contain zero.

=cut

for ( 'Int(range=>[-10,-1])', 'Int(range=>[1,10])'  ) {

    like( eval $_ || $@,
          qr/does not contain zero/,
          "$_ is caught as incompatible with sizing"  );
}

for ( 'Int(range=>[-10,0])', 'Int(range=>[0,10])', 'Int' ) {

    isa_ok( eval $_,
           'Test::LectroTest::Generator',
           "$_ is not wrongly caught as incompatible with sizing /"  );
}


#==============================================================================

=pod

=head2 Hash

Hash is a thin wrapper around List and so we need only a few
Hash-specific tests to get good coverage.

=cut

for( 'Unit(0),Unit(1)           {0=>1}',
     'Int(range=>[0,5],sized=>0),Unit(1),length=>1000 {0=>1,1=>1,2=>1,3=>1,4=>1,5=>1}' )
{
    my ($hash_args, $expected) = split ' ', $_, 2;
    my $gen_spec = "Hash($hash_args)";
    is_deeply( (eval $gen_spec)->generate(1000), 
               eval $expected,
               "$gen_spec gens $expected");
}

=pod

Still, we need to test the pre-flight checks.

=cut

like( eval { Hash(Int) } || $@,
      qr/requires two/,
      "pre-flight: Hash(Int) caught"
);




#==============================================================================

=pod

=head2 List

We consider four test cases to determine whether List respects
its B<length> modifier.  First, we test the default list generation
method, where list length is constrained only by the sizing guidance.
For sizing guidance in [1..I<N>], the expected mean generated list
length is (1+I<N>)/4.

=cut

{
    my $gstr = "List(Unit(1))";
    my $gen  = eval $gstr;
    for (1,5,10,25) {
        dist_mean_ok( "$gstr elem length under sizing [1..$_]",
                      $gen, [(1..$_)x($tsize/$_)],
                      sub { scalar @{$_[0]} }, (1+$_)/4 );
    }
}

=pod

Second, we test the B<length=E<gt>>I<N> variant.  It should
generate lists whose length always equals I<N>.

=cut

{
    for my $len (0..3) {
        my $gstr = "List(Unit('x'),length=>$len)";
        my $gen  = eval $gstr;
        my @vals = map {$gen->generate($_)} 1..$tsize;
        is( scalar ( grep { $len == grep {'x' eq $_} @$_ } @vals ), $tsize,
            "All lists from $gstr are [('x')x$len]" );
    }
}

=pod

Third, we test the B<length=E<gt>>[I<M>,] variant.  For sizing
guidance in [I<S>..I<N>], the expected mean of the
distribution is given by the formula in the helper
function C<clipped_triangle_mean>(I<M>,I<S>,I<N>).
(Note that when I<M>=0 this case is equivalent to the first case.)

=cut

{
    for my $s (0,1,2) {
        for ([0,5],[1,5],[4,5],[5,10]) {
            my ($m,$n) = @$_;
            my $gstr = "List(Unit('x'),length=>[$m,])";
            my $gen  = eval $gstr;
            dist_mean_ok("$gstr elem length under sizing [$s..$n]",
                         $gen, [($s..$n)x($tsize/$n)],
                         sub { scalar @{$_[0]} },
                         clipped_triangle_mean($m,$s,$n));
        }
    }
}


=pod

Fourth, we test the B<length=E<gt>>[I<M>,I<N>] variant.  The
expected mean generated list length is (I<M>+I<N>)/2, regardless
of sizing guidance (which should be ignored in this case).

=cut

for (0..3) {
    $_ *= 10;
    my ($m,$n) = ($_,$_+9);
    my $gstr = "List(Unit('x'),length=>[$m,$n])";
    my $gen  = eval $gstr;
    dist_mean_ok("$gstr elem length",
                 $gen, [0..$tsize],
                 sub { scalar @{$_[0]} }, ($m+$n)/2 );
}


=pod

Fifth, we check to see if List's pre-flight checks catch common
problems.

=cut

like( eval { List(Int,length=>-1) } || $@,
      qr/length.*< 0/,
      "pre-flight: List(length=>-1) caught"
);

like( eval { List(Int,length=>[-1]) } || $@,
      qr/length.*< 0/,
      "pre-flight: List(length=>[-1,]) caught"
);

like( eval { List(Int,length=>[-1,0]) } || $@,
      qr/length.*invalid/,
      "pre-flight: List(length=>[-1,0]) caught"
);

like( eval { List(Int,length=>[1,0]) } || $@,
      qr/length.*invalid/,
      "pre-flight: List(length=>[1,0]) caught"
);

for ("[]", "[0,1,2]", "{1=>1}") {
    like( eval "List(Int,length=>$_)" || $@,
          qr/length spec.*bad/,
          "pre-flight: List(length=>$_) caught"
    );
}


#==============================================================================

=pod

=head2 String

We consider four test cases to determine whether String respects its
B<length> modifier.  These test cases are nearly identical to the four
cases for the List generator.  Because String is built on List, these
tests are mostly redundant.  However, it is a good idea to have them
anyway because it frees us to change the implementation.

First, we test the default string generation method, where string
length is constrained only by the sizing guidance.  For sizing
guidance in [1..I<N>], the expected mean generated string length is
(1+I<N>)/4.

=cut

{
    my $gstr = "String()";
    my $gen  = eval $gstr;
    for (1,5,10,25) {
        dist_mean_ok( "$gstr length under sizing [1..$_]",
                      $gen, [(1..$_)x($tsize/$_)],
                      sub { length $_[0] }, (1+$_)/4 );
    }
}

=pod

Second, we test the B<length=E<gt>>I<N> variant.  It should
generate strings whose length always equals I<N>.

=cut

{
    for my $len (0..3) {
        my $gstr = "String(charset=>'x',length=>$len)";
        my $gen  = eval $gstr;
        my @vals = map {$gen->generate($_)} 1..$tsize;
        is( scalar ( grep { $_ eq "x"x$len } @vals ), $tsize,
            "All strings from $gstr are '" . ("x"x$len) . "'" );
    }
}

=pod

Third, we test the B<length=E<gt>>[I<M>,] variant.  For sizing
guidance in [I<S>..I<N>] we have the expected mean of the
distribution is given by the formula in the helper function
C<clipped_triangle_mean>(I<M>,I<S>,I<N>).
(Note that when I<M>=0, this test case is equivalent to the first.)

=cut

{
    for my $s (0,1,2) {
        for ([0,5],[1,5],[4,5],[5,10]) {
            my ($m,$n) = @$_;
            my $gstr = "String(length=>[$m,])";
            my $gen  = eval $gstr;
            dist_mean_ok("$gstr length under sizing [$s..$n]",
                         $gen, [($s..$n)x($tsize/$n)],
                         sub { length $_[0] },
                         clipped_triangle_mean($m,$s,$n));
        }
    }
}

=pod

Fourth, we test the B<length=E<gt>>[I<M>,I<N>] variant.  The
expected mean generated string length is (I<M>+I<N>)/2, regardless
of sizing guidance (which should be ignored in this case).

=cut

for (0..3) {
    $_ *= 10;
    my ($m,$n) = ($_,$_+9);
    my $gstr = "String(length=>[$m,$n])";
    my $gen  = eval $gstr;
    dist_mean_ok("$gstr elem length",
                 $gen, [0..$tsize],
                 sub { length $_[0] }, ($m+$n)/2 );
}


#==============================================================================

=pod

=head2 Unit

The Unit generator is simple and always returns the same value.
So we test it with three values: "a", 1, and 0.334.

=cut

for (qw|"a" 1 0.334|) {
    my $v = eval $_;
    ok(Unit($v)->generate eq $v, "Unit($_)->generate eq $_");
}





#==============================================================================
#==============================================================================
#==============================================================================

=head1 Combinator tests

Here we test the combinators.  We perform the following tests. 

=cut

#==============================================================================

=head2 Frequency

We provide two tests of the Frequency combinator.  First, we make
sure that when all of the frequencies are identical the resulting
distribution is complete and uniform.  In effect, Frequency behaves
like Elements for this case.

=cut

for ([0..9],["a".."j"])
{
    my $g = Frequency( map {[1,Unit($_)]} @$_ );
    complete_and_uniform_ok($g, "Frequency(all freqs = 1, @$_)", $_);
}

=pod

Second, we test that the frequencies are actually respected.  When a
sub-generator has a zero frequency, it should never be selected.  We
test this by creating a "yes" generator with frequency 1 and a "no"
generator with frequency 0.  We make sure that the combined
Frequency generator generates only "yes" values.  We run two variants
of this test, one for each ordering of the two sub-generators.

=cut

for ('([[0,Unit("no")],[1,Unit("yes")]])',
     '([[1,Unit("yes")],[0,Unit("no")]])')
{
    my $g = Frequency( @{eval $_} );
    my @yesses = grep { $_ eq "yes" } map {$g->generate} 1..1000;
    is(scalar @yesses, 1000, "Frequency$_ generates only 'yes'");
}

=pod

Third, we check to make sure the pre-flight checks catch bad arguments.

=cut 

like( eval { Frequency() } || $@,
      qr/at least one frequency/,
      "pre-flight: Frequency() caught"
);

like( eval { Frequency([0,Bool]) } || $@,
      qr/at least one frequency.*greater than zero/,
      "pre-flight: Frequency([0,Bool]) caught"
);

like( eval { Frequency([1,Bool],[-1,Bool]) } || $@,
      qr/non-negative/,
      "pre-flight: Frequency([1,Bool],[-1,Bool]) caught"
);



#==============================================================================

=pod

=head2 Paste

To test the Paste generator, we create six Unit generators that
return, respectively, the values "a".."f".  Then we combine them in
two ways via Paste combinators.  The first does not use glue and
thus should always generate "abcdef".  The second uses the glue "-"
and thus should always generate "a-b-c-d-e-f".

=cut

{
    my @gens = map {Unit($_)} "a".."f";
    is(Paste(@gens)->generate, "abcdef", "Paste w/o glue as expected");
    is(Paste(@gens,glue=>'-')->generate, "a-b-c-d-e-f",
       "Paste w/ glue as expected");
}

=pod

We also test to see that Paste handles Lists properly.  It should
concatenate the elements of all Lists and then paste them together
with the other arguments.

=cut

{
    my $lgen0 = List( Unit(1), length=>0 );
    my $lgen4 = List( Unit(1), length=>4 );
    is(Paste($lgen0)->generate(5), "", "Paste([empty]) => empty str");
    is(Paste($lgen4)->generate(5), "1111",
       "Paste([1,1,1,1]) => '1111'");
    is(Paste(Unit(0),$lgen0,Unit(2))->generate(5), "02",
       "Paste(0,[],2) => '02'");
    is(Paste(Unit(0),$lgen4,Unit(2))->generate(5), "011112",
       "Paste(0,[1,1,1,1],2) => '011112'");
}

#==============================================================================

=pod

=head2 Sized

We run two tests for the Sized combinator.  First, we apply the
constant-sizing C<Sized{1}> combinator to a sized-Int generator
over the range[-1,100].  If the combinator works properly,
the sizing guidance passed to the Int generator will always be
one, effectively clipping its range to [-1,1].  Thus we
test that the mean of the resulting distribution is 0.

=cut

{
    # const sizing of 1 should clip range to [-1,1];
    # thus, w/ uniform distribution, mean = 0

    my $gstr = 'Sized{1}(Int(sized=>1,range=>[-1,100]))';
    my $gen  = eval $gstr;
    dist_mean_ok($gstr, $gen, [1..200],sub{$_[0]}, 0);
}

=pod

Second, we apply a "size-halving" combinator C<Sized{$_[0]/2}>
to the same Int generator as before and draw values from
the combined generator for sizing values ranging from [1..200].
We expect the mean of the distribution of generated values
should be equal to (-1 + 100) / 4.

=cut

{
    # halving sizing should clip range to [-1,h] where h varies from
    # [1/2,100] linearly; thus dist forms a triangle w/ peak height at
    # 200/2 = 100 and has mean of (-1 + 100) / 4 = 24.75.

    my $gstr = 'Sized{$_[0]/2}(Int(sized=>1,range=>[-1,100]))';
    my $gen  = eval $gstr;
    dist_mean_ok($gstr, $gen, [1..200],sub{$_[0]}, (-1 + 100) / 4);
}


#==============================================================================

=pod

=head2 Each

The Each combinator is just a wrapper around List, so the tests
for it are simple.

=cut

for ( 'Each(Unit(1),Unit(2),Unit(3))' )
{
    my $g = eval $_;
    is_deeply( $g->generate(1), [1,2,3],
               "$_ generates [1,2,3]" );
    
}

#==============================================================================

=pod

=head2 Apply

Apply, in turn, is built upon Each, so we just make sure that
it gets its own additional functionality right.

=cut

for ( 'Apply(sub{join"/",@_},Unit(1),Unit(2),Unit(3))' )
{
    my $g = eval $_;
    is( $g->generate(1), "1/2/3", "$_ generates 1/2/3" );
    
}

#==============================================================================

=pod

=head2 Map

Map is also built upon Each.  Again, we just make sure it
adds the correct twist.

=cut

for ( ['(Map {"x" x $_[0]} Unit(1),Unit(2))', '["x","xx"]'] )
{
    my ($gstr, $expected) = @$_;
    my $g = eval $gstr || die $@;
    is_deeply( $g->generate(1), eval $expected, "$gstr generates $expected" );
}

#==============================================================================

=pod

=head2 Concat

Testing Concat is straightforward.  We just feed it a few
list generators and make sure it returns the right thing.

=cut

for ( ['Concat', '[]']
    , ['Concat(List(Int,length=>0))', '[]']
    , ['Concat(Unit("a"))', '["a"]']
    , ['Concat(Unit("a"),List(Int,length=>0))', '["a"]']
    , ['Concat(List(Int,length=>0))', '[]']
    , ['Concat(List(Unit([1]),length=>1))', '[[1]]']
    , ['Concat(List(Unit(1),length=>2))', '[1,1]']
    , ['Concat(List(Unit(1),length=>2),List(Unit([2]),length=>1))'
      ,'[1,1,[2]]']
     )
{
    my ($gstr, $expected) = @$_;
    my $g = eval $gstr || die $@;
    is_deeply( $g->generate(1), eval $expected, "$gstr generates $expected" );
}


=cut

#==============================================================================

=pod

=head2 Flatten

Testing Flatten is like Concat, except here we must make sure
that the resulting list does not contain any other lists.

=cut

for ( ['Flatten', '[]']
    , ['Flatten(Unit([[[[[[[]]]]]]]))', '[]']
    , ['Flatten(Unit("a"))', '["a"]']
    , ['Flatten(Unit("a"),List(Int,length=>0))', '["a"]']
    , ['Flatten(List(Int,length=>0))', '[]']
    , ['Flatten(List(Unit([9]),length=>1))', '[9]']
    , ['Flatten(List(Unit(9),length=>2))', '[9,9]']
    , ['Flatten(List(Unit(9),length=>2),List(Unit([2]),length=>1))'
      ,'[9,9,2]']
     )
{
    my ($gstr, $expected) = @$_;
    my $g = eval $gstr || die $@;
    is_deeply( $g->generate(1), eval $expected, "$gstr generates $expected" );
}


=cut


#==============================================================================

=pod

=head2 ConcatMap

Testing ConcatMap is like testing Concat and Map together.  (Who
would have guessed?)

=cut

for ( ['ConcatMap{}', '[]']
    , ['ConcatMap{1}Unit(2)', '[1]']
    , ['ConcatMap{[1]}Unit(2)', '[1]']
    , ['ConcatMap{[@_]}Each(Unit(2),Unit(3))', '[[2,3]]']
    , ['ConcatMap{[@_]}Unit(2),Unit(3)', '[2,3]']
    , ['ConcatMap{my($a)=@_;$a%2?[$a]:[]}Unit(1),Unit(2),Unit(3)', '[1,3]']
    )
{
    my ($gstr, $expected) = @$_;
    my $g = eval $gstr || die $@;
    is_deeply( $g->generate(1), eval $expected, "$gstr generates $expected" );
}


#==============================================================================

=pod

=head2 FlattenMap

Can you see where this is going?  FlattenMap is just like Flatten
and Map, together as best friends.

=cut

for ( ['FlattenMap{}', '[]']
    , ['FlattenMap{9}Unit(2)', '[9]']
    , ['FlattenMap{[8]}Unit(2)', '[8]']
    , ['FlattenMap{[[7]]}Unit(2)', '[7]']
    , ['FlattenMap{[@_]}Each(Unit(2),Unit(3))', '[2,3]']
    , ['FlattenMap{[@_]}Unit(2),Unit([3])', '[2,3]']
    , ['FlattenMap{[[[[[9]]]]]}Unit(2),Unit([3])', '[9,9]']
    , ['FlattenMap{my($a)=@_;$a%2?[$a]:[]}Unit(9),Unit(2),Unit(3)', '[9,3]']
    )
{
    my ($gstr, $expected) = @$_;
    my $g = eval $gstr || die $@;
    is_deeply( $g->generate(1), eval $expected, "$gstr generates $expected" );
}




=cut


#==============================================================================
#==============================================================================
#==============================================================================
# More helpers

=head1 Helper functions

The test suite relies upon a few helper functions.

=head2 sample_distribution_z_score

This function takes an expected mean and a set of data
values.  It analyzes the data set to determine its mean M and standard
deviation.  Then it computes a z-score for the hypothesis that M is
equal to the expected mean.  The return value is the z-score.

=cut

sub sample_distribution_z_score {
    my ($expected_mean, $data) = @_;
    my ($sum, $ssq, $count) = (0, 0, scalar @$data);
    $sum += $_, $ssq += $_**2 for @$data;
    my $mean     = $sum/$count;
    my $numer    = $ssq + $count * $mean**2 - 2 * $mean * $sum;
    my $s2       = $numer / ($count - 1);
    my $stdev    = sqrt $s2;
    my $sampdev  = $stdev / sqrt($count);
    my $z_score  = ($mean - $expected_mean) / $sampdev;
    return $z_score;
}

=pod

=head2 dist_mean_ok

This function is used to determine if the mean of 
the distribution of values returned by a generator is
equal to the expected mean.  The generator is asked to
generate one value for each element of sizing guidance
given.  The resulting values are passed through the given
$numerizer function to convert them into numbers (useful
if you are testing a String or Char generator).  The
name you are giving to the whole mean test should be passed
in $name.  This is passed to the Test::More C<cmp_ok> function
which records the result of the test.

=cut

sub dist_mean_ok {
    my ($name, $gen, $sizes, $numerizer, $expected_mean) = @_;
    my @data = map { $numerizer->($gen->generate($_)) } @$sizes;
    my $z = sample_distribution_z_score($expected_mean, \@data);
    cmp_ok(abs($z), '<', 3.89,  # w/in 99.99% confidence interval
       sprintf "$name dist mean is $expected_mean (z-score = %.2f)", $z);
}

=pod

=head2 complete_and_uniform_ok

This function determines whether the given generator $g
returns values that are uniformly distributed across the complete
range of values it is supposed to cover.  In order for this test to
function properly the generator must be designed to select from
among ten distinct values.  (E.g., Int(range=>[0,9]) is fine but not
Int(range=>[1,100]).)  The test draws 10,000 output values from the
generator and then ensures that all ten @$expected_values are
represented in the output and that all ten were selected with
equal probability.  The result of the test is reported
via the Test::More C<ok> function.

=cut

sub complete_and_uniform_ok {
    my ($g, $dist_name, $expected_values) = @_;
    die unless @$expected_values == 10;  
    my %counts;
    $counts{$_}++ for map { $g->generate } 1..10_000;
    my $test = 0; # assume failure
    foreach my $count (values %counts) {
        # if the distribution is uniform, the following
        # test will succeed with 99.997 percent probability
        $test = 875 <= $count && $count <= 1125;
        last unless $test;
    }
    ok($test && grep(defined,@counts{@$expected_values}) == 10,
       "$dist_name is complete and uniformly distributed");
}


=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 COPYRIGHT and LICENSE

Copyright (C) 2004 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

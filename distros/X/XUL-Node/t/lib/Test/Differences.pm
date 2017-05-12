package Test::Differences;

=head1 NAME

Test::Differences - Test strings and data structures and show differences if not ok

=head1 SYNOPSIS

   use Test;    ## Or use Test::More
   use Test::Differences;

   eq_or_diff $got,  "a\nb\nc\n",   "testing strings";
   eq_or_diff \@got, [qw( a b c )], "testing arrays";

   ## Passing options:
   eq_or_diff $got, $expected, $name, { context => 300 };  ## options

   ## Using with DBI-like data structures

   use DBI;

   ... open connection & prepare statement and @expected_... here...
   
   eq_or_diff $sth->fetchall_arrayref, \@expected_arrays  "testing DBI arrays";
   eq_or_diff $sth->fetchall_hashref,  \@expected_hashes, "testing DBI hashes";

   ## To force textual or data line numbering (text lines are numbered 1..):
   eq_or_diff_text ...;
   eq_or_diff_data ...;

=head1 DESCRIPTION

When the code you're testing returns multiple lines, records or data
structures and they're just plain wrong, an equivalent to the Unix
C<diff> utility may be just what's needed.  Here's output from an
example test script that checks two text documents and then two
(trivial) data structures:

 t/99example....1..3
 not ok 1 - differences in text
 #     Failed test ((eval 2) at line 14)
 #     +---+----------------+----------------+
 #     | Ln|Got             |Expected        |
 #     +---+----------------+----------------+
 #     |  1|this is line 1  |this is line 1  |
 #     *  2|this is line 2  |this is line b  *
 #     |  3|this is line 3  |this is line 3  |
 #     +---+----------------+----------------+
 not ok 2 - differences in whitespace
 #     Failed test ((eval 2) at line 20)
 #     +---+------------------+------------------+
 #     | Ln|Got               |Expected          |
 #     +---+------------------+------------------+
 #     |  1|        indented  |        indented  |
 #     *  2|        indented  |\tindented        *
 #     |  3|        indented  |        indented  |
 #     +---+------------------+------------------+
 not ok 3
 #     Failed test ((eval 2) at line 22)
 #     +----+-------------------------------------+----------------------------+
 #     | Elt|Got                                  |Expected                    |
 #     +----+-------------------------------------+----------------------------+
 #     *   0|bless( [                             |[                           *
 #     *   1|  'Move along, nothing to see here'  |  'Dry, humorless message'  *
 #     *   2|], 'Test::Builder' )                 |]                           *
 #     +----+-------------------------------------+----------------------------+
 # Looks like you failed 3 tests of 3.

eq_or_diff_...() compares two strings or (limited) data structures and
either emits an ok indication or a side-by-side diff.  Test::Differences
is designed to be used with Test.pm and with Test::Simple, Test::More,
and other Test::Builder based testing modules.  As the SYNOPSIS shows,
another testing module must be used as the basis for your test suite.

These functions assume that you are presenting it with "flat" records,
looking like:

   - scalars composed of record-per-line
   - arrays of scalars,
   - arrays of arrays of scalars,
   - arrays of hashes containing only scalars

All of these are flattened in to single strings which are then compared
for differences.  Differently data structures can be compared, as long
as they flatten identically.

All other data structures are run through Data::Dumper first.  This is a
bit dangerous, as some versions of perl shipped with Data::Dumpers that
could do the oddest things with unexpected, like core dump.  Only as of
5.8.0 does Data::Dumper sort hash keys, which is necessary for HASH
dumps to be fully predictable.  This will be changed when this bites
somebody or I get some free time.

C<eq_or_diff()> starts counting records at 0 unless you pass it two text
strings:

   eq_or_diff $a, $b;   ## First line is line number 1
   eq_or_diff @a, @b;   ## First element is element 0
   eq_or_diff $a, @b;   ## First line/element is element 0

If you want to force a first record number of 0, use C<eq_or_diff_data>.  If
you want to force a first record number of 1, use C<eq_or_diff_text>.  I chose
this over passing in an options hash because it's clearer and simpler this way.
YMMV.

=head1 OPTIONS

There is currently only one option: "context".  This allows you to
control the amount of context shown:

   eq_or_diff $got, $expected, $name, { context => 50000};

will show you lots and lots of context.  Normally, eq_or_diff() uses
some heuristics to determine whether to show 3 lines of context (like
a normal unified diff) or 25 lines (for 

=head1 Deploying Test::Differences

There are three basic ways of deploying Test::Differences requiring more or less
labor by you or your users.

=over

=item *

eval "use Test::Differences";

This is the easiest option.

If you want to detect the presence of Test::Differences on the fly, something
like the following code might do the trick for you:

    use Test qw( !ok );   ## get all syms *except* ok

    eval "use Test::Differences";
    use Data::Dumper;

    sub ok {
        goto &eq_or_diff if defined &eq_or_diff && @_ > 1;
        @_ = map ref $_ ? Dumper( @_ ) : $_, @_;
        goto Test::&ok;
    }

    plan tests => 1;

    ok "a", "b";

=item *

PREREQ_PM => { .... "Test::Differences" => 0, ... }

This method will let CPAN and CPANPLUS users download it automatically.  It
will discomfit those users who choose/have to download all packages manually.

=item *

t/lib/Test/Differences.pm, t/lib/Text/Diff.pm, ...

By placing Test::Differences and it's prerequisites in the t/lib directory, you
avoid forcing your users to download the Test::Differences manually if they
aren't using CPAN or CPANPLUS.

If you put a C<use lib "t/lib";> in the top of each test suite before the
C<use Test::Differences;>, C<make test> should work well.

You might want to check once in a while for new Test::Differences releases
if you do this.



=back


=head1 LIMITATIONS

This module "mixes in" with Test.pm or any of the test libraries based on
Test::Builder (Test::Simple, Test::More, etc).  It does this by 
peeking to see whether Test.pm or Test/Builder.pm is in %INC, so if you are
not using one of those, it will print a warning and play dumb by not emitting
test numbers (or incrementing them).  If you are using one of these, it
should interoperate nicely.

Uses Data::Dumper for complex data structures (like hashes :), which can lead
to some problems on older perls.

Exports all 3 functions by default (and by design).  Use

    use Test::Differences ();

to suppress this behavior if you don't like the namespace pollution.

This module will not override functions like ok(), is(), is_deeply(), etc.  If
it did, then you could C<eval "use Test::Differences qw( is_deeply );"> to get
automatic upgrading to diffing behaviors without the C<sub my_ok> shown above.
Test::Differences intentionally does not provide this behavior because this
would mean that Test::Differences would need to emulate every popular test
module out there, which would require far more coding and maintenance that I'm
willing to do.  Use the eval and my_ok deployment shown above if you want some
level of automation.

=cut

$VERSION = 0.47;

use Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( eq_or_diff eq_or_diff_text eq_or_diff_data );

use strict;

use Carp;
use Text::Diff;

sub _isnt_ARRAY_of_scalars {
    return 1 if ref ne "ARRAY";
    return scalar grep ref, @$_;
}


sub _isnt_HASH_of_scalars {
    return 1 if ref ne "HASH";
    return scalar grep ref, keys %$_;
}

use constant ARRAY_of_scalars           => "ARRAY of scalars";
use constant ARRAY_of_ARRAYs_of_scalars => "ARRAY of ARRAYs of scalars";
use constant ARRAY_of_HASHes_of_scalars => "ARRAY of HASHes of scalars";


sub _grok_type {
    local $_ = shift if @_;
    return "SCALAR" unless ref ;
    if ( ref eq "ARRAY" ) {
        return undef unless @$_;
        return ARRAY_of_scalars unless 
            _isnt_ARRAY_of_scalars;
        return ARRAY_of_ARRAYs_of_scalars 
            unless grep _isnt_ARRAY_of_scalars, @$_;
        return ARRAY_of_HASHes_of_scalars
            unless grep _isnt_HASH_of_scalars, @$_;
        return 0;
    }
}


## Flatten any acceptable data structure in to an array of lines.
sub _flatten {
    my $type = shift;
    local $_ = shift if @_;

    return [ split /^/m ] unless ref;

    croak "Can't flatten $_" unless $type ;

    ## Copy the top level array so we don't trash the originals
    my @recs = @$_;

    if ( $type eq ARRAY_of_ARRAYs_of_scalars ) {
        ## Also copy the inner arrays if need be
        $_ = [ @$_ ] for @recs;
    }


    if ( $type eq ARRAY_of_HASHes_of_scalars ) {
        my %headings;
        for my $rec ( @recs ) {
            $headings{$_} = 1 for keys %$rec;
        }
        my @headings = sort keys %headings;

        ## Convert all hashes in to arrays.
        for my $rec ( @recs ) {
            $rec = [ map $rec->{$_}, @headings ],
        }

        unshift @recs, \@headings;

        $type = ARRAY_of_ARRAYs_of_scalars;
    }

    if ( $type eq ARRAY_of_ARRAYs_of_scalars ) {
        ## Convert undefs
        for my $rec ( @recs ) {
            for ( @$rec ) {
                $_ = "<undef>" unless defined;
            }
            $rec = join ",", @$rec;
        }
    }

    return \@recs;
}


sub _identify_callers_test_package_of_choice {
    ## This is called at each test in case Test::Differences was used before
    ## the base testing modules.
    ## First see if %INC tells us much of interest.
    my $has_builder_pm = grep $_ eq "Test/Builder.pm", keys %INC;
    my $has_test_pm    = grep $_ eq "Test.pm",         keys %INC;

    return "Test"          if $has_test_pm && ! $has_builder_pm;
    return "Test::Builder" if ! $has_test_pm && $has_builder_pm;

    if ( $has_test_pm && $has_builder_pm ) {
        ## TODO: Look in caller's namespace for hints.  For now, assume Builder.
        ## This should only ever be an issue if multiple test suites end
        ## up in memory at once.
        return "Test::Builder";
    }
}


my $warned_of_unknown_test_lib;

sub eq_or_diff_text { $_[3] = { data_type => "text" }; goto &eq_or_diff; }
sub eq_or_diff_data { $_[3] = { data_type => "data" }; goto &eq_or_diff; }

## This string is a cheat: it's used to see if the two arrays of values
## are identical.  The stringified values are joined using this joint
## and compared using eq.  This is a deep equality comparison for
## references and a shallow one for scalars.
my $joint = chr( 0 ) . "A" . chr( 1 );

sub eq_or_diff {
    my ( @vals, $name, $options );
    $options = pop if @_ > 2 && ref $_[-1];
    ( $vals[0], $vals[1], $name ) = @_;

    my $data_type;
    $data_type = $options->{data_type} if $options;
    $data_type ||= "text" unless ref $vals[0] || ref $vals[1];
    $data_type ||= "data";

    my @widths;

    my @types = map _grok_type, @vals;

    my $dump_it = !$types[0] || !$types[1];

    if ( $dump_it ) {
	require Data::Dumper;
	local $Data::Dumper::Indent    = 1;
	local $Data::Dumper::Sortkeys  = 1;
	local $Data::Dumper::Purity    = 0;
	local $Data::Dumper::Terse     = 1;
	local $Data::Dumper::Deepcopy  = 1;
	local $Data::Dumper::Quotekeys = 0;
        @vals = map 
	    [ split /^/, Data::Dumper::Dumper( $_ ) ],
	    @vals;
    }
    else {
	@vals = (
	    _flatten( $types[0], $vals[0] ),
	    _flatten( $types[1], $vals[1] )
	);
    }

    my $caller = caller;

    my $passed = join( $joint, @{$vals[0]} ) eq
                 join( $joint, @{$vals[1]} );

    my $diff;
    unless ( $passed ) {
        my $context;

        $context = $options->{context}
            if exists $options->{context};

        $context = $dump_it ? 2**31 : grep( @$_ > 25, @vals ) ? 3 : 25
            unless defined $context;

        confess "context must be an integer: '$context'\n"
            unless $context =~ /\A\d+\z/;

        $diff = diff @vals, {
            CONTEXT     => $context,
            STYLE       => "Table",
	    FILENAME_A  => "Got",
	    FILENAME_B  => "Expected",
            OFFSET_A    => $data_type eq "text" ? 1 : 0,
            OFFSET_B    => $data_type eq "text" ? 1 : 0,
            INDEX_LABEL => $data_type eq "text" ? "Ln" : "Elt",
        };
        chomp $diff;
        $diff .= "\n";
    }

    my $which = _identify_callers_test_package_of_choice;

    if ( $which eq "Test" ) {
        @_ = $passed 
            ? ( "", "", $name )
            : ( "\n$diff", "No differences", $name );
        goto &Test::ok;
    }
    elsif ( $which eq "Test::Builder" ) {
        my $test = Test::Builder->new;
        ## TODO: Call exported_to here?  May not need to because the caller
        ## should have imported something based on Test::Builder already.
        $test->ok( $passed, $name );
        $test->diag( $diff ) unless $passed;
    }
    else {
        unless ( $warned_of_unknown_test_lib ) {
            Carp::cluck
                "Can't identify test lib in use, doesn't seem to be Test.pm or Test::Builder based\n";
            $warned_of_unknown_test_lib = 1;
        }
        ## Play dumb and hope nobody notices the fool drooling in the corner
        if ( $passed ) {
            print "ok\n";
        }
        else {
            $diff =~ s/^/# /gm;
            print "not ok\n", $diff;
        }
    }
}


=head1 LIMITATIONS

Perls before 5.6.0 don't support characters > 255 at all, and 5.6.0
seems broken.  This means that you might get odd results using perl5.6.0
with unicode strings.

Relies on Data::Dumper (for now), which, prior to perl5.8, will not
always report hashes in the same order.  C< $Data::Dumper::SortKeys >
I<is> set to 1, so on more recent versions of Data::Dumper, this should
not occur.  Check CPAN to see if it's been peeled out of the main perl
distribution and backported.  Reported by Ilya Martynov
<ilya@martynov.org>, although the SortKeys "future perfect" workaround
has been set in anticipation of a new Data::Dumper for a while.  Note
that the two hashes should report the same here:

    not ok 5
    #     Failed test (t/ctrl/05-home.t at line 51)
    # +----+------------------------+----+------------------------+   
    # | Elt|Got                     | Elt|Expected                |   
    # +----+------------------------+----+------------------------+   
    # |   0|{                       |   0|{                       |   
    # |   1|  'password' => '',     |   1|  'password' => '',     |   
    # *   2|  'method' => 'login',  *    |                        |   
    # |   3|  'ctrl' => 'home',     |   2|  'ctrl' => 'home',     |   
    # |    |                        *   3|  'method' => 'login',  *   
    # |   4|  'email' => 'test'     |   4|  'email' => 'test'     |   
    # |   5|}                       |   5|}                       |   
    # +----+------------------------+----+------------------------+   

Data::Dumper also overlooks the difference between

    $a[0] = \$a[1];
    $a[1] = \$a[0];   # $a[0] = \$a[1]

and

    $x = \$y;
    $y = \$x;
    @a = ( $x, $y );  # $a[0] = \$y, not \$a[1]

The former involves two scalars, the latter 4: $x, $y, and @a[0,1].
This was carefully explained to me in words of two syllables or less by
Yves Orton <demerphq@hotmail.com>.  The plan to address this is to allow
you to select Data::Denter or some other module of your choice as an
option.

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 LICENSE

Copyright 2001 Barrie Slaymaker, All Rights Reserved.

You may use this software under the terms of the GNU public license, any
version, or the Artistic license.

=cut


1;

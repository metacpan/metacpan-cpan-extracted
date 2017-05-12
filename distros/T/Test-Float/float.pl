#!/usr/bin/perl

package float;

use 5.10.0;

use strict;
use warnings;

use Test::Float;
use File::Find;
use StupidMarkov;
use Acme::State 'float';
use Data::Dumper;
use IO::Handle;
use PPI;
# use autobox::Core;

# Todo:
#
# * actually get some sequence alignment stuff going!  merge chains intelligently
# * who.int world hunger test
# 
# Done:
# 
# * use PPI to break terms up rather than just breaking on whitespace.... 
# * use a user specified program as the starting point in the pool
# * let the user set genetic algorithm parameters
# * test to punish it for having too many comments... perhaps leave it off at first then suck it in during live demo
# * if we wind up with duplicates in the pool -- which *is* happening -- then kill dups or mutate them or something

=head1 NAME

float.pl - Genetic programming front-end using Test::Float, StupidMarkov, and PPI

=head1 SYNOPSIS
       
L<float.pl> is to L<Test::Float> as L<prove> is to L<Test::Harness>.
That is, L<float.pl> is a command line interface to L<Test::Float>.

  perl float.pl --help
  perl float.pl --learn /path/to/some/code
  perl float.pl --spew 20
  perl float.pl --code

WARNING!  In the process of assimulating existing code and creating semi-random permutations from it, this
script could easily come up with code that will ERASE YOUR DATA OR SEND INAPPROPRIATE PHOTOS TO YOUR INLAWS.

=head2 GLOSSARY

This has a number of parts.  It's useful to define them before getting into arguments and usage.
This also ships with a demo.

=over 1

=item L<Test::Float> -- hacked up L<Test::Harness> that understands floating point test results.

=item L<float.pl> -- this script; trains a Markov engine from code samples, generates semi-random random snippets, and applies a simple genetic programming algorithm using floating point test results as a fitness tests to the snippets

=item C<t/*> -- internal tests that have to pass before L<cpanm> or whatever will install L<Test::Float>; returns C<ok>/C<not ok>; uninteresting

=item C<fitness-t/*> -- genetic selection criteria fitness criteria tests that returning floating point values

=item C<fitness-t/goo.t> -- genetic selection criteria fitness tests that do some basic sanity checking such as looking for code that passes syntax check

=item C<fitness-t/logic.t> -- genetic selection critera fitness tests that inspect output on STDOUT; this test should be used as an example but otherwise REMOVED or ALTERED to be specific to test for whatever you want C<float.pl --code> to write code to do

=item C<goo.pl> -- the primary output of C<float.pl --code>; also the current member of the current generation of genetic-Markov code samples being tested by C<float.pl --code>; after C<float.pl --code> finishes, the specimen with the best test score is left in place as C<goo.pl>; the population of specimes exist primarily in memory

=item C<seq.pl> -- an example starting program to output a (kind of) Fibonacci sequence of numbers; it contaisn a bug (with a comment)

=back

C<seq.pl> and C<fitness-t/logic.pl>, as shipped, are part of a demonstration in automatic bug repair.
C<seq> attempts to compute (sort of) the Fibonacci sequence but contains a bug (with a comment marking it).
C<fitness-t/logic.pl> tests for the correct output of the first three in the (kind of, simplified) Fibonacci sequence.
C<float.pl --code --from seq.pl> should find and fix the bug in C<seq.pl>, leaving a corrected version of C<seq.pl> as C<goo.pl>.
C<float.pl> is non-deterministic, so depending on luck, number of generations, and other parameters, may or may not arrive at a solution.

=head2 ARGUMENTS

Here are the arguments:

        --learn <dir>         -- feed .pl and .pm files in a directory into the Markov engine
        --spew <n>            -- (test) output n successive tokens from the Markov engine
        --eval <str>          -- (test) in-context eval; changes to the corpus are saved on exit
        --code                -- write a program to satisify tests

        --code options:

            --chainlength <n> -- number of tokens (program size) in each semi-randomly generated initial specimen OR:
            --from <fn.pl>    -- file to start with; implies learning from it as well as mutating it directly

            --generations <n> -- how many generations to run, max (stops early on a perfect score)

            --keep <n>        -- how many top performers of the previous generation to include in each new generation
            --breed <n>       -- how many children of the top performers to include in each new generation
            --mutate <n>      -- how many mutated children of the top performers to include in each new generation
            --new <n>         -- how many brand new, semi-random specimen to include in each new generation

L<Acme::State> is used to preserve program state between runs.
If you tell it to C<--learn> a directory, it'll remember everything it has seen in there until you remove your
C<~/float.pl.state> file.
This allows you to learn in one invocation and then generate code in another invocation.

C<--from> uses a program you provide as one of the first generation of specimens.
This is what you want if you're using L<Test::Float> to try to fix a bug for you in existing code rather than writing code from scratch.

C<--code> tells the thing to try to contrive a program that passes tests with the best score possible.

C<--code> requires a unit test that returns floating point values between 0 and 1 (inclusive) rather than C<ok> and C<not ok>.
Genetic code specimens that do better are favored for preservation and breeding for next generations.
Creating tests that describe the code you want written is critical.
These live in the C<< fitness-t/ >> directory.

C<--code> can be used one of two basic ways.  
With a C<--from> argument, it'll start from a pre-written script.
It'll include an exact copy of that script in each generation, train the Markov engine from it, and generate an itinitial random population
of similar number of tokens as it.

Without C<--form>, the initial random population are of C<--chainlength> tokens each, or 20 by default.

Currently, you need to C<cd> into the C<< Test-Float-xx >> directory to use the C<< --code >> operation, or else you need to
copy or create a C<< fitness-t/ >> directory with floating point tests.
Either way, you need the C<< fitness-t/ >> directory and fitness tests.

Two fitness test files ship with this thing, both in the C<fitness-t/> directory.
The first fitness test, C<fitness-t/goo.t>, has tests to see that the program is at least a reasonable length long, 
passes syntax checks, isn't composed of too many comments, and a few other similar things.
You may wish to keep this script as is, modify, or extend it.

The other fitness test, C<fitness-t/logic.t> should be used as an example or demonstration only and then commented out, removed, or completely rewritten and adapted
to the purpose at hand.
As shipped, it tests for the first three numbers (kind of) in the Fibonacci sequence.

Numerous times each generation -- once for each specimen -- C<goo.pl> is written out and the tests in C<< fitness-t/ >> are run on it.

After C<< --code >> mode finishes running, the best contender will be left in place in C<< goo.pl >>.

=head1 BUGS

WARNING!  In the process of assimulating existing code and creating semi-random permutations from it, this
script could easily come up with code that will ERASE YOUR DATA OR SEND INAPPROPRIATE PHOTOS TO YOUR INLAWS.

I'm serious.
This thing generates quasi-random code and then RUNS IT.  This is STUPID.

In fact, this thing is STUPID in general -- nearly as a stupid as your average ASU undergrad.
Far more intelligent genetic programming systems exist.

This program should be in L<Acme::>.

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Scott Walters

This library is not free software; you can redistribute it and/or modify
it provided you take my name off of it and accept or disclaim all responsibility for the horrible things it will inevitably do.
By using this program, you agree not to use this program.

THIS PROGRAM MAKES NO WARRANTY OF FITNESS FOR ANY PURPOSE, INCLUDING THE PURPOSE OF NOT DELETING ALL OF YOUR DATA.
This program is stupid and if you run it, so are you.

Do not email me and ask me to clarify the copyright license so you may include it in Debian.
Let me save you the trouble:  you may NOT include this program in Debian.  
You can include L<Test::Float> itself, but you may not include this program.

=cut

#
#
#

sub opt ($) { scalar grep $_ eq $_[0], @ARGV }
sub arg ($) { my $opt = shift; my $i=1; while($i<=$#ARGV) { return $ARGV[$i] if $ARGV[$i-1] eq $opt; $i++; } }

our $markov ||= StupidMarkov->new;

if(arg '--chainlength' and arg '--from') {
    die "specify --chainlength or --from but not both";
}

my $chain_length = arg '--chainlength';
my $from_program = arg '--from';

my $generations = arg '--generations' || 30;

my $breed = arg '--breed' // 10;
my $keep = arg '--keep' // 10;
my $mutate = arg '--mutate' // 10;
my $new = arg '--new' // 10;

warn "breed: $breed keep: $keep mutate: $mutate new: $new";

if(opt '--test') {

    @ARGV = glob "fitness-t/*.t";
    Test::Float::test_harness(1, "blib/lib", "blib/arch");

} elsif (opt '--learn') {

    my $path = shift @ARGV or die "usage: $0 learn /path/";
    File::Find::find(sub { learn($File::Find::name) if m/\.pl$/ or m/\.pm$/ }, $path);

} elsif (opt '--spew') {

    my $num_terms = arg '--spew' or die;

    print float::Chain->new->random($num_terms)->to_string, "\n";
    STDOUT->flush;

} elsif (opt '--eval') {

    eval $ARGV[0];

} elsif (opt '--code') {

    code();

} else {
    print <<EOF;
        $0:
        --test                -- invoke the test harness, similar to `make test` but with Test::Float thrown in
        --learn <dir>         -- feed .pl and .pm files in a directory into the Markov engine
        --spew <n>            -- (test) output n successive tokens from the Markov engine
        --eval <str>          -- (test) in-context eval; changes to the corpus are saved on exit
        --code                -- write a program to satisify tests

        --code options:

            --chainlength <n> -- number of tokens (program size) in each semi-randomly generated initial specimen
            --from <fn.pl>    -- file to start with

            --generations <n> -- how many generations to run, max (stops early on a perfect score)

            --keep <n>        -- how many top performers of the previous generation to include in each new generation
            --breed <n>       -- how many children of the top performers to include in each new generation
            --mutate <n>      -- how many mutated children of the top performers to include in each new generation
            --new <n>         -- how many new, randomly created specimen to introduce each generation


    typical usage:

        perl float.pl --learn /path/to/some/code
        perl float.pl --spew 20
        perl float.pl --code --from someprogram.pl

EOF
}

sub learn {

    my $fn = shift;

    $markov->add_item("\n");
    $markov->add_item("    ");

    # open my $fh, '<', $fn or do { warn "$fn: $!"; return; };
    # for my $token ( split /\s+/, join '', readline $fh ) {
    #     $markov->add_item($token);
    # }

    my $doc = PPI::Document->new($fn) or do {
        warn "PPI failed on: ``$fn'': " . PPI::Document->errstr;
        return;
    };

    for my $token (reguritate($doc)) {
         $markov->add_item($token);
    }

}

sub reguritate {
    # regurgitate the source of a document from its PPI tree as a list of individual tokens
    my @tokens = ();
    my $doc = shift;
    my $reguritate; $reguritate = sub {
        my $doc = shift;
        my @children = $doc->can('children') ? $doc->children : ();
        my ($brace_start, $brace_stop) = ('', '');
        if($doc->can('braces')) {
            my $braces = $doc->braces;
            ($brace_start, $brace_stop) = split //, $braces;
        }
        push @tokens, $brace_start;
        if(! @children) {
            push @tokens, $doc->content;
        } else {
            for my $child (@children) {
                $reguritate->($child);
            }
        }
        push @tokens, $brace_stop;
    };
    $reguritate->($doc);
    return grep { length $_ } @tokens;
}

sub code {

    # attempt to write code

    # initialize first ancestors

    my @pool;

    my $initial_pool_size = $breed + $keep + $mutate + $new;   # initial pool the same size as we wind up with from breeding, mutating, keeping, and new

    my $glorified_elder;

    if( $from_program ) {

        # initialize from a file
        # ideally, the sample program would score better on the tests than random programs, but just in case not, do this $glorified_elder thing
        # the rest of the population is random programs of the same number of terms
        # this initialization method would probably do better with a good --mutate rate

        learn($from_program);
        my $doc = PPI::Document->new($from_program) or do {
            die "PPI failed on: ``$from_program'': " . PPI::Document->errstr;
        };
        $glorified_elder = float::Chain->new->from_PPI($doc);
        push @pool, $glorified_elder;
        my $num_terms = $glorified_elder->size;
        for ( 2 .. $initial_pool_size ) {
            push @pool, float::Chain->new->random($num_terms);
        }

    } else {

        $chain_length ||= 20;

        for ( 1 .. $initial_pool_size ) {
            push @pool, float::Chain->new->random($chain_length);
        }

    }

    # run some generations

    my @scores;
    
    for my $generation (1..$generations) {

        # find the most fit  -- compute_scores() updates the score field and sorts them descending on that

        @pool = compute_scores(\@pool);

        if( $pool[0]->score == 1.0 ) {
            warn "a specimen scored a perfect score -- stopping early";
            last;
        }

        # next generation is a mix of the most fit of the previous generation, mutated copies of members of the previous generation, and children

        print "============== generation $generation\n"; 
        # for my $chain (@pool) { print $chain->score, ":\n", $chain->to_string, "\n"; }
        for my $chain (@pool) { print $chain->score, "\n"; }
        # for my $chain (@pool) { our $sn; open my $fh, '>', sprintf "tmp/t%08d.pl", ++$sn or die $!; $fh->print("# " . $chain->score, "\n", $chain->to_string, "\n"); }

        my @new_pool;

        # if we read an example program from a file, never kill that original specimen

        push @new_pool, $glorified_elder if $glorified_elder;

        # next generation keeps some of the best of the last pool

        if($keep) {
            push @new_pool, @pool[0 .. $keep-1];
        }

        # take some of the top scorers (weighted) and breed them

        my $pick_one = sub {
            # my $s1 = $pool[0];
            #for my $num ( 0 .. $#pool ) {
            #    $s1 = $pool[$num] if rand($pool[$num]->score) > rand($s1->score);
            #}
            # $s1;
            my $winner = $pool[int rand int rand @pool];
            warn "pick_one ``$_[0]''picked one with score: " . $winner->score;
            $winner;
        };

        for ( 1 .. $breed ) {
            my $s1 = $pick_one->('breed1');
            my $s2 = $pick_one->('breed2');
            redo if $s1 == $s2;
            push @new_pool, $s1->breed($s2);
        }

        # then it gets mutated children of some of the top performers

        for ( 1 .. $mutate ) {
            my $s1 = $pick_one->('mutate');
            push @new_pool, $s1->clone->mutate;
            # my $s1 = $pick_one->('mutate1');
            # my $s2 = $pick_one->('mutate2');
            # redo if $s1 == $s2;
            # push @new_pool, $s1->breed($s2)->mutate;
            # push @new_pool, $s1->breed($s2)->mutate;
            # warn "mutate!\nONE:\n" . $s1->to_string . "\nTWO:\n" . $s2->to_string . "\nOUTPUT:\n" . $new_pool[-1]->to_string . "\n";
        }

        # then it gets some random-ish new ones

        for ( 1 .. $new ) {
            my $size = $pick_one->('new-random-size')->size;
            push @new_pool, float::Chain->new->random($size);
        }

        # get rid of exact duplicates

        my %unique;
        for my $chain (@new_pool) {
            $unique{$chain->to_string} = $chain;
        }
        @new_pool = values %unique;

        # copy @new_pool back over @pool

        warn "new pool size is " . @new_pool;        

        @pool = @new_pool;

    }

    # find the top performer after those generations and leave it in place 
    # compute_score() has a sideeffect of leaving that file so we compute scores on exactly one item

    @pool = compute_scores(\@pool);
    compute_scores([ $pool[0] ]);

    print "winner: " . $pool[0]->score . "\n" . $pool[0]->to_string;

}

sub compute_scores {

    my @pool = @{ shift or die };

    for my $chain (@pool) {

        # write the stringified chain to the file and run the tests on it

        open my $fh, '>', 'goo.pl' or die $!;
        $fh->print($chain->to_string, "\n");
        $fh->close;
    
        @ARGV = glob "fitness-t/*.t" or die "nothing in t/*.t... where's the fitness test?";
        $chain->score = Test::Float::test_harness(0, "blib/lib", "blib/arch");
        # warn "computed a score: ". $chain->score;

    }

    @pool = sort { $b->score <=> $a->score } @pool;

    return wantarray ? @pool : \@pool;

}

#
#
#

package float::Chain;

# use Data::Alias; # broken in 5.12 currently

sub new { bless { }, $_[0] }

sub score :lvalue { $_[0]->{score} }

sub clone { 
    my $self = shift;
    my $new = ref($self)->new;
    $new->{chain} = [ @{ $self->{chain} } ];
    return $new;
}

sub random {

    my $self = shift;
    my $num_terms = shift || 50;

    my $chain = $self->{chain} ||= [ ];

    my @states = keys %{ $markov->{_probabilities} } or die "markov not trained";
    $markov->{_state} = $states[int rand @states];

    for (my $i = 0; $i < $num_terms; $i++ ) {
        $chain->[$i] = $markov->get_next_item;
        # $num_terms++ if $chain[$i] =~ m/^\s+$/; # XXX highly experimental... don't count whitespace
    }

    $self;

}

sub from_PPI {

    my $self = shift;
    my $doc = shift;

    my $chain = $self->{chain} ||= [ ];

    my $i = 0;
    for my $token (float::reguritate($doc)) {
         $chain->[$i++] = $token;
    }

    $self;

}

sub to_string {

    my $self = shift;
    my $chain = $self->{chain} or die;
    my $str = '';

    for my $term (@$chain) {
        $str .= $term;
        $str .= $term =~ m/;$/ ? "\n" : " ";
    }

    return $str;

}

sub size {
    my $self = shift;
    my $chain = $self->{chain} or die;
    scalar @$chain;
}

sub mutate {

    my $self = shift;

    my $chain = $self->{chain} or die;
    my @states = keys %{ $markov->{_probabilities} } or die "markov not trained";

    my $thing = int rand 4;
    my $loc = int rand @$chain;

    if($thing == 0) {

        #   add a new term at a random point
        # splice @chain, $loc, 1, $states[int rand @states];  # no, not a completely random term, but instead one that follows the sequence
warn "mutate: insert term";
        $markov->{_state} = $chain->[$loc];
        splice @$chain, $loc+1, 1, $markov->get_next_item;

    } elsif($thing == 1) {

warn "mutate: drop term";
        #   drop a term from a random point
        splice @$chain, $loc, 1, ();

    } elsif($thing == 3) {

warn "mutate: change term";
        #   change the state transition for a term
        if($loc > 1) {
            $markov->{_state} = $chain->[$loc-1];
            $chain->[$loc] = $markov->get_next_item;
        } else {
            # but the very first term doesn't have anything to follow so it's completely random
            $chain->[0] = $states[int rand @states];
        }

    } elsif($thing == 2) {

warn "mutate: change term to completely random term";
        #   change a term at a point to something completely random
        $chain->[$loc] = $states[int rand @states];

    }

    $self;
   
}

sub breed {

    my $self = shift;
    my $mate = shift or die;

    my @my_chain = @{$self->{chain}} or die;
    my @their_chain = @{$mate->{chain}};
    my @child_chain;

    # when merging two chains, do a random on the size of the output (somewhere between the possibilities)
    # then randomize where terms get dropped

    my $smaller_chain_size = @my_chain;
    my $larger_chain_size = @their_chain;
    ($smaller_chain_size, $larger_chain_size) = ($larger_chain_size, $smaller_chain_size) if $smaller_chain_size > $larger_chain_size;
    my $chain_size_diff = $larger_chain_size - $smaller_chain_size;

    for my $i (0 .. $larger_chain_size-1) {
        if($chain_size_diff > 0 and $my_chain[$i] ne $their_chain[$i] and rand 1 < 0.3) {
            # insert a token from the longer into the shorter at the current point to grow the shorter
            # XXX tweak the odds so that they're proportional to how much chain is left and how many inserts are needed
            if(@my_chain > @their_chain) {
                splice @their_chain, $i, 0, $my_chain[$i];
            } elsif(@their_chain > @my_chain) {
                splice @my_chain, $i, 0, $their_chain[$i];
            }
            $chain_size_diff--;
        }
        $child_chain[$i] = rand 1 < 0.5 ? $my_chain[$i] : $their_chain[$i];
        # if we picked the blank of two, use the one that isn't blank -- end of size mismatched chains
        $child_chain[$i] ||= $my_chain[$i] || $their_chain[$i];  
    }

    my $child = ref($self)->new();
    $child->{chain} = \@child_chain;
    return $child;

}


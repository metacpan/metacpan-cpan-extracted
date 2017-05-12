#!/usr/bin/perl -w
use strict;

use Test::More tests => 17;
use VCS::Lite;

my $save_output = $ENV{VCS_LITE_KEEP_OUTPUT};

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

#02
is($el1->id,'data/mariner.txt','Correct name returned by id');

my $el2 = VCS::Lite->new('data/marinerx.txt');

#03
ok(!$el1->delta($el1),'Compare with same returns empty array');

my $dt1 = $el1->delta($el2);

#04
isa_ok($dt1,'VCS::Lite::Delta','Delta return');

#05
my @id = $dt1->id;
is_deeply(\@id,['data/mariner.txt',
		'data/marinerx.txt'],
		'id method of delta returns correct ids');

#06
my @hunks = $dt1->hunks;
is_deeply(\@hunks,
	[
	    [
	    	['-', 3, "Now wherefore stopp'st thou me?\n"],
	    	['+', 3, "Now wherefore stoppest thou me?\n"],
	    ],[
	    	['-', 20, "The Wedding-Guest sat on a stone:\n"],
	    	['-', 21, "He cannot chuse but hear;\n"],
	    	['-', 22, "And thus spake on that ancient man,\n"],
	    	['-', 23, "The bright-eyed Mariner.\n"],
	    	['-', 24, "\n"],
	    ],[
	    	['+', 32, "Wondering about the wretched loon\n"],
	    ],[
	    	['-', 94, "Whiles all the night, through fog-smoke white,\n"],
	    	['-', 95, "Glimmered the white Moon-shine.\n"],
	    	['+', 90, "While all the night, through fog-smoke white,\n"],
	    	['+', 91, "Glimmered the white Moonshine.\n"],
	    ]
	], 'Full comparison of hunks');

my $diff = $dt1->diff;

#07
ok($diff, 'Diff returns differences');

if ($save_output) {
    open (my $dfh, '>', 'diff1.out')
        or die "Failed to write output: $!";
    print $dfh $diff;
}

my $results = do { local (@ARGV, $/) = 'data/marinerx.dif'; <> };

#08
is($diff, $results, 'Diff matches expected results (diff)');

my $el1c = VCS::Lite->new('data/mariner.txt', { chomp => 1 } );
my $el2c = VCS::Lite->new('data/marinerx.txt', { chomp => 1 } );
my $dt1c = $el1c->delta($el2c);
$diff = $dt1c->diff;

if ($save_output) {
    open (my $dfh, '>', 'diff1c.out')
        or die "Failed to write output: $!";
    print $dfh $diff;
}

#09
is($diff, $results, 'Chomped mode: diff matches expected results');

my $el3 = VCS::Lite->new('data/marinery.txt');
$diff = $el1->diff($el3);	# old form of call

#10
ok($diff, 'Diff returns differences');

if ($save_output) {
    open (my $dfh, '>', 'diff2.out')
        or die "Failed to write output: $!";
    print $dfh $diff;
}

$results = do { local (@ARGV, $/) = 'data/marinery.dif'; <> };

#11
is($diff, $results, 'Diff matches expected results (diff)');

my $udiff = $dt1->udiff;

#12
ok($udiff, 'udiff returns differences');

if ($save_output) {
    open (my $dfh, '>', 'diff3.out')
        or die "Failed to write output: $!";
    print $dfh $udiff;
}

$results = do { local (@ARGV, $/) = 'data/marinerx1.udif'; <> };

#13
is($udiff, $results, 'Diff matches expected results (udiff)');

$dt1 = $el1->delta($el2, window => 3);
$udiff = $dt1->udiff;

$results = do { local (@ARGV, $/) = 'data/marinerx.udif'; <> };

#14
is($udiff, $results, 'Diff matches expected results (udiff, 3 window)');

$dt1c = $el1c->delta($el2c, window => 3);
$udiff = $dt1c->udiff;

#15
is($udiff, $results, 'Chomped diff matches expected results (udiff, 3 window)');

if ($save_output) {
    open (my $dfh, '>', 'diff4.out')
        or die "Failed to write output: $!";
    print $dfh $udiff;
}

#Test with no newline at end of file
my $el4 = VCS::Lite->new('data/snarka.txt');
my $el5 = VCS::Lite->new('data/snarkb.txt');
my $dt2 = $el4->delta($el5);

$results = do { local (@ARGV, $/) = 'data/snarkab.dif'; <> };
$diff = $dt2->diff;

#16
is($diff, $results, 'Diff matches expected results (diff)');

$results = do { local (@ARGV, $/) = 'data/snarkab.udif'; <> };
$udiff = $dt2->udiff;

#17
is($udiff, $results, 'Diff matches expected results (udiff)');

if ($save_output) {
    open (my $dfh, '>', 'diff5.out')
        or die "Failed to write output: $!";
    print $dfh $udiff;
}

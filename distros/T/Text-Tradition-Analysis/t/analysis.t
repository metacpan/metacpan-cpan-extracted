#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use feature 'say';
use Test::More;
use Text::Tradition;
use Text::Tradition::Analysis qw/ run_analysis /;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
eval { no warnings; binmode $DB::OUT, ':utf8'; $DB::deep = 1000 };

my $tradition = Text::Tradition->new(
	'input' => 'Self',
	'file' => 't/data/besoin.xml' );
$tradition->add_stemma( 'dotfile' => 't/data/besoin.dot' );

# Run the analysis of the tradition

my %expected = (
    2 => 'type1',
    3 => 'genealogical',
    28 => 'genealogical',
    39 => 'genealogical',
    62 => 'type1',
    63 => 'type1',
    73 => 'reverted',
    76 => 'genealogical',
    91 => 'conflict',
    93 => 'genealogical',
    94 => 'genealogical',
    99 => 'reverted',
    110 => 'type1',
    117 => 'type1',
    136 => 'reverted',
    142 => 'conflict',
    155 => 'genealogical',
    170 => 'genealogical',
    182 => 'type1',
    205 => 'genealogical',
    219 => 'genealogical',
    239 => 'genealogical',
    244 => 'genealogical',
    245 => 'type1',
    251 => 'genealogical',
    252 => 'genealogical',
    293 => 'genealogical',
    295 => 'genealogical',
    309 => 'genealogical',
    310 => 'type1',
    314 => 'type1',
    315 => 'type1',
    317 => 'reverted',
    318 => 'genealogical',
    319 => 'genealogical',
    324 => 'type1',
    328 => 'reverted',
    334 => 'type1',
    335 => 'genealogical',
    350 => 'reverted',
    361 => 'reverted',
    367 => 'type1',
    370 => 'type1',
    382 => 'reverted',
    385 => 'reverted',
    406 => 'genealogical',
    413 => 'genealogical',
    417 => 'type1',
    418 => 'reverted',
    459 => 'type1',
    493 => 'genealogical',
    497 => 'reverted',
    499 => 'type1',
    500 => 'reverted',
    515 => 'reverted',
    556 => 'type1',
    558 => 'conflict',
    597 => 'type1',
    615 => 'type1',
    617 => 'type1',
    632 => 'genealogical',
    634 => 'genealogical',
    636 => 'genealogical',
    685 => 'genealogical',
    737 => 'genealogical',
    742 => 'reverted',
    743 => 'reverted',
    744 => 'reverted',
    745 => 'type1',
    746 => 'type1',
    747 => 'type1',
    757 => 'type1',
    762 => 'type1',
    763 => 'type1',
    777 => 'reverted',
    780 => 'genealogical',
    802 => 'type1',
    803 => 'type1',
    815 => 'type1',
    837 => 'genealogical',
    854 => 'type1',
    855 => 'type1',
    856 => 'type1',
    857 => 'type1',
    858 => 'type1',
    859 => 'type1',
    860 => 'type1',
    861 => 'type1',
    862 => 'type1',
    863 => 'type1',
    864 => 'type1',
    865 => 'type1',
    866 => 'type1',
    867 => 'type1',
    868 => 'type1',
    869 => 'type1',
    870 => 'type1',
    871 => 'type1',
    872 => 'type1',
    873 => 'type1',
    874 => 'type1',
    875 => 'type1',
    876 => 'type1',
    877 => 'type1',
    878 => 'type1',
    879 => 'type1',
    880 => 'type1',
    881 => 'type1',
    882 => 'type1',
    883 => 'type1',
    884 => 'type1',
    885 => 'type1',
    886 => 'type1',
    887 => 'type1',
    888 => 'type1',
    889 => 'type1',
    890 => 'type1',
    891 => 'type1',
    892 => 'type1',
    893 => 'type1',
    894 => 'type1',
    895 => 'type1',
    896 => 'type1',
    897 => 'conflict',
    898 => 'conflict',
    899 => 'type1',
    900 => 'type1',
    901 => 'type1',
    902 => 'type1',
    903 => 'type1',
    904 => 'type1',
    905 => 'type1',
    906 => 'type1',
    907 => 'type1',
    915 => 'type1',
    916 => 'type1',
    925 => 'genealogical',
    927 => 'type1',
    952 => 'genealogical',
    954 => 'genealogical',
    969 => 'genealogical',
    972 => 'genealogical',
    973 => 'genealogical',
    974 => 'type1',
    1003 => 'genealogical',
    1004 => 'genealogical' # check for transp
);

my %num_readings;

my @all_variant_ranks = sort { $a <=> $b } keys( %expected );
# Look through the results
my $c = $tradition->collation;
my %analysis_opts = ( solver_url => 'https://stemmaweb.net/cgi-bin/graphcalc.cgi' );
my $results = run_analysis( $tradition, %analysis_opts );
my $connection_error;
my @analyzed;
foreach my $row ( @{$results->{'variants'}} ) {
	push( @analyzed, $row->{id} );
        if( exists $row->{'unsolved'} ) {
		# If it is an "IDP error" then ignore it and move on - 
		# probably a connectivity problem
		if( $row->{'unsolved'} ne 'IDP error' ) {
			ok( 0, "Got a solution for the stated problem" );
		}
		$connection_error = 1;
		next;
	}

	$num_readings{$row->{id}} = scalar @{$row->{'readings'}};
	my $type = 'genealogical';
	if( grep { $_->{'is_conflict'} } @{$row->{'readings'}} ) {
		$type = 'conflict';
	} elsif( grep { $_->{'is_reverted'} } @{$row->{'readings'}} ) {
		$type = 'reverted';
	}
	my $expected = $expected{$row->{'id'}};
	$expected = 'genealogical' if $expected eq 'type1';
	is( $type, $expected, "Got expected genealogical result for rank " . $row->{'id'} );
	# If the row is genealogical, there should be one reading with no parents,
	# every reading should independently occur exactly once, and the total
	# number of changes + maybe-changes should equal the total number of
	# readings who have that one as a parent.
	if( $row->{'genealogical'} ) {
		# Make the mapping of parent -> child readings
		my %is_parent;
		my @has_no_parent;
		foreach my $rdg ( @{$row->{'readings'}} ) {
			my $parents = $rdg->{'source_parents'} || {};
			foreach my $p ( keys %$parents ) {
				push( @{$is_parent{$p}}, $rdg->{'readingid'} );
			}
			push( @has_no_parent, $rdg->{'readingid'} ) unless keys %$parents;
		}
		# Test some stuff
		foreach my $rdg ( @{$row->{'readings'}} ) {
			is( @{$rdg->{'independent_occurrence'}}, 1, 
				"Genealogical reading originates exactly once" );
		}
		is( @has_no_parent, 1, "Only one genealogical reading lacks a parent" );
	}
}
# Check that run_analysis ran an analysis on all our known variant ranks
is_deeply( \@all_variant_ranks, \@analyzed, "Ran analysis for all expected rows" ) unless $connection_error;

# Now run it again, excluding type 1 variants.
map { delete $expected{$_} if $expected{$_} eq 'type1' } keys %expected;
my @useful_variant_ranks = sort { $a <=> $b } keys( %expected );
$analysis_opts{'exclude_type1'} = 1;
@analyzed = ();
$results = run_analysis( $tradition, %analysis_opts );
$connection_error = undef;
foreach my $row ( @{$results->{'variants'}} ) {
        if( exists $row->{'unsolved'} ) {
		# If it is an "IDP error" then ignore it and move on - 
		# probably a connectivity problem
		if( $row->{'unsolved'} ne 'IDP error' ) {
			ok( 0, "Got a solution for the stated problem" );
		}
		$connection_error = 1;
		next;
	}

	push( @analyzed, $row->{id} );
	my $type = 'genealogical';
	if( grep { $_->{'is_conflict'} } @{$row->{'readings'}} ) {
		$type = 'conflict';
	} elsif( grep { $_->{'is_reverted'} } @{$row->{'readings'}} ) {
		$type = 'reverted';
	}
	is( $type, $expected{$row->{'id'}}, "Got expected genealogical result on exclude_type1 run for rank " . $row->{'id'} );
}
is_deeply( \@analyzed, \@useful_variant_ranks, "Ran analysis for all useful rows" ) unless $connection_error;

# Now run it again, excluding orthography / spelling.
my @merged_exclude = qw/ 76 136 142 155 293 317 319 335 350 361 413 500 515 636 685 
	737 954 1003 /;
# 205 now conflicts; it and 493 should also have one fewer reading
$expected{205} = 'conflict';
$num_readings{205}--;
$num_readings{493}--;
map { delete $expected{$_} } @merged_exclude;
my @merged_remaining = sort { $a <=> $b } keys( %expected );
$analysis_opts{'merge_types'} = [ qw/ orthographic spelling / ];
@analyzed = ();
$results = run_analysis( $tradition, %analysis_opts );
foreach my $row ( @{$results->{'variants'}} ) {
	push( @analyzed, $row->{id} );
        if( exists $row->{'unsolved'} ) {
		# If it is an "IDP error" then ignore it and move on - 
		# probably a connectivity problem
		if( $row->{'unsolved'} ne 'IDP error' ) {
			ok( 0, "Got a solution for the stated problem" );
		}
		next;
	}

	my $type = 'genealogical';
	if( grep { $_->{'is_conflict'} } @{$row->{'readings'}} ) {
		$type = 'conflict';
	} elsif( grep { $_->{'is_reverted'} } @{$row->{'readings'}} ) {
		$type = 'reverted';
	}
	is( $type, $expected{$row->{'id'}}, "Got expected genealogical result on merge_types run for rank " . $row->{'id'} );
	is( scalar @{$row->{'readings'}}, $num_readings{$row->{id}}, "Got expected number of readings during merge" );
}
is_deeply( \@analyzed, \@merged_remaining, "Ran analysis for all useful unmerged rows" );

done_testing();

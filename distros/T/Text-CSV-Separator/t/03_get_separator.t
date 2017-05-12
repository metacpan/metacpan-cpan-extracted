#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 17;
use FindBin();

use Text::CSV::Separator qw(get_separator);


my @separators;

#-------------------------------------------------------------------------------
my $sample1_path = $FindBin::Bin . '/commasep.csv';

@separators = get_separator( path => $sample1_path );

is( $separators[0], ',', 'The separator should be a comma');
is( @separators, 1, 'There must be only 1 candidate left');

# testing the return value when there are no candidates left
@separators = get_separator(
                            path => $sample1_path,
                            exclude => [',', ':'],
                           );

is(@separators, 0, 'There must be no candidates left');


#-------------------------------------------------------------------------------
my $sample2_path = $FindBin::Bin . '/tabsep.csv';

@separators = get_separator( path => $sample2_path );

is( $separators[0], "\t", 'The separator should be a tab');
is( @separators, 1, 'There must be only 1 candidate left');


#-------------------------------------------------------------------------------
my $sample3_path = $FindBin::Bin . '/commacolonpipe.csv';

@separators = get_separator( path => $sample3_path );

is( $separators[0], ":", 'The most likely candidate should be a colon');
ok( @separators > 1, 'There must be more than 1 candidate left');

# testing the exclude functionality
@separators = get_separator(
                            path => $sample3_path,
                            exclude => [',', ':'],
                           );

is( $separators[0], "|", 'The separator should be a pipe');
is( @separators, 1, 'There must be only 1 candidate left');


#-------------------------------------------------------------------------------
my $sample4_path = $FindBin::Bin . '/commacolon.csv';

@separators = get_separator( path => $sample4_path );

is( $separators[0], ":", 'The most likely candidate should be a colon');
is( @separators,  2, 'There must be 2 candidates left');

# testing the include/exclude functionality
@separators = get_separator(
                            path => $sample4_path,
                            include => ['@'],
                            exclude => [',', ':'],
                           );

is( $separators[0], "@", 'The separator should be an at sign');
is( @separators,  1, 'There must be 1 candidate left');


#-------------------------------------------------------------------------------
my $sample5_path = $FindBin::Bin . '/semicolon_commasep.csv';

@separators = get_separator( path => $sample5_path );

is( $separators[0], ";", 'The most likely candidate should be a semicolon');
is( @separators,  2, 'There must be 2 candidates left');


#-------------------------------------------------------------------------------
my $sample6_path = $FindBin::Bin . '/tabsep_timecol.csv';

@separators = get_separator( path => $sample6_path );

is( $separators[0], "\t", 'The most likely candidate should be a semicolon');
is( @separators,  2, 'There must be 2 candidates left');




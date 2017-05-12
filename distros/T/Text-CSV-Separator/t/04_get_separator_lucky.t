#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
use FindBin();

use Text::CSV::Separator qw(get_separator);

my $separator;

#-------------------------------------------------------------------------------
my $sample1_path = $FindBin::Bin . '/commasep.csv';

$separator = get_separator( path => $sample1_path, lucky => 1 );

is( $separator, ',', 'The separator should be a comma');

# testing the return value when there are no candidates left
$separator = get_separator(
                            path => $sample1_path,
                            exclude => [',', ':'],
                            lucky => 1,
                          );

is($separator, undef, 'There must be no candidates left');


#-------------------------------------------------------------------------------
my $sample2_path = $FindBin::Bin . '/tabsep.csv';

$separator = get_separator( path => $sample2_path, lucky => 1 );

is( $separator, "\t", 'The separator should be a tab');


#-------------------------------------------------------------------------------
my $sample3_path = $FindBin::Bin . '/commacolonpipe.csv';

$separator = get_separator( path => $sample3_path, lucky => 1 );

is( $separator, undef, 'Several candidates left');


# testing the exclude functionality
$separator = get_separator(
                            path => $sample3_path,
                            exclude => [',', ':'],
                            lucky => 1,
                           );

is( $separator, "|", 'The separator should be a pipe');


#-------------------------------------------------------------------------------
my $sample4_path = $FindBin::Bin . '/commacolon.csv';

$separator = get_separator( path => $sample4_path, lucky => 1 );

is( $separator, undef, 'Several candidates left');

# testing the include/exclude functionality
$separator = get_separator(
                            path => $sample4_path,
                            include => ['@'],
                            exclude => [',', ':'],
                            lucky => 1,
                          );

is( $separator, "@", 'The separator should be an at sign');


#-------------------------------------------------------------------------------
my $sample5_path = $FindBin::Bin . '/semicolon_commasep.csv';

$separator = get_separator( path => $sample5_path, lucky => 1 );

is( $separator, undef, 'Several candidates left');


#-------------------------------------------------------------------------------
my $sample6_path = $FindBin::Bin . '/tabsep_timecol.csv';

$separator = get_separator( path => $sample6_path, lucky => 1 );

is( $separator, undef, 'Several candidates left');





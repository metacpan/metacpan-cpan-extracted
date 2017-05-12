#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 5 };
use Test::Differences;
use Test::Exception;

use File::Slurp 'read_file';

use FindBin qw($Bin);
use lib "$Bin/../lib";


BEGIN {
	use_ok ( 'URL::Transform' ) or exit;
}

my $TRANSFORM_FUNCTION = sub {
    my %x = @_;
    return (
        join(', ',
            map { $_.': '.$x{$_} } sort keys %x
        )
    )
};

# text/html tests

my $output;
my $urlt1 = URL::Transform->new(
    'parser'             => 'XML::SAX',
    'output_function'    => sub { $output .= "@_" },
    'transform_function' => $TRANSFORM_FUNCTION,
);

isa_ok($urlt1, 'URL::Transform');

$urlt1->parse_file($Bin.'/data/URL-Transform-01.html');
my $result_01 = scalar read_file($Bin.'/data/URL-Transform-01-result.html');
$result_01    =~ s/"/'/g;
eq_or_diff(
    [ split "\n", $output ],
    [ split "\n", $result_01 ],
    'check the parse_file',
);


$output = '';
$urlt1->parse_string(scalar read_file($Bin.'/data/URL-Transform-01.html'));
eq_or_diff(
    [ split "\n", $output ],
    [ split "\n", $result_01 ],
    'check the parse_string',
);


ok(!$urlt1->can_parse_chunks, 'we can not parse_chunk :(');



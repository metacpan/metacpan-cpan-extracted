use strict;
use warnings;

use File::Object;
use JSON::XS;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use WQS::SPARQL::Result;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = WQS::SPARQL::Result->new;
my $result1_json = slurp($data_dir->file('result1.json')->s);
my $result1_hr = decode_json($result1_json);
my @ret = $obj->result($result1_hr);
is_deeply(\@ret, [{'item' => 'Q104381358'}], 'Get one item result.');

# Test.
$obj = WQS::SPARQL::Result->new;
my $result2_json = slurp($data_dir->file('result2.json')->s);
my $result2_hr = decode_json($result2_json);
@ret = $obj->result($result2_hr);
is_deeply(\@ret, [{'foo' => 'Q104381358'}], 'Get one foo result.');

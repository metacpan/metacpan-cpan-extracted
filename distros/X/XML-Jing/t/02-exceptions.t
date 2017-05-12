#Check that Java exceptions are properly caught
use strict;
use warnings;
use XML::Jing;
use Test::More;
# use Test::Warn;
use Test::Exception;
use Path::Tiny;
use FindBin qw($Bin);
plan tests => 6;

my $jing;
my $nonexistent = 'nonexistent.xml';

#test the constructor
throws_ok
	{$jing = XML::Jing->new($nonexistent)}
	qr/^File doesn't exist: $nonexistent/,
	'warning for nonexistent RNG file';
ok(!$jing, 'constructor returns nothing for non-existent RNG file');

my $bad_rng = path($Bin, 'data', 'BAD.rng');

throws_ok
	{$jing = XML::Jing->new($bad_rng)}
	qr/^Error reading RNG file:/,
	'warning for bad RNG file';
ok(!$jing, 'constructor returns nothing for bad RNG file');

#test the validate method
$jing = XML::Jing->new(path($Bin, 'data','test.rng'));
my $errors = '';
throws_ok
	{$jing->validate($nonexistent)}
	qr/^File doesn't exist: $nonexistent/,
	'warning for nonexistent XML file';

$errors = '';
throws_ok
	{$jing->validate(path($Bin,'data','testBADDTD.xml'))}
	qr/^Error reading file:/,
	'warning for nonexistent DTD required by XML file';

use strict;
use warnings;

use Test::More tests => 31;
use File::Temp 'tempfile';



## create a temp CSV file

my ($tmp_fh, $tmp_file) = tempfile( UNLINK => 1 );

print $tmp_fh <<EOCSV;
foo:bar:baz
potato:monkey:rutabaga
fred:barney:wilma
EOCSV

close $tmp_fh;


## load module

use_ok('Tie::Handle::CSV');

## HEADER IN FILE

## test tie interface

eval { tie(*FH, 'Tie::Handle::CSV', '', header => 1) };
ok( $@, 'tie - bad - header' );
ok(  tie(*FH, 'Tie::Handle::CSV', $tmp_file, header => 1, sep_char => ':'), 'tie - good - header' );

## test new() interface

my $csv_fh;

ok(  $csv_fh = Tie::Handle::CSV->new($tmp_file, header => 1, sep_char => ':'), 'new - good - header' );
eval { Tie::Handle::CSV->new('', header => 1) };
ok( $@, 'new - bad - header' );

## test reading with no header

my $line1 = <FH>;
my $line2 = <FH>;
my $line3 = <FH>;

ok( ref $line1 eq 'Tie::Handle::CSV::Hash',              'tie - ref' );

ok( $line1 eq 'potato:monkey:rutabaga', 'tie - line1 - stringify' );
ok( $line2 eq 'fred:barney:wilma',      'tie - line2 - stringify' );
ok(! defined $line3,                    'tie - line3 - undef' );

is( $line1->{'foo'}, 'potato',   'tie - line1 - foo' );
is( $line1->{'bar'}, 'monkey',   'tie - line1 - bar' );
is( $line1->{'baz'}, 'rutabaga', 'tie - line1 - baz' );
is( $line1->{'not'}, undef,      'tie - line1 - not' );

is( $line2->{'foo'}, 'fred',     'tie - line2 - foo' );
is( $line2->{'bar'}, 'barney',   'tie - line2 - bar' );
is( $line2->{'baz'}, 'wilma',    'tie - line2 - baz' );
is( $line2->{'not'}, undef,      'tie - line2 - not' );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;

ok( ref $line1 eq 'Tie::Handle::CSV::Hash',              'new - ref' );

ok( $line1 eq 'potato:monkey:rutabaga', 'new - line1 - stringify' );
ok( $line2 eq 'fred:barney:wilma',      'new - line2 - stringify' );
ok(! defined $line3,                    'new - line3 - undef' );

is( $line1->{'foo'}, 'potato',   'new - line1 - foo' );
is( $line1->{'bar'}, 'monkey',   'new - line1 - bar' );
is( $line1->{'baz'}, 'rutabaga', 'new - line1 - baz' );
is( $line1->{'not'}, undef,      'new - line1 - not' );

is( $line2->{'foo'}, 'fred',     'new - line2 - foo' );
is( $line2->{'bar'}, 'barney',   'new - line2 - bar' );
is( $line2->{'baz'}, 'wilma',    'new - line2 - baz' );
is( $line2->{'not'}, undef,      'new - line2 - not' );

ok( close(FH),      'tie - close' );
ok( close($csv_fh), 'new - close' );

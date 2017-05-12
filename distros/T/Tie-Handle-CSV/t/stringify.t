use strict;
use warnings;

use Test::More tests => 58;
use File::Temp 'tempfile';

## create a temp CSV file

my ($tmp_fh, $tmp_file) = tempfile( UNLINK => 1 );

print $tmp_fh <<EOCSV;
foo,bar,baz
potato,monkey,rutabaga
fred,barney,wilma
EOCSV

close $tmp_fh;

## load module

use_ok('Tie::Handle::CSV');

## HEADER IN ARGS

## test new() interface

my $csv_fh;

ok(  $csv_fh = Tie::Handle::CSV->new($tmp_file, header => [qw/ one two three /], simple_reads => 1), 'new - good - header' );

my $line1 = <$csv_fh>;
my $line2 = <$csv_fh>;
my $line3 = <$csv_fh>;
my $line4 = <$csv_fh>;

ok( ref $line1 eq 'HASH',               'new - ref' );

like( $line1, qr/HASH/,            'new - line1 - stringify' );
like( $line2, qr/HASH/,            'new - line2 - stringify' );
like( $line3, qr/HASH/,            'new - line3 - stringify' );
ok(! defined $line4,               'new - line4 - undef' );

is( $line1->{'one'},   'foo',      'new - line1 - one' );
is( $line1->{'two'},   'bar',      'new - line1 - two' );
is( $line1->{'three'}, 'baz',      'new - line1 - three' );
is( $line1->{'not'}, undef,        'new - line1 - not' );

is( $line2->{'one'},   'potato',   'new - line2 - one' );
is( $line2->{'two'},   'monkey',   'new - line2 - two' );
is( $line2->{'three'}, 'rutabaga', 'new - line2 - three' );
is( $line2->{'not'}, undef,        'new - line2 - not' );

is( $line3->{'one'},   'fred',     'new - line3 - one' );
is( $line3->{'two'},   'barney',   'new - line3 - two' );
is( $line3->{'three'}, 'wilma',    'new - line3 - three' );
is( $line3->{'not'}, undef,        'new - line3 - not' );

ok( close($csv_fh), 'new - close' );

ok(  $csv_fh = Tie::Handle::CSV->new($tmp_file, header => [qw/ one two three /], stringify => 0, simple_reads => 1), 'new - good - header' );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;
$line4 = <$csv_fh>;

ok( ref $line1 eq 'HASH',               'new - ref' );

like( $line1, qr/HASH/,            'new - line1 - stringify' );
like( $line2, qr/HASH/,            'new - line2 - stringify' );
like( $line3, qr/HASH/,            'new - line3 - stringify' );
ok(! defined $line4,               'new - line4 - undef' );

is( $line1->{'one'},   'foo',      'new - line1 - one' );
is( $line1->{'two'},   'bar',      'new - line1 - two' );
is( $line1->{'three'}, 'baz',      'new - line1 - three' );
is( $line1->{'not'}, undef,        'new - line1 - not' );

is( $line2->{'one'},   'potato',   'new - line2 - one' );
is( $line2->{'two'},   'monkey',   'new - line2 - two' );
is( $line2->{'three'}, 'rutabaga', 'new - line2 - three' );
is( $line2->{'not'}, undef,        'new - line2 - not' );

is( $line3->{'one'},   'fred',     'new - line3 - one' );
is( $line3->{'two'},   'barney',   'new - line3 - two' );
is( $line3->{'three'}, 'wilma',    'new - line3 - three' );
is( $line3->{'not'}, undef,        'new - line3 - not' );

ok( close($csv_fh), 'new - close' );

ok(  $csv_fh = Tie::Handle::CSV->new($tmp_file, header => [qw/ one two three /], stringify => 0), 'new - good - header' );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;
$line4 = <$csv_fh>;

ok( ref $line1 eq 'HASH',               'new - ref' );

like( $line1, qr/HASH/,            'new - line1 - stringify' );
like( $line2, qr/HASH/,            'new - line2 - stringify' );
like( $line3, qr/HASH/,            'new - line3 - stringify' );
ok(! defined $line4,               'new - line4 - undef' );

is( $line1->{'one'},   'foo',      'new - line1 - one' );
is( $line1->{'two'},   'bar',      'new - line1 - two' );
is( $line1->{'three'}, 'baz',      'new - line1 - three' );
is( $line1->{'not'}, undef,        'new - line1 - not' );

is( $line2->{'one'},   'potato',   'new - line2 - one' );
is( $line2->{'two'},   'monkey',   'new - line2 - two' );
is( $line2->{'three'}, 'rutabaga', 'new - line2 - three' );
is( $line2->{'not'}, undef,        'new - line2 - not' );

is( $line3->{'one'},   'fred',     'new - line3 - one' );
is( $line3->{'two'},   'barney',   'new - line3 - two' );
is( $line3->{'three'}, 'wilma',    'new - line3 - three' );
is( $line3->{'not'}, undef,        'new - line3 - not' );

ok( close($csv_fh), 'new - close' );

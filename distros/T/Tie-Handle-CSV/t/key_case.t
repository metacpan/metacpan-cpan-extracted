use strict;
use warnings;

use Test::More tests => 69;
use File::Temp 'tempfile';

## create a temp CSV file

my ($tmp_fh, $tmp_file) = tempfile( UNLINK => 1 );

print $tmp_fh <<EOCSV;
Foo,Bar,Baz
potato,monkey,rutabaga
fred,barney,wilma
EOCSV

close $tmp_fh;

## load module

use_ok('Tie::Handle::CSV');

my $csv_fh = Tie::Handle::CSV->new(
   file     => $tmp_file,
   key_case => 'as_is' );

my $line1 = <$csv_fh>;
my $line2 = <$csv_fh>;
my $line3 = <$csv_fh>;

ok( $line1 eq 'potato,monkey,rutabaga', 'new - line1 - stringify' );
ok( $line2 eq 'fred,barney,wilma',      'new - line2 - stringify' );
ok(! defined $line3,                    'new - line3 - undef' );

is( $line1->{'Foo'}, 'potato',   'new - line1 - Foo' );
is( $line1->{'Bar'}, 'monkey',   'new - line1 - Bar' );
is( $line1->{'Baz'}, 'rutabaga', 'new - line1 - Baz' );
is( $line1->{'foo'}, undef,      'new - line1 - foo' );

is( $line2->{'Foo'}, 'fred',     'new - line2 - Foo' );
is( $line2->{'Bar'}, 'barney',   'new - line2 - Bar' );
is( $line2->{'Baz'}, 'wilma',    'new - line2 - Baz' );
is( $line2->{'foo'}, undef,      'new - line2 - foo' );

my @keys = keys %{ $line1 };
my @exp  = qw/ Foo Bar Baz /;

is_deeply(\@keys, \@exp, "new - keys");

ok( close($csv_fh), 'new - close' );

$csv_fh = Tie::Handle::CSV->new(
   file     => $tmp_file,
   key_case => 'lower' );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;

ok( $line1 eq 'potato,monkey,rutabaga', 'new - line1 - stringify' );
ok( $line2 eq 'fred,barney,wilma',      'new - line2 - stringify' );
ok(! defined $line3,                    'new - line3 - undef' );

is( $line1->{'foo'}, 'potato',   'new - line1 - foo' );
is( $line1->{'bar'}, 'monkey',   'new - line1 - bar' );
is( $line1->{'baz'}, 'rutabaga', 'new - line1 - baz' );
is( $line1->{'Foo'}, undef,      'new - line1 - Foo' );

is( $line2->{'foo'}, 'fred',     'new - line2 - foo' );
is( $line2->{'bar'}, 'barney',   'new - line2 - bar' );
is( $line2->{'baz'}, 'wilma',    'new - line2 - baz' );
is( $line2->{'Foo'}, undef,      'new - line2 - Foo' );

@keys = keys %{ $line1 };
@exp  = qw/ foo bar baz /;

is_deeply(\@keys, \@exp, "new - keys");

ok( close($csv_fh), 'new - close' );

$csv_fh = Tie::Handle::CSV->new(
   file        => $tmp_file,
   force_lower => 1 );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;

ok( $line1 eq 'potato,monkey,rutabaga', 'new - line1 - stringify' );
ok( $line2 eq 'fred,barney,wilma',      'new - line2 - stringify' );
ok(! defined $line3,                    'new - line3 - undef' );

is( $line1->{'foo'}, 'potato',   'new - line1 - foo' );
is( $line1->{'bar'}, 'monkey',   'new - line1 - bar' );
is( $line1->{'baz'}, 'rutabaga', 'new - line1 - baz' );
is( $line1->{'Foo'}, undef,      'new - line1 - Foo' );

is( $line2->{'foo'}, 'fred',     'new - line2 - foo' );
is( $line2->{'bar'}, 'barney',   'new - line2 - bar' );
is( $line2->{'baz'}, 'wilma',    'new - line2 - baz' );
is( $line2->{'Foo'}, undef,      'new - line2 - Foo' );

@keys = keys %{ $line1 };
@exp  = qw/ foo bar baz /;

is_deeply(\@keys, \@exp, "new - keys");

ok( close($csv_fh), 'new - close' );

$csv_fh = Tie::Handle::CSV->new(
   file         => $tmp_file,
   key_case     => 'upper',
   openmode     => '<',
   simple_reads => 1 );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;

like( $line1, qr/HASH/, 'new - line1 - stringify' );
like( $line2, qr/HASH/,      'new - line2 - stringify' );
ok(! defined $line3,                    'new - line3 - undef' );

is( $line1->{'FOO'}, 'potato',   'new - line1 - FOO' );
is( $line1->{'BAR'}, 'monkey',   'new - line1 - BAR' );
is( $line1->{'BAZ'}, 'rutabaga', 'new - line1 - BAZ' );
is( $line1->{'Foo'}, undef,      'new - line1 - Foo' );

is( $line2->{'FOO'}, 'fred',     'new - line2 - FOO' );
is( $line2->{'BAR'}, 'barney',   'new - line2 - BAR' );
is( $line2->{'BAZ'}, 'wilma',    'new - line2 - BAZ' );
is( $line2->{'Foo'}, undef,      'new - line2 - Foo' );

@keys = sort keys %{ $line1 };
@exp  = qw/ BAR BAZ FOO /;

is_deeply(\@keys, \@exp, "new - keys");

ok( close($csv_fh), 'new - close' );

$csv_fh = Tie::Handle::CSV->new(
   file         => $tmp_file,
   open_mode    => '<',
   key_case     => 'any' );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;

is( $line1, 'potato,monkey,rutabaga', 'new - line1 - stringify' );
is( $line2, 'fred,barney,wilma',      'new - line2 - stringify' );
ok(! defined $line3,                    'new - line3 - undef' );

is( $line1->{'FoO'}, 'potato',   'new - line1 - FOO' );
is( $line1->{'BAr'}, 'monkey',   'new - line1 - BAR' );
is( $line1->{'bAZ'}, 'rutabaga', 'new - line1 - BAZ' );
is( $line1->{'not'}, undef,      'new - line1 - not' );

is( $line2->{'fOO'}, 'fred',     'new - line2 - FOO' );
is( $line2->{'bar'}, 'barney',   'new - line2 - BAR' );
is( $line2->{'Baz'}, 'wilma',    'new - line2 - BAZ' );
is( $line2->{'NoT'}, undef,      'new - line2 - not' );

@keys = sort keys %{ $line1 };
@exp  = qw/ Bar Baz Foo /;

is_deeply(\@keys, \@exp, "new - keys");

ok( exists $line2->{'baZ'},    'new - line2 - baz' );
is( delete $line2->{'bAZ'}, 'wilma',    'new - line2 - baz' );

%{ $line2 } = ();

is( $line2->{'fOO'}, undef,     'new - line2 - FOO' );

ok( close($csv_fh), 'new - close' );

use strict;
use warnings;

use Test::More tests => 43;
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

## test tie interface

eval { tie(*FH, 'Tie::Handle::CSV', '', header => [qw/ one two three /]) };
ok( $@, 'tie - bad - header' );
ok( tie(*FH, 'Tie::Handle::CSV', $tmp_file, header => [qw/ one tWo three /], force_lower => 1), 'tie - good - header' );

## test new() interface

open my $raw_csv_fh, '<', $tmp_file or die "$tmp_file: $!";

ok( my $csv_fh = Tie::Handle::CSV->new($raw_csv_fh, header => [qw/ one two thRee /], force_lower => 1), 'new - good - header' );
eval { Tie::Handle::CSV->new('', header => [qw/ one two three /]) };
ok( $@, 'new - bad - header' );

## test reading with no header

my $line1 = <FH>;
my $line2 = <FH>;
my $line3 = <FH>;
my $line4 = <FH>;

ok( ref $line1 eq 'Tie::Handle::CSV::Hash',              'tie - ref' );

ok( $line1 eq 'foo,bar,baz',            'tie - line1 - stringify' );
ok( $line2 eq 'potato,monkey,rutabaga', 'tie - line2 - stringify' );
ok( $line3 eq 'fred,barney,wilma',      'tie - line3 - stringify' );
ok(! defined $line4,                    'tie - line4 - undef' );

is( $line1->{'one'},   'foo',      'tie - line1 - one' );
is( $line1->{'two'},   'bar',      'tie - line1 - two' );
is( $line1->{'three'}, 'baz',      'tie - line1 - three' );
is( $line1->{'not'}, undef,        'tie - line1 - not' );

is( $line2->{'one'},   'potato',   'tie - line2 - one' );
is( $line2->{'two'},   'monkey',   'tie - line2 - two' );
is( $line2->{'three'}, 'rutabaga', 'tie - line2 - three' );
is( $line2->{'not'}, undef,        'tie - line2 - not' );

is( $line3->{'one'},   'fred',     'tie - line3 - one' );
is( $line3->{'two'},   'barney',   'tie - line3 - two' );
is( $line3->{'three'}, 'wilma',    'tie - line3 - three' );
is( $line3->{'not'}, undef,        'tie - line3 - not' );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;
$line4 = <$csv_fh>;

ok( ref $line1 eq 'Tie::Handle::CSV::Hash',              'new - ref' );

is( $csv_fh->header, 'one,two,thRee',     'new - header - string' );

is_deeply( [ @{ $csv_fh->header } ], [ 'one', 'two', 'thRee' ], 'new - header - array' );  

ok( $line1 eq 'foo,bar,baz',            'new - line1 - stringify' );
ok( $line2 eq 'potato,monkey,rutabaga', 'new - line2 - stringify' );
ok( $line3 eq 'fred,barney,wilma',      'new - line3 - stringify' );
ok(! defined $line4,                    'new - line4 - undef' );

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

ok( close(FH),      'tie - close' );
ok( close($csv_fh), 'new - close' );

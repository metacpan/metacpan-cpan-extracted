# Before `make install' is performed this script should be runnable with `make test'
# After `make install' it should work as `perl List.t'

#########################

use Test::More tests => 8;
BEGIN { use_ok('YVDHOVE::List', qw(:all)) };

#########################

my $debug = 0;

my @input01    = ('A', 'B', 'C', 'D');
my $expected01 = 'A;B;C;D';
my $result01   = ArrayToDelimitedList(\@input01, ';', $debug);

my %input02    = ( A => undef, B => undef, C => undef, D => undef);
my $expected02 = 'A;B;C;D';
my $result02   = HashToDelimitedList(\%input02, ';', $debug);

my $input03    = 'A;B;C;D';
my @expected03 = ('A', 'B', 'C', 'D');
my $result03   = DelimitedListToArray($input03, ';', 1, $debug);

my $input04    = 'A;B;C;D';
my @expected04 = ('A;B', 'C;D');
my $result04   = DelimitedListToArray($input04, ';', 2, $debug);

my $input05    = 'A;B;C;D';
my %expected05 = (A => undef, B => undef, C => undef, D => undef);
my $result05   = DelimitedListToHash($input05, ';', 1, $debug);

my $input06    = 'A;B;C;D';
my %expected06 = ('A;B' => undef, 'C;D' => undef);
my $result06   = DelimitedListToHash($input06, ';', 2, $debug);

my $input07    = 'A=B|C=D';
my %expected07 = (A => B, C => D);
my $result07   = DelimitedKeyValuePairToHash($input07, '\|', $debug);
 
is($result01, $expected01, 'ArrayToDelimitedList()');
is($result02, $expected02, 'HashToDelimitedList()');
is_deeply($result03, \@expected03, 'DelimitedListToArray()');
is_deeply($result04, \@expected04, 'DelimitedListToArray()');
is_deeply($result05, \%expected05, 'DelimitedListToHash()');
is_deeply($result06, \%expected06, 'DelimitedListToHash()');
is_deeply($result07, \%expected07, 'DelimitedKeyValuePairToHash()');
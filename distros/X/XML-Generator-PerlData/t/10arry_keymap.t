use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 13 }
use vars qw/@stack/;


my $dumper = SAXDumper->new();
my $tester = XML::Generator::PerlData->new( Handler => $dumper );


my @row_one   = ('a', 'b', 'c');

my %all_rows = ( one => {data => \@row_one} );

$tester->add_keymap( data => ['foo', 'bar', 'baz'] );

$tester->parse( \%all_rows );

ok( $stack[1]->{LocalName} eq 'document' );
ok( $stack[2]->{LocalName} eq 'one' );
ok( $stack[3]->{LocalName} eq 'foo' );
ok( $stack[4]->{Data} eq 'a' );
ok( $stack[5]->{LocalName} eq 'foo' );
ok( $stack[6]->{LocalName} eq 'bar' );
ok( $stack[7]->{Data} eq 'b' );
ok( $stack[8]->{LocalName} eq 'bar' );
ok( $stack[9]->{LocalName} eq 'baz' );
ok( $stack[10]->{Data} eq 'c' );
ok( $stack[11]->{LocalName} eq 'baz' );
ok( $stack[12]->{LocalName} eq 'one' );
ok( $stack[13]->{LocalName} eq 'document' );


# end main

package SAXDumper;
use strict;

use vars qw($AUTOLOAD);
    
sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto; 
    my $self = \%args;
    bless ($self, $class);
    return $self;
}   

    
sub AUTOLOAD {
    my ($self, $other) = @_;
    my $called_sub = $AUTOLOAD;
    $called_sub =~ s/.+:://; # snip pkg name... 
    return if $called_sub eq 'DESTROY';
    push (@main::stack, $other);
}

1;

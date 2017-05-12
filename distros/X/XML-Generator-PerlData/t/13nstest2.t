use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 5 }
use vars qw/@stack/;
my $obj     = SomeObj->new();
my $handler = SAXDumper->new;
my $tester  = XML::Generator::PerlData->new( Handler  => $handler );

my $NS = 'http://localhost/ns/default';

$tester->add_namespace( prefix => 'ubu',
                        uri    => 'http://localhost/ns/default'

                       );

my %attrmap = ( zoix => ['bar', 'norkel'] );

my %opts = ( attrmap => \%attrmap,
             skipelements => ['freep'],
             namespacemap => {'http://localhost/ns/default' => [ 'document' ]},
             keymap => {baz => 'norkel'}
           );

my $dom = $tester->parse( $obj, %opts );


ok( $stack[1]->{Prefix} eq 'ubu' );
ok( $stack[1]->{NamespaceURI} eq 'http://localhost/ns/default' );
ok( $stack[2]->{LocalName} eq 'document' );
ok( $stack[2]->{Prefix} eq 'ubu' );
ok( $stack[2]->{Name} eq 'ubu:document' );

package SomeObj;
use strict;

sub new {
    my $proto = shift;
    my %args = @_;

my %sh = (foo => 'foobie',
          bar => 'barbie',
          baz => 'bazly'
         );

my @sa = ( 'one', 'two', 'three' );
my @sa2 = ( 'four', 'five', 'six' );
my @sa3 = ( 'seven', 'eight', 'nine' );

my %hashofrefs = (array => \@sa,
                  hash  => \%sh
                 );
my @aofas = ( \@sa, \@sa2, \@sa3 );

my %sh2 = (foo  => 'foobie',
           zoix => \%sh,
           bar  => 'barbie',
           hork => \@sa,
           baz  => 'bazly',
           bibble => \%hashofrefs,
           freep => 'funk',
           fibble => \@aofas           
          );

    $args{yick} = \%sh2;

    
    my $class = ref( $proto ) || $proto;
    my $self = bless( \%args, $class );
    return $self;
}

1;

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

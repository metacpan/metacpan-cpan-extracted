use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 35 }
use vars qw/@stack/;
my $obj     = SomeObj->new();
my $handler = SAXDumper->new;
my $tester  = XML::Generator::PerlData->new( Handler  => $handler );

my $NS = 'http://localhost/ns/default';

$tester->add_namespace( prefix => 'foo',
                        uri    => 'http://localhost/ns/foo'
                       );

$tester->add_namespace( prefix => 'bar',
                        uri    => 'http://localhost/ns/bar'
                       );

$tester->add_namespace( prefix => 'baz',
                        uri    => 'http://localhost/ns/baz'
                       );


my %opts = ( namespacemap => {'http://localhost/ns/foo' => [ 'document', 'grandchild' ],
                              'http://localhost/ns/bar' => 'parent',
                              'http://localhost/ns/baz' => 'child'
                             }
           );

my $dom = $tester->parse( $obj, %opts );

ok( defined $stack[1]->{Prefix} and  defined $stack[1]->{NamespaceURI} );
ok( defined $stack[2]->{Prefix} and  defined $stack[1]->{NamespaceURI} );
ok( defined $stack[3]->{Prefix} and  defined $stack[1]->{NamespaceURI} );


ok( $stack[4]->{Prefix} eq 'foo' );
ok( $stack[4]->{Name} eq 'foo:document' );
ok( $stack[4]->{NamespaceURI} eq 'http://localhost/ns/foo' );

ok( $stack[5]->{LocalName} eq 'parent' );
ok( $stack[5]->{Prefix} eq 'bar' );
ok( $stack[5]->{Name} eq 'bar:parent' );
ok( $stack[5]->{NamespaceURI} eq 'http://localhost/ns/bar' );

ok( $stack[6]->{LocalName} eq 'child' );
ok( $stack[6]->{Prefix} eq 'baz' );
ok( $stack[6]->{Name} eq 'baz:child' );
ok( $stack[6]->{NamespaceURI} eq 'http://localhost/ns/baz' );

ok( $stack[7]->{LocalName} eq 'grandchild' );
ok( $stack[7]->{Prefix} eq 'foo' );
ok( $stack[7]->{Name} eq 'foo:grandchild' );
ok( $stack[7]->{NamespaceURI} eq 'http://localhost/ns/foo' );

ok( $stack[8]->{Data} eq 'grandchildtext' );

ok( $stack[9]->{LocalName} eq 'grandchild' );
ok( $stack[9]->{Prefix} eq 'foo' );
ok( $stack[9]->{Name} eq 'foo:grandchild' );
ok( $stack[9]->{NamespaceURI} eq 'http://localhost/ns/foo' );

ok( $stack[10]->{LocalName} eq 'child' );
ok( $stack[10]->{Prefix} eq 'baz' );
ok( $stack[10]->{Name} eq 'baz:child' );
ok( $stack[10]->{NamespaceURI} eq 'http://localhost/ns/baz' );

ok( $stack[11]->{LocalName} eq 'parent' );
ok( $stack[11]->{Prefix} eq 'bar' );
ok( $stack[11]->{Name} eq 'bar:parent' );
ok( $stack[11]->{NamespaceURI} eq 'http://localhost/ns/bar' );

ok( $stack[12]->{LocalName} eq 'document' );
ok( $stack[12]->{Prefix} eq 'foo' );
ok( $stack[12]->{Name} eq 'foo:document' );
ok( $stack[12]->{NamespaceURI} eq 'http://localhost/ns/foo' );

package SomeObj;
use strict;

sub new {
    my $proto = shift;

    my %args = ( 
                 parent => { child  => { grandchild => 'grandchildtext' }},
               );

    
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

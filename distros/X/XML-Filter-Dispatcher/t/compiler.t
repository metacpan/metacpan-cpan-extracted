use Test;
use XML::Filter::Dispatcher::Compiler qw( xinline );
use strict;

my $c;
my $code;
my $package_code;
my $actions;
my @out;

my @tests = (
##
## Check the internal compiler
##
sub {
    $c = XML::Filter::Dispatcher::Compiler->new(
        Rules => [
            'a' => sub { push @out, 'a' },
            'b' => sub { push @out, 'b' },
        ],
    );

    ok $c->isa( "XML::Filter::Dispatcher::Compiler" );
},

sub {
    ( $code, $actions ) = $c->_compile;
    ok $code, qr/('a'.*'b')|('b'.*'a')/s;
},

sub {
    ok 0+@$actions, 2;
},

##
## Check the package builder
##
sub {
    $package_code = $c->compile(
        Package  => "My::Filter1",
        Import   => [qw( xvalue )],
        Preamble => q{use vars qw( @o );},
#        Debug => 1,
        Rules       => [
            'a' => xinline q{push @o, 'a'},
            'b' => xinline q{push @o, 'b'},
            'c' => "Handler",
        ],
    );
    ok $package_code, qr/('a'.*'b')|('b'.*'a')/s;
},


sub {
    my $ok = eval $package_code;
    my $c = $package_code;
    unless ( $ok ) {
        my $i = 0;
        $c =~ s/^/sprintf "%3d|", ++$i/mge;
    }
    
    ok $ok ? "" : $@ . $c, "";
},

sub {
    my $f = My::Filter1->new( Handler => H->new );
    $f->start_document( {} );
    $f->start_element( { Name => 'a' } );
    $f->start_element( { Name => 'b' } );
    $f->start_element( { Name => 'c' } );
    $f->start_element( { Name => 'd' } );
    ok join( ",", @My::Filter1::o ), "a,b,c";
},

);

plan tests => 0+@tests;

$_->() for @tests;

package H;

use XML::SAX::Base;
BEGIN { @H::ISA = qw( XML::SAX::Base ); }

sub start_element { push @My::Filter1::o, "c" }

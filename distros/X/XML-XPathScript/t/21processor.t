use strict;
use warnings;

use Test::More tests => 8;

use XML::XPathScript;
use XML::XPathScript::Processor;
use XML::XPathScript::Template;

my $xps = XML::XPathScript->new;
$xps->set_xml( '<doc><foo>I am the walrus!</foo></doc>' );

my $template = XML::XPathScript::Template->new;
$template->set( 'foo' => { rename => 'bar' } );

##### OO call ##############################################

my $processor = $xps->processor;
$processor->set_template( $template );

is $processor->apply_templates( '//foo' ) => '<bar>I am the walrus!</bar>';

#### functional call #######################################

eval {
    package Foo;
    apply_templates( '//foo' );
};
ok $@, "can't call apply_templates without import";

my $result = do {
    package Foo2;
    $processor->import_functional;
    apply_templates( '//foo' );
};

is $result => '<bar>I am the walrus!</bar>', 
                'functional import of the processor';

{
    package Foo3;
    $processor->import_functional( 'xps_' );
}

is eval { Foo3::apply_templates( '//foo' ); } => undef;
is eval { Foo3::xps_apply_templates( '//foo' ); } 
    => '<bar>I am the walrus!</bar>';

$result = eval {
    package Foo4;
    XML::XPathScript::Processor->import_functional;
    set_dom( $xps->{dom} );
    set_template( $template );
    apply_templates( '//foo' );  
};

is $@ => '';
is $result => '<bar>I am the walrus!</bar>', 
                'functional import of the processor, class-level';


is $processor->apply_templates( '/path/to/nowhere' ) => undef,
    "apply_templates with a path without match";


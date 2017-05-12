use strict;
use warnings;

use Test::More tests => 3;

use XML::XPathScript;
use XML::XPathScript::Template;
use XML::XPathScript::Processor qw/ DO_SELF_AND_KIDS /;

my $xps = XML::XPathScript->new;

$xps->set_xml( <<'END_XML' );
    <doc><foo/></doc>
END_XML

my $processor = $xps->processor;
my $template = XML::XPathScript::Template->new;
$processor->set_template( $template );
$template->set( foo => { testcode => \&tc_foo } );
sub tc_foo {
    my( $n, $t, $p ) = @_;

    $t->set({ pre => join ":", map { $_ . '=' . $p->{$_} } keys %$p });

    return DO_SELF_AND_KIDS();
}


is $processor->apply_templates( ) => '<doc></doc>';
is $processor->apply_templates( { mode => 'normal' } ) 
                                    => '<doc>mode=normal</doc>';
is $processor->apply_templates( '//foo' =>  { mode => 'normal' } ) 
    => 'mode=normal', 'apply_template( $path, \%params )';



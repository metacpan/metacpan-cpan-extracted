use strict;
use warnings;

use Test::More tests => 5;                      # last test to print

use XML::XPathScript;
use XML::XPathScript::Template;
use XML::XPathScript::Processor;

# rename

my $xml = '<doc><foo>ttt</foo></doc>';
my $stylesheet = q#<%  $t->set( foo => { rename => 'bar' } ) %><%~ / %>#;

my $xps = XML::XPathScript->new;
is $xps->transform( $xml => $stylesheet ) 
    => '<doc><bar>ttt</bar></doc>', 'rename tag';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $processor = $xps->processor;
my $template = XML::XPathScript::Template->new;
$processor->set_template( $template );

$xps->set_xml( <<END_XML );
<doc>
    <foo>
        <one/>
        <two/>
        <three/>
    </foo>
</doc>
END_XML

$template->set( foo => {
    showtag      => 1,
    pre          => '[pre {name()}]',
    intro        => '[intro {name()}]',
    prechildren  => '[prechildren {name()}]',
    prechild     => '[prechild {name()}]',
    postchild    => '[postchild {name()}]',
    postchildren => '[postchildren {name()}]',
    extro        => '[extro {name()}]',
    post         => '[post {name()}]',
} );

        # adding the "\n" is a kludge to use the <<here 
is $processor->apply_templates()."\n" => <<END_EXPECTED, 'display tags as strings with interpolation';
<doc>
    [pre foo]<foo>[intro foo][prechildren foo]
        [prechild one]<one></one>[postchild one]
        [prechild two]<two></two>[postchild two]
        [prechild three]<three></three>[postchild three]
    [postchildren foo][extro foo]</foo>[post foo]
</doc>
END_EXPECTED

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$template = XML::XPathScript::Template->new;
$processor->set_template( $template );

$template->set( foo => {
    showtag      => 1,
    map { $_ => gen_sub( $_ ) } 
        qw/ pre intro prechildren prechild postchild postchildren extro post /
} );

sub gen_sub {
    my $tag = shift;
    return sub {
        my ( $n, $t, $p ) = @_;
        my $name = $n->findvalue( 'name()' );
        return "#$tag $name $p->{p}#";
    }
}

is $processor->apply_templates( { p => '!' } )."\n" => <<END_EXPECTED, 'display tags as functions';
<doc>
    #pre foo !#<foo>#intro foo !##prechildren foo !#
        #prechild one !#<one></one>#postchild one !#
        #prechild two !#<two></two>#postchild two !#
        #prechild three !#<three></three>#postchild three !#
    #postchildren foo !##extro foo !#</foo>#post foo !#
</doc>
END_EXPECTED

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$template = XML::XPathScript::Template->new;
$processor->set_template( $template );
$xps->set_xml( '<doc>palyndrome</doc>' );

$template->set( 'text()' => {
    pre => sub { 
        my ( $n, $t, $p ) = @_;
        return reverse $n->findvalue( 'string()' );
    }
} );

is $processor->apply_templates() => '<doc>emordnylap</doc>',
    'text() with function pre';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$template = XML::XPathScript::Template->new;
$processor->set_template( $template );
$xps->set_xml( '<doc><!-- palyndrome --></doc>' );

$template->set( 'comment()' => {
    action => $DO_SELF_ONLY,
    pre => sub { 
        my ( $n, $t, $p ) = @_;
        return reverse $n->findvalue( 'string()' );
    }
} );

is $processor->apply_templates() => '<doc> emordnylap </doc>',
    'comment() with function pre';

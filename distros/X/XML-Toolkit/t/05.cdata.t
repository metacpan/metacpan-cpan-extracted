#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;
use Test::XML;

use aliased 'XML::Toolkit::Config::Container' => 'XMLTK::App';

use aliased 'XML::Toolkit::Generator';

{
    my $xml = '<code><![CDATA[<crackers & cheese>]]></code>';

    ok( my $builder = XMLTK::App->new(xmlns => { '' => 'MyApp' })->builder, 'Build XML::Toolkit::Builder' );
    lives_ok { $builder->parse_string($xml) } 'parsed the xml';
    ok( my $code = $builder->render(), 'render code' );

    eval $code;
    if ($@) {
        diag "Couldn't EVAL code $@";
        done_testing;
        exit;
    }

    ok( my $loader = XMLTK::App->new(xmlns => { '' => 'MyApp' })->loader, 'Build XML::Toolkit::Loader' );
    $loader->parse_string($xml);
    ok( my $root = $loader->root_object, 'extract root object' );

    ok( $root->text, 'have text' );

    ok( my $generator = XMLTK::App->new( xmlns => { '' => '' } )->generator,
        'Build XML::Toolkit::Loader' );
    $generator->render_object($root);
    my $output = join( '', $generator->output );
    is_xml( $xml, $output, 'XML compares' );
    like( $output, qr/CDATA/, 'have a CDATA section' );
}
{
    my $xml = '<code>&lt;crackers &amp; cheese&gt;</code>';
    ok( my $builder = XMLTK::App->new(xmlns => { '' => 'MyApp' })->builder, 'Build XML::Toolkit::Builder' );
    lives_ok { $builder->parse_string($xml) } 'parsed the xml';
    ok( my $code = $builder->render(), 'render code' );

    eval $code;
    if ($@) {
        diag "Couldn't EVAL code $@";
        done_testing;
        exit;
    }

    ok( my $loader = XMLTK::App->new(xmlns => { '' => 'MyApp' })->loader, 'Build XML::Toolkit::Loader' );
    $loader->parse_string($xml);
    ok( my $root = $loader->root_object, 'extract root object' );

    ok( $root->text, 'have text' );

    ok( my $generator = XMLTK::App->new( xmlns => { '' => '' } )->generator,
        'Build XML::Toolkit::Loader' );
    $generator->render_object($root);
    my $output = join( '', $generator->output );
    is_xml( $xml, $output, 'XML compares' );
    unlike( $output, qr/CDATA/, 'have a CDATA section' );
}

done_testing;

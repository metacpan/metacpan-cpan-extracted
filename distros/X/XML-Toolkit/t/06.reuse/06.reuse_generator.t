#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;
use Test::XML;

use aliased 'XML::Toolkit::Config::Container' => 'XMLTK::App';

use aliased 'XML::Toolkit::Generator';

my $xml = <<'END_XML';
<?xml version="1.0"?>
<note>
    <to>Tove</to>
    <from>Jani</from>
    <heading>Reminder</heading>
    <body>Don't forget me this weekend!</body>
</note>
END_XML

my $xml2 = <<'END_XML';
<note>
    <to>Jani</to>
    <from>Tove</from>
    <heading>Re: Reminder</heading>
    <body>Bite me.</body>
</note>
END_XML

my $app = XMLTK::App->new( xmlns => { '' => 'MyTest' } );
my $builder = $app->builder;
$builder->parse_string($xml);
eval $builder->render();
if ($@) {
    diag "Couldn't EVAL code $@";
    done_testing;
    exit;
}

my $loader = XMLTK::App->new( xmlns => { '' => 'MyTest' } )->loader;
$loader->parse_string($xml);
my $root = $loader->root_object;

$loader->parse_string($xml2);
my $root2 = $loader->root_object;

ok( $root != $root2, 'root and root2 are different' );

ok( my $generator = XMLTK::App->new( xmlns => { '' => '' } )->generator,
    'Build XML::Toolkit::Loader' );
$generator->render_object($root);
my $output = join( '', $generator->output );
is_xml( $xml, $output, 'XML compares' );

lives_ok { $generator->render_object($root2) } 'reused generator';
my $output2 = join( '', $generator->output );
is_xml( $xml2, $output2, 'Second XML compares' );

done_testing;

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

ok( my $loader = XMLTK::App->new( xmlns => { '' => 'MyTest' } )->loader,
    'Build XML::Toolkit::Loader' );
lives_ok { $loader->parse_string($xml) } 'loader parsed';
ok( my $root = $loader->root_object, 'extract root object' );

lives_ok { $loader->parse_string($xml2), 'parse new xml' } 'loader parsed again';
ok( my $root2 = $loader->root_object, 'extract second root object' );

ok($root != $root2, 'root and root2 are different');

done_testing;

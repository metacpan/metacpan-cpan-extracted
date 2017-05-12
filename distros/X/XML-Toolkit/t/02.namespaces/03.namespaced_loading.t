#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use aliased 'XML::Toolkit::Config::Container' => 'XMLTK::App';

my $xml1 = <<'END_XML';
<root xmlns:a="a" xmlns:b="b">
    <a:one>oneA</a:one>
    <b:one>twoB</b:one>
</root>
END_XML

my $xml2 = <<'END_XML';
<root xmlns:y="a" xmlns:z="b">
    <y:one>oneY</y:one>
    <z:one>twoZ</z:one>
</root>
END_XML

my $args = {
    namespace_map => {
        ''  => 'MyApp',
        'a' => 'A',
        'b' => 'B',
    },
};

my $root_class_name = 'MyApp::Root';

eval {
    my $builder = XMLTK::App->new($args)->builder;
    $builder->parse_string($xml2);
    my $code = $builder->render();
    eval $code;
    ok( Class::MOP::is_class_loaded($root_class_name),
        "$root_class_name is loaded" );
    my $root = MyApp::Root->new();
    isa_ok( $root, $root_class_name );
};

eval {
    my $loader = XMLTK::App->new($args)->loader;
    $loader->parse_string($xml1);
    my $root = $loader->root_object;
    isa_ok( $root, $root_class_name );

    # FIXME: Need to pull out the data here
    #ok($root->text eq 'test1', 'root node text was not loaded correctly');
};

eval {
    my $loader = XMLTK::App->new($args)->loader;
    $loader->parse_string($xml2);
    my $root = $loader->root_object;
    isa_ok( $root, $root_class_name );

    # FIXME:: Need to pull out the data here
    #ok($root->text eq 'test2', 'root node text was not loaded correctly');
};

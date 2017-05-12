#!/usr/bin/env perl
use Test::More;
use Test::XML;
use Test::Deep;

use Path::Class qw(dir);

my $test_dir = dir('t/data');

use aliased 'XML::Toolkit::Config::Container' => 'XMLTK::App';
use aliased 'XML::Toolkit::Loader';
use aliased 'XML::Toolkit::Generator';

ok(
    my $app = XMLTK::App->new(
        xmlns => {
            ''                       => 'XMLTK::Test',
            'http://example.org/my/' => 'My'
        }
    )
);

ok( my $builder = $app->builder );

my $xml = '<foo xmlns:my="http://example.org/my/"><my:bar /></foo>';

$builder->parse_string($xml);
my $class = $builder->render;

ok( defined $class, 'build a class' );
eval $class;
can_ok( 'XMLTK::Test::Foo', 'new' );
can_ok( 'My::Bar',          'new' );

ok( my $loader = $app->loader, 'Build XML::Toolkit::Loader' );
$loader->parse_string($xml);
my $tree = $loader->root_object;
ok( $tree, 'parse_string' );

ok(
    my $generator = XMLTK::App->new(
        xmlns => {
            ''   => '',
            'my' => 'http://example.org/my/',
        }
      )->generator
);
$generator->render_object($tree);
ok( my $output = join( '', $generator->output ), 'got output' );
is_xml( $output, $xml, 'got the right XML' );

{
    my $tree2 = XMLTK::Test::Foo->new(  bars => [ My::Bar->new ] );    
    ok(
        my $generator = XMLTK::App->new(
            xmlns => {
                ''   => '',
                'my' => 'http://example.org/my/',
            }
          )->generator
    );
    $generator->render_object($tree2);
    ok( my $output = join( '', $generator->output ), 'got output' );
    # is_deeply( $tree, $tree2 );
    is_xml( $output, $xml, 'got the right XML' );
}

done_testing;

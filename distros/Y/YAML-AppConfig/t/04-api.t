use strict;
use warnings;
use Test::More tests => 24;
do "t/lib/helpers.pl";

BEGIN { use_ok('YAML::AppConfig') }

# TEST: config and config_keys
{
    my $app = YAML::AppConfig->new( file => 't/data/config.yaml' );
    ok( $app, "Object created." );
    is_deeply( $app->config, { foo => 1, bar => 2, eep => '$foo' },
        "config() method." );
    is_deeply( [ $app->config_keys ], [qw(bar eep foo)],
        "config_keys() method." );
}

# TEST: merge
{
    my $app = YAML::AppConfig->new( file => 't/data/basic.yaml' );
    ok( $app, "Object created." );
    is( $app->get_foo, 1, "Checking foo before merge()." );
    is( $app->get_bar, 2, "Checking bar before merge()." );
    $app->merge( file => 't/data/merge.yaml' );
    is( $app->get_foo, 2,  "Checking foo after merge()." );
    is( $app->get_bar, 2,  "Checking bar after merge()." );
    is( $app->get_baz, 3, "Checking bar after merge()." );
}

# TEST: resolve
{
    my $yaml = <<'YAML';
---
foo: hello
bar: $foo world
circ1: $circ2
circ2: $circ1
cows:
    - are
    - wonderful
    - $bar
YAML

    my $app = YAML::AppConfig->new( string => $yaml );
    ok($app, "Object loaded");
    is(
        $app->resolve('I like $bar a lot'), 'I like hello world a lot',
        'Testing our resolve()'
    );
    is_deeply(
        $app->resolve('$cows'),
        [qw(are wonderful), "hello world"],
        'Testing our resolve() with references',
    );
    eval { $app->resolve('$circ1 is a loop!') };
    like( $@, qr/Circular reference/,
        'Testing our resolve() with circular refs' );
    my $template = { qux => '$foo is good', baz => [ '$foo', '$cows' ] };
    my $new = $app->resolve($template);
    isnt( $new, $template, "Testing we did not smash our old object" );
    is_deeply(
        $new,
        {
            qux => 'hello is good',
            baz => [ 'hello', [ qw(are wonderful), "hello world" ], ],
        },
        "Testing our resolve() with nested structures."
    );
}

# TEST: dump
{
    my $yaml = "---\nfoo: 1\nbar: 2\n";
    my $app = YAML::AppConfig->new( string => $yaml );
    ok( $app, "Object created." );
    $app->set_foo(42);
    my $dump = $app->dump();
    like( $dump, qr/foo:\s*42/, "Testing dump()" );
    like( $dump, qr/bar:\s*2/,  "Testing dump()" );

    my $file = 't/data/dump.yaml';
    $app->dump($file);
    ok( ( -f $file ), "Testing dump() with file: $file" );
    ok( open( FILE, $file ), "Opening file: $file" );
    my $text = join( "", <FILE> );
    like( $text, qr/foo:\s*42/, "Testing dump() with file: $file" );
    like( $text, qr/bar:\s*2/,  "Testing dump() with file: $file" );
    is( $text, $dump, "Testing that dump() and dump() to file are same" );
}

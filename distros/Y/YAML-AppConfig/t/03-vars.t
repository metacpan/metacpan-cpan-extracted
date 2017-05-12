use strict;
use warnings;
use Test::More tests => 56;
do "t/lib/helpers.pl";
use Storable qw(dclone);

BEGIN { use_ok('YAML::AppConfig') }

# TEST: Variable usage.
{
    my $app = YAML::AppConfig->new( file => 't/data/vars.yaml' );
    ok($app, "Created object.");

    # Check basic retrieval
    is( $app->get_dapper, "life", "Checking variables." );
    is( $app->get_breezy, "life is good", "Checking variables." );
    is( $app->get_hoary, "life is good, but so is food",
        "Checking variables." );
    is( $app->get_stable,
        "life is good, but so is food and so, once again, life is good.",
        "Checking variables." );
    is( $app->get_nonvar, '$these are $non $vars with a var, life',
        "Checking variables." );

    # Check get()'s no resolve flag
    is( $app->get( 'breezy', 1 ), '$dapper is good',
        "Checking variables, no resolve." );
    is( $app->get_hoary(1), '$breezy, but so is food',
        "Checking variables, no resolve." );

    # Check basic setting
    $app->set_dapper("money");
    is( $app->get_dapper, "money", "Checking variables." );
    is( $app->get_breezy, "money is good", "Checking variables." );
    is( $app->get_hoary, "money is good, but so is food",
        "Checking variables." );
    is( $app->get_stable,
        "money is good, but so is food and so, once again, money is good.",
        "Checking variables." );
    is( $app->get_nonvar, '$these are $non $vars with a var, money',
        "Checking variables." );

    # Check that our circular references break.
    for my $n ( 1 .. 4 ) {
        my $method = "get_circ$n";
        eval { $app->$method };
        like( $@, qr/Circular reference/, "Checking that get_circ$n failed" );
    }

    # Break the circular reference.
    $app->set_circ1("dogs");
    is($app->get_circ1, "dogs", "Checking circularity removal.");
    is($app->get_circ2, "dogs lop bop oop", "Checking circularity removal.");
    is($app->get_circ3, "dogs lop bop", "Checking circularity removal.");
    is($app->get_circ4, "dogs lop", "Checking circularity removal.");

    # Test that we references load up in the expected way within scalars.
    like(
        $app->get_refs, 
        qr/^ARRAY\(.*?\) will not render, nor will HASH\(.*?\)$/,
        "Checking that references are not used as variables." 
    );

    # Test that nesting and interpolation of references works
    my $nestee = {
        food => 'money',
        drink => [{ cows => [qw(are good)]}, "money is good and moneyyummy"],
    };
    is_deeply(
        $app->get_nest1,
        {
            blah => ["harry potter", "golem", "mickey mouse", $nestee],
            loop => {foopy => [$nestee, "money is good"], boop => $nestee},
        },
        "Checking variable interpolation with references."
    );

    # Make sure circular references between references breaks
    eval { $app->get_circrefref1 };
    like( $@, qr/Circular reference/, "Checking that get_circreref1 failed" );

    # Look in the heart of our deep data structures
    is_deeply($app->get_list,
      [[[[[[[
        [
         'money', 
         "money is good, but so is food and so, once again, money is good.",
        ], 
        "money is good, but so is food" 
      ]]]]]]], "Testing nested list.");
    is_deeply(
        $app->get_hash,
        {
            key => {
                key => {
                    key => {
                        key => { key => 'money is good', other => 'money' },
                        something => 'money'
                    }
                }
            }
        },
        "Testing nested hash."
    );
}

# TEST: no_resolve
{
    my $app
        = YAML::AppConfig->new( file => 't/data/vars.yaml', no_resolve => 1 );
    ok($app, "Created object.");

    # Check basic retrieval
    is( $app->get_dapper, "life", "Checking variables, no_resolve => 1" );
    is( $app->get_breezy, '$dapper is good',
        "Checking variables, no_resolve => 1" );
    is(
        $app->get_hoary, '$breezy, but so is food',
        "Checking variables, no_resolve => 1"
    );
    is(
        $app->get_stable,
        '$hoary and so, once again, $breezy.',
        "Checking variables, no_resolve => 1"
    );
    is(
        $app->get_nonvar, '$these are $non $vars with a var, $dapper',
        "Checking variables, no_resolve => 1"
    );
}

# TEST: Substituting in a variable with no value does not produce warnings
{
    my $app = YAML::AppConfig->new( string => "---\nnv:\nfoo: \$nv bar\n" );
    ok($app, "Object created");
    local $SIG{__WARN__} = sub { die };
    eval { $app->get_nv };
    ok( !$@, "Getting a setting with no value does not produce warnings." );
    eval { $app->get_foo };
    ok( !$@, "Getting a setting using a no value variable does not warn." );
    is( $app->get_foo, " bar", "No value var used as empty string." );
}

# TEST: Make sure ${foo} style vars work.
{
    my $yaml =<<'YAML';
---
xyz: foo
xyzbar: bad
'{xyzbar': bad
'xyz}bar': bad
test1: ${xyz}bar
test2: ${xyzbar
test3: $xyz}bar
YAML
    my $app = YAML::AppConfig->new( string => $yaml );
    ok($app, "Object created");
    is( $app->get_test1, 'foobar', "Testing \${foo} type variables." );
    is( $app->get_test2, '${xyzbar', "Testing \${foo} type variables." );
    is( $app->get_test3, 'foo}bar', "Testing \${foo} type variables." );
}

# TEST: Escaping of variables.
{
    my $yaml =<<'YAML';
---
paulv: likes cheese
nosubst: \$paulv a lot
usens: $nosubst \$paulv $paulv \\\$paulv \\$paulv cows.
YAML
    my $ESCAPE_N = 10;

    # Add \\$paulv, \\\$paulv, \\\\$paulv, ...
    for my $n (1 .. $ESCAPE_N) {
        $yaml .= "literal$n: " . '\\'x$n . "\\\$paulv stuffs\n";
    }
    my $app = YAML::AppConfig->new( string => $yaml );
    ok($app, "Object created");

    for my $n (1 .. $ESCAPE_N)  {
        my $string = '\\'x$n . '$paulv stuffs';
        is( $app->get("literal$n"), $string, "Testing escapes: $string" );
    }
    is( $app->get_usens, 
        '$paulv a lot $paulv likes cheese \\\\$paulv \\$paulv cows.',
        "Testing vars with escapes." );
}

# TEST: self-circular references
{
    my $yaml = <<'YAML';
---
foo: $foo
bar:
   - cows
   - $bar
YAML
    my $app = YAML::AppConfig->new( string => $yaml );
    ok( $app, "Object loaded" );
    eval { $app->get_foo };
    like( $@, qr/Circular reference/, "Testing self-circular references. " );
    eval { $app->get_bar };
    like( $@, qr/Circular reference/, "Testing self-circular references. " );
}

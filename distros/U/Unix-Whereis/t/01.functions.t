use Test::More tests => 92;
use File::Temp;
use File::Slurp;

use Unix::Whereis;

diag("Testing Unix::Whereis $Unix::Whereis::VERSION");

#################
#### pathsep() ##
#################

{
    my %copy = %Config::Config;
    untie %Config::Config;
    local %Config::Config = ();

    delete $Config::Config{'path_sep'};    # just in case
    is( Unix::Whereis::pathsep(), ':', q{pathsep() no $Config{'path_sep'} does default} );

    Unix::Whereis::pathsep("Y");
    is( Unix::Whereis::pathsep(), 'Y', q{pathsep() arg is used} );
    is( Unix::Whereis::pathsep(), 'Y', q{pathsep() cache is used} );

    Unix::Whereis::pathsep(undef);
    is( Unix::Whereis::pathsep(), ':', q{pathsep() undef results in re-set} );

    $Config::Config{'path_sep'} = '';
    Unix::Whereis::pathsep(undef);
    is( Unix::Whereis::pathsep(), ':', q{pathsep() $Config{'path_sep'} = '' does default} );

    $Config::Config{'path_sep'} = undef;
    Unix::Whereis::pathsep(undef);
    is( Unix::Whereis::pathsep(), ':', q{pathsep() $Config{'path_sep'} = undef does default} );

    $Config::Config{'path_sep'} = 'X';
    Unix::Whereis::pathsep(undef);
    is( Unix::Whereis::pathsep(), 'X', q{pathsep() Custom $Config{'path_sep'} is used} );
    is( Unix::Whereis::pathsep(), 'X', q{pathsep() cache is used w/ Custom $Config{'path_sep'} value} );

    $Unix::Whereis::sep = 'Z';
    is( Unix::Whereis::pathsep(), 'Z', q{pathsep() manual set global is used} );

    # reset for remaining tests
    delete $Config::Config{'path_sep'};
    undef $Unix::Whereis::sep;
}

#########################
#### _build_env_path() ##
#########################

# basic main value
is( Unix::Whereis::_build_env_path( {} ), $ENV{PATH}, "defaults to PATH only" );
is( Unix::Whereis::_build_env_path( { mypath => "foo:bar" } ),      'foo:bar',  'mypath is used instead of PATH' );
is( Unix::Whereis::_build_env_path( { mypath => "" } ),             $ENV{PATH}, 'mypath of zero length is not used' );
is( Unix::Whereis::_build_env_path( { mypath => undef } ),          $ENV{PATH}, 'mypath of undef length is not used' );
is( Unix::Whereis::_build_env_path( { mypath => 0 } ),              "0",        'mypath of zero is used' );
is( Unix::Whereis::_build_env_path( { mypath => ":foo:bar:" } ),    'foo:bar',  'surrounding seperators are removed from main value' );
is( Unix::Whereis::_build_env_path( { mypath => "::foo:bar:::" } ), 'foo:bar',  'multiple surrounding seperators are removed from main value' );

# no value:
is( Unix::Whereis::_build_env_path( { prepend => "" } ), $ENV{PATH}, "prepend empty" );
is( Unix::Whereis::_build_env_path( { append  => "" } ), $ENV{PATH}, "append empty" );
is( Unix::Whereis::_build_env_path( { prepend => "", append => "" } ), $ENV{PATH}, "append and prepend empty" );

is( Unix::Whereis::_build_env_path( { mypath => "", prepend => "" } ), $ENV{PATH}, "mypath and prepend empty" );
is( Unix::Whereis::_build_env_path( { mypath => "", append  => "" } ), $ENV{PATH}, "mypath and append empty" );
is( Unix::Whereis::_build_env_path( { mypath => "", prepend => "", append => "" } ), $ENV{PATH}, "mypath, append, and prepend empty" );

# value is undef == same as no value but possible uninit warnings
is( Unix::Whereis::_build_env_path( { prepend => undef() } ), $ENV{PATH}, "prepend undef" );
is( Unix::Whereis::_build_env_path( { append  => undef() } ), $ENV{PATH}, "append undef" );
is( Unix::Whereis::_build_env_path( { prepend => undef(), append => undef() } ), $ENV{PATH}, "append and prepend undef" );

is( Unix::Whereis::_build_env_path( { mypath => undef(), prepend => undef() } ), $ENV{PATH}, "mypath and prepend undef" );
is( Unix::Whereis::_build_env_path( { mypath => undef(), append  => undef() } ), $ENV{PATH}, "mypath and append undef" );
is( Unix::Whereis::_build_env_path( { mypath => undef(), prepend => undef(), append => undef() } ), $ENV{PATH}, "mypath, append, and prepend undef" );

# value is zero
is( Unix::Whereis::_build_env_path( { prepend => "0" } ), "0:$ENV{PATH}", "prepend zero" );
is( Unix::Whereis::_build_env_path( { append  => "0" } ), "$ENV{PATH}:0", "append zero" );
is( Unix::Whereis::_build_env_path( { prepend => "0", append => "0" } ), "0:$ENV{PATH}:0", "append and prepend zero" );

is( Unix::Whereis::_build_env_path( { mypath => "0", prepend => "0" } ), "0:0", "mypath and prepend zero" );
is( Unix::Whereis::_build_env_path( { mypath => "0", append  => "0" } ), "0:0", "mypath and append zero" );
is( Unix::Whereis::_build_env_path( { mypath => "0", prepend => "0", append => "0" } ), "0:0:0", "mypath, append, and prepend zero" );

# value w/ no surrounding sep
is( Unix::Whereis::_build_env_path( { prepend => "pre:pend" } ), "pre:pend:$ENV{PATH}", "prepend no surrounding sep" );
is( Unix::Whereis::_build_env_path( { append  => "ap:pend" } ),  "$ENV{PATH}:ap:pend",  "append no surrounding sep" );
is( Unix::Whereis::_build_env_path( { prepend => "pre:pend", append => "ap:pend" } ), "pre:pend:$ENV{PATH}:ap:pend", "append and prepend no surrounding sep" );

is( Unix::Whereis::_build_env_path( { mypath => "my:path", prepend => "pre:pend" } ), "pre:pend:my:path", "mypath and prepend no surrounding sep" );
is( Unix::Whereis::_build_env_path( { mypath => "my:path", append  => "ap:pend" } ),  "my:path:ap:pend",  "mypath and append no surrounding sep" );
is( Unix::Whereis::_build_env_path( { mypath => "my:path", prepend => "pre:pend", append => "ap:pend" } ), "pre:pend:my:path:ap:pend", "mypath, append, and prepend no surrounding sep" );

# value w/ left side sep
is( Unix::Whereis::_build_env_path( { prepend => ":pre:pend" } ), "pre:pend:$ENV{PATH}", "prepend left side sep" );
is( Unix::Whereis::_build_env_path( { append  => ":ap:pend" } ),  "$ENV{PATH}:ap:pend",  "append left side sep" );
is( Unix::Whereis::_build_env_path( { prepend => ":pre:pend", append => ":ap:pend" } ), "pre:pend:$ENV{PATH}:ap:pend", "append and prepend left side sep" );

is( Unix::Whereis::_build_env_path( { mypath => ":my:path", prepend => ":pre:pend" } ), "pre:pend:my:path", "mypath and prepend left side sep" );
is( Unix::Whereis::_build_env_path( { mypath => ":my:path", append  => ":ap:pend" } ),  "my:path:ap:pend",  "mypath and append left side sep" );
is( Unix::Whereis::_build_env_path( { mypath => ":my:path", prepend => ":pre:pend", append => ":ap:pend" } ), "pre:pend:my:path:ap:pend", "mypath, append, and prepend left side sep" );

# value w/ right side sep
is( Unix::Whereis::_build_env_path( { prepend => "pre:pend:" } ), "pre:pend:$ENV{PATH}", "prepend right side sep" );
is( Unix::Whereis::_build_env_path( { append  => "ap:pend:" } ),  "$ENV{PATH}:ap:pend",  "append right side sep" );
is( Unix::Whereis::_build_env_path( { prepend => "pre:pend:", append => "ap:pend:" } ), "pre:pend:$ENV{PATH}:ap:pend", "append and prepend right side sep" );

is( Unix::Whereis::_build_env_path( { mypath => "my:path:", prepend => "pre:pend:" } ), "pre:pend:my:path", "mypath and prepend right side sep" );
is( Unix::Whereis::_build_env_path( { mypath => "my:path:", append  => "ap:pend:" } ),  "my:path:ap:pend",  "mypath and append right side sep" );
is( Unix::Whereis::_build_env_path( { mypath => "my:path:", prepend => "pre:pend:", append => "ap:pend:" } ), "pre:pend:my:path:ap:pend", "mypath, append, and prepend right side sep" );

# value with both side sep
is( Unix::Whereis::_build_env_path( { prepend => ":pre:pend:" } ), "pre:pend:$ENV{PATH}", "prepend both side sep" );
is( Unix::Whereis::_build_env_path( { append  => ":ap:pend:" } ),  "$ENV{PATH}:ap:pend",  "append both side sep" );
is( Unix::Whereis::_build_env_path( { prepend => ":pre:pend:", append => ":ap:pend:" } ), "pre:pend:$ENV{PATH}:ap:pend", "append and prepend both side sep" );

is( Unix::Whereis::_build_env_path( { mypath => ":my:path:", prepend => ":pre:pend:" } ), "pre:pend:my:path", "mypath and prepend both side sep" );
is( Unix::Whereis::_build_env_path( { mypath => ":my:path:", append  => ":ap:pend:" } ),  "my:path:ap:pend",  "mypath and append both side sep" );
is( Unix::Whereis::_build_env_path( { mypath => ":my:path:", prepend => ":pre:pend:", append => ":ap:pend:" } ), "pre:pend:my:path:ap:pend", "mypath, append, and prepend both side sep" );

# value with both side sep mutli
is( Unix::Whereis::_build_env_path( { prepend => "::pre:pend::" } ), "pre:pend:$ENV{PATH}", "prepend both side sep mutli" );
is( Unix::Whereis::_build_env_path( { append  => "::ap:pend::" } ),  "$ENV{PATH}:ap:pend",  "append both side sep mutli" );
is( Unix::Whereis::_build_env_path( { prepend => "::pre:pend::", append => "::ap:pend::" } ), "pre:pend:$ENV{PATH}:ap:pend", "append and prepend both side sep mutli" );

is( Unix::Whereis::_build_env_path( { mypath => "::my:path::", prepend => "::pre:pend::" } ), "pre:pend:my:path", "mypath and prepend both side sep mutli" );
is( Unix::Whereis::_build_env_path( { mypath => "::my:path::", append  => "::ap:pend::" } ),  "my:path:ap:pend",  "mypath and append both side sep mutli" );
is( Unix::Whereis::_build_env_path( { mypath => "::my:path::", prepend => "::pre:pend::", append => "::ap:pend::" } ), "pre:pend:my:path:ap:pend", "mypath, append, and prepend both side sep mutli" );

############################
#### test filesys setup ####
############################

my $dir = File::Temp->newdir();

for my $sub (qw(bin local local/bin foo)) {
    mkdir "$dir/$sub" || die "Could not mkdir “$dir/$sub”: $!";
}

chmod 0755, "$dir/foo" || die "Could not chmod “$dir/foo”: $!";
write_file( "$dir/empty", { perms => 0755 }, '' ) || die "Could not create “$dir/empty”: $!";

write_file( "$dir/bin/file",       { perms => 0644 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";
write_file( "$dir/local/bin/file", { perms => 0644 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";
write_file( "$dir/foo/file",       { perms => 0755 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";

write_file( "$dir/bin/myprog",       { perms => 0755 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";
write_file( "$dir/local/bin/myprog", { perms => 0755 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";
write_file( "$dir/foo/myprog",       { perms => 0755 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";

{
    local $ENV{'PATH'} = "$dir:$dir/bin:$dir/local/bin:$dir/foo";

    ##########################
    #### whereis_everyone() ##
    ##########################

    is_deeply(
        [ Unix::Whereis::whereis_everyone('nadda') ],
        [],
        "whereis_everyone() returns nothing when it finds nothing"
    );

    is_deeply(
        [ Unix::Whereis::whereis_everyone( 'nadda', { fallback => 1 } ) ],
        [],
        "whereis_everyone() still returns nothing when it finds nothing and fallback is true (is a noop)"
    );

    is_deeply(
        [ Unix::Whereis::whereis_everyone('empty') ],
        [],
        "whereis_everyone() does not include empty executables"
    );

    is_deeply(
        [ Unix::Whereis::whereis_everyone('foo') ],
        [],
        "whereis_everyone() does not include executable directpries"
    );

    is_deeply(
        [ Unix::Whereis::whereis_everyone('file') ],
        ["$dir/foo/file"],
        "whereis_everyone() does not include non-executable files"
    );

    is_deeply(
        [ Unix::Whereis::whereis_everyone('myprog') ],
        [ "$dir/bin/myprog", "$dir/local/bin/myprog", "$dir/foo/myprog" ],
        "whereis_everyone() includes all executable files"
    );

    #### _build_env_path() vars prepend, append, mypath ##
    {
        no warnings 'redefine';
        my $_build_env_path;
        my $conf = { mypath => '…' };
        local *Unix::Whereis::_build_env_path = sub { $_build_env_path = $_[0] };
        Unix::Whereis::whereis_everyone( 'xyz', $conf );
        is_deeply( $_build_env_path, $conf, 'whereis_everyone() passes the option hash to _build_env_path()' );
    }

    #### cache ##

    ok( !exists $Unix::Whereis::cache->{'whereis_everyone'}, 'cache not set rpior to caceh being true' );

    is_deeply(
        [ Unix::Whereis::whereis_everyone( 'myprog', { 'cache' => 1 } ) ],
        [ "$dir/bin/myprog", "$dir/local/bin/myprog", "$dir/foo/myprog" ],
        "whereis_everyone() cache true returns correct values"
    );

    is_deeply(
        $Unix::Whereis::cache->{'whereis_everyone'}{'myprog'},
        [ "$dir/bin/myprog", "$dir/local/bin/myprog", "$dir/foo/myprog" ],
        "whereis_everyone() cache true sets correct values"
    );

    unlink "$dir/bin/myprog" || die "Could not unlink “$dir/bin/myprog”: $!";

    is_deeply(
        [ Unix::Whereis::whereis_everyone( 'myprog', { 'cache' => 1 } ) ],
        [ "$dir/bin/myprog", "$dir/local/bin/myprog", "$dir/foo/myprog" ],
        "whereis_everyone() cache true returns cached values, even though reality has changed"
    );

    is_deeply(
        [ Unix::Whereis::whereis_everyone('myprog') ],
        [ "$dir/local/bin/myprog", "$dir/foo/myprog" ],
        "whereis_everyone() cache not true returns reality, not the cache"
    );

    is_deeply(
        [ Unix::Whereis::whereis_everyone( 'myprog', { 'cache' => 'clear' } ) ],
        [ "$dir/local/bin/myprog", "$dir/foo/myprog" ],
        "whereis_everyone() cache clear returns correct values"
    );

    is_deeply(
        $Unix::Whereis::cache->{'whereis_everyone'}{'myprog'},
        [ "$dir/local/bin/myprog", "$dir/foo/myprog" ],
        "whereis_everyone() cache clear reset to correct values"
    );

    # reset for whereis() version
    write_file( "$dir/bin/myprog", { perms => 0755 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";

    #################
    #### whereis() ##
    #################

    is( whereis('nadda'), undef(), "whereis() returns nothing when it finds nothing" );
    is( whereis( 'nadda', { fallback => 1 } ), 'nadda', "whereis() returns the program name when it finds nothing and fallback is ture" );
    is( whereis('empty'),  undef(),           "whereis() does not include empty executables" );
    is( whereis('foo'),    undef(),           "whereis() does not include executable directpries" );
    is( whereis('file'),   "$dir/foo/file",   "whereis() does not include non-executable files" );
    is( whereis('myprog'), "$dir/bin/myprog", "whereis() returns first executable file" );

    #### _build_env_path() vars prepend, append, mypath ##
    {
        no warnings 'redefine';
        my $_build_env_path;
        my $conf = { mypath => '…' };
        local *Unix::Whereis::_build_env_path = sub { $_build_env_path = $_[0] };
        Unix::Whereis::whereis( 'xyz', $conf );
        is_deeply( $_build_env_path, $conf, 'whereis_everyone() passes the option hash to _build_env_path()' );
    }

    #### cache ##

    ok( !exists $Unix::Whereis::cache->{'whereis'}, 'cache not set rpior to caceh being true' );
    is( Unix::Whereis::whereis( 'myprog', { 'cache' => 1 } ), "$dir/bin/myprog", "whereis() cache true returns correct values" );
    is( $Unix::Whereis::cache->{'whereis'}{'myprog'}, "$dir/bin/myprog", "whereis() cache true sets correct values" );

    unlink "$dir/bin/myprog" || die "Could not unlink “$dir/bin/myprog”: $!";

    is( Unix::Whereis::whereis( 'myprog', { 'cache' => 1 } ), "$dir/bin/myprog", "whereis() cache true returns cached values, even though reality has changed" );
    is( Unix::Whereis::whereis('myprog'), "$dir/local/bin/myprog", "whereis() cache not true returns reality, not the cache" );
    is( Unix::Whereis::whereis( 'myprog', { 'cache' => 'clear' } ), "$dir/local/bin/myprog", "whereis() cache clear returns correct values" );
    is( $Unix::Whereis::cache->{'whereis'}{'myprog'}, "$dir/local/bin/myprog", "whereis() cache clear reset to correct values" );

    # reset in case tests are added later
    write_file( "$dir/bin/myprog", { perms => 0755 }, "#!/bin/sh\necho 42;\n" ) || die "Could not create “$dir/empty”: $!";
}

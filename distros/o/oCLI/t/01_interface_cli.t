#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use oCLI::Request;

my $tests = [
    {
        in   => [qw( /foo )],
        out  => { override => { foo => 1 }, args => [], setting => {} },
        desc => "Override: No argument results in 1 ",
        line => __LINE__,
    },
    {
        in   => [qw( /foo /bar=10 )],
        out  => { override => { foo => 1, bar => 10 }, args => [], setting => {} },
        desc => "Override: Numerical value assignment",
        line => __LINE__,
    },
    {
        in   => [qw( /foo /bar=10 /baz=10.5 )],
        out  => { override => { foo => 1, bar => 10, baz => 10.5}, args => [], setting => {} },
        desc => "Override: Floating point numerical value assignment",
        line => __LINE__,
    },
    
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar )],
        out  => { override => { foo => 1, bar => 10, baz => 10.5, bing => 'bar' }, args => [], setting => {} },
        desc => "Override: string assignment",
        line => __LINE__,
    },
    
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar )],
        out  => { override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, args => [], setting => {} },
        desc => "Override: Later assignments overwrite earlier",
        line => __LINE__,
    },
    
    {
        in   => [qw( /foo /bar=10 ), '/blee=foo bar'],
        out  => { override => { foo => 1, bar => 10, blee => 'foo bar' }, args => [], setting => {} },
        desc => "Override: token value can have spaces ",
        line => __LINE__,
    },

    {
        in   => [ qw( server --foo ) ],
        out  => { command => 'server', setting => { foo => 1 }, args => [] },
        desc => 'Setting with no value is a true bool',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server --foo --bar blee) ],
        out  => { command => 'server', setting => { foo => 1, bar => 'blee' }, args => [ ] },
        desc => 'Settings with an argument',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server --foo --bar blee --bar baz) ],
        out  => { command => 'server', setting => { foo => 1, bar => [ 'blee', 'baz' ] }, args => [ ] },
        desc => 'Settings with multiple arguments become an array ref',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server --foo --bar blee --bar baz --no-bat) ],
        out  => { command => 'server', setting => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0 }, args => [ ] },
        desc => 'Setting prefixed with --no- is a false bool',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server:create bar --foo ) ],
        out  => { command => 'server:create', setting => { foo => 1 }, args => [ 'bar' ] },
        desc => 'Positional Arguments',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server:create bar blee --foo ) ],
        out  => { command => 'server:create', setting => { foo => 1 }, args => [ 'bar', 'blee' ] },
        desc => 'Positional Arguments followed by settings',
        line => __LINE__,
    },

    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create --minus - --neg -5 --foo --bar blee --bar baz --no-bat )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command => 'server:create',
            setting => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0, minus => '-', neg => -5 },
            args    => [ ],
        },
        desc => "Various forms of - and -n as setting values.",
        line => __LINE__,
    },

    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create bar @t/etc/data --foo --bar blee --bar baz --no-bat )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command  => 'server:create',
            args     => [ 'bar', "I am a data file.\nI have two lines.\n" ],
            setting  => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0 },
        },
        desc => 'Data expansion in arguments with @filename',
        line => __LINE__,
    },
    
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create bar blee --foo --bar blee --bar baz --no-bat --data @t/etc/data )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command  => 'server:create',
            args     => [ 'bar', 'blee' ],
            setting  => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0, data => "I am a data file.\nI have two lines.\n" },
        },
        desc => 'Data expansion in settings with @filename',
        line => __LINE__,
    },

    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create bar blee --foo --bar blee --bar baz --no-bat --data @t/etc/data )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command  => 'server:create',
            args     => [ 'bar', 'blee' ],
            setting  => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0, data => "I am a data file.\nI have two lines.\n" },
            stdin    => "I am from STDIN.\nI have two lines.\n"
        },
        desc => "Process standard input",
        line => __LINE__,
        stdin   => "I am from STDIN.\nI have two lines.\n"
    },

];


my $stdin = *STDIN;
foreach my $test ( @{$tests} ) {

    # Stuff STDIN if we have content.
    if ( $test->{stdin} ) {
        open my $sf, "<", \"$test->{stdin}" or die "Failed to inject STDIN content: $!";
        *STDIN = $sf;
    }

    my $obj = oCLI::Request->new_from_command_line( @{$test->{in}} );

    # Handle bug in STDIN between "" and undef under test_harness, vs prove
    is ( $obj->stdin || "", delete $test->{out}{stdin} || "", sprintf( "Line %d: %s", $test->{line}, $test->{desc}));

    # Normal CDS testing
    is_deeply( $obj->overrides, $test->{out}->{override}, sprintf( "[Overrides] Line %d: %s", $test->{line}, $test->{desc}) );
    is_deeply( $obj->command,   $test->{out}->{command}, sprintf( "[Command] Line %d: %s", $test->{line}, $test->{desc}) );
    is_deeply( $obj->args,      $test->{out}->{args}, sprintf( "[Args] Line %d: %s", $test->{line}, $test->{desc}) );
    is_deeply( $obj->settings,  $test->{out}->{setting}, sprintf( "[Settings] Line %d: %s", $test->{line}, $test->{desc}) );

    # Reset STDIN if we stuffed it.
    *STDIN = $stdin if $test->{stdin};
}

done_testing();

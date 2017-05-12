BEGIN { chdir 't' if -d 't' };

use lib '../lib';
use strict;

use Test::More      'no_plan';
use Data::Dumper;
use FileHandle;

my $Class   = 'Variable::Watcher';
my $Obj     = bless {}, __PACKAGE__;

### stupid warnings;
local $Variable::Watcher::VERBOSE = 0;
local $Variable::Watcher::VERBOSE = 0;

### XXX use_ok doesn't set up inheritance properly =/
#use_ok( $Class);
use Variable::Watcher;

isa_ok( $Obj , $Class);

### simple scalar tests
{   my $foo : Watch(foo) = $0;

    ### manipulate it some
    ok( $foo,                   "Scalar foo is defined" );
    is( $foo, $0,               "   Foo set to '$$'" );

    ### check if we tied it indeed
    my $obj = tied $foo;
    ok( $obj,                   "   Foo is tied" );
    isa_ok( $obj,               $Class );

    ### retrieve what we've logged so far
    my $stack = $Class->stack_as_string;
    for my $item( qw[foo STORE FETCH line], $0 ) {
        my $re = quotemeta $item;
        like( $stack, qr/$re/,  "   Stack mentions '$item'" );
    }

    ### dump what we have so far
    $Class->flush;
}

### simple array tests
{   my @foo : Watch(foo);

    ### manipulate it some
    @foo = @INC;
    ok( scalar(@foo),           "Array foo has elements" );
    is_deeply( \@foo, \@INC,    '   Foo set to @INC' );

    @foo = (1);
    push @foo, 2;
    is_deeply( \@foo, [1,2],    "   Foo redefined" );

    ### check if we tied it indeed
    my $obj = tied @foo;
    ok( $obj,                   "   Foo is tied" );
    isa_ok( $obj,               $Class );

    ### retrieve what we've logged so far
    my $stack = $Class->stack_as_string;
    for my $item( qw[foo STORE FETCH FETCHSIZE EXTEND CLEAR line], $0 ) {
        my $re = quotemeta $item;
        like( $stack, qr/$re/,  "   Stack mentions '$item'" );
    }

    ### dump what we have so far
    $Class->flush;
}


### simple hash tests
{   my %foo : Watch(foo);

    ### manipulate it some
    %foo = ( a => 1 );
    ok( scalar(keys %foo),      "Hash foo has elements" );

    $foo{b} = 2;
    is( scalar(keys %foo), 2,   "   Foo extended" );
    is_deeply( \%foo, {a=>1,b=>2},
                                "   Foo as expected" );

    %foo = %INC;
    is_deeply( \%foo, \%INC,    '   Foo set to %INC' );

    ### check if we tied it indeed
    my $obj = tied %foo;
    ok( $obj,                   "   Foo is tied" );
    isa_ok( $obj,               $Class );

    ### retrieve what we've logged so far
    my $stack = $Class->stack_as_string;
    for my $item( qw[foo STORE FETCH CLEAR line
                        NEXTKEY FIRSTKEY EXISTS], $0
    ) {
        my $re = quotemeta $item;
        like( $stack, qr/$re/,  "   Stack mentions '$item'" );
    }

    ### dump what we have so far
    $Class->flush;
}



### test printing to alternate file handles
{   my $file = $$.'.out';

    ### open a filehandle, print some stuff to it
    {   my $fh = FileHandle->new( '>'.$file )
            or die "Could not open '$file': $!";

        ### stupid warnings
        local $Variable::Watcher::REPORT_FH = $fh;
        local $Variable::Watcher::REPORT_FH = $fh;
        local $Variable::Watcher::VERBOSE = 1;

        my $foo : Watch(foo) = 1;
        my $bar = $foo;

        close $fh;
    }

    ### reopen the file, check the contents
    {   my $fh = FileHandle->new( $file )
            or die "Could not open '$file': $!";

        my $stack = do { local $/; <$fh> };

        ok( $stack,             "Retrieved stack from file" );

        for my $item( qw[foo STORE FETCH line], $0 ) {
            my $re = quotemeta $item;
            like( $stack, qr/$re/,
                                "   Stack mentions '$item'" );
        }

        close $fh;
    }

    ### dump what we have so far
    $Class->flush;

    unlink $file;
}

### test retrieving only parts of a stack
### + flushing it
{   my $foo : Watch(foo) = 1;
    my $bar : Watch(bar) = 1;
    my $zot = $foo; $zot = $bar;

    ### full stack first
    {   my $stack = $Class->stack_as_string;
        ok( $stack,             "Full stack retrieved" );

        for my $item( qw[foo bar STORE FETCH line], $0 ) {
            my $re = quotemeta $item;
            like( $stack, qr/$re/,
                                "   Stack mentions '$item'" );
        }
    }

    ### now just ask for foo things
    {   my $stack = $Class->stack_as_string( name => 'foo' );
        ok( $stack,             "Stack for just 'foo' retrieved" );

        for my $item( qw[foo STORE FETCH line], $0 ) {
            my $re = quotemeta $item;
            like( $stack, qr/$re/,
                                "   Stack mentions '$item'" );
        }

        for my $item( qw[bar] ) {
            my $re = quotemeta $item;
            unlike( $stack, qr/$re/,
                                "   Stack doesn't mention '$item'" );
        }
    }

    ### now just ask for STORE things
    {   my $stack = $Class->stack_as_string( action => 'STORE' );
        ok( $stack,             "Stack for just 'STORE' retrieved" );

        for my $item( qw[bar foo STORE line], $0 ) {
            my $re = quotemeta $item;
            like( $stack, qr/$re/,
                                "   Stack mentions '$item'" );
        }

        for my $item( qw[FETCH] ) {
            my $re = quotemeta $item;
            unlike( $stack, qr/$re/,
                                "   Stack doesn't mention '$item'" );
        }
    }

    ### now just ask for foo & STORE things
    {   my $stack = $Class->stack_as_string( action => 'STORE', name => 'foo' );
        ok( $stack,             "Stack for just 'foo' & 'STORE' retrieved" );

        for my $item( qw[foo STORE line], $0 ) {
            my $re = quotemeta $item;
            like( $stack, qr/$re/,
                                "   Stack mentions '$item'" );
        }

        for my $item( qw[bar FETCH] ) {
            my $re = quotemeta $item;
            unlike( $stack, qr/$re/,
                                "   Stack doesn't mention '$item'" );
        }
    }

    ### now flush the thing
    {   my @items = $Class->flush;
        ok( scalar(@items),     "Stack flushed" );
        ok( !$Class->stack_as_string,
                                "   Stack is now empty" );
    }
}

### test Watching things we don't support
### XXX leave this at the bottom
{   my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= "@_" };

    ### declare the sub in a string eval, to make sure it
    ### happens in this block rather than at compile time
    eval "sub bar : Watch(foo) { 1 }";

    ok(__PACKAGE__->can('bar'), "Sub 'bar' created" );
    like( $warnings, qr/Cannot watch variable of type: 'CODE'/,
                                "   No Watcher attached" );
    like( $warnings, qr/eval/,  "   Warnings mentions the eval" );

}




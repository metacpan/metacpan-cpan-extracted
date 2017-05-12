#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;

my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, join '', @_ } }

BEGIN {
  package Foo;
  $Foo::moo = 42;
}


require_ok( 'your' );

$Foo::you = 1;
use your qw($Foo::moo $Foo::bar);

is( scalar @warnings, 1,                        'only the expected warnings' );
ok( (grep /^Name "Foo::you" used only once/, @warnings), 'foreign name once' );
is( $Foo::moo, 42,                            'values still there' );
$Foo::bar = "yarrow";

{
    package Foo;
    ::is( $bar, 'yarrow', 'other package can still get at the variable' );
}

eval 'use your qw($moo)';
like( $@, "/^Can only declare other package's variables/",
          "can't use it to declare our own variables" );

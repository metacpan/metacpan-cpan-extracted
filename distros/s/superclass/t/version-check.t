use strict;
use Test::More tests => 14;
use lib 't/lib';

eval "package Foo; use superclass Versioned => 0.4; 1";
is( $@, '', "pass decimal version check" );

eval "package Foo; use superclass Versioned => 0.6; 1";
like( $@, qr/this is only/, "fail decimal version check" );

eval "package Foo; use superclass DotVersioned => 1; 1";
is( $@, '', "pass integer version check" );

eval "package Foo; use superclass DotVersioned => 2; 1";
like( $@, qr/this is only/, "fail integer version check" );

eval "package Foo; use superclass DotVersioned => v1.0.0; 1";
is( $@, '', "pass v-string version check" );

eval "package Foo; use superclass DotVersioned => v1.1.0; 1";
like( $@, qr/this is only/, "fail v-string version check" );

eval "package Foo; use superclass DotVersioned => 'v1.0.0'; 1";
is( $@, '', "pass string v-string version check" );

eval "package Foo; use superclass DotVersioned =>'v1.1.0'; 1";
like( $@, qr/this is only/, "fail string v-string version check" );

eval "package Foo; use superclass 'Dummy', Versioned => 0.4, 'Dummy::Outside'; 1";
is( $@, '', "versioned superclass between unversioned" );

eval "package Foo; use superclass UnVersioned => 0; 1";
is( $@, '', "requiring 0 doesn't fail on undef \$VERSION" );

eval "package Foo; use superclass UnVersioned => 1; 1";
like( $@, qr/failed/, "requiring 1 does fail on undef \$VERSION" );

eval "package Foo; use superclass DotVersioned => 'v1.0_0'; 1";
is( $@, '', "pass string alpha v-string version check" );

eval "package Foo; use superclass DotVersioned =>'v1.0_1'; 1";
like( $@, qr/this is only/, "fail string alpha v-string version check" );

eval "package Foo; use superclass DotVersioned => v65.0.65; 1";
like( $@, qr/this is only/, "fail v65.0.65 version check" );


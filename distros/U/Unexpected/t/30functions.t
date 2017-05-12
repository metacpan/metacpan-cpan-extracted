use t::boilerplate;

use English      qw( -no_match_vars );
use Scalar::Util qw( blessed );
use Test::More;

sub EXCEPTION_CLASS { 'MyException' }

BEGIN {
   {  package MyException;

      use Moo;
      use Unexpected::Functions qw( has_exception );

      extends 'Unexpected';
      with    'Unexpected::TraitFor::ErrorLeader';
      with    'Unexpected::TraitFor::ExceptionClasses';

      my $class = __PACKAGE__;

      has_exception 'A';
      has_exception 'B', parents => [ 'A' ];
      has_exception 'C', parents => 'A';
      has_exception 'D', parents => [ qw( A B ) ];
      has_exception 'E', parents => 'A';

      $INC{ 'MyException.pm' } = __FILE__;
   }
}

use Unexpected::Functions;

use Unexpected::Functions { into => 'main' };

use Unexpected::Functions qw( :all );

ok( (main->can( 'parse_arg_list' )), 'Imports parse_arg_list' );
ok( (main->can( 'inflate_message' )), 'Imports inflate_message' );

is parse_arg_list( bless { error => 'fooled_you' }, 'HASH' )->{error},
   'fooled_you', 'Ignores blessed if not one of us';

is( (exception 'Bite Me')->error, 'Bite Me', 'Exception function' );
eval { throw 'Bite Me' }; is $EVAL_ERROR->error, 'Bite Me', 'Throw function';
eval { eval { throw 'Bite Me' }; throw_on_error }; my $e = $EVAL_ERROR;
is $e->error, 'Bite Me', 'Throw_on_error function';
is blessed $e, 'MyException', 'Function throw correct class';

# Lifted from Class::Load
ok(  is_class_loaded( 'MyException' ), 'MyException is loaded' );
ok( !is_class_loaded( 'MyException::NOEXIST' ), 'Nonexistent class NOT loaded');

do {
   package MyException::ISA;
   our @ISA = 'MyException';
};

ok(  is_class_loaded( 'MyException::ISA' ), 'Defines \@ISA loaded' );

do {
   package MyException::ScalarISA;
   our $ISA = 'MyException';
};

ok( !is_class_loaded( 'MyException::ScalarISA' ), 'Defines $ISA not loaded' );

do {
   package MyException::UndefVers;
   our $VERSION;
};

ok( !is_class_loaded( 'MyException::UndefVers' ), 'Undef version not loaded' );

do {
   package MyException::UndefScalar;
   my $version; our $VERSION = \$version;
};

ok( !is_class_loaded( 'MyException::UndefScalar' ), 'Undef scalar not loaded' );

do {
   package MyException::DefScalar;
   my $version = 1; our $VERSION = \$version;
};

ok(  is_class_loaded( 'MyException::DefScalar' ), 'Defined scalar ref loaded' );

do {
   package MyException::VERSION;
   our $VERSION = '1.0';
};

ok(  is_class_loaded( 'MyException::VERSION' ), 'Defines $VERSION is loaded' );

do {
   package MyException::VersionObj;
   our $VERSION = version->new( 1 );
};

ok(  is_class_loaded( 'MyException::VersionObj' ), 'Version obj returns true' );

do {
   package MyException::WithMethod;
   sub foo { }
};

ok(  is_class_loaded( 'MyException::WithMethod' ), 'Defines a method loaded' );

do {
   package MyException::WithScalar;
   our $FOO = 1;
};

ok( !is_class_loaded( 'MyException::WithScalar' ), 'Defines scalar not loaded');

do {
   package MyException::Foo::Bar;
   sub bar {}
};

ok( !is_class_loaded( 'MyException::Foo' ), 'If Foo::Bar is loaded Foo is not');

do {
   package MyException::Quuxquux;
   sub quux {}
};

ok( !is_class_loaded( 'MyException::Quux' ),
    'Quuxquux does not imply the existence of Quux' );

do {
   package MyException::WithConstant;
   use constant PI => 3;
};

ok(  is_class_loaded( 'MyException::WithConstant' ),
     'Defining a constant means the class is loaded' );

do {
   package MyException::WithRefConstant;
   use constant PI => \3;
};

ok(  is_class_loaded( 'MyException::WithRefConstant' ),
     'Defining a constant as a reference means the class is loaded' );

do {
   package MyException::WithStub;
   sub foo;
};

ok(  is_class_loaded( 'MyException::WithStub' ),
     'Defining a stub means the class is loaded' );

do {
   package MyException::WithPrototypedStub;
   sub foo (&);
};

ok(  is_class_loaded( 'MyException::WithPrototypedStub' ),
     'Defining a stub with a prototype means the class is loaded' );

is inflate_placeholders
   ( [ 'undef', 'null', 1 ], 'test [_3] [_2] [_1]', 'x', q() ),
   'test undef null x', 'Inflate_placeholders';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:

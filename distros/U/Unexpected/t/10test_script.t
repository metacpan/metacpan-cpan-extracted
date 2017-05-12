use t::boilerplate;

use Test::More;
use Test::Requires { Moo => 1.002 };
use English      qw( -no_match_vars );
use Scalar::Util qw( blessed refaddr );
use Try::Tiny;

BEGIN {
   {  package MyException;

      use Moo;

      extends 'Unexpected';
      with    'Unexpected::TraitFor::ErrorLeader';
      with    'Unexpected::TraitFor::ExceptionClasses';

      my $class = __PACKAGE__;

      $class->add_exception( 'A' );
      $class->add_exception( 'B', [ 'A' ] );
      $class->add_exception( 'C', { error => 'Class C', parents => 'A' } );
      $class->add_exception( 'D', [ qw( A B ) ] );
      $class->add_exception( 'E', 'A' );

      $INC{ 'MyException.pm' } = __FILE__;
   }
}

sub EXCEPTION_CLASS { 'MyException' }

use Unexpected::Functions 'Unspecified';

sub _eval_error () { my $e = $EVAL_ERROR; $EVAL_ERROR = undef; return $e }

my $class = 'MyException'; my $e = _eval_error;

is $class->ignore->[ 0 ], 'Try::Tiny', 'No initial ignore class';

ok $class->ignore_class( 'IgnoreMe' ), 'Set ignore class';

is $class->ignore->[ 1 ], 'IgnoreMe', 'Get ignore class';

eval { $class->throw_on_error };

ok ! _eval_error, 'No throw without error';

eval { eval { die 'In a pit of fire' }; $class->throw_on_error };

like _eval_error, qr{ \QIn a pit of fire\E }mx , 'Throws on error';

eval { $class->throw( 'PracticeKill' ) }; $e = _eval_error;

can_ok $e, 'message';

like $e->message, qr{ PracticeKill }mx, 'Message contains known string';

is blessed $e, $class, 'Good class'; my $min_level = $e->level;

like $e, qr{ PracticeKill \s* \z   }mx, 'Throws error message';

is $e->class, 'Unexpected', 'Default error classification';

my $addr = refaddr $e;

is refaddr $e->caught(), $addr, 'Catches self';

is refaddr $class->caught( $e ), $addr, 'Catches own objects';

my $can_trace = $e =~ m{ \A main }mx ? 1 : 0;

$can_trace or $ENV{UNEXPECTED_SHOW_RAW_TRACE} = 1;

SKIP: {
   $can_trace or skip 'Stacktrace broken', 1;

   like $e, qr{ \A main \[ \d+ / $min_level \] }mx, 'Package and default level';
};

eval { $e->throw() }; $e = _eval_error;

is refaddr $e, $addr, 'Throws self';

eval { $class->throw( $e ) }; $e = _eval_error;

is refaddr $e, $addr, 'Throws own objects';

eval { $e->throw( 'Not allowed' ) }; $e = _eval_error;

like $e, qr{ object \s+ with \s+ arguments }mx, 'No throwing objects with args';

eval { Unexpected->clone }; $e = _eval_error;

like $e, qr{ \QClone is an object method\E }mx, 'Clone is an object method';

like $e->clone( { error => 'Mutated' } ), qr{ Mutated }mx, 'Clone mutates';

eval { $class->throw() }; $e = _eval_error;

like $e, qr{ Unknown \s+ error }mx, 'Default error string';

eval { $class->throw( error => sub { 'Test firing' } ) }; $e = _eval_error;

like $e, qr{ Test \s+ firing }mx, 'Derefernces coderef as error string';

eval { $class->throw( 'error', args => {} ) }; $e = _eval_error;

like $e, qr{ not \s+ pass \s+ type \s+ constraint }mx, 'Attribute type error';

eval { $class->throw( 'error', [] ) }; $e = _eval_error;

is $e->error, 'error', 'Constucts from string and arrayref';

eval { $class->throw( 'error', { args => [] } ) }; $e = _eval_error;

is $e->error, 'error', 'Constructs from string and hashref';

eval { $class->throw( class => 'Unspecified', args => [ 'Parameter' ] ) };

$e = _eval_error;

like $e, qr{ \Q'Parameter' not specified\E }mx, 'Error string from class';

eval { $class->throw( Unspecified, args => [ 'Parameter' ] ) };

$e = _eval_error;

like $e, qr{ \Q'Parameter' not specified\E }mx, 'Error string from coderef';

eval { $class->throw( Unspecified, [ 'Parameter' ] ) }; $e = _eval_error;

like $e, qr{ \Q'Parameter' not specified\E }mx,
   'Error string from coderef - args shortcut';

eval { $class->throw( Unspecified ) }; $e = _eval_error;

like $e, qr{ \Qnot specified\E }mx, 'Error string from coderef no args';

$e = $class->caught( $e, { leader => 'different' } );

is $e->leader, 'different', 'Constructs from self plus mutation';

my ($line1, $line2, $line3);

SKIP: {
   $can_trace or skip 'Stacktrace broken', 1;

   sub test_throw { $class->throw( 'PracticeKill' ) }; $line1 = __LINE__;

   sub test_throw1 { test_throw() }; $line2 = __LINE__;

   eval { test_throw1() }; $line3 = __LINE__; $e = _eval_error;

   my @lines = $e->stacktrace;

   like $e, qr{ \A main \[ $line2 / \d+ \] }mx, 'Package and line number';

   is $lines[ 0 ], "main::test_throw line ${line1}", 'Stactrace line 1';

   is $lines[ 1 ], "main::test_throw1 line ${line2}", 'Stactrace line 2';

   is $lines[ 2 ], "main line ${line3}", 'Stactrace line 3';

   @lines = $e->stacktrace( 1 );

   is $lines[ 0 ], "main::test_throw1 line ${line2}",
      'Stactrace can skip frames';

   my $lines = $e->stacktrace;

   like $lines, qr{ main::test_throw }mx, 'Stacktrace can return a scalar';
};

my $level = $min_level + 1;

sub test_throw2 { $class->throw( 'PracticeKill', level => $level ) };

sub test_throw3 { test_throw2() }

sub test_throw4 { test_throw3() }; $line1 = __LINE__;

eval { test_throw4() }; $e = _eval_error;

SKIP: {
   $can_trace or skip 'Stacktrace broken', 1;

   like $e, qr{ \A main \[ $line1 / $level \] }mx, 'Specific leader level';
};

$line1 = __LINE__; eval {
   $class->throw( args  => [ 'flap' ],
                  class => 'nonDefault',
                  error => 'cat: [_1] cannot open: [_2]', ) }; $e = _eval_error;

eval { $e->class}; $e = _eval_error;

like $e, qr{ 'nonDefault' \s+ does \s+ not \s+ exist }mx,
   'Non existant exception class';

eval { $class->add_exception() }; $e = _eval_error;

like $e, qr{ \QParameter 'exception class' not specified\E }mx,
   'Undefined exception class';

eval { $class->add_exception( 'F', 'Unknown' ) }; $e = _eval_error;

like $e, qr{ Unknown \s+ does \s+ not \s+ exist }mx,
   'Parent class does not exist';

eval { $class->add_exception( 'A', 'Unexpected' ) }; $e = _eval_error;

like $e, qr{ A \s+ already \s+ exists }mx,
   'Exception class already exists';

$line1 = __LINE__; eval {
   $class->throw( args  => [ 'flap' ],
                  class => 'A',
                  error => 'cat: [_1] cannot open: [_2]', ) }; $e = _eval_error;

is $e->class, 'A', 'Specific error classification';

SKIP: {
   $can_trace or skip 'Stacktrace broken', 1;

   like $e,
      qr{ main\[ $line1 / \d+ \]:\scat:\s'flap'\scannot\sopen: }mx,
      'Placeholer substitution - with quotes';
};

use Unexpected::Functions
   { exception_class => 'MyException' }, qw( A catch_class inflate_message );

is A()->(), 'A', 'Imports exception';

my $qstate = Unexpected::Functions->quote_bind_values();

is $qstate, 1, 'Default quoting state';

Unexpected::Functions->quote_bind_values( 0 );

SKIP: {
   $can_trace or skip 'Stacktrace broken', 1;

   like $e, qr{ main\[ $line1 / \d+ \]:\scat:\sflap\scannot\sopen: }mx,
      'Placeholer substitution - without quotes';
};

ok !$class->is_exception(), 'Exception predicate - undef';
ok $class->is_exception( 'E' ), 'Exception predicate - true';
ok !$class->is_exception( 'F' ), 'Exception predicate - false';

$line1 = __LINE__; eval {
   $class->throw( args  => [ 'flap' ],
                  class => 'D',
                  error => 'cat: [_1] cannot open: [_2]', ) }; $e = _eval_error;

is $e->class, 'D', 'Current exception classification';

is $e->previous_exception->class, 'A', 'Previous exception';

is $e->instance_of(), 0, 'Null class is false';

is $e->instance_of( 'A' ), 1, 'Inherits exception class';

is $e->instance_of( A ), 1, 'Inherits exception class - coderef';

is $e->instance_of( 'E' ), 0, 'Does not match exception class';

eval { $e->instance_of( 'nonExistant' ) }; $e = _eval_error;

like $e, qr{ nonExistant \s+ does \s+ not \s+ exist }mx,
   'Non existant exception class throws';

eval { $class->throw( error => 'PracticeKill', level => 99 )}; $e = _eval_error;

SKIP: {
   $can_trace or skip 'Stacktrace broken', 1;

   like $e, qr{ /1 }mx, 'Level greater than number of frames';
};

$class->ignore_class( 'main' );

eval { $class->throw( 'PracticeKill' ) }; $e = _eval_error;

is $e->leader, q(), 'No leader';

is "${e}", "PracticeKill\n", 'Stringifies';

my $v = try { $class->throw( class => 'C' ) } catch_class [ C => undef ];

is $v, undef, 'No catch class';

$v = try { $class->throw( class => 'C' ) } catch_class [ C => sub { 42 } ];

is $v, 42, 'Catch class';

$v = try { $class->throw( class => 'D', error => 'Must have an error' ) }
           catch_class [ B => sub { 42 } ];

is $v, 42, 'Catch class - instance_of';

eval { try { $class->throw( class => 'C' ) } catch_class [ D => sub { 42 } ]; };

$e = _eval_error;

is "${e}", "Class C\n", 'Catch class - default throws';

eval { try { die 'string' } catch_class [ C => sub { 42 } ]; };

$e = _eval_error;

like "${e}", qr{ \A string }mx, 'Catch class - ignores strings';

$v = try { die 'string' } catch_class [ ':str' => sub { 42 } ];

is $v, 42, 'Catch class - string exceptions';

$v = try { die [] } catch_class [ 'ARRAY' => sub { 42 } ];

is $v, 42, 'Catch class - references';

$v = try         { $class->throw( class => 'C' ) }
     catch_class [ Unexpected => sub { 42 } ];

is $v, 42, 'Catch class - real class names';

eval { try { die } catch_class []; };

$e = _eval_error;

like "${e}", qr{ \A Died }mx, 'Catch class - undefined keys';

$v = try { $class->throw( class => 'Unspecified' ) }
     catch_class [ undef, sub { 1 }, 'Unspecified' => sub { 1 } ];

is $v, 1, 'Catch class - undefined catch_class keys';

eval { catch_class []; };

$e = _eval_error;

like "${e}", qr{ \Qbare catch_class\E }mx, 'Catch class - bare catch_class';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:

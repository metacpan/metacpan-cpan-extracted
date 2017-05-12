#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/07-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 8 + 5*18;
use strict;
use warnings;

use Test::Trap::Builder;
my $Builder; BEGIN { $Builder = Test::Trap::Builder->new }

local @ARGV; # in case some harness wants to mess with it ...
my @argv = ('A');
BEGIN {
  package TT::A;
  use base 'Test::Trap';
  $Builder->layer( argv => $_ ) for sub {
    my $self = shift;
    local *ARGV = \@argv;
    $self->{inargv} = [@argv];
    $self->Next;
    $self->{outargv} = [@argv];
  };
  $Builder->accessor( is_array => 1, simple => [qw/inargv outargv/] );
  $Builder->accessor( flexible =>
		      { argv => sub {
			  $_[1] && $_[1] !~ /in/i ? $_[0]{outargv} : $_[0]{inargv};
			},
		      },
		    );
  $Builder->test( can => 'element, predicate, name', $_ ) for sub {
    my ($got, $methods) = @_;
    @_ = ($got, @$methods);
    goto &Test::More::can_ok;
  };
  # Hack! Make perl think we have successfully required this package,
  # so that we can "use" it, even though it can't be found:
  $INC{'TT/A.pm'} = 'Hack!';
}

BEGIN {
  package TT::B;
  use base 'Test::Trap';
  $Builder->accessor( flexible =>
		      { leavewith => sub {
			  my $self = shift;
			  my $leaveby = $self->leaveby;
			  $self->$leaveby;
			},
		      },
		    );
  # Hack! Make perl think we have successfully required this package,
  # so that we can "use" it, even though it can't be found:
  $INC{'TT/B.pm'} = 'Hack!';
}

BEGIN {
  package TT::AB;
  use base qw( TT::A TT::B );
  $Builder->test( fail => 'name', \&Test::More::fail );
  # Hack! Make perl think we have successfully required this package,
  # so that we can "use" it, even though it can't be found:
  $INC{'TT/AB.pm'} = 'Hack!';
}

BEGIN {
  package TT::A2;
  use base qw( TT::A );
  $Builder->test( anotherfail => 'name', \&Test::More::fail );
  $Builder->accessor( flexible =>
		      { anotherouterr => sub {
			  my $self = shift;
			  $self->stdout . $self->stderr;
			},
		      },
		    );
  # Hack! Make perl think we have successfully required this package,
  # so that we can "use" it, even though it can't be found:
  $INC{'TT/A2.pm'} = 'Hack!';
}

BEGIN {
  # Insert s'mores into Test::Trap itself ... not clean, but a nice
  # quick thing to be able to do, in need:
  package Test::Trap;
  $Builder->test( pass => 'name', \&Test::More::pass );
  $Builder->accessor( flexible =>
		      { outerr => sub {
			  my $self = shift;
			  $self->stdout . $self->stderr;
			},
		      },
		    );
}

BEGIN {
  use_ok( 'Test::Trap' ); # import a standard trap/$trap
  use_ok( 'Test::Trap', '$D', 'D' );
  use_ok( 'TT::A',  '$A',  'A',  ':argv' );
  use_ok( 'TT::B',  '$B',  'B' );
  use_ok( 'TT::AB', '$AB', 'AB', ':argv' );
  use_ok( 'TT::A2', '$A2', 'A2', ':argv' );
}

BEGIN {
  trap {
    package TT::badclass;
    use base 'Test::Trap';
    $Builder->multi_layer( trouble => qw( warn no_such_layer ) );
  };
  like( $trap->die,
	qr/^\QUnknown trap layer "no_such_layer" at ${\__FILE__} line/,
	'Bad definition: unknown layer',
      );
}

BEGIN {
  trap {
    package TT::badclass3;
    use base 'Test::Trap';
    $Builder->test( pass => 'named', \&Test::More::pass );
  };
  like( $trap->die,
	qr/^\QUnrecognized identifier named in argspec at ${\__FILE__} line/,
	'Bad definition: test argspec typo ("named" for "name")',
      );
}

basic( \&D, \$D, 'Unmodified Test::Trap',
       qw( isno_A isno_B isno_AB ),
     );

basic( \&A, \$A, 'TT::A',
       qw( isan_A isno_B isno_AB ),
     );

basic( \&B, \$B, 'TT::B',
       qw( isno_A isa_B isno_AB ),
     );

basic( \&AB, \$AB, 'TT::AB',
       qw( isan_A isa_B isan_AB ),
     );

basic( \&A2, \$A2, 'TT::A2',
       qw( isan_A isno_B isno_AB ),
     );

exit 0;

# compile this after the CORE::GLOBAL::exit has been set:

my $argv_expected;
my $ARGV_expected;

sub isno_A {
  my ($func, $handle, $name) = @_;
  ok( !exists $$handle->{inargv}, "$name: no inargv internally" );
  push @$ARGV_expected, $name;
  ok( !exists $$handle->{outargv}, "$name: no outargv internally" );
  is_deeply( \@ARGV, $ARGV_expected, "$name: \@ARGV modified" );
  is_deeply( \@argv, $argv_expected, "$name: \@argv unmofied" );
  ok( !$$handle->can('return_can'), "$name: no return_can method" );
  ok( !$$handle->can('outargv'), "$name: no outargv method" );
  ok( !$$handle->can('outargv_can'), "$name: no outargv_can method" );
  ok( !$$handle->can('outargv_pass'), "$name: no outargv_pass method" );
}

sub isan_A {
  my ($func, $handle, $name) = @_;
  is_deeply( $$handle->{inargv}, $argv_expected, "$name: inargv present internally" );
  push @$argv_expected, $name;
  is_deeply( $$handle->{outargv}, $argv_expected, "$name: outargv present internally" );
  is_deeply( \@ARGV, $ARGV_expected, "$name: \@ARGV unmodified" );
  is_deeply( \@argv, $argv_expected, "$name: \@argv modified" );
  ok( $$handle->can('return_can'), "$name: return_can method present" );
  () = trap { $$handle->outargv };
  $trap->return_is_deeply( [$argv_expected], "$name: outargv method present and functional" );
  ok( $$handle->can('outargv_can'), "$name: outargv_can method present" );
  ok( $$handle->can('outargv_pass'), "$name: outargv_pass method present" );
}

sub isa_B {
  my ($func, $handle, $name) = @_;
  () = trap { $$handle->leavewith };
  $trap->return_is_deeply( [1], "$name: leavewith method present and functional" );
}

sub isno_B {
  my ($func, $handle, $name) = @_;
  ok( !$$handle->can('leavewith'), "$name: no leavewith method" );
}

sub isan_AB {
  my ($func, $handle, $name) = @_;
  ok( $$handle->can('stderr_fail'),    "$name: stderr_fail method present" );
  ok( $$handle->can('argv_fail'),      "$name: argv_fail method present" );
  ok( $$handle->can('leavewith_fail'), "$name: leavewith_fail method present" );
TODO: {
    local $TODO = 'Multiple inheritance still incomplete';
    ok( $$handle->can('leavewith_can'),  "$name: leavewith_fail method present" );
  }
}

sub isno_AB {
  my ($func, $handle, $name) = @_;
  ok( !$$handle->can('stderr_fail'),    "$name: no stderr_fail method" );
  ok( !$$handle->can('argv_fail'),      "$name: no argv_fail method" );
  ok( !$$handle->can('leavewith_fail'), "$name: no leavewith_fail method" );
  ok( !$$handle->can('leavewith_can'),  "$name: no leavewith_can method" );
}

sub basic {
  my ($func, $handle, $name) = @_;
  $argv_expected ||= ['A'];
  $ARGV_expected ||= [];
  $func->(sub { print "Hello"; warn "Hi!\n"; push @ARGV, $name; exit 1 });
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is( $$handle->exit, 1, "$name: trapped exit" );
  is( $$handle->stdout, "Hello", "$name: trapped stdout" );
  is( $$handle->stderr, "Hi!\n", "$name: trapped stderr" );
  is_deeply( $$handle->warn, ["Hi!\n"], "$name: trapped warnings" );
  ok( $$handle->can('stdout_pass'), "$name: stdout_pass method present" );
  $Test::Builder::Level++;
  no strict 'refs';
  $_->(@_) for @_[3..$#_];
}

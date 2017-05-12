#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/06-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 4*15 + 4*5 + 3*6 + 5*13; # non-default standard layers + capture strategies + internal exceptions + exits
use IO::Handle;
use File::Temp qw( tempfile );
use Data::Dump qw( dump );
use strict;
use warnings;

use Test::Trap; # XXX: testing ourselves ... too early, I suppose?

# The built-in non-default layers -- up against a standard.  So far
# just context manipulation:

for my $case
  ( [ standard => [           ], context => undef, ],
    [ Void     => [ ':void'   ], void    => undef, ],
    [ Scalar   => [ ':scalar' ], scalar  => '',    ],
    [ List     => [ ':list'   ], list    => 1,     ],
  ) {
    my ($name, $layer, $context, $wantarray) = @$case;
    my $x = 0;
    eval sprintf <<'TEST', ($name) x 4 or diag "Error in eval $name: $@";
#line 1 (%s)
      BEGIN {
	my @L = @$layer; # be nice to perl562
	trap { use_ok 'Test::Trap', '$T', $name, @L };
	$trap->did_return(" ... importing $name");
	$trap->quiet(' ... quietly');
      }

      () = trap { my $x; () = %s { $x = wantarray }; $x };
      if ($context eq 'context') {
        $trap->return_is_deeply( [1],  ' ... list context propagated' );
        $T->wantarray_is( 1, ' ... list context propagated' );
      }
      else {
        $trap->return_is_deeply( [$wantarray],  " ... forced $context context" );
        $T->wantarray_is( $wantarray, " ... forced $context context" );
      }
      $T->quiet( " ... with no output in the $name trap" );
      $trap->quiet( " ... and no output from the $name trap itself" );

      () = trap { my $x; scalar %s { $x = wantarray }; $x };
      if ($context eq 'context') {
        $trap->return_is_deeply( [''],  ' ... scalar context propagated' );
        $T->wantarray_is( '', ' ... scalar context propagated' );
      }
      else {
        $trap->return_is_deeply( [$wantarray],  " ... forced $context context" );
        $T->wantarray_is( $wantarray, " ... forced $context context" );
      }
      $T->quiet( " ... with no output in the $name trap" );
      $trap->quiet( " ... and no output from the $name trap itself" );


      () = trap { my $x; %s { $x = wantarray }; $x };
      if ($context eq 'context') {
        $trap->return_is_deeply( [undef],  ' ... void context propagated' );
        $T->wantarray_is( undef, ' ... void context propagated' );
      }
      else {
        $trap->return_is_deeply( [$wantarray],  " ... forced $context context" );
        $T->wantarray_is( $wantarray, " ... forced $context context" );
      }
      $T->quiet( " ... with no output in the $name trap" );
      $trap->quiet( " ... and no output from the $name trap itself" );
      1;
TEST
}

# The exceptions -- different layers that are supposed to raise an
# internal exception are added (in two copies!) to a default setup.
# Exceptions may be raised in the application of the layer, in the
# teardown, or both.  Exceptions in the application of the layer are
# immediate (and terminate the trap), but exceptions in teardown are
# delayed, and any number of teardown actions can raise an exception.

for my $case
  ( [ exception1 => sub { die "going down\n" },
      qr{^Rethrowing internal exception: going down\n at \(exception1\) line 7\.?\n\z},
      0, '(in layer, so user code not run)',
    ],
    [ exception2 => sub { my $self = shift; $self->Teardown(sub { die "going up\n" } ); $self->Next },
      qr{^Rethrowing teardown exception: going up\n\nRethrowing teardown exception: going up\n at \(exception2\) line 7\.?\n\z},
      1, '(in teardown, so user code has been run)',
    ],
    [ exception3 => sub { my $self = shift; $self->Teardown(sub { die "going up\n" } ); die "going down\n" },
      qr{^Rethrowing internal exception: going down\n\nRethrowing teardown exception: going up\n at \(exception3\) line 7\.?\n\z},
      0, '(in layer, so user code has not run)',
    ],
  ) {
    my ($name, $layer, $exception, $value, $test_name) = @$case;
    my $x = 0;
    eval sprintf <<'TEST', ($name) x 2, ( $value ? (teardown => 'run') : (layer => 'not run') ) or diag "Error in eval $name: $@";
#line 1 (%s)
      BEGIN {
	my $L = $layer; # be nice to perl562
	trap { use_ok 'Test::Trap', '$T', $name, $L, $L };
	$trap->did_return(" ... importing $name");
	$trap->quiet(' ... quietly');
      }
      trap { %s { ++$x } };
      $trap->die_like( $exception, ' ... internal exceptions caught and rethrown' );
      is( $x, $value, ' ... in %s, so user code %s' );
      $trap->quiet;
      1;
TEST
}

# Test the new :output() layer:
for my $case #    layers                        strategies              useable
  ( [ Tempfile => [ ':output(tempfile)'      ], '"tempfile"',           1                                  ],
    [ Perlio   => [ ':output(perlio)'        ], '"perlio"',             !!eval q{ use PerlIO 'scalar'; 1 } ],
    [ Mixed    => [ ':output(nosuch;perlio)' ], '("nosuch", "perlio")', !!eval q{ use PerlIO 'scalar'; 1 } ],
    [ Badout   => [ ':output(nosuch)'        ], '"nosuch"',             0                                  ],
  ) {
  my ($name, $layer, $strategies, $usable) = @$case;
  eval sprintf <<'TEST', ($name) x 2 or diag "Error in $name eval: $@";
#line 1 (%s)
    BEGIN {
      my @L = @$layer; # be nice to perl562
      trap { use_ok 'Test::Trap', '$T', $name, @L };
      $trap->did_return(" ... importing $name");
      $trap->quiet(' ... quietly');
    }
    () = trap { %s { print "foo" }; $T->stdout };
    if ($usable) {
      $trap->return_is_deeply( ['foo'], "Trapped the STDOUT with $name" );
    }
    else {
      $trap->die_like( qr/^No capture strategy found for \Q$strategies/, "Died with $name" );
    }
    $trap->warn_is_deeply( [], 'No warnings' );
    1;
TEST
  $@ and die "Got $@";
}

# Need some setup to test missing STDOUT/STDERR trapping layer:

STDOUT: {
  close STDOUT;
  my ($outfh, $outname) = tempfile( UNLINK => 1 );
  open STDOUT, '>', $outname;
  STDOUT->autoflush(1);
  print STDOUT '';
  sub stdout () { local $/; local *OUT; open OUT, '<', $outname or die; <OUT> }
  END { close STDOUT; close $outfh }
}

STDERR: {
  close STDERR;
  my ($errfh, $errname) = tempfile( UNLINK => 1 );
  open STDERR, '>', $errname;
  STDERR->autoflush(1);
  print STDERR '';
  sub stderr () { local $/; local *ERR; open ERR, '<', $errname or die; <ERR> }
  END { close STDERR; close $errfh }
}

# More setup, to deal with the "special" argv-messing layer:

local @ARGV; # in case some harness wants to mess with it ...
my @argv = ('A');
my $special = sub {
  my $self = shift;
  local *ARGV = \@argv;
  $self->{inargv} = [@argv];
  $self->Next;
  $self->{outargv} = [@argv];
};

# And then we apply varying combinations of layers, to test what is
# trapped and what isn't:

for my $case
  ( [ default  => [ ':default' ],                        qw( stdout stderr warn ) ],
    [ raw      => [ ':flow' ],                           qw( ) ],
    [ mixed    => [ ':raw:warn:stderr:stdout:exit:die'], qw( stdout stderr warn ) ],
    [ special  => [ ':default', $special ],              qw( stdout stderr warn argv )],
    [ warntrap => [ ':flow:warn' ],                      qw( warn ) ],
  ) {
    my ($name, $layer, @active) = @$case;
    my %t = map { $_ => 1 } @active;
    my @a = @ARGV;
    my @a2 = @argv;
    my $out = stdout;
    my $err = stderr;
    eval sprintf <<'TEST', ($name) x 2 or diag "Error in eval $name: $@";
#line 1 (%s)
      BEGIN {
	my @L = @$layer; # be nice to perl562
	trap { use_ok 'Test::Trap', '$T', $name, @L };
	$trap->did_return(" ... importing $name");
	$trap->quiet(' ... quietly');
      }
      %s { print 'Hello'; warn "Hi!\n"; push @ARGV, $name; exit 1 };
      is( $T->exit, 1, "&$name traps exit code 1" );
      if ($t{stdout}) {
	is( $T->stdout, 'Hello', ' ... the stdout' );
	is( stdout,     $out,    '     (preventing output on the previous STDOUT)' );
      }
      else {
	is( $T->stdout, undef,          ' ... no stdout' );
	is( stdout,     $out . 'Hello', '     (leaving the output going to the previous STDOUT)' );
      }
      if ($t{stderr}) {
	is( $T->stderr, "Hi!\n", ' ... the stderr' );
	is( stderr,     $err,    '     (preventing output on the previous STDERR)' );
      }
      else {
	is( $T->stderr, undef,          ' ... no stderr' );
	is( stderr,     $err . "Hi!\n", '     (leaving the output going to the previous STDERR)' );
      }
      &is_deeply( scalar $T->warn,
		  $t{warn} ? ( ["Hi!\n"], ' ... the warnings' )
			   : (  undef,    ' ... no warnings'  ),
		);
      if ($t{argv}) {
	is_deeply( $T->{inargv},  \@a2,         ' ... the in-@ARGV' );
	is_deeply( $T->{outargv}, [@a2, $name], ' ... the out-@ARGV' );
	is_deeply( \@ARGV,        \@a,          '     (keeping the real @ARGV unchanged)' );
	is_deeply( \@argv,        [@a2, $name], '     (instead modifying the lexical @argv)' );
      }
      else {
	is_deeply( $T->{inargv},  undef,       ' ... no in-@ARGV' );
	is_deeply( $T->{outargv}, undef,       ' ... no out-@ARGV' );
	is_deeply( \@ARGV,        [@a, $name], '     (so not preventing the modification of the real @ARGV)' );
	is_deeply( \@argv,        \@a2,        '     (leaving the lexical @argv unchanged)' );
      }
      1;
TEST
}

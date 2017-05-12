#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 61;

# We need IO::Capture::Std(out|err) only for this test, so rather than
# make the user install it for us, we have a copy for use in testing
use lib 't/lib';
use lib 'lib';
use lib '../lib';

use Test::Resub qw(resub);

use IO::Capture::Stdout;
use IO::Capture::Stderr;

sub _std_of {
  my ($class, $code) = @_;
  my $capture = $class->new;
  $capture->start;
  $code->();
  $capture->stop;
  return join "\n", $capture->read;
}

sub stderr_of { return _std_of('IO::Capture::Stderr', @_) }
sub stdout_of { return _std_of('IO::Capture::Stdout', @_) }

{
  my $orig_msg = 'aklejave geagk';

  {
    package TestResub;
    sub resub_me { 'uh uh' }
    sub resub_me2 { $orig_msg }
    sub resub_me3 { $orig_msg }
  }

  my $msg = 'yes, please';
  # successful resub method in scalar context
  is( TestResub::resub_me2(), $orig_msg );
  {
    my $resub = resub 'TestResub::resub_me2', sub { $msg };
    ok( $resub->not_called, 'start out uncalled' );

    is( TestResub::resub_me2(), $msg );
    is( $resub->called, 1, 'call counter increments' );
    ok( ! $resub->not_called, 'no longer uncalled' );

    # increment called counter
    TestResub::resub_me2();
    is( $resub->called, 2, 'call counter increments again' );

    # reset should reset the called counter, not the was_called flag
    $resub->reset;
    is( $resub->called, 0 );
    ok( $resub->was_called );
  }
  is( TestResub::resub_me2(), $orig_msg );

  # multiple resubs on the same method play nicely together
  {
    is( TestResub::resub_me2(), $orig_msg );
    {
      my $resub1 = Test::Resub->new({
        name => "TestResub::resub_me2",
        code => sub { 'one' },
      });
      is( TestResub::resub_me2(), 'one' );
      my $resub2 = Test::Resub->new({
        name => "TestResub::resub_me2",
        code => sub { 'two' },
      });
      is( TestResub::resub_me2(), 'two', 'can reresub');
    }
    is( TestResub::resub_me2(), $orig_msg );
  }

  # Argument capturing
  {
    # capture arguments with 'capture => 1',
    {
      my $resub = Test::Resub->new({
        name => "TestResub::resub_me2",
        code => sub { $msg },
      });
      is_deeply( $resub->args, [] );
      is_deeply( $resub->method_args, [] );
      TestResub::resub_me2();
      TestResub::resub_me2('abc', [1,2,3]);
      is_deeply( $resub->args, [[], ['abc', [1,2,3]]] );
      is_deeply( $resub->method_args, [[], [[1,2,3]]] );
      $resub->reset;
      is_deeply( $resub->args, [] );
      is_deeply( $resub->method_args, [] );
      is_deeply( $resub->named_args, [] );

      # named args
      TestResub::resub_me2(dog => 'bark', cat => 'meow');
      is_deeply( $resub->named_args, [{
        dog => 'bark',
        cat => 'meow',
      }] );
      $resub->reset;

      # named method args
      TestResub->resub_me2(dog => 'bark', cat => 'meow');
      is_deeply( $resub->named_method_args, [{
        dog => 'bark',
        cat => 'meow',
      }] );

      # Make sure we can call the puppy twice in a row.  No, seriously.
      is_deeply( $resub->named_method_args, [{
        dog => 'bark',
        cat => 'meow',
      }] );

      # allow us to shift off the first N scalars before the %args
      $resub->reset;
      TestResub->resub_me2('timestamp', dog => 'bark', cat => 'meow');
      is_deeply( [$resub->named_method_args(scalars => 1)], [[
        'timestamp',
        {
          dog => 'bark',
          cat => 'meow',
        },
      ]] );
      is_deeply( [$resub->named_method_args(scalars => 3)], [[
        'timestamp',
        'dog',
        'bark',
        {
          cat => 'meow',
        },
      ]] );

      # really, really shift off the first N scalars before the %args
      is_deeply( $resub->named_method_args(arg_start_index => 3), [{
        cat => 'meow',
      }] );
      is_deeply( $resub->named_args(arg_start_index => 4), [{
        cat => 'meow',
      }] );
    }

    # default replacement code is 'sub {}'
    {
      {
        package DifferentDefault;
        use base qw(Test::Resub);
        sub default_replacement_sub { sub { 'bell-bottoms' } }
      }
      my $no_specified_code = DifferentDefault->new({
        name => 'TestResub::resub_me2',
        call => 'optional',
      });
      is( TestResub::resub_me2, 'bell-bottoms' );

    }
    {
      {
        package Test::Resub;
        use Data::Dumper;
        use strict;
        local $Data::Dumper::Deparse = 1;
        main::is( Dumper(Test::Resub->default_replacement_sub),
          Dumper(sub {}) );
      }
    }
  }

  # error when trying to resub improperly named method
  {
    local $@;
    eval {
      my $rs = Test::Resub->new({name => 'Hello->world', code => sub { 1 }});
    };
    like( $@, qr/bad method name/i, 'catch bad method names' );
    like( $@, qr/01-main/, "error is from caller's perspective" );
  }

  # won't resub things into existence without create flag
  {
    local $@;
    eval {
      my $rs = resub "TestResub::kinks_Flourtown";
    };
    like( $@,
      qr/Package TestResub doesn't implement nor inherit a sub named 'kinks_Flourtown'.*'create' flag/,
      "Don't create nonexistent functions unless told to",
    );

    my $rs = resub "TestResub::countersunk_hilltopped", sub { 2336 }, create => 1;
    is( TestResub->countersunk_hilltopped(), 2336 );
  }

  # error when passing bad 'call' argument
  {
    local $@;
    eval {
      my $rs = Test::Resub->new({name => 'main::function', call => 'spork'});
    };
    like( $@, qr/call.*spork/i );
  }
}

{
  package TestBase;
  sub base_method { 1; }

  package TestChild;
  use base qw(TestBase);
  sub child_method { }

  package main;

  $TestChild::base_method = (my $keep_scalar = "Don't hurt me!");
  @TestChild::base_method = my @keep_array = qw(leave us alone);
  %TestChild::base_method = my %keep_hash = ('eliminate?' => 'no!');
  $TestChild::keep_me_too = (my $keep_me_too = "Me either!");
  @TestChild::keep_me_too = my @keep_me_too = qw(don't throw me out);
  %TestChild::keep_me_too = my %keep_me_too = (keep => 1);
  {
    my $rs = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { 0 },
    });

    is( TestChild->base_method(), 0 );
  }

  is( TestChild->base_method(), 1 );

  {
    my $rs2 = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { 18 },
    });
    my $rs3 = Test::Resub->new({
      name => 'TestChild::dont_exist',
      code => sub { 22 },
      create => 1,
    });

    # this next test is important; it used to break.
    is( TestChild->base_method(), 18 );
    is( TestChild->dont_exist(), 22 );
  }

  is( TestChild->base_method(), 1 );
  ok( not UNIVERSAL::can('TestChild', 'dont_exist') )
    or warn TestChild->dont_exist;

  is( eval '$TestChild::base_method', $keep_scalar );
  is_deeply( [eval '@TestChild::base_method'], \@keep_array );
  is_deeply( {eval '%TestChild::base_method'}, \%keep_hash );
  is( eval '$TestChild::keep_me_too', $keep_me_too );  # sanity check
  is_deeply( [eval '@TestChild::keep_me_too'], \@keep_me_too );
  is_deeply( {eval '%TestChild::keep_me_too'}, \%keep_me_too );

  # resub'd methods that don't specify otherwise cause failures if not called
  {
    my $rs = resub 'TestChild::base_method', sub { };
    like( stdout_of(sub{ undef $rs }), qr/not ok 1000/ );
  }

  # resub'd methods that specify 'required' cause failures if not called
  # this is also the default
  {
    my $rs = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { },
    });
    my $output = stdout_of(sub { undef $rs });
    like( $output, qr/not ok 1000.+was not called/, q{not ok 1000 if not called} );

    $rs = resub('TestChild::base_method', sub {}, call => 'required');
    like( stdout_of(sub{ undef $rs }), qr/not ok 1000/ );
  }

  # don't fail if we're required and called
  {
    my $rs = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { },
    });
    TestChild->base_method();
  }

  # we don't fail if uncalled and we've declared that to be o.k.
  {
    my $rs = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { },
      call => 'forbidden',
    });
  }

  # we DO fail if called when we don't expect to be
  {
    my $rs = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { },
      call => 'forbidden',
    });
    TestChild->base_method();
    my $output = stdout_of(sub{ undef $rs });
    like( $output, qr/not ok 1000.+was called/ );
    like( $output, qr/Test::Resub/ ) or warn $output;
  }

  # we don't fail if uncalled and we've declared calling optional
  {
    my $rs = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { },
      call => 'optional',
    });
  }

  # we don't fail if called and we've declared calling optional
  {
    my $rs = Test::Resub->new({
      name => 'TestChild::base_method',
      code => sub { },
      call => 'optional',
    });
    TestChild->base_method();
  }
}

# A resubbed inherited method gets restored back to undef
{
  {
    package InheritBase;
    sub method { 10 }
  }
  {
    package Inherit;
    use base qw(InheritBase);
  }

  is( Inherit->method, 10 );
  {
    my $rs1 = Test::Resub->new({
      name => 'InheritBase::method',
      code => sub { 15 },
    });
    is( Inherit->method, 15 );
    {
      my $rs2 = Test::Resub->new({
        name => 'Inherit::method',
        code => sub { 20 },
      });
      is( Inherit->method, 20 );
    }
    is( Inherit->method, 15 );
  }
  is( Inherit->method, 10 );
}

# Resub objects don't get destroyed where we expect if we close over them
{
  {
    package CloseOverMe;
    sub close_over_me { 'close_over_me' }
  }

  {
    my $d;
    $d = Test::Resub->new({
      name => 'CloseOverMe::close_over_me',
      code => sub {
        my $count = $d->called;
        return 'CLOSE_OVER_ME';
      },
    });

    is( CloseOverMe::close_over_me(), 'CLOSE_OVER_ME' );
  }
  is( CloseOverMe::close_over_me(), 'CLOSE_OVER_ME' );
}

# When capturing args, don't save off the actual args, save off a copy. This
#  lets us capture args when resub'ing a method or function which uses pass-by-
#  reference to change its caller's values (like perl's built-in select)
{
  sub capture_test { 99 }
  my $rs = Test::Resub->new({
    name => 'main::eternalised',
    code => sub { $_[0] = 88 },
    capture => 1,
    create => 1,
  });

  my $arg = 'sagittiform';
  eternalised($arg);

  is_deeply( $rs->args, [['sagittiform']] );  # Not 88!
}

# Coderefs can be captured
{
  my $rs = Test::Resub->new({
    name => 'main::some_random_function',
    create => 1,
    capture => 1,
  });
  some_random_function(sub {});
  is( ref($rs->args->[0][0]), 'CODE', 'saved a coderef' );
}

# Although coderefs can be captured, we don't affect how dclone
# works universally.
{
  require Storable;
  my $rs = resub 'some::function', sub {
    Storable::dclone([@_]);
  }, create => 1;

  my @args = ([1, 2, 3], sub { (4, 5, 6) }, [7, 8, 9]);

  my $error;
  local $@;
  eval {
    local $@;
    local $SIG{__DIE__} = sub { $error = shift };
    eval { some::function(@args) };
  };
  like ( $error, qr/Can't store CODE items/, "our use of dclone() doesn't globally affect dclone" );
}

package Test::Script::Async;

use strict;
use warnings;
use 5.008001;
use Carp ();
use AnyEvent::Open3::Simple 0.86;
use File::Spec ();
use Probe::Perl;
use Test2::API qw( context );
use base qw( Exporter );

# ABSTRACT: Non-blocking friendly tests for scripts
our $VERSION = '0.02'; # VERSION

our @EXPORT    = qw( script_compiles script_runs );


sub _path ($)
{
  my $path = shift;
  Carp::croak("Did not provide a script name") unless $path;
  Carp::croak("Script name must be relative") if File::Spec::Unix->file_name_is_absolute($path);
  File::Spec->catfile(
    File::Spec->curdir,
    split /\//, $path
  );
}

my $perl;

sub _perl ()
{
  $perl ||= Probe::Perl->find_perl_interpreter;
}

sub _detect
{
  if(grep /^(Mojo|Mojolicious)(\/.*)?\.pm?$/, keys %INC)
  { 'mojo' }
  else
  { return undef }
}

sub _is_mojo
{
  my $detect = _detect();
  defined $detect && $detect eq 'mojo';
}


sub script_compiles
{
  my($script, $test_name) = @_;
  my @libs = map { "-I$_" } grep { !ref($_) } @INC;
  my @cmd = ( _perl, @libs, '-c', _path $script );
  
  $test_name ||= "Script $script compiles";
  
  # TODO: also work with mojo
  my $done;
  unless(_detect())
  {
    require AE;
    $done = AE::cv();
  }
  my @stderr;

  my $ctx = context();

  my $ipc = AnyEvent::Open3::Simple->new(
    on_stderr => sub {
      my($proc, $line) = @_;
      push @stderr, $line;
    },
    on_exit   => sub {
      my($proc, $exit, $sig) = @_;
      
      my $ok = $exit == 0 && $sig == 0 && grep / syntax OK$/, @stderr;
      
      $ctx->send_event('Ok', pass => $ok, name => $test_name);
      $ctx->diag(@stderr) unless $ok;
      $ctx->diag("exit - $exit") if $exit;
      $ctx->diag("signal - $sig") if $sig;
      
      $done->send($ok);
      
    },
    on_error  => sub {
      my($error) = @_;
      
      $ctx->send_event('Ok', pass => 0, name => $test_name);
      $ctx->diag("error compiling script: $error");
      
      $done->send(0);
    },
  );
  
  $ipc->run(@cmd);
  my $ok = $done->recv;
  $ctx->release;
  
  $ok;
}


# TODO: support stdin input

sub script_runs
{
  my($script, $test_name) = @_;
  my @libs = map { "-I$_" } grep { !ref($_) } @INC;
  $script = [ $script ] unless ref $script;
  my @args;
  ($script, @args) = @$script;
  my @cmd = ( _perl, @libs, _path $script, @args );
  
  $test_name ||= @args ? "Script $script runs with arguments @args" : "Script $script runs";
  
  # TODO: also work with mojo
  my $done;
  unless(_detect())
  {
    require AE;
    $done = AE::cv();
  }
  my $run = bless {
    script => _path $script,
    args   => [@args],
    out    => [],
    err    => [], 
    ok     => 0,
  }, __PACKAGE__;
  my $ctx = context();

  unless(-f $script)
  {
    $ctx->send_event('Ok', pass => 0, name => $test_name);
    $ctx->diag("script does not exist");
    $run->{fail} = 'script not found';
    $ctx->release;
    return $run;
  }

  my $ipc = AnyEvent::Open3::Simple->new(
    implementation => _detect(),
    on_stderr => sub {
      my(undef, $line) = @_;
      push @{ $run->{err} }, $line;
    },
    on_stdout => sub {
      my(undef, $line) = @_;
      push @{ $run->{out} }, $line;
    },
    on_exit   => sub {
      (undef, $run->{exit}, $run->{signal}) = @_;

      $run->{ok} = 1;
      $ctx->send_event('Ok', pass => 1, name => $test_name);
      
      _is_mojo() ? $done = 1 : $done->send;
      
    },
    on_error  => sub {
      my($error) = @_;
      
      $run->{ok} = 0;
      $run->{fail} = $error;
      $ctx->send_event('Ok', pass => 0, name => $test_name);
      $ctx->diag("error running script: $error");      
      _is_mojo() ? $done = 1 : $done->send;
    },
  );
  
  $ipc->run(@cmd);
  if(_is_mojo())
  {
    Mojo::IOLoop->one_tick until $done;
  }
  else
  {
    $done->recv;
  }
  $ctx->release;
  
  $run;
}


sub out { shift->{out} }
sub err { shift->{err} }
sub exit { shift->{exit} }
sub signal { shift->{signal} }


our $reverse = 0;
our $level   = 0;

sub exit_is
{
  my($self, $value, $test_name) = @_;
  my $ctx = context( level => $level );

  $test_name ||= $reverse ? "script exited with a value other than $value" : "script exited with value $value";
  my $ok = defined $self->exit && !$self->{signal} && ($reverse ? $self->exit != $value : $self->exit == $value);

  $ctx->send_event('Ok', pass => $ok, name => $test_name);
  if(!defined $self->exit)
  {
    $ctx->diag("script did not run so did not exit");
  }
  elsif($self->signal)
  {
    $ctx->diag("script killed with signal @{[ $self->signal ]}");
  }
  elsif(!$ok)
  {
    $ctx->diag("script exited with value @{[ $self->exit ]}");
  }
  
  $self->{ok} = 0 unless $ok;

  $ctx->release;
  $self;
}


sub exit_isnt
{
  local $reverse = 1;
  local $level   = 1;
  shift->exit_is(@_);
}


sub signal_is
{
  my($self, $value, $test_name) = @_;
  my $ctx = context(level => $level);

  $test_name ||= $reverse ? "script not killed by signal $value" : "script killed by signal $value";
  my $ok = $self->signal && ($reverse ? $self->signal != $value : $self->signal == $value);

  $ctx->send_event('Ok', pass => $ok, name => $test_name);
  if(!defined $self->signal)
  {
    $ctx->diag("script did not run so was not killed");
  }
  elsif(!$self->signal)
  {
    $ctx->diag("script exited with value @{[ $self->exit ]}");
  }
  elsif(!$ok)
  {
    $ctx->diag("script killed with signal @{[ $self->signal ]}");
  }

  $self->{ok} = 0 unless $ok;

  $ctx->release;
  $self;
}


sub signal_isnt
{
  local $reverse = 1;
  local $level   = 1;
  shift->signal_is(@_);
}


our $stream = 'out';
our $stream_name = 'standard output';

sub out_like
{
  my($self, $regex, $test_name) = @_;
  
  my $ctx = context(level => $level);
  $test_name ||= $reverse ? "$stream_name does not match $regex" : "$stream_name matches $regex";
  
  my $ok;
  my @diag;
  
  if($reverse)
  {
    $ok = 1;
    my $num = 1;
    foreach my $line (@{ $self->{$stream} })
    {
      if($line =~ $regex)
      {
        $ok = 0;
        push @diag, "line $num of $stream_name matches: $line";
      }
      $num++;
    }
  }
  else
  {
    $ok = 0;
    foreach my $line (@{ $self->{$stream} })
    {
      if($line =~ $regex)
      {
        $ok = 1;
        last;
      }
    }
  }
  
  $ctx->send_event('Ok', pass => $ok, name => $test_name);
  $ctx->diag($_) for @diag;
  
  $ctx->release;
  $self->{ok} = 0 unless $ok;
  
  $self;
}


sub out_unlike
{
  local $reverse = 1;
  local $level   = 1;
  shift->out_like(@_);
}


sub err_like
{
  local $stream      = 'err';
  local $stream_name = 'standard error';
  local $level       = 1;
  shift->out_like(@_);
}


sub err_unlike
{
  local $stream      = 'err';
  local $stream_name = 'standard error';
  local $reverse     = 1;
  local $level       = 1;
  shift->out_like(@_);
}


our $diag = 'diag';

sub diag
{
  my($self) = @_;

  my $ctx = context(level => $level);
  
  $ctx->$diag("script:    @{[ $self->{script} ]}");
  $ctx->$diag("arguments: @{[ join ' ', @{ $self->{args} } ]}") if @{ $self->{args} };
  if(defined $self->{fail})
  {
    $ctx->$diag("error:     @{[ $self->{fail} ]}");
  }
  elsif($self->signal)
  {
    $ctx->$diag("signal:    @{[ $self->signal ]}");
  }
  else
  {
    $ctx->$diag("exit:      @{[ $self->exit ]}");
  }
  $ctx->$diag("[out] $_") for @{ $self->out };
  $ctx->$diag("[err] $_") for @{ $self->err };
  
  $ctx->release;
  
  $self;
}


sub note
{
  local $diag  = 'note';
  local $level = 1;
  shift->diag;
}


sub diag_if_fail
{
  my($self) = @_;
  return if $self->{ok};
  local $level = 1;
  $self->diag;
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Script::Async - Non-blocking friendly tests for scripts

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Test2::Bundle::Extended;
 use Test::Script::Async;
 
 plan 4;
 
 # test that the scripts compiles.
 script_compiles 'script/myscript.pl';
 
 # test that we are able to run the script
 script_runs('script/myscript.pl')
   # and it exits with a success value
   ->exit_is(0)
   # and that the standard output has
   # foo in it somewhere
   ->out_like(qr{foo})
   # print diagnostic if any of the tests
   # for this run failed.  Useful for
   # cpan testers reports
   ->diag_if_fail;

=head1 DESCRIPTION

This is a non-blocking friendly version of L<Test::Script>.  It is useful when you have scripts
that you want to test against a L<AnyEvent> or L<Mojolicious> based services that are running
in the main test process.  The L<AnyEvent> implementations that are known to work with this
module are pure perl, L<EV> and L<Event>.  Others may work, or may be added in the future.

This module will use L<Mojo::IOLoop> if any L<Mojo> modules are loaded.  The L<Mojo> event loop
only works with L<EV> if you want to use L<AnyEvent>, so make sure that you include a C<use EV>
line if you intend on using both L<AnyEvent> and L<Mojolicious>.

The interface is different from L<Test::Script> for running scripts, in that it is object oriented.
The L</script_runs> function only tests that the script was able to run normally, and returns
an instance of L<Test::Script::Async> which can be interrogated for things like the exit value
and output.

It uses the brand spanking new L<Test2> framework, which is experimental as of this writing.
In particular it is not currently compatible with L<Test::More> and L<Test::Builder>, but hopefully
will be one day.

=head1 FUNCTIONS

=head2 script_compiles

 script_compiles $scriot;
 script_compiles $script, $test_name;

Tests to see Perl can compile the script.

C<$script> should be the path to the script in unix-format non-absolute form.

=head2 script_runs

 my $run = script_runs $script;
 my $run = script_runs $script, $test_name;
 my $run = script_runs [ $script, @arguments ];
 my $run = script_runs [ $script, @arguments ], $test_name;

Attempt to run the given script.  The only test made on this call
is simply that the script ran.  The reasons this test might fail
are: the script does not exist, or the operating system is unable
to execute perl to run the script.  The returned C<$run> object
(an instance of L<Test::Script::Async>) can be used to further
test the success or failure of the script run. 

Note that this test does NOT fail on compile error, for that
use L</script_compiles>.

=head1 ATTRIBUTES

=head2 out

 my $listref = $run->out;

Returns a list reference of the captured standard output, split on new lines.

=head2 err

 my $listref = $run->err;

Returns a list reference of the captured standard error, split on new lines.

=head2 exit

 my $int = $run->exit;

Returns the exit value of the script run.

=head2 signal

 my $int = $run->signal;

Returns the signal that killed the script, if any.  It will be 0 if the script
exited normally.

=head1 METHODS

=head2 exit_is

 $run->exit_is($value);
 $run->exit_is($value, $test_name);

Test passes if the script run exited with the given value.

=head2 exit_isnt

 $run->exit_isnt($value);
 $run->exit_isnt($value, $test_name);

Same as L</exit_is> except the test fails if the exit value matches.

=head2 signal_is

 $run->signal_is($value);
 $run->signal_is($value, $test_name);

Test passes if the script run was killed by the given signal.

Note that this is inherently unportable!  Especially on Windows!

=head2 signal_isnt

 $run->signal_isnt($value);
 $run->signal_isnt($value, $test_name);

Same as L</signal_is> except the test fails if the exit value matches.

=head2 out_like

 $run->out_like($regex);
 $run->out_like($regex, $test_name);

Test passes if one of the output lines matches the given regex.

=head2 out_unlike

 $run->out_like($regex);
 $run->out_like($regex, $test_name);

Test passes if none of the output lines matches the given regex.

=head2 err_like

 $run->out_like($regex);
 $run->out_like($regex, $test_name);

Test passes if one of the standard error output lines matches the given regex.

=head2 err_unlike

 $run->err_like($regex);
 $run->err_like($regex, $test_name);

Test passes if none of the standard error output lines matches the given regex.

=head2 diag

 $run->diag;

Print out diagnostics (with C<diag>) to describe the run of the script.
This includes the script filename, any arguments, the termination status
(either error, exit value or signal number), the output and the standard
error output.

=head2 note

 $run->note;

Same as L</diag> above, but use C<note> instead of C<diag> to print out
the diagnostic.

=head2 diag_if_fail

 $run->diag_if_fail;

Print out full diagnostic using L</diag> if any of the tests for this run
failed.  This can be handy after a long series of tests for cpan testers.
If everything is good then no diagnostic is printed but if anything failed,
then you will see the script, arguments, termination status and output.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

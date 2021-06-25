package Test2::Tools::FFI;

use strict;
use warnings;
use 5.008001;
use base qw( Exporter );
use FFI::Platypus 1.00;
use FFI::CheckLib 0.11 ();
use File::Basename ();
use Cwd ();
use File::Glob ();
use Test2::API qw( context );
use Test2::EventFacet::Trace;

# ABSTRACT: Tools for testing FFI
our $VERSION = '0.06'; # VERSION

our @EXPORT = qw( ffi ffi_options );


{
  my $singleton;

  sub ffi
  {
    unless($singleton)
    {
      $singleton = bless {}, 'Test2::Tools::FFI::Single';
    }

    $singleton;
  }


  sub ffi_options
  {
    my(%options) = @_;
    Carp::croak("Please call ffi_options before calling ffi")
      if defined $singleton;

    my $ffi = ffi();

    my @new_args;

    if(my $api = delete $options{api})
    {
      push @new_args, api => $api;
    }

    $ffi->{new_args} = \@new_args;

    Carp::croak("Unknown option or options: @{[ sort keys %options ]}")
      if %options;
  }
}

sub _pass
{
  my($name, @location) = @_;
  my $ctx = context();
  $ctx->send_event(
    'Pass',
    name => $name,
    # this seems to swallow some info, be good
    # to know if we need it.
    trace => Test2::EventFacet::Trace->new(
      frame => [@location],
    )
  );
  $ctx->release;
}

sub _fail
{
  my($name, @location) = @_;
  my $ctx = context();
  $ctx->send_event(
    'Fail',
    name => $name,
    trace => Test2::EventFacet::Trace->new(
      frame => [@location],
    )
  );
  $ctx->release;
}

sub _note
{
  my($message, @location) = @_;
  my $ctx = context();
  $ctx->send_event(
    'Note',
    message => $message,
    trace => Test2::EventFacet::Trace->new(
      frame => [@location],
    )
  );
  $ctx->release;
}

sub _diag
{
  my($message, @location) = @_;
  my $ctx = context();
  $ctx->send_event(
    'Diag',
    message => $message,
    trace => Test2::EventFacet::Trace->new(
      frame => [@location],
    )
  );
  $ctx->release;
}

{
  local $ENV{FFI_PLATYPUS_DLERROR} = 1;
  our $ffi = FFI::Platypus->new( api => 1 );
  our @closures = map { $ffi->closure($_) } \&_note, \&_diag, \&_pass, \&_fail;
  $ffi->bundle;
  $ffi->type('(string,string,string,int,string)->void' => 'message_cb_t');
  $ffi
    ->function(t2t_simple_init => ['message_cb_t','message_cb_t','message_cb_t','message_cb_t'] => 'void')
    ->call(@closures);
}

package Test2::Tools::FFI::Single;


sub runtime
{
  my($self) = @_;

  $self->{runtime} ||= (sub {
    my $ffi = Test2::Tools::FFI::Platypus->new( @{ $self->{new_args} } );

    my @dll = File::Glob::bsd_glob("blib/lib/auto/share/dist/*/lib/*");
    if(@dll)
    {
      $ffi->lib(@dll);
      return $ffi;
    }

    @dll = File::Glob::bsd_glob("share/lib/*");
    if(@dll)
    {
      $ffi->lib(@dll);
      return $ffi;
    }
    $ffi;
  })->();
}


sub _build_test
{
  if(-d "t/ffi")
  {
    require FFI::Build::MM;
    require Capture::Tiny;

    my($output, $error) = Capture::Tiny::capture_merged(sub {
      local $@ = '';
      eval {
        my $fbmm = FFI::Build::MM->new( save => 0 );
        $fbmm->mm_args( DISTNAME => "My-Test" );  # the DISTNAME isn't used for building the test anyway.
        $fbmm->test->build;
      };
      $@;
    });
    if($error)
    {
      my $ctx = Test2::API::context();
      $ctx->diag($error);
      $ctx->diag($output);
      $ctx->release;
      die $error;
    }
    else
    {
      my $ctx = Test2::API::context();
      $ctx->note($output);
      $ctx->release;
    }
  }
}

sub test
{
  my($self) = @_;

  $self->{test} ||= do {
    _build_test();
    my $ffi = Test2::Tools::FFI::Platypus->new( @{ $self->{new_args} } );
    my @lib = FFI::CheckLib::find_lib(
      lib => '*',
      libpath => 't/ffi/_build',
      systempath => [],
    );
    Carp::croak("unable to find test lib in t/ffi/_build")
      unless @lib;
    $ffi->lib(@lib);
    $ffi;
  };
}


sub combined
{
  my($self) = @_;

  $self->{combined} ||= do {
    _build_test();
    my $rt = $self->runtime;
    my $t  = $self->test;
    my $ffi = Test2::Tools::FFI::Platypus->new( @{ $self->{new_args} } );
    $ffi->lib($rt->lib, $t->lib);
    $ffi;
  };
}

package Test2::Tools::FFI::Platypus;

use base qw( FFI::Platypus );
use Test2::API ();

sub symbol_ok
{
  my($self, $symbol_name, $test_name) = @_;

  $test_name ||= "Library has symbol: $symbol_name";
  my $address = $self->find_symbol($symbol_name);

  my $ctx = Test2::API::context();
  if($address)
  {
    $ctx->pass_and_release($test_name);
  }
  else
  {
    $ctx->fail_and_release($test_name, map { "looked in $_" } $self->lib);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::FFI - Tools for testing FFI

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your t/ffi/test.c:

 int
 mytest()
 {
   return 42;
 }

In your t/mytest.t:

 use Test2::V0;
 use Test2::Tools::FFI;

 is(
   ffi->test->function( mytest => [] => 'int')->call,
   42,
 );
 
 done_testing;

=head1 DESCRIPTION

This Test2 Tools module provide some basic tools for testing FFI modules.

=head1 FUNCTIONS

=head2 ffi_options

 ffi_options %options;

This must be run before any C<< ffi-> >> functions.  Options available:

=over 4

=item api

The L<FFI::Platypus> api level.  Zero (0) by default for backward compat,
but it is recommended that you use One (1).

=back

=head2 ffi->runtime

 my $ffi = ffi->runtime;

Returns a L<FFI::Platypus> instance connected to the runtime for your module.

=head2 ffi->test

 my $ffi = ffi->test;

Returns a L<FFI::Platypus> instance connected to the test for your module.

=head2 ffi->combined

 my $ffi = ffi->combined;

Return a L<FFI::Platypus> instance with the combined test and runtime libraries for your module.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Test2::Tools::FFI;

use strict;
use warnings;
use 5.008001;
use base qw( Exporter );
use FFI::Platypus;
use FFI::CheckLib 0.11 ();
use File::Basename ();
use Cwd ();
use File::Glob ();
use Test2::API qw( context );
use Test2::EventFacet::Trace;

# ABSTRACT: Tools for testing FFI
our $VERSION = '0.05'; # VERSION

our @EXPORT = qw( ffi );


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
  our $ffi = FFI::Platypus->new;
  our @closures = map { $ffi->closure($_) } \&_note, \&_diag, \&_pass, \&_fail;
  $ffi->package;
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
    my $ffi = Test2::Tools::FFI::Platypus->new;

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


sub test
{
  my($self) = @_;

  $self->{test} ||= do {
    my $ffi = Test2::Tools::FFI::Platypus->new;
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
    my $rt = $self->runtime;
    my $t  = $self->test;
    my $ffi = Test2::Tools::FFI::Platypus->new;
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

version 0.05

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

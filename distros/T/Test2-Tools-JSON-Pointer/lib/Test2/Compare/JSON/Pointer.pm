package Test2::Compare::JSON::Pointer;

use strict;
use warnings;
use Test2::Util::HashBase qw( pointer input json );
use JSON::Pointer;
use Encode ();
use parent 'Test2::Compare::Base';

# ABSTRACT: Representation of a hash or array reference pointed to by a JSON pointer during deep comparison.
our $VERSION = '0.01'; # VERSION


sub operator { 'JSON PTR' }

sub name
{
  my($self) = @_;
  my($input, $pointer) = ($self->{+INPUT}, $self->{+POINTER});
  $pointer eq '' ? "$input" : "$pointer $input";
}

sub verify
{
  my($self, %params) = @_;
  my($got, $exists) = @params{'got','exists'};

  return 0 unless $exists;
  return 1;
}

sub _convert_got
{
  my(undef, $got) = @_;

  if(ref $got)
  {
    if(eval { $got->isa('Path::Tiny') })
    {
      return $got->slurp_raw;
    }
    elsif(eval { $got->isa('Path::Class::File') })
    {
      return $got->slurp(iomode => '<:unix');
    }
  }

  return Encode::encode("UTF-8", $got);
}

sub deltas
{
  my($self, %p) = @_;
  my($got, $convert) = @p{'got','convert','seen'};

  my $check = $convert->($self->{+INPUT});

  my $got_root_ref = eval {
    $self->{+JSON}->decode($self->_convert_got($got));
  };

  my $pointer = $self->{+POINTER};
  my $id = [ META => $pointer eq '' ? 'JSON' : "JSON $pointer" ];

  if(my $error = "$@")
  {
    my $check = $convert->('valid json');
  
    $error =~ s/ at \S+ line [0-9]+\.//;
    return $check->delta_class->new(
      verified  => undef,
      id        => $id,
      got       => undef,
      check     => $check,
      exception => "invalid json: $error",
    );
  }

  my $got_ref;
  my $exists;

  if(JSON::Pointer->contains($got_root_ref, $pointer))
  {
    $exists  = 1;
    $got_ref = JSON::Pointer->get($got_root_ref, $pointer);
  }
  else
  {
    $exists = 0;
  }

  my $delta = $check->run(
    id      => $id,
    got     => $got_ref,
    exists  => $exists,
    convert => $convert,
    seen    => {},
  );

  $delta ? $delta : ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Compare::JSON::Pointer - Representation of a hash or array reference pointed to by a JSON pointer during deep comparison.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Test2::Compare::JSON::Pointer;
 use JSON::PP;
 
 sub my_json_test
 {
   my($pointer, $json) = @_;
   my @caller = caller;
   Test2::Compare::JSON::Pointer->new(
     file    => $caller[1],
     lines   => [$caller[2]],
     input   => $json,
     pointer => $pointer,
     json    => JSON::PP->new->utf8,
  );
 }

=head1 DESCRIPTION

This class lets you specify an expected hash or array reference in deep comparison along with the JSON
pointer for where to find that reference.

=head1 BASE CLASS

L<Test2::Compare::Base>

=head1 ATTRIBUTES

=over 4

=item pointer

 my $string = $cmp->pointer;

The JSON pointer as a string.  Something like C</foo/bar> would point to C<baz> in the json string

 {"foo":{"bar":"baz"}}

=item input

 my $string = $cmp->input;

The JSON to be compared against.  This should be a regular Perl scalar in Perl's internal format.
It will be encoded into UTF-8 before being decoded.

=item json

 my $json = $cmp->json;

The JSON object used for decoding JSON.  Any one of L<JSON::PP>, L<JSON::XS>, L<JSON::MaybeXS>
or compatible ought to work.

=back

=head1 SEE ALSO

=over 4

=item L<TEst2::Tools::JSON::Pointer>

This is what you would use in a C<.t> file, and probably what you are interested in.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Test::SpellCheck::INI;

use strict;
use warnings;
use 5.026;
use experimental qw( signatures );
use base qw( Config::INI::Reader );

# ABSTRACT: INI Parser for Test::SpellCheck
our $VERSION = '0.02'; # VERSION


sub new ($class)
{
  my $self = $class->SUPER::new;
  $self->{data} = [[undef,{}]];
  return $self;
}

sub change_section ($self, $name)
{
  push $self->{data}->@*, [$name,{}];
}

sub set_value ($self, $name, $value)
{
  my $h = $self->{data}->[-1]->[1];
  if(exists $h->{$name})
  {
    if(ref $h->{$name} eq 'ARRAY')
    {
      push $h->{$name}->@*, $value;
    }
    else
    {
      $h->{$name} = [ $h->{$name}, $value ];
    }
  }
  else
  {
    $h->{$name} = $value;
  }
}

sub finalize ($self)
{
  foreach my $array ($self->{data}->@*)
  {
    my $hash = pop $array->@*;
    foreach my $key (sort keys %$hash)
    {
      my $value = $hash->{$key};
      push $array->@*, $key => $value;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SpellCheck::INI - INI Parser for Test::SpellCheck

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This class is private to L<Test::SpellCheck>.

=head1 SEE ALSO

=over 4

=item L<Test::SpellCheck>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Valiant::Util::Exception::UnexpectedUseModuleError;

use Moo;
extends 'Valiant::Util::Exception';

has err => (is=>'ro', required=>1);
has package => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  return "Package '@{[ $self->package ]}' returned unexpected error: @{[ $self->err ]}.";
}

1;

=head1 NAME

Valiant::Util::Exception::UnexpectedUseModuleError - Unexpected error while using a module dynamically

=head1 SYNOPSIS

    throw_exception UnexpectedUseModuleError => (package => $package, err => $@);

=head1 DESCRIPTION

We tried to load a module dynamically and got an error we can't handle for you.

=head1 ATTRIBUTES

=head2 err

=head2 package

The string message of the returned error and the package that caused it when trying to use dynamically

=head2 message

The actual exception message

=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

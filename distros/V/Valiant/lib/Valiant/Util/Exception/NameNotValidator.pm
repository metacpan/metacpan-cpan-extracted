package Valiant::Util::Exception::NameNotValidator;

use Moo;
extends 'Valiant::Util::Exception';

has name => (is=>'ro', required=>1);
has packages => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  my $ns = join(', ', @{$self->packages});
  return "Validator namepart '@{[ $self->name ]}' not found in existing namespace \@INC: $ns";
}

1;

=head1 NAME

Valiant::Util::Exception::NameNotValidator - Failure to load a validator

=head1 SYNOPSIS

    throw_exception('NameNotValidator', name => $key, packages => \@validator_packages)

=head1 DESCRIPTION

Encapsulates an error when the validator namepart you use can't be found in the validator
namespace.

=head1 ATTRIBUTES

=head2 name

=head2 packages

The string name of of the validator namepart and the list of package namespaces we search for
it in.

=head2 message

The actual exception message

=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

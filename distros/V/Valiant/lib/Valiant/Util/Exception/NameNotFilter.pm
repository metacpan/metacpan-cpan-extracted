package Valiant::Util::Exception::NameNotFilter;

use Moo;
extends 'Valiant::Util::Exception';

has name => (is=>'ro', required=>1);
has packages => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  my $ns = join(', ', @{$self->packages});
  return "Filter namepart '@{[ $self->name ]}' not found in existing namespace \@INC: $ns";
}

1;

=head1 NAME

Valiant::Util::Exception::NameNotFilter - Failure to load a filter

=head1 SYNOPSIS

    throw_exception('NameNotFilter', name => $key, packages => \@filter_packages)

=head1 DESCRIPTION

Encapsulates an error when the filter namepart you use can't be found in the filter
namespace.

=head1 ATTRIBUTES

=head2 name

=head2 packages

The string name of of the filter namepart and the list of package namespaces we search for
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

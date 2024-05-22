package Treex::PML::Schema::Choice;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
no warnings 'uninitialized';
use Carp;
use Treex::PML::Schema::Constants;
use base qw( Treex::PML::Schema::Decl );

=head1 NAME

Treex::PML::Schema::Choice - implements declaration of an enumerated
type (choice).

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->is_atomic ()

Returns 1.

=item $decl->get_decl_type ()

Returns the constant PML_CHOICE_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'choice'.

=item $decl->get_values ()

Return list of possible values.

=item $decl->set_values (\@values)

Set possible values.

=item $decl->get_content_decl ()

Returns undef.

=item $decl->validate_object($object)

See C<validate_object()> in L<Treex::PML::Schema>.

=back

=cut

sub is_atomic { 1 }
sub get_decl_type { return PML_CHOICE_DECL; }
sub get_decl_type_str { return 'choice'; }
sub get_content_decl { return(undef); }
sub get_values { return @{ $_[0]->{values} }; }
sub set_values {
  my ($self,$values) = @_;
  croak(__PACKAGE__."::set_values : argument is not an array reference\n") unless ref($values) eq 'ARRAY';
  @{ $self->{values} }=@$values;
}
sub init {
  my ($self,$opts)=@_;
  $self->{-parent}{-decl} = 'choice';
}
sub post_process {
  my ($choice,$opts)=@_;
  $choice->{values} = delete $choice->{value};
}

sub validate_object {
  my ($self, $object, $opts) = @_;
  my $ok = 0;
  my $values = $self->{values};
  if ($values) {
    foreach (@{$values}) {
      if ($_ eq $object) {
	$ok = 1;
	last;
      }
    }
  }
  if (!$ok and ref($opts) and ref($opts->{log})) {
    my $path = $opts->{path};
    my $tag = $opts->{tag};
    $path.="/".$tag if $tag ne q{};
    push @{$opts->{log}}, "$path: Invalid value: '$object'";
  }
  return $ok;
}

sub serialize_get_children {
  my ($choice,$opts)=@_;
  return map ['value',$_],@{$choice->{values}};
}


1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>, L<Treex::PML::CDATA>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut


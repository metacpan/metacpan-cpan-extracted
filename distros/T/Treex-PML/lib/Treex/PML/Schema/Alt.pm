package Treex::PML::Schema::Alt;

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

Treex::PML::Schema::Alt - implements declaration of an alternative (alt).

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->get_decl_type ()

Returns the constant PML_ALT_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'alt'.

=item $decl->get_content_decl ()

Return type declaration of the list members.

=item $decl->is_flat ()

Return 1 for ``flat'' alternatives, otherwise return 0. (Flat
alternatives are not part of PML specification, but are used for
translating attribute values from C<Treex::PML::FSFormat>.)

=item $decl->is_atomic ()

Returns 0.

=back

=cut

sub is_atomic { 0 }
sub get_decl_type { return PML_ALT_DECL; }
sub get_decl_type_str { return 'alt'; }
sub is_flat { return $_[0]->{-flat} }
sub init {
  my ($self,$opts)=@_;
  $self->{-parent}{-decl} = 'alt';
}

sub validate_object {
  my ($self, $object, $opts) = @_;

  my ($path,$tag,$flags);
  my $log = [];
  if (ref($opts)) {
    $flags = $opts->{flags};
    $path = $opts->{path};
    $tag = $opts->{tag};
    $path.="/".$tag if $tag ne q{};
  }
  my $am_decl = $self->get_content_decl;
  if ($self->is_flat) {
    # flat alternative:
    if (ref($object)) {
      push @$log, "$path: flat alternative is supposed to be a string: $object";
    } else {
      my $i = 1;
      foreach my $val (split /\|/,$object) {
	$am_decl->validate_object($val, {
	  flags => $flags,
	  path=> $path,
	  tag => "[".($i++)."]",
	  log => $log,
	});
      }
    }
  } elsif (ref($object) and UNIVERSAL::DOES::does($object,'Treex::PML::Alt')) {
    for (my $i=0; $i<@$object; $i++) {
      $am_decl->validate_object($object->[$i], {
	flags => $flags,
	path=> $path,
	tag => "[".($i+1)."]",
	log => $log,
      });
    }
  } else {
    $am_decl->validate_object($object,{
      flags => $flags,
      path=>$path,
      # tag => "[1]", # TrEdNodeEdit would very much like [1] here
      log => $log});
  }
  if ($opts and ref($opts->{log})) {
    push @{$opts->{log}}, @$log;
  }
  return @$log ? 0 : 1;
}


1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>, L<Treex::PML::Alt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut


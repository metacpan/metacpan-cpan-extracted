package WebService::Cmis::Property::Boolean;

=head1 NAME

WebService::Cmis::Property::Boolean

Representation of a propertyBoolean of a cmis object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use WebService::Cmis::Property ();
our @ISA = qw(WebService::Cmis::Property);

=head1 METHODS

=over 4

=item parse($cmisValue) -> $perlValue

static helper to convert the given string into its perl representation

=cut

sub parse {
  my ($this, $value) = @_;

  return 0 unless defined $value;

  $value =~ s/^\s+//;
  $value =~ s/\s+$//;
  $value =~ s/off//gi;
  $value =~ s/no//gi;
  $value =~ s/false//gi;

  return ($value) ? 1 : 0;
}

=item unparse($perlValue) $cmisValue

converts a perl representation back to a format understood by cmis

=cut

sub unparse {
  my ($this, $value) = @_;

  #print STDERR "this=$this, value=$value, ref(this)=".ref($this)."\n";
  $value = $this->{value} if ref($this) && ! defined $value;

  return 'none' unless defined $value;
  return 'false' if $value eq '0';
  return 'true' if $value eq '1';
  return $value;
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

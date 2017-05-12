package WebService::Cmis::ACE;

=head1 NAME

WebService::Cmis::ACE

Representation of a cmis ACE object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

=head1 METHODS

=over 4

=item new()

  my $ace = new WebService::Cmis::ACE(
    principalId => 'jdoe',
    permissions => ['cmis:write'],
    direct => 'true',
  );

=cut

sub new {
  my $class = shift;

  my $this = bless({ @_ }, $class);

  unless (ref($this->{permissions})) {
    $this->{permissions} = [$this->{permissions}];
  }

  return $this;
}

=item toString()

return a string representation of this object

=cut

sub toString {
  my $this = shift;

  my $result = $this->{principalId}." is allowed to ";
  $result .= join(", ", sort @{$this->{permissions}});
  $result .= " (direct=".$this->{direct}.")";
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

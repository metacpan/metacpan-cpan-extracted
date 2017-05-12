package WebService::Cmis::AtomFeed::ObjectTypes;

=head1 NAME

WebService::Cmis::AtomFeed::ObjectTypes

=head1 SYNOPSIS

This is a Result sets representing an atom feed of CMIS ObjectTypes.

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use WebService::Cmis::AtomFeed ();
use WebService::Cmis::ObjectType ();

our @ISA = qw(WebService::Cmis::AtomFeed);

=head1 METHODS

=over 4

=item newEntry(xmlDoc) -> $object

returns a CMIS ObjectType created by parsing the given XML fragment

=cut

sub newEntry {
  my ($this, $xmlDoc) = @_;

  return unless defined $xmlDoc;
  return new WebService::Cmis::ObjectType(repository=>$this->{repository}, xmlDoc=>$xmlDoc);
}

=back

=head1 AUTHOR

Michael Daum C<< <daum@michaeldaumconsulting.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

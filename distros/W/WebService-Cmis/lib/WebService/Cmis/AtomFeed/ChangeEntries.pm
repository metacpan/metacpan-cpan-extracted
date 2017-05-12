package WebService::Cmis::AtomFeed::ChangeEntries;

=head1 NAME

WebService::Cmis::AtomFeed::ChangeEntries - a set of CMIS ChangeEntry objects

=head1 DESCRIPTION

This is a Result sets representing an atom feed of L<CMIS ChangeEntry objects|WebService::Cmis::ChangeEntry>

Parent-class: L<WebService::Cmis::AtomFeed>

=cut

use strict;
use warnings;
use WebService::Cmis::AtomFeed ();
use WebService::Cmis::ChangeEntry ();

our @ISA = qw(WebService::Cmis::AtomFeed);

=head1 METHODS

=over 4

=item newEntry(xmlDoc) -> $object

returns a ChangeEntry objct created by parsing the given XML fragment

=cut

sub newEntry {
  my ($this, $xmlDoc) = @_;

  return unless defined $xmlDoc;
  #print STDERR "### creating ChangeEntry from\n".$xmlDoc->toString(1)."\n###\n";
  return new WebService::Cmis::ChangeEntry(repository=>$this->{repository}, xmlDoc=>$xmlDoc);
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

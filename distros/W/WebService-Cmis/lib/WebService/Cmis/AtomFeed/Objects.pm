package WebService::Cmis::AtomFeed::Objects;

=head1 NAME

WebService::Cmis::AtomFeed::Objects - a set of CMIS objects

=head1 DESCRIPTION

This is a result sets representing an atom feed of L<CMIS Objects|WebService::Cmis::Object>.

Parent-class: L<WebService::Cmis::AtomFeed>

=cut

use strict;
use warnings;

use WebService::Cmis::AtomFeed ();
use WebService::Cmis::Object ();

our @ISA = qw(WebService::Cmis::AtomFeed);

=head1 METHODS

=over 4

=item newEntry(xmlDoc) -> $object

returns a CMIS Object created by parsing the given XML fragment

=cut

sub newEntry {
  my ($this, $xmlDoc) = @_;

  return unless defined $xmlDoc;
  #print STDERR "### creating Object from\n".$xmlDoc->toString(1)."\n###\n";
  return new WebService::Cmis::Object(repository=>$this->{repository}, xmlDoc=>$xmlDoc);
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

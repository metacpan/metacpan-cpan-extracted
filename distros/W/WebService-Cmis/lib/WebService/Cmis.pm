package WebService::Cmis;

use warnings;
use strict;
use v5.12.1;

=head1 NAME

WebService::Cmis - Perl interface to CMIS-compliant document management systems

=head1 SYNOPSIS

    use WebService::Cmis;

    my $client = WebService::Cmis::getClient(
      url => "http://.../alfresco/service/cmis",
    );

    $client->login(
      user => "...",
      password => "..."
    );

    my $repo = $client->getRepository;
    my $root = $client->getRootFolder;

=head1 DESCRIPTION

This library provides a CMIS client library for Perl that can be used to work with
CMIS-compliant repositories such as Alfresco, IBM FileNet, Nuxeo and others.
CMIS is an OASIS approved specification with backing by major ECM players including
those mentioned as well as Microsoft, Oracle, and SAP. 

CMIS providers must expose both Web Services and Restful AtomPub bindings.
WebService::Cmis uses the Restful AtomPub binding to communicate with the CMIS
repository. All you have to tell WebService::Cmis is the repository's service
URL and your credentials. There is nothing to install on the server side. 

See the F<http://docs.oasis-open.org/cmis/CMIS/v1.0/cs01/cmis-spec-v1.0.html>
for a full understanding of what CMIS is.

=head1 METHODS

=over 4

=cut

use Error qw(:try);
use Exporter qw(import);

use Carp;
$Carp::Verbose = 1;

our $VERSION = '0.09';

our @ISA = qw(Exporter);

our @_namespaces = qw(ATOM_NS APP_NS CMISRA_NS CMIS_NS OPENSEARCH_NS);

our @_contenttypes = qw(ATOM_XML_TYPE ATOM_XML_ENTRY_TYPE ATOM_XML_ENTRY_TYPE_P
  ATOM_XML_FEED_TYPE ATOM_XML_FEED_TYPE_P CMIS_TREE_TYPE CMIS_TREE_TYPE_P
  CMIS_QUERY_TYPE CMIS_ACL_TYPE);

our @_relations = qw(ACL_REL ALLOWABLEACTIONS_REL ALTERNATE_REL CHANGE_LOG_REL DESCRIBEDBY_REL
  DOWN_REL EDIT_MEDIA_REL EDIT_REL FIRST_REL FOLDER_TREE_REL LAST_REL NEXT_REL
  POLICIES_REL PREV_REL RELATIONSHIPS_REL ROOT_DESCENDANTS_REL SELF_REL
  SERVICE_REL TYPE_DESCENDANTS_REL UP_REL VERSION_HISTORY_REL VIA_REL);

our @_collections = qw(QUERY_COLL TYPES_COLL CHECKED_OUT_COLL UNFILED_COLL
  ROOT_COLL);

our @_utils = qw(_writeCmisDebug _urlEncode);

our @EXPORT_OK = (@_namespaces, @_contenttypes, @_relations, @_collections, @_utils);
our %EXPORT_TAGS = (
  namespaces => \@_namespaces,
  contenttypes => \@_contenttypes,
  relations => \@_relations,
  collections => \@_collections,
  utils => \@_utils,
);

# Namespaces
use constant ATOM_NS => 'http://www.w3.org/2005/Atom';
use constant APP_NS => 'http://www.w3.org/2007/app';
use constant CMISRA_NS => 'http://docs.oasis-open.org/ns/cmis/restatom/200908/';
use constant CMIS_NS => 'http://docs.oasis-open.org/ns/cmis/core/200908/';
use constant OPENSEARCH_NS => 'http://a9.com/-/spec/opensearch/1.1/';

# Content types
# Not all of these patterns have variability, but some do. It seemed cleaner
# just to treat them all like patterns to simplify the matching logic
use constant ATOM_XML_TYPE => 'application/atom+xml';
use constant ATOM_XML_ENTRY_TYPE => 'application/atom+xml;type=entry';
use constant ATOM_XML_ENTRY_TYPE_P => qr/^application\/atom\+xml.*type.*entry/;
use constant ATOM_XML_FEED_TYPE => 'application/atom+xml;type=feed';
use constant ATOM_XML_FEED_TYPE_P => qr/^application\/atom\+xml.*type.*feed/;
use constant CMIS_TREE_TYPE => 'application/cmistree+xml';
use constant CMIS_TREE_TYPE_P => qr/^application\/cmistree\+xml/;
use constant CMIS_QUERY_TYPE => 'application/cmisquery+xml';
use constant CMIS_ACL_TYPE => 'application/cmisacl+xml';

# Standard rels
use constant ALTERNATE_REL => 'alternate';
use constant DESCRIBEDBY_REL => 'describedby';
use constant DOWN_REL => 'down';
use constant EDIT_MEDIA_REL => 'edit-media';
use constant EDIT_REL => 'edit';
use constant ENCLOSURE_REL => 'enclosure';
use constant FIRST_REL => 'first';
use constant LAST_REL => 'last';
use constant NEXT_REL => 'next';
use constant PREV_REL => 'previous';
use constant SELF_REL => 'self';
use constant SERVICE_REL => 'service';
use constant UP_REL => 'up';
use constant VERSION_HISTORY_REL => 'version-history';
use constant VIA_REL => 'via';

use constant ACL_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/acl';
use constant ALLOWABLEACTIONS_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/allowableactions';
use constant CHANGE_LOG_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/changes';
use constant FOLDER_TREE_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/foldertree';
use constant POLICIES_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/policies';
use constant RELATIONSHIPS_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/relationships';
use constant ROOT_DESCENDANTS_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/rootdescendants';
use constant TYPE_DESCENDANTS_REL => 'http://docs.oasis-open.org/ns/cmis/link/200908/typedescendants';

# Collection types
use constant QUERY_COLL => 'query';
use constant TYPES_COLL => 'types';
use constant CHECKED_OUT_COLL => 'checkedout';
use constant UNFILED_COLL => 'unfiled';
use constant ROOT_COLL => 'root';

=item getClient(%params) -> L<WebService::Cmis::Client>

Static method to create a cmis client. The client serves as an agent to fulfill
all operations while contacting the document management system. 

While passing on all provided parameters to the real client constructor, the C<impl>
parameter is used to point to the class that actually implements the client, defaulting
to L<WebService::Cmis::Client::BasicAuthClient>. 

=cut

sub getClient {
  require WebService::Cmis::Client;
  return new WebService::Cmis::Client(@_);
}

# static utility to write debug output to STDERR. Set the CMIS_DEBUG environment variable to switch on some additional debug messages.
sub _writeCmisDebug {
  print STDERR "WebService::Cmis - $_[0]\n" if $ENV{CMIS_DEBUG};
}

#encodes a string to be used as a parameter in an url
sub _urlEncode {
  my $text = shift;

  $text =~ s/([^0-9a-zA-Z-_.:~!*'\/])/'%'.sprintf('%02x',ord($1))/ge;

  return $text;
}


=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-cmis at rt.cpan.org>, or through
the web interface at F<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Cmis>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Cmis

You can also look for information at:

=over 4

=item * Github

F<https://github.com/MichaelDaum/cmis-perl>

=item * Meta CPAN

F<https://metacpan.org/module/WebService::Cmis>

=item * AnnoCPAN: Annotated CPAN documentation

F<http://annocpan.org/dist/WebService-Cmis>

=item * CPAN Ratings

F<http://cpanratings.perl.org/d/WebService-Cmis>

=back

=head1 ACKNOWLEDGEMENTS

This implementation is inspired by the Pyhton implementation
F<http://code.google.com/p/cmislib> written by Jeff Potts.

=head1 AUTHOR

Michael Daum C<< <daum@michaeldaumconsulting.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

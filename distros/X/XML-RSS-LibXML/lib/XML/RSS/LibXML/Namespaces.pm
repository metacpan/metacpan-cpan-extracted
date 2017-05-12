# $Id$
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::Namespaces;
use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
my %KnownNamespaces;
my %RevKnownNamespaces;

BEGIN
{
    %KnownNamespaces = (
        rdf     => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        dc      => "http://purl.org/dc/elements/1.1/",
        syn     => "http://purl.org/rss/1.0/modules/syndication/",
        admin   => "http://webns.net/mvcb/",
        content => "http://purl.org/rss/1.0/modules/content/",
        cc      => "http://web.resource.org/cc/",
        taxo    => "http://purl.org/rss/1.0/modules/taxonomy/",
        rss20   => "http://backend.userland.com/rss2", # really a dummy
        rss10   => "http://purl.org/rss/1.0/",
        rss09   => "http://my.netscape.com/rdf/simple/0.9/",
    );
    %RevKnownNamespaces = map { ($KnownNamespaces{$_} => $_) } keys %KnownNamespaces;

    my %constants;
    while (my ($prefix, $ns) = each %KnownNamespaces) {
        $constants{'NS_' . uc($prefix)} = $ns;
    }

    require constant;
    constant->import(\%constants);

    @EXPORT_OK = keys %constants;
}

sub lookup_prefix { $RevKnownNamespaces{$_[0]} }
sub lookup_uri    { $KnownNamespaces{$_[0]} }

1;

__END__

=head1 NAME

XML::RSS::LibXML::Namespaces - Utility Catalog For Known Namespacee

=head1 SYNOPSIS

  use XML::RSS::LibXML::Namespaces qw(NS_RSS10);

  print NS_RSS10, "\n";
  XML::RSS::LibXML::Namespaces::lookup_uri('rdf');

=head1 FUNCTIONS

=head2 lookup_uri($prefix)

=head2 lookup_prefix($uri)

=cut

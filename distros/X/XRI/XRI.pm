# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>

# TODO: Insert logic about choosing an authority from the current descriptor
# TODO: Logic about whether to look at the mapping, etc.

require 5.6.0;

package XRI;
our $VERSION = '0.2.4';

use strict;

use XRI::Parse qw( GCS_CHARS );
use XRI::Descriptor;

use XML::Smart;
use URI::Escape;
use LWP::Simple;

use Log::Agent;
logconfig(-prefix => $0);

# this gets changed during make install
my $ROOTS = '/etc/xriroots.xml';

my $xrins = 'xri:$r.s/XRIDescriptor';

our %globals = ();
our %private = ();

sub new {
    my $self = shift;
    my $xri = shift;
    my $this = { descriptor=>undef,
                 descriptorXML=>undef,
                 localAccessURL=>undef,
                 xri=>$xri };
    bless $this, $self;
}

# Converts XRIs with DNS-based Authorities to HTTP URIs and stores the localaccessurl
#
# FIXME: more escaping needed - also need to check for absoluteness
#
sub convertToHTTP {
    my $self = shift;

    $self->{localAccessURL} = "http:" .
        (( $self->{xri} =~ /^xri:(.*)$/ ) ? $1 : $self->{xri} );
}

sub resolveToAuthorityXML {
    my $self = shift;
    my ($service, $type) = @_;
    my $XRI = new XRI::Parse $self->{xri}; # FIXME: created two XRI objects...
    my ($authRef, $descriptor, @authURIs);
    my $descXML = undef;

    # get the authority and local access parts
    #
    my $authLocal = $XRI->splitAuthLocal;

    # no authority part -> relative-path
    #
    if ( ! defined $XRI->{authority} ) {
        die "RelativePathNotXRIAuthority for passed service or type\n"
            if ($service || $type);
        $self->{localAccessURL} = $authLocal;
        logtrc 'notice', "No XRI Authority - relative-path resolved";
        return;
    }
    # if the first segment is '//' convert to HTTP and return
    #
    if ( $XRI->{authority} eq '//') {
        die "URIAuthorityNotXRIAuthority for passed service or type\n"
            if ($service || $type);
        $self->convertToHTTP;
        logtrc 'notice', "XRI Authority is DNS Based - XRI converted to HTTP";
        return;
    }
    logtrc 'notice', "Extracted root identifier of %s", $XRI->{authority};

    # load the roots (global roots could be "precomputed")
    # FIXME: need mechanism to incrementally add to private roots
    #
    readRoots() if ! scalar %globals;

    ($authRef, $self->{localAccessURL}) = @$authLocal;
    my $subseg = shift @$authRef;

    # get the root authority
    # HACK: we assume there's only one root AuthorityURI
    # HACK: we randomly choose the first XRIAuthority URI
    #
    my $url = isGCS( $subseg ) ? $globals{ $subseg } : $private{ $subseg };
    if (! defined $url) {
        die "UnknownAuthority: $subseg\n";
    }
    while ( $subseg = shift @$authRef ) {       # divider
        $subseg .= shift @$authRef;             # segment
        logtrc 'notice', "Resolving authority subsegment %s", $subseg;

        $url .= '/' unless $url =~ m|/$|;
        $url .= uri_escape($subseg); # FIXME turn spaces into '+', etc...

        logtrc 'notice', "Contacting Naming Authority URL %s", $url;
        $descXML = get $url; # Quick and dirty - should catch exceptions and 404s
        if ( ! defined $descXML ) {
            die "NoDescriptorXML for $url\n"; # FIXME
        }
        logtrc 'notice', "Descriptor for %s is\n%s", $subseg, $descXML;

        $descriptor = XRI::Descriptor->new($descXML);

        if (! defined $descriptor) {
            die "MalformedXRIDescriptor for $url\n";
        }
        @authURIs = @{$descriptor->getXRIAuthorityURIs};

        # is it a bug if there is no XRIAuthority URI in a delegated segment?
        # we'll accept it for now, and expect to use LocalAccess from here...
        #
        last unless scalar @authURIs;   # done if no XRI Authority URU

        $url = $authURIs[0];            # HACK: randomly choose the first URI
    }
    $self->{descriptor} = $descriptor;
    $self->{descriptorXML} = $descXML;
}

# Performs basic Authority Resolution
# Assumes we are not using a DNS-based authority 
# Sets the descriptor to the XRI
#
sub resolveToLocalAccessURI {
    my $self = shift;
    my ($service, $type) = @_;
    $self->resolveToAuthorityXML($service, $type);

    return unless $self->{descriptor};

    my $local = $self->{localAccessURL};
    my @localAccessElem = $self->{descriptor}->getLocalAccess($service, $type);

    if ( scalar @localAccessElem ) {
        
        # HACK: randomly choose the first LocalAccess element and the first URI within it
        #
        my $desLocalAccess = ${$localAccessElem[0]->uris}[0];
        logtrc( 'notice',
                "Constructed local access URL from base local access url %s and local XRI part %s",
                $desLocalAccess, $local );
        $desLocalAccess .= '/' if $local && $desLocalAccess !~ m|\/$|;
        logtrc 'notice', "Local access descriptor is %s", $desLocalAccess;
        $self->{localAccessURL} = $desLocalAccess . XRI::Parse->new($local)->escapeURI;
    }
    else {
        #No local access URL! Probably should raise an excepetion
        $self->{localAccessURL} = undef;
        die "NoLocalAccessFound for XRI $self->{xri}\n";
    }
}

sub doGet {
    my $self = shift;

    $self->resolveToLocalAccessURI
        unless defined $self->{localAccessURL};
    return get( $self->{localAccessURL} );      # returns the document
}

sub getGetURL {
    my $self = shift;

    $self->resolveToLocalAccessURI
        unless defined $self->{localAccessURL};
    return $self->{localAccessURL};
}

sub isGCS {
    my $char = shift;

    return grep { $_ eq $char } @XRI::Parse::GCS_CHARS;
}

# Read XRI roots file
# TODO: implement mechanism to add private roots
#
sub readRoots {
    my $roots = shift;

    $roots = $ROOTS unless defined $roots;

    die "XRIRootsNotFound: Can't find $roots\n" unless -r $roots;

    my $XML = XML::Smart->new($roots);

    $XML = $XML->cut_root();

    foreach my $descriptor ( @{$XML->{XRIDescriptor}} ) { # missing: ('xmlns','eq',$xrins)
        my $resolved = $descriptor->{Resolved};
        my $authority = $descriptor->{XRIAuthority}{URI};
        if ( isGCS( $resolved )) {
            logtrc 'notice', "Resolved Global %s to %s", $resolved, $authority;
            $XRI::globals{$resolved} = $authority;
        }
        else {
            logtrc 'notice', "Resolved Private %s to %s", $resolved, $authority;
            $XRI::private{$resolved} = $authority;
        }
    }
}

1;
__END__
=head1 NAME

XRI - Resolver for eXtensible Resource Identifiers

=head1 SYNOPSIS

    use XRI;
    my $XRI = XRI->new($xri);

    $XRI->resolveToAuthorityXML;
    print $XRI->{descriptorXML};

    $XRI->resolveToLocalAccessURI;
    $XRI->resolveToLocalAccessURI(service, type);
    print $XRI->{localAccessURL};

    print $XRI->doGet;

=head1 ABSTRACT

Resolve an XRI to a LocalAccess URL or an XRIAuthority Descriptor

=head1 DESCRIPTION

The XRI Resolver Library resolves an XRI to a LocalAccess URL or an
XRIAuthority Descriptor.  It can also be used to actually fetch the
data at the LocalAccess URL.

=head1 FATAL ERROR STRINGS

These strings are returned via die() so trap them by running library
calls within an eval{} block  $@ will be set to the error code, if any.

    RelativePathNotXRIAuthority for passed service or type
    URIAuthorityNotXRIAuthority for passed service or type
    UnknownAuthority: $subseg
    NoDescriptorXML for $url
    MalformedXRIDescriptor for $url
    NoLocalAccessFound for XRI $self->{xri}

=head1 BUGS

=over 4

=item *

Doesn't handle multiple LocalAccess URIs

=item *

Doesn't parse cross references properly

=back

=head1 SEE ALSO

XRI OASIS TC:
    http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=xri

XRI Specification:
    http://www.oasis-open.org/committees/download.php/5109/xri-syntax-resolution-1.0-cd.pdf

Mailing list:
    http://idcommons.net/cgi-bin/mailman/listinfo/xrixdi

Wiki:
    http://xrixdi.idcommons.net/

=head1 AUTHOR

Fen Labalme, E<lt>fen@idcommons.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Identity Commons

See LICENSE.

=cut

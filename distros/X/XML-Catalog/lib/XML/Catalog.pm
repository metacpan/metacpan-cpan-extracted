package XML::Catalog;

use strict;
use warnings;

use XML::Parser;
use LWP::Simple;
use URI::URL;
use Text::ParseWords;

## no critic
our $VERSION = "1.03";
$VERSION = eval $VERSION;
## use critic

#####################################################################
# Class variables (private)
#####################################################################

# hash of catalog objects indexed by URL (to prevent loops in construction)
my %catobjs;

# hash of catalog objects visited in current search, indexed by
# stringified reference (to prevent loops in search)
use vars qw/%visited/;

#####################################################################
# Constructor
#####################################################################

sub new {
    my $class = shift;
    my $url   = shift || die "No catalog specified";
    my $cat   = build( $class, $url ) or return;
    $cat->add(@_);
    return $cat;
}

#####################################################################
# Public methods
#####################################################################

sub add {
    my $self = shift;
    foreach my $url (@_) {
        my $cat = build( $self, $url );
        $self->add_extend_object( $cat, 'chain' ) if defined $cat;
    }
}

sub resolve_public {
    my ( $self, $pubid ) = @_;
    %visited = ();

    # try without delegation
    my $rm = $self->_resolve_public( $pubid, 0 );
    unless ($rm) {

        # try with delegation
        %visited = ();
        $rm = $self->_resolve_public( $pubid, 1 );
    }
    return $self->remap_system($rm) if defined $rm;
    return;
}

sub remap_system {
    my ( $self, $sysid ) = @_;
    %visited = ();
    my $rm = $self->_remap_system($sysid);
    return ( defined($rm) ? $rm : $sysid );
}

sub get_handler {
    my ( $catalog, $parser ) = @_;
    my ( $t, $orig_handler ) = $parser->setHandlers( ExternEnt => 0 );
    return sub {
        my ( $expat, $base, $sysid, $pubid ) = @_;
        if ($pubid) {
            my $t = $catalog->resolve_public($pubid);
            $sysid = $t if $t;
        }
        $sysid = $catalog->remap_system($sysid);
        $orig_handler->( $expat, $base, $sysid, $pubid );
        }
}

#####################################################################
# Private methods and subs
#####################################################################

# create new catalog object

sub build {
    my ( $c, $url ) = @_;
    return $catobjs{$url} if defined $catobjs{$url};
    my $class = ref($c) || $c;
    my $self = {
        url      => $url,    #needed?
        base     => $url,
        map      => {},
        remap    => {},
        delegate => {},
        extend   => [],
        chain    => []
    };
    bless( $self, $class );
    $catobjs{$url} = $self;
    $self->parse;
    return $self;
}

# add another catalog object as extension to ours

sub add_extend_object {
    my ( $self, $cat, $group ) = @_;
    foreach my $t ( @{ $self->{$group} } ) {
        return if $t == $cat;
    }
    push @{ $self->{$group} }, $cat;
}

# translate public identifier with or without delegation, checking for loops
sub _resolve_public {
    my ( $self, $pubid, $allowdeleg ) = @_;
    return if $visited{$self};
    $visited{$self} = 1;
    if ($allowdeleg) {
        local %visited;
        foreach my $deleg ( keys %{ $self->{delegate} } ) {
            if ( index( $pubid, $deleg ) == 0 ) {
                my $rm = $self->{delegate}{$deleg}->resolve_public($pubid);
                return $rm if defined $rm;
            }
        }
    }
    else {
        return $self->{map}{$pubid} if defined $self->{map}{$pubid};
    }

    # no local match, try chained and extend entries
    foreach my $group (qw/chain extend/) {
        foreach my $cat ( @{ $self->{$group} } ) {
            my $rm = $cat->_resolve_public( $pubid, $allowdeleg );
            return $rm if defined $rm;
        }
    }
    return;
}

# translate system identifier, checking for loops
sub _remap_system {
    my ( $self, $sysid ) = @_;
    return if $visited{$self};
    return $self->{remap}{$sysid} if defined $self->{remap}{$sysid};
    $visited{$self} = 1;
    foreach my $group (qw/chain extend/) {
        foreach my $cat ( @{ $self->{$group} } ) {
            my $rm = $cat->_remap_system($sysid);
            return $rm if defined $rm;
        }
    }
    return;
}

sub parse {
    my $self = shift;
    my $u    = new URI::URL( $self->{url} );
    $u->scheme('file') unless $u->scheme();
    my $url = $u->as_string();
    my $ct  = LWP::Simple::get($url);
    die "Unable to retrieve URL: [$url]" unless defined $ct;
    $self->parse_SOCAT($ct) unless $self->parse_XML($ct);
}

sub fix_base {
    my ( $self, $url ) = @_;
    my $u = new URI::URL( $url, $self->{base} );
    return $u->abs->as_string();
}

sub add_map {
    my ( $self, $pubid, $href ) = @_;
    $self->{map}{$pubid} = $self->fix_base($href);
}

sub add_remap {
    my ( $self, $sysid, $href ) = @_;
    $self->{remap}{$sysid} = $self->fix_base($href);
}

sub add_delegate {
    my ( $self, $pubid, $href ) = @_;
    my $cat = build( $self, $self->fix_base($href) );
    $self->{delegate}{$pubid} = $cat if defined $cat;
}

sub add_extend {
    my ( $self, $href ) = @_;
    $href = $self->fix_base($href);
    my $cat = build( $self, $href );
    $self->add_extend_object( $cat, 'extend' ) if defined $cat;
}

sub set_base {
    my ( $self, $href ) = @_;
    $self->{base} = $self->fix_base($href);
}

sub parse_SOCAT {
    my ( $token, $sysid, $pubid, $href );
    my ( $self, $ct ) = @_;

    #backslashes are allowed; change them to forward slashes
    $ct =~ s#\\#/#g;

    #strip comments
    $ct =~ s/((['"]).*\2|.*)--.*?--/$1/g;
    my @tokens = quotewords( '\s+', 0, $ct );
    while ( defined( $token = shift @tokens ) ) {
        if ( uc $token eq 'PUBLIC' ) {
            defined( $pubid = shift @tokens ) or return 0;
            defined( $href  = shift @tokens ) or return 0;
            $self->add_map( $pubid, $href );
        }
        elsif ( uc $token eq 'SYSTEM' ) {
            defined( $sysid = shift @tokens ) or return 0;
            defined( $href  = shift @tokens ) or return 0;
            $self->add_remap( $sysid, $href );
        }
        elsif ( uc $token eq 'DELEGATE' ) {
            defined( $pubid = shift @tokens ) or return 0;
            defined( $href  = shift @tokens ) or return 0;
            $self->add_delegate( $pubid, $href );
        }
        elsif ( uc $token eq 'CATALOG' ) {
            defined( $href = shift @tokens ) or return 0;
            $self->add_extend($href);
        }
        elsif ( uc $token eq 'BASE' ) {
            defined( $href = shift @tokens ) or return 0;
            $self->set_base($href);
        }
        else {
            next;
        }
    }
    return 1;
}

sub parse_XML {
    my ( $self, $ct ) = @_;
    my $p = new XML::Parser( Style => 'Subs', Pkg => 'XML::Catalog::XML' );
    $p->{XMLCatalog} = $self;
    eval { $p->parse($ct) };
    return ( $@ ? 0 : 1 );
}

package XML::Catalog::XML;

## no critic
our $VERSION = "1.02";
$VERSION = eval $VERSION;
## use critic

sub Map {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_map( $attrs{PublicId}, $attrs{HRef} );
}

sub Remap {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_remap( $attrs{SystemId}, $attrs{HRef} );
}

sub Delegate {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_delegate( $attrs{PublicId}, $attrs{HRef} );
}

sub Extend {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_extend( $attrs{HRef} );
}

sub Base {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->set_base( $attrs{HRef} );
}

# Oasis XML catalog support
sub catalog {
}

sub rewriteURI {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_delegate( $attrs{uriStartString}, $attrs{rewritePrefix} );
}

sub rewriteSystem {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_delegate( $attrs{systemIdStartString}, $attrs{rewritePrefix} );
}

sub public {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_map( $attrs{publicId}, $attrs{uri} );
}

sub delegatePublic {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_extend( $attrs{catalog} );
}

sub delegateSystem {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_extend( $attrs{catalog} );
}

sub delegateURI {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_extend( $attrs{catalog} );
}

sub nextCatalog {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_extend( $attrs{catalog} );
}

sub system {
    my ( $p, $elem, %attrs ) = @_;
    my $self = $p->{XMLCatalog};
    $self->add_delegate( $attrs{systemId}, $attrs{uri} );
}

1;
__END__

=head1 NAME

XML::Catalog - Resolve public identifiers and remap system identifiers

=head1 SYNOPSIS

  use XML::Catalog;
  my $catalog=XML::Catalog->new('/xml/catalog.cat');
  $catalog->add('http://www.w3.org/xcatalog/mastercat.xml');
  my $sysid=$catalog->resolve_public('-//John Cowan//LOC Diacritics');
  my $newsysid=$catalog->remap_system('http://www.w3.org');
  $parser->setHandlers(ExternEnt=>$catalog->get_handler($parser));

=head2 Oasis Example

  $ perl -e 'use XML::Catalog; \
  $pubid = q|-//OASIS//DTD DocBook XML V4.5//EN|; \
  my $catalog=XML::Catalog->new("/etc/xml/catalog"); \
  print $catalog->resolve_public($pubid), "\n";'

  file:///usr/share/sgml/docbook/xml-dtd-4.5-1.0-51.el6/docbookx.dtd 

=head1 DESCRIPTION

This module implements draft 0.4 of John Cowan's XML Catalog (formerly 
known as XCatalog) proposal 
(<http://www.ccil.org/~cowan/XML/XCatalog.html>).  Catalogs may be written 
in either SOCAT or XML syntax (see the proposal for syntax details); 
XML::Catalog will assume SOCAT syntax if the catalog is not in well-formed 
XML syntax.

This module, as of 1.0.0, also supports Oasis XML catalogs.

=head1 CONSTRUCTOR

=over 4

=item new(URL [,URL]*)

Read the catalog identified by URL and return a catalog object 
implementing it.  If more than one URL is given, chain the additional 
catalogs as extensions to the catalog (they will be searched before 
catalogs specified by EXTEND entries).

All URLs must be absolute.  A URL with no protocol is treated as a 
filename.

=back

=head1 METHODS

=over 4

=item add(URL [,URL]*)

Chain the catalogs identified by the URL(s) to the current catalog.

=item resolve_public(PUBID)

Translate the public identifier PUBID to a system identifier.  Returns 
undef if the identifier could not be translated.

=item remap_system(SYSID)

Remap the system identifier SYSID as specified by the catalog.  Returns 
SYSID unchanged if no remapping was found.

=item get_handler(PARSER)

Returns a coderef to a resolver suitable for use as the ExternEnt handler 
for an XML::Parser object.  The resolver will first attempt to resolve a 
public identifier if supplied, and then attempt to remap the resulting 
system identifier (or the original system identifier if no public 
identifier was supplied).  It will then call the original ExternEnt handler 
associated with the parser object.  PARSER is the parser object; it is 
needed as an argument in order to obtain the original handler.

=item add_delegate($pubid,  $href)

TBD

=item add_extend($href)

TBD

=item add_extend_object($cat, $group )

TBD

=item add_map($pubid,  $href)

TBD

=item add_remap($sysid,  $href)

TBD

=item build($url)

create new catalog object

=item fix_base($url)

TBD

=item parse

TBD

=item parse_SOCAT($ct)

TBD

=item parse_XML($ct)

TBD

=item set_base($href)

TBD

=back

=head1 BUGS / TODO

Searching of chained catalogs is not purely depth-first (EXTEND items in a 
chained catalog will be searched before EXTEND items in the original 
catalog.

Error checking leaves much to be desired.

=head1 AUTHOR

Current Author:

	Jeff Fearn E<lt>jfearn@cpan.orgE<gt>.

Former Authors:

	Eric Bohlman E<lt>ebohlman@netcom.comE<gt>.

=head1 COPYRIGHT

Copyright (c) 1999-2000 Eric Bohlman.  All rights reserved.
Copyright (c) 2013 Jeff Fearn. All rights reserved.

This program is free software; you can use/modify/redistribute it under the 
same terms as Perl itself.

=cut

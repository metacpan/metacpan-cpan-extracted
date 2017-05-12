# $Id: Base.pm,v 1.4 2004/12/28 21:49:53 asc Exp $
use strict;

package XML::Generator::vCard::Base;
use base qw (XML::SAX::Base);

$XML::Generator::vCard::Base::VERSION = '1.0';

=head1 NAME

XML::Generator::vCard::Base - base class for generating SAX2 events for vCard data

=head1 SYNOPSIS

 # Ceci n'est pas une boite noire.
 
 package XML::Generator::vCard::FooBar;
 use base qw (XML::Generator::vCard::Base);

=head1 DESCRIPTION

Base class for generating SAX2 events for vCard data

=cut

use File::Spec;
use URI::Escape;
use URI::Split;
use Encode;
use Memoize;

use constant NS => {"vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
		    "rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		    "rdfs"  => "http://www.w3.org/2000/01/rdf-schema#",
		    "geo"   => "http://www.w3.org/2003/01/geo/wgs84_pos#",
		    "foaf"  => "http://xmlns.com/foaf/0.1/"};

sub import {
    my $pkg = shift;

    &memoize("_prepare_qname","prepare_uri","_prepare_path");
    return 1;
}

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->prepare_uri($uri)

Encodes (decoding first, where necessary) a URI's path as UTF-8.

Returns a string.

=cut

# this is actually only used by ::RDF at the moment
# but it seems like a good candidate for inclusion
# here

sub prepare_uri {
    my $pkg = shift;
    return &_prepare_uri(@_);
}

# memoized

sub _prepare_uri {
    my $uri = shift;

    my ($scheme, $auth, $path, $query, $frag) = URI::Split::uri_split($uri);
    
    $path = File::Spec->catdir(map { &_prepare_path($_) } split("/",$path));
    return URI::Split::uri_join($scheme, $auth, $path, $query, $frag);
}

# memoized

sub _prepare_path {
    my $str = shift;
    
    $str =~ s/(?:%([a-fA-F0-9]{2})%([a-fA-F0-9]{2}))/pack("U0U*",hex($1),hex($2))/eg;
    $str = decode_utf8($str);
    return URI::Escape::uri_escape_utf8($str);
}

=head2 __PACKAGE__->prepare_qname($qname)

Utility method to return a hash reference suitable for passing 
a XML QName to I<XML::SAX>.

Returns a hash reference.

=cut

sub prepare_qname {
    my $pkg = shift;
    return &_prepare_qname(@_);
}

# memoized

sub _prepare_qname {
    my $qname  = shift;

    $qname =~ /^([^:]+):(.*)$/;

    my $prefix = $1;
    my $name   = $2;

    my $ns     = NS->{ $prefix };
	
    return {Name         => $qname,
	    LocalName    => $name,
	    Prefix       => $prefix,
	    NamespaceURI => $ns};
}

=head2 __PACKAGE__->prepare_attrs(\%attrs)

Utility method to return a hash reference suitable for passing 
XML attributes to I<XML::SAX>.

Returns a hash reference.

=cut

sub prepare_attrs {
    my $pkg   = shift;
    my $attrs = shift;

    foreach my $uri (keys %$attrs) {
	
	my ($key, $data) = &_prepare_attr($attrs->{$uri});
	
	$attrs->{ $key } = $data;
	delete $attrs->{$uri};
    }

    return {Attributes => $attrs};
}

sub _prepare_attr {
    my $attr = shift;

    my $data       = &_prepare_qname($attr->{Name});
    $data->{Value} = $attr->{Value};

    my $fq_uri = sprintf("{%s}%s",
			 $data->{NamespaceURI},
			 $data->{LocalName});

    return ($fq_uri,$data);
}

=head2 __PACKAGE__->namespaces()

Returns a hash reference of commonly used prefixes
and namespace URIs.

=cut

sub namespaces {
    return NS;
}

# deprecated

sub _namespaces {
    return $_[0]->namespaces();
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2004/12/28 21:49:53 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<XML::SAX>

=head1 LICENSE

Copyright (c) Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it 
under the same terms as Perl itself.

=cut

return 1;

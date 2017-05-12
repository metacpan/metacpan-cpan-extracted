package W3C::SOAP::Utils;

# Created on: 2012-06-01 12:15:15
# Create by:  dev
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use W3C::SOAP::WSDL::Utils;
use W3C::SOAP::WSDL::Meta::Method;
use URI;

Moose::Exporter->setup_import_methods(
    as_is     => [qw/split_ns xml_error normalise_ns cmp_ns ns2module/],
    with_meta => ['operation'],
);

our $VERSION = 0.14;

sub split_ns {
    my ($tag) = @_;
    confess "No XML tag passed to split!\n" unless defined $tag;
    my ($ns, $name) = split /:/xms, $tag, 2;
    return $name ? ($ns, $name) : ('', $ns);
}

sub normalise_ns {
    my ($ns) = @_;

    my $uri = URI->new($ns);

    if ( $uri->can('host') ) {
        $uri->host(lc $uri->host);
    }

    return "$uri";
}

sub ns2module {
    my ($ns) = @_;

    my $uri = URI->new($ns);

    # URI's which have a host an a path are converted Java style name spacing
    if ( $uri->can('host') ) {
        my $module
            = join '::',
            reverse map { ucfirst $_}
            map { lc $_ }
            map { s/\W/_/gxms; $_ } ## no critic
            split /[.]/xms, $uri->host;
        $module .= join '::',
            map { s/\W/_/gxms; $_ } ## no critic
            split m{/}xms, $uri->path;
        return $module;
    }

    # other URI's are just made safe as a perl module name.
    $ns =~ s{://}{::}xms;
    $ns =~ s{([^:]:)([^:])}{$1:$2}gxms;
    $ns =~ s{[^\w:]+}{_}gxms;

    return $ns;
}

sub cmp_ns {
    my ($ns1, $ns2) = @_;

    return normalise_ns($ns1) eq normalise_ns($ns2);
}

sub xml_error {
    my ($node) = @_;
    my @lines  = split /\r?\n/xms, $node->toString;
    my $indent = '';
    if ( $lines[-1] =~ /^(\s+)/xms ) {
        $indent = $1;
    }
    my $error = $indent . $node->toString."\n at ";
    $error .= "line - ".$node->line_number.' ' if $node->line_number;
    $error .= "path - ".$node->nodePath;

    return $error;
}

1;

__END__

=head1 NAME

W3C::SOAP::Utils - Utility functions to be used with C<W3C::SOAP> modules

=head1 VERSION

This documentation refers to W3C::SOAP::Utils version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::Utils;

   # splits tags with an optional XML namespace prefix
   my ($namespace, $tag) = split_ns('xs:thing');
   # $namespace = xs
   # $tag = thing

=head1 DESCRIPTION

Utility Functions

=head1 SUBROUTINES

=over 4

=item C<split_ns ($name)>

Splits an XML tag's namespace from the tag name

=item C<normalise_ns ($ns)>

Creates a normalized XML name space string (ie lower cases the host part of
the name space)

=item C<ns2module ($ns)>

Takes the XML namespace C<$ns> and coverts it to a module name, if it is a
"normal" URI the module name is got by reversing the order of the domain
parts and joining that with any directory parts (setting default Perl module
capitalization along the way)

 eg http://www.example.com/some/path => Com::Example::Www::Some::Path

If the URI doesn't have a host part then URI is split on the non-word
characters and similarly rejoined

 eg uri:thing.other/unknown => Uri::Thing::Other::Unknown

=item C<cmp_ns ($ns1, $ns2)>

Compare two namespaces (with normalized host parts lower cased)

=item C<xml_error ($xml_node)>

Pretty format the C<$xml_node> for an error message

=back

=head1 MOOSE HELPERS

=over 4

=item C<operation ($name, %optisns)>

See L<W3C::SOAP::WSDL::Utils> for details using it from this module is deprecated

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills - (ivan.wills@gmail.com)

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

package W3C::SOAP::WADL::Element;

# Created on: 2013-04-27 21:58:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use Carp qw/carp croak cluck confess longmess/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.007');

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    if ( blessed $args
        && ( $args->isa('HTTP::Request') || $args->isa('HTTP::Response') )
    ) {
        my $http = $args;
        my $uri  = $http->can('uri') ? $http->uri : undef;
        $args = {};

        my %map = $class->_map_fields;

        # process headers
        for my $header ( $http->header_field_names ) {
            if ( $map{$header} ) {
                $args->{ $map{$header} } = $http->header($header);
            }
            elsif ( $map{lc $header} ) {
                $args->{ $map{lc $header} } = $http->header($header);
            }
            else {
                $args->{$header} = $http->header($header);
            }
        }

        # process URI params
        if ( $uri ) {
            my @query = $uri->query_form;
            while ( my $key = shift @query ) {
                my $value = shift @query;
                # TODO make work with multiple values
                $args->{ $map{$key} } = $value;
            }
        }
    }

    return $class->$orig($args);
};

sub _map_fields {
    my ($self) = @_;
    my $meta = $self->meta;

    my @parent_nodes;
    my @supers = $meta->superclasses;
    for my $super (@supers) {
        push @parent_nodes, $super->_map_fields
            if $super ne __PACKAGE__ && UNIVERSAL::can($super, '_map_fields');
    }

    return @parent_nodes, map {
            $meta->get_attribute($_)->real_name => $_,
            lc $meta->get_attribute($_)->real_name => $_
        }
        grep {
            $meta->get_attribute($_)->does('W3C::SOAP::WADL::Traits')
        }
        $meta->get_attribute_list;
}

sub _get_headers {
    my ($self) = @_;
    my $meta = $self->meta;
    my %headers;

    for my $name ( $meta->get_attribute_list ) {
        my $attr = $meta->get_attribute($name);
        next if !$attr->does('W3C::SOAP::WADL');
        next if !$attr->style eq 'header';

        my $has = 'has_' . $name;
        next if !$self->$has;

        $headers{$attr->real_name} = $self->$name;
    }

    return %headers;
}

my $urlencode = sub {
    my $url = shift;
    $url =~ s/(\W)/sprintf('%%%x',ord($1))/eg;
    return $url;
};
sub _get_query {
    my ($self) = @_;
    my $meta = $self->meta;
    my %query;

    for my $name ( $meta->get_attribute_list ) {
        my $attr = $meta->get_attribute($name);
        next if !$attr->does('W3C::SOAP::WADL');
        next if !$attr->style eq 'query';

        my $has = 'has_' . $name;
        next if !$self->$has;

        $query{ $urlencode->( $attr->real_name )} = $urlencode->( $self->$name );
        $query{$attr->real_name} = $self->$name;
    }

    return wantarray ? %query : join '&', map { "$_=$query{$_}"} keys %query;
}

1;

__END__

=head1 NAME

W3C::SOAP::WADL::Element - Provides ability to map inputted request object to response object.

=head1 VERSION

This documentation refers to W3C::SOAP::WADL::Element version 0.007.

=head1 SYNOPSIS

   use W3C::SOAP::WADL::Element;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Has a builder the will convert a HTTP request object to the WADL object.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

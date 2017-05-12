package W3C::SOAP::Document::Node;

# Created on: 2012-05-26 19:04:19
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = 0.14;
$ENV{W3C_SOAP_NAME_STYLE} ||= 'perl';

has node => (
    is       => 'rw',
    isa      => 'XML::LibXML::Node',
    required => 1,
);
has parent_node => (
    is        => 'rw',
    isa       => 'Maybe[W3C::SOAP::Document::Node]',
    predicate => 'has_parent_node',
    weak_ref  => 1,
);
has document => (
    is         => 'rw',
    isa        => 'W3C::SOAP::Document',
    required   => 1,
    builder    => '_document',
    lazy => 1,
    weak_ref   => 1,
    handles    => {
        xpc => 'xpc',
    },
);
has name => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    predicate  => 'has_name',
    builder    => '_name',
    lazy       => 1,
);

has perl_name  => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    predicate  => 'has_perl_name',
    builder    => '_perl_name',
    lazy       => 1,
);

has perl_names => (
    is   => 'ro',
    isa  => 'HashRef',
    lazy => 1,
    default => sub { return {} },
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    confess "If document is not specified parent_node must be defined!\n"
        if !$args->{document} && !$args->{parent_node};

    return $class->$orig($args);
};

sub _document {
    my ($self) = shift;
    confess "Lazybuild $self has both no parent_node nore document!\n" if !$self->has_parent_node || !defined $self->parent_node;
    return $self->parent_node->isa('W3C::SOAP::Document') ? $self->parent_node : $self->parent_node->document;
}

sub _name {
    my ($self) = shift;
    my $name = $self->node->getAttribute('name');
    $name =~ s/\W/_/gxms if $name;
    return $name;
}

sub _perl_name
{
    my ($self) = @_;
    my $name = $self->name;

    if ( $name && ( $ENV{W3C_SOAP_NAME_STYLE} ne 'original' ) ) {

        $name =~ s/ (?<= [^A-Z_] ) ([A-Z]) /_$1/gxms;

        # the allowed characters in XML identifiers are not the same
        # as those in Perl
        $name =~ s/\W//g;
        $name = lc $name;

        # horrid hack to dedupe elements Foo_Bar and Foo.Bar
        # which are obviously stupid but allowed
        if ( defined( my $parent = $self->parent_node() ) ) {
            if ( exists $parent->perl_names()->{$name} ) {
                $name .= '_' . $parent->perl_names()->{$name};
            }
            $parent->perl_names()->{$name}++;
        }
    }
    return $name;
}

1;

__END__

=head1 NAME

W3C::SOAP::Document::Node - The super class for document nodes

=head1 VERSION

This documentation refers to W3C::SOAP::Document::Node version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::Document::Node;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Base class for modules extracting information about XML nodes.

=head1 SUBROUTINES/METHODS

=over 4

=item C<perl_name ()>

Converts the node's name (if it has one) from camel case to the Perl style
underscore separated words eg TagName -> tag_name.

=back

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

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

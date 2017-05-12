#============================================================= -*-perl-*-
#
# XML::Schema::Facet
#
# DESCRIPTION
#   Module implementing a base object class for representing XML
#   Schema facets.  A facet is a mechanism for specifying optional
#   properties which constrain the value space of a datatype.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Facet.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Facet;

use strict;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( value );
@OPTIONAL  = qw( annotation name errmsg );


#------------------------------------------------------------------------
# new()
#
# Specialised constructor which extracts the facet name from the last
# element of the package name.  e.g. for XML:Schema::Facet::minLength
# the facet name is 'minLength'.  The $NAME package variable may be
# defined to override this behaviour and specify an alternate facet
# name.
#------------------------------------------------------------------------

sub new {
    my $class = shift;

    # make "new($n)" equivalent to "new(value => $n)"
    unshift(@_, 'value') if @_ == 1 && ref $_[0] ne 'HASH';

    $class->SUPER::new(@_);
}


sub init {
    my ($self, $config) = @_;
    my ($mand, $option) = @{ $self->_baseargs( qw( @MANDATORY %OPTIONAL ) ) };

    $self->_mandatory($mand, $config)
	|| return;

    $self->_optional($option, $config)
	|| return;

    $self->{ name } ||= do {
	my $class = ref $self;
	$class =~ /.*::(\w+)$/;
	$1;
    };

    return $self;
}


sub install {
    my ($self, $facets, $table) = @_;
#    $self->DEBUG("installing $self into type as $self->{ name }\n");
    push(@$facets, $self);
    $table->{ $self->{ name } } = $self;
    return 1;
}

sub name {
    my $self = shift;
    return $self->{ name };
}

sub value {
    my $self = shift;
    return $self->{ value };
}

sub annotation {
    my $self = shift;
    return $self->{ annotation };
}

sub valid {
    my ($self, $instance, $type) = @_;
    return 1;
}

sub invalid {
    my ($self, $msg) = @_;
    $self->error($self->{ errmsg } ||
		 "$msg (required $self->{ name }: $self->{ value })");
}


sub accept {
    my ($self, $visitor) = @_;
    $visitor->visit_facet($self);
}

1;

__END__

=head1 NAME

XML::Schema::Facet - base class for XML Schema facets

=head1 SYNOPSIS

    package XML::Schema::Facet::MyFacet;
    use base qw( XML::Schema::Facet );

    my $facet = XML::Schema::Facet::MyFacet->new(...);
    my $instance = {
	value => 'some data value',
    };

    print $facet->valid($instance) ? "valid" : "invalid";

=head1 DESCRIPTION

The XML::Schema::Facet module is a base class for objects that
represent XML Schema facets.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Facet
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema> and L<XML::Schema::Type::Simple>.


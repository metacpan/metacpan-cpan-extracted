#============================================================= -*-perl-*-
#
# XML::Schema::Type.pm
#
# DESCRIPTION
#   Module implementing a base class for XML Schema datatypes.  This
#   is the ur-type, instantiated within a schema as the ever-present
#   anyType.
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
#   $Id: Type.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Type;

use strict;
use XML::Schema::Base;
use XML::Schema::Type::Simple;
use XML::Schema::Type::Complex;

use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( ); 
@OPTIONAL  = qw( name namespace base );


#------------------------------------------------------------------------
# init()
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($name, $value);

    my ($mand, $option) 
	= @{ $self->_baseargs( qw( @MANDATORY %OPTIONAL ) ) };

    $self->_mandatory($mand, $config)
	|| return if @$mand;

    $self->_optional($option, $config)
	|| return;

    return $self;
}


#------------------------------------------------------------------------
# base()
# 
# Returns the value of the 'base' item, denoting a base class type.
#------------------------------------------------------------------------

sub base {
    my $self = shift;
    return $self->{ base };
}


#------------------------------------------------------------------------
# name()
# 
# Returns the type name.
#------------------------------------------------------------------------

sub name {
    my $self = shift;
    return $self->{ name };
}


#------------------------------------------------------------------------
# namespace()
# 
# Returns the type namespace.
#------------------------------------------------------------------------

sub namespace {
    my $self = shift;
    return $self->{ namespace };
}

1;

__END__

=head1 NAME

XML::Schema::Type - base class for XML Schema datatypes

=head1 SYNOPSIS

    package XML::Schema::Type::MyType;
    use base qw( XML::Schema::Type );

    package main;
    my $type = XML::Schema::Type::MyType->new(
	name      => 'MyTypeName',
	namespace => 'http://my.namespace.com/xyz',
    );

    print $type->name(), ", ", $type->namespace(), "\n";

=head1 DESCRIPTION

The XML::Schema::Type module is a base class for objects that 
represent XML Schema types.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Type module,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema>.


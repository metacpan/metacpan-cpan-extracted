#============================================================= -*-perl-*-
#
# XML::Schema::Handler
#
# DESCRIPTION
#   Module implementing a base class parser handler.
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
#   $Id: Handler.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Handler;

use strict;
use XML::Schema::Schedule;
use base qw( XML::Schema::Schedule );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( type );
@OPTIONAL  = qw( name );


#------------------------------------------------------------------------
# init()
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($name, $value);

    $self->SUPER::init($self, $config);

    my ($mand, $option) 
	= @{ $self->_baseargs( qw( @MANDATORY @OPTIONAL ) ) };

    $self->_mandatory($mand, $config)
	|| return if @$mand;

    $self->_optional($option, $config)
	|| return if @$option;

    $self->{ name } ||= '<anon>';

    return $self;
}


#------------------------------------------------------------------------
# accessor methods
#------------------------------------------------------------------------

sub type {
    my $self = shift;
    return $self->{ type };
}

sub name {
    my $self = shift;
    return $self->{ name };
}

sub ID {
    my $self = shift;
    return "Handler[$self->{ name }]";
}

1;

__END__

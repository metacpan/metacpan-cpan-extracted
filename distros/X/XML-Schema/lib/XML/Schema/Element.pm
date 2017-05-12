#============================================================= -*-perl-*-
#
# XML::Schema::Element.pm
#
# DESCRIPTION
#   Module implementing an object class for XML Schema elements.
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
#   $Id: Element.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Element;

use strict;
use XML::Schema;
use XML::Schema::Scoped;
use XML::Schema::Scheduler;
use base qw( XML::Schema::Scoped XML::Schema::Scheduler );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL @SCHEDULES );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

# mandatory 'type' implied by XML::Schema::Scoped base class
@MANDATORY = qw( name ); 
# optional 'scope' implied by XML::Schema::Scoped base class
@OPTIONAL  = qw( namespace annotation );
@SCHEDULES = qw( start_element start_child end_child end_element text );


#------------------------------------------------------------------------
# init()
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    # call base class (XML::Schema::Scoped) initialiser
    $self->SUPER::init($config)
	|| return;

    # call XML::Schema::Scheduler initialiser
    $self->init_scheduler($config)
	|| return;

    return $self;
}


#------------------------------------------------------------------------
# name($newname)
#
# Accesor method to fetch (no arguments) or update (first argument)
# element name.
#------------------------------------------------------------------------

sub name {
    my $self = shift;
    return @_ ? ($self->{ name } = shift) : $self->{ name };
}


#------------------------------------------------------------------------
# handler($instance)
# 
# Called 
#------------------------------------------------------------------------

sub handler {
    my ($self, $instance) = @_;
    my $type = $self->type();
    return $type->handler($instance, $self)
	|| $self->error($type->error());
}   

sub present {
    my ($self, $view) = @_;
    $view->view( element => $self );
}

sub ID {
    my $self = shift;
    return "Element[$self->{ name }]";
}


1;

__END__



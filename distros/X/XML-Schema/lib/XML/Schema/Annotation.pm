#============================================================= -*-perl-*-
#
# XML::Schema::Annotation.pm
#
# DESCRIPTION
#   Module implementing a mixin class for adding functionality to 
#   annotate objects.
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
#   $Id: Annotation.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Annotation;

use strict;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';



#------------------------------------------------------------------------
# init()
#------------------------------------------------------------------------

*init_annotation = \&init;

sub init {
    my ($self, $config) = @_;
    return $self;
}

sub add_annotation {
    my ($self, $type, $note) = @_;
    $self->{"_ANNOTATE_\U$type"} = $note;

    $self->TRACE("annotating ", $self, " with [$type] [$note]\n");
}

sub get_annotation {
    my ($self, $type, $note) = @_;
    $self->TRACE("fetching annotating [$type] from ", $self);
    return $self->{"_ANNOTATE_\U$type"};
}

1;

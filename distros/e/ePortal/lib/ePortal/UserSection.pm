#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------

package ePortal::UserSection;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::Support/;

    use ePortal::Global;
    use ePortal::PageSection;
    use ePortal::Utils;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{pv_id} ||= { dtype => 'Number'};
    $p{Attributes}{ps_id} ||= { dtype => 'Number'};
    $p{Attributes}{order_id} ||= { dtype => 'Number'};
    $p{Attributes}{colnum} ||= { dtype => 'Number'},
    $p{Attributes}{minimized} ||= { dtype => 'YesNo'},
    $p{Attributes}{setupinfo} ||= {
                dtype => 'Varchar',
                maxlength => 16000000,
        };

    $self->{ps} = new ePortal::PageSection;
    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Function: parent
############################################################################
sub parent  {   #05/17/01 3:32
############################################################################
    my $self = shift;

    my $parent = new ePortal::PageView;
    if ($parent->restore($self->pv_id)) {
        return $parent;
    } else {
        return undef;
    }
}##parent


############################################################################
sub restore_next    {   #10/12/01 2:29
############################################################################
    my $self = shift;
    my $result = $self->SUPER::restore_next(@_);

    if ($result) {
        $self->{ps}->restore($self->ps_id);
        # set default setupinfo in case we upgrading
        if ($self->setupinfo eq '' and $self->{ps}->setupinfo ne '') {
            $self->setupinfo( $self->{ps}->setupinfo );
        }
    } else {
        $self->{ps}->clear;
    }
    $result
}##restore_next




# ------------------------------------------------------------------------
# Here some attributes functions used to get values from related PageSection
# object
sub title   {   my $self = shift;   return $self->{ps}->title;  }
sub URL     {   my $self = shift;   return $self->{ps}->URL;}
sub width   {   my $self = shift;   return $self->{ps}->width;}
sub component{  my $self = shift;   return $self->{ps}->component;}
sub params  {   my $self = shift;   return $self->{ps}->params;}
sub content {   my $self = shift;   return $self->{ps}->content($self, @_);}
sub Setupable { my $self = shift;   return $self->{ps}->Setupable;}

############################################################################
# Функция аналогично ePortal::PageSection. 
sub setupinfo_hash {
############################################################################
    my $self = shift; 
    ePortal::PageSection::setupinfo_hash($self, @_) ;
}

1;

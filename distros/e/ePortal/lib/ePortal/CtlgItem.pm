#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software.
#
#----------------------------------------------------------------------------


package ePortal::CtlgItem;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::ParentACL/;

    use ePortal::Utils;
    use ePortal::Global;
    use Params::Validate qw/:types/;
    use ePortal::Catalog;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {};
    $p{Attributes}{parent_id} ||= {
        dtype => 'Number',
        fieldtype => 'popup_menu',
        popup_menu => sub {
            my $self = shift;
            my (@values, %labels);

            my $c = new ePortal::Catalog;
            if ( $c->restore($self->parent_id) ) {
              push @values, $self->parent_id;
              $labels{$self->parent_id} = $c->Title;
            };
            return (\@values, \%labels);
          },
        label => {rus => "Ресурс Каталога", eng => "Catalogue resource"},
        };
    $p{Attributes}{category1} ||= {
        dtype => 'Number',
        fieldtype => 'popup_menu',
        popup_menu => sub {
            my $self = shift;

            my $c = new ePortal::CtlgCategory;
            my ($values, $labels) = $c->restore_all_hash('id','title', 'parent_id=? AND catnum=1', 'title', $self->parent_id);
            unshift @{$values}, 0;
            $labels->{0} = pick_lang(rus => "-Без категории-", eng => "-No groupping-");
            return ($values, $labels);
          },
        };
    $p{Attributes}{category1_newname} ||= {
      type => 'Transient',
      label => { rus => 'Добавить группировку', eng => 'Add groupping'},
    };  
    $p{Attributes}{item_date} ||= {
        dtype => 'Date',
        fieldtype => 'date',
        };
    $p{Attributes}{uid} ||= { dtype => 'Varchar',
        default => $ePortal->username,
        };
    $p{Attributes}{ts} ||= { };
    $p{Attributes}{text} ||= {
        dtype => 'VarChar',
        maxlength => 16000000,
        };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    # Check title
    if ($self->Text eq '') {
        # It's possible if attachments exists
    }

    my $parent = $self->parent;
    if (! $parent->check_id) {
        return 'parent_id cannot be null';
    }

    # Check for required categories
    # Not need it! Any item is able to be without categories.
    if ($self->item_date eq '') {
        return pick_lang(rus => "Не указана группировка:", eng => "Category is missing:").
            $parent->catname_date;
    }
    $self->category1(undef) if $self->category1 == 0;

    undef;
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # default ORDER BY clause
    $p{order_by} = 'parent_id,item_date,title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub parent  {   #06/17/02 11:10
############################################################################
    my $self = shift;

    my $C = new ePortal::Catalog;
    $C->restore($self->parent_id);
    return $C;
}##parent


############################################################################
sub delete  {   #06/18/2003 1:15
############################################################################
    my $self = shift;
    my $result;

    if ($self->xacl_check_delete) {
        # myself attachments
        my $att = $self->Attachment;
        while($att and $att->restore_next) {
            $result += $att->delete;
        }
    }

    $result += $self->SUPER::delete;
    return $result;
}##delete

1;

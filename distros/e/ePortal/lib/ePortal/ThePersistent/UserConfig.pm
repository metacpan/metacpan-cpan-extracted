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
# The main ThePersistent class without ACL checking. All system tables
# without ACL should grow from this class
# ------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::UserConfig - ThePersistent object stored in UserConfig
database.

=head1 SYNOPSIS

See C<ePortal::ThePersistent::Support> and its base classes for more
information. This class stores objects in users session hash.

It can be used to create pseudo persistent objects with use all power of
C<Support.pm>

 # The example is equivalent to $ePortal->Config('attr_name')

 my $obj = new ePortal::ThePersistent::UserConfig;
 $obj->add_attribute(attr_name => {
                    dtype => 'VarChar',
                    maxlength => 64,
                    label => {rus => 'label rus', eng => 'Label eng'});
 $obj->restore();
 $obj->attr_name('value');
 $obj->update();

ID attribute is added internally.

=head1 METHODS

=cut

package ePortal::ThePersistent::UserConfig;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::Support/;

    use Carp qw/croak/;
    use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang

################################################################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my $self = shift;
    $self->SUPER::initialize(@_);

    $self->add_attribute( id => { type => 'ID', dtype => 'VarChar'} );
}##initialize

############################################################################
sub restore {   #11/22/01 11:49
############################################################################
    my $self = shift;
    my $id = shift || '!ePortal!';    # See Server::Config()

    $self->clear();
    $self->_id($id);
    foreach my $attr ($self->attributes) {
        next if $attr eq 'id';
        my $newvalue = $ePortal->_Config($id, $attr);
        $self->value($attr, $newvalue) if defined $newvalue;
    }
    1;
}##restore


############################################################################
sub restore_where   {   #11/22/01 11:52
############################################################################
    my $self = shift;

    croak "restore_where is not supported by ".__PACKAGE__;
}##restore_where

############################################################################
sub restore_next    {   #11/22/01 11:50
############################################################################
    my $self = shift;
    $self->clear;
    undef;
}##restore_next


############################################################################
sub delete  {   #11/22/01 11:53
############################################################################
    1;
}##delete


############################################################################
sub update  {   #11/22/01 11:53
############################################################################
    my $self = shift;
    my $id = $self->id;

    return undef if not $id;

    foreach my $attr ($self->attributes) {
        next if $attr eq 'id';
        $ePortal->_Config($id, $attr, $self->value($attr));
    }

    1;
}##update


############################################################################
sub insert  {   #11/22/01 11:53
############################################################################
    my $self = shift;
    $self->update;
}##insert


############################################################################
sub xacl_check  {   #02/20/03 8:29
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    ePortal::ThePersistent::ExtendedACL::xacl_check($self, $xacl_field);
}##xacl_check


1;

__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

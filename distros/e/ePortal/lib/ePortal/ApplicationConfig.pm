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

ePortal::ThePersistent::ApplicationConfig - ThePersistent object stored in UserConfig
database.

=head1 SYNOPSIS

See C<ePortal::ThePersistent::Support> and its base classes for more
information. This class stores objects in users session hash.

It can be used to create pseudo persistent objects with use all power of
C<Support.pm>

 # The example is equivalent to $ePortal->Config('attr_name')

 my $obj = new ePortal::ThePersistent::ApplicationConfig;
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

package ePortal::ApplicationConfig;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::Support/;

    use Carp qw/croak/;
    use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang

################################################################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my $self = shift;
    my %p = @_;

    $self->{obj} = $p{ApplicationObject};
    delete $p{ApplicationObject};
    throw ePortal::Exception::Fatal(-text => "Object needed for ePortal::ApplicationConfig")
        unless ref($self->{obj});

    # Add attributes to config object
    $p{Attributes}{id} = { type => 'ID', dtype => 'VarChar'};
    $p{Attributes}{dbi_source_type} = {
          type => 'Transient',
          fieldtype => 'radio_group',
          default => 'ePortal',
          values => ['ePortal', 'custom'],
          label => pick_lang(rus => "Подключение к базе данных", eng => "Database connect"),
          labels => { 
            ePortal => pick_lang(rus => "Стандартное", eng => "Standard"),
            custom  => pick_lang(rus => "Специальное", eng => "Custom"),
          }};

    $p{Attributes}{dbi_source} = {
            size => 50,
#            label => pick_lang(rus => "Источник данных DBI", eng => "DBI connect string"),
            default => 'ePortal',
      };
    $p{Attributes}{dbi_username} = {
            size => 20,
#            label => pick_lang(rus => "Имя пользователя DBI", eng => "DBI user name")
      };
    $p{Attributes}{dbi_password} = {
            size => 20,
#            label => pick_lang(rus => "Пароль пользователя DBI", eng => "DBI password")
      };


    $self->SUPER::initialize(%p);
}##initialize

############################################################################
# Load attributes from ApplicationObject->{attribute}
sub restore {   #11/22/01 11:49
############################################################################
    my $self = shift;

    $self->clear();
    $self->_id('!' . $self->{obj}->ApplicationName . '!');
    $self->{obj}->config_load;  # once again. Refresh config

    foreach my $attr ($self->attributes_a) {
        my $newvalue = $self->{obj}->{$attr};
        $self->value($attr, $newvalue) if defined $newvalue;
    }

    $self->dbi_source_type( $self->dbi_source eq 'ePortal' ? 'ePortal' : 'custom' );
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

    $self->dbi_source('ePortal') if $self->dbi_source_type eq 'ePortal';
    foreach my $attr ($self->attributes_a) {
        $self->{obj}->{$attr} = $self->value($attr);
    }
    $self->{obj}->config_save;

    # test database connection. This will throw ePortal::Exception::DBI
    $self->{obj}->dbh;

    # clear storage_version for external storages
    if ($self->{obj}->dbi_source ne 'ePortal') {
        $self->{obj}->{storage_version} = 0;
        $self->{obj}->config_save;
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

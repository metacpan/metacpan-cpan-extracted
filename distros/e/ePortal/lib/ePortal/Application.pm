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

=head1 NAME

ePortal::Application - The base class for ePortal applications.

=head1 SYNOPSIS

To create an application derive it from ePortal::Application and place base
module in lib/ePortal/App/YourModule.pm

This manual is incomplete !!!

=head1 METHODS

=cut

package ePortal::Application;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::ACL/;

	use ePortal::Global;
	use ePortal::Utils;


############################################################################
sub new {   #09/08/2003 1:53
############################################################################
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->config_load;
    return $self;
}##new

################################################################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my $self = shift;
    my %p = @_;

    # Add attributes to config object
    $p{Attributes}{uid} ||= {};
    $p{Attributes}{id} = { 
            type => 'ID', 
            default => '!' . $self->ApplicationName . '!',
            dtype => 'VarChar'};
    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub ApplicationName	{	#04/18/02 2:33
############################################################################
	my $self = shift;
	my $appname = ref($self);
	$appname =~ s/.*:://;
	return $appname;
}##ApplicationName



############################################################################
sub config_load {   #03/17/03 4:55
############################################################################
    my $self = shift;
    my @parameters = @_;

    $self->_id('!' . $self->ApplicationName . '!');

    # Try load config hash
    my $c = $ePortal->_Config('!' . $self->ApplicationName . '!', 'config');
    if ( ref($c) eq 'HASH' ) {
        foreach ($self->attributes_a) {
            $self->value($_, $c->{$_}) if exists $c->{$_};
        }

    }
}##config_load



############################################################################
sub config_save {   #03/17/03 4:55
############################################################################
    my $self = shift;
    my @parameters = @_;

    my $c = {};

    # Save configuration parameters
    foreach ($self->attributes_a ) {
        $c->{$_} = $self->value($_);
    }
    $ePortal->_Config('!' . $self->ApplicationName . '!', 'config', $c);
}##config_save


############################################################################
sub Config  {   #07/29/2003 11:21
############################################################################
    my $self = shift;
    $ePortal->_Config('!' . $self->ApplicationName . '!', @_);
}##Config





############################################################################
sub dbh	{	#05/06/02 2:46
############################################################################
	my $self = shift;
  return $ePortal->dbh;
}##dbh


=head2 onDeleteUser,onDeleteGroup

This is callback function. Do not call it directly. It is called from
ePortal::Server. Overload it in your application package to remove user or
group specific data.

Parameters:

=over 4

=item * username or groupname

User or Group name to delete.

=back

=cut

############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;

}##onDeleteUser


############################################################################
sub onDeleteGroup    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $groupname = shift;

}##onDeleteGroup

############################################################################
# Load attributes from ApplicationObject->{attribute}
sub restore {   #11/22/01 11:49
############################################################################
    my $self = shift;
    $self->config_load;
    1;
}##restore


############################################################################
sub restore_where   {   #11/22/01 11:52
############################################################################
    my $self = shift;

    throw ePortal::Exception::Fatal(-text => "restore_where is not supported by ".__PACKAGE__);
}##restore_where

############################################################################
sub restore_next    {   #11/22/01 11:50
############################################################################
    my $self = shift;
    undef;
}##restore_next

############################################################################
sub update  {   #11/22/01 11:53
############################################################################
    my $self = shift;
    
    $self->config_save;
    1;
}##update


############################################################################
sub insert  {   #11/22/01 11:53
############################################################################
    my $self = shift;
    $self->update;
}##insert



# ------------------------------------------------------------------------
# This is standard set of XACL methods
# Other Applications may have another methods
#
#sub xacl_check_read { 1; }
#sub xacl_check_children { shift->xacl_check_update; }
sub xacl_check_insert { 0; }     # impossible for Application
sub xacl_check_delete { 0; }     # impossible for Application
sub xacl_check_admin  { $ePortal->isAdmin; }
sub xacl_check_update   { 
    my $self = shift;
    if ($self->attribute('xacl_write')) {
        return $self->xacl_check('xacl_write');
    } else {
        return $ePortal->isAdmin;
    }
}



1;

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

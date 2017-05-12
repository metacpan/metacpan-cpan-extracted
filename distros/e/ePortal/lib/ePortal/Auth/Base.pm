#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::Auth::Base - ePortal authentication module.

=head1 SYNOPSIS

This is base class for authentication modules. Others are inherited from 
this.

=head1 METHODS

=cut


package ePortal::Auth::Base;
    our $VERSION = '4.5';

    use ePortal::Exception;
    use ePortal::Global;
    use ePortal::Utils;
    use Error qw/:try/;
    use Params::Validate qw/:types/;

=head2 new

Object constructor.

=over 4

=item * username

Login user name to deal with.

=back

=cut

############################################################################
sub new {   #09/12/2003 2:36
############################################################################
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $username = shift;

    my $self = {
        username => $username,
        };
    bless $self, $class;

    $self->initialize(@_);
    return $self;
}##new



=head2 initialize

Extra initialization module. Derived packages may use it for further 
initialization

This function is called from object construstor.

=cut

############################################################################
sub initialize  {   #09/12/2003 2:41
############################################################################
    my $self = shift;
    
}##initialize

=head2 check_account

Check user account for existance.

This method is responsible for retrieval of additional user information.
This information should be cached.

=cut

############################################################################
sub check_account   {   #09/12/2003 2:40
############################################################################
    my $self = shift;
    
}##check_account


=head2 check_password

Authenticate the user with password

=cut

############################################################################
sub check_password  {   #09/12/2003 2:40
############################################################################
    my $self = shift;
    my $password = shift;
    0;
}##check_password


=head2 dn

DN of user object in external directory. That is LDAP DN. May be different 
from username.

=cut

############################################################################
sub dn  {   #09/12/2003 2:47
############################################################################
    my $self = shift;
    return $self->{dn};
}##dn


=head2 title

Additional user information.

=cut

############################################################################
sub title   {   #09/12/2003 2:48
############################################################################
    my $self = shift;
    return $self->{title};
}##title


=head2 full_name

Additional user information

=cut

############################################################################
sub full_name   {   #09/12/2003 2:48
############################################################################
    my $self = shift;
    return $self->{full_name};
}##full_name


=head2 department

Additional user information

=cut

############################################################################
sub department  {   #09/12/2003 2:49
############################################################################
    my $self = shift;
    return $self->{department};
}##department


=head2 membership

Return array of group names where the user is member.

=cut

############################################################################
sub membership {   #09/12/2003 2:40
############################################################################
    my $self = shift;
    
}##membership



=head2 check_group

Check group for existance

=over 4

=item * group_dn

Group DN to check.

=back

=cut

############################################################################
sub check_group {   #09/12/2003 2:50
############################################################################
    my $self = shift;
    
}##check_group


=head2 group_title

Group title as present in external directory

=over 4

=item * group_dn

Group DN to check.

=back

=cut

############################################################################
sub group_title {   #09/12/2003 2:49
############################################################################
    my $self = shift;
    
}##group_title

1;


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

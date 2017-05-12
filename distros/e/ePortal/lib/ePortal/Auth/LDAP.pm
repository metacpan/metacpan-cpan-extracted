#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#----------------------------------------------------------------------------

package ePortal::Auth::LDAP;
    our $VERSION = '4.5';
    use base qw/ePortal::Auth::Base/;

    use ePortal::Exception;
    use ePortal::Global;
    use ePortal::Utils;
    use Error qw/:try/;
    use Params::Validate qw/:types/;

    use Net::LDAP;
    use Unicode::Map8;
    use Unicode::String;

############################################################################
sub initialize  {   #09/12/2003 2:54
############################################################################
    my $self = shift;
    
    # check required parameters
    throw ePortal::Exception::Fatal(-text => "ldap_charset parameter of ePortal is empty")
        if ! $ePortal->ldap_charset;
    throw ePortal::Exception::Fatal(-text => "ldap_server parameter is empty")
        if ! $ePortal->ldap_server;

    # connect to LDAP server
    $self->{ldap_server} = $self->ldap_connect($ePortal->ldap_binddn, $ePortal->ldap_bindpw);
    throw ePortal::Exception::Fatal(-text => "Cannot connect to LDAP server")
        if ! $self->{ldap_server};

    # search the user 
    $self->{ldap_entry} = $self->search_entry($ePortal->ldap_uid_attr, $self->{username});

    # get additional info about the user
    if ($self->{ldap_entry}) {
        my $ldap_charset = $ePortal->ldap_charset;
        $self->{dn} = $self->{ldap_entry}->dn;
        $self->{full_name} = cstocs($ldap_charset,'WIN', $self->{ldap_entry}->get_value($ePortal->ldap_fullname_attr))
                                if $ePortal->ldap_fullname_attr;
        $self->{title}     = cstocs($ldap_charset,'WIN', $self->{ldap_entry}->get_value($ePortal->ldap_title_attr))
                                if $ePortal->ldap_title_attr;
        $self->{department}= cstocs($ldap_charset,'WIN', $self->{ldap_entry}->get_value($ePortal->ldap_ou_attr))
                                if $ePortal->ldap_ou_attr;
    }
}##initialize


############################################################################
sub ldap_connect    {   #10/30/02 4:08
############################################################################
    my ($self, $connect_username, $connect_password) = Params::Validate::validate_with( params => \@_, spec => [
        { type => OBJECT },
        { type => UNDEF | SCALAR, optional => 1},
        { type => UNDEF | SCALAR, optional => 1} ] );

    if (! $ePortal->ldap_server) {
        logline('emerg', 'ldap_connect: ldap_server parameter is empty in ePortal.conf');
        return undef;
    }

    # Connect to LDAP server
    if ($connect_username ne '' and $connect_password eq '') {
        logline('error', 'ldap_connect: password is empty. Cannot connect to LDAP');
        return undef;
    }
#    $connect_password = cstocs('WIN', 'DOS', $connect_password);
#    $connect_password = cstocs('WIN', 'UTF8', $connect_password);

    my $ldap_server = new Net::LDAP( $ePortal->ldap_server, onerror => 'warn', version => 3 );
    if (!$ldap_server) { return undef; }

    my $mesg;
    if ($connect_username) {
        $mesg = $ldap_server->bind( $connect_username,
                password => $connect_password);
        logline('debug', "ldap_connect: authenticating with $connect_username. Error code:", $mesg->is_error);
    } else {
        $mesg = $ldap_server->bind();
        logline('debug', "ldap_connect: binding anonymously. Error code:", $mesg->is_error);
    }

    return $mesg->is_error? undef : $ldap_server;
}##ldap_connect


############################################################################
sub check_account   {   #09/12/2003 2:40
############################################################################
    my $self = shift;

    return undef if ! $self->{ldap_entry};

    return 1;
}##check_account


############################################################################
sub search_entry   {   #10/30/02 4:13
############################################################################
    my ($self, $search_attr, $search_value) =
        Params::Validate::validate_with( params => \@_, spec => [
        { type => OBJECT },
        { type => SCALAR},
        { type => SCALAR} ] );

    # Construct search LDAP filter
    $search_value = cstocs('WIN', $ePortal->ldap_charset, $search_value);
    my $filter = sprintf q|(&(%s=%s))|, $search_attr, $search_value;

    my $mesg;
    if ($search_attr eq 'dn') {
        $mesg = $self->{ldap_server}->search(
            base => $search_value,  # search_value is DN. Start searching from it.
                                    # If it is not exists then search will fail
            filter => 'cn=*',
            deref => 'always',
            scope => 'base',
            timelimit => 600,
            attrs => ['*']);
    } else {
        $mesg = $self->{ldap_server}->search(
            base => $ePortal->ldap_base,
            deref => 'always',
            filter => $filter,
            scope => 'sub',
            timelimit => 600,
            attrs => ['*']);
    }

    if ($mesg->is_error) {
        logline('emerg', "An error occured during LDAP query: ", $mesg->error);
        return undef;
    }

    my $entry = $mesg->pop_entry;
    return undef if ! ref($entry);

    return $entry;
}##search_entry


############################################################################
sub check_password  {   #09/15/2003 9:46
############################################################################
    my $self = shift;
    my $password = shift;

    return 0 if ! $self->check_account;

    my $result = $self->ldap_connect($self->dn, $password);
    return $result ? 1 : 0;
}##check_password


############################################################################
sub membership  {   #09/15/2003 9:48
############################################################################
    my $self = shift;

    return () if ! $self->{ldap_entry};
    return () if ! $ePortal->ldap_group_attr;

    my $ldap_charset = $ePortal->ldap_charset;
    my @v = $self->{ldap_entry}->get_value($ePortal->ldap_group_attr);
    @v = grep {length($_) < $ePortal::Server::MAX_GROUP_NAME_LENGTH} @v;
    foreach (@v) {
        $_ = cstocs($ldap_charset,'WIN', $_);
    }
    return @v;  
}##membership

############################################################################
sub check_group {   #09/15/2003 10:31
############################################################################
    my $self = shift;
    my $group_dn = shift;

    my $entry = $self->search_entry('dn', $group_dn);
    return $entry ? 1 : 0;
}##check_group


############################################################################
sub group_title {   #09/15/2003 10:32
############################################################################
    my $self = shift;
    my $group_dn = shift;
    
    return undef if ! $ePortal->ldap_groupdesc_attr;

    my $entry = $self->search_entry('dn', $group_dn);
    return undef if ! $entry;

    my $ldap_charset = $ePortal->ldap_charset;
    my $v = $entry->get_value($ePortal->ldap_groupdesc_attr);
    $v = cstocs($ldap_charset, 'WIN', $v);
    return $v;
}##group_title


1;

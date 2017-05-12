# -*- perl -*-
#
#   Wizard - A Perl package for implementing system administration
#            applications in the style of Windows wizards.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@ispsoft.de
#                                  Phone: +49 7123 14887
#
#                          and     Amarendran R. Subramanian
#                                  Grundstr. 32
#                                  72810 Gomaringen
#                                  Germany
#
#                                  Email: amar@ispsoft.de
#                                  Phone: +49 7072 920696
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   $Id$
#

use strict;

use Socket ();
use Net::LDAP ();
use Wizard;
use Wizard::SaveAble ();

package Wizard::SaveAble::LDAP;

@Wizard::SaveAble::LDAP::ISA = qw(Wizard::SaveAble);
$Wizard::SaveAble::LDAP::VERSION = '0.1001';

=pod

=head1 NAME

    Wizard::SaveAble::LDAP - A package for automatically saved objects,
    that are stored in a LDAP server's directory structure.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

#'
sub _load {
    my $proto = shift; my $self = shift; my $dn = shift;
    die "Cannot load object without a valid dn" unless($dn);
    my $prefix = $self->{'prefix'};

    my $ldap = LDAPBind($self);
    my $mesg = $ldap->search(base => $dn,
			     filter => 'objectClass=*',
			     scope => 0) || die "Could not search for $dn: $@";
    die "Following error occured while searching: code=" . $mesg->code
	. ", error=" . $mesg->error if $mesg->code;
    die "Could not find entry $dn " unless $mesg->count;
    my $entry = $mesg->entry(0); my ($value, $val); my @vals;
    $self = bless({%$self, map { @vals = $entry->get($_);
				 ($#vals == 0) ? ($prefix . $_ => $vals[0]) 
				               : ($prefix . $_ => [ @vals ]);
			       } $entry->attributes}, $proto);
    LDAPUnbind($self);
    $self;
}


sub AttrRef2Scalar($$) {
    my $self = shift; my @keys = @_;
    my $key; my $prefix = $self->{'prefix'};
    my ($val, $vals);
    foreach $key (@keys) {
	$key = $prefix . $key unless $key =~ /^$prefix/;
	next unless ref($self->{$key});
	$vals = $self->{$key};
	$self->{$key} = shift @$vals;
	foreach $val (@$vals) {
	    $self->{$key} .= ", $val";
	}
    }
}

sub AttrScalar2Ref($$) {
    my $self = shift; my @keys = @_;
    my $key; my $prefix = $self->{'prefix'};
    foreach $key (@keys) {
	$key = $prefix . $key unless $key =~ /^$prefix/;
	next if (ref($self->{$key}) || !($self->{$key}));
	$self->{$key} = [ split(/\,\s*/, $self->{$key})];
    }
}

sub LDAPBind {
    my $self=shift;
    my $serverport = $self->{'serverport'};
    my $ldap = new Net::LDAP($self->{'serverip'},
			     $serverport > 0 ? (port => $serverport)
			                     : ()); 
    die "Could not initialize LDAP object, probable cause: $!" unless(ref($ldap));
    $self->{'_wizard_saveable_ldap'} = $ldap;
    my $dn = $self->{'adminDN'};
    my $password = $self->{'adminPassword'};
    $ldap->bind(dn       => $self->{'adminDN'},
		password => $self->{'adminPassword'}
		) or die "Cannot bind to LDAP server $@";
    $ldap->sync;
    $ldap;
}

sub LDAPUnbind {
    my $self=shift;
    my $ldap = (delete $self->{'_wizard_saveable_ldap'}) || return;
    $ldap->unbind;
}

sub new {
    my $proto = shift;
    my $self = { @_ };
    $self->{'serverport'} ||= 0;
    $self->{'adminPassword'} ||= '';
    $self->{'prefix'} ||= '';
    my $serverport = $self->{'serverport'};
    die "Missing server ip or invalid server ip" 
	unless (($self->{'serverip'} ne '') && (Socket::inet_aton($self->{'serverip'})));
    die "Missing server port" unless $serverport =~ /^[\d]+$/;
    die "Missing admin dn" unless $self->{'adminDN'};

    my $dn = delete $self->{'dn'} if (exists($self->{'dn'}));
    if (exists($self->{'load'}) and delete $self->{'load'}) {
	return $proto->_load($self, $dn) if $dn;
    }
    bless($self, (ref($proto) || $proto));
    $self->Modified(1);
    $self->DN($dn);
    $self->CreateMe($dn);
    $self;    
}

sub DN {
    my $self = shift;
    if (@_) {
	$self->{'_wizard_saveable_olddn'} = $self->{'_wizard_saveable_dn'};
        $self->{'_wizard_saveable_dn'} = shift;
    }
    wantarray ? return ($self->{'_wizard_saveable_dn'}, 
			$self->{'_wizard_saveable_olddn'}) 
	      : return $self->{'_wizard_saveable_dn'};
}

sub Store {
    my $self = shift;

    # Create a copy of the object to work with it.
    my $copy = { %$self };
    bless($copy, ref($self));

    return unless delete $copy->{'_wizard_saveable_modified'};

    my $cme = delete $copy->{'_wizard_saveable_createme'};
    my $dn = delete $copy->{'_wizard_saveable_dn'} 
       or die "Cannot store object without a valid DN";    
    my $old_dn = delete $copy->{'_wizard_saveable_olddn'} || $dn;
    my $prefix = delete $copy->{'prefix'};
    my $ldap = $self->LDAPBind();
    my $mesg; my @vals;
    my $attr =[ map {(/^$prefix(.+)$/ && ($copy->{$_} ne '')) 
			 ? ($1 => $copy->{$_}) 
			 : ()
		     } (keys %$copy)];
    if(!$cme) {
	if($old_dn ne $dn) {
	    $mesg = $ldap->delete(dn => $old_dn);
	    die "Error deleting old entry '$old_dn', code=" . $mesg->code
		. " error=" . $mesg->error . "." if $mesg->code;
	    $self->LDAPUnbind();
	    $ldap = $self->LDAPBind();
	    $mesg = $ldap->add(dn => $dn, attr => $attr) 
		or die "Error while adding $dn: $@";
	} else {
	    $mesg = $ldap->modify(dn => $dn, replace => { @$attr });
	}
    } else {
	$mesg = $ldap->add(dn => $dn, attr => $attr) 
	    or die "Error while adding $dn: $@";
    }
    die "Object '$dn' already exists: code=" . $mesg->code . ", error=" 
	. $mesg->error if($mesg->code == Net::LDAP::Constant::LDAP_ALREADY_EXISTS());
    die "Following error occured while adding/modifying '$dn': code=" . $mesg->code 
	. ", error=" . $mesg->error  if $mesg->code;
    
    $self->LDAPUnbind();
    $self->CreateMe(0);
    $self->Modified(0);
}

sub Delete {
    my $self = shift;
    my $dn = $self->DN() || die "Missing dn";
    my $ldap = $self->LDAPBind();
    my $mesg = $ldap->delete(dn => $dn);
    die "Following error occured while deleting '$dn': code=" . $mesg->code
	. ", error=" . $mesg->error  if $mesg->code;

    $self->LDAPUnbind();
}


1;

=pod

=head1 AUTHORS AND COPYRIGHT

This module is

  Copyright (C) 1999     Jochen Wiedmann
                         Am Eisteich 9
                         72555 Metzingen
                         Germany

                         Email: joe@ispsoft.de
                         Phone: +49 7123 14887

                 and     Amarendran R. Subramanian
                         Grundstr. 32
                         72810 Gomaringen
                         Germany

                         Email: amar@ispsoft.de
                         Phone: +49 7072 920696

All Rights Reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<Wizard::SaveAble(3)>, L<Wizard(3)>, L<Wizard::State(3)>

=cut

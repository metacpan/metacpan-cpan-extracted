package Net::LDAP::Shell::Desc;
require Exporter;
use strict;

# This is a package to print the descriptions of any given attribute from LDAP
# it's just a convenient way to correlate an attribute to its description, without
# having to have every script do the same thing.
#
# Begun on 9/28/01
# Luke A. Kanies

our @ISA			= qw(Exporter);
our @EXPORT		= qw(describe);
our @EXPORT_OK	= qw($at_desc_ref);
our @VERSION	= 1.00;

unless ($Net::LDAP::Shell::Desc::at_desc_ref)
{
	$Net::LDAP::Shell::Desc::at_desc_ref =
	{
		'cn'								=> "Name",
		'iphostnumber'					=> "IP Address",
		"systemversion"				=> "OS Version",
		"operatingsystem"				=> "Operating System",
		"systemrelease"				=> "OS Release",
		"hardwareplatform"			=> "Hardware Platform",
		"uniqueid"						=> "Unique ID",
		"service"						=> "Services",
		"uid"								=> "User ID",
		'menuapp'						=> 'Application',
		'menuhost'						=> 'Server',
		'menudir'						=> 'Directory',
		'menuprev'						=> 'Previous Menu Item',
		'menutz'							=> 'Timezone',
		'departmentnumber'			=> 'Department',
		'cataffiliatedorgcode'		=> 'Cat Affiliated Org Code',
		'cataffiliation'				=> 'Cat Affiliation',
		'cataffiliationcode'			=> 'Cat Affiliation Code',
		'catcupid'						=> 'Cat CUP ID',
		'catlastloginipaddress'		=> 'Cat Last Login IP Address',
		'catlastlogintime'			=> 'Cat Last Login Time',
		'catmiddleinitial'			=> 'Cat Middle Initial',
		'consoleserver'				=> 'Console Server',
		'description'					=> 'Description',
		'cwsdn'							=> 'CWS Address',
		'gidnumber'						=> 'Unix Group Number',
		'givenname'						=> 'First Name',
		'homedirectory'				=> 'Unix Home Directory',
		'initials'						=> 'Initials',
		'mail'							=> 'Email Address',
		'menutz'							=> 'Menu Timezone',
		'middlename'					=> 'Middle Name',
		'objectclass'					=> 'Objectclass',
		'registeredname'				=> 'Registered Name',
		'sn'								=> 'Last Name',
		'telephonenumber'				=> 'Telephone Number',
		'uid'								=> 'User ID',
		'uidnumber'						=> 'Unix User ID Number',
		'unixhost'						=> 'Unix Host',
		'userpassword'					=> 'Password',
		'oldpassword'					=> 'Old Password',
		'newpassword'					=> 'New Password',
		'confpassword'					=> 'Confirm Password',

	};
}

sub describe
{
	my $attr = shift;

	$attr =~ tr/A-Z/a-z/;

	if (exists ($Net::LDAP::Shell::Desc::at_desc_ref->{$attr}) )
	{
		return $Net::LDAP::Shell::Desc::at_desc_ref->{$attr};
	}
	else
	{
		return $attr;
	}
}

#$Id: Desc.pm,v 1.5 2002/10/02 23:27:32 luke Exp $

1;

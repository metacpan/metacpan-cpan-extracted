# utility routines to be shared amongst the various classes
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>
package Unix::Conf::Bind8::Conf::Lib;

use strict;
use warnings;

require Exporter;
our @ISA = qw (Exporter);
#	__valid_rlim
our @EXPORT = qw (
	__valid_element
	__valid_ipaddress 
	__valid_port 
	__valid_ipprefix
	__valid_yesno 
	__valid_forward 
	__valid_checknames 
	__valid_category 
	__valid_facility 
	__valid_severity 
	__valid_number 
	__valid_sizespec
	__valid_string
	__valid_transfer_format
);


# used for validating  resource limit type options
#sub __valid_rlim
#{
#	my $num = qr/\d+[KkMmGg]?/;
#	return ($_[0] =~ /^($num|'unlimited'|'default')$/);
#}

# ACL element
sub __valid_element
{
    my ($confds, $element) = @_;

	# if an Acl object, return true.
	ref ($element) && UNIVERSAL::isa ($element, 'Unix::Conf::Bind8::Conf::Acl')
		&& return (1);

	# strip any leading `!'
    $element =~ s/^!(.*)/$1/o;
	if ($element =~ /^key/gc) {
		$element =~ /\G\s+(\S+)\s*$/ || return ();
		return (1) if (Unix::Conf::Bind8::Conf::_get_key ($confds, $1));
		return (Unix::Conf->_err ("__valid_element", "key `$1' not defined"));
	}
    __valid_ipaddress ($element) && return (1);
    __valid_ipprefix ($element) && return (1);
    # must be some acl name (built-in or defined)
    (
		$element eq 'none' || $element eq 'any' ||
    	$element eq 'localhost' || $element eq 'localnets'
	) && return (1);
    Unix::Conf::Bind8::Conf::_get_acl ($confds, $element) && return (1);
    return (Unix::Conf->_err ("__valid_element", "acl `$element' not defined"));
}


sub __valid_port ($)
{
	no warnings;
	($_[0] eq '*') 					&& return (1);
	($_[0] !~ /^\d+$/)				&&	return ();
	($_[0] >= 0 && $_[0] <= 65536)	&& return (1);
	return ();
}

# routine to validate an IPv4 address. check this out later
sub __valid_ipaddress ($) { return ($_[0] =~ /^(?:(?:\d{1,3}\.){3}\d{1,3})$/); }
# we could tighten this up a lot
sub __valid_ipprefix ($) 	{ return ($_[0] =~ /^(?:\d{1,3}(\.\d{1,3}){0,3}\/\d{1,2})$/); }
sub __valid_yesno ($) 		{ return ($_[0] =~ /^(yes|no|true|false|1|0)$/); }
sub __valid_checknames ($) 	{ return ($_[0] =~ /^(warn|fail|ignore)$/); }
sub __valid_forward ($) 	{ return ($_[0] =~ /^(only|first)$/); }
sub __valid_category ($) 	{ return ($_[0] =~ /^(default|config|parser|queries|lame-servers|statistics|panic|update|ncache|xfer-in|xfer-out|db|eventlib|packet|notify|cname|security|os|insist|maintenance|load|reponse-checks)$/); }
sub __valid_facility ($) 	{ return ($_[0] =~ /^(kern|user|mail|daemon|auth|syslog|lpr|news|uucp|cron|authpriv|ftp|local0|local1|local2|local3|local4|local5|local7|local7)$/); }
sub __valid_severity ($) 	{ return ($_[0] =~ /^(critical|error|warning|notice|info|debug|dynamic)$/); }
sub __valid_number ($) 		{ return ($_[0] =~ /^\d+$/); }
sub __valid_sizespec ($) 	{ return ($_[0] =~ /^(unlimited|default|\d+[kKmMgG]?)/); }
sub __valid_transfer_format { return ($_[0] =~ /^(one-answer|many-answers)$/); }

# This routine strips any "" in the original argument as it acts on the ref
# returns true all the time
sub __valid_string ($) { $_[0] =~ s/^"(.+)"$/$1/; return (1) }

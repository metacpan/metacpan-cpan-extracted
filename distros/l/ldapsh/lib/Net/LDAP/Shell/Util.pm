package Net::LDAP::Shell::Util;

$^W = 1;

use strict;
require Exporter;
use Getopt::Long;
use Net::LDAP::Shell qw(shellSearch);

use vars qw($VERSION @ISA @EXPORT $NOCOLOR);

@ISA = qw(Exporter);
@EXPORT = qw(
	color
	debug
	edit
	error
	entry2ldif
	serverType
);

$VERSION = 1.00;

=head1 NAME

Net::LDAP::Shell::Util - a module for utility routines

=head1 SYNOPSIS

   my $shell = Net::LDAP::Shell->new();
	$shell->run();

=head1 DESCRIPTION

B<Net::LDAP::Shell> is the base module for an interactive
LDAP shell, modeled after the Unix CLI but hopefully
nowhere near as complicated.  It has both builtin commands
(found by running 'builtins' on the CLI) and external
commands (?).

=cut

=head1 DESCRIPTION

=over 4

=cut

=begin comment

####################################################################################
# debug

=item debug

Can be used to turn debugging on (debug("on")) or off (debug("off")),
otherwise prints on STDERR anything passed to it if debugging is
currently on.

=cut

sub debug
{
	if ($_[0])
	{
		$_[0] =~ /^on$/i and do
		{
			warn "turning debug on\n";
			$Net::LDAP::Shell::DEBUG = 1;
			return;
		};
		$_[0] =~ /^off$/i and do
		{
			warn "turning debug off\n";
			$Net::LDAP::Shell::DEBUG = 0;
			return;
		};
	}
	else
	{
		return $Net::LDAP::Shell::DEBUG || 0;
	}
	unless ($Net::LDAP::Shell::DEBUG) { return; }
	if (@_)
	{
		warn "$0: @_\n";
	}
   return 1;
}
# debug
##################################################################################

#-----------------------------------------------------------------------------
# edit
sub edit {
	my $tmpfile = shift;
	my $osum = shift;
	my $editor = $ENV{'EDITOR'} || "vi";
	system($editor,$tmpfile);

	my $nsum = qx|sum $tmpfile|;
	chomp $nsum;

	if ($osum eq $nsum) {
		warn "Entry did not change\n";
		return 0;
	} else {
		return 1;
	}
}
# edit
#-----------------------------------------------------------------------------

##################################################################################
# error

=item error

Used to store and report errors on the shell.  Any arguments
passed to B<error> are joined into a single error message and 
returned as an error any time B<error> is called.

EXAMPLE

=over 4

if ( error() ) { warn error("There was a problem"); }
else { dostuff(); }

if (error()) { die error(); }

=back

=cut

sub error
{
   if (@_)
   {
      $Net::LDAP::Shell::ERROR = join(' ', @_) . "\n";
   }
    
   if ($Net::LDAP::Shell::ERROR)
   {
      return $Net::LDAP::Shell::ERROR;
   }
	else
	{
		return;
	}
}
# error
####################################################################################

####################################################################################
# entry2ldif

=item entry2ldif

Turns an entry into plain ldif.  From what I can tell, not everything
agrees that $entry->dump is valid LDIF, so I wrote this instead.  Accepts
a L<Net::LDAP::Entry> object, and returns a string.

=cut

sub entry2ldif
{
	my $entry = shift or return;;

	my ($string,$attr,@values);

	$string = "dn: " . $entry->dn() . "\n";
	foreach $attr ($entry->attributes)
	{
		@values = $entry->get_value($attr);
		map { $string .= "$attr: $_\n"; } @values;
	}

	return $string;
}
# entry2ldif
####################################################################################

####################################################################################
# serverType

=item serverType

Given a L<Net::LDAP> object, returns what type of server it is.

=cut

sub serverType
{
	my (%base,$ldap,@entries,$dse,);

	use vars qw($type); # we want this to persist

	if ($type) { return $type; } # if we've already been run, return the cached type

	$ldap = shift;

	$base{'filter'} = 'objectclass=*';
	$base{'base'} = '';
	$base{'scope'} = 0;
	$base{'attrs'} = [qw(namingcontexts objectclass)];

	my $results = $ldap->search(%base);
	$results->code and error($results->error) and return;
	@entries = $results->all_entries;

	$dse = shift @entries;

	if (grep /OpenLDAProotDSE/, $dse->get_value('objectclass'))
	{
		# openldap
		debug("server type: openldap");
		$type = 'openldap';
	}
	elsif (grep /o=NetscapeRoot/, $dse->get_value('namingcontexts'))
	{
		# iplanet/netscape
		debug("server type: iplanet");
		$type = 'iplanet';
	}
	else
	{
		error("I don't know your ldap server type, and thus can't look
up the schema.  Please email luke\@madstop.com with the ldap server type,
how to recognize it by searching with base='', and where to search to
get the schema (e.g., base='cn=schema').
");
		return $type;
	}

	return $type;
}
# serverType
##################################################################################

#------------------------------------------------------------------------------

####################################################################################
# getSchema
#
# pulls the schema from the ldap server
#
sub getSchema
{
	my (@ocs,%base,@entries,$dse,$type,);

	use vars qw($schema);

	if ($schema) { return $schema; }

	$base{'ldap'} = shift;
	$base{'filter'} = 'objectclass=*';
	$base{'scope'} = 0;

	$type = serverType($base{'ldap'}) or return;

	for ($type)
	{
		/iplanet/ and do
		{
			$base{'base'} = 'cn=schema';
			next;
		};
		/openldap/ and do
		{
			$base{'base'} = 'cn=subschema';
			next;
		};
		warn "Server type '$type' not understood.\n";
		return;
	}

	$base{'attrs'} = [qw(objectclasses attributetypes)];

	@entries = shellSearch(%base) or
		warn error("Could not find schema entry") and
		return;

	$schema = shift @entries;

	return $schema;
}
# getSchema
####################################################################################

=back

=head1 BUGS

See L<ldapsh>.

=head1 SEE ALSO

L<ldapsh>,
L<Net::LDAP>

=head1 AUTHOR

Luke A. Kanies, luke@madstop.com

=for html <hr>

I<$Id: Util.pm,v 1.4 2002/08/19 04:07:33 luke Exp $>

=cut

1;

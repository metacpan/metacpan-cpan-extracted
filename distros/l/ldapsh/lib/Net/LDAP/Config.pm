# configuration for ldap

package Net::LDAP::Config;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $AUTOLOAD $CONFIG);

=head1 NAME

Net::LDAP::Config - a simple wrapper for maintaining info related to LDAP
connections

=head1 SYNOPSIS

	my $config = Net::LDAP::Config->new('source' => 'default');
	$config->clauth(); # CLI authentation
	$config->bind(
		'dn' => $dn,
		'password' => $password
	); # normal authentation

=head1 DESCRIPTION

B<Net::LDAP::Config> is a wrapper module originally written
for B<ldapsh> but which is useful for much more.  It's not very well
documented just yet, but here are the main uses:

=head1 CONFIG FILE

The config file is a simple INI-style format.  There is one special section,
B<main>, and the only option it recognizes is B<default>, for specifying
the default source.  Any other sections specify an LDAP source.

For example:
	[ldap]
	servers: ldap1.domain.com,ldap2.domain.com
	base: dc=domain,dc=com
	ssl: require

	[main]
	default: ldap

A main config file is looked for in /etc/ldapsh_config and
/usr/local/etc/ldapsh_config, and then in the user's home directory, either
in the file specified by $LDAP_CONFIG or ~/.ldapsh_config.

=head1 CLI AUTHENTICATION

If you are building an interactive script, you'll want to use this method:

create the configuration object, which basically pulls the server
configuration from the config file
 my $config = Net::LDAP::Config->new('source' => 'mysource');

and then get all of the necessary info
this caches ldap UIDs in ~/.ldapuids

 $config->clauth();

=head1 NORMAL AUTHENTICATION

This is where you collect the DN and password and auth normally:

 my $config = Net::LDAP::Config->new('source' => 'mysource');
 $config->bind(
	'dn' => $dn,
	'password' => $password
 ); # normal authentation

If you don't want to authenticate, use B<connect>:

 my $config = Net::LDAP::Config->new('source' => 'mysource');
 $config->connect();

Yes, it sucks that there's a difference.  I'm still trying
to clean up the API.

You should probably just use B<bind>, as it behaves well
either with or without auth information.

=head1 ENVIRONMENT VARIABLES

Here are the environment variables that B<Net::LDAP::Config> uses:

=over 4

=item LDAP_UIDFILE

The file in which to store LDAP DN's.  Defaults to ~/.ldapuids.
This file is maintained automatically by B<Net::LDAP::Config>, although
you can modify it if you like -- it just caches the searched-for DN
so you don't have to specify your username each time.

Feel free to recommend a different design.

=item LDAP_CONFIG

A user-specific config file; over-rides any information in the central
file.  Defaults to ~/.ldapsh_config.

=back

=head1 FUNCTIONS

=over 4

=cut

#---------------------------------------------------------------
#---------------------------------------------------------------
# Code that everyone will use

#-----------------------------------------------------------------
# debug

=item debug

Can be used to turn debugging on (debug("on")) or off (debug("off")),
otherwise prints on STDERR anything passed to it if debugging is
currently on.

=cut

sub debug {
	if ($_[0]) {
		$_[0] =~ /^on$/i and do {
			warn "turning debug on\n";
			$Net::LDAP::DEBUG = 1;
			return;
		};
		$_[0] =~ /^off$/i and do {
			warn "turning debug off\n";
			$Net::LDAP::DEBUG = 0;
			return;
		};
	} else {
		return $Net::LDAP::DEBUG || 0;
	}
	unless ($Net::LDAP::DEBUG) { return; }
	if (@_) {
		warn "$0: @_\n";
	}
   return 1;
}
# debug
#-----------------------------------------------------------------

#-----------------------------------------------------------------
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

sub error {
	if (@_) {
	  $Net::LDAP::ERROR = join(' ', @_) . "\n";
	}

	if ($Net::LDAP::ERROR) {
	  return $Net::LDAP::ERROR;
	} else {
		return;
	}
}
# error
#-----------------------------------------------------------------

#---------------------------------------------------------------
#---------------------------------------------------------------
# Code related to command-line stuff

use strict;
use Exporter;

use vars qw($UIDFILE @ISA @EXPORT $VERSION);

@ISA = qw(Exporter);
@EXPORT = qw(
	CLIauth
);
$VERSION = 2.00;

$UIDFILE = $ENV{'LDAP_UIDFILE'} || glob("~/.ldapuids");

#-----------------------------------------------------------------
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# CLIauth

# command-line authentication routine
sub CLIauth {
	debug("Entering CLIauth");
	use Term::ReadKey;
	use Net::LDAP;

	#my ($pass,$dn,$uid,$UIDFILE,$active,$tmp,$server,$base,$tmpdn,$line);
	#my (%hash,$config->ldap'},$results,%args,$default);

	my (%args,$config,@clist,$tmp,$source,$var,$results,$active,$uid);
	my (%dns);

	if (@_) {
		$config = Net::LDAP::Config->new(@_) or die "Could not retrieve config\n";
	}

	# now we either have a server list or a defined source
	# now we need to try to get the user's login

	# retrieve the uids
	my (%uids,%cuids);
	%uids = getUids();

	# cache the existing uids, for later comparison, so we don't rewrite
	# the file unless it's changed
	%cuids = %uids;

	unless ($config->dn()) {
		if ($config->source()) {
			debug("source is " . $config->source());
			if (exists $uids{$config->source()}) {
				$config->dn($uids{$config->source()});
			}
		}

		debug("looking in servers for uid");
		if ($config->servers()) {
			foreach (@{ $config->servers() }) {
				if (exists $uids{$_} and $uids{$_}) {
					debug("uid from $_");
					$config->dn($uids{$_});
					last;
				}
			}
		}
	}

	# see if they passed one and not the other...
	if (! $config->dn() && $config->uid()) {
		$config->dn($config->uid());
	}

	print $config->dn(), "\n";

	# this tells whether they are piping to us or have an interactive session
	if (-t STDIN) {
		$active = '1';
	} else {
		$active = '0';
	}

	# no point in prompting if it's not interactive
	if ($active) {
		open INPUT, "/dev/tty";
		open OUTPUT, ">/dev/tty";
		while (! $config->dn()) {
			print OUTPUT "Username: ";
			#$uid = <INPUT>;
			#chomp $uid;
			$tmp = <INPUT>;
			chomp $tmp;
			$config->dn($tmp);
		}

		while (! $config->password()) {
			print OUTPUT "password: ";

			ReadMode('noecho');
			$tmp = <INPUT>;
			chomp $tmp;
			$config->password($tmp);
			ReadMode('normal');
			print OUTPUT "\n";
		}

		# if $config->uid() and $config->dn() disagree see if they want to overwrite .uid
		if (
			$config->uid() && 
			($config->dn() ne $config->uid()) && 
			($UIDFILE && -f $UIDFILE)
		) {
			print OUTPUT "Overwrite $UIDFILE? (y/[n])  ";
			chomp ($tmp = <INPUT>);
		}
		close INPUT;
		close OUTPUT;
	} else {
		if (! ( $config->dn() && $config->password()) ) {
			error("You must provide both a uid and a password.");
			exit(1);
		}
	}

	#unless ($config->dn() =~ /^uid=/)
	unless ($config->dn() =~ /^[a-z]+=/) {
		debug("dn not found...");
		$config->connect() or
			error("Could not connect to LDAP server " . $config->{'servers'}[0]), return;

		$config->filter("(uid=" . $config->dn() . ")");
		$results = $config->search();

		$results->code and error("CLIauth: ", $results->error()), return;

		if (my $entry = $results->pop_entry) {
			$config->dn($entry->dn() );
		} else {
			error("CLIauth: Could not find user" . $config->dn());
			return;
		}
	}

	my $ldap;
	until ($ldap = $config->ldap()) {
		debug("have all the info now...");
		$config->connect() or 
			error("Could not connect to LDAP server " . $config->server()) && return;
	}

	$results = $ldap->bind($config->dn(),'password' => $config->password());
	$results->code and 
		error("Invalid username (" . $config->dn(). ") or password.") && return;

	$config->ldap($ldap);
	# now we have successfully connected, so we know we have a valid DN
	# let's set it everywhere we can
	if ($config->source()) {
		#debug("setting uid for source");
		$uids{$config->source()} = $config->dn();
	}

	foreach (@{ $config->servers() }) {
		#debug("setting uid for $_");
		$uids{$_} = $config->dn();
	}

	# if they want to overwrite, or if they don't have the file, try to create it
	if (
			(
				(
					( $tmp && 
						($tmp =~ /^y/)
					) ||
					(! -f $UIDFILE)
				) && 
				$< != 0
			) ||
			join("", sort %uids) ne join("", sort %cuids)
		)
	{
		debug("writing uids");
		writeUids(%uids);
	}

	return $config;
}
# CLIauth
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# getUids
sub getUids {
	my (%uids,$line);
	if ($ENV{'HOME'}) {
		if (-f $UIDFILE) {
			open UID, "$UIDFILE" or do {
				error("Cannot read $UIDFILE; ignoring");
				next;
			};
			while ($line = <UID>) {
				my ($tmp1, $tmp2) = split /: /, $line;
				chomp $tmp2;
				$uids{$tmp1} = $tmp2;
			}
			close UID;
		}
	}

	return %uids;
}
# getUids
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# writeUids
sub writeUids {
	my %uids = @_;

	if (open UID, "> $UIDFILE") {
		foreach (keys %uids) {
			print UID "$_: $uids{$_}\n";
		}
		close UID;
	} else {
		error("Cannot overwrite $UIDFILE; skipping.");
		return;
	}
}
# writeUids
#-----------------------------------------------------------------

#---------------------------------------------------------------
#---------------------------------------------------------------

#---------------------------------------------------------------
#---------------------------------------------------------------
# stuff related to actually connecting to the server

#-----------------------------------------------------------------
# multiConnect

=item multiConnect

Connects to the first viable ldap server from a list or reference to
a list.

=cut

sub multiConnect {
	use Net::LDAP;
	debug("entering multiConnect");
	my ($ldap,@list,$host,%args,$sslcan,$ssl,$config,$source);

	if (ref $_[0] and ref $_[0] eq 'Net::LDAP::Config') {
		$config = shift;
	} else {
		%args = @_;

		# okay, see if we have a valid config...
		$config = Net::LDAP::Config->new(%args) or die "Invalid config.\n";
	}

	#map {print "$_ => $args{$_}\n"; } keys %args;

	unless ($config->servers() ) {
		$config->error("Failed to acquire a list of servers.");
		return;
	}

	@list = @{ $config->servers() };
	unless (@list) { error("No server list") && return; }
	debug("server list is [@list]");

	unless ($config->ssl()) {
		$config->ssl('none');
	}

	if (eval { require Net::LDAPS; } and ! $@)
	{
		debug("ssl capable");
		$sslcan = 1;
	} else {
		# nothing...
	} 

	for ($config->ssl) {
		/require/i and do {
			unless ($sslcan) {
				error("ssl is required but not possible");
				return;
			}
			$ssl = 1;
			next;
		};
		/prefer/i and do {
			if ($sslcan) {
				$ssl = 1;
			}
			next;
		};
		/none/i and do {
			$ssl = 0;
			next;
		};
		if ($sslcan) { $ssl = 1; }
	}
	#debug("ssl is $ssl");

	while (@list and ! $ldap) {
		$host = shift @list;
		if ($ssl and $sslcan) {
			debug("using ssl");
			$ldap = Net::LDAPS->new($host,) or next;
		} else {
			$ldap = Net::LDAP->new($host,) or next;
		}
	}
	if ($ldap) {
		$config->ldap($ldap);
		return $config;
=begin comment
		if (wantarray)
		{
			return (%$config);
		}
		else
		{
			return $ldap;
		}
=cut
	} else {
		return;
	}
}

# multiConnect
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# servers

=item servers

Allows developers to pick from a list of configured hosts,
or to get the list.

=cut

sub serverlist {
	unless ($Net::LDAP::Config::SERVERS) {
		die "Net::LDAP::Connect is not configured yet; either edit the
file manually, or run Net::LDAP::Connect::config.\n";
	}

	my (@return,$server);

	foreach $server (@_) {
		if (exists $Net::LDAP::Config::SERVERS->{$server} ) {
			push @return, $Net::LDAP::Config::SERVERS->{$server};
		}
	}
	if (@return) {
		if (wantarray) {
			return @return;
		} else {
			return shift @return;
		}
	} else {
		if (wantarray) {
			return keys %$Net::LDAP::Config::SERVERS;
		}
	}
}
# servers
#-----------------------------------------------------------------

#---------------------------------------------------------------
#---------------------------------------------------------------
# and here's the actual config code

#---------------------------------------------------------------
# AUTOLOAD
# until i see a reason to do it otherwise, I'm just going to autoload
# everything...
sub AUTOLOAD {
	my $func = &_compile;
	goto &$func;
}
# AUTOLOAD
#---------------------------------------------------------------

#---------------------------------------------------------------
# _compile
sub _compile {
	use vars qw($TEXT);

	$TEXT ||=
q[
	my $config = shift;
	if (@_) {
		$config->{$var} = shift;
	}

	if (wantarray and ref $config->{$var} eq 'ARRAY') {
		return @{ $config->{$var} };
	} elsif (wantarray and ref $config->{$var} eq 'HASH') {
		return %{ $config->{$var} };
	} else {
		return $config->{$var};
	}
];

	my ($func,$pack,$func_name);
	$func = $AUTOLOAD;
	$func=~/(.+)::([^:]+)$/;
	($pack,$func_name) = ($1,$2);

	if ($pack ne 'Net::LDAP::Config') {
		die "Cannot AUTOLOAD outside of Net::LDAP::Config\n";
	}

	eval 
"sub $func_name
{
	my \$var = '$func_name';
	$TEXT
}";

	return $func_name;
}
# _compile
#---------------------------------------------------------------

#---------------------------------------------------------------
# bind
sub bind {
	my $obj = shift;

	my $ldap;
	unless ($ldap = $obj->ldap()) {
		$obj->connect() or die "Could not connect to LDAP\n";
		$ldap = $obj->ldap();
	}

	my %args;

	if (@_) {
		%args = @_;
	}

	unless ($obj->anonymous()) {
		if (my $dn = $obj->dn()) {
			$args{'dn'} ||= $dn;
		}
		if (my $password = $obj->password()) {
			$args{'password'} ||= $password;
		}
	}

	$obj->{'bind'}++;
	return $obj->ldap()->bind(%args);
}
# bind
#---------------------------------------------------------------

#---------------------------------------------------------------
# clauth
sub clauth {
	my $obj = shift;
	$obj->debug("calling CLIauth");

	my $config = CLIauth($obj) || die error();


	$obj->debug("config is $config");
	$obj->{'connected'}++;
	return $config;
}
# clauth
#---------------------------------------------------------------

#---------------------------------------------------------------
# connect
sub connect {
	my $obj = shift;
	$obj->debug("calling multiConnect");

	if (my $config = multiConnect($obj)) {
		$obj->debug("config is $config");
		$obj->{'connected'}++;
		return $config;
	} else {
		warn $config->error, "\n";
		exit;
	}

}
# connect
#---------------------------------------------------------------

#---------------------------------------------------------------
sub loadconfig {
	my ($config,$ref) = @_;

	unless (-e $config) {
		die "You must create the config, currently set to: \n\t$config\n";
	}

	open CONFIG, $config or
		die "Could not open $config: $!\n";

	my ($group,$lineno);
	while (my $line = <CONFIG>) {
		$lineno++;
		for ($line) {
			/^#/ and do {
				next;
			};
			/^\s*$/ and do {
				next;
			};
			/^\[*(.+)\]/ and do {
				$group = $1;
				next;
			};
			/^([^:]+):\s+(.+)/ and do {
				unless ($group) {
					die "Invalid line at line $lineno:\n$line";
				}
				#warn "setting $1 to [$2] in $group\n";
				$ref->{$group}->{$1} = $2;
				next;
			};
			die "Invalid line in $config at line $lineno:\n$line";
		}
	}
	close CONFIG;
}
# loadconfig
#---------------------------------------------------------------

#---------------------------------------------------------------
sub init {
	# currently if all of these exist, they'll all be loaded; that's
	# probably okay...

	# the possible main configs
	my @mains;
	if ($_[0]) {
		push @mains, $_[0];
	}
	push @mains, "/etc/ldapsh_config", "/usr/local/etc/ldapsh_config";

	# the possible personal configs
	my @personals;
	if ($_[0]) {
		push @personals, $_[0];
	}
	push @personals, glob("~/.ldapsh_config");

	my %hash;
	my $loaded = 0;
	foreach my $config (@mains, @personals) {
		next unless $config;
		if (-e $config) {
			debug "loading $config\n";
			loadconfig($config,\%hash);
			$loaded++;
		} else {
			debug "No file $config\n";
		}
	}

	unless ($loaded) {
		warn "Could not find a configuration file.  Please create one of:\n\t" .
			join("\n\t",@mains,@personals) . "\n";
		exit(14);
	}

	# set up our default source
	if (exists $hash{'main'} and exists $hash{'main'}->{'default'}) {
		my $default = $hash{'main'}->{'default'};
		debug "default is $default\n";
		unless (exists $hash{$default}) {
			die "Could not find default source '$default'\n";
		}
		$hash{'default'} = $hash{$default};
	}

	delete $hash{'main'};

	# now fix the server stuff
	foreach my $source (keys %hash) {
		next if $source eq 'default';
		my $servers =	$hash{$source}->{'server'} ||
						$hash{$source}->{'servers'} ||
						"";

		delete $hash{$source}->{'server'};
		delete $hash{$source}->{'servers'};
		my (@servers,$pattern);
		if ($servers =~ /\s/) {
			@servers = split /\s/, $servers;
		} elsif ($servers =~ /,/) {
			@servers = split /,/, $servers;
		} else {
			# this should only be one server
			push @servers, $servers;
			#@servers = ($servers);
		}
		unless (@servers) {
			warn "No servers defined for source '$source'; skipping\n";
			delete $hash{$source};
			next;
		}

		$hash{$source}->{'servers'} = \@servers;
	}

	# this still just feels like a big hack, but that's probably okay...
	$Net::LDAP::Config::SOURCES = \%hash;

	return \%hash;
}
# init
#---------------------------------------------------------------

#---------------------------------------------------------------
# ldapsearch
sub ldapsearch {
	my $obj = shift;
	unless ($obj->ldap()) {
		return;
	}

	return $obj->ldap()->search(@_);
}
# ldapsearch
#---------------------------------------------------------------

#---------------------------------------------------------------
# new
# build our new config, based on either what is configured in
# the Sources modules, or what is passed in
sub new {
	my $class = shift;
	if (ref $_[0] eq 'Net::LDAP::Config') {
		return shift @_;
	}
	my $config = {};
	bless $config, $class;

	my ($source,%args,$var);
	%args = @_;

	# pull in the config file
	# this is what allows us to specify a different config file
	unless ($Net::LDAP::Config::SOURCES) {
		my @initargs;
		if (exists $args{'config'}) {
			push @initargs, $args{'config'};
		}
		init(@initargs);
	}

	use subs;
	# first pull in anything from the basic config
	if ($args{'source'}) {
		$source = $Net::LDAP::Config::SOURCES->{$args{'source'}} or die 
"Source '$args{source}' could not be found.  Please configure 
Net::LDAP::Sources appropriately.\n";

		# we just want to call the init for all known routines
		# it should be set up so that the variables stored also
		# have routines with the same name
		foreach $var (keys %$source) {
			#print "working on $var\n";
			my $value = eval { $config->$var($source->{$var}); };
			#print "value is $value from $source->{$var}\n";
			if ($@) {
				die "Option '$var' not valid.\n";
			}
		}
	}

	# then do any overrides based on stuff passed in
	foreach $var (keys %args) {
		eval { $config->$var($args{$var}); };
		if ($@) {
			die "Option '$var' not valid.\n";
		}
	}

	#if ($args{'bind') {
	#	$config->bind();
	#}
	# okay, at this point, we theoretically have a complete
	# config
	return $config;
}
# new
#---------------------------------------------------------------

#---------------------------------------------------------------
# search
sub search {
	my $obj = shift;
	unless ($obj->ldap()) {
		$obj->connect();
	}

	my %args = @_;

	my %hash;

	# we actually want to allow a null search base
	$hash{'base'} = $args{'base'} || $obj->base() || "";
	#unless ($hash{'base'} = $args{'base'} || $obj->base()) {
	#	warn "LDAP Search base is unset\n";
	#	return;
	#}

	unless ($hash{'filter'} = $args{'filter'} || $obj->filter()) {
		warn "LDAP Search filter is unset\n";
		return;
	}

	unless ($hash{'attrs'} = $args{'attrs'} || $obj->attrs()) {
		delete $hash{'attrs'};
	}

	return $obj->ldapsearch(%hash);
}
# search
#---------------------------------------------------------------

# $Id: Config.pm,v 1.4 2004/07/26 22:33:08 luke Exp $

1;

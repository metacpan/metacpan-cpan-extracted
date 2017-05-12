# -*- perl -*-

use strict;
use Config;

my $script = <<'END_OF_SCRIPT';
~startperl~ -w
#
#   ldapAdmin - A script for fixing the LDAP servers settings into
#               the system
#

use strict;

use Wizard::LDAP::Config ();
use Wizard::SaveAble::LDAP ();
use Getopt::Long ();
use Net::LDAP ();
use Net::Netmask ();
use IO::AtomicFile ();


############################################################################
#
#   Global variables
#
############################################################################

my $ETC_NAMED_CONF = "/etc/named.conf";
my $VAR_NAMED = "/var/named";
my $NDC_RELOAD = "/usr/sbin/ndc reload";

use vars qw($debug $verbose);

$ENV{'PATH'} = '/bin:/usr/bin'; # See "perldoc perlsec"
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

$> = $< = 0;


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print usage message and exit
#
############################################################################

sub Usage {
    print <<"EOF";
Usage: $0 <action> [options]

Read system settings from the LDAP server and fix them into the current
configuration.

Possible actions are:

  --prefs		Preferences have changes, read and fix everything.
			Implies --nets and --hosts.
  --nets        	Networks have changed, read and fix network and host
			settings. Implies --hosts.
  --hosts		Hosts have changed, read and fix host settings.
  --help		Print this message
  --add-user=<user>	Add the given user

Possible options are:

  --debug	Turn on debugging mode: Print what would have been done
		instead of really taking action. Implies --verbose.
  --verbose	Turn on verbose mode: Print all actions.
EOF
    exit 1;
}


############################################################################
#
#   Name:    LdapConnect
#
#   Purpose: Connect to the LDAP server
#
#   Inputs:  $prefs - LDAP wizard prefs
#
#   Returns: Net::LDAP object; dies in case of problems
#
############################################################################

sub LdapConnect {
    my $prefs = shift;
    my $server = $prefs->{'ldap-prefs-serverip'};
    my $port = $prefs->{'ldap-prefs-serverport'} || 0;
    my $ldap = Net::LDAP->new($server, 'port' => $port)
        or die "Failed to connect to LDAP server $server"
	    . ($port ? ":$port" : "") . ": $!";
    my $adminDN = $prefs->{'ldap-prefs-adminDN'};
    my $adminPassword = $prefs->{'ldap-prefs-adminPassword'};
    $ldap->bind('dn' => $adminDN, 'password' => $adminPassword)
        or die "Failed to bind as $adminDN: $!";
    $ldap;
}


############################################################################
#
#   Name:    AddUser
#
#   Purpose: Add a new user
#
#   Inputs:  $prefs - LDAP wizard prefs
#            $user - User being added
#
#   Returns: Nothing; exits in case of problems
#
############################################################################

sub AddUser {
    my($options, $prefs, $user) = @_;
    my $uidnumber = $options->{'uidnumber'};
    die "Invalid UID number: $uidnumber" unless $uidnumber =~ /^(\d+)$/;
    my $gidnumber = $options->{'gidnumber'};
    die "Invalid GID number: $gidnumber" unless $gidnumber =~ /^(\d+)$/;
    my $homedir = $options->{'homedir'};
    if (-d $homedir) {
	print STDERR "A directory $homedir already exists. Please decide\n";
	print STDERR "manually, what to do.\n";
	return;
    }

    print "Making directory $homedir\n" if $verbose;
    require File::Path;
    File::Path::mkpath([$homedir], 0, 0755)
	or die "Failed to create directory $homedir: $!";

    print "Making directory $homedir owned by $uidnumber.$gidnumber"
	if $verbose;
    system "chown", "-R", "$uidnumber.$gidnumber", $homedir unless $debug;
}


############################################################################
#
#   Name:    ItemList
#
#   Purpose: Read a list of items from the LDAP server
#
#   Inputs:  $prefs - LDAP wizard prefs
#	     $base - Base DN
#            $filter - Filter string
#
#   Returns: Array of items, aborts in case of trouble
#
############################################################################

sub ItemList {
    my($prefs, $base, $filter, $ldap) = @_;
    $ldap ||= LdapConnect($prefs);
    my $msg = $ldap->search('base' => $base, 'filter' => $filter,
			    'scope' => 1);
    die sprintf("Error while searching: code=%s, error=%s",
		$msg->code(), $msg->error())
        if $msg->code() and $msg->code() ne 32;
    ($ldap, $msg->entries());
}


############################################################################
#
#   Name:    MakeFile
#
#   Purpose: Generate a config file
#
#   Inputs:  $path - Path of the file being generated
#            $ci - Comment introducer
#            $here - Beginning and end of the automatically generated
#                    section
#            $sec - Automatically generated section
#            $template - Template file, in case the file needs to be
#                generated from scratch
#
#   Returns: Nothing, dies in case of trouble
#
############################################################################

sub MakeFile {
    my($path, $ci, $here, $sec, $template) = @_;
    my $fh = Symbol::gensym();
    my $rfile = $path;
    if (!-f $rfile) {
	$rfile = $template or die "No template for creating file: $path";
    }
    print "Reading contents for $path from $rfile.\n" if $verbose;
    open($fh, "<$rfile") or die "Failed to open $rfile: $!";
    local $/ = undef;
    my $contents = <$fh>;
    die "Failed to read $rfile: $!" unless defined($contents);
    close($fh);

    $sec = '' unless defined($sec);
    $sec = "$ci$here by $0 at " . scalar(localtime)
	. "\n$ci\DO NOT EDIT!\n$sec$ci$here\n";
    if ($contents !~ s/\Q$ci$here\E.*?\n(.*?)\Q$ci$here\E\n/$sec/s) {
	$contents .= $sec;
    }
    print "Creating $path:\n$contents" if $verbose;
    return if $debug;
    $fh = IO::AtomicFile->open($path, "w")
	or die "Failed to open $path for writing: $!";
    if (!$fh->print($contents)  ||   !$fh->close()) {
	my $msg = "Failed to write $path: $!";
	$fh->delete();
	die $msg;
    }
}


############################################################################
#
#   Name:    MakeNets
#
#   Purpose: Create a new list of networks
#
#   Inputs:  $o - Option list
#            $cfg - LDAP Prefs
#
#   Returns: Nothing, aborts in case of trouble
#
############################################################################

sub FindNets {
    my $o = shift;  my $cfg = shift;

    my($ldap, @entries) = ItemList($cfg, $cfg->{'ldap-prefs-netbase'},
                                   '(objectclass=*)');
    my %a_nets;
    my %ptr_nets;
    foreach my $e (@entries) {
	my $mask = Net::Netmask->new($e->get('mask'));
	my @nets = $mask->inaddr();
	while (@nets) {
	    my $ina = shift @nets;
	    my $firstip = shift @nets;
	    my $lastip = shift @nets;
	    $ptr_nets{$ina} = [];
	}
	my $domain = $e->get('domain');
        if (ref($domain)) {
	    foreach my $d (@$domain) {
	        $a_nets{$d} = [];
	    }
	} else {
	    $a_nets{$domain} = [];
	}
    }
    return { 'a_nets' => \%a_nets,
             'ptr_nets' => \%ptr_nets,
             'ldap' => $ldap,
             'entries' => \@entries
           };
}

sub MakeNets {
    my $result = FindNets(@_);

    my @zones = map { qq[zone "$_" {\n  type master;\n  file "db.$_";\n};\n] }
	            (keys %{$result->{'a_nets'}},
                     keys %{$result->{'ptr_nets'}});
    MakeFile($ETC_NAMED_CONF, "// ", "AUTOMATICALLY GENERATED",
	     join("", @zones));

    $result;
}


############################################################################
#
#   Name:    MakeHosts
#
#   Purpose: Create a new list of hosts
#
#   Inputs:  $o - Option list
#            $cfg - LDAP Prefs
#            $nets - MakeNets or FindNets result
#
#   Returns: Nothing, aborts in case of trouble
#
############################################################################

sub MakeHosts {
    my($o, $cfg, $nets) = @_;
    my $a_nets = $nets->{'a_nets'};
    my $ptr_nets = $nets->{'ptr_nets'};
    my $adminDN = $cfg->{'ldap-prefs-adminDN'};
    foreach my $e (@{$nets->{'entries'}}) {
	my $netname = $e->get('netname');
	my @netnames = ref($netname) ? @$netname : ($netname);
	foreach $netname (@netnames) {
	    my $dn = "network=$netname, $cfg->{'ldap-prefs-netbase'}";
	    my($ldap, @hosts) = ItemList($cfg, $dn, "(objectclass=*)",
					 $nets->{'ldap'});
	    foreach my $h (@hosts) {
	        my $name = $h->get('dnsname');
		my @names = ref($name) ? @$name : ($name);
		my $ip = $h->get('ip');
		my @ips = ref($ip) ? @$ip : ($ip);
		foreach $name (@names) {
		    my $found;
		    foreach my $a (sort {length $b <=> length $a}
				   keys %$a_nets) {
		        if ($name eq $a) {
			    $found = "$a.";
			} elsif ($name =~ /^(.*)\.$a$/) {
			    $found = $1;
			} else {
			  next;
			}
			push(@{$a_nets->{$a}}, map { ($found, $_) } @ips);
			last;
		    }
		}
		foreach $ip (@ips) {
		    next unless ($ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/);
		    my $inarpa = "$4.$3.$2.$1.in-addr.arpa";
		    foreach my $ptr (keys %$ptr_nets) {
		        if ($inarpa =~ /(.*)\.$ptr$/) {
			    push(@{$ptr_nets->{$ptr}},
				 map { ($1, "$_.") } @names);
			    last;
			}
		    }
		}
	    }
	}
    }

    foreach my $a (keys %$a_nets) {
	my @list = @{$a_nets->{$a}};
	my $hosts;
	while (@list) {
	    my $name = shift @list;
	    my $ip = shift @list;
	    $hosts .= "$name\t\tIN A $ip\n";
	}
	MakeFile("$VAR_NAMED/db.$a", "; ", "AUTOMATICALLY GENERATED", $hosts,
		 "$VAR_NAMED/db.hosts.template");
    }

    foreach my $ptr (keys %$ptr_nets) {
	my @list = @{$ptr_nets->{$ptr}};
	my $hosts;
	while (@list) {
	    my $ip = shift @list;
	    my $name = shift @list;
	    $hosts .= "$ip\t\tIN PTR $name\n";
	}
	MakeFile("$VAR_NAMED/db.$ptr", "; ", "AUTOMATICALLY GENERATED", $hosts,
		 "$VAR_NAMED/db.ips.template");
    }
 
    print "Restarting named: $NDC_RELOAD\n" if $verbose;
    system $NDC_RELOAD unless $debug;
}


############################################################################
#
#   This is main()
#
############################################################################

eval {
    my $pfile = $Wizard::LDAP::Config::config->{'ldap-prefs-file'};
    my $cfg = eval { require $pfile }
        or die "Failed to read LDAP prefs from $pfile: $@";

    my %o = (
	'debug' => \$debug,
	'verbose' => \$verbose
    );
    Getopt::Long::GetOptions(\%o, 'debug', 'help', 'hosts', 'nets', 'prefs',
			     'add-user=s', 'homedir=s', 'uidnumber=i',
			     'gidnumber=i', 'verbose');
    $verbose = 1 if $debug and not $verbose;

    if ($o{'help'}) {
	Usage();
    } elsif ($o{'prefs'}) {
	MakePrefs(\%o, $cfg);
	my $nets = MakeNets(\%o, $cfg);
	MakeHosts(\%o, $cfg, $nets);
    } elsif ($o{'nets'}) {
	my $nets = MakeNets(\%o, $cfg);
	MakeHosts(\%o, $cfg, $nets);
    } elsif ($o{'hosts'}) {
	my $nets = FindNets(\%o, $cfg);
	MakeHosts(\%o, $cfg, $nets);
    } elsif (my $user = $o{'add-user'}) {
	AddUser(\%o, $cfg, $user);
    } else {
	Usage();
    }
};

if (my $msg = $@) {
    print STDERR $@;
    eval {
        require Sys::Syslog;
        Sys::Syslog::openlog("ldapAdmin", "cons,pid", "mail");
        Sys::Syslog::setlogsock('unix')
            if (defined(&Sys::Syslog::setlogsock)  and
                defined(&Sys::Syslog::_PATH_LOG));
        Sys::Syslog::syslog('err', $msg);
    }
}

__END__

=pod

=head1 NAME

ldapAdmin - Helper tool for the Wizard::LDAP module


=head1 SYNOPSIS

  # Create a home directory
  ldapAdmin --add-user=<user> --uidnumber=<uid> --gidnumer=<gid> \
	    --homedir=<dir>


=head1 DESCRIPTION

This script is created for adjusting the system to the LDAP wizards
settings.


=head1 SEE ALSO

Wizard::LDAP

=cut
END_OF_SCRIPT

$^W = 1;
$script =~ s/\~(\w+)\~/$Config::Config{$1}/sg;

(open(FILE, ">ldapAdmin")  and
 (print FILE $script)      and
 close(FILE))  or die "Failed to create ldapAdmin: $!";
chmod 0755, "ldapAdmin" or die "Failed to set mode of ldapAdmin: $!";

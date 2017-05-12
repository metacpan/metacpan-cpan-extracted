# $Id: install.pl,v 1.15 2004/09/14 09:08:40 joern Exp $

require 5.004_04;

use strict;
use Getopt::Std;
use lib "lib";
use Cwd;
use Term::Cap;
use Config;
use NewSpirit;

BEGIN {
	$NewSpirit::install_pl = 1;
	require "etc/tmpl-newspirit.conf";
	eval { require "etc/newspirit.conf" };
}

$| = 1;

my $VERBOSE = 0;

main: {
	hello();

	my %opts;
	my $ok = getopts ('lpvc:h:b:s:V:', \%opts);

	$VERBOSE = 1 if $opts{v};

	usage() unless $ok;

	print "Checking prerequisites:\n";

	check_manifest();
	check_modules();

	configure(
		dont_ask     => $opts{c} && $opts{h},
		cgi_url      => $opts{c} || $CFG::cgi_url,
		htdocs_url   => $opts{h} || $CFG::htdocs_url,
		ldap_enabled => $opts{l} || $CFG::ldap_enabled,
		ldap_base    => $opts{b} || $CFG::ldap_base,
		ldap_server  => $opts{s} || $CFG::ldap_server,
		ldap_uid     => $opts{u} || $CFG::ldap_uid,
		ldap_version => $opts{V} || $CFG::ldap_version,
	);

	create_passwd(
		force => $opts{p}
	);
	
	set_file_modes() if not $CFG::OS;
	set_shebang();

	thanks();
}

sub message {
	my ($msg) = @_;
	
	print "- $msg... ";
}

sub message_ok {
	print "$_[0]Ok\n";
}

sub message_not_ok {
	print "$_[0]NOT Ok\n";
}

sub usage {
	print <<__EOF;
usage: perl install.pl [-p] [-v] [-c cgi-alias] [-h htdocs-alias]

       -p    force etc/passwd creation with spirit standard
             account
       -v    verbose
       -c    takes default value for CGI webserver mapping
       -h    takes default value for htdocs webserver mapping

       -l    enable LDAP account validation
       -s    LDAP server
       -b    LDAP search base
       -u    LDAP uid attribute
       -V    LDAP protocol version (1 or 2)
       
       If -c and -h are given, installation is non interactive.

__EOF
	exit 1;
};

sub hello {
	if ( $CFG::OS == 0 ) {
		# this does not work with ActiveState Perl Build 519
		my $term = Term::Cap->Tgetent({ TERM => undef, OSPEED => 9600 });
		$term->Tputs('cl',1, \*STDOUT);
	}

	my $blanks = " " x (46-length($CFG::VERSION));
	my @d = localtime(time);
	my $year = $d[5]+1900;	# shit, we have a year 10000 problem!

	print <<__EOF;
+----------------------------------------------------------------------+
| new.spirit - $CFG::VERSION Installer$blanks|
| Copyright (c) 1997-$year dimedis GmbH, All Rights Reserved            |
+----------------------------------------------------------------------+
| new.spirit is free Perl software; you can redistribute it and/or     |
| modify it under the same terms as Perl itself. By installing this    |
| software you accept one of the licenses located in the "license"     |
| directory of this distribution (Artistic or Gnu Public License).     |
+----------------------------------------------------------------------+

__EOF
}

sub thanks {
	print <<__EOF;

new.spirit was successfully installed. Please ensure
that your webserver is configured with the mappings
you entered. If you use the Apache webserver, you can
simply add these parameters to your httpd.conf file:

  Alias       $CFG::htdocs_url $CFG::root_dir/htdocs
  ScriptAlias $CFG::cgi_url $CFG::root_dir/cgi-bin

Point your browser to this URL for further documentation:

  http://localhost$CFG::htdocs_url/doc/

And don't forget to have fun with new.spirit... ;)


Information for spirit 1.x upgraders:
-------------------------------------

If you are uprading from a spirit 1.x installation, you
can use bin/convert_from_spirit1x.pl to import your
user account and project informationen into your new
new.spirit 2.x system. Your spirit 1.x files are not
touched through this procedure.

ATTENTION:  But if you access spirit 1.x objects with
----------  new.spirit 2.x they will be converted on
	    the fly. They are not accessible through
	    spirit 1.x anymore after this conversion!

__EOF
}

sub create_passwd {
	my %par = @_;
	
	my $force = $par{force};
	
	if ( $force or not -f $CFG::passwd_file ) {
		message ("creating new $CFG::passwd_file");
		unlink $CFG::passwd_file;
		require "NewSpirit/Passwd.pm";
		NewSpirit::LKDB->set_db_module($CFG::db_module);
	        my $p = new NewSpirit::Passwd;
	        $p->add ('spirit', 'spirit', {PROJECT=>1,USER=>1},{});
		message_ok();
	} else {
		message ("file $CFG::passwd_file exists (-p forces recreation)");
		message_ok();
	}
}

sub set_file_modes {
	my %par = @_;
	
	message("setting file modes");
	
	my $files = require "etc/filemodes.conf";
	$files->{"./etc/passwd"} = 33204;

	foreach my $file ( sort keys %{$files} ) {
		$VERBOSE && print "$file: $files->{$file}\n";
		chmod $files->{$file}, $file;
	}
	
	!$VERBOSE && message_ok();
}

sub set_shebang {
	my %par = @_;
	
	message ("setting shebang line");
	
	my @files;
	find (
		sub {
			return if not -f $_;
			return if not /\.(pl|cgi)$/;
			push @files, "$File::Find::dir/$_";
		},
		"."
	);
	
	my $shebang = "#!$Config{perlpath}";
	
	foreach my $file ( @files ) {
		print "$file...\n";
		open (SCRIPT, $file)
			or die "can't read $file";
		my $text = join '', <SCRIPT>;
		close SCRIPT;
		
		$text =~ s/^#\!.*/$shebang/;
		
		open (SCRIPT, "> $file")
			or die "can't write $file";
		print SCRIPT $text;
		close SCRIPT;
	}
	
	message_ok();

	1;
}

sub check_modules {
	my $modules = require "etc/perl-modules.conf";
	
	message("checking for Perl modules");
	$VERBOSE && print "\n";
	
	my @missing;
	
	foreach my $module ( sort keys %{$modules} ) {
		$VERBOSE && print "\t$module... ";
		eval "use $module";
		if ( $@ ) {
			push @missing, $module;
			$VERBOSE && message_not_ok();
		} else {
			$VERBOSE && message_ok();
		}
	}
	
	if ( not $VERBOSE ) {
		@missing ? message_not_ok() : message_ok();
	}
	
	if ( @missing ) {
		print "\n";
		print "Please install the following modules and\n";
		print "execute 'perl install.pl' again.\n\n";
		print "  ", join (" ", @missing);
		print "\n\n";
		exit 1;
	}
	
	# warn if installed CIPP version is older than shipped version
	my @files = sort @{NewSpirit::filename_glob (
		dir => "$CFG::perlmodules_dir",
		regex => "CIPP.*"
	)};
	
	my $last = @files[@files-1];
	$last =~ /CIPP-(\d+\.\d+(_\d+)?)/;
	my $last_version = $1;
	
	if ( $last_version > $CIPP::VERSION ) {
		print "\n";
		my $answer = ask (
			text => "Warning! Installed CIPP version $CIPP::VERSION is older than\n".
			        "shipped version $last_version. You should install the package\n\n".
				"$last first.\n\n".
				"Type 'ignore' to ignore this warning an proceed",
			default => 'exit',
		);
		
		exit 1 if $answer ne 'ignore';
	}
}

sub check_manifest {
	open (MAN, "MANIFEST") or die "can't read MANIFEST";
	
	message ("checking whether distribution is complete");
	
	my @missing;
	while (<MAN>) {
		chomp;
		push @missing, $_ if not -r $_;
	}
	close MAN;
	
	if ( @missing ) {
		message_not_ok();
		print "\n\nThe following files are missing:\n\n";
		print "\t", join ("\t\n", @missing), "\n\n";
		exit 1;
	} else {
		message_ok();
	}
}

sub configure {
	my %par = @_;
	
	my $dont_ask     = $par{dont_ask};
	my $cgi_url      = $par{cgi_url};
	my $htdocs_url   = $par{htdocs_url};
	my $ldap_enabled = $par{ldap_enabled};
	my $ldap_base    = $par{ldap_base};
	my $ldap_server  = $par{ldap_server};
	my $ldap_uid     = $par{ldap_uid};
	my $ldap_version = $par{ldap_version};

	my $root_dir = cwd();

	# first check for a usable database module,
	# if not already configured

	my $db_module = $CFG::db_module;

	my $db_module_msg_printed;
	
	if ( not $db_module ) {
		message("determine installed flat file database modules");
		$db_module_msg_printed = 1;
	}

	$db_module ||= eval 'use GDBM_File; "GDBM_File"';
	$db_module ||= eval 'use DB_File;   "DB_File"';
	$db_module ||= eval 'use SDBM_File; "SDBM_File"';

	if ( not $db_module ) {
		message_not_ok();
		print "\n";
		print "Error: Please install one of the following modules:\n";
		print "GDBM_File, DB_File, SDBM_File\n\n";
		exit 1;
	}

	# now set configuration variable to $db_module,
	# so create_passwd() works allready with the
	# this module.
	
	$CFG::db_module = $db_module;

	$db_module_msg_printed && message_ok();
	
	message ("flat file database module is: '$db_module'");
	message_ok();

	# now ask for mappings, if not provided on command line
	
	if ( not $dont_ask ) {
		print "\n";
		print "Please specify the URLs you configured to access\n";
		print "the htdocs and cgi-bin directories:\n";
		print "(Press the enter key to accept the default value)\n\n";
	
		$htdocs_url = ask (
			text => "Webserver Alias for ./htdocs",
			default => $htdocs_url
		);
		
		$cgi_url = ask (
			text => "Webserver Script Alias for ./cgi-bin",
			default => $cgi_url
		);
		
		print "\n";
		print "new.spirit can use an existing LDAP directory for\n";
		print "user account validation. You will need Net::LDAP\n";
		print "for this functionality.\n\n";
		
		$ldap_enabled = ask (
			text    => "Do you want do use the LDAP account validation?",
			default => ($ldap_enabled ? 'y' : 'n'),
			answers => { 'y' => 1, 'n' => 0 },
		);
		
		$ldap_server = ask (
			text    => "LDAP server name",
			default => $ldap_server
		);
		
		$ldap_base   = ask (
			text    => "LDAP search base",
			default => $ldap_base,
		);
		
		$ldap_uid    = ask (
			text    => "LDAP username attribute",
			default => $ldap_uid
		);
		
		$ldap_version = ask (
			text    => "LDAP protocol version",
			default => $ldap_version,
			answers => { 1 => 1, 2 => 2 },
		);

		print "\n";

		my $try = ask (
			text    => "Should the installer now try to connect the\nserver with these values?",
			default => 'n',
			answers => { 'y' => 1, 'n' => 0 },
		);
		
		if ( $try ) {
			print "\n";
			require "Net/LDAP.pm";

			my $username = ask (
				text    => "Enter a username to search for",
			);

			my $ldap = Net::LDAP->new (
				$ldap_server,
				onerror => 'die',
				version => $ldap_version,
			) or die "$@";

	        	$ldap->bind;
			
			# search uid (we need the dn)
	        	my $result = $ldap->search (
				base   => $ldap_base,
				filter => "$ldap_uid=$username"
			);

			die "username ambigious" if $result->count > 1;
			die "username not found" if $result->count == 0;

			# catch dn
			my $entry = $result->shift_entry;
			my $dn = $entry->dn;
			
			$ldap->unbind;
			
			print "\nIt works! DN of this user: $dn\n";
		}
	}
	
	# cut off trailing slashes
	$htdocs_url =~ s,/$,,;
	$cgi_url    =~ s,/$,,;
	
	print "\n";
	print "Configuration:\n";
	print "--------------\n";
	print "htdocs alias:   $htdocs_url\n";
	print "cgi-bin alias:  $cgi_url\n";
	print "db module:      $db_module\n";
	print "root directory: $root_dir\n";
	
	if ( not $ldap_enabled ) {
		print "LDAP:           disabled\n";
	} else {
		print "LDAP:           enabled\n";
		print "LDAP server:    $ldap_server\n";
		print "LDAP base:      $ldap_base\n";
		print "LDAP uid attr:  $ldap_uid\n";
		print "LDAP version:   $ldap_version\n";
	}

	print "\n";
	
	if ( not $dont_ask ) {
		print "Press Enter to proceed with these values, otherwise\n";
		print "press Ctrl+C to cancel the operation! ";
		<STDIN>;
		print "\n";
	}
	
	$CFG::root_dir   = $root_dir;
	$CFG::cgi_url    = $cgi_url;
	$CFG::htdocs_url = $htdocs_url;
	$CFG::db_module  = $db_module;

	message ("creating new 'etc/newspirit.conf'");
	
	create_conf_from_template (
		from => "etc/tmpl-newspirit.conf",
		to => "etc/newspirit.conf",
		values => {
			root_dir => $root_dir,
			cgi_url => $cgi_url,
			htdocs_url => $htdocs_url,
			db_module => $db_module,
			ldap_enabled => $ldap_enabled,
			ldap_server => $ldap_server,
			ldap_base => $ldap_base,
			ldap_uid => $ldap_uid,
			ldap_version => $ldap_version,
		}
	);
	
	message_ok();
	
	create_index_html("htdocs/index.html");
}

sub create_index_html {
	my ($filename) = @_;
	
	message ("creating '$filename'");
	
	open (OUT, "> $filename") or die "can't write $filename";
	print OUT <<__EOF;
<HTML>
<HEAD>
<TITLE>$CFG::window_title</TITLE>
<FRAMESET COLS="100%,*" FRAMEBORDER=NO BORDER=0>
  <FRAME NAME="NEWSPIRIT" SRC="$CFG::cgi_url/admin.cgi">
</FRAMESET>
</HEAD>
</HTML>
__EOF
	close OUT;

	message_ok();
}

sub create_conf_from_template {
	my %par = @_;
	
	my $from   = $par{from};
	my $to     = $par{to};
	my $values = $par{values};
	
	open (FROM, "$from") or die "can't read $from";
	open (TO, "> $to") or die "can't write $to";
	
	while (<FROM>) {
		if ( /;\s+#--(.*)--#/ ) {
			print TO "\t" if $1 eq 'root_dir';
			print TO "\$$1 = '$values->{$1}'; #--$1--#\n";
		} else {
			print TO $_;
		}
	}
	
	close FROM;
	close TO;
}

sub ask {
	my %par = @_;
	
	my $text = $par{text};
	my $default = $par{default};
	my $answers = $par{answers};

	my $answers_text;
	if ( $answers ) {
		$answers_text = join ("', '", keys %{$answers});
		$answers_text = "('$answers_text') ";
	}

	my $value;
	while (1) {
		print "$text $answers_text\[ '$default' ] : ";
		$value = <STDIN>;
		chomp $value;
		$value ||= $default;
		last if not $answers;
		last if defined ($value = $answers->{$value});
	}
		
	return $value;
}

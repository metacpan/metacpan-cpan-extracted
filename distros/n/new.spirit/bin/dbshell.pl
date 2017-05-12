#!/usr/dim/perl/5.8/bin/perl

# $Id: dbshell.pl,v 1.22 2004/11/09 13:44:34 joern Exp $

use strict;
use Getopt::Std;
use DBI;
use Carp;
use File::Basename;

my $STATIC;

my $newspirit_home;
BEGIN {
	$STATIC = 0;
	if ( not $STATIC ) {
		$newspirit_home = $ENV{NEWSPIRIT_HOME} ||
			  "/usr/projects/newspirit2";
		unshift @INC, "$newspirit_home/lib";
		eval {
			require "NewSpirit/SqlShell/Text.pm";
		};
		if ( $@ =~ /Can't locate/i ) {
			print "\n";
			print "ERROR: Unable to load module NewSpirit::SqlShell::Text\n";
			print "       Please install this module or set the environment\n";
			print "       variable NEWSPIRIT_HOME to the installation path\n";
			print "       of new.spirit\n\n";
			exit 1;
		} elsif ( $@ ) {
			die $@;
		}
	}
}

my $VERSION = "0.12";
my $USAGE;

if ( $STATIC ) {
	$USAGE =<<__EOF;

dbshell.pl Version $VERSION - Copyright 2001-2004 (c) dimedis GmbH, Cologne, Germany

usage: dbshell.pl [-s] [-e] [-x] [-u username] [-p password] DBI-Data-Source
       dbshell.pl [-s] [-e] [-x] new.spirit-db-config-file
       dbshell.pl [-s] [-e] [-x] new.spirit-sql-prod-file

       -e      echo sql statements
       -s      print error summary on exit
       -x      abort on error

       In a new.spirit production environment (where no sources
       are available) you can pass a new.spirit-sql-prod-file
       (located in the prod/sql folder) or a new.spirit-db-config-file
       (located in the prod/config folder). dbshell.pl will then
       connect to the database using the according configuration
       information in prod/config. A new.spirit-sql-prod-file will
       be executed.
       
       The exit code is 0 on success and 1 if a statement fails.
__EOF
} else {
	$USAGE =<<__EOF;

dbshell.pl Version $VERSION - Copyright 2001-2002 (c) dimedis GmbH, Cologne, Germany

usage: dbshell.pl [-s] [-u username] [-p password] [-x] DBI-Data-Source
       dbshell.pl [-s] [-e] [-x] new.spirit-Database-Object
       dbshell.pl [-s] [-e] [-x] new.spirit-SQL-Object
       dbshell.pl [-s] [-e] [-x] new.spirit-db-config-file
       dbshell.pl [-s] [-e] [-x] new.spirit-sql-prod-file

       -e      echo sql statements
       -s      print error summary on exit
       -x      abort on error

       If you pass a new.spirit-Database-Object, its information
       is used for connecting the database. If you pass a
       new.spirit-SQL-Object, the program will connect to the
       according database and the SQL code of the object is
       executed.
       
       In a new.spirit production environment (where no sources
       are available) you can pass a new.spirit-sql-prod-file
       (located in the prod/sql folder) or a new.spirit-db-config-file
       (located in the prod/config folder). dbshell.pl will then
       connect to the database using the according configuration
       information in prod/config. A new.spirit-sql-prod-file will
       be executed.
       
       The exit code is 0 on success and 1 if a statement fails.
__EOF
}

$| = 1;

main: {
	my %opts;
	my $ok = getopts ('xesu:p:', \%opts);
	
	my $db_info = shift @ARGV;
	
	if ( not $ok or not $db_info or @ARGV ) {
		print $USAGE;
		exit 1;
	}

	eval {
		db_shell_main (
			opts_href => \%opts,
			db_info   => $db_info
		);
	};

	exception (message => $@) if $@;
}

sub db_shell_main {
	my %par = @_;
	
	my $db_info = $par{db_info};
	my $opts    = $par{opts_href};
	
	print STDERR "dbshell.pl Version $VERSION, Copyright 2000 dimedis GmbH, All Rights Reserved\n\n";
	
	if ( $db_info =~ /^dbi/ ) {
		db_shell (
			username   => $opts->{u},
			password   => $opts->{p},
			source     => $db_info,
			print_error_summary => $opts->{s},
			opts_href  => $opts,
		);
	} elsif ( $db_info =~ /\.(sql|db-conf)$/  ) {
		db_shell (
			get_newspirit_prod_db_conf (
				db_object => $db_info
			),
			print_error_summary => $opts->{s},
			opts_href  => $opts,
		);
	} elsif ( not $STATIC) {
		db_shell (
			get_newspirit_src_db_conf (
				db_object => $db_info
			),
			print_error_summary => $opts->{s},
			opts_href  => $opts,
		);
	} else {
		print STDERR "Unknown file parameter.\n\n";
		exit 1;
	}
}

sub exception {
	my %par = @_;
	
	my $message = $par{message};
	
	$message =~ s/ at .*?line\s*\d+\.//;
	
	print "Exception: $message\n\n";
	exit 1;
}

sub info {
	print join ("\n",@_),"\n";
}

sub get_newspirit_src_db_conf {
	my %par = @_;
	
	my $db_object = $par{db_object};
	my $project = $db_object;
	$project =~ s/\..*//;
	$db_object =~ s/.*?\.//;
	$db_object =~ s!\.!/!g;

	eval {
		require "NewSpirit/Object.pm";
		require "$newspirit_home/etc/newspirit.conf";
		require "$newspirit_home/etc/objecttypes.conf";
	};
	if ( $@ ) {
		print "ERROR: Unable to load new.spirit modules and/or configuration!\n";
		print "       You must have new.spirit installed for connecting to a\n";
		print "       database via a new.spirit database configuration object!\n";
		print "\n";
		print "The error message was:\n$@\n";
		exit 1;
	}
	
	my $cgi = bless {
		ticket   => 'dummy',
		username => 'dummy',
		project  => $project
	}, "MyCGI";

	my $db_obj;
	
	# try to treat the object as a database configuration
	eval {
		$db_obj = new NewSpirit::Object (
			q => $cgi,
			object => $db_object.".cipp-db"
		);
	};

	# otherwise try treating it as a SQL object
	$@ && eval {
		$db_obj = new NewSpirit::Object (
			q => $cgi,
			object => $db_object.".cipp-sql"
		);
	};
	
	if ( $@ ) {
		print STDERR "Can't find a new.spirit DB or SQL object with this name!\n\n";
		exit 1;
	}
	
	if ( $db_obj->{object_type} eq 'cipp-sql' ) {
		# Ok, we have a SQL Object. Lets determine its
		# database configuration object
		my $sql_obj = $db_obj;

		my $meta = $db_obj->get_meta_data;
		
		my $db_obj_name = $meta->{sql_db};
		
		if ( $db_obj_name eq '__default' ) {
			$db_obj_name = $db_obj->get_default_database;
		}
		
		$db_obj = new NewSpirit::Object (
			q => $cgi,
			object => $db_obj_name
		);
		
		# now connect the SQL object file to STDIN
		close STDIN;
		open (STDIN, $sql_obj->{object_file})
			or croak "can't read SQL object file '$sql_obj->{object_file}'";
	}
	
	my $db_data = $db_obj->get_data;

	# set database environment

	my %OLD_ENV = %ENV;

	my @env = split (/\r?\n/, $db_data->{db_env});
	foreach my $env (@env) {
		my ($k,$v) = split (/\s+/, $env, 2);
		$ENV{$k} = $v;
	}

	# decode the password
	my $pass;
	{
		# strange workaround. without this block the
		# regex of NewSpirit::SqlShell::next_command
		# will result in this $1 if no match is found
		( $pass = $db_data->{db_pass} )=~
			s/%(..)/chr(ord(pack('C', hex($1)))^85)/eg;
	}
		
	return (
		username => $db_data->{db_user},
		password => $pass,
		source   => $db_data->{db_source}
	);
}

sub get_newspirit_prod_db_conf {
	my %par = @_;
	
	my $db_object = $par{db_object};
	
	my $db_config_file;
	if ( $db_object =~ /sql$/ ) {
		my $db_info_file = $db_object;
		$db_info_file =~ s/\.sql$//;
		$db_info_file .= ".db";
	
		open (DBINFO, $db_info_file) or croak "can't read $db_info_file";
		$db_config_file = <DBINFO>;
		chomp $db_config_file;
		close DBINFO;
	
		$db_config_file = dirname($db_object)."/".$db_config_file;
		
		# connect sql file to STDIN
		close STDIN;
		open (STDIN, $db_object) or croak "can't read $db_object";
	} else {
		$db_config_file = $db_object;
	}
	
	open (DBCONFIG, $db_config_file) or croak "can't read '$db_config_file'";
	my $config = join ('', <DBCONFIG>);
	close DBCONFIG;
	
	$config =~ s/::cipp.*?::/::/g;
	my $cipp3_config = eval $config;
	croak "can't eval config: $@" if $@;

	if ( ref $cipp3_config ) {
		return (
			username => $cipp3_config->{user},
			password => $cipp3_config->{password},
			source   => $cipp3_config->{data_source},
		);
	}

	return (
		username => $CIPP_Exec::user,
		password => $CIPP_Exec::password,
		source   => $CIPP_Exec::data_source,
	);
}

sub db_shell {
	my %par = @_;
	
	my $username            = $par{username};
	my $password            = $par{password};
	my $source              = $par{source};
	my $print_error_summary = $par{print_error_summary};
	my $opts_href           = $par{opts_href};

	# build prompt label
	$source =~ /^dbi:(\w+)/;
	my $driver = $1;
	$source =~ /^dbi:\w+:(\w*)$/;
	my $db = $1;

	my $selected_db = $db?$db:$driver;
	
	my $lf;
	if ( $username eq '' ) {
		$username = ask (
			label => "Username",
		);
		$lf = 1;
	}
	
	if ( $password eq '' ) {
		$password = ask (
			label => "Password",
			invisible => 1
		);
		$lf = 1;
	}

	print "\n" if $lf;

	my $get_line_cb;
	
	my $shell;
	my $initialize_history;
	my $term;
	
	my $rl_package;
	if ( -t STDIN ) {
		# we're connected to a TTY, so install
		# a Term::Readline input handler
		require "Term/ReadLine.pm";
		$term = new Term::ReadLine 'dbshell';
		
		$rl_package = $term->ReadLine;
		if ( $rl_package eq 'Term::ReadLine::Perl' ) {
			$readline::rl_completion_function = 'main::perl_rl_completion';
		} elsif ( $rl_package eq 'Term::ReadLine::Gnu' ) {
			my $attribs = $term->Attribs;
			$attribs->{'attempted_completion_function'} = undef;
			$attribs->{'completion_entry_function'} = undef;
			$attribs->{'list_completion_function'} = undef;
		}

		$get_line_cb = sub {
			print "\n" if $shell->{command_completed};
			$shell->{command_completed} = 0;
			my $line = $term->readline (
				$shell->{username}.'@'.
				$shell->{selected_db}."> "
			);
			print "> $line" if $opts_href->{e};
			add_line_to_history ($line) if $line;
			print "\n" if not defined $line;
			return $line;
		};
		
		$initialize_history = 1;
		
	} else {
		# no TTY, so simply read from STDIN without
		# giving a prompt
		$get_line_cb = sub {
			my $line = <STDIN>;
			print "> $line" if $opts_href->{e};
			return $line;
		}
	}
	
	$shell = new NewSpirit::SqlShell::Text (
		source      => $source,
		username    => $username,
		password    => $password,
		selected_db => $selected_db,
		autocommit  => 1,
		echo        => 0,
		get_line_cb => $get_line_cb,
		preference_file => home_dir()."/.dbshell_prefs"
	);

	$shell->{abort_mode} = $opts_href->{x};

	if ( $initialize_history ) {
		$shell->info ("Initializing command history");
		initialize_history (
			$term, $shell->get_preference('history_size')
		) 
	}

	if ( $rl_package eq 'Term::ReadLine::Stub' ) {
		$shell->info ("WARNING: Only stub ReadLine support available.",
	        	      "Install Term::ReadLine::Gnu or Term::ReadLine::Perl",
			      "to get enhanced ReadLine support!")
	} elsif ( $rl_package ) {
		$shell->info ("ReadLine support activated using module '$rl_package'");
	}

	$shell->loop;

	print "\n" if $opts_href->{e};

	$shell->error_summary if not $shell->{abort_mode} and
	                         $print_error_summary;

	exit $shell->has_errors;
}

sub perl_rl_completion {
	my ($input) = @_;
	return $input." ";
}

sub ask {
	my %par = @_;
	
	my $label     = $par{label};
	my $invisible = $par{invisible};
	
	if ( $invisible ) {
		eval "use Term::ReadKey";
		ReadMode(2);
	}
	
	print "$label: ";
	my $input = <STDIN>;
	chomp $input;
	
	if ( $invisible ) {
		ReadMode(0);
		print "\n";
	}
	
	return $input;
}

{
	my $file_not_writable_already_warned;
	sub add_line_to_history {
		my ($line) = @_;
		my $home_dir = home_dir();
		return if not $home_dir;
		
		my $history_file = "$home_dir/.dbshell_history";
		if ( not open (FH, ">> $history_file") ) {
			print STDERR "Warning: Can't write '$history_file'\n"
				if not $file_not_writable_already_warned;
			$file_not_writable_already_warned = 1;
			return;
		}
		
		print FH $line, "\n";
		close FH;
	}

	sub initialize_history {
		my ($term, $size) = @_;

		$size ||= 100;

		my $home_dir = home_dir();
		return if not $home_dir;

		my $history_file = "$home_dir/.dbshell_history";
		open (FH, $history_file) or return;
		my @hist = <FH>;
		close FH;

		if ( @hist > $size) {
			@hist = splice(@hist, @hist-$size, $size);
			if ( open (FH, "> $history_file") ) {
				print FH @hist;
				close FH;
			} else {
				print STDERR "Warning: Can't write '$history_file'\n"
					if not $file_not_writable_already_warned;
				$file_not_writable_already_warned = 1;
			}
		}

		foreach ( @hist ) {
			chomp;
			$term->addhistory ($_);
		}
	}
}

sub home_dir {
	return $ENV{HOME}||$ENV{USERPROFILE};
}

package MyCGI;

sub param {
	my $self = shift;
	return $self->{$_[0]};
}

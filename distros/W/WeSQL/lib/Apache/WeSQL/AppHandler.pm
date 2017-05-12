package Apache::WeSQL::AppHandler;

use 5.006;
use strict;
use warnings;
use lib(".");
use lib("..");

use Apache::WeSQL;
use Apache::WeSQL::SqlFunc qw(sqlConnect);
use Apache::WeSQL::Auth qw(:all);
use Apache::WeSQL::Session qw(:all);

use Apache::Constants qw(:common);
our $VERSION = '0.53';

# Some global variables

our $conf_file_contents = "";
our @commandlist = ();
our ($r,$dbtype,$dsn,$dbuser,$dbpass,$dbh);
our ($authenticate,$noauthurls,$authurls,$authsuperuser,$authsuperuserdir,$defaultlanguage);

# Preloaded methods go here.

sub read_conf_file {
	my $conf_file = shift;
	unless (defined(open(CONFFILE,$conf_file))) {
		&Apache::WeSQL::log_error("Could not open configuration file: $conf_file");
		return SERVER_ERROR;
	}
	$conf_file_contents = join("",<CONFFILE>);
	close(CONFFILE);
	&Apache::WeSQL::log_error("$$: config file $conf_file read successfully") if ($Apache::WeSQL::DEBUG);
	return $conf_file_contents;
}

sub handler { 
	# Get Apache request/response object
	$r = shift;

	# Determine the name of the configuration file
	my $conf_file = $r->dir_config('WeSQLConfig');

	# Read the config file if this is the first time we are run in this Apache thread
	# We need to do the eval here, because there seems to be some weird namespace problem
	# otherwise: the read variables stay in 'read_conf_file' and don't become globally
	# assigned. Strange. Perl 5.6.1.
	eval(&read_conf_file($conf_file)) if ($conf_file_contents eq "");

	# Connect to the database if there is no connection
	$dbh = &sqlConnect($dsn,$dbuser,$dbpass,$dbtype) if (!defined($dbh));
	&Apache::WeSQL::log_error("$$: connected to $dsn") if ($Apache::WeSQL::DEBUG);

	# Make sure we have a session hash!
	my $cookieheader = &Apache::WeSQL::Session::session($dbh);

  &Apache::WeSQL::log_error("$$: AddrHandler: default language setting: $defaultlanguage") if ($Apache::WeSQL::DEBUG);

	# Get the GET/POST parameters
	# getparams fills in the global %params and %cookies hashes, and gets the session language
	&Apache::WeSQL::getparams($dbh,'',$cookieheader,$defaultlanguage);

	my $uri = $r->uri;
	$uri .= "index.wsql" if ($uri =~ /\/$/);

	# Multi-language support
	$uri =~ s/\.[\w\-]{2,5}\.wsql$/\.wsql/;

	&Apache::WeSQL::log_error("$$: AppHandler: authenticate setting: $authenticate") if ($Apache::WeSQL::DEBUG);

	# First check the authentication of the user!
	&Apache::WeSQL::Auth::authenticate($dbh,$authsuperuserdir,$authsuperuser) if ($authenticate && !($uri =~ /^($noauthurls)$/));

	&Apache::WeSQL::log_error("$$: AppHandler: parsing " . $r->uri) if ($Apache::WeSQL::DEBUG);

	# Call WeSQL to do its thing!
	&Apache::WeSQL::display($dbh,$r,$authsuperuserdir,$cookieheader,@commandlist);
}

1;
__END__

=head1 NAME

Apache::WeSQL::AppHandler - Perl ApacheHandler for a WeSQL application

=head1 SYNOPSIS

    PerlSetVar WeSQLConfig /var/www/WeSQL/somesite/conf/WeSQL.pl
    PerlModule Apache::WeSQL::AppHandler

    <FilesMatch "*.wsql">
      SetHandler perl-script
      PerlHandler Apache::WeSQL::AppHandler
    </FilesMatch>
    DocumentRoot "/var/www/WeSQL/somesite/public_html"
		DirectoryIndex index.wsql

=head1 DESCRIPTION

This module is an ApacheHandler for a WeSQL application. It's sole purpose is to
keep the configuration unique to the application in a separate namespace. This includes
the variables defined in the configuration file (as set by WeSQLConfig), and most
importantly the database connection for this application.

Every WeSQL application running on the webserver will need it's own version of this
module, with a different name. This is necessary to avoid namespace-problems (the 
database-handler is always called $dbh in WeSQL!).

For more information about running several WeSQL sites on 1 Apache server, see the
'RUNNING MULTIPLE WEBSITES' section in the Apache::WeSQL man page.

Apart from a sub to read the configuration file, there is no intelligence in this
module. All calls are handled by Apache::WeSQL and its helper modules.

This module is part of the WeSQL package, version 0.53

(c) 2000-2002 by Ward Vandewege. This program is free software; you can redistribute it and/or modify it under the terms of the GPL.

=head2 EXPORT

Nothing.

=head1 AUTHOR

Ward Vandewege, E<lt>ward@pong.beE<gt>

=head1 SEE ALSO

L<Apache::WeSQL>, L<Apache::WeSQL::SqlFunc>, L<Apache::WeSQL::Journalled>, L<Apache::WeSQL::Display>, L<Apache::WeSQL::Auth>.

=cut

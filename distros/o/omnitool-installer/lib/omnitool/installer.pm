package omnitool::installer;

use 5.022001;
use strict;
use warnings;

our $VERSION = "1.0.12";

# for reading in configs
use File::Slurp;
use IO::Prompter;
use Getopt::Long;

# for creating config files
use Template;

# for building databases
use DBI;

# for getting default hostname/domain name
use Net::Domain qw( hostfqdn domainname );

# create myself and try to grab arguments
sub new {
	my $class = shift;

	# our variables
	my ($self, $default_text, $hostname, $domainname, $options_map, $option_keys, $options, $options_file, $line, $name, $value, $option_key, $my_git_repo);

	# my default hostname and domain name
	$hostname = hostfqdn();
	$domainname = domainname();

	# where OmniTool lives
	$my_git_repo = 'https://github.com/ericschernoff/omnitool';

	# we need a map of what our options mean and their defaults
	# the default will be the second item in the array, if there is a default
	$options_map = {
		'config-file' => ['Full path to a file name which will include some/all of the config parameters for this installer, one name=value pairs, one per line.  Provided args will override.'],
		'save-config-file' => ['If you wish to save a file with config parameters, provide a full path to the new file.'],
		'save-config-file-only' => ['Will save file with config parameters and exit without attempting to install; provide a full path to the new file.'],
		'othome' => ['The root directory for OmniTool, e.g. /usr/local/omnitool','/opt/omnitool'],
		'database-server' => ['Hostname or IP address of primary MySQL database server','127.0.0.1'],
		'db-username' => ['Username for connecting to MySQL; value must be provided'],
		'db-password' => ['Password for connecting to MySQL; value must be provided'],
		'init-vector' => ['Init vector for MySQL encryption; value longer than 10 characters must be provided'],
		'salt-phrase' => ['Salt phrase for MySQL encryption; value longer than 10 characters must be provided'],
		'ot-cookie-domain' => ['The domain name for the authentication cookie',$domainname],
		'ot-primary-hostname' => ['The full hostname for the main Web URI for this system',$hostname],
		'omnitool-admin' => ['The email address of the responsible party(ies) for this OmniTool system',$ENV{USER}.'@'.$domainname],
		'os-username' => ['The OS username who will run and own all OmniTool processes and resources',$ENV{USER}],
		'admin-ui-password' => [qq{The password for the 'omnitool_admin' user in the OT Admin Web UI; value must be provided}],
		'source_git_repo' => [qq{The source repo for OmniTool; change from default only if you have your own trusted fork.}, $my_git_repo],
	};
	$option_keys = [
		'config-file','save-config-file','save-config-file-only',
		'othome','database-server','db-username','db-password',
		'init-vector','salt-phrase',
		'omnitool-admin','os-username','admin-ui-password',
		'ot-cookie-domain','ot-primary-hostname','source_git_repo'
	];

	# what arguments did they send?
	$options = {};
	GetOptions ($options, qw(-help+
		-config-file=s -save-config-file=s -save-config-file-only=s
		-othome=s -database-server=s
		-db-username=s -db-password=s init-vector=s -salt-phrase=s -ot-cookie-domain=s
		-admin-ui-password=s -ot-primary-hostname=s -omnitool-admin=s -os-username=s
		-source_git_repo=s)
	);

	# do they just want to see the help screen?
	if ($$options{help}) {
		$self = bless {
			'options' => $options,
			'options_map' => $options_map,
			'option_keys' => $option_keys,
		}, $class;
		$self->print_help_text();
	}

	# if they sent a file that exists, read it to get any options now already sent
	if ($$options{'config-file'} && (-e $$options{'config-file'})) {
		$options_file = read_file($$options{'config-file'});
		foreach $line (split /\n/, $options_file) {
			($name,$value) = split /\s?\=\s?/, $line;
			next if $$options{$name}; # skip if already filled
			$$options{$name} = $value
		}
	}

	# now we need to validate what we have so far, and prompt for what we do not have
	foreach $option_key (@$option_keys) {
		next if $option_key =~ /config-file/; # not for the config files

		# if we do not have a value for this option, prompt for it
		if (!$$options{$option_key}) {
			# does it have a default?
			if ($$options_map{$option_key}[1]) {
				$default_text = ' [Default: '.$$options_map{$option_key}[1].']: ';
			} else { # no default
				$default_text = ' [No Default] : ';
			}

			# password mode?
			if ($option_key =~ /password/i) {
				$$options{$option_key} = prompt $$options_map{$option_key}[0].$default_text, -v, -echo=>'*';
			} else { # OK to show
				$$options{$option_key} = prompt $$options_map{$option_key}[0].$default_text, -v;
			}

			# if it was not provided, take any calculated default
			$$options{$option_key} = $$options_map{$option_key}[1] if !length($$options{$option_key});

			# if it is required and either does not exist or is not long enough, then die() here.
			if (!length($$options{$option_key}) && ($$options_map{$option_key}[0] =~ /must be provided/ || $option_key eq 'source_git_repo')) {
				die(qq{ERROR: You must provide a value for the '$option_key' option.  Please run 'omnitool-installer --help' for details.}."\n");
			} elsif (length($$options{$option_key}) < 10 && $$options_map{$option_key}[0] =~ /longer than 10 characters/) {
				die(qq{ERROR: Value for '$option_key' option must be 10 characters or greater.  Please run 'omnitool-installer --help' for details.}."\n");
			}

		}
	}

	# set up the object with all the options data
	$self = bless {
		'options' => $options,
		'options_map' => $options_map,
		'option_keys' => $option_keys,
	}, $class;

	# do they want to save these configs back out (and potentially exit)?
	if ($self->{options}{'save-config-file'} || $self->{options}{'save-config-file-only'}) {
		$self->save_config_file();
	}

	# if we are still alive, send it back
	return $self;
}

# method to undertake all the installation tasks
sub do_the_installation {
	my $self = shift;

	my (@sub_directories, $config_file, $sub_directory, $the_sub_directory, $belt, $db_info, $distribution_directory, $htdocs_source, $htdocs_link, $omnitool_pm_source, $omnitool_pm_link, @ot_code_pieces, $ot_code_piece, $ot_code_source, $ot_code_link, @web_urls, $next_steps,$next_steps_file);

	print "\n\nATTEMPTING INSTALLATION TASKS:\n\n";

	# here are the sub-directories we need
	@sub_directories = qw(
		code code/omnitool code/omnitool/applications
		configs configs/ssl_cert
		files hash_cache
		htdocs log log/archive
		tmp tmp/docs tmp/email_incoming	tmp/pids
	);

	# start with the home directory
	if (!(-d $self->{options}{othome})) {
		mkdir($self->{options}{othome}, 0755);
		print "Created OmniTool root directory at ".$self->{options}{othome}."\n";
	} else {
		print "OmniTool root directory already exists at ".$self->{options}{othome}."\n";
	}

	# no go through the sub directories
	foreach $sub_directory (@sub_directories) {
		$the_sub_directory = $self->{options}{othome}.'/'.$sub_directory;
		if (!(-d $the_sub_directory)) {
			mkdir($the_sub_directory, 0755);
			print "Created $the_sub_directory\n";
		} else {
			print "Skipped $the_sub_directory - already exists\n";
		}
	}

	# our distribution directory will be here:
	$distribution_directory = $self->{options}{othome}.'/distribution';

	# now pull down the code
	if (-d $distribution_directory.'/omnitool') { # already there, need to do a 'git pull'
		chdir $distribution_directory;
		system('git','pull');
		print "Latest OmniTool code repo *pulled* into $distribution_directory\n";

	} else { # need to do a clone
		system('git','clone',$self->{options}{source_git_repo},$distribution_directory);
		print "Latest OmniTool code repo *cloned* into $distribution_directory\n";
	}

	# link distribution/htdocs to OTHOME/htdocs/omnitool
	$htdocs_source = $distribution_directory.'/htdocs';
	$htdocs_link =  $self->{options}{othome}.'/htdocs/omnitool';
	if (!(-l $htdocs_link)) {
		symlink $htdocs_source, $htdocs_link;
		print "Linked static (HTML/JS/CSS/Images) collateral to $htdocs_link.\n";
	} else {
		print "Skipped link to static (HTML/JS/CSS/Images) collateral to $htdocs_link; symlink already exists.\n";
	}

	# now link to the code, but make it possible for them to write their own applications under $OTPERL/applications

	# first: omnitool.pm
	$omnitool_pm_source = $distribution_directory.'/omnitool.pm';
	$omnitool_pm_link =  $self->{options}{othome}.'/code/omnitool.pm';
	if (!(-l $omnitool_pm_link)) {
		symlink $omnitool_pm_source, $omnitool_pm_link;
		print "Linked omnitool.pm to $omnitool_pm_link.\n";
	} else {
		print "Skipped link of omnitool.pm to $omnitool_pm_link; symlink already exists.\n";
	}

	# now the bits under the actual directory
	@ot_code_pieces = qw(
		common dispatcher.pm main.psgi omniclass omniclass.pm scripts
		static_files tool tool.pm
		applications/otadmin applications/sample_apps
	);
	foreach $ot_code_piece (@ot_code_pieces) {
		$ot_code_source = $distribution_directory.'/omnitool/'.$ot_code_piece;
		$ot_code_link =  $self->{options}{othome}.'/code/omnitool/'.$ot_code_piece;
		if (!(-l $ot_code_link)) {
			symlink $ot_code_source, $ot_code_link;
			print "Linked $ot_code_source to $ot_code_link.\n";
		} else {
			print "Skipped link of $ot_code_source to $ot_code_link; symlink already exists.\n";
		}
	}

	# now, let's set up configs/dbinfo.txt
	$db_info = $self->{options}{'db-username'}."\n".$self->{options}{'db-password'};
	$self->stash_some_text($db_info, $self->{options}{othome}.'/configs/dbinfo.txt');

	# now create the configuration files
	foreach $config_file ('bash_aliases.tt','mysql_omnitool.cnf.tt','omnitool.service.tt','omnitool_apache.conf.tt','start_omnitool.bash.tt') {
		$self->create_config_files($config_file);
	}

	# symlink over code map
	symlink $self->{options}{othome}.'/distribution/configs/ot6_modules.yml', $self->{options}{othome}.'/configs/ot6_modules.yml';

	# if the user who will run OT6 is not the same username running this script, run a chown
	if ($ENV{USER} ne $self->{options}{'os-username'}) {
		system('chown -R '.$self->{options}{'os-username'}.' '.$self->{options}{othome});
	}

	# final step is the database work
	# we need to log into the database and see if we need to create the 'omnitool' and 'otstatedata' DB's
	# and then set up their OT6 Admin user
	$self->setup_databases();

	# what is left for them to do?
	$web_urls[0] = 'https://'.$self->{options}{'ot-primary-hostname'}.'/sample_apps_admin';
	$web_urls[1] = 'https://'.$self->{options}{'ot-primary-hostname'}.'/sample_tools';
	$web_urls[2] = 'https://'.$self->{options}{'ot-primary-hostname'}.'/apps_admin';
	$web_urls[3] = 'https://'.$self->{options}{'ot-primary-hostname'}.'/apps_admin#/tools/view_module_docs';
	$next_steps = qq{
OMNITOOL INSTALLATION IS COMPLETE.

Next Steps:
1. Adjust your CLI environment by adding this to ~/.bash_aliases:
	source $self->{options}{othome}/configs/bash_aliases
2. Bring in the Apache config (or adjust Nginix to taste).  For Ubuntu:
	cd /etc/apache2/conf-enabled ; ln -s $self->{options}{othome}/configs/omnitool_apache.conf
3. Install SSL certificates in here: $self->{options}{othome}/configs/ssl_cert
	- Self-signing cert info: https://httpd.apache.org/docs/2.4/ssl/ssl_faq.html#selfcert
	- You will need to edit lines 76-78 in $self->{options}{othome}/configs/omnitool_apache.conf
4. Restart Apache: sudo systemctl restart apache2
5. Review/tweak and install the special MySQL Config File.  For Ubuntu:
	cd /etc/mysql/mysql.conf.d ; sudo cp /opt/omnitool/configs/mysql_omnitool.cnf ./
	\$EDITOR mysql_omnitool.cnf
	sudo systemctl restart mysql
6. Reviw/tweak the script to start the Plack Service, especially lines 24-42:
	\$EDITOR /opt/omnitool/configs/start_omnitool.bash
	# Note the 'RECAPTCHA' vars if you want to use Google's ReCaptcha service.
7. Start the Plack Service:
	sudo /opt/omnitool/configs/start_omnitool.bash start
	(Look at the omnitool.service SystemD script under /opt/omnitool/configs/ as well.)
8. Check out the sample apps:
	Admin: $web_urls[0]
	User-Facing: $web_urls[1]
9. Read some Perl docs: $web_urls[3]
10. Get Started on Your Apps:  $web_urls[2]

** The username for the Web URL's in steps 8-10 will be 'omnitool_admin' with the
	password you gave for the ''admin-ui-password' option. **

If you have any questions, please reach out to ericschernoff\@gmail.com .
};

	# save that to their home directory
	$next_steps_file = $self->{options}{othome}.'/configs/omnitool_next_steps.txt';
	write_file($next_steps_file,$next_steps);

	# output it, telling them where it is
	print $next_steps."\n(A copy of these next steps have been saved to $next_steps_file .\n";

}

# stripped-down version of text-stashing
sub stash_some_text {
	my $self = shift;

	my ($text_to_stash,$file_location) = @_;

	# garble it up
	my $obfuscated = unpack "h*", $text_to_stash;
	# get this out like:
	# 	$obfuscated = read_file($file_location);
	# 	my $stashed_text = pack "h*", $obfuscated;
	# 	print $stashed_text."\n";
	# This is 0.0000001% of what pack() can do, please see: http://perldoc.perl.org/functions/pack.html

	# stash it out
	write_file( $file_location, $obfuscated);

	return 1;
}

# method to create new config files from my templates
sub create_config_files {
	my $self = shift;

	# the name of the config file template we are going to create
	my ($config_filename) = @_;
	# return if blank or non-existent
	return if !$config_filename || !(-e $self->{options}{othome}.'/distribution/configs/'.$config_filename);

	my ($destination_file, $output, $tt, $key, $new_key);

	# where is it going?
	$destination_file = $self->{options}{othome}.'/configs/'.$config_filename;
	$destination_file =~ s/.tt$//;

	# if it exists, abort
	if (-e 	$destination_file) {
		print "SKIPPED: Can not overwrite config file: $destination_file ; please delete and re-attempt or adjust by hand.\n";
		return;
	}

	# i hate dashes, but felt like they were standard in the args
	foreach $key ('database-server','omnitool-admin','os-username','init-vector','salt-phrase','ot-cookie-domain','ot-primary-hostname') {
		($new_key = $key) =~ s/-/_/g;
		$self->{options}{$new_key} = $self->{options}{$key};
	}

	# prepare template toolkit
	$output = ''; # where the text shall go
	$tt = Template->new({
		ENCODING => 'utf8',
		INCLUDE_PATH => $self->{options}{othome}.'/distribution/configs/',
		OUTPUT => \$output,
	});
	# process the template
	$tt->process($config_filename, $self, $output, {binmode => ':encoding(utf8)'});

	# save the new file under OTHOME/configs
	write_file($destination_file, $output);

	# if it's start_omnitool.bash.tt, make it executable
	if ($config_filename eq 'start_omnitool.bash.tt') {
		chmod 0744, $destination_file;
	}

	# symlink over code map
	symlink $self->{options}{othome}.'/distribution/configs/ot6_modules.yml', $self->{options}{othome}.'/configs/ot6_modules.yml';

	# report success
	print "Created config file $destination_file ; please verify and adjust.\n";
	return;
}

# method to set up the 'omnitool' and 'otstatedata' databases
sub setup_databases {
	my $self = shift;

	my ($dsn, $dbh, $db_name, $sth, $exists, $safe_to_modify);

	# try to make the connection
	$dsn = qq{DBI:mysql:database=information_schema;host=}.$self->{options}{'database-server'}.qq{;port=3306};
	$dbh = DBI->connect($dsn, $self->{options}{'db-username'}, $self->{options}{'db-password'},{ PrintError => 1, RaiseError=>1, mysql_enable_utf8=>8 });
	$dbh->{LongReadLen} = 1000000;

	# check to see if it has our databases
	foreach $db_name ('omnitool','otstatedata','omnitool_applications','omnitool_samples','sample_tools') {
		$sth = $dbh->prepare(qq{select CATALOG_NAME from SCHEMATA where SCHEMA_NAME='$db_name'});
		$sth->execute or print $dbh->errstr."\n";
		($exists) = $sth->fetchrow_array;
		if ($exists) { # if it exists, skip it
			print "SKIPPED: $db_name already exists and was not be overwritten.\n";
		} else { # otherwise, load it in
			$sth = $dbh->prepare(qq{create database $db_name});
			$sth->execute or print $dbh->errstr."\n";
			system('mysql -u'.$self->{options}{'db-username'}.' -p'.$self->{options}{'db-password'}.' -h'.$self->{options}{'database-server'}.' '.$db_name.' < '.$self->{options}{othome}.'/distribution/schema/'.$db_name.'.sql');
			print "Created $db_name from included schema.\n";
			# so we know we can update the databases below with out install tweaks
			$$safe_to_modify{$db_name} = 1;
		}
	}

	# start tweaking the omnitool(_*) DB's

	if ($$safe_to_modify{omnitool}) { # can modify core omnitool admin
		# fix the password for the 'omnitool_admin' user in all three databases
		foreach $db_name ('omnitool','omnitool_applications','omnitool_samples') {
			$sth = $dbh->prepare('update '.$db_name.qq{.omnitool_users set password=sha2(?,224) where username='omnitool_admin'});
			$sth->execute($self->{options}{'admin-ui-password'}) or print $dbh->errstr."\n";
		}

		print "Set Password for 'omnitool_admin' user in the OmniTool Admin Web UI.\n";

		# fix the name and hostname of the Apps for their domain
		$sth = $dbh->prepare(qq{update omnitool.instances set name=?, hostname=? where code='10'});
		$sth->execute('Admin for '.ucfirst($self->{options}{'ot-cookie-domain'}), 'apps-admin.'.$self->{options}{'ot-cookie-domain'}) or print $dbh->errstr."\n";

		# fix the name and hostname of the Sample Apps
		$sth = $dbh->prepare(qq{update omnitool.instances set hostname=? where code='9'});
		$sth->execute('sample-apps-admin.'.$self->{options}{'ot-cookie-domain'}) or print $dbh->errstr."\n";

		print "Updated Name, Hostname for Custom Applications Admin UI.\n";

	} else {

		print "SKIPPED: Could not modify 'omnitool_admin' password; Core 'omnitool' database already exists.\n";

	}

	# Update all database server records
	foreach $db_name ('omnitool','omnitool_applications','omnitool_samples') {
		if ($$safe_to_modify{$db_name}) {
			$sth = $dbh->prepare('update '.$db_name.qq{.database_servers set hostname=?});
			$sth->execute($self->{options}{'database-server'}) or print $dbh->errstr."\n";

			print "Set database server hostname for $db_name.\n";

		} else {
			print "SKIPPED: Could not set database server hostname for $db_name; that database already exists.\n";
		}
	}

}

# method to save out the config file if they sent the right arguments
sub save_config_file {
	my $self = shift;

	my ($option_key, $options_config);

	# just need a set of name=value pairs, one per line
	foreach $option_key (@{ $self->{option_keys} }) {
		next if $option_key =~ /config-file/; # not for the config files
		$options_config .= $option_key.'='.$self->{options}{$option_key}."\n";
	}

	# take off the last character
	chomp($options_config);

	# just save?
	if ($self->{options}{'save-config-file'}) {

		write_file($self->{options}{'save-config-file'}, $options_config);

		print "\n\nConfig options file saved to ".$self->{options}{'save-config-file'}."\n\n";

	# or save an exit
	} elsif ($self->{options}{'save-config-file-only'}) {

		write_file($self->{options}{'save-config-file-only'}, $options_config);

		print "\n\nConfig options file saved to ".$self->{options}{'save-config-file-only'}." and no further action taken.\n\n";
		exit;
	}
}

# method to print a help screen, based on map above
sub print_help_text {
	my $self = shift;

	# start with intro
	print qq{
OmniTool Installer: Retrieves and installs the OmniTool Web Framework onto this system.

Usage: omnitool_installer [OPTIONS]
Must provide either a config_file or all options, where options are:

Git Repo for OmniTool: https://github.com/ericschernoff/omnitool

OmniTool Website:  http://www.omnitool.org

Requires Ubuntu 16.04+ (or distro based on 16.04), as well as Perl 5.22+ and Git.
Also requires MySQL 5.7+ or MariaDB 10.3+ here or close by, and it's no fun without
Apache installed.

Before running, please install the following packages:

zlib1g-dev libssl-dev install build-essential cpanminus perl-doc
mysql-server libmysqlclient-dev apache2

Then, you will need to enable a few Apache modules:

	a2enmod proxy ssl headers proxy_http rewrite

};
	foreach my $option_key (@{ $self->{option_keys} }) {
		print '--'.$option_key.' ';
		if ($self->{options_map}{$option_key}[1]) {
			print $self->{options_map}{$option_key}[0].': [Default: '.$self->{options_map}{$option_key}[1].']';
		} else {
			print $self->{options_map}{$option_key}[0].': [No Default]';
		}
		print "\n\n";
	}

	# done here
	exit;
}

1;

__END__

=encoding utf-8

=head1 NAME

omnitool::installer - Install the OmniTool Web Application Framework

Provides the 'omnitool_installer' script to install OmniTool on your system.

=head1 SYNOPSIS

    # To provide installation details interactively then install:
    omnitool_installer

    # Safer approach: provide the installation details interactively and save config file:
    omnitool_installer --save-config-file-only=/some/path/ot_install.config
    # then run
    omnitool_installer --config-file=/some/path/ot_install.config

	# Be sure to delete/protect ot_install.config

    # To see help and exit:
    omnitool_installer --help

=head1 DESCRIPTION

OmniTool allows you to build web application suites very quickly and with minimal code.  It is
designed to simplify and speed up the development process, reducing code requirements to only
the specific features and logic for the target application.  The resulting applications are
mobile-responsive and API-enabled with no extra work by the developers.

For lots more information on how this works, including demos, examples, and lots of documentation,
please visit L<http://www.omnitool.org/>

The GitHub Repo for OmniTool is L<https://github.com/ericschernoff/omnitool>

=head2 PREREQUISITES

OmniTool has been developed and tested with the following base components:

=over

=item - Ubuntu 16.04 Server

=item - Perl 5.22

=item - Git 2.10

=item - MySQL 5.7 or MariaDB 10.3 (at least the client libraries if separate DB server)

=item - Apache 2.4

=back

You can very likely make it work on FreeBSD 10.1+ or a recent release of RHEL, Fedora, or CentOS.  I am not able
to provide detailed instructions on each of these -- volunteers would be very welcome!

Prior to installation, the following packages will need to be installed via 'sudo apt install':

=over

=item - build-essential

=item - zlib1g-dev

=item - libssl-dev

=item - cpanminus

=item - perl-doc

=item - mysql-server

=item - libmysqlclient-dev

=item - apache2

=back

Then, you will need to enable a few Apache modules:

=over

sudo a2enmod proxy ssl headers proxy_http rewrite

=back

Again, these are Ubuntu 16.04 commands.  I am quite sure you can make this work with the other BSD, Linux
flavors, as well as with Nginix instead of Apache if you prefer.

=head2 ACKNOWLEDGEMENTS

I am very appreciative to my employer, Cisco Systems, Inc., for allowing this software to be
released to the community as open source.  (IP Central ID: 153330984).

I am also grateful to Mohsen Hosseini for allowing me to include his most excellent Ace
Admin as part of this software.

=head1 LICENSE

MIT License

Copyright (c) 2017 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 AUTHOR

Eric Chernoff E<lt>ericschernoff@gmail.comE<gt>

=cut


#!/usr/bin/perl -w

use strict;
use warnings;
use Config::General qw(ParseConfig SaveConfig);

my $was_installed = 0;
my $DEFAULT_FILE;

if ($was_installed) {
	$DEFAULT_FILE  = "XXX_DEFAULT_XXX";
} else {
	$DEFAULT_FILE  = "/etc/perfsonar/collector.conf";
}

print " -- perfSONAR-PS Collectors Configuration --\n";
print " - [press enter for the default choice] -\n\n";

my $file = shift;

$file = &ask("What file should I write the configuration to? ", $DEFAULT_FILE, undef, '.+');

my $tmp;
my $hostname;

my %config = ();
if (-f $file) {
	%config = ParseConfig($file);
}

while (1) {
	my $input;

	print "1) Add/Edit Collector\n";
	print "2) Save configuration\n";
	print "3) Exit\n";
	$input = &ask("? ", "", undef, '[1234]');

	my $hostname;

	if ($input == 3) {
		exit(0);
	} elsif ($input == 2) {
		if (-f $file) {
			system("mv $file $file~");
		}

		SaveConfig($file, \%config);
	} elsif ($input == 1) {
		my $id = &ask("Enter collector identifier", "", undef, '.+');

		if (!defined $config{"collector"}->{$id}) {
			$config{"collector"}->{$id} = ();
		}

		my $valid_module = 0;
		my $module = $config{"collector"}->{$id}->{"module"};
		if (defined $module) {
			if ($module eq "perfSONAR_PS::Collectors::LinkStatus") {
				$module = "linkstatus";
			}
		}

		my %opts;
		do {
			$module = &ask("Enter collector module [linkstatus] ", "", $module, '');
			$module = lc($module);

			if ($module eq "linkstatus") {
				$valid_module = 1;
			}
		} while($valid_module == 0);

		if ($module eq "linkstatus") {
			$config{"collector"}->{$id}->{"module"} = "perfSONAR_PS::Collectors::LinkStatus";
			config_linkstatus($config{"collector"}->{$id}, \%config);
		}
	}
}

sub config_linkstatus {
	my ($config, $def_config) = @_;

	$config->{"collection_interval"} = &ask("Enter the number of seconds between status collections ", "60", $config->{"collection_interval"}, '^\d+$');

	$config->{"link_file"} = &ask("Enter the file to read the link information from", "/etc/perfsonar/links.conf", $config->{"link_file"}, '^.+$');
	$config->{"link_file_type"} = "file";

	$config->{"ma_type"} = &ask("Enter the database type to read from ", "sqlite|mysql|ma", $config->{"ma_type"}, '(sqlite|mysql|ma)');

	if ($config->{"ma_type"} eq "sqlite") {
		$config->{"ma_name"} = &ask("Enter the filename of the SQLite database ", "", $config->{"ma_file"}, '.+');
		$tmp = &ask("Enter the table in the database to use (leave blank for the default) ", "link_status", $config->{"ma_table"}, '');
		$config->{"ma_table"} = $tmp if ($tmp ne "");
	} elsif ($config->{"ma_type"} eq "mysql") {
		$config->{"ma_name"} = &ask("Enter the name of the MySQL database ", "", $config->{"ma_name"}, '.+');
		$tmp = &ask("Enter the host for the MySQL database ", "localhost", $config->{"ma_host"}, '');
		$config->{"ma_host"} = $tmp if ($tmp ne "");
		$tmp = &ask("Enter the port for the MySQL database (leave blank for the default) ", "", $config->{"ma_port"}, '^\d*$');
		$config->{"ma_port"} = $tmp if ($tmp ne "");
		$tmp = &ask("Enter the username for the MySQL database (leave blank for none) ", "", $config->{"ma_username"}, '');
		$config->{"ma_username"} = $tmp if ($tmp ne "");
		$tmp  = &ask("Enter the password for the MySQL database (leave blank for none) ", "", $config->{"ma_password"}, '');
		$config->{"ma_password"} = $tmp if ($tmp ne "");
		$tmp = &ask("Enter the table in the database to use (leave blank for the default) ", "link_status", $config->{"ma_table"}, '');
		$config->{"ma_table"} = $tmp if ($tmp ne "");
	} else {
		$config->{"ma_uri"} = &ask("URL for the MA to store to ", "", $config->{"ma_uri"}, '^http:\/\/');
	}

	return;
}

sub ask {
    my ( $prompt, $value, $prev_value, $regex ) = @_;

    my $result;
    do {
        print $prompt;
        if ( defined $prev_value ) {
            print "[", $prev_value, "]";
        }
        elsif ( defined $value ) {
            print "[", $value, "]";
        }
        print ": ";
        local $| = 1;
        local $_ = <STDIN>;
        chomp;
        if ( defined $_ and $_ ne q{} ) {
            $result = $_;
        }
        elsif ( defined $prev_value ) {
            $result = $prev_value;
        }
        elsif ( defined $value ) {
            $result = $value;
        }
        else {
            $result = q{};
        }
    } while ( $regex and ( not $result =~ /$regex/mx ) );

    return $result;
}

__END__

=head1 NAME

configure.pl - Ask a series of questions to generate a configuration file.

=head1 DESCRIPTION

Ask questions based on a service to generate a configuration file.
	
=head1 SEE ALSO

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut

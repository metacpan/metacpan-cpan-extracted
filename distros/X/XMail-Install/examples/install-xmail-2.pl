#!/usr/bin/perl
#
# Name:
#	install-xmail.pl.
#
# Description:
#	Install and configure a basic XMail installation.
#
# Output:
#	o Exit value
#
# History Info:
#	Rev		Author		Date		Comment
#	1.00   	Ron Savage	20061106	Initial version <ron@savage.net.au>

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use XMail::Install;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions(\%option, 'domain_name=s', 'help', 'in_dir=s', 'out_dir=s', 'postmaster_password=s', 'server=s', 'user_name=s', 'user_password=s', 'verbose') )
{
	pod2usage(1) if ($option{'help'});

	exit XMail::Install -> new(options => \%option) -> run_run();
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

install-xmail.pl - Install and configure a basic XMail installation

=head1 SYNOPSIS

install-xmail.pl [options]

	Options:
	-domain_name my_domain
	-help
	-in_dir input_dir
	-out_dir output_dir
	-postmaster_password a_password
	-server ip_or_name_of_host
	-user_name a_name
	-user_password a_password
	-verbose

Exit value:

=over 4

=item Zero

Success.

=item Non-Zero

Error.

=back

=head1 OPTIONS

=over 4

=item -domain_name my_domain

The name of your mail domain to write into the ctrlaccounts.tab and server.tab files.

The default value is xmail.net.

=item -help

Print help and exit.

=item -in_dir input_dir

	E.g.: -in_dir c:\xmail-1.24

The directory where you unpacked xmail.

If you downloaded xmail-1.24.win32bin.zip from http://www.xmailserver.org/ and unzipped it into c:\,
then you'll have created c:\xmail-1.24, so use -in_dir c:\xmail-1.24.

The default value for in_dir is c:\xmail-1.24.

=item -out_dir output_dir

	E.g.: -out_dir c:\

The directory where you want XMail's MailRoot directory to be installed.

Note: Any pre-existing output_dir will be removed before copying starts. This in turn means if XMail is running,
this script will stop it and remove the service.

-out_dir c:\ means c:\xmail-1.24\MailRoot is copied to c:\MailRoot, and c:\xmail-1.24\*.exe files
are copied to c:\MailRoot\bin.

The default value for output_dir is c:\.

=item -postmaster_password a_password

The password to use for the postmaster's account.

The default value is richness-of-martens (as in 'A richness of martens').

=item -server ip_or_name_of_host

The IP address or the host name of the machine on which XMail will run.

The default value is 127.0.0.1.

=item -user_name a_name

The name to use for a first user's account.

The default value is rsavage.

=item -user_password a_password

The password to use for the user's account.

The default value is skulk-of-foxes (as in 'A skulk of foxes').

=item -verbose

Print verbose messages.

The default value for verbose is 0.

=back

=head1 DESCRIPTION

install-xmail.pl installs and configures a basic XMail installation.

=cut

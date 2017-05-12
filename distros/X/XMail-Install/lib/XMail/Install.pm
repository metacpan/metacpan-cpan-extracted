package XMail::Install;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	tab = 4 spaces || die.
#
# History Info:
#	Rev		Author		Date		Comment
#	1.00   	Ron Savage	20061106	Initial version <ron@savage.net.au>

use strict;
use warnings;

use Carp;
use Email::Send;
use File::Copy;		# For copy().
use File::Copy::Recursive qw(dircopy);
use File::Path;		# For rmtree().
use Mail::POP3Client;
use Path::Class;	# For dir() and file().
use Win32;
use Win32::Process;
use Win32::Process::List;
use Win32::Service;
use Win32::TieRegistry (Delimiter => '/');

our $VERSION = '1.01';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_options => '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		return $_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		return keys %_attr_data;
	}
}

# -----------------------------------------------

sub copy_dirs_and_files
{
	my($self) = @_;

	$self -> info("Removing directory $$self{'_target_dir'}");

	rmtree("$$self{'_target_dir'}"); # ($$self{'_target_dir'}) dies with: Not an ARRAY reference at C:/Perl/lib/File/Path.pm line 191.

	$self -> info("Recursively copying directory $$self{'_source_dir'} to $$self{'_target_dir'}");

	my(@result) = dircopy($$self{'_source_dir'}, $$self{'_target_dir'});

	$self -> info("Copied $result[0] files and directories");

	my($dir) = $$self{'_target_dir'} -> subdir('bin');

	my($file);

	for (qw/ctrlclnt mkusers sendmail XMail xmcrypt/)
	{
		$file = $$self{'_options'}{'in_dir'} -> file("$_.exe");

		$self -> info("Copying $file to $dir");

		copy($file, $dir -> file("$_.exe") );
	}

}	# End of copy_dirs_and_files.

# -----------------------------------------------

sub create_account
{
	my($self)	= @_;
	my($file)	= $$self{'_target_dir'} -> file('ctrlaccounts.tab');

	$self -> info("Updating $file to contain the xmailuser's account");
	$self -> info('o This account is used to create the domain and the user account');
	$self -> info("o Later, the postmaster's account overwrites the xmailuser's account");

	open(OUT, "> $file") || die "Can't open(> $file): $!";
	print OUT qq|"xmailuser"\t"1d08040c09"\n|; # Password is xmail.
	close OUT;

}	# End of create_account.

# -----------------------------------------------

sub create_domain
{
	my($self)		= @_;
	my($file)		= $$self{'_target_dir'} -> file('domains.tab');
	my($command)	= "$$self{'_ctrlclnt'} -s $$self{'_options'}{'server'} -u xmailuser -p xmail domainadd $$self{'_options'}{'domain_name'}";

	$self -> info("Running ctrlclnt to create the domain $$self{'_options'}{'domain_name'}");
	$self -> info("o Run: $command");
	$self -> info("o This will update $file");

	$self -> execute($command);
	$self -> sleep($$self{'_options'}{'short_delay'});

	my($dir) = $$self{'_target_dir'} -> subdir('domains', $$self{'_options'}{'domain_name'});

	if (-d $dir)
	{
		$self -> info("Created domain directory $dir");
	}
	else
	{
		Carp::croak "Failed to create domain directory $dir";
	}

}	# End of create_domain.

# -----------------------------------------------

sub create_postmaster_account
{
	my($self)		= @_;
	my($command)	= "$$self{'_xmcrypt'} $$self{'_options'}{'postmaster_password'}";

	$self -> info("Running xmcrypt to encrypt the postmaster's password");
	$self -> info("o Run: $command");

	my($password) = `$command`;

	chomp $password;

	$self -> info("o Password: $password");

	my($file) = $$self{'_target_dir'} -> file('ctrlaccounts.tab');

	$self -> info("Updating $file to contain the postmaster's account");

	open(OUT, "> $file") || die "Can't open(> $file): $!";
	print OUT qq|"postmaster"\t"$password"\n|;
	close OUT;

}	# End of create_postmaster_account.

# -----------------------------------------------

sub create_user_account
{
	my($self)		= @_;
	my($command)	= "$$self{'_xmcrypt'} $$self{'_options'}{'user_password'}";

	$self -> info("Running xmcrypt to encrypt $$self{'_options'}{'user_name'}'s password");
	$self -> info("o Run: $command");

	my($password) = `$command`;

	chomp $password;

	$self -> info("o Password: $password");

	$command	= "$$self{'_ctrlclnt'} -s $$self{'_options'}{'server'} -u xmailuser -p xmail useradd $$self{'_options'}{'domain_name'} $$self{'_options'}{'user_name'} $$self{'_options'}{'user_password'} U";
	my($file)	= $$self{'_target_dir'} -> file('mailusers.tab');

	$self -> info("Running ctrlclnt to create the user $$self{'_options'}{'user_name'}");
	$self -> info("o Run: $command");
	$self -> info("o This will update $file");

	$self -> execute($command);

	$self -> info('Created user account');

}	# End of create_user_account.

# -----------------------------------------------

sub execute
{
	my($self, $command)	= @_;
	my(@result)			= `$command`;

	chomp @result;

	@result = '(nothing)' if (! @result);

	$self -> info("Output of that command: $_") for @result;

}	# End of execute.

# -----------------------------------------------

sub info
{
	my($self, $message) = @_;

	print "$message\n" if ($$self{'_options'}{'verbose'});

}	# End of info.

# -----------------------------------------------

sub install_and_start_service
{
	my($self) 		= @_;
	my($xmail)		= $$self{'_target_dir'} -> file('bin', 'XMail.exe');
	my($command)	= "$xmail --install-auto";

	$self -> info("Installing XMail as a service");
	$self -> info("o Run: $command");

	$self -> execute($command);
	$self -> info('Starting the XMail service');

	Win32::Service::StartService('', 'XMail');

}	# End of install_and_start_service.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	$$self{'_options'}							= {}						if (! $$self{'_options'});
	$$self{'_options'}{'domain_name'}			= 'xmail.net'				if (! $$self{'_options'}{'domain_name'});
	$$self{'_options'}{'server'}				= '127.0.0.1'				if (! $$self{'_options'}{'server'});
	$$self{'_options'}{'in_dir'}				= dir('c:', 'xmail-1.25')	if (! $$self{'_options'}{'in_dir'});
	$$self{'_options'}{'long_delay'}			= 20;
	$$self{'_options'}{'out_dir'}				= dir('c:')					if (! $$self{'_options'}{'out_dir'});
	$$self{'_options'}{'postmaster_password'}	= 'richness-of-martens'		if (! $$self{'_options'}{'postmaster_password'});
	$$self{'_options'}{'short_delay'}			= 5;
	$$self{'_options'}{'user_name'}				= 'rsavage'					if (! $$self{'_options'}{'user_name'});
	$$self{'_options'}{'user_password'}			= 'skulk-of-foxes'			if (! $$self{'_options'}{'user_password'});
	$$self{'_options'}{'verbose'}				= 0							if (! $$self{'_options'}{'verbose'});

	$self -> info("Program:             $0");
	$self -> info("Version:             $VERSION");
	$self -> info("domain_name:         $$self{'_options'}{'domain_name'}");
	$self -> info("server:  		    $$self{'_options'}{'server'}");
	$self -> info("in_dir:              $$self{'_options'}{'in_dir'}");
	$self -> info("out_dir:             $$self{'_options'}{'out_dir'}");
	$self -> info("postmaster_password: $$self{'_options'}{'postmaster_password'}");
	$self -> info("user_name:           $$self{'_options'}{'user_name'}");
	$self -> info("user_password:       $$self{'_options'}{'user_password'}");
	$self -> info("verbose:             $$self{'_options'}{'verbose'}");
	$self -> info('-' x 50);

	return $self;

}	# End of new.

# -----------------------------------------------

sub receive_test_message
{
	my($self)	= @_;
	my($pop)	= Mail::POP3Client -> new
	(
		USER		=> $$self{'_options'}{'user_name'},
		PASSWORD	=> $$self{'_options'}{'user_password'},
		HOST		=> $$self{'_options'}{'server'},
		AUTH_MODE	=> 'PASS',
	);
	my($count) = $pop -> Count();

	$self -> info("Server has $count message(s) waiting to be read");
	$self -> info('-' x 50);

	my(@body);
	my(@head);
	my($i);

	for ($i = 1; $i <= $count; $i++)
	{
		@head = $pop -> Head($i);

		$self -> info("Received head: $_") for @head;
		$self -> info('');

		@body = $pop -> Body($i);

		$self -> info("Received body: $_") for @body;
		$self -> info('-' x 50);

		$pop -> Delete($i);
	}

	$pop -> Close();

}	# End of receive_test_message.

# -----------------------------------------------

sub run
{
	my($self)				= @_;
	$$self{'_source_dir'}	= $$self{'_options'}{'in_dir'} -> subdir('MailRoot');
	$$self{'_target_dir'}	= $$self{'_options'}{'out_dir'} -> subdir('MailRoot');
	$$self{'_ctrlclnt'}		= $$self{'_target_dir'} -> file('bin', 'ctrlclnt.exe');
	$$self{'_xmail'}		= $$self{'_target_dir'} -> file('bin', 'XMail.exe');
	$$self{'_xmail_debug'}	= 'XMail --debug';
	$$self{'_xmcrypt'}		= $$self{'_target_dir'} -> file('bin', 'xmcrypt.exe');

	$self -> stop_and_remove_service();
	$self -> update_the_registry();
	$self -> copy_dirs_and_files();
	$self -> create_account();
	$self -> info("Starting '$$self{'_xmail_debug'}' using the config files shipped with XMail");
	$self -> info('o Server must be up to run ctrlclnt');
	$self -> info("o Creating the domain $$self{'_options'}{'domain_name'}");
	$self -> info("o Creating the account for the user $$self{'_options'}{'user_name'}");

	my($process) = $self -> start_server();

=pod

	$self -> create_domain();
	$self -> create_user_account();
	$self -> stop_server();

	$self -> create_postmaster_account();
	$self -> update_dirs_and_files();
	$self -> info("Starting '$$self{'_xmail_debug'}' with the new config files");
	$self -> info('o Server must be up for it to receive mail');
	$self -> info("o Sending a test message to $$self{'_options'}{'user_name'}");

	$process = $self -> start_server();

	$self -> send_test_message();
	$self -> receive_test_message();
	$self -> stop_server();
	$self -> install_and_start_service();

=cut

	$self -> info('Finished');

	return 0;

}	# End of run.

# -----------------------------------------------

sub run_run
{
	my($self)				= @_;
	$$self{'_source_dir'}	= $$self{'_options'}{'in_dir'} -> subdir('MailRoot');
	$$self{'_target_dir'}	= $$self{'_options'}{'out_dir'} -> subdir('MailRoot');
	$$self{'_ctrlclnt'}		= $$self{'_target_dir'} -> file('bin', 'ctrlclnt.exe');
	$$self{'_xmail'}		= $$self{'_target_dir'} -> file('bin', 'XMail.exe');
	$$self{'_xmail_debug'}	= 'XMail --debug';
	$$self{'_xmcrypt'}		= $$self{'_target_dir'} -> file('bin', 'xmcrypt.exe');

	$self -> create_domain();
	$self -> create_user_account();
	$self -> stop_server();

	$self -> create_postmaster_account();
	$self -> update_dirs_and_files();
	$self -> info("Starting '$$self{'_xmail_debug'}' with the new config files");
	$self -> info('o Server must be up for it to receive mail');
	$self -> info("o Sending a test message to $$self{'_options'}{'user_name'}");

	my($process) = $self -> start_server();

	$self -> send_test_message();
	$self -> receive_test_message();
	$self -> stop_server();
	$self -> install_and_start_service();
	$self -> info('Finished');

	return 0;

}	# End of run_run.

# -----------------------------------------------

sub sleep
{
	my($self, $timeout) = @_;

	$self -> info("Sleeping $timeout seconds");

	sleep $timeout;

}	# End of sleep.

# -----------------------------------------------

sub send_test_message
{
	my($self)		= @_;
	my($subject)	= 'Testing installation of XMail';
	my($message)	= <<EOS;
To: $$self{'_options'}{'user_name'}\@$$self{'_options'}{'domain_name'}
From: ron\@savage.net.au
Subject: $subject

An implausibility of gnus.
An impossibility of platypuses.
EOS
	$self -> info('Message reads...');
	$self -> info('-' x 50);
	$self -> info($message);
	$self -> info('-' x 50);

	my($sender) = Email::Send->new({mailer => 'SMTP'});

	$sender->mailer_args([Host => $$self{'_options'}{'server'}]);
	$sender->send($message);
	$self -> info('Sent test message');
	$self -> sleep($$self{'_options'}{'short_delay'});

}	# End of send_test_message.

# -----------------------------------------------

sub start_server
{
	my($self) = @_;

	my($process);

	Win32::Process::Create($process, $$self{'_xmail'}, $$self{'_xmail_debug'}, 0, NORMAL_PRIORITY_CLASS, '.') || die "Can't start process $$self{'_xmail'}. \n" . win32_error();

	$self -> info("Started $$self{'_xmail'} as a process, not as a service");

	$self -> sleep($$self{'_options'}{'long_delay'});

	return $process;

}	# End of start_server.

# -----------------------------------------------

sub stop_and_remove_service
{
	my($self)		= @_;
	my($command)	= $$self{'_options'}{'in_dir'} -> file('XMail.exe');
	$command		.= ' --remove';

	$self -> info('Stopping the XMail service');

	Win32::Service::StopService('', 'XMail');

	$self -> info("Running XMail to remove the service");
	$self -> info("o Run: $command");

	$self -> execute($command);
	$self -> sleep(2);
	$self -> info('Service removed');

}	# End of stop_and_remove_service.

# -----------------------------------------------

sub stop_server
{
	my($self) = @_;

	# We do things this way, rather than using the $process returned from start_server()
	# so that we can run start_server() and stop_server() via run() and run_run()
	# respectively, and in the latter case $process is not available.

	$self -> info("Stopping the $$self{'_xmail'} process");

	my($processor)	= Win32::Process::List -> new();
	my(%process)	= $processor -> GetProcesses();

	my($p, $pid);

	for $p (keys %process)
	{
		$pid = $process{$p} if ($p eq 'XMail.exe');
	}

	if ($pid)
	{
		Win32::Process::KillProcess($pid, 0);

		$self -> info('Stopped XMail');
	}
	else
	{
		$self -> info("Can't stop XMail. It is not running");
	}

}	# End of stop_server.

# -----------------------------------------------

sub update_dirs_and_files
{
	my($self) = @_;

	my($dir);

	for (qw/home.bogus xmailserver.test/)
	{
		$dir = $$self{'_target_dir'} -> subdir('domains', $_);

		$self -> info("Removing obsolete directory $dir");

		rmtree("$dir"); # ($dir) dies with: Not an ARRAY reference at C:/Perl/lib/File/Path.pm line 191.
	}

	my($file);

	for (qw/aliases/)
	{
		$file = $$self{'_target_dir'} -> file("$_.tab");

		$self -> info("Removing contents of $file");
		$self -> info('o It refers to the obsolete account xmailserver.test');

		open(OUT, "> $file") || die "Can't open(> $file): $!";
		close OUT;
	}

	$file = $$self{'_target_dir'} -> file('server.tab');

	$self -> info("Updating $file");
	$self -> info("o Converting xmailserver.test to $$self{'_options'}{'domain_name'}");
	$self -> info("o Converting root\@$$self{'_options'}{'domain_name'} to postmaster\@$$self{'_options'}{'domain_name'}");

	open(INX, $file) || die "Can't open($file): $!";
	my(@line) = map
	{
		s/xmailserver.test/$$self{'_options'}{'domain_name'}/;
		s/root/postmaster/ if (/^"ErrorsAdmin/);
		s/root/postmaster/ if (/^"PostMaster/);
		$_;
	} <INX>;
	close INX;

	open(OUT, "> $file") || die "Can't open(> $file): $!";
	print OUT @line;
	close OUT;

	$file = $$self{'_target_dir'} -> file('domains.tab');

	$self -> info("Updating $file");
	$self -> info('o Remove the domain shipped with XMail');
	$self -> info("o Leave only the new domain $$self{'_options'}{'domain_name'}");

	open(INX, $file) || die "Can't open($file): $!";
	@line = grep{/"$$self{'_options'}{'domain_name'}"/} <INX>;
	close INX;

	open(OUT, "> $file") || die "Can't open(> $file): $!";
	print OUT $line[0];
	close OUT;

	$file = $$self{'_target_dir'} -> file('mailusers.tab');

	$self -> info("Updating $file");
	$self -> info('o Remove the account shipped with XMail');
	$self -> info("o Leave only the new account for $$self{'_options'}{'user_name'}");

	open(INX, $file) || die "Can't open($file): $!";
	@line = grep{/"$$self{'_options'}{'domain_name'}"/} <INX>;
	close INX;

	open(OUT, "> $file") || die "Can't open(> $file): $!";
	print OUT $line[0];
	close OUT;

	for (qw/ctrl smtp/)
	{
		$file = $$self{'_target_dir'} -> file("$_.ipmap.tab");

		$self -> info("Updating $file");
		$self -> info('o Convert original line (Allow all) to Deny all');
		$self -> info("o Add a line to allow admin only from $$self{'_options'}{'server'}");

		open(OUT, "> $file") || die "Can't open(> $file): $!";
		print OUT qq|"0.0.0.0"\t"0.0.0.0"\t"DENY"\t1\n|;
		print OUT qq|"$$self{'_options'}{'server'}"\t"255.255.255.0"\t"ALLOW"\t2\n|;
		close OUT;
	}

}	# End of update_dirs_and_files.

# -----------------------------------------------

sub update_the_registry
{
	my($self) = @_;

	$self -> info('Checking for registry keys under HKEY_LOCAL_MACHINE/SOFTWARE/GNU/XMail');

	my($root) = 'HKEY_LOCAL_MACHINE/SOFTWARE';
	my($hash) = $$Registry{"$root/"};

	if (! $$Registry{"$root/GNU"})
	{
		$self -> info("Creating key $root/GNU");
		$hash -> CreateKey('GNU');
	}

	$root = "$root/GNU";
	$hash = $$Registry{"$root/"};

	if (! $$Registry{"$root/XMail"})
	{
		$self -> info("Creating key $root/XMail");
		$hash -> CreateKey('XMail');
	}

	$root = "$root/XMail";
	$hash = $$Registry{"$root/"};

	my($result);

	if ($$Registry{"$root/MAIL_CMD_LINE"})
	{
		$result = delete $$Registry{"$root//MAIL_CMD_LINE"};

		$self -> info("Deleted existing $root/MAIL_CMD_LINE: $result");
	}

	my($parameters) = '-Pl -Sl -Ql -Yl -Fl -Cl -Ll';

	$self -> info("Creating value $root/MAIL_CMD_LINE => $parameters");

	$result = $hash -> SetValue('MAIL_CMD_LINE', $parameters);

	if ($$Registry{"$root/MAIL_ROOT"})
	{
		$result = delete $$Registry{"$root//MAIL_ROOT"};

		$self -> info("Deleted existing $root/MAIL_ROOT: $result");
	}

	$self -> info("Creating value $root/MAIL_ROOT => $$self{'_target_dir'}");

	$result = $hash -> SetValue('MAIL_ROOT', $$self{'_target_dir'});

	$self -> info("Values under $root:");
	$self -> info("o $_ => " . $hash -> GetValue($_) ) for sort $hash -> ValueNames();

}	# End of update_the_registry.

# -----------------------------------------------

sub win32_error
{
	return Win32::FormatMessage(Win32::GetLastError() );

}	# End of win32_error.

# -----------------------------------------------

1;

=head1 NAME

C<XMail::Install> - A module to install the MS Windows mail server XMail

=head1 Synopsis

	#!/usr/bin/perl

	use strict;
	use warnings;

	use XMail::Install;

	# -----------------

	my(%option) = (...);

	XMail::Install -> new(options => \%option) -> run();

See the next section for details.

=head1 Description

C<XMail::Install> is a pure Perl module. It only runs under MS Windows.

It will read an unpacked distro of the XMail mail server, and install, configure and test it.

Also, it will stop and remove the service if it is already running.

So, download xmail-1.25.win32bin.zip from http://xmailserver.org/ and unpack it into c:\. This creates c:\xmail-1.25.

	Then:
	Unpack the distro.
	shell>cd examples
	shell>perl install-xmail-1.pl -h
	shell>perl install-xmail-1.pl -v -other -options
	shell>perl install-xmail-2.pl -v -other -options

The reason for having 2 install programs is that I could not get 1 to work properly, neither under Win2FK nor WinXFP.
Sometimes it would work, and sometimes it would not.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<XMail::Install>.

This is the class's contructor.

Usage: XMail::Install -> new().

This method takes a hashref of options. There are no mandatory options.

Call C<new()> as new(options => {key_1 => value_1, key_2 => value_2, ...}).

=over 4

=item domain_name

This is the name of your mail domain.

The default is xmail.net.

=item in_dir

This is the name of the directory into which you unpacked XMail.

The default is c:\xmail-1.25.

=item out_dir

This is the name of the directory into which XMail's default directory MailRoot will be installed.

The default is c:\, so XMail will be installed into c:\MailRoot.

Also, executables in the distro dir c:\xmail-1.25\bin will be copied to c:\MailRoot\bin.

=item postmaster_password

This is the password of the postmaster (admin) account.

The default is 'richness-of-martens'.

=item server

This is the IP address, or name, of the host on which the XMail service will be running.

The default is 127.0.0.1.

=item user_name

This is the name of a user (non-admin) account.

The default is 'rsavage'.

=item user_password

This is the password of the user account.

The default is 'skulk-of-foxes'.

=item verbose

This is the flag which controls the amount of progress messages printed.

Values are 0 or 1.

The default is 0.

=back

=head1 Method: copy_dirs_and_files

A convenience method which makes the main line code in method C<run()> simpler.

Actually, except for C<new()> and C<run()>, all methods in the class are convenience methods.

=head1 Method: create_account

Update ctrlaccounts.tab with the details of the user 'xmailuser'.

=head1 Method: create_domain

Use the C<XMail> C<ctrlclnt> program to create a mail domain.

=head1 Method: create_postmaster_account

Create C<XMail>'s postmaster account and password.

=head1 Method: create_user_account

Create an C<XMail> user account and password.

=head1 Method: info

Print progress messages, while checking the verbose switch.

=head1 Method: install_and_start_service

This installs and starts the XMail service.

=head1 Method: receive_test_message

Receive and print the test message sent by method C<send_test_message>.

=head1 Method: run

Do all the work required to install C<XMail>.

This is achieved by calling all the convenience methods in the class.

=head1 Method: send_test_message

Send a test message, which will be received by method C<receive_test_message>.

=head1 Method: start_server

Start the C<XMail> program as a process, not as a service.

=head1 Method: stop_and_remove_service

Stop the C<XMail> service, and then remove it.

=head1 Method: stop_server

Stop the C<XMail> program.

=head1 Method: update_dirs_and_files

Update various directories and files.

=head1 Method: update_the_registry

Update the registry, if necessary, being careful to preserve data in the immediate vicinity of the new keys.

=head1 Method: win32_error

Return the last error available from the OS.

=head1 FAQ

=over

=item Why did you write this module?

To explicitly document a minimum set of steps I believe are required to install XMail.

This allows to me very simply install XMail on more than one system and, in the same way, it allows anyone
to very simply set up a mail server to experiment with.

Email me if you have any suggestions regarding the steps I've implemented.

=item How secure is C<XMail>?

Well, you'll need to investigate C<XMail> itself to answer that question. See http://www.xmailserver.org/

But we can say mail server security is a complex issue, and installing a mail server should not be done lightly.

At the absolute minimum, you should C<not> use the default passwords shipped with this module.

=item Why did you use passwords such as 'richness-of-martens' anyway?

Firstly, as a way of drawing you attention to the problem of choosing good passwords, and secondly because
I like playing with the English language.

And yes, 'a richness of martens' is correct English, where martens refers to a type of bird, and richness is the
corresponding collective noun. The same goes for 'skulk-of-foxes'.

One source of passwords is https://www.grc.com/passwords.htm

=item Which versions of C<XMail> did you test this module against?

V 1.22 and V 1.24.

=item Is C<XMail> your primary mail server?

No. I use a commercial web hosting company, http://www.quadrahosting.com.au/

The way I use C<XMail> is by restricing the clients which can talk to it to be clients with IP addresses in
the ranges 192.168.*.* and 10.*.*.*.

=item Why don't you use the module XMail::Ctrl?

I examined it, and decided it wasn't quite relevant.

=item What's with this word daemon?

A daemon is what Microsoft, and others, call a service.

See http://en.wikipedia.org/wiki/Daemon_%28computer_software%29 for an explanation.

=back

=head1 Required Modules

=over 4

=item Carp

=item Email::Send

=item File::Copy

=item File::Copy::Recursive

=item File::Path

=item Mail::POP3Client

=item Path::Class

=item Win32

=item Win32::Process

=item Win32::Process::List

=item Win32::Service

=item Win32::TieRegistry

=back

=head1 Author

C<XMail::Install> was written by Ron Savage in 2007. [ron@savage.net.au]

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2007, Ron Savage. All rights reserved.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut

package Test::SSH;

our $VERSION = '0.08';

use strict;
use warnings;

use Carp;
use File::Glob qw(:glob);
require File::Spec;
require Test::More;

my (@extra_path, @default_user_keys, $default_user, $private_dir);

my @default_test_commands = ('true', 'exit', 'echo foo', 'date',
                             'cmd /c ver', 'cmd /c echo foo');

if ( $^O =~ /^MSWin/) {
    require Win32;
    $default_user = Win32::LoginName();
	
	my @pf;
	for my $folder (qw(PROGRAM_FILES PROGRAM_FILES_COMMON)) {
		my $dir = eval "Win32::GetFolderPath(Win32::$folder)";
		if (defined $dir) {
		    push @extra_path, File::Spec->join($dir, 'PuTTY');
		}
	}
}
else {
    @extra_path = ( map { File::Spec->join($_, 'bin'), File::Spec->join($_, 'sbin') }
                    map { File::Spec->rel2abs($_) }
                    map { bsd_glob($_, GLOB_TILDE|GLOB_NOCASE) }
                    qw( /
                        /usr
                        /usr/local
                        ~/
                        /usr/local/*ssh*
                        /usr/local/*ssh*/*
                        /opt/*SSH*
                        /opt/*SSH*/* ) );

    @default_user_keys = bsd_glob("~/.ssh/*", GLOB_TILDE);

    $default_user = getpwuid($>);

    ($private_dir) = bsd_glob("~/.libtest-ssh-perl", GLOB_TILDE|GLOB_NOCHECK);

}

@default_user_keys = grep {
    my $fh;
    open $fh, '<', $_ and <$fh> =~ /\bBEGIN\b.*\bPRIVATE\s+KEY\b/
} @default_user_keys;


my @default_path = grep { -d $_ } File::Spec->path, @extra_path;

unless (defined $private_dir) {
    require File::temp;
    $private_dir = File::Spec->join(File::Temp::tempdir(CLEANUP => 1),
                                    "libtest-ssh-perl");
}

my $default_logger = sub { Test::More::diag("Test::SSH > @_") };

my %defaults = ( backends      => [qw(Remote OpenSSH)],
                 timeout       => 10,
                 port          => 22,
                 host          => 'localhost',
                 user          => $default_user,
                 test_commands => \@default_test_commands,
                 path          => \@default_path,
                 user_keys     => \@default_user_keys,
                 private_dir   => $private_dir,
                 logger        => $default_logger,
                 run_server    => 1,
               );

sub new {
    my ($class, %opts) = @_;
    defined $opts{$_} or $opts{$_} = $defaults{$_} for keys %defaults;

    if (defined (my $target = $ENV{TEST_SSH_TARGET})) {
        $opts{requested_uri} = $target;
        $opts{run_server} = 0;
    }

    if (defined (my $password = $ENV{TEST_SSH_PASSWORD})) {
        $opts{password} = $password;
    }

    for my $be (@{delete $opts{backends}}) {
        $be =~ /^\w+$/ or croak "bad backend name '$be'";
        my $class = "Test::SSH::Backend::$be";
        eval "require $class; 1" or die;
        my $sshd = $class->new(%opts) or next;
        $sshd->_log("connection uri", $sshd->uri(hidden_password => 1));
        return $sshd;
    }
    return;
}

1;
__END__

=head1 NAME

Test::SSH - Perl extension for testing SSH modules.

=head1 SYNOPSIS

  use Test::SSH;
  my $sshd = Test::SSH->new or skip_all;

  my %opts;
  $opts{host} = $sshd->host();
  $opts{port} = $sshd->port();
  $opts{user} = $sshd->user();
  given($sshd->auth_method) {
    when('password') {
      $opts{password} = $sshd->password;
    }
    when('publickey') {
      $opts{key_path} = $sshd->key_path;
    }
  }

  my $openssh = Net::OpenSSH->new(%opts);
  # or...
  my $anyssh  = Net::SSH::Any->new(%opts);
  # or...


=head1 DESCRIPTION

B<Important>: This module is being replaced by
L<Net::SSH::Any::Test>. Development of C<Test::SSH> is now mostly
limited to bug fixing!

In order to test properly Perl modules that use the SSH protocol, a
running server and a set of valid authentication credentials are
required.

If you test your modules on a controlled environment, you may know the
details of some local server or even have one configured just for that
purpose, but if you plan to upload your modules to CPAN (or for that
matter distribute them through any other medium) and want them to be
tested by the CPAN testers and by programmers installing them, things
become quite more difficult.

This module, uses several heuristics to find a local server or if none
is found, start a new one and then provide your testing scripts with
the credentials required to login.

Besides finding or starting a server the module also tests that it
works running some simple commands there. It would try hard to not
return the details of a server that is not working properly.

=head2 API

The module provides the following methods:

=over 4

=item $sshd = Test::SSH-E<gt>sshd(%opts)

Returns an object that can be queried to obtain the details of an
accesible SSH server. If no server is found or can be launched, undef
is returned.

In case a slave SSH server had been started, it will be killed once
the returned object goes out of scope.

For modules distributed through CPAN or that are going to be tested
on uncontrolled environments, commonly, no options should be
given as the default should already be the right choice.

In any case, these are the accepted options:

=over 4

=item requested_uri =E<gt> $uri

The module looks for a SSH server at the location given.

=item backends =E<gt> \@be

The module has several backend modules, every one implementing a
different approach for finding a SSH server. This argument allows to
select a specific subset of them.

=item path =E<gt> \@path

By default the module looks for SSH program binaries on the path and
on several common directories (i.e. C</opt/*SSH*>). This parameter
allows to change that.

=item timeout =E<gt> $timeout

Timeout used for running commands and stablishing remote
connections. The default is 10s.

=item test_commands =E<gt> \@cmds

When testing a SSH connection the module would try running the
commands given here until any of them succeeds. The defaults is a set
of very common Unix and shell commands (i.e. C<echo> or C<true>).

=item private_dir =E<gt> $dir

Location used to save data bewteen runs (i.e. generated user and host
key pairs).

The default is C<~/.libtest-ssh-perl>

=item private_keys =E<gt> \@key_paths

List of private keys that will be used for login into the remote host.

The default is to look for keys in C<~/.ssh>.

=item logger =E<gt> sub { ... }

Subroutine that will be called to report activity to the user.

The default is to use L<Test::More::diag>.

=item run_server => $bool

Enables/disables the backends that start a new SSH server.

For instance:

  my $sshd = Test::SSH->new(run_server => ($ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING}));

=item override_server_config => $hash_reference

Key/Value pairs in this hash reference will be used to override the
defaults for the C<sshd_config> file of the C<sshd> server started. If
a value in this hash is undef, the respective key of the server config
will be deleted.

=back

Also, the following environment variables can be used to change the
module behaviour:

=over 4

=item TEST_SSH_TARGET

Target URI. When set, the module will look for the SSH server at the
location given. For instance:

  TEST_SSH_TARGET=ssh://root:12345@ssh.google.com/ perl testing_script.pl

Setting this variable will also dissable launching a custom SSH server
for testing.

=item TEST_SSH_PASSWORD

When set, the value will be used as the login password. For instance:

  TEST_SSH_PASSWORD=12345 perl testing_script.pl

=back

=item $sshd-E<gt>host

Returns the name of the host.

=item $sshd-E<gt>port

Returns the TCP port number where the server is listening.

=item $sshd-E<gt>user

Returns the name of the remote user

=item $sshd-E<gt>auth_method

Returns C<password> or C<publickey> indicating the method that can be
used to connect to the remote server.

=item $sshd-E<gt>key_path

When the authentication method is C<publickey>, this method returns
the path to the private key that can be used for loging into the
remote host.

=item $sshd-E<gt>password

When the authentication method is C<password>, this method returns the
password to be used for logging into the remote host.

=item $sshd-E<gt>uri(%opts)

Returns an L<URI> object descibing the SSH server.

The accepted options are as follows:

=over 4

=item hidden_password => 1

When this option is set and in case of password authentication, the
password will be replaced by five asterisks on the returned URI.

=back

=item my %params = $sshd-E<gt>connection_params

Returns the connection parameters as a list of key/value pairs.

=item $sshd-E<gt>server_version

Connects to the server and retrieves its version signature.

=back

=head1 BUGS AND SUPPORT

Well, this module is of complicated nature. It interacts in several
ways with external uncontrolled entities in an unknown environment, so
it may probably fail in lots of ways...

The good news is that if you use it and report me failures, bugs or
any unexpected failure I will try to fix it and it will improve and
mature over time!!!

In order to report bugs use the CPAN bugtracker
(L<http://rt.cpan.org>) or at your option the GitHub one
(L<https://github.com/salva/p5-Test-SSH/issues>).

The source code for the development version of the module is hosted at
GitHub: L<https://github.com/salva/p5-Test-SSH>). Patches or
pull-request are very well welcome!

=head2 Commercial support

Commercial support, professional services and custom software
development around this module are available through my current
company. Drop me an email with a rough description of your
requirements and we will get back to you ASAP.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2017 by Salvador FandiE<ntilde>o (sfandino@yahoo.com),
    Andreas KE<ouml>nig (andk@cpan.org)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

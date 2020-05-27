package Test::FTP::Server;

use strict;
use warnings;

our $VERSION = '0.013';

use Carp;

use File::Find;
use File::Spec;
use File::Copy;
use File::Temp qw/ tempfile tempdir /;

use Test::FTP::Server::Server;

sub new {
	my $class = shift;
	my (%opt) = @_;

	my @args = ();

	if (my $users = $opt{'users'}) {
		foreach my $u (@$users) {
			if (my $base = $u->{'sandbox'}) {

				croak($base . ' is not directory.') unless -d $base;

				my $dir = tempdir(CLEANUP => 1);
				File::Find::find({
					'wanted' => sub {
						my $src = my $dst = $_;
						$dst =~ s/^$base//;
						$dst = File::Spec->catfile($dir, $dst);

						if (-d $_) {
							mkdir($dst);
						}
						else {
							File::Copy::copy($src, $dst);
						}

						chmod((stat($src))[2], $dst);
						utime((stat($src))[8,9], $dst);
					},
					'no_chdir' => 1,
				}, $base);

				$u->{'root'} = $dir;
			}

			croak(
				'It\'s necessary to specify parameter that is ' .
				'"root" or "sandbox" for each user.'
			) unless $u->{'root'};

			croak($u->{'root'} . ' is not directory.') unless -d $u->{'root'};
			croak('"user" is required.') unless $u->{'user'};
			croak('"pass" is required.') unless $u->{'pass'};

			$u->{'root'} =~ s{/+$}{};
		}
		push(@args, '_test_users', $users);
	}

	if ($opt{'ftpd_conf'}) {
		if (ref $opt{'ftpd_conf'}) {
			my ($fh, $filename) = tempfile();
			while (my ($k, $v) = each %{ $opt{'ftpd_conf'} }) {
				print($fh "$k: $v\n");
			}
			close($fh);

			push(@args, '-C', $filename);
		}
		else {
			push(@args, '-C', $opt{'ftpd_conf'});
		}
	}

	my $self = bless({ 'args' => \@args }, $class);
}

sub run {
	my $self = shift;
	Test::FTP::Server::Server->run($self->{'args'});
}

1;
__END__

=head1 NAME

Test::FTP::Server - ftpd runner for tests

=head1 SYNOPSIS

  use Test::TCP;
  use Test::FTP::Server;

  my $user = 'testuser';
  my $pass = 'testpass';
  my $root_directory = '/path/to/root_directory';

  my $server = Test::FTP::Server->new(
    'users' => [{
      'user' => $user,
      'pass' => $pass,
      'root' => $root_directory,
    }],
    'ftpd_conf' => {
      'port' => $port,
      'daemon mode' => 1,
      'run in background' => 0,
    },
  );
  $server->run;

or

  use Test::TCP;
  use Test::FTP::Server;

  my $user = 'testuser';
  my $pass = 'testpass';
  my $sandbox_base = '/path/to/sandbox_base';

  my $server = Test::FTP::Server->new(
    'users' => [{
      'user' => $user,
      'pass' => $pass,
      'sandbox' => $sandbox_base,
    }],
    'ftpd_conf' => {
      'port' => $port,
      'daemon mode' => 1,
      'run in background' => 0,
    },
  );
  $server->run;

=head1 DESCRIPTION

C<Test::FTP::Server> run C<Net::FTPServer> internally.
The server's settings can be specified as a parameter, therefore it is not necessary to prepare the configuration file.

=head1 FUNCTIONS

=head2 new

Create a ftpd instance.

B<%options>

=over 3

=item C<users>

Definition of users.

C<user> and C<pass> are used for login.

If C<root> is specified, ftpd behaves as if the specified directory is the root directory. 

If C<sandbox> is specified, The content of sandbox is copied into the temporary directory, and ftpd behaves as if the temporary directory is the root directory. The content of sandbox never changes by the user's operation.

It is necessary to specify "root" or "sandbox". 

=item C<ftpd_conf>

The settings that is usually specified in "/etc/ftpd.conf" when using  L<Net::FTPServer>.

Specified by the hash reference. 

=back


=head2 run

Run a ftpd instance. 


=head1 EXAMPLE

  use Test::FTP::Server;
  use Test::TCP;
  use Net::FTP;

  my $user = 'testid';
  my $pass = 'testpass';
  my $sandbox_base = '/path/to/sandbox_base';

  test_tcp(
    server => sub {
      my $port = shift;

      Test::FTP::Server->new(
        'users' => [{
          'user' => $user,
          'pass' => $pass,
          'sandbox' => $sandbox_base,
        }],
        'ftpd_conf' => {
          'port' => $port,
          'daemon mode' => 1,
          'run in background' => 0,
        },
      )->run;
    },
    client => sub {
      my $port = shift;

      my $ftp = Net::FTP->new('localhost', Port => $port);
      ok($ftp);
      ok($ftp->login($user, $pass));
      ok($ftp->quit);
    },
  );

=head1 NOTES

=over 4

=item *

Test::FTP::Server is for test use only. "root" and "sandbox" is not using chroot to keep available for any user. Therefore, there is a security risk when a server opened to the public. 

=back

=head1 AUTHOR

Taku Amano E<lt>taku@toi-planning.netE<gt>

=head1 CONTRIBUTORS

Kazuhiro Osawa

Roy Storey

=head1 SEE ALSO

L<Net::FTPServer>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

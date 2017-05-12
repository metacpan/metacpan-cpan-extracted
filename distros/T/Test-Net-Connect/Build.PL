use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Net::Connect',
    license             => 'bsd',
    dist_author         => 'Nik Clayton <nik@FreeBSD.org>',
    dist_version_from   => 'lib/Test/Net/Connect.pm',
    requires => {
		 'Test::More' => 0,
		 'IO::Socket::INET' => 0,
    },
    add_to_cleanup      => [ 'Test-Net-Connect-*' ],
    sign		=> 1,
    create_readme	=> 1,
);

print <<EOM;

The automated tests need to be configured with host:port information
for a connection that you expect to work, and host:port information for
a connection that you expect to fail.

EOM

my %config = ();

my $host_port;
my($host, $port);

print <<EOM;
First, a host:port that you expect to connect to.  The default specifies
the SSH port on the localhost.

EOM

$host_port = $builder->prompt('host:port :', 'localhost:22');

($host, $port) = split(/:/, $host_port, 2);

$builder->config_data(good_host => $host);
$builder->config_data(good_port => $port);

print <<EOM;

Now, an IP address:port that you expect to connect to.  The default specifies
the SSH port on 127.0.0.1 (localhost).

EOM

$host_port = $builder->prompt('ip:port :', '127.0.0.1:22');

$builder->config_data(good_ip => $host_port);

print <<EOM;

Finally, a host:port that you do not expect to connect to.  Note that the
host must exist in order for the tests to work, but it should have nothing
listening on the specified port.  The default specifies the telnet port on
the localhost.

EOM

$host_port = $builder->prompt('host:port :', 'localhost:23');

($host, $port) = split(/:/, $host_port, 2);

$builder->config_data(bad_host => $host);
$builder->config_data(bad_port => $port);

$builder->create_build_script();

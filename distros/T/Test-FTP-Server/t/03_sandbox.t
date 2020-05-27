#!perl
##!perl -T

use strict;
use warnings;

use Test::More;

use File::Spec;
use File::Basename;
use File::Temp qw/ tempfile /;

use Test::FTP::Server;
use Test::TCP;

use Net::FTP;

my $user = 'testid';
my $pass = 'testpass';
(my $sandbox = __FILE__) =~ s/\.t$//;
(my $samplefile = __FILE__) =~ s/\.t$/.txt/;

test_tcp(
	server => sub {
		my $port = shift;

		Test::FTP::Server->new(
			'users' => [{
				'user' => $user,
				'pass' => $pass,
				'sandbox' => $sandbox,
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

		my $ftp = Net::FTP->new('127.0.0.1', Port => $port);
		ok($ftp);
		ok($ftp->login($user, $pass));
		is(
			join(',', sort($ftp->ls('/'))),
			join(',', sort(map(basename($_), glob(File::Spec->catfile($sandbox, '*')))))
		);


		my ($dir) =  grep(-d $_, glob(File::Spec->catfile($sandbox, '*')));
		ok($ftp->cwd('/' . basename($dir)), 'change directory');
		my @files =  glob(File::Spec->catfile($dir, '*'));
		is(join('', @{ $ftp->ls() }), join('', map(basename($_), @files)), 'list file');

		my $file = $files[0];
		my ($fh, $fn) = tempfile();
		close($fh);
		ok($ftp->get(basename($file), $fn), 'get file');
		is(
			do{ local $/; open(my $fh, '<', $file); <$fh> },
			do{ local $/; open(my $fh, '<', $fn); <$fh> },
			'get same content'
		);


		my @current_sandbox_files =  glob(File::Spec->catfile($dir, '*'));
		ok($ftp->put($samplefile), 'put file');
		is(
			join('', sort(@{ $ftp->ls() })),
			join('', sort(map(basename($_), @files, $samplefile))),
			'list file (puted)'
		);
		isnt(
			join('', sort(@{ $ftp->ls() })),
			join('', sort(map(basename($_), @current_sandbox_files))),
			'base directory of sandbox was not changed.'
		);

		my ($fh2, $fn2) = tempfile();
		close($fh2);
		ok($ftp->get(basename($samplefile), $fn2), 'get file (puted)');
		is(
			do{ local $/; open(my $fh, '<', $samplefile); <$fh> },
			do{ local $/; open(my $fh, '<', $fn2); <$fh> },
			'get same content (puted)'
		);


		ok($ftp->quit());
	},
);

done_testing;

1;

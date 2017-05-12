#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for App file descriptor handling.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl App.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;
use strict;
use threads;
use Symbol;

use Test;
BEGIN { plan tests => 54 };
use Triceps;
use Carp;
use IO::Socket;
use IO::Socket::INET;
ok(1); # If we made it this far, we're ok.

#########################
# A lot of this is just the manual touch-tests.

sub ls # ($msg)
{
	# uncomment, to eyeball what is going on
	#print $_[0], "\n";
	#system("ls -l /proc/$$/fd");
}

Triceps::Triead::startHere(
	app => "a1",
	thread => "t1",
	main => sub {
		my $opts = {};
		&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
		my $owner = $opts->{owner};
		my $app = $owner->app();
		my ($fd, $fclass);

		# used for synchronization through draining
		my $faSync = $owner->makeNexus(
			name => "sync",
			import => "writer",
		);

		#############################
		# single-threaded, direct reuse

		open(A, "</dev/null") or confess "/dev/null error: $!";
		&ls("========= open");
		$app->storeFd("A", fileno(A), "");
		&ls("stored");
		close(A);
		&ls("closed orig");

		($fd, $fclass) = $app->loadFd("A");
		ok($fclass, "");
		open(A, "<&$fd");
		&ls("reopened");
		open(B, "<&$fd");
		&ls("reopened 2");

		close(A);
		close(B);
		&ls("closed copies");

		open(A, "<&=$fd");
		&ls("reopened = 1");
		open(B, "<&=$fd");
		&ls("reopened = 2");

		close(A);
		&ls("closed = 1");
		close(B);
		&ls("closed = 2");

		$app->forgetFd("A");
		
		#############################
		# load with a dup

		open(A, "</dev/null") or confess "/dev/null error: $!";
		&ls("========= open for dup");
		$app->storeFd("A", fileno(A), "CLASS");
		&ls("stored");
		close(A);
		&ls("closed orig");

		($fd, $fclass) = Triceps::App::loadDupFd("a1", "A");
		ok($fclass, "CLASS");
		&ls("dupped");
		open(A, "<&$fd");
		&ls("reopened");
		open(B, "<&$fd");
		&ls("reopened 2");

		close(A);
		close(B);
		&ls("closed copies");

		open(A, "<&=$fd");
		&ls("reopened = 1");
		open(B, "<&=$fd");
		&ls("reopened = 2");

		close(A);
		&ls("closed = 1");
		close(B);
		&ls("closed = 2");

		Triceps::App::closeFd("a1", "A");
		&ls("closed stored");

		#############################
		# multithreaded,

		open(A, "</dev/null") or confess "/dev/null error: $!";
		&ls("========= open MT");
		Triceps::App::storeFd("a1", "A", fileno(A), "");
		&ls("stored");
		close(A);
		&ls("closed orig");

		($fd, $fclass) = Triceps::App::loadFd("a1", "A");
		&ls("t1 loaded");
		open(A, "<&$fd");
		&ls("t1 reopened");

		Triceps::Triead::start(
			app => "a1",
			thread => "t2",
			main => sub {
				my $opts = {};
				&Triceps::Opt::parse("t2 main", $opts, {@Triceps::Triead::opts}, @_);
				my $owner = $opts->{owner};
				my $app = $owner->app();
				my ($fd, $fclass);

				my $faSync = $owner->importNexus(
					from => "t1/sync",
					import => "reader",
				);

				($fd, $fclass) = Triceps::App::loadFd("a1", "A");
				&ls("t2 loaded");
				open(A, "<&$fd");
				&ls("t2 reopened");

				$owner->readyReady();

				close(A);
				&ls("t2 closed");
			},
		);
		$owner->readyReady();

		Triceps::AutoDrain::makeShared($owner);

		close(A);
		&ls("t1 closed");

		$app->closeFd("A");
		&ls("closed stored");

if (0) {
		#############################
		# multithreaded, load with =
		# THIS DOES NOT WORK, NO COORDINATION BETWEEN PERL FILES IN DIFFERENT THREADS

		open(A, "</dev/null") or confess "/dev/null error: $!";
		&ls("========= open MT for <&=");
		Triceps::App::storeFd("a1", "A", fileno(A), "");
		&ls("stored");
		close(A);
		&ls("closed orig");

		($fd, $fclass) = Triceps::App::loadFd("a1", "A");
		&ls("t1 loaded");
		open(A, "<&=$fd");
		&ls("t1 reopened");

		Triceps::Triead::start(
			app => "a1",
			thread => "t3",
			main => sub {
				my $opts = {};
				&Triceps::Opt::parse("t3 main", $opts, {@Triceps::Triead::opts}, @_);
				my $owner = $opts->{owner};
				my $app = $owner->app();
				my ($fd, $fclass);

				my $faSync = $owner->importNexus(
					from => "t1/sync",
					import => "reader",
				);

				($fd, $fclass) = Triceps::App::loadFd("a1", "A");
				&ls("t2 loaded");
				open(A, "<&=$fd");
				&ls("t2 reopened");

				$owner->readyReady();

				close(A);
				&ls("t2 closed");
			},
		);
		$owner->readyReady();

		Triceps::AutoDrain::makeShared($owner);

		close(A);
		&ls("t1 closed");

		Triceps::App::forgetFd("a1", "A");
		&ls("forgot stored");
}

		#############################
		# multithreaded, load with =, must dup for each thread

		open(A, "</dev/null") or confess "/dev/null error: $!";
		&ls("========= open MT for dup <&=");
		Triceps::App::storeFd("a1", "A", fileno(A), "");
		&ls("stored");
		close(A);
		&ls("closed orig");

		($fd, $fclass) = Triceps::App::loadDupFd("a1", "A");
		&ls("t1 loaded");
		open(A, "<&=$fd");
		&ls("t1 reopened");

		Triceps::Triead::start(
			app => "a1",
			thread => "t4",
			main => sub {
				my $opts = {};
				&Triceps::Opt::parse("t4 main", $opts, {@Triceps::Triead::opts}, @_);
				my $owner = $opts->{owner};
				my $app = $owner->app();
				my ($fd, $fclass);

				my $faSync = $owner->importNexus(
					from => "t1/sync",
					import => "reader",
				);

				($fd, $fclass) = Triceps::App::loadDupFd("a1", "A");
				&ls("t2 loaded");
				open(A, "<&=$fd");
				&ls("t2 reopened");

				$owner->readyReady();

				close(A);
				&ls("t2 closed");
			},
		);
		$owner->readyReady();

		Triceps::AutoDrain::makeShared($owner);

		undef $!;
		close(A);
		ok($!, "");
		&ls("t1 closed");

		$app->closeFd("A");
		&ls("closed stored");
	},
);
ok(1);

my $n1; # the first descriptor that gets dupped to

# the small tests, and errors
Triceps::Triead::startHere(
	app => "a1",
	thread => "t1",
	main => sub {
		my $opts = {};
		&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
		my $owner = $opts->{owner};
		my $app = $owner->app();
		my ($fdr, $fclass);

		eval { $app->storeFd("x", -1, ""); };
		ok($@, qr/^Triceps::App::storeFd: dup failed: Bad file descriptor/);

		$app->storeFd("x", 0, "");
		($n1, $fclass) = $app->loadFd("x");
		my $n2 = $n1+1;
		eval { $app->storeFd("x", 1, ""); };
		ok($@, qr/^store of duplicate descriptor 'x', new fd=$n2, existing fd=$n1/);

		# check that the failed descriptor got closed
		$app->storeFd("y", 0, "");
		($fdr, $fclass) = $app->loadFd("y");
		ok($fdr, $n2);

		my $dup;
		($dup, $fclass) = $app->loadDupFd("x");
		ok($dup, $n2+1);
		ok($fclass, "");
		open(F, "<&=$dup") or die "$!";
		close(F) or die "$!";

		eval { $app->loadFd("z"); };
		ok($@, qr/^Triceps::App::loadFd: unknown file descriptor 'z'/);
		eval { $app->loadDupFd("z"); };
		ok($@, qr/^Triceps::App::loadDupFd: unknown file descriptor 'z'/);

		eval { $app->forgetFd("z"); };
		ok($@, qr/^Triceps::App::forgetFd: unknown file descriptor 'z'/);
		eval { $app->closeFd("z"); };
		ok($@, qr/^Triceps::App::closeFd: unknown file descriptor 'z'/);

		# the successfull close
		$app->closeFd('y');

		# the successful forget ($n1 still contains 'x')
		$app->forgetFd('x');
		open(F, "<&=$n1") or die "$!";
		close(F) or die "$!";

		# now store one more fd, to check that the App destruction closes it
		$app->storeFd("z", 0, "");
		($fdr, $fclass) = $app->loadFd("z");
		ok($fdr, $n1);
	},
);

Triceps::Triead::startHere(
	app => "a1",
	thread => "t1",
	main => sub {
		my $opts = {};
		&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
		my $owner = $opts->{owner};
		my $app = $owner->app();
		my ($fdr, $fclass);

		# store the file handle;
		# along the way check that the previous App closed its fds
		$app->storeFile("z", *STDIN);
		($fdr, $fclass) = $app->loadFd("z");
		ok($fdr, $n1);
		ok($fclass, "");

		# restore as file handles
		my $f1 = $app->loadDupFileClass("z", "<", "IO::Handle") or die "$!";
		ok(ref $f1, "IO::Handle");
		$f1->close() or die "$!";

		my $f2 = $app->loadDupFile("z", "<") or die "$!";
		ok(ref $f2, "IO::Handle");
		$f2->close() or die "$!";
	},
);

# the load-and-track calls
Triceps::Triead::startHere(
	app => "a1",
	thread => "t1",
	main => sub {
		my $opts = {};
		&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
		my $owner = $opts->{owner};
		my $app = $owner->app();

		my $file = gensym();
		open($file, '</dev/null') or die "$!";
		my $fd = fileno($file);

		{
			my $trf = $owner->makeTrackedFile($file);
			ok(ref $trf, "Triceps::TrackedFile");

			ok($trf->fd(), $fd);
			my $copyf = $trf->get();
			ok(fileno($copyf), $fd);
			ok($copyf, $file);
			undef $file; # remove that first reference
		}

		$file = gensym();
		open($file, '</dev/null') or die "$!";
		my $fd2 = fileno($file);

		# if the first file is closed, the second would get the same fd
		ok($fd2, $fd);

		# now repeat the same stuff, only with an explicit close
		{
			my $trf = $owner->makeTrackedFile($file);
			ok(ref $trf, "Triceps::TrackedFile");

			ok($trf->fd(), $fd);
			my $copyf = $trf->get();
			ok(fileno($copyf), $fd);
			ok($copyf, $file);

			$trf->close();

			# the next file reopened should get the same fd
			$file = gensym();
			open($file, '</dev/null') or die "$!";
			$fd2 = fileno($file);
			ok($fd2, $fd);
			close($file);

			# reading from trf will return errors now
			eval { $trf->fd(); };
			ok($@, qr/^Triceps::TrackedFile::fd: the file is already closed/);
			eval { $trf->get(); };
			ok($@, qr/^Triceps::TrackedFile::get: the file is already closed/);
		}

		{
			$app->storeFile("z", *STDIN);
			my ($fdr, $fclass) = $app->loadFd("z");
			ok($fdr, $n1);
			ok($fclass, "");
			my ($trf, $ff) = $owner->trackDupFile("z", "<");
			ok(ref $trf, "Triceps::TrackedFile");
			ok(ref $ff, "IO::Handle");
			$app->closeFd("z");
		}
		{
			my $sock = IO::Socket::INET->new(
				Proto => "tcp",
				LocalPort => 0,
				Listen => 10,
			) or confess "socket failed: $!";
			my $port = $sock->sockport();

			$app->storeCloseFile("z", $sock);

			my ($trf, $ff) = $owner->trackDupFile("z", "<");
			ok(ref $trf, "Triceps::TrackedFile");
			ok(ref $ff, "IO::Socket::INET");

			my $port2 = $trf->get()->sockport();
			ok($port2, $port);
			ok($ff->sockport(), $port);

			($trf, $ff) = $owner->trackDupClass("z", "<", "IO::Socket::INET");
			ok(ref $trf, "Triceps::TrackedFile");
			ok(ref $ff, "IO::Socket::INET");

			$port2 = $trf->get()->sockport();
			ok($port2, $port);
			ok($ff->sockport(), $port);

			$app->closeFd("z");
		}
		{
			$app->storeFile("z", *STDIN);
			my ($fdr, $fclass) = $app->loadFd("z");
			ok($fdr, $n1);
			ok($fclass, "");
			my ($trf, $ff) = $owner->trackGetFile("z", "<");
			ok(ref $trf, "Triceps::TrackedFile");
		}
		{
			my $sock = IO::Socket::INET->new(
				Proto => "tcp",
				LocalPort => 0,
				Listen => 10,
			) or confess "socket failed: $!";
			my $port = $sock->sockport();

			$app->storeFile("z", $sock);
			$app->storeFile("y", $sock);

			my ($trf, $ff) = $owner->trackGetFile("z", "<");
			ok(ref $trf, "Triceps::TrackedFile");

			my $port2 = $trf->get()->sockport();
			ok($port2, $port);
			ok($ff->sockport(), $port);

			($trf, $ff) = $owner->trackGetClass("y", "<", "IO::Socket::INET");
			ok(ref $trf, "Triceps::TrackedFile");

			$port2 = $trf->get()->sockport();
			ok($port2, $port);
			ok($ff->sockport(), $port);
		}

		# the next file reopened should get the same fd as before
		$file = gensym();
		open($file, '</dev/null') or die "$!";
		$fd2 = fileno($file);
		ok($fd2, $fd);
		close($file);
	},
);

# check that the load-and-track calls actually do track and the reads et interrupted
Triceps::Triead::startHere(
	app => "a1",
	thread => "t1",
	main => sub {
		my $opts = {};
		&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
		my $owner = $opts->{owner};
		my $app = $owner->app();

		my $sock = IO::Socket::INET->new(
			Proto => "tcp",
			LocalPort => 0,
			Listen => 10,
		) or confess "socket failed: $!";

		$app->storeCloseFile("z", $sock);
		undef $sock;

		Triceps::Triead::start(
			app => "a1",
			thread => "t4",
			main => sub {
				my $opts = {};
				&Triceps::Opt::parse("t4 main", $opts, {@Triceps::Triead::opts}, @_);
				my $owner = $opts->{owner};
				my $app = $owner->app();

				my ($trf, $sock) = $owner->trackGetFile("z", "+<");
				$owner->readyReady();

				do {
					$sock->accept(); # will be stuck here until revoked
				} while($!{EAGAIN} || $!{EINTR}); # this ignores the signal on shutdown
			},
		);

		$owner->readyReady();
		$app->shutdown();
	},
);
ok(1);

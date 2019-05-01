# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Unix-Pledge.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use BSD::Resource qw(RLIMIT_CORE setrlimit);
use File::Temp;
use IO::Socket;

use Test::More tests => 11;
BEGIN { use_ok('Unix::Pledge') };

my $TESTS = {
    "stdio only, ok" => {
        aborts => 0,
        run => sub {
            pledge("stdio");
            print "test test\n";
        }
    },
    "compute only, aborts" => {
        aborts => 1,
        run => sub {
            pledge("");
            print "test test\n";
        }
    },
    "stdio only, aborts opening a socket" => {
        aborts => 1,
        run => sub {
            pledge("stdio");
            IO::Socket::INET->new('open a socket');
        }
    },
    "File::Temp, ok" => {
        aborts => 0,
        run => sub {
            pledge("stdio rpath flock fattr tmppath");
            my $fh = File::Temp::tempfile();

            pledge("stdio");
            print $fh "temp data\n";
            close $fh;
        }
    },
    "File::Temp, aborts no flock" => {
        aborts => 1,
        run => sub {
            pledge("stdio rpath fattr tmppath");
            my $fh = File::Temp::tempfile();
        }
    },
    "File::Temp, ok no flock" => {
        aborts => 0,
        run => sub {
            pledge("stdio rpath fattr tmppath");
            my $fh = File::Temp::tempfile(EXLOCK => 0);
        }
    },
    "UNIX Socket, ok" => {
        aborts => 0,
        run => sub {
            pledge("stdio unix");
            IO::Socket::UNIX->new(Listen => 1, Local => "/tmp/unix-pledge-test-socket");
        }
    },
    "INET Socket, ok" => {
        aborts => 0,
        run => sub {
            pledge("stdio dns inet");
            IO::Socket::INET->new(
                LocalAddr => '127.0.0.1',
                Proto => 'udp'
            );
        }
    },
    "Blacklist file" => {
        aborts => 1,
        run => sub {
            use File::Temp;
            my $parent = File::Temp::tempdir(CLEANUP => 0); # would break veil
            mkdir "$parent/bad";
            mkdir "$parent/good";
            my (undef, $bad)  = File::Temp::tempfile('X'x10, DIR => "$parent/bad");
            my (undef, $good) = File::Temp::tempfile('X'x10, DIR => "$parent/good");

            unveil("$parent/good", 'r');
            unveil;

            open(my $fh1, '<', $bad) and return;
            exit 1;
        },
    },
    "Whitelist file" => {
        aborts => 0,
        run => sub {
            use File::Temp;
            my $parent = File::Temp::tempdir(CLEANUP => 0); # would break veil
            my (undef, $file) = File::Temp::tempfile('X'x10, DIR => $parent);

            unveil($parent, 'r');
            unveil;

            open(my $fh1, '<', $file) and return;
            exit 1;
        },
    },
};

for (sort keys %$TESTS) {
    my ($name, $test) = ($_, $TESTS->{$_});
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid) {
        wait;
        ok($test->{aborts} ? $? != 0 : $? == 0, $name);
    }
    else {
        setrlimit(RLIMIT_CORE, 0, 0); # No core dumps from SIGABRT
        $test->{run}();
        exit 0;
    }
}

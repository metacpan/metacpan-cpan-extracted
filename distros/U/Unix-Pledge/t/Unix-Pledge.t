# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Unix-Pledge.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use File::Temp;
use IO::Socket;

use Test::More tests => 9;
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
# Disabled this test since pledge(2) will not initially support
# whitelists in OpenBSD 5.9
#
#    "Whitelist file" => {
#        aborts => 0,
#        run => sub {
#            use File::Temp;
#            my ($fh, $filename) = File::Temp::tempfile();
#
#            pledge("stdio rpath", ["$filename-to-some-other-file"]);
#
#            # File not found though it's there
#            open(my $fh2, "<", $filename) or return;
#            exit 1;
#        },
#    },
};


while (my ($name, $test) = each %$TESTS) {
    if (fork) {
        wait;
        ok($test->{aborts} ? $? != 0 : $? == 0, $name);
    }
    else {
        $test->{run}();
        exit 0;
    }
}

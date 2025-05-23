use strict;
use warnings;
use DBI;

use FindBin qw($Bin);
use IO::Socket::INET;
use MogileFS::Server;

sub find_mogclient_or_skip {

    # needed for running "make test" from project root directory, with
    # full svn 'mogilefs' repo checked out, without installing
    # MogileFS::Client to normal system locations...
    #
    # then, second path is when running "make disttest", which is another
    # directory below.
    foreach my $dir ("$Bin/../../api/perl/MogileFS-Client/lib",
                     "$Bin/../../../api/perl/MogileFS-Client/lib",
                     ) {
        next unless -d $dir;
        unshift @INC, $dir;
        $ENV{PERL5LIB} = $dir . ($ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : "");
    }

    unless (eval "use MogileFS::Client; 1") {
        warn "Can't find MogileFS::Client: $@\n";
        Test::More::plan('skip_all' => "Can't find MogileFS::Client library, necessary for testing.");
    }

    unless (eval { TrackerHandle::_mogadm_exe() }) {
        warn "Can't find mogadm utility.\n";
        Test::More::plan('skip_all' => "Can't find mogadm executable, necessary for testing.");
    }

    return 1;
}

sub temp_store {
    my $type = $ENV{MOGTEST_DBTYPE};

    # default to mysql, but make sure DBD::MySQL is installed
    unless ($type) {
        $type = "MySQL";
        eval "use DBD::mysql; 1" or
            die "DBD::mysql isn't installed.  Please install it or define MOGTEST_DBTYPE env. variable";
    }

    die "Bogus type" unless $type =~ /^\w+$/;
    my $store = "MogileFS::Store::$type";
    eval "use $store; 1;";
    if ($@) {
        die "Failed to load $store: $@\n";
    }
    my $sto = $store->new_temp;
    Mgd::set_store($sto);
    return $sto;
}


sub create_temp_tracker {
    my $sto = shift;
    my $opts = shift || [];

    my $pid = fork();
    my $whoami = `whoami`;
    chomp $whoami;

    my $connect = sub {
        return IO::Socket::INET->new(PeerAddr => "127.0.0.1:7001",
                                     Timeout  => 2);
    };

    my $conn = $connect->();
    die "Failed:  tracker already running on port 7001?\n" if $conn;

    unless ($pid) {
        exec("$Bin/../mogilefsd",
             ($whoami eq "root" ? "--user=root" : ()),
             "--skipconfig",
             "--workers=2",
             "--dsn=" . $sto->dsn,
             "--dbuser=" . $sto->user,
             "--dbpass=" . $sto->pass,
             @$opts,
             );
    }

    for (1..3) {
        if ($connect->()) {
            return TrackerHandle->new(pid => $pid);
        }
        sleep 1;
    }
    return undef;
}

sub create_mogstored {
    my ($ip, $root, $daemonize) = @_;

    my $connect = sub {
        return IO::Socket::INET->new(PeerAddr => "$ip:7500",
                                     Timeout  => 2);
    };

    my $conn = $connect->();
    die "Failed:  tracker already running on port 7500?\n" if $conn;

    my @args = ("$Bin/../mogstored",
                "--httplisten=$ip:7500",
                "--mgmtlisten=$ip:7501",
                "--maxconns=1000",  # because we're not root, put it below 1024
                "--docroot=$root");

    my $pid;
    if ($daemonize) {
        # don't set pid.  since our fork fid would just
        # go away, once perlbal daemonized itself.
        push @args, "--daemonize";
        system(@args) and die "Failed to start daemonized mogstored.";
    } else {
        $pid = fork();
        die "failed to fork: $!" unless defined $pid;
        unless ($pid) {
            exec(@args);
        }
    }

    for (1..12) {
        if ($connect->()) {
            return MogstoredHandle->new(pid => $pid, ip => $ip, root => $root);
        }
        select undef, undef, undef, 0.25;
    }
    return undef;
}

############################################################################
package ProcessHandle;
sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub pid { return $_[0]{pid} }

sub DESTROY {
    my $self = shift;
    return unless $self->{pid};
    kill 15, $self->{pid};
}


############################################################################

package TrackerHandle;
use base 'ProcessHandle';

sub ipport {
    my $self = shift;
    return "127.0.0.1:7001";
}

my $_mogadm_exe_cache;
sub _mogadm_exe {
    return $_mogadm_exe_cache if $_mogadm_exe_cache;
    foreach my $exe ("$FindBin::Bin/../../utils/mogadm",
                     "$FindBin::Bin/../../../utils/mogadm",
                     "/usr/bin/mogadm",
                     "/usr/sbin/mogadm",
                     ) {
        return $_mogadm_exe_cache = $exe if -x $exe;
    }
    die "mogadm executable not found.\n";
}

sub mogadm {
    my $self = shift;
    my $rv = system(_mogadm_exe(), "--trackers=" . $self->ipport, @_);
    return !$rv;
}

############################################################################
package MogstoredHandle;
use base 'ProcessHandle';

# this space intentionally left blank.  all in super class for now.

############################################################################
package MogPath;
sub new {
    my ($class, $url) = @_;
    return bless {
        url => $url,
    }, $class;
}

sub host {
    my $self = shift;
    my ($host1) = $self->{url} =~ m!^http://(.+:\d+)!;
    return $host1
}

sub device {
    my $self = shift;
    my ($dev) = $self->{url} =~ m!dev(\d+)!;
    return $dev
}

sub path {
    my $self = shift;
    my $path = $self->{url};
    $path =~ s!^http://(.+:\d+)!!;
    return $path;
}

1;

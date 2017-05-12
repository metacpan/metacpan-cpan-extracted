#!perl -w

use strict;
use warnings;

use Test::More tests => 80 + 1;    # +1 is for NoWarnings
use Test::NoWarnings;

use Test::Warn;
use File::Slurp;
use File::Temp;
my $dir = File::Temp->newdir();

our $current_kill  = sub { diag( "kill: " . explain( \@_ ) ) };
our $current_sleep = sub { diag( "sleep: " . explain( \@_ ) ) };

BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::sleep = sub { $current_sleep->(@_) };    # needs to happen before Unix::PID::Tiny is brought in
}

use Unix::PID::Tiny;

BEGIN {
    no warnings 'redefine';
    *Unix::PID::Tiny::_kill = sub { $current_kill->(@_) };
}

#############
#### new() ##
#############

is( \&Unix::PID::Tiny::pid_file_no_cleanup, \&Unix::PID::Tiny::pid_file_no_unlink, 'pid_file_no_cleanup() is the same as pid_file_no_unlink()' );

my $p = Unix::PID::Tiny->new();
is( $p->{'minimum_pid'}, 11, "new() no args gives default minimum_pid" );
is( $p->{'ps_path'},     "", "new() no args has empty ps_path" );

my $x = Unix::PID::Tiny->new( { minimum_pid => 42, ps_path => "/bin" } );
my $s = Unix::PID::Tiny->new( { ps_path => "/bin/" } );
is( $x->{'minimum_pid'}, 42, "new() minimum_pid attr is set when given and valid" );
SKIP: {
    skip "/bin/ps is not executable", 2 unless -x '/bin/ps';
    is( $x->{'ps_path'}, '/bin/', "new() ps_path attr is set when given and valid (slash added)" );
    is( $s->{'ps_path'}, '/bin/', "new() ps_path attr is set when given and valid (slash not removed)" );
}

write_file( "$dir/imafile", "from $$" );
my $non_dir = Unix::PID::Tiny->new( { ps_path => "$dir/imafile" } );
is( $non_dir->{'ps_path'}, "", "new() ps_path is empty when given a non-dir" );

my $no_ps = Unix::PID::Tiny->new( { ps_path => $dir } );
is( $no_ps->{'ps_path'}, "", "new() ps_path is empty when given a dir without ps" );

write_file( "$dir/ps", "from $$" );
chmod 0644, "$dir/ps";
my $no_exec = Unix::PID::Tiny->new( { ps_path => $dir } );
is( $no_exec->{'ps_path'}, "", "new() ps_path is empty when given a dir whose ps is non-executable" );

############
#### kill ##
############

{
    warning_like {
        ok( !$x->kill(41), "kill() returns false when given PID is less than minimum_pid" );
    }
    qr/kill\(\) called with integer value less than 42/, "kill() does warn() when given PID is less than minimum_pid";

    # PID is not running
    my $kill_called  = 0;
    my $sleep_called = 0;
    my $is_pid_running;
    local $current_kill  = sub { $kill_called++ };
    local $current_sleep = sub { $sleep_called++ };

    no warnings 'redefine';
    local *Unix::PID::Tiny::is_pid_running = sub { $is_pid_running = $_[1]; return; };

    ok( $p->kill( 42, 2 ), 'kill() on pid that is not running: returns true (i.e. already dead)' );
    is( $kill_called,    0,  'kill() on pid that is not running: kill not called' );
    is( $sleep_called,   0,  'kill() on pid that is not running: sleep not called' );
    is( $is_pid_running, 42, "kill() on pid that is not running: is_pid_running () called w/ correct PID" );

    # PID is running:
    *Unix::PID::Tiny::is_pid_running = sub { $is_pid_running = $_[1]; return 1; };
    $kill_called = [];
    $current_kill = sub { push @{$kill_called}, \@_ };
    ok( !$p->kill(23), 'kill() on pid that is running: return false when pid is still running after kill' );
    is( $sleep_called, 0, 'kill() on pid that is running: sleep not called w/ no give_kill_a_chance' );
    is_deeply(
        $kill_called, [
            [ 15, 23 ], [ 2, 23 ], [ 1, 23 ], [ 9, 23 ]
        ], 'kill() on pid that is running: kill called in correct order'
    );

    $current_sleep = sub { $sleep_called++; is( $_[0], 9, "kill() on pid that is running: sleep called w/ correct value w/ give_kill_a_chance" ); };
    *Unix::PID::Tiny::is_pid_running = sub {
        *Unix::PID::Tiny::is_pid_running = sub { return };
        return 1;
    };
    ok( $p->kill( 51, 9 ), 'kill() on pid that is running: return true when pid is no longer running after kill' );
    is( $sleep_called, 1, 'kill() on pid that is running: sleep called once w/ give_kill_a_chance' );
}

######################
#### is_pid_running ##
######################

{
    warnings_like {
        ok( !$p->is_pid_running("not numeric"), "is_pid_running(): bad arg returns false: string" );
        ok( !$p->is_pid_running(0),             "is_pid_running(): bad arg returns false: zero" );
        ok( !$p->is_pid_running(-99),           "is_pid_running(): bad arg returns false: negative" );
        ok( !$p->is_pid_running(""),            "is_pid_running(): bad arg returns false: empty" );
        ok( !$p->is_pid_running(undef),         "is_pid_running(): bad arg returns false: undef explicit" );
        ok( !$p->is_pid_running(),              "is_pid_running(): bad arg returns false: undef implicit" );
    }
    [ qr/isn\'t numeric in int/, qr/isn\'t numeric in int/, qr/Use of uninitialized value/, qr/Use of uninitialized value/ ], "is_pid_running(): Weird args give weird warnings";

  SKIP: {
        skip "need to be root to run these tests", 8 unless $> == 0;
        my @kill;
        local $current_kill = sub { push @kill, \@_; return 1 };

        my @ps;
        no warnings 'redefine';
        local *Unix::PID::Tiny::_raw_ps = sub { shift; push @ps, \@_; return ( "foo", "bar" ) };

        $p->is_pid_running(0);
        is_deeply( \@kill, [], "is_pid_running(): invalid arg does not get past initial check" );

        # kill(0) return true == return true then
        ok( $p->is_pid_running(42), "is_pid_running(): kill(0) return true" );
        is_deeply( \@kill, [ [ 0, 42 ] ], "is_pid_running(): kill(0) called w/ correct args" );

        # kill(0) return false == moves on to other logic
        $current_kill = sub { push @kill, \@_; return };

        my $didproc = 0;
      SKIP: {
            skip "no /proc", 1 if !-r "/proc/$$";
            $didproc = 1;
            $p->is_pid_running($$);
            is_deeply( \@ps, [], "is_pid_running(): _raw_ps not called when /proc check runs and is valid" );
        }

        my $rv = $p->is_pid_running(23);

        is_deeply( \@kill, [ [ 0, 42 ], ( $didproc ? [ 0, $$ ] : () ), [ 0, 23 ] ], "is_pid_running(): kill(0) called w/ correct args (when rv false)" );

      SKIP: {
            skip "test /proc/23 exists", 2 if -r "/proc/23";
            ok( $rv, "is_pid_running(): returns true via _raw_ps()" );
            is_deeply( \@ps, [ [ 'u', '-p', 23 ] ], "is_pid_running(): _raw_ps called w/ correct args" );
        }

      SKIP: {
            *Unix::PID::Tiny::_raw_ps = sub { return };
            skip "test /proc/14 exists", 1 if -r "/proc/14";
            ok( !$p->is_pid_running(14), "is_pid_running(): returns false via _raw_ps()" );
        }
    }
}

#####################
#### pid_info_hash ##
#####################

{
    no warnings 'redefine';
    local *Unix::PID::Tiny::_raw_ps = sub { return ( "foo bar baz bar wop zap zig jim jag jam zog zim\n", "1 2 3 4 5 6 7 8 9 10 11 12\n" ) };

    my %res = $p->pid_info_hash(100);
    my $res = $p->pid_info_hash(101);

    my $exp = {
        'bar'     => '4',
        'baz'     => '3',
        'foo'     => '1',
        'jag'     => '9',
        'jam'     => '10',
        'jim'     => '8',
        'wop'     => '5',
        'zap'     => '6',
        'zig'     => '7',
        'zog zim' => '11 12'

    };
    is_deeply( \%res, $exp, "pid_info_hash(): returns hash in array context (w/ 11 columns)" );
    is_deeply( $res,  $exp, "pid_info_hash(): returns hashref in scalar context (w/ 11 columns)" );

    warnings_like {
        ok( !$p->pid_info_hash("not numeric"), "pid_info_hash(): bad arg returns false: string" );
        ok( !$p->pid_info_hash(0),             "pid_info_hash(): bad arg returns false: zero" );
        ok( !$p->pid_info_hash(-99),           "pid_info_hash(): bad arg returns false: negative" );
        ok( !$p->pid_info_hash(""),            "pid_info_hash(): bad arg returns false: empty" );
        ok( !$p->pid_info_hash(undef),         "pid_info_hash(): bad arg returns false: undef explicit" );
        ok( !$p->pid_info_hash(),              "pid_info_hash(): bad arg returns false: undef implicit" );
    }
    [ qr/isn\'t numeric in int/, qr/isn\'t numeric in int/, qr/Use of uninitialized value/, qr/Use of uninitialized value/ ], "pid_info_hash(): Weird args give weird warnings";
}

my $myps = $p->pid_info_hash($$);
is( $myps->{PID}, $$, "pid_info_hash(): calls ps and parses result" );

################
##### _raw_ps ##
################

my @ps = $p->_raw_ps($$);
is( @ps, 2, "_raw_ps: returns array in array context" );

my $ps = $p->_raw_ps($$);
my ($end) = reverse( split( /\s+/, $ps[1], 11 ) );
like( $ps, qr/^$ps[0]/,   "_raw_ps: returns single string in scalar context (begin)" );
like( $ps, qr/\Q$end\E$/, "_raw_ps: returns single string in scalar context (end)" );

############################
#### get_pid_from_pidfile ##
############################

is( $p->get_pid_from_pidfile("$dir/noexist.pid"), 0, "get_pid_from_pidfile: returns zerp on !-e pidfile" );

write_file( "$dir/jibby.pid", "42\n" );
is( $p->get_pid_from_pidfile("$dir/jibby.pid"), 42, "get_pid_from_pidfile: returns normalized value from pidfile" );

write_file( "$dir/jibby.pid", " -42 \n" );
is( $p->get_pid_from_pidfile("$dir/jibby.pid"), 42, "get_pid_from_pidfile: returns normalized value from pidfile (w/ complexly goofed up data)" );

##########################
#### is_pidfile_running ##
##########################

ok( !$p->is_pidfile_running("$dir/noexist.pid"), "is_pidfile_running: returns false when pidfile does not exist" );

{
    local $current_kill = sub { return 1 };
    write_file( "$dir/me.pid", $$ );
    is( $p->is_pidfile_running("$dir/me.pid"), $$, "is_pidfile_running: returns the pid (i.e. true) when its pid is still running" );
}

write_file( "$dir/me.pid", 12345 );
SKIP: {
    local $current_kill = sub { CORE::kill(@_) };
    skip "test pid is running", 1 if $p->is_pid_running(12345);
    $current_kill = sub { return };
    ok( !$p->is_pidfile_running("$dir/me.pid"), "is_pidfile_running: returns false when pidfile pid is not running" );
}

################
#### pid_file ##
################

{
    my @last_args;
    my $exp_rv = 1;
    no warnings 'redefine';
    local *Unix::PID::Tiny::pid_file_no_unlink = sub {
        @last_args = @_;
        return $exp_rv;
    };

    is( $p->pid_file("$dir/foo.pid"), 1, "pid_file: returns 1 when pid_file_no_unlink returns 1" );
    is_deeply( \@last_args, [ $p, "$dir/foo.pid", $$, undef() ], "pid_file: only one arg defaults to \$\$ and no conf" );

    $exp_rv = 0;
    is( $p->pid_file("$dir/foo.pid"), 0, "pid_file: returns 0 when pid_file_no_unlink returns 0" );

    $exp_rv = undef;
    is( $p->pid_file("$dir/foo.pid"), undef(), "pid_file: returns false when pid_file_no_unlink returns other than 1 or 0" );

    my $conf = {};
    $p->pid_file( "$dir/foo.pid", 42, $conf );
    is_deeply( \@last_args, [ $p, "$dir/foo.pid", 42, $conf ], "pid_file: different pid and conf passed through" );
}

# pidfile cleanup/behavior
SKIP: {
    my $pid = fork();

    skip "failed to fork()", 3 unless defined $pid;
    if ($pid) {

        # diag("parent: $$");
        waitpid( $pid, 0 );

        ok( !-e "$dir/pid_file_child.pid", "pid file gone on process END" );
        is( $p->get_pid_from_pidfile("$dir/child_res.txt"),            $pid, "sanity: fork pid_file used child’s PID" );
        is( $p->get_pid_from_pidfile("$dir/after_grandchild_res.txt"), $pid, "only the PID in the file cleans up pid file" );
    }
    else {
        # diag("child: $$");
        $p->pid_file("$dir/pid_file_child.pid");
        write_file( "$dir/child_res.txt", $p->get_pid_from_pidfile("$dir/pid_file_child.pid") );

        my $npid = fork();
        if ($npid) {

            # diag("new parent: $$");
            waitpid( $npid, 0 );
            write_file( "$dir/after_grandchild_res.txt", $p->get_pid_from_pidfile("$dir/pid_file_child.pid") );
        }
        else {
            # diag("grand child: $$);
            exit 0;
        }

        exit 0;
    }
}

##########################
#### pid_file_no_unlink ##
##########################

{
    local $current_kill = sub { return 1 };
    my @sleep;
    local $current_sleep = sub { push @sleep, \@_ };

    # 3 short circuit returns for when -e PIDFILE
    write_file( "$dir/exists_nu", $$ );
    is( $p->pid_file_no_unlink( "$dir/exists_nu", $$ ), 1, "pid_file_no_unlink: -e FILE rv is 1 when filepid is \$\$ and we're setting up \$\$" );
    ok( !$p->pid_file_no_unlink( "$dir/exists_nu", 123 ), "pid_file_no_unlink: -e FILE rv is false when filepid is \$\$ and we're not setting up \$\$" );

  SKIP: {
        my $pid = fork();

        skip "failed to fork()", 1 unless defined $pid;
        if ($pid) {

            # diag("parent: $$");
            waitpid( $pid, 0 );
            is( read_file("$dir/exists_nu.rv"), "false", "pid_file_no_unlink: -e FILE rv is false when filepid is not \$\$ and filepid is running" );
        }
        else {
            # diag("child: $$");
            write_file( "$dir/exists_nu", $$ );

            my $npid = fork();
            if ($npid) {

                # diag("new parent: $$");
                waitpid( $npid, 0 );
            }
            else {

                # diag("grand child: $$);
                my $rv = $p->pid_file_no_unlink("$dir/exists_nu");
                $rv = "false" if !defined $rv;
                write_file( "$dir/exists_nu.rv", $rv );

                exit 0;
            }

            exit 0;
        }
    }

    {
        my $sysopen_cnt = 0;
        no warnings 'redefine';
        local *Unix::PID::Tiny::_sysopen = sub {
            $sysopen_cnt++;
            return;
        };
        @sleep = ();
        is( $p->pid_file_no_unlink( "$dir/failopen", 12345 ), 0, "pid_file_no_unlink: return 0 when we can't sysopen the pidfile" );
        is_deeply( \@sleep, [ [1], [2] ], "default rety config is as expected" );
        is( $sysopen_cnt, 3, "retry count is first item in retry config" );

        @sleep = ();
        my $code = sub { ok( 1, 'given rety config is either CODE or > 0: CODE' ) };
        warning_like {
            is( $p->pid_file_no_unlink( "$dir/failopen", 12345, [ 7, 5, -37, $code, "this is not a zero", 53, 0 ] ), 0, "pid_file_no_unlink: return 0 when we can't sysopen the pidfile" );
        }
        qr/isn\'t numeric/, "pid_file_no_unlink(): bad args give warning from perl";

        is_deeply( \@sleep, [ [5], [37], [53] ], "given rety config is either CODE or > 0: > 0" );

        $sysopen_cnt = 0;
        @sleep       = ();
        $p->pid_file_no_unlink( "$dir/failopen", 12345, { num_of_passes => 4, passes_config => [ 23, 86, 99 ] } );
        is( $sysopen_cnt, 4, "retry count w/ both keys" );
        is_deeply( \@sleep, [ [23], [86], [99] ], "retry conf passes w/ both keys" );

        $sysopen_cnt = 0;
        @sleep       = ();
        $p->pid_file_no_unlink( "$dir/failopen", 12345, { num_of_passes => 8 } );
        is( $sysopen_cnt, 8, "retry count w/ only num_of_passes" );
        is_deeply( \@sleep, [ [1], [2] ], "retry conf passes w/ only num_of_passes" );

        $sysopen_cnt = 0;
        @sleep       = ();
        $p->pid_file_no_unlink( "$dir/failopen", 12345, { passes_config => [ 8, 9 ] } );
        is( $sysopen_cnt, 3, "retry count w/ only passes_config" );
        is_deeply( \@sleep, [ [8], [9] ], "retry conf passes w/ only passes_config" );
    }

    is( $p->pid_file_no_unlink( "$dir/mypid.$$.pid", $$ ), 1, "pid_file_no_unlink: returns true when it sets up the pidfile" );
}

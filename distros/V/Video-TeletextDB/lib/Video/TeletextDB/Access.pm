package Video::TeletextDB::Access;
use 5.006001;
use strict;
use warnings;
use Carp;
use DB_File;
use POSIX qw(ENOENT EWOULDBLOCK);
use Fcntl qw(F_GETFL O_CREAT O_RDWR O_RDONLY O_ACCMODE LOCK_NB LOCK_EX);
# use AutoLoader qw(AUTOLOAD);

use Video::TeletextDB::Constants qw(:BdbPrefixes :VTX :VBI DB_VERSION);
use Video::TeletextDB::Page qw(vote $epoch_time);

our $VERSION = "0.02";
use base qw(Video::TeletextDB::Parameters);

use Exporter::Tidy
    functions => [qw(tilde)],
    variables => [qw($default_cache_dir $default_page_versions)];

use constant MIN_STORES	=> 10000; # Must have at least 10000 stores
use constant DB_RO	=> "Video::TeletextDB::DB_RO";
use constant DB_RW	=> "Video::TeletextDB::DB_RW";

our @CARP_NOT = qw(Video::TeletextDB::Options);

our $default_cache_dir = "~/.TeletextDB/cache";
our $default_page_versions = 5;

# Database format:
#  V.	=> a*  (version)
#  s.	=> NNN (start time, number of stores, last store time)
#  S.	=> C   (page_versions)
#  c.nn  (page, subpage) => CN (last_counter, last_time)
#        There is a fake c."\xff"x4 at the end to make scanning easier
#  p.nnC (page, subpage, counter) =>
#           Na* (store time, join \xa, raw rows (without \xa))
#        There is a fake p."\xff"x5 at the end to make scanning easier

sub tilde {
    defined(my $file = shift) || croak "Undefined file";
    my ($user, $rest) = $file =~ m!^~([^/]*)(.*)\z!s or return $file;
    if ($user ne "") {
        my @pw = getpwnam($user) or croak "Could not find user $user";
        $user = $pw[7];
    } elsif (!defined($user = $ENV{HOME})) {
        my @pw = getpwuid($>) or
            croak "Could not determine who you are";
        $user = $pw[7];
    }
    croak "Home directory is the empty string" if $user eq "";
    $user =~ s!/*\z!$rest!;
    $user = "/" if $user eq "";
    # Restore taintedness
    return $user . substr($file, 0, 0);
}

# Prepare a directory to contain databases
sub prepare {
    my ($class, $tele, $params) = @_;

    my $mkpath = exists $params->{mkpath} ?
        delete $params->{mkpath} : !exists $params->{cache_dir};
    my $dir = delete $params->{cache_dir};
    $dir = $default_cache_dir unless defined $dir;
    $dir = tilde($dir);
    if ($dir !~ m!\A/!) {
        require Cwd;
        my $prefix = Cwd::getcwd();
        $dir = $prefix =~ m!/\z! ? $prefix . $dir : "$prefix/$dir";
    }
    $dir .= "/" unless $dir =~ m!/\z!;
    if (!-d $dir) {
        croak "No visible directory named '$dir'" unless $mkpath;
        require File::Path;
        my $old_mask = umask($tele->{umask}) if defined($tele->{umask});
        eval { File::Path::mkpath($dir) };
        my $err = $@;
        umask($old_mask) if defined($tele->{umask});
        die $err if $err;
    }
    $tele->{cache_dir} = $dir;
}

# Opening a db file with O_CREAT can give you RW access even if you didn't
# ask for that. Use this to fix the state.
sub db_maybe_rw {
    my $db = shift->{db};
    open(my $fh, "+<&", $db->fd) || croak "Could not dup db fileno: $!";
    my $flags = fcntl($fh, F_GETFL, 0) ||
        croak "Could not fcntl db handle: $!";
    $flags &= O_ACCMODE;
    return 0 if $flags == O_RDONLY;
    croak "Don't know how to handle a database opened in mode $flags" unless
        $flags == O_RDWR;
    bless $db, DB_RW;
    return 1;
}

sub db_check {
    my $access = shift;
    my $db = $access->{db};

    if (!$db->get(VERSION, my $version)) {
        croak("Wanted version ", DB_VERSION, " differs from current $version for ", $access->db_file) if $version ne DB_VERSION;
    } else {
        $db = $access->upgrade(1);
        croak "Storage problem" if $db->put(VERSION, DB_VERSION);
    }

    my $versions_wanted = $access->page_versions;
    if ($db->get(PAGE_VERSIONS, my $page_versions) == 0) {
        $page_versions = unpack("C", $page_versions);
        croak("Wanted versions $versions_wanted differs from current $page_versions for ", $access->db_file) if defined($versions_wanted) && $versions_wanted != $page_versions;
        $access->{page_versions} = $page_versions;
    } else {
        $db = $access->upgrade(1);
        $access->{page_versions} = $versions_wanted || $default_page_versions;
        croak "Storage problem" if
            $db->put(PAGE_VERSIONS, pack("C", $access->{page_versions}));
    }

    my $value;
    if ($db->get(PAGE . "\xff" x 5, $value)) {
        # No PAGE terminator
        $db = $access->upgrade(1);
        croak "Storage problem" if $db->put(PAGE . "\xff" x 5, "\xff" x 4);
    }

    if ($db->get(COUNTER . "\xff" x 4, $value) ||
        $value ne "\x0" . "\xff" x 4) {
        # No COUNTER terminator
        $db = $access->upgrade(1);
        croak "Storage problem" if $db->put(COUNTER . "\xff" x 4, "\x00" . "\xff" x 4);
    }
}

sub init {
    my ($access, $params) = @_;

    my $acquire = exists $params->{acquire} ? delete $params->{acquire} : 1;
    $access->SUPER::init($params);
    $access->{stores} = 0;
    $access->acquire if $acquire;

    return $access;
}

sub cache_dir {
    return shift->{parent}->cache_dir;
}

sub teletext_db {
    return shift->{parent};
}

sub db {
    return shift->{db};
}

sub stale_period {
    return shift->{stale_period};
}

sub expire_period {
    return shift->{expire_period};
}

sub channel {
    croak "You can't change the channel on a $_[0]" if @_ >= 2;
    return shift->{channel};
}

sub page_versions {
    croak "You can't change the page_versions on a $_[0]" if @_ >= 2;
    return shift->{page_versions};
}

sub delete {
    my ($access, %options) = shift;
    defined($access->{channel}) || croak "No channel";

    # We won't check lockfile unlinks since they are not really
    # part of the semantics of a channel existing, and there actually is no
    # clean way to make things look atomic in that case anyways.
    my $want_file = $access->want_file;
    my $lock_file = $access->lock_file;
    my $want_fh   = $access->{want_fh};
    my $lock_fh   = $access->{lock_fh};

    my $rc;
    my $old_mask = $access->{creat} && defined($access->{umask}) ?
        umask($access->{umask}) : undef;
    eval {
        my $db_file = $access->db_file;
        $want_fh ||= $access->{want} && $access->get_lock($want_file, 1);
        $lock_fh ||= $access->get_lock($lock_file, 1);
        if (unlink($db_file)) {
            $rc = 1;
        } elsif ($! != ENOENT) {
            croak "Could not unlink $db_file: $!";
        }
        if (my $db = delete $access->{db}) {
            # This is pure evil.
            $db->DESTROY;
            bless $db, "Video::TeletextDB::Bug";
        }
        unlink($lock_file);
        delete $access->{lock_fh};
        if ($want_fh) {
            unlink($want_file);
            delete $access->{want_fh};
        }
    };
    umask($old_mask) if defined $old_mask;
    return $rc || () unless $@;

    unlink($lock_file) if $lock_fh && !$access->{lock_fh};
    unlink($want_file) if $want_fh && !$access->{want_fh};
    die $@ if $@;
}

sub unwant {
    my $access = shift;
    croak "You don't have the database"		unless	$access->{db};
    croak "You don't have the database lock"	unless	$access->{lock_fh};
    croak "You don't have the database want"	unless	$access->{want_fh};
    close delete $access->{want_fh};
}

sub rewant {
    my $access = shift;
    croak "You don't have the database"		unless	$access->{db};
    croak "You don't have the database lock"	unless	$access->{lock_fh};
    croak "You already have the database want"	if	$access->{want_fh};

    my $want_file = $access->want_file;
    sysopen(my $fh, $want_file, $access->{creat} ? O_RDWR | O_CREAT : O_RDWR)||
        croak "Could not open/create '$want_file': $!";
    if (flock($fh, LOCK_NB | LOCK_EX)) {
        my $oldfh = select $fh;
        $| = 1;
        print "$$\n";
        truncate $fh, tell($fh);
        select $oldfh;
        $access->{want_fh} = $fh;
        return;
    }
    croak "Could not lock '$want_file': $!" unless $! == EWOULDBLOCK;
    close $fh;

    $access->release;
    local $access->{want} = 1;
    $access->acquire;
    return 1;
}

sub restart {
    my $access = shift;
    delete $access->{start_time};
    delete $access->{end_time};
    $access->{stores} = 0;
}

sub start_time {
    croak 'Too many arguments for start_time method' if @_ > 1;
    return shift->{start_time} || croak "Time doesn't seem to have started";
}

sub end_time {
    croak 'Too many arguments for end_time method' if @_ > 1;
    return shift->{end_time} || croak "Time doesn't seem to have ended";
}

sub stores {
    croak 'Too many arguments for stores method' if @_ > 1;
    return shift->{stores};
}

sub acquire {
    my $access = shift;

    croak "You already have the database"	if $access->{db};
    croak "You already have the database lock"	if $access->{lock_fh};
    croak "You already have the database want"	if $access->{want_fh};

    my $old_mask = $access->{creat} && defined($access->{umask}) ?
        umask($access->{umask}) : undef;
    eval {
        $access->{want_fh} = $access->want(1) if $access->{want};
        $access->{lock_fh} = $access->lock(1);

        $access->{db} = ($access->{RW} ? DB_RW : DB_RO)->TIEHASH
            ($access->db_file,
            ($access->{RW}	? O_RDWR  : O_RDONLY) |
            ($access->{creat}	? O_CREAT : 0), 0666, $DB_BTREE) ||
            croak "Could not db_open ", $access->db_file, ": $!";
        $access->db_maybe_rw if $access->{creat} && !$access->{RW};
        $access->db_check;
        $access->downgrade if !$access->{RW} && defined $access->{RW} &&
            $access->{db}->isa(DB_RW);

        return if $access->{db}->get(STORES, my $stores);
        (my $end, $stores) = unpack("NN", $stores);
        $access->{stale}  = $end - $access->{stale_period};
        $access->{expire} =
            $stores < MIN_STORES ? -9**9**9 : $end - $access->{expire_period};
    };
    umask($old_mask) if defined $old_mask;
    return $access->{db} unless $@;

    my $err = $@;
    $access->release;
    die $err;
}

sub upgrade {
    my $access = shift;

    $access->{db} || croak "You don't have the database";
    return $access->{db} if $access->{db}->isa(DB_RW);
    croak "Can't upgrade pure readonly access" if
        !$access->{RW} && defined $access->{RW} &&
        !($access->{creat} && shift);

    my $db = delete $access->{db};
    # This is pure evil.
    $db->DESTROY;
    bless $db, "Video::TeletextDB::Bug";

    my $old_mask = $access->{creat} && defined($access->{umask}) ?
        umask($access->{umask}) : undef;
    eval {
        $access->{db} = DB_RW->TIEHASH
            ($access->db_file, $access->{creat} ? O_RDWR | O_CREAT : O_RDWR,
             0666, $DB_BTREE) ||
             croak "Could not db_open ", $access->db_file, ": $!";
        $access->db_check;
    };
    umask($old_mask) if defined $old_mask;
    return $access->{db} unless $@;

    my $err = $@;
    $access->release;
    die $err;
}

sub downgrade {
    my $access = shift;

    $access->{db} || croak "You don't have the database";
    return $access->{db} if $access->{db}->isa(DB_RO);

    my $db = delete $access->{db};
    # This is pure evil.
    $db->DESTROY;
    bless $db, "Video::TeletextDB::Bug";

    my $old_mask = $access->{creat} && defined($access->{umask}) ?
        umask($access->{umask}) : undef;
    eval {
        while (1) {
            $access->{db} = DB_RO->TIEHASH
                ($access->db_file,
                 $access->{creat} ? O_CREAT | O_RDONLY : O_RDONLY,
                 0666, $DB_BTREE) ||
                 croak "Could not db_open ", $access->db_file, ": $!";
            $access->db_maybe_rw if $access->{creat};
            $access->db_check;
            last if $access->{db}->isa(DB_RO);

            if ($access->{db} = DB_RO->TIEHASH
                ($access->db_file, O_RDONLY, 0666, $DB_BTREE)) {
                $access->db_check;
                # check may have caused an upgrade again
                last if $access->{db}->isa(DB_RO);
            } elsif ($! != ENOENT) {
                croak "Could not db_open ", $access->db_file, ": $!";
            }
            # Someone must have undone us. Retry.
        }
    };
    umask($old_mask) if defined $old_mask;
    return $access->{db} unless $@;

    my $err = $@;
    $access->release;
    die $err;
}

sub release {
    my $access = shift;
    # Make sure things get closed in the right order
    if (my $db = delete $access->{db}) {
        # This is pure evil.
        $db->DESTROY;
        bless $db, "Video::TeletextDB::Bug";
    }
    my $fh = delete $access->{lock_fh};
    close($fh) if $fh;
    $fh = delete $access->{want_fh};
    close($fh) if $fh;
}

sub cache_status {
    my $access = shift;
    my $db = $access->{db} || croak "You don't have the database";
    return if $db->get(STORES, my $update);
    my ($end, $stores, $start) = unpack("NNN", $update);
    return {
        channel		=> $access->{channel},
        start_time	=> $start+$epoch_time,
        end_time	=> $end  +$epoch_time,
        stores		=> $stores,
    };
}

sub expire {
    my $access = shift;
    my $db = $access->upgrade;
    for my $page (@_) {
        croak "Delete problem" if $db->del($page);
        $db->del(PAGE . substr($page, 1) . pack("C", $_)) for
            0..$access->{page_versions}-1;
    }
    return $db;
}

sub db_subpages {
    my ($access, $page) = @_;

    my $db = $access->{db} || croak "You don't have the database";

    my $key = my $prefix = COUNTER . $page;
    return wantarray ? () : 0 if $db->seq($key, my $counter, R_CURSOR);

    my $updatable = $access->{RW} || !defined $access->{RW};
    my (@good_pages, @bad, $stale);
    my $zero_time = my $non_zero_time = 0;

    while (substr($key, 0, 3) eq $prefix) {
        my ($c, $time) = unpack("CN", $counter);
        if ($time <= $access->{stale}) {
            #print STDERR ("Expiring ",unpack("n", $page),"/",unpack("n", $_),
            #              " (", scalar localtime($time),
            #              ") versus ", scalar localtime($expire), "\n");
            push @bad, $key if $updatable && $time <= $access->{expire};
        } else {
            #print STDERR ("good ", unpack("n", $page),"/",unpack("n", $_),
            #              " with date ",
            #              scalar localtime($time), "\n");
            my $subpage_nr = unpack("x3n", $key);
            if (sprintf("%x", $subpage_nr) !~ /[a-fA-F]/) {
                push @good_pages, $subpage_nr;
                if ($good_pages[-1]) {
                    $non_zero_time = $time if $non_zero_time < $time;
                } else {
                    $zero_time = $time;
                }
            }
        }
        croak "Unexpected sequence end" if $db->seq($key, $counter, R_NEXT);
    }
    # print STDERR "returning @{[unpack('n*', $good_pages)]} instead of @{[unpack('n*', $subpages)]}\n";
    $access->expire(@bad) if @bad;
    return @good_pages unless $zero_time && $non_zero_time;
    # Here we assume that a 0 page and a 1-n page are mutually exclusive
    return wantarray ? 0 : 1 if $zero_time >= $non_zero_time;
    return wantarray ? grep $_, @good_pages : @good_pages - 1;
}

sub subpages {
    my $access = shift;
    my $page	= pack("n", shift);
    return $access->db_subpages($page, @_);
}

sub raw_fetch_page {
    my $access = shift;
    my $page = pack("nn", @_);
    my $db = $access->{db} || croak "You don't have the database";

    return if $db->get(COUNTER . $page, my $counter);
    my $time = unpack("xN", $counter);
    if ($access->{stale} < $time) {
        my $content;
        return sort { $b cmp $a } map
            $db->get(PAGE . $page . pack("C", $_), $content) ? () : $content,
            0..$access->{page_versions}-1;
    }
    return if !$access->{RW} && defined $access->{RW} ||
        $access->{expire} < $time;
    $db = $access->upgrade;
    croak "Delete problem" if $db->del(COUNTER . $page);
    $db->del(PAGE . $page . pack("C", $_)) for 0..$access->{page_versions}-1;
}

sub fetch_page {
    my $access = shift;
    return vote($access->{channel}, @_[0..1], $access->raw_fetch_page(@_));
}

sub fetch_page_versions {
    my $access = shift;
    return map {
        my ($time, @rows) = unpack "N(C/a)*", $_;
        bless {
            time	=> $time+$epoch_time,
            raw_rows	=> \@rows,
            channel	=> $access->{channel},
            page_nr	=> $_[0],
            subpage_nr	=> $_[1],
        }, "Video::TeletextDB::Page";
    } $access->raw_fetch_page(@_);
}

sub scan_page {
    my ($access, $step, $from) = @_;
    my $db = $access->{db} || croak "You don't have the database";
    croak "Zero step" unless $step;
    my $updatable = $access->{RW} || !defined $access->{RW};
    my @bad;
    if ($step >= 0) {
        $from ||= 0;
        croak "Too high page $from" if $from >= 0x900;
        my $base = $from;
        my $end = 0xffff;
        while (1) {
            # print STDERR "from=$from, base=$base, end=$end\n";
            my $key = my $start = COUNTER . pack("n", $base) . "\xffff";
            croak "No followup after $from" if
                $db->seq($key, my $counter, R_CURSOR);
            # One more step if we hit the element itself
            croak "No followup after $from" if
                substr($key, 0, 3) eq $start &&
                $db->seq($key, $counter, R_NEXT);
            while (unpack("xN", $counter) <= $access->{stale}) {
                push @bad, $key if
                    $updatable && unpack("xN", $counter) <= $access->{expire};
                croak "No followup after $from" if
                    $db->seq($key, $counter, R_NEXT);
            }
            my $hex = unpack("xH4", $key);
            # print STDERR "Considering 0x$hex\n";
            unless ($hex =~ s/(\D.*)/"f" x length $1/eg) {
                # We found a non-hex page
                $access->expire(@bad) if @bad;
                return hex $hex > $end ? () : hex $hex;
            }
            $base = hex $hex;
            if ($base == 0xffff) {
                unless ($end == 0xffff) {
                    $access->expire(@bad) if @bad;
                    return;
                }
                # wrap
                $end = $from;
                $base = 0;
            }
        }
    } else {
        $from ||= 0xffff;
        croak "Too low page $from" if $from < 0x100;
        my $base = $from;
        my $end = 0;
      START:
        while (1) {
            # print STDERR "from=$from, base=$base, end=$end\n";
            my $key = my $start = COUNTER . pack("n", $base);
            croak "No followup after $from" if
                $db->seq($key, my $counter, R_CURSOR);
            # print STDERR "found ", unpack("H*", $key), "\n";
            # and step back
            until ($db->seq($key, $counter, R_PREV) ||
                   substr($key, 0, 1) ne COUNTER) {
                if (unpack("xN", $counter) <= $access->{stale}) {
                    push @bad, $key if $updatable &&
                        unpack("xN", $counter) <= $access->{expire};
                    next;
                }

                my $hex = unpack("xH4", $key);
                # print STDERR "Considering 0x$hex\n";
                # We found a non-hex page
                unless ($hex =~ s/(\D.*)/"9" x length $1/eg) {
                    $access->expire(@bad) if @bad;
                    return hex $hex < $end ? () : hex $hex;
                }
                $base = hex($hex)+1;
                next START;
            }
            if ($end) {
                $access->expire(@bad) if @bad;
                return;
            }
            # wrap
            $end = $from;
            $base = 0xffff;
        }
    }
}

sub page_ids {
    my $access = shift;
    my $db = $access->{db} || croak "You don't have the database";
    my $updatable = $access->{RW} || !defined $access->{RW};
    my (@keys, $time, @bad);
    croak "No followup after ", COUNTER if
        $db->seq(my $key = COUNTER, my $value, R_CURSOR);
    while ($key ne COUNTER . "\xff" x 4) {
        $time = unpack("xN", $value);
        if ($access->{stale} < $time) {
            my $page_id = sprintf("%03x/%02x", unpack("xnn", $key));
            push @keys, $page_id unless $page_id =~ /[a-fA-F]/;
        } elsif ($updatable && $time <= $access->{expire}) {
            push @bad, $key;
        }
        croak "No followup" if $db->seq($key, $value, R_NEXT);
    }
    $access->expire(@bad) if @bad;
    return @keys;
}

sub write_pages {
    my ($access, %params) = @_;
    my $time	= exists $params{time} ? delete $params{time} : time;
    defined(my $pages	= delete $params{pages}) ||
        croak "No pages parameter";
    croak("Unknown parameters ", join(", ", keys %params)) if %params;
    return unless @$pages;

    $access->{start_time} = $time if
        !defined $access->{start_time}	|| $time < $access->{start_time};
    $access->{end_time}   = $time if
        !defined $access->{end_time}	|| $time > $access->{end_time};
    $time -= $epoch_time;
    my $t = pack("N", $time);

    my $db = $access->upgrade;

    my $counter;
    for (@$pages) {
        my $main_page = $_->{page};
        # Maybe caller should do this...
        die "Bad page nr $main_page" if $main_page >= 0x800;
        $main_page += 0x800 if $main_page < 0x100;
        $main_page	= pack("n", $main_page);
        my $subpage	= pack("n", $_->{ctrl} & VTX_SUB);
        my $page = $main_page . $subpage;

        $counter = pack("C", $access->{page_versions}-1) if
            $db->get(COUNTER . $page, $counter);
        $counter = pack "C", (1 + unpack "C", $counter) % $access->{page_versions};
        my $rc = $db->put(PAGE . $page . $counter, do {
            no warnings "uninitialized";
            pack "a*(C/a*)*", $t, @{$_->{packet}};
        });
        $rc == 0 || croak "Storage problem (rc=$rc)";
        $db->put(COUNTER . $page, $counter . $t) == 0 ||
            croak "Storage problem";
        ++$access->{stores};
    }

    if ($db->get(STORES, $counter) == 0) {
        my ($old_end, $old_stores, $old_start) = unpack("NNN", $counter);
        if ($old_start <= $time && $time <= $old_end) {
            $db->put(STORES, pack("NNN", $old_end, $old_stores + @$pages,
                                  $old_start)) == 0 || croak "Storage problem";
            return;
        }
        return if $access->{end_time} < $old_end+$epoch_time;
        return if $access->{stores} < MIN_STORES;
    }
    $db->put(STORES, pack("NNN",
                          $access->{end_time} - $epoch_time,
                          $access->{stores},
                          $access->{start_time} - $epoch_time)) == 0 ||
                              croak "Storage problem";
}

sub write_feed {
    my ($access, %params) = @_;
    my $time = exists $params{time} ? delete $params{time} : time;
    defined(my $fields	= delete $params{decoded_fields}) ||
        croak "No decoded_fields parameter";
    croak("Unknown parameters ", join(", ", keys %params)) if %params;
    return unless @$fields;

    my @pages;
    for (@$fields) {
        next unless $_->[0] == VBI_VT;
        # Currently only handle teletext
        my $y = $_->[2];
        if ($y == 0) {
            if ($access->{curpage}{page}) {
                if ($_->[5] & VTX_C11 ||
                    ($access->{curpage}->{page} ^ $_->[4]) & 0xf00) {
                    push @pages, $access->{curpage} unless
                        ($access->{curpage}->{page} & 0xff) == 0xff;
                }
            }
            $access->{curpage} = {
                packet => [$_->[3]],
                page   => $_->[4],
                ctrl   => $_->[5],
            };
        } elsif ($y <= 25) {
            $access->{curpage}{packet}[$y] = $_->[3];
        }
        # We currently ignore packets 26 and higher
    }
    $access->write_pages(time => $time, pages => \@pages) if @pages;
}

sub next_page {
    return shift->scan_page(+1, @_);
}

sub previous_page {
    return shift->scan_page(-1, @_);
}

sub DESTROY {
    shift->release;
}

package Video::TeletextDB::DB_RW;
our @ISA = qw(DB_File);

package Video::TeletextDB::DB_RO;
our @ISA = qw(DB_File);

package Video::TeletextDB::Access;

1;
__END__

=head1 NAME

Video::TeletextDB::Access - Represents Video::TeletextDB database access

=head1 SYNOPSIS

  use Video::TeletextDB;
  $tele_db	= Video::TeletextDB->new(...);
  $access	= $tele_db->access(...);

  $hash_ref	= $access->cache_status;

  $access->write_pages(%parameters);
  # Possible parameters are:
  # time  => $epoch_seconds
  # pages => \@pages
  $access->write_feed(%parameters);
  # Possible parameters are:
  # time  => $epoch_seconds
  # decoded_fields => \@decoded_fields
  @raw_pages	= $access->raw_fetch_page($page_nr, $subpage_nr);
  @pages	= $access->fetch_page_versions($page_nr, $subpage_nr);
  $page		= $access->fetch_page($page_nr, $subpage_nr);
  @page_ids	= $access->page_ids;
  @subpage_nrs	= $access->subpages($page_nr);
  $next_page_nr	= $access->next_page($page_nr);
  $prev_page_nr = $access->prev_page($page_nr);

  $cache_dir	= $access->cache_dir;
  $channel	= $access->channel;
  $tele		= $access->teletext_db;
  $db		= $access->db;
  $db_file	= $access->db_file;
  $lock_file	= $access->lock_file;
  $access->lock;
  $page_versions= $access->page_versions;
  $umask	= $access->umask;
  $old_umask	= $access->umask($new_umask);
  $RW		= $access->RW;
  $old_RW	= $access->RW($new_RW);
  $user_data	= $access->user_data;
  $old_user_data= $access->user_data($new_user_data);

  $access->release;
  $db		= $access->acquire;
  $db		= $access->downgrade;
  $db		= $access->upgrade;
  $access->delete;

=head1 DESCRIPTION

This class implements the actual access to the database for a particular
channel. It uses a Berkeley DB with an external lockfile for the actual
storage.

=head1 METHODS

All methods throw an exception in case of failure unless mentioned otherwise.

All page and subpage numbers used in these methods are the real numbers.
However, what's normally displayed on teletext viewers is the hexadecimal
notation. So if you want to work with the page that's normally shown as page
"100", you'll have to use 0x100 or 256 as an argument.

=over

=item X<cache_status>$hash_ref = $access->cache_status

Return a hashreference describing the last major update to the database, or
undef if there hasn't been one yet. See L<write_pages|"write_pages"> for a more
in depth discussion on what these values mean.

The hash keys are:

=over

=item start_time

The storage time of the oldest page during the last major update.

=item end_time

The storage time of the most recent page during the last major update.

=item stores

The number of stores done during the last major update (the number of refreshed
pages will normally be a lot lower than this because many of these stores will
be for versions of the same page).

=back

=item X<write_pages>$access->write_pages(%parameters)

the arguments are a list of name/value pairs. Recognized are:

=over

=item X<write_pages_time>time => $epoch_seconds

This is the time that will be associated with all of the pages to be stored.
If not given, will default to the current time.

When you use L<access|Video::TeletextDB/access> to create a new
Video::TeletextDB::Access object, an internal counter of number of stores is
initialized to zero and internals start_time and end_time are set to undef.
Whenever you then use this method to store at least one page, the stores
counter is increased by the number of stored pages and the
[start_time, end_time] interval is extended minimally to include the the page
time.

Then it looks at the current values for these stored in the database. If there
are none, it stores the internal values in the database. Otherwise it checks
if the page time falls inside the database interval, and if so increases the
database number of stores with the number of pages. Otherwise it looks if the
internal number of stores is above a certain threshold (currently 10000) and
if so writes internal start_time, end_time and number of stores to the
database.

To make a long story short, the database values will now tell you the time
period of the last major update to the database.

However, it will only work properly if you don't deallocate the
Video::TeletextDB::Access object all the time. On the other hand, you don't
want to keep the database open all the time since you will then lock out
other users like the actual display program. So the proper action is to
L<release|"release"> the database when unneeded and to L<re-acquire|"acquire">
it when it 's needed again.

=item X<write_pages_pages>pages => \@pages

A mandatory parameter refering to the pages that must get stored in the
database. Each page itself must be a hash reference with the following
values:

=over

=item page => $nr

This is the page number (normally derived from packet 0)

=item ctrl => $value

The control flags for this page as a number (also normally derived from
packet 0). Anding this with VTX_SUB (0x003f7f) should give the subpage number.

=item packet => \@packets

A reference to an array of packets associated with this page. Each packet is
normally 40 bytes of raw teletext data. You may represent missing packets as
an empty string or undef. A tail of missing packets on the list may be left
out completely.

=back

These fields are exactly in the format that's passed as argument to
enter_page method of Video::Capture::VBI::VT. That means a basic teletext
collector can look this:

    use Video::Capture::VBI;

    my $vbi_dev = "/dev/v4l/vbi0";

    package Decoder;
    use base 'Video::Capture::VBI::VT';

    my @pages;
    sub enter_page {
        push @pages, $_[1];
    }

    package main;
    my $vbi = Video::Capture::V4l::VBI->new($vbi_dev) ||
        die "Could not open $vbi_dev: $!";

    # max. 1 second backlog (~1M)
    $vbi->backlog(25);

    my $vt = Decoder->new;
    my $read_mask = "";
    vec($read_mask, $vbi->fileno, 1) = 1;

    my $tele = Video::TeletextDB->new(RW => 1, creat => 1);
    my $access = $tele->access(channel => "foo");
    $access->release;
    while (1) {
        # This select seems to be totally blocking
        select(my $r = $read_mask, undef, undef, undef);
        my $now = time;

        @pages = ();
        $vt->feed(decode_field $vbi->field, VBI_VT) while $vbi->queued;
        next unless @pages;

        $access->acquire;
        $access->write_pages(time => $now, pages => \@pages);
        $access->release;
    }

=back

=item X<write_feed>$access->write_feed(%parameters)

The page feeding in the example under L<write_pages|"write_pages"> is still
a bit inconvenient, so the essential part of the
L<Video::Capture::V4l::VBI|Video::Capture::V4l::VBI> feed code is duplicated
here. It will take decoded fields, assemble them into pages and directly
send them to the database by doing a L<write_pages|"write_pages">. You should
realize however that when it returns it can still internally store a currently
unfinished page expecting that later decoded fields will finish that page.
If it gets fed fields while there is nothing cached yet, it will drop fields
until it sees a page start. So this is yet another reason to not drop the
Video::TeletextDB::Access object all the time, but to only release the
database.

The parameters are name/value pairs which can be:

=over

=item X<write_feed_time>time => $epoch_seconds

This is the time that will be associated with all of the pages to be stored.
If not given, will default to the current time.

This will be passed to L<write_pages|"write_pages"> as the
L<time parameter|"write_pages_time">.

=item X<write_feed_decode_fields>decoded_fields => \@decoded_fields

Mandatory parameter representing the already decoded fields that will get
assembled into pages. All pages that are completed at the end of the method
call will then be passed on as the L<pages parameter|"write_pages_pages"> to
L<write_pages|"write_pages">.

=back

Using this method the previous example to store a teletext feed in the database
becomes:

    use Video::Capture::VBI;
    my $vbi_dev = "/dev/v4l/vbi0";

    package main;
    my $vbi = Video::Capture::V4l::VBI->new($vbi_dev) ||
        die "Could not open $vbi_dev: $!";

    # max. 1 second backlog (~1M)
    $vbi->backlog(25);

    my $read_mask = "";
    vec($read_mask, $vbi->fileno, 1) = 1;

    my $tele = Video::TeletextDB->new(RW => 1, creat => 1);
    my $access = $tele->access(channel => "foo");
    $access->release;
    while (1) {
        # This select seems to be totally blocking
        select(my $r = $read_mask, undef, undef, undef);
        my $now = time;

        my @decoded;
        push @decoded, decode_field($vbi->field, VBI_VT) while $vbi->queued;
        next unless @decoded;

        $access->acquire;
        $access->write_feed(time => $now, decoded_fields => \@decoded);
        $access->release;
    }

=item X<raw_fetch_page>@raw_pages = $access->raw_fetch_page($page_nr, $subpage_nr)

Returns a list of all version of the given $page_nr/$subpage_nr in raw format
(as stored in the database). The versions are sorted from most recent to
oldest. Only the first page is guaranteed to be non-stale.

This function is meant for people who want to do their own processing of the
raw data. Normally you'd use L<fetch_page|"fetch_page"> or
L<fetch_page_versions|"fetch_page_versions"> which are more cooked.

=item X<fetch_page_versions>@pages = $access->fetch_page_versions($page_nr, $subpage_nr)

This has the same semantics as L<raw_fetch_page|"raw_fetch_page"> but each raw
page is converted to a L<Video::TeletextDB::Page|Video::TeletextDB::Page>
object to which you can apply the provided methods.

=item X<fetch_page>$page = $access->fetch_page($page_nr, $subpage_nr)

This is the preferred interface to fetch teletext pages from the database.

Internally this uses L<raw_fetch_page|"raw_fetch_page">, but then mainly tries
to return the most recent version of the page. It will however use the other
versions of the pages in an attempt to fix up transmission errors. At the end
one best effort L<Video::TeletextDB::Page|Video::TeletextDB::Page> is returned.
Due to the use of older page versions you can in principle get an almost random
mix of old and new information if there are errors in the first version. In
practice things work quite well and you rarely see artifacts.

=item X<pages>@page_ids = $access->page_ids

Returns a list of all decimal page ids in the database. A page id is of the
form C<hex_page/hex_subpage>. So if one of the returned strings is
e.g. C<"100/10">, that means that page 256, subpage 16 is in the database.
The returned list is sorted, first by page and then by subpage.

=item X<subpages>@subpage_nrs = $access->subpages($page_nr)

Returns a list of subpages of the given page. It assumes that a subpage 0 and
other non-0 subpages are mutually exclusive, so it returns only one of these
two cases (the set that has the most recent subpage wins).

=item X<next_page>$next_page_nr = $access->next_page($page_nr)

Given a page number, it scans the database for the next existing
non-hexadecimal page, wrapping back to the first page after the last. It can
return the startpage itself if after a complete scan that's the only page it
found. Returns undef if there are no non-hexadecimal pages.

=item X<previous_page>$prev_page_nr = $access->prev_page($page_nr)

Given a page number, it scans the database for the previous existing
non-hexadecimal page, wrapping back to the last page after the first. It can
return the startpage itself if after a complete scan that's the only page it
found. Returns undef if there are no non-hexadecimal pages.

=item X<cache_dir>$cache_dir = $access->cache_dir

Returns the directory containing the channel database. The same as

 $cache_dir = $access->tele_db->cache_dir


=item X<channel>$channel = $access->channel

Returns the channel this $access object is associated with.

=item X<teletext_db>$tele = $access->teletext_db

Returns the L<Video::TeletextDB object|Video::TeletextDB/access> that was used
to create this $access object.

=item X<db>$db = $access->db

Return an open database handle if $access currently has one, false otherwise.
The hanlde is a L<DB_File object|DB_File> to which you can apply the normal
DB_File methods. There is no tied hash, so you can't use the tie interface.

=item X<db_file>$db_file = $access->db_file

Returns the name of the actual database file that is/will be used for the
channel associated with the $access object.

=item X<lock_file>$lock_file = $access->lock_file

Returns the name of the lockfile that is/will be used for the channel
associated with the $access object.

=item X<lock>$access->lock

Takes a blocking lock on $access->lock_file and truncates it to one
line containing the process id (L<$$|perlvar/$$>. Returns an open filehandle
for that lockfile, which is the last reference, none is kept internally.
So you'll have the lock for as long as you keep this handle alive, or until
you do an explicit unlock.

You normally don't use this method since all locking is taken care of
automatically by L<access|Video::TeletextDB/access>, L<acquire|"acquire"> and
L<release|"release">.

=item X<page_versions>$page_versions= $access->page_versions

Returns the value for L<page_versions|"new_page_versions">. This normally
can't be undef because if it starts out like that, it will be updated from
the setting in the database, which itself is initialized with the current
setting if there is none yet (and with $default_page_versions if that is
undefined).

=item X<umask>$umask = $access->umask

Returns the umask with which any lockfile or database creation will happen.
A value of undef means that it will use the global umask at such a moment.

Remember that the returned value is a number, not a string with a leading 0.

=item $old_umask = $access->umask($new_umask)

Sets a new umask, and returns the old one.

Remember that an umask is a number, usually given in octal. It is not a string
of octal digits.  See L<oct|perlfunc/oct> to convert an octal string to a
number.

=item X<RW>$RW = $access->RW

Returns the current value of the RW parameter.

A true value means that any database open will by default be done in readwrite
mode. The open database can later be switched to readonly by a
L<downgrade|"downgrade">.

An undefined value means the state of the database isn't fixed. It will start
out as readonly on open, but whenever the system needs write access, it will
internally do an L<upgrade|"upgrade">.

All other false values (C<0> and C<""> normally) mean that any open will be
readonly and is meant to remain so. An L<upgrade|"upgrade"> will fail unless
you change the RW flag first.

The database needs some initialization on create though. So whatever value
is returned here, there can be a little bit of write activity if the
L<creat option|"creat"> is true (this can happen even if the database already
existed if it somehow was missing its initial state). The database will then
be reopened readonly if you wanted pure readonly access.

But whatever value this method returns, you can't conclude anything from that
about the state of any currently opened database, since either the RW flag can
have been changed since the open, or the database can have been
L<upgraded|"upgrade"> or L<downgraded|"downgrade">.

=item $old_RW = $access->RW($new_RW)

Sets a new value for the RW parameter, returning the old value.

=item X<user_data>$user_data = $access->user_data

With every TeletextDB::Access object you can associate one scalar of user data
(default undef). This method returns that user data.

=item $old_user_data= $acess->user_data($new_user_data)

Set new user data, returning the old value.

=item X<release>$access->release

Closes access to the channel database and drops its lock. This will give
other parties the chance to now acquire access, without you forgetting
all attributes you've set. At a later time you can try to acquire the database
again using the L<acquire method|"acquire">.

=item X<acquire>$db = $access->acquire

Will block until it can get a lock on the channel database and will then open
the database, whose handle will then be returned. It will create lockfiles and
database files if needed if the L<creat options|Video::TeletextDB/new_creat> is
set.

=item X<downgrade>$db = $access->downgrade

If you have readwrite access to the database, it will close it and then reopen
it readonly. This is done without dropping the lock. The old database handle
will be invalidated and the new database handle is returned.

If you already have readonly access to the database, it simply returns its
handle.

All of this does in no way change the L<RW setting|Video::TeletextDB/new_RW>,
so if that one is undef, methods will still upgrade to readwrite whenever
needed. Use the L<RW method|"RW"> to change the RW setting if you don't want
that.

=item X<upgrade>$access->upgrade

If you have readonly access to the database, it will close it and reopen it
readwrite, This is done without dropping the lock. The old database handle will
be invalidated and the new database handle will be returned.

If you already have readwrite access to the database, it simply returns its
handle.

All of this does in no way change the L<RW setting|Video::TeletextDB/new_RW>.

=item X<delete>$access->delete

Closes and invalidates the database handle if it has the database open, erases
the database and then deletes the lockfile. If any of these didn't actually
exist that's not considered an error, the files are gone either way.
(for the moment inability to remove the lockfile is also not considered an
error).

=back

=head1 EXPORT

None by default.

But you can ask for:

=over

=item X<tilde>$expanded_path = tilde($path)

This does a C<~> expansion like a typical unix shell does, though the
rules are a bit simplified.

If $path begins with a tilde  character (C<~>) all of the following characters
preceding the first slash (or all following characters, if there is  no slash)
are considered as a login name. If this login name is the empty string, the
tilde is replaced  with  the value of the environment variable $ENV{HOME}. If
HOME is unset, the home directory of  the  user  executing the function is
used instead. Otherwise, the tilde and the login name are replaced with the
home directory associated with the specified login name, and the resulting
string is returned.

Throws an exception if the specified user is not found or the home directory
is an empty string.

If the $path doesn't start with a tilde, it's returned unchanged.

If you have a $path starting with a C<~> and don't want it expanded, put <./>
in front, e.g. F<./~non-expanded> instead of F<~non-expanded>.

=item X<$default_cache_dir>$default_cache_dir

This is the cache directory that gets used if you give no
L<cache_dir argument|"new_cache_dir"> to the L<new|"new"> method. It starts out
as F<~/.TeletextDB/cache>.

=item X<$default_page_versions>$default_page_versions

The number that will be used for L<page_versions|"page_versions"> if there is
none in the database yet and no setting is inherited from
L<access|Video::TeletextDB/access>.

=back

=head1 DATABASE FORMAT

This section describes database format version 1. Normal users of this module
shouldn't care about any of this, but may be needed if you want to write
extensions.

The data are stored in a L<standard Berkeley BTREE database|DB_FILE>. Since it
needs a number of logical tables, each logical key is prefixed with a single
character saying which logical table it's for. The prefixes are available as
names representing their meaning as the :BdbPrefixes tag in
L<Video::TeletextDB::Constants|Video::TeletextDB::Constants>.

All times in the database are in seconds since Jan 1 1970 without counting
leap seconds, even if your systems epoch is not Jan 1 1970. The value of
the standard Jan 1 1970 epoch in terms of the systems epoch is available in
the exportable variable
L<$Video::TeletextDB::Page::epoch_time|Video::TeletextDB::Page/$epoch_time>.

The logical tables are:

=over

=item VERSION

There is only a single entry with logical key C<""> and the version as a plain
ASCII string (should be C<1> for this specification). Only a freshly created
database can have nothing there yet, in which case you should write one before
writing anything into the database (see the internal db_check method  which is
automatically called for you already when use any of the documented methods to
acquire a database).

=item PAGE_VERSIONS

Again only a single ebtry with logical key "" and a value in
L<pack|perlfunc/pack> C<C> format, representing how many versions of a given
page will get stored. Only a freshly created database can have nothing there
yet, in which case you should write one before writing anything into the
database (see the internal db_check method which is automatically called for
you already when use any of the documented methods to acquire a database).

=item STORES

Again there is only a single entry with logical key "" and a value in
L<pack|perlfunc/pack> C<NNN> format. These integers correspond to the
values for L<end_time|"end_time">, L<stores|"stores"> and
L<start_time|"start_time"> in the L<cache_status method|"cache_status">
(except that all times are Jan 1 1970 based of course).

=item COUNTER

Maps a logical key in L<pack|perlfunc/pack> C<nn> format (decimal page and
subpage number) to C<CN> format, where the first value is the entry number
of the last page version written to the database. This will be an integer in
the range [0..PAGE_VERSIONS[, which starts counting from 0, is increased by one
on each new write and wraps back to 0 when it reaches
L<PAGE_VERSIONS|"PAGE_VERSIONS">. The second number is the epoch time the
version was extracted from the teletext stream.

There is a guaranteed terminator entry mapping C<"\xff" x 4> (invalid page
65535/65535) to C<"\x00" . "\xff" x 4> (version 0 written far into the future).
Only a freshly created database can have nothing there yet, in which case you
should write one before writing anything into the database (see the internal
db_check method which is automatically called for you already when use any of
the documented methods to acquire a database).

=item PAGE

Maps a logical key in L<pack|perlfunc/pack> C<nnC> format (page and subpage
number followed by verion number) to C<N(C/a*)*> format. The first integer
is again the epoch time the version was extracted from the teletext stream,
followed by a sequence of counyed strings, each representing one decoded
row packet (missing packets are represented by an empty string or simply
dropped if they are at the end of the sequence).

Each L<COUNTER|"COUNTER"> entry should always map to a valid L<PAGE|"PAGE">
entry, so you should write the L<PAGE|"PAGE"> entry before writing the
corresponding L<COUNTER|"COUNTER"> entry when storing a new page version, and
delete the L<COUNTER|"COUNTER"> entry before deleting all L<PAGE|"PAGE">
entries when removing a page completely.

There is a guaranteed terminator entry mapping C<"\xff" x 5> (invalid page
65535/65535 version 255) to C<"\xff" x 4> (empty page from far into the
future). Only a freshly created database can have nothing there yet, in which
case you should write one before writing anything into the database (see the
internal db_check method which is automatically called for you already when use
any of the documented methods to acquire a database).

=back

=head1 SEE ALSO

L<DB_File>,
L<Video::TeletextDB>,
L<Video::TeletextDB::Page>,
L<Video::Capture::VBI>,

=head1 AUTHOR

Ton Hospel, E<lt>Video-TeletextDB@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

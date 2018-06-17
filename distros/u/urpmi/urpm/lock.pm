package urpm::lock;


use strict;
use urpm::msg;
use urpm::util 'cat_';

#- avoid putting a require on Fcntl ':flock' (which is perl and not perl-base).
my ($LOCK_SH, $LOCK_EX, $LOCK_NB, $LOCK_UN) = (1, 2, 4, 8);



=head1 NAME

urpm::lock - urpm/rpm DB locking related routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut 


################################################################################
#- class functions


=item rpm_db($urpm, $b_exclusive, %options)

Lock rpm DB.

Lock policy concerning chroot : lock rpm db in chroot

Options: nofatal, wait

=cut

sub rpm_db {
    my ($urpm, $b_exclusive, %options) = @_;
    my $f = ($urpm->{root} ? "$urpm->{root}/" : '') . "/var/lib/rpm/.RPMLOCK";
    urpm::lock->new($urpm, $f, 'rpm', $b_exclusive, %options);
}

=item urpmi_db($urpm, $b_exclusive, %options)

Lock urpmi DB.

Lock policy concerning chroot : lock urpmi db in /

Options: nofatal, wait

=cut

sub urpmi_db {
    my ($urpm, $b_exclusive, %options) = @_;
    urpm::lock->new($urpm, "$urpm->{statedir}/.LOCK", 'urpmi', $b_exclusive, %options);
}


################################################################################
#- methods

# (options: nofatal, wait)
sub new {
    my ($_class, $urpm, $file, $db_name, $b_exclusive, %options) = @_;
    
    my $fh;
    #- we don't care what the mode is. ">" allow creating the file, but can't be done as user
    open($fh, '>', $file) or open($fh, '<', $file) or return;

    my $lock = bless { 
	fh => $fh, db_name => $db_name, 
	fatal => $options{nofatal} ? $urpm->{error} : sub { $urpm->{fatal}(7, $_[0]) }, 
	info => $urpm->{info},
	log => $urpm->{log},
    };
    _lock($lock, $b_exclusive, $options{wait});
    $lock;
}

sub get_lock_pid {
    my ($fh) = @_;
    my ($dev, $ino, undef) = stat($fh);
    my $major = int($dev/256);
    my $minor = $dev % 256;
    my $fileid = sprintf("%02x:%02x:%d",$major,$minor,$ino);
    foreach (urpm::util::cat_('/proc/locks')) { /FLOCK.*WRITE\s*(\d+)\s*$fileid\s/ && return $1 }
}

sub warn_about_locker {
    my ($lock) = @_;
    if (my $pid = get_lock_pid($lock->{fh})) {
        my $name = urpm::util::cat_("/proc/$pid/cmdline");
        $name =~ tr/\0/ /;
        $name =~ s/ *$//;
        $lock->{fatal}(N("%s database is locked, process %d is already using it", $lock->{db_name}, $pid) . ($name ? " ($name)" : ""));
    } else {
        $lock->{fatal}(N("%s database is locked (another program is already using it)", $lock->{db_name}));
    }
}

sub _lock {
    my ($lock, $b_exclusive, $b_wait) = @_;
    $b_exclusive ||= '';
    if ($lock->{log}) {
	my $action = $lock->{exclusive} && !$b_exclusive ? 'releasing exclusive' : $b_exclusive ? 'getting exclusive' : 'getting';
	$lock->{log}("$action lock on $lock->{db_name}");
    }
    my $mode = $b_exclusive ? $LOCK_EX : $LOCK_SH;
    if (!flock($lock->{fh}, $mode | $LOCK_NB)) {
	if ($b_wait) {
	    $lock->{info}(N("%s database is locked. Waiting...", $lock->{db_name}));
	    flock($lock->{fh}, $mode) or $lock->{fatal}(N("aborting"));
	} else {
            warn_about_locker($lock);
	}
    }
    $lock->{locked} = 1;
    $lock->{exclusive} = $b_exclusive;
}

sub unlock {
    my ($lock) = @_;
    $lock->{fh} or warn "lock $lock->{db_name} already released\n", return;

    if ($lock->{locked}) {
	$lock->{log} and $lock->{log}("unlocking $lock->{db_name} database");
	flock $lock->{fh}, $LOCK_UN;
    }
    close $lock->{fh};
    delete $lock->{fh};
}

sub DESTROY { 
    my ($lock) = @_;
    unlock($lock) if $lock->{fh};
}

=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut

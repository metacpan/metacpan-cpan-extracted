package urpm::sys;


use strict;
use warnings;
use urpm::util 'cat_';
use urpm::msg;
use POSIX ();


=head1 NAME

urpm::sys - OS-related routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut 

=item get_packages_list($file, $o_extra)

Get the list of packages that should not be upgraded or installed,
typically from the inst.list or skip.list files.

=cut

sub get_packages_list {
    my ($file, $o_extra) = @_;
    my @l = split(/,/, $o_extra || '');
    push @l, cat_($file);
    [ grep { $_ } map {
	chomp; s/#.*$//; s/^\s*//; s/\s*$//;
	$_;
    } @l ];
}

sub _read_fstab_or_mtab {
    my ($file) = @_;

    my @l;
    foreach (cat_($file)) {
	next if /^\s*#/;
	my ($device, $mntpoint, $fstype, $_options) = m!^\s*(\S+)\s+(/\S+)\s+(\S+)\s+(\S+)!
	    or next;
	$mntpoint =~ s,/+,/,g; $mntpoint =~ s,/$,,;
	push @l, { mntpoint => $mntpoint, device => $device, fs => $fstype };
    }
    @l;
}

=item find_a_mntpoint($dir)

Find used mount point from a pathname

=cut

sub find_a_mntpoint {
    my ($dir) = @_;
    _find_a_mntpoint($dir, {});
}

sub read_mtab() { _read_fstab_or_mtab('/etc/mtab') }

#- find used mount point from a pathname
sub _find_a_mntpoint {
    my ($dir, $infos) = @_;

    #- read /etc/fstab and check for existing mount point.
    foreach (_read_fstab_or_mtab("/etc/fstab")) {
	$infos->{$_->{mntpoint}} = { mounted => 0, %$_ };
    }
    foreach (read_mtab()) {
	$infos->{$_->{mntpoint}} = { mounted => 1, %$_ };
    }

    #- try to follow symlink, too complex symlink graph may not be seen.
    #- check the possible mount point.
    my @paths = split '/', $dir;
    my $pdir = '';
    while (@paths) {
	my $path = shift @paths;
	length($path) or next;
	$pdir .= "/$path";
	$pdir =~ s,/+,/,g; $pdir =~ s,/$,,;
	if (exists($infos->{$pdir})) {
	    #- following symlinks may be useless or dangerous for supermounted devices.
	    #- this means it is assumed no symlink inside a removable device
	    #- will go outside the device itself (or at least will go into
	    #- regular already mounted device like /).
	    #- for simplification we refuse also any other device and stop here.
	    return $infos->{$pdir};
	} elsif (-l $pdir) {
	    unshift @paths, split '/', _expand_symlink($pdir);
	    $pdir = '';
	}
    }
    undef;
}

=item df($mntpoint)

Return the size of the partition and its free space in KiB

=cut

sub df {
    my ($mntpoint) = @_;
    require Filesys::Df;
    my $df = Filesys::Df::df($mntpoint || "/", 1024); # ask 1kb values
    @$df{qw(blocks bfree)};
}

sub _expand_symlink {
    my ($pdir) = @_;

    while (my $v = readlink $pdir) {
	if ($pdir =~ m|^/|) {
	    $pdir = $v;
	} else {
	    while ($v =~ s!^\.\./!!) {
		$pdir =~ s!/[^/]+/*$!!;
	    }
	    $pdir .= "/$v";
	}
    }
    $pdir;
}

sub whereis_binary {
    my ($prog, $o_prefix) = @_;
    if ($prog =~ m!/!) {
	warn qq(don't call whereis_binary with a name containing a "/" (the culprit is: $prog)\n);
	return;
    }
    my $prefix = $o_prefix || '';
    foreach (split(':', $ENV{PATH})) {
	my $f = "$_/$prog";
	-x "$prefix$f" and return $f; 
    }
}

sub may_clean_rpmdb_shared_regions {
    my ($urpm, $test) = @_;

    if ($urpm->{root} && !$test || $urpm->{tune_rpm}{private}) {
	$urpm->{root} && $urpm->{debug} and $urpm->{debug}("workaround bug in rpmlib by removing $urpm->{root}/var/lib/rpm/__db*");
	clean_rpmdb_shared_regions($urpm->{root});
    }
}

sub clean_rpmdb_shared_regions {
    my ($prefix) = @_;
    unlink glob("$prefix/var/lib/rpm/__db.*");
}

sub proc_mounts() {
    my @l = cat_('/proc/mounts') or warn "Can't read /proc/mounts: $!\n";
    @l;
}

sub proc_self_mountinfo() {
    my @l = cat_('/proc/self/mountinfo') or warn "Can't read /proc/self/mountinfo: $!\n";
    @l;
}

sub trim_until_d {
    my ($dir) = @_;
    foreach (proc_mounts()) {
	#- fail if an iso is already mounted
	m!^/dev/loop! and return $dir;
    }
    while ($dir && !-d $dir) { $dir =~ s,/[^/]*$,, }
    $dir;
}

=item check_fs_writable()

Checks if the main filesystems are writable for urpmi to install files in

=cut

sub check_fs_writable () {
    foreach (proc_self_mountinfo()) {
	(undef, undef, undef, undef, our $mountpoint, my $opts) = split ' ';
	if ($opts =~ /(?:^|,)ro(?:,|$)/ && $mountpoint =~ m!^(/|/usr|/s?bin)\z!) {
	    return 0;
	}
    }
    1;
}

sub _launched_time {
    my ($component) = @_;

    if ($component eq N_("system")) {
	my ($uptime) = cat_('/proc/uptime') =~ /(\S+)/;
	time() - $uptime;
    } else {
	1; # TODO
    }
}

sub need_restart {
    my ($root) = @_;
    my $rpm_qf = '%{name} %{installtime} [%{provides}:%{Provideversion} ]\n';
    my $options = ($root ? "--root $root " : '') . "-q --whatprovides should-restart --qf '$rpm_qf'";
    open(my $F, "rpm $options | uniq |");

    my (%need_restart, %launched_time);
    while (my $line = <$F>) {
	my ($name, $installtime, $s) = $line =~ /(\S+)\s+(\S+)\s+(.*)/;
	
	my @should_restart = $s =~ /should-restart:(\S+)/g;
	foreach my $component (@should_restart) {
	    $launched_time{$component} ||= _launched_time($component);

	    if ($launched_time{$component} < $installtime) {
		push @{$need_restart{$component}}, $name;
	    }
	}
    }
    %need_restart && \%need_restart;
}

sub need_restart_formatted {
    my ($root) = @_;
    my $need_restart = need_restart($root) or return;

    foreach (keys %$need_restart) {
	my $packages = join(', ', sort @{$need_restart->{$_}});
	if ($_ eq 'system') {
	    $need_restart->{$_} = N("You should restart your computer for %s", $packages);
	} elsif ($_ eq 'session') {
	    $need_restart->{$_} = N("You should restart your session for %s", $packages);
	} else {
	    $need_restart->{$_} = N("You should restart %s for %s", translate($_), $packages); 
	}
    }
    $need_restart;
}

# useful on command-line: perl -Murpm::sys -e 'urpm::sys::print_need_restart'
sub print_need_restart() {
    my $h = need_restart_formatted('');
    print "$_\n" foreach values %$h;
}

sub migrate_back_rpmdb_db_to_hash_8 {
    my ($urpm, $root) = @_;

    $urpm->{info}("migrating back the created rpm db from Hash version 9 to Hash version 8");

    foreach my $db_file (glob("$root/var/lib/rpm/[A-Z]*")) {
	rename $db_file, "$db_file.";
	system("db_dump $db_file. | db42_load $db_file");
	if (-e $db_file) {
	    unlink "$db_file.";
	} else {
	    rename "$db_file.", $db_file;
	    $urpm->{error}("rpm db migration failed on $db_file. You will not be able to run rpm chrooted");
	    return;
	}
    }
}

sub migrate_back_rpmdb_db_to_4_6 {
    my ($urpm, $root) = @_;
    $urpm->{info}("migrating back the created rpm db from rpm-4.9 to rpm-4.6/4.8");
    if (system('chroot', $root, 'rpm', '--rebuilddb') == 0) {
	$urpm->{log}("rpm db downgraded successfully");
    } else {
	$urpm->{error}("rpm db downgrade failed. You will not be able to run rpm chrooted");
    }
}

sub migrate_back_rpmdb_db_version {
    my ($urpm, $root) = @_;

    if ($urpm->{need_migrate_rpmdb} eq '4.6') {
	migrate_back_rpmdb_db_to_hash_8($urpm, $root);
    } elsif ($urpm->{need_migrate_rpmdb} eq '4.8') {
	migrate_back_rpmdb_db_to_4_6($urpm, $root);
    }

    clean_rpmdb_shared_regions($root);
}


=item apply_delta_rpm($deltarpm, $o_dir, $o_pkg)

Create a plain rpm from an installed rpm and a delta rpm (in the current directory)
Returns the new rpm filename in case of success.
Params :

=over

=item * $deltarpm : full pathname of the deltarpm

=item * $o_dir : directory where to put the produced rpm (optional)

=item * $o_pkg : URPM::Package object corresponding to the deltarpm (optional)

=back

=cut

our $APPLYDELTARPM = '/usr/bin/applydeltarpm';
sub apply_delta_rpm {
    my ($deltarpm, $o_dir, $o_pkg) = @_;
    -x $APPLYDELTARPM or return 0;
    -e $deltarpm or return 0;
    my $rpm;
    if ($o_pkg) {
	require URPM; #- help perl_checker
	$rpm = $o_pkg->fullname . '.rpm';
    } else {
	$rpm = `rpm -qp --qf '%{name}-%{version}-%{release}.%{arch}.rpm' '$deltarpm'`;
    }
    $rpm or return 0;
    $rpm = $o_dir . '/' . $rpm;
    unlink $rpm;
    system($APPLYDELTARPM, $deltarpm, $rpm);
    -e $rpm ? $rpm : '';
}

our $tempdir_template = '/tmp/urpm.XXXXXX';
sub mktempdir() {
    my $tmpdir;
    eval { require File::Temp };
    if ($@) {
	#- fall back to external command (File::Temp not in perl-base)
	$tmpdir = `mktemp -d $tempdir_template`;
	chomp $tmpdir;
    } else {
	$tmpdir = File::Temp::tempdir($tempdir_template);
    }
    return $tmpdir;
}

# temporary hack used by urpmi when restarting itself.
sub fix_fd_leak() {
    opendir my $dirh, "/proc/$$/fd" or return undef;
    my @fds = grep { /^(\d+)$/ && $1 > 2 } readdir $dirh;
    closedir $dirh;
    foreach (@fds) {
	my $link = readlink("/proc/$$/fd/$_");
	$link or next;
	next if $link =~ m!^/(usr|dev)/! || $link !~ m!^/!;
	POSIX::close($_);
    }
}

sub clean_dir {
    my ($dir) = @_;

    require File::Path;
    File::Path::rmtree([$dir]);
}

sub empty_dir {
    my ($dir) = @_;
    clean_dir($dir);
    mkdir $dir, 0755;
}

sub syserror { 
    my ($urpm, $msg, $info) = @_;
    $urpm->{error}("$msg [$info] [$!]");
}

sub open_safe {
    my ($urpm, $sense, $filename) = @_;
    open my $f, $sense, $filename
	or syserror($urpm, $sense eq '>' ? N("Can't write file") : N("Can't open file"), $filename), return undef;
    return $f;
}

sub opendir_safe {
    my ($urpm, $dirname) = @_;
    opendir my $d, $dirname
	or syserror($urpm, "Can't open directory", $dirname), return undef;
    return $d;
}

sub move_or_die {
    my ($urpm, $file, $dest) = @_;
    urpm::util::move($file, $dest) or $urpm->{fatal}(1, N("Can't move file %s to %s", $file, $dest));
}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut

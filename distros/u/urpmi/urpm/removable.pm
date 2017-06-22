package urpm::removable;


use strict;
use urpm::msg;
use urpm::sys;
use urpm::util 'reduce_pathname';
use urpm 'file_from_local_medium';



=head1 NAME

urpm::removable - Removable media routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut 


sub file_or_synthesis_dir {
    my ($medium, $o_url) = @_;
    
    urpm::media::_valid_synthesis_dir($medium) && !$o_url ? 
	urpm::media::_synthesis_dir($medium) : 
	file_from_local_medium($medium, $o_url);
}

sub file_or_synthesis_dir_from_blist {
    my ($blist) = @_;

    file_or_synthesis_dir($blist->{medium}, _blist_first_url($blist));
}

#- side-effects:
#-   + those of try_mounting_medium_ ($medium->{mntpoint})
sub try_mounting_medium {
    my ($urpm, $medium, $o_blist) = @_;

    my $rc = try_mounting_medium_($urpm, $medium, $o_blist);
    $rc or $urpm->{error}(N("unable to access medium \"%s\".", $medium->{name}));
    $rc;
}

#- side-effects:
#-   + those of urpm::cdrom::try_mounting_cdrom ($urpm->{cdrom_mounted}, $medium->{mntpoint}, "hal_mount")
#-   + those of _try_mounting_local ($urpm->{removable_mounted}, "mount")
sub try_mounting_medium_ {
    my ($urpm, $medium, $o_blist) = @_;

    if (urpm::is_cdrom_url($medium->{url})) {
	require urpm::cdrom;
	urpm::cdrom::try_mounting_cdrom($urpm, [ { medium => $medium, pkgs => $o_blist && $o_blist->{pkgs} } ]);
    } else {
	_try_mounting_local($urpm, $medium, $o_blist);
    }
}

#- side-effects:
#-   + those of _try_mounting_using_fstab ($urpm->{removable_mounted}, "mount")
#-   + those of _try_mounting_iso ($urpm->{removable_mounted}, "mount")
sub _try_mounting_local {
    my ($urpm, $medium, $o_blist) = @_;

    my $dir = file_or_synthesis_dir($medium, $o_blist && _blist_first_url($o_blist));
    -e $dir and return 1;

    $medium->{iso} ? _try_mounting_iso($urpm, $dir, $medium->{iso}) : _try_mounting_using_fstab($urpm, $dir);
    -e $dir;
}

#- side-effects: $urpm->{removable_mounted}, "mount"
sub _try_mounting_iso {
    my ($urpm, $dir, $iso) = @_;

    #- note: for isos, we don't parse the fstab because it might not be declared in it.
    #- so we try to remove suffixes from the dir name until the dir exists
    my $mntpoint = urpm::sys::trim_until_d($dir);

    if ($mntpoint) {
	$urpm->{log}(N("mounting %s", $mntpoint));

	sys_log("mount iso $mntpoint on $iso");
	system('mount', $iso, $mntpoint, qw(-t iso9660 -o loop));
	$urpm->{removable_mounted}{$mntpoint} = undef;
    }
}

#- side-effects: $urpm->{removable_mounted}, "mount"
sub _try_mounting_using_fstab {
    my ($urpm, $dir) = @_;

    my $mntpoint = _non_mounted_mntpoint($dir);

    if ($mntpoint) {
	$urpm->{log}(N("mounting %s", $mntpoint));
	sys_log("mount $mntpoint");
	system("mount '$mntpoint' 2>/dev/null");
	$urpm->{removable_mounted}{$mntpoint} = undef;
    }
}

#- side-effects: $urpm->{removable_mounted}, "umount"
sub try_umounting {
    my ($urpm, $dir) = @_;

    if (my $mntpoint = _mounted_mntpoint($dir)) {
	$urpm->{log}(N("unmounting %s", $mntpoint));
	sys_log("umount $mntpoint");
	system("umount '$mntpoint' 2>/dev/null");
	delete $urpm->{removable_mounted}{$mntpoint};
    }
    ! -e $dir;
}

#- side-effects: none
sub _mounted_mntpoint {
    my ($dir) = @_;
    $dir = reduce_pathname($dir);
    my $entry = urpm::sys::find_a_mntpoint($dir);
    $entry->{mounted} && $entry->{mntpoint};
}
#- side-effects: none
sub _non_mounted_mntpoint {
    my ($dir) = @_;
    $dir = reduce_pathname($dir);
    my $entry = urpm::sys::find_a_mntpoint($dir);
    !$entry->{mounted} && $entry->{mntpoint};
}

#- side-effects: $urpm->{removable_mounted}
#-   + those of try_umounting ($urpm->{removable_mounted}, umount)
sub try_umounting_removables {
    my ($urpm) = @_;
    foreach (keys %{$urpm->{removable_mounted}}) {
	try_umounting($urpm, $_);
    }
    delete $urpm->{removable_mounted};
}

#- side-effects:
#-   + those of try_mounting_non_cdrom ($urpm->{removable_mounted}, "mount")
sub try_mounting_non_cdroms {
    my ($urpm, $blists) = @_;

    foreach my $blist (grep { urpm::file_from_local_url($_->{medium}{url}) } @$blists) {
	try_mounting_medium($urpm, $blist->{medium}, $blist);
    }
}

#- side-effects: none
sub _blist_first_url {
    my ($blist) = @_;

    my ($pkg) = values %{$blist->{pkgs}} or return;
    urpm::blist_pkg_to_url($blist, $pkg);
}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut

package urpm::orphans;

use strict;
use urpm::util qw(add2hash_ append_to_file cat_ output_safe partition put_in_hash uniq wc_l);
use urpm::msg;
use urpm;


my $fullname2name_re = qr/^(.*)-[^\-]*-[^\-]*\.[^\.\-]*$/;


=head1 NAME

urpm::orphans - The orphan management code for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut

#- side-effects: none
sub installed_packages_packed {
    my ($urpm) = @_;

    my $db = urpm::db_open_or_die_($urpm);
    my @l;
    $db->traverse(sub {
        my ($pkg) = @_;
	$pkg->pack_header;
	push @l, $pkg;
    });
    \@l;
}


=item unrequested_list__file($urpm)

Return the path of the unrequested list file.

=cut

#- side-effects: none
sub unrequested_list__file {
    my ($urpm) = @_;
    ($urpm->{env_dir} || "$urpm->{root}/var/lib/rpm") . '/installed-through-deps.list';
}

=item unrequested_list($urpm)

Returns the list of potentiel files (ake files installed as requires for others)

=cut

#- side-effects: none
sub unrequested_list {
    my ($urpm) = @_;
    +{ map { 
	chomp; 
	s/\s+\(.*\)$//; 
	$_ => 1;
    } cat_(unrequested_list__file($urpm)) };
}

=item mark_as_requested($urpm, $state, $test)

Mark some packages as explicitly requested (usually because
they were manually installed).

=cut

#- side-effects: those of _write_unrequested_list__file
sub mark_as_requested {
    my ($urpm, $state, $test) = @_;
    my $unrequested = unrequested_list($urpm);
    my $dirty;

    foreach (keys %{$state->{rejected_already_installed}}, 
	     grep { $state->{selected}{$_}{requested} } keys %{$state->{selected}}) {
	my $name = $urpm->{depslist}[$_]->name;
	if (defined($unrequested->{$name})) {
	    $urpm->{info}(N("Marking %s as manually installed, it won't be auto-orphaned", $name));
	    $dirty = 1;
	} else {
	    $urpm->{debug}("$name is not in potential orphans") if $urpm->{debug};
	}
	delete $unrequested->{$name};
    }

    if ($dirty && !$test) {
	_write_unrequested_list__file($urpm, [keys %$unrequested]);
    }
}

=item _installed_req_and_unreq($urpm)

Returns :

=over

=item * req: list of installed packages that were installed as requires of others 

=item * unreq: list of installed packages that were not installed as requres of others (ie the ones that were explicitely selected for install)

=back

=cut

#- side-effects:
#-   + those of _installed_req_and_unreq_and_update_unrequested_list (<root>/var/lib/rpm/installed-through-deps.list)
sub _installed_req_and_unreq {
    my ($urpm) = @_;
    my ($req, $unreq, $_unrequested) = _installed_req_and_unreq_and_update_unrequested_list($urpm);
    ($req, $unreq);
}

=item _installed_and_unrequested_lists($urpm)

Returns :

=over

=item * pkgs: list of installed packages

=item * unrequested: list of packages that were installed as requires of others (the sum of the previous lists)

=back

=cut

#- side-effects:
#-   + those of _installed_req_and_unreq_and_update_unrequested_list (<root>/var/lib/rpm/installed-through-deps.list)
sub _installed_and_unrequested_lists {
    my ($urpm) = @_;
    my ($pkgs, $pkgs2, $unrequested) = _installed_req_and_unreq_and_update_unrequested_list($urpm);
    push @$pkgs, @$pkgs2;
    ($pkgs, $unrequested);
}

#- side-effects: <root>/var/lib/rpm/installed-through-deps.list
sub _write_unrequested_list__file {
    my ($urpm, $unreq) = @_;
    return if $>;

    $urpm->{info}("writing " . unrequested_list__file($urpm));
    
    output_safe(unrequested_list__file($urpm), 
		join('', sort map { $_ . "\n" } @$unreq),
		".old") if !$urpm->{env_dir};
}

=item _installed_req_and_unreq_and_update_unrequested_list ($urpm)

Returns :

=over

=item * req: list of installed packages that were installed as requires of others 

=item * unreq: list of installed packages that were not installed as requres of others (ie the ones that were explicitely selected for install)

=item * unrequested: list of packages that were installed as requires of others (the sum of the previous lists)

=back

=cut

#- side-effects: those of _write_unrequested_list__file
sub _installed_req_and_unreq_and_update_unrequested_list {
    my ($urpm) = @_;

    my $pkgs = installed_packages_packed($urpm);

    $urpm->{debug}("reading and cleaning " . unrequested_list__file($urpm)) if $urpm->{debug};
    my $unrequested = unrequested_list($urpm);
    my ($unreq, $req) = partition { $unrequested->{$_->name} } @$pkgs;
    
    # update the list (to filter dups and now-removed-pkgs)
    my @old = keys %$unrequested;
    my @new = map { $_->name } @$unreq;
    if (@new != @old) {
        _write_unrequested_list__file($urpm, \@new);
    }

    ($req, $unreq, $unrequested);
}

=item _selected_unrequested($urpm, $selected, $rejected)

Returns the new "unrequested" packages.
The reason can be "required by xxx" or "recommended"

=cut

#- side-effects: none
sub _selected_unrequested {
    my ($urpm, $selected, $rejected) = @_;

    require urpm::select;
    map {
	if (my $from = $selected->{$_}{from}) {
	    my $pkg = $urpm->{depslist}[$_];
	    my $name = $pkg->name;
	    $pkg->flag_requested || urpm::select::was_pkg_name_installed($rejected, $name) ? () : 
		($name => "(required by " . $from->fullname . ")");
	} elsif ($selected->{$_}{recommended}) {
	    ($urpm->{depslist}[$_]->name => "(recommended)");
	} else {
	    ();
	}
    } keys %$selected;
}

=item _renamed_unrequested($urpm, $selected, $rejected)

Returns the packages obsoleting packages marked "unrequested"

=cut

#- side-effects: none
sub _renamed_unrequested {
    my ($urpm, $selected, $rejected) = @_;
    
    my @obsoleted = grep { $rejected->{$_}{obsoleted} } keys %$rejected or return;

    # we have to read the list to know if the old package was marked "unrequested"
    my $current = unrequested_list($urpm);

    my %l;
    foreach my $fn (@obsoleted) {
	my ($n) = $fn =~ $fullname2name_re;
	$current->{$n} or next;

	my ($new_fn) = keys %{$rejected->{$fn}{closure}};
	my ($new_n) = $new_fn =~ $fullname2name_re;

	grep { my $pkg = $urpm->{depslist}[$_]; ($pkg->name eq $new_n) && $pkg->flag_installed && $pkg->flag_upgrade } keys %$selected and next;
	if ($new_n ne $n) {
	    $l{$new_n} = "(obsoletes $fn)";
	}
    }
    %l;
}

sub new_unrequested {
    my ($urpm, $state) = @_;
    (
	_selected_unrequested($urpm, $state->{selected}, $state->{rejected}),
	_renamed_unrequested($urpm, $state->{selected}, $state->{rejected}),
    );
}

#- side-effects: <root>/var/lib/rpm/installed-through-deps.list
sub add_unrequested {
    my ($urpm, $state) = @_;

    my %l = new_unrequested($urpm, $state);
    append_to_file(unrequested_list__file($urpm), join('', map { "$_\t\t$l{$_}\n" } keys %l));
}

=item check_unrequested_orphans_after_auto_select($urpm)

We don't want to check orphans on every auto-select.
We do it only after many packages have been added.

Returns whether we should look for orphans depending on a threshold.

=cut

#- side-effects: none
sub check_unrequested_orphans_after_auto_select {
    my ($urpm) = @_;
    my $f = unrequested_list__file($urpm);
    my $nb_added = wc_l($f) - wc_l("$f.old");
    $nb_added >= $urpm->{options}{'nb-of-new-unrequested-pkgs-between-auto-select-orphans-check'};
}


=item unrequested_orphans_after_remove($urpm, $toremove)

This function computes whether removing $toremove packages will create
unrequested orphans.

It does not return the new orphans since "whatrecommends" is not
available,

If it detects there are new orphans, _all_unrequested_orphans() must
be used to have the list of the orphans

=cut

#- side-effects: none
sub unrequested_orphans_after_remove {
    my ($urpm, $toremove) = @_;

    my $db = urpm::db_open_or_die_($urpm);
    my %toremove = map { $_ => 1 } @$toremove;
    _unrequested_orphans_after_remove_once($urpm, $db, unrequested_list($urpm), \%toremove);
}

#- side-effects: none
sub _unrequested_orphans_after_remove_once {
    my ($urpm, $db, $unrequested, $toremove) = @_;

    # first we get the list of requires/recommends that may be unneeded after removing $toremove
    my @requires;
    foreach my $fn (keys %$toremove) {
	my ($n) = $fn =~ $fullname2name_re;

	$db->traverse_tag('name', [ $n ], sub {
	    my ($p) = @_;
	    $p->fullname eq $fn or return;
	    push @requires, $p->requires, $p->recommends_nosense;
	});
    }

    foreach my $req (uniq(@requires)) {
	$db->traverse_tag_find('whatprovides', URPM::property2name($req), sub {
            my ($p) = @_;
	    $toremove->{$p->fullname} and return; # already done
	    $unrequested->{$p->name} or return;
	    $p->provides_overlap($req) or return;

	    # cool, $p is "unrequested" and will potentially be newly unneeded
	    if (_will_package_be_unneeded($urpm, $db, $toremove, $p)) {
		$urpm->{debug}("installed " . $p->fullname . " can now be removed") if $urpm->{debug};
		return 1;
	    } else {
		$urpm->{debug}("installed " . $p->fullname . " can not be removed") if $urpm->{debug};
	    }
	    0;
	}) and return 1;
    }
    0;
}

=item _will_package_be_unneeded($urpm, $db, $toremove, $pkg)

Return true if $pkg will no more be required after removing $toremove

nb: it may wrongly return false for complex loops,
but will never wrongly return true

=cut

#- side-effects: none
sub _will_package_be_unneeded {
    my ($urpm, $db, $toremove, $pkg) = @_;

    my $required_maybe_loop;

    foreach my $prop ($pkg->provides) {
	_will_prop_still_be_needed($urpm, $db, $toremove, 
				   scalar($pkg->fullname), $prop, \$required_maybe_loop)
	  and return;	
    }

    if ($required_maybe_loop) {
	my ($fullname, @provides) = @$required_maybe_loop;
	$urpm->{debug}("checking whether $fullname is a dependency loop") if $urpm->{debug};

	# doing it locally, since we may fail (and so we must backtrack this change)
	my %ignore = %$toremove;
	$ignore{$pkg->fullname} = 1;

	foreach my $prop (@provides) {
	    #- nb: here we won't loop.
	    _will_prop_still_be_needed($urpm, $db, \%ignore, 
				       $fullname, $prop, \$required_maybe_loop)
	      and return;
	}
    }
    1;
}

=item _will_prop_still_be_needed($urpm, $db, $toremove, $fullname, $prop, $required_maybe_loop)

Return true if $prop will still be required after removing $toremove

=cut

#- side-effects: none
sub _will_prop_still_be_needed {
    my ($urpm, $db, $toremove, $fullname, $prop, $required_maybe_loop) = @_;

    my ($prov, $range) = URPM::property2name_range($prop) or return;
    
    $db->traverse_tag_find('whatrequires', $prov, sub {
	my ($p2) = @_;
	$toremove->{$p2->fullname} and return 0; # this one is going to be removed, skip it

	foreach ($p2->requires) {
	    my ($pn, $ps) = URPM::property2name_range($_) or next;
	    if ($pn eq $prov && URPM::ranges_overlap($ps, $range)) {
		#- we found $p2 which requires $prop

		if ($$required_maybe_loop) {
		    $urpm->{debug}("  installed " . $p2->fullname . " still requires " . $fullname) if $urpm->{debug};
		    return 1;
		}
		$urpm->{debug}("  installed " . $p2->fullname . " may still requires " . $fullname) if $urpm->{debug};
		$$required_maybe_loop = [ scalar $p2->fullname, $p2->provides ];
	    }
	}
	0;
    });
}

=item _get_current_kernel_package()

Return the current kernel's package so that we can filter out current running
kernel:

=cut

sub _get_current_kernel_package() {
    my $release = (POSIX::uname())[2];
    # --qf '%{name}' is used in order to provide the right format:
    -e "/boot/vmlinuz-$release" && ($release, `rpm -qf --qf '%{name}' /boot/vmlinuz-$release`);
}


=item _kernel_callback ($pkg, $unreq_list)

Returns list of kernels

_fast_ version w/o looking at all non kernel packages requires on
kernels (like "urpmi_find_leaves '^kernel'" would)

_all_unrequested_orphans blacklists nearly all kernels b/c of packages
like 'ndiswrapper' or 'basesystem' that requires 'kernel'

rationale: other packages only require 'kernel' or a sub package we
do not care about (eg: kernel-devel, kernel-firmware, kernel-latest)
so it's useless to look at them

=cut

my (@req_by_latest_kernels, %requested_kernels, %kernels);
sub _kernel_callback { 
    my ($pkg, $unreq_list) = @_;
    my $shortname = $pkg->name;
    my $n = $pkg->fullname;

    # only consider kernels (and not main 'kernel' package):
    # but perform a pass on their requires for dkms like packages that require a specific kernel:
    if ($shortname !~ /^kernel-/) {
	foreach (grep { /^kernel/ } $pkg->requires_nosense) {
	    $requested_kernels{$_}{$shortname} = $pkg;
	}
	return;
    }

    # only consider real kernels (and not kernel-doc and the like):
    return if $shortname =~ /-(?:source|doc|headers|firmware(?:|-extra|-nonfree))$/;

    # ignore requested kernels (aka that are not in /var/lib/rpm/installed-through-deps.list)
    return if !$unreq_list->{$shortname} && $shortname !~ /latest/;

    # keep track of packages required by latest kernels in order not to try removing requested kernels:
    if ($n =~ /latest/) {
        push @req_by_latest_kernels, $pkg->requires;
    } else {
        $kernels{$shortname} = $pkg;
    }
}


=item _get_orphan_kernels()

Returns list of orphan kernels

=cut

sub _get_orphan_kernels() {
    # keep kernels required by kernel-*-latest:
    delete $kernels{$_} foreach @req_by_latest_kernels;
    # return list of unused/orphan kernels:
    \%kernels;
}


=item _all_unrequested_orphans($urpm, $req, $unreq)

Returns the list of "unrequested" orphans.

=cut

#- side-effects: none
sub _all_unrequested_orphans {
    my ($urpm, $req, $unreq) = @_;

    my (%l, %provides);
    # 1- list explicit provides (not files) from installed packages:
    foreach my $pkg (@$unreq) {
	$l{$pkg->name} = $pkg;
	push @{$provides{$_}}, $pkg foreach $pkg->provides_nosense;
    }
    my $unreq_list = unrequested_list($urpm);

    my ($current_kernel_version, $current_kernel) = _get_current_kernel_package();

    # 2- check if "unrequested" packages are still needed:
    while (my $pkg = shift @$req) {
        # do not do anything regarding kernels if we failed to detect the running one (ie: chroot)
 	_kernel_callback($pkg, $unreq_list) if $current_kernel;
	foreach my $prop ($pkg->requires, $pkg->recommends_nosense) {
	    my $n = URPM::property2name($prop);
	    foreach my $p (@{$provides{$n} || []}) {
		if ($p != $pkg && $l{$p->name} && $p->provides_overlap($prop)) {
		    delete $l{$p->name};
		    push @$req, $p;
		}
	    }
	}
    }

    # add orphan kernels to the list:
    my $a = _get_orphan_kernels();
    add2hash_(\%l, $a);

    # add packages that require orphan kernels to the list:
    foreach (keys %$a) {
	add2hash_(\%l, $requested_kernels{$_});
    }

    # do not offer to remove current kernel or DKMS modules for current kernel:
    delete $l{$current_kernel};
    # prevent removing orphan kernels if we failed to detect running kernel version:
    if ($current_kernel_version) {
        do { delete $l{$_} } foreach grep { /$current_kernel_version/ } keys %l;
    }

    [ values %l ];
}

=item compute_future_unrequested_orphans($urpm, $state)

Compute the list of packages that will be unrequested and
could potently be removed.

=cut

#- side-effects: $state->{orphans_to_remove}
#-   + those of _installed_and_unrequested_lists (<root>/var/lib/rpm/installed-through-deps.list)
sub compute_future_unrequested_orphans {
    my ($urpm, $state) = @_;

    $urpm->{log}("computing unrequested orphans");

    my ($current_pkgs, $unrequested) = _installed_and_unrequested_lists($urpm);

    put_in_hash($unrequested, { new_unrequested($urpm, $state) });

    my %toremove = map { $_ => 1 } URPM::removed_or_obsoleted_packages($state);
    my @pkgs = grep { !$toremove{$_->fullname} } @$current_pkgs;
    push @pkgs, map { $urpm->{depslist}[$_] } keys %{$state->{selected} || {}};

    my ($unreq, $req) = partition { $unrequested->{$_->name} } @pkgs;

    $state->{orphans_to_remove} = _all_unrequested_orphans($urpm, $req, $unreq);

    # nb: $state->{orphans_to_remove} is used when computing ->selected_size
}


=item get_orphans($urpm)

Returns the list of unrequested packages (aka orphans).

It is quite fast. the slow part is the creation of
$installed_packages_packed (using installed_packages_packed())

=cut

#
#- side-effects:
#-   + those of _installed_req_and_unreq (<root>/var/lib/rpm/installed-through-deps.list)
sub get_orphans {
    my ($urpm) = @_;

    $urpm->{log}("computing unrequested orphans");

    my ($req, $unreq) = _installed_req_and_unreq($urpm);
    _all_unrequested_orphans($urpm, $req, $unreq);
}

sub _get_now_orphans_raw_msg {
    my ($urpm) = @_;

    my $orphans = get_orphans($urpm);
    my @orphans = map { scalar $_->fullname } @$orphans or return;

    (scalar(@orphans), add_leading_spaces(join("\n", sort @orphans)));
}

=item get_now_orphans_gui_msg($urpm)

Like get_now_orphans_msg() but more suited for GUIes, it return
message about orphan packages.

Used by rpmdrake.

=cut

sub get_now_orphans_gui_msg {
    my ($urpm) = @_;

    my ($count, $list) = _get_now_orphans_raw_msg($urpm) or return;
    join("\n",
       P("The following package:\n%s\nis now orphaned.",
         "The following packages:\n%s\nare now orphaned.", $count, $list),
        undef,
	P("You may wish to remove it.",
	  "You may wish to remove them.", $count)
    );
}


=item get_now_orphans_msg($urpm)

Similar to get_now_orphans_gui_msg() but more suited for CLI, it
return message about orphan packages.

=cut

sub get_now_orphans_msg {
    my ($urpm) = @_;

    my ($count, $list) = _get_now_orphans_raw_msg($urpm) or return;
    P("The following package:\n%s\nis now orphaned, if you wish to remove it, you can use \"urpme --auto-orphans\"",
      "The following packages:\n%s\nare now orphaned, if you wish to remove them, you can use \"urpme --auto-orphans\"",
      $count, $list) . "\n";
}


=item add_leading_spaces($string)

Add leading spaces to the string and return it.

=cut

#- side-effects: none
sub add_leading_spaces {
    my ($s) = @_;
    $s =~ s/^/  /gm;
    $s;
}

#- side-effects: none
sub installed_leaves {
    my ($urpm, $o_discard) = @_;

    my $packages = installed_packages_packed($urpm);

    my (%l, %provides);
    foreach my $pkg (@$packages) {
	next if $o_discard && $o_discard->($pkg);
	$l{$pkg->name} = $pkg;
	push @{$provides{$_}}, $pkg foreach $pkg->provides_nosense;
    }

    foreach my $pkg (@$packages) {
	foreach my $prop ($pkg->requires, $pkg->recommends_nosense) {
	    my $n = URPM::property2name($prop);
	    foreach my $p (@{$provides{$n} || []}) {
		$p != $pkg && $p->provides_overlap($prop) and 
		  delete $l{$p->name};
	    }
	}
    }

    [ values %l ];
}

1;


=back

=head1 COPYRIGHT


Copyright (C) 2008-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut

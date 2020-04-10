package URPM;
#package URPM::Resolve;
#use URPM;


use strict;
use warnings;
use Config;

# perl_checker: require URPM


=head1 NAME

URPM::Resolve - Resolve routines for URPM/urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut 


#- a few functions from MDK::Common copied here:
sub any(&@) {
    my $f = shift;
    $f->($_) and return 1 foreach @_;
    0;
}
sub uniq {
    my (@l) = @_;
    my %l;
    $l{$_} = 1 foreach @l;
    grep { delete $l{$_} } @l;
}
sub find(&@) {
    my $f = shift;
    $f->($_) and return $_ foreach @_;
    undef;
}

=back

=head2 The property functions

The property2name* functions parse things like "mageia-release[>= 1]"
which is the format returned by URPM.xs for ->requires, ->provides, ->conflicts...

=over 4

=item property2name($property)

Returns the property name (eg: "mageia-release" in above example)

=cut

sub property2name {
    my ($property) = @_;
    $property =~ /^([^\s\[]*)/ && $1;
}

=item property2name_range($property)

Returns the property name & range (eg: "mageia-release" & ">= 1" in above example)

=cut

sub property2name_range {
    my ($property) = @_;
    $property =~ /^([^\s\[]*)(?:\[\*\])?\[?([^\s\]]*\s*[^\s\]]*)/;
}

=item property2name_op_version($property)

Returns the property name, operator & range (eg: "mageia-release", ">=", & "1" in above example)

=cut


sub property2name_op_version {
    my ($property) = @_;
    $property =~ /^([^\s\[]*)(?:\[\*\])?\s*\[?([^\s\]]*)\s*([^\s\]]*)/;
}


=back

=head2 The state functions

Those are wrappers around $state (cf "The $state object" in L<URPM>).

=over 4

=item packages_to_remove($state)

Returns the ids of the packages to remove

=cut


sub packages_to_remove {
    my ($state) = @_;
    grep {
	$state->{rejected}{$_}{removed} && !$state->{rejected}{$_}{obsoleted};
    } keys %{$state->{rejected} || {}};
}

=item removed_or_obsoleted_packages($state)

Returns the ids of the packages that are either to remove or are obsoleted

=cut

sub removed_or_obsoleted_packages {
    my ($state) = @_;
    grep {
	$state->{rejected}{$_}{removed} || $state->{rejected}{$_}{obsoleted};
    } keys %{$state->{rejected} || {}};
}

=back

=head2 Strict arch related functions

=over 4

=item strict_arch($urpm)

Is "strict-arch" wanted? (cf "man urpmi")
Since it's slower we only force it on bi-arch

=cut

sub strict_arch {
    my ($urpm) = @_;
    defined $urpm->{options}{'strict-arch'} ? $urpm->{options}{'strict-arch'} : $Config{archname} =~ /x86_64|sparc64|ppc64/;
}
my %installed_arch;

=item strict_arch_check_installed($db, $pkg) 

Checks whether $pkg could be installed under strict-arch policy
(ie check whether $pkg->name with different arch is not installed)

=cut

#- side-effects: none (but uses a cache)
sub strict_arch_check_installed {
    my ($db, $pkg) = @_;
    my $arch = $pkg->arch;
    if ($arch ne 'src' && $arch ne 'noarch') {
	my $n = $pkg->name;
	defined $installed_arch{$n} or $installed_arch{$n} = get_installed_arch($db, $n);
	if ($installed_arch{$n} && $installed_arch{$n} ne 'noarch') {
	    $arch eq $installed_arch{$n} or return;
	}
    }
    1;
}

=item strict_arch_check($installed_pkg, $pkg) = @_;

Check whether $installed_pkg and $pkg have same arch
(except for src/noarch of course)

=cut

#- side-effects: none
sub strict_arch_check {
    my ($installed_pkg, $pkg) = @_;
    my $arch = $pkg->arch;
    if ($arch ne 'src' && $arch ne 'noarch') {
	my $inst_arch = $installed_pkg->arch;
	if ($inst_arch ne 'noarch') {
	    $arch eq $inst_arch or return;
	}
    }
    1;
}

=back

=head2 Installed packages related functions

=over 4

=item get_installed_arch($db, $n)

Returns the architecture of package $n in rpm DB

=cut

sub get_installed_arch {
    my ($db, $n) = @_;
    my $arch;
    $db->traverse_tag_find('name', $n, sub { $arch = $_[0]->arch; 1 });
    $arch;
}

=item is_package_installed($db, $n)

Is $pkg->name installed?

=cut

#- side-effects: none
sub is_package_installed {
    my ($db, $pkg) = @_;

    my $found;
    $db->traverse_tag_find('name', $pkg->name, sub {
	my ($p) = @_;
	$found ||= $p->fullname eq $pkg->fullname;
    });
    $found;
}

sub _is_selected_or_installed {
    my ($urpm, $db, $name) = @_;

    (grep { $_->flag_available } $urpm->packages_providing($name)) > 0 ||
      $db->traverse_tag('name', [ $name ], undef) > 0;
}

=item provided_version_that_overlaps($pkg, $provide_name)

Finds $pkg "provides" that matches $provide_name, and returns the version provided.
eg: $pkg provides "a = 3", $provide_name is "a > 1", returns "3"

=cut

sub provided_version_that_overlaps {
    my ($pkg, $provide_name) = @_;

    my $version;
    foreach my $property ($pkg->provides) {
	my ($n, undef, $v) = property2name_op_version($property) or next;
	$n eq $provide_name or next;

	if ($version) {
	    $version = $v if URPM::rpmvercmp($v, $version) > 0;
	} else {
	    $version = $v;
	}
    }
    $version;
}


=item find_required_package($urpm, $db, $state, $id_prop)

Find the package (or packages) to install matching $id_prop.
Returns (list ref of matches, list ref of preferred matches)
(see also find_candidate_packages())

=cut

#- side-effects: flag_install, flag_upgrade (and strict_arch_check_installed cache)
sub find_required_package {
    my ($urpm, $db, $state, $id_prop) = @_;
    my (%packages, %provided_version);
    my $strict_arch = strict_arch($urpm);

    my $may_add_to_packages = sub {
	my ($pkg) = @_;

	if (my $p = $packages{$pkg->name}) {
	    $pkg->flag_requested > $p->flag_requested ||
	      $pkg->flag_requested == $p->flag_requested && $pkg->compare_pkg($p) > 0 and $packages{$pkg->name} = $pkg;
	} else {
	    $packages{$pkg->name} = $pkg;
	}
    };

    #- search for possible packages, try to be as fast as possible, backtrack can be longer.
    foreach (split /\|/, $id_prop) {
	if (/^\d+$/) {
	    my $pkg = $urpm->{depslist}[$_];
	    $pkg->arch eq 'src' || $pkg->is_arch_compat or next;
	    $pkg->flag_skip || $state->{rejected}{$pkg->fullname} and next;
	    #- determine if this package is better than a possibly previously chosen package.
	    $pkg->flag_selected || exists $state->{selected}{$pkg->id} and return [$pkg];
	    !$strict_arch || strict_arch_check_installed($db, $pkg) or next;
	    $may_add_to_packages->($pkg);
	} elsif (my $name = property2name($_)) {
	    my $property = $_;
	    foreach my $pkg (packages_providing($urpm, $name)) {
		$pkg->is_arch_compat or next;
		$pkg->flag_skip || $state->{rejected}{$pkg->fullname} and next;
		#- check if at least one provide of the package overlaps the property
		if (!$urpm->{provides}{$name}{$pkg->id} || $pkg->provides_overlap($property)) {
		    #- determine if this package is better than a possibly previously chosen package.
		    $pkg->flag_selected || exists $state->{selected}{$pkg->id} and return [$pkg];
		    !$strict_arch || strict_arch_check_installed($db, $pkg) or next;
		    $provided_version{$pkg} = provided_version_that_overlaps($pkg, $name);
		    $may_add_to_packages->($pkg);		    
		}
	    }
	}
    }
    my @packages = sort { $a->fullname cmp $b->fullname } values %packages;

    if (@packages > 1) {
	#- packages should be preferred if one of their provides is referenced
	#- in the "requested" hash, or if the package itself is requested (or
	#- required).
	#- If there is no preference, choose the first one by default (higher
	#- probability of being chosen) and ask the user.
	#- Packages with more compatibles architectures are always preferred.
	#- Puts the results in @chosen. Other are left unordered.
	foreach my $pkg (@packages) {
	    _set_flag_installed_and_upgrade_if_no_newer($db, $pkg);
	}

	if (my @kernel_source = _find_required_package__kernel_source($urpm, $db, \@packages)) {
	    $urpm->{debug_URPM}("packageCallbackChoices: kernel source chosen " . join(",", map { $_->name } @kernel_source) . " in " . join(",", map { $_->name } @packages)) if $urpm->{debug_URPM};
	    return \@kernel_source, \@kernel_source;
	}
	if (my @kmod = _find_required_package__kmod($urpm, $db, \@packages)) {
	    $urpm->{debug_URPM}("packageCallbackChoices: kmod packages " . join(",", map { $_->name } @kmod) . " in " . join(",", map { $_->name } @packages)) if $urpm->{debug_URPM};
	    return \@kmod, \@kmod;
	}

	_find_required_package__sort($urpm, $db, \@packages, \%provided_version);
    } else {
	\@packages;
    }
}

# nb: _set_flag_installed_and_upgrade_if_no_newer must be done on $packages
sub _find_required_package__sort {
    my ($urpm, $db, $packages, $provided_version) = @_;

	my ($best, @other) = sort {
	      $a->[1] <=> $b->[1] #- we want the lowest (ie preferred arch)
	      || $b->[2] <=> $a->[2] #- and the higher score
	      || $b->[0]->compare_pkg($a->[0]) #- then by EVR (for upgrade)
	      || $a->[0]->fullname cmp $b->[0]->fullname; #- then by name
	} map {
	    my $score = 0;
	    $score += 2 if $_->flag_requested;
	    $score += $_->flag_upgrade ? 1 : -1 if $_->flag_installed;
	    [ $_, $_->is_arch_compat, $score ];
	} @$packages;

	my @chosen_with_score = ($best, grep { $_->[1] == $best->[1] && $_->[2] == $best->[2] } @other);
	my @chosen = map { $_->[0] } @chosen_with_score;

	#- return immediately if there is only one chosen package
	return \@chosen if @chosen == 1;

	#- if several packages were selected to match a requested installation,
	#- and if --more-choices wasn't given, trim the choices to the first one.
	if (!$urpm->{options}{morechoices} && $chosen_with_score[0][2] == 3) {
	    return [ $chosen[0] ];
	}

    if ($urpm->{media}) {
	@chosen_with_score = sort {
	    $a->[2] != $b->[2] ? 
	       $b->[0]->compare_pkg($a->[0]) :
	       $b->[1] <=> $a->[1] || $b->[0]->compare_pkg($a->[0]);
	} map { [ $_, _score_for_locales($urpm, $db, $_), pkg2media($urpm->{media}, $_) ] } @chosen;
    } else {
	# obsolete code which should not happen, kept just in case
	$urpm->{debug_URPM}("can't sort choices by media") if $urpm->{debug_URPM};
	@chosen_with_score = sort {
	    $b->[1] <=> $a->[1] ||
	      $b->[0]->compare_pkg($a->[0]) || $a->[0]->id <=> $b->[0]->id;
	} map { [ $_, _score_for_locales($urpm, $db, $_) ] } @chosen;
    }
    if (!$urpm->{options}{morechoices}) {
	if (my @valid_locales = grep { $_->[1] } @chosen_with_score) {
	    #- get rid of invalid locales
	    @chosen_with_score = @valid_locales;
	}
    }
    # propose to select all packages for installed locales
    my @prefered = grep { $_->[1] == 3 } @chosen_with_score;

    @chosen = map { $_->[0] } @chosen_with_score;
    if (%$provided_version) {
	# highest provided version first
	# (nb: this sort overrules the sort on media (cf ->id above))
	@chosen = sort { URPM::rpmvercmp($provided_version->{$b} || 0, $provided_version->{$a} || 0) } @chosen;
    }
    \@chosen, [ map { $_->[0] } @prefered ];
}

=back

=head2 Choosing packages helpers

=over 4

=item _find_required_package__kernel_source($urpm, $db, $choices)

Prefer the pkgs corresponding to installed/selected kernels

=cut

sub _find_required_package__kernel_source {
    my ($urpm, $db, $choices) = @_;

    $choices->[0]->name =~ /^kernel-(.*source-|.*-devel-)/ or return;

    grep {
	if ($_->name =~ /(kernel-.*)-devel-(.*)/) {
	    my $kernel = "$1-$2";
	    _is_selected_or_installed($urpm, $db, $kernel);
	} elsif ($_->name =~ /^kernel-.*source-/) {
	    #- hopefully we don't have a media with kernel-source but not kernel-.*-devel
	    0;
	} else {
	    $urpm->{debug_URPM}("unknown kernel-source package " . $_->fullname) if $urpm->{debug_URPM};
	    0;
	}
    } @$choices;
}

=item _find_required_package__kmod($urpm, $db, $choices)

Prefer the pkgs corresponding to installed/selected kernels

=cut

sub _find_required_package__kmod {
    my ($urpm, $db, $choices) = @_;

    $choices->[0]->name =~ /^dkms-|-kernel-\d\./ or return;

    grep {
	if (my ($version, $flavor, $release) = $_->name =~ /(?:.*)-kernel-(\d\..*)-(.*)-(.*)/) {
	    my $kernel = "kernel-$flavor-$version-$release";
	    _is_selected_or_installed($urpm, $db, $kernel);
	} elsif ($_->name =~ /^dkms-/) {
	    0; # we prefer precompiled dkms
	} else {
	    $urpm->{debug_URPM}("unknown kmod package " . $_->fullname) if $urpm->{debug_URPM};
	    0;
	}
    } @$choices;
}

=item _score_for_locales($urpm, $db, $pkg)

Packages that require locales-xxx when the corresponding locales are
already installed should be preferred over packages that require locales
which are not installed.

eg: locales-fr & locales-de are installed, 
     prefer firefox-fr & firefox-de which respectively require locales-fr & locales-de

=cut

sub _score_for_locales {
    my ($urpm, $db, $pkg) = @_;

    my @r = $pkg->requires_nosense;

    if (my ($specific_locales) = grep { /locales-(?!en)/ } @r) {
	if (_is_selected_or_installed($urpm, $db, $specific_locales)) {
	      3; # good locale
	  } else {
	      0; # bad locale
	  }
    } elsif (any { /locales-en/ } @r) {
	2; # 
    } else {
	1;
    }
}

#- side-effects: $properties, $choices
#-   + those of backtrack_selected ($state->{backtrack}, $state->{rejected}, $state->{selected}, $state->{whatrequires}, flag_requested, flag_required)
sub _choose_required {
    my ($urpm, $db, $state, $dep, $properties, $choices, $diff_provides, %options) = @_;

    #- take the best choice possible.
    my ($chosen, $prefered) = find_required_package($urpm, $db, $state, $dep->{required});

    #- If no choice is found, this means that nothing can be possibly selected
    #- according to $dep, so we need to retry the selection, allowing all
    #- packages that conflict or anything similar to see which strategy can be
    #- tried. Backtracking is used to avoid trying multiple times the same
    #- packages. If multiple packages are possible and properties is not
    #- empty, postpone the choice for a later time as one of the packages
    #- may be selected for another reason. Otherwise simply ask the user which
    #- one to choose; else take the first one available.
    if (!@$chosen) {
	$urpm->{debug_URPM}("no packages match " . _dep_to_name($urpm, $dep) . " (it is either in skip.list or already rejected)") if $urpm->{debug_URPM};
	unshift @$properties, backtrack_selected($urpm, $db, $state, $dep, $diff_provides, %options);
	return; #- backtrack code choose to continue with same package or completely new strategy.
    } elsif (@$chosen > 1) {
	if (@$properties) {
	    unshift @$choices, $dep;
	    return;
	} elsif ($options{callback_choices}) {
	    my @l = grep { ref $_ } $options{callback_choices}->($urpm, $db, $state, $chosen, _dep_to_name($urpm, $dep), $prefered);
	    $urpm->{debug_URPM}("replacing " . _dep_to_name($urpm, $dep) . " with " . 
				join(' ', map { $_->name } @l)) if $urpm->{debug_URPM};
	    unshift @$properties, map {
		+{
		    required => $_->id,
		    _choices => $dep->{required},
		    exists $dep->{from} ? (from => $dep->{from}) : @{[]},
		    exists $dep->{requested} ? (requested => $dep->{requested}) : @{[]},
		};
	    } @l;
	    return; #- always redo according to choices.
	}
    }


    #- now do the real work, select the package.
    my $pkg = shift @$chosen;
    if ($urpm->{debug_URPM} && $pkg->name ne _dep_to_name($urpm, $dep)) {
	$urpm->{debug_URPM}("chosen " . $pkg->fullname . " for " . _dep_to_name($urpm, $dep));
	@$chosen and $urpm->{debug_URPM}("  (it could also have chosen " . join(' ', map { scalar $_->fullname } @$chosen));
    }

    $pkg;
}

=back

=head2 Misc helpers

=over 4

=item pkg2media($mediums, $pkg)

Return the medium that contains the URPM::Package $pkg

=cut

sub pkg2media {
   my ($mediums, $p) = @_; 
   my $id = $p->id;
   #- || 0 to avoid undef, but is it normal to have undef ?
   find { $id >= ($_->{start} || 0) && $id <= ($_->{end} || 0) } @$mediums;
}


=back

=head2 Dependancy resolver related functions

=over 4

=item find_candidate_packages($urpm, $id_prop, $o_rejected)

Find candidates packages from a require string (or id).
Takes care of choices using the '|' separator.
(nb: see also find_required_package())

=cut

#- side-effects: none
sub find_candidate_packages {
    my ($urpm, $id_prop, $o_rejected) = @_;
    my @packages;

    foreach (split /\|/, $id_prop) {
	if (/^\d+$/) {
	    my $pkg = $urpm->{depslist}[$_];
	    $pkg->flag_skip and next;
	    $pkg->arch eq 'src' || $pkg->is_arch_compat or next;
	    $o_rejected && exists $o_rejected->{$pkg->fullname} and next;
	    push @packages, $pkg;
	} elsif (my $name = property2name($_)) {
	    my $property = $_;
	    foreach (sort keys %{$urpm->{provides}{$name} || {}}) {
		my $pkg = $urpm->{depslist}[$_];
		$pkg->flag_skip and next;
		$pkg->is_arch_compat or next;
		$o_rejected && exists $o_rejected->{$pkg->fullname} and next;
		#- check if at least one provide of the package overlap the property.
		!$urpm->{provides}{$name}{$_} || $pkg->provides_overlap($property)
		    and push @packages, $pkg;
	    }
	}
    }
    @packages;
}


=item whatrequires($urpm, $state, $property_name)

Return packages requiring $property_name

=cut

sub whatrequires {
    my ($urpm, $state, $property_name) = @_;

    map { $urpm->{depslist}[$_] } whatrequires_id($state, $property_name);
}

=item whatrequires_id($state, $property_name)

Return ids of packages requiring $property_name

=cut

sub whatrequires_id {
    my ($state, $property_name) = @_;

    keys %{$state->{whatrequires}{$property_name} || {}};
}

=item unsatisfied_requires($urpm, $db, $state, $pkg, %options)

Return unresolved requires of a package (a new one or an existing one).

=cut

#- side-effects: none (but uses a $state->{cached_installed})
sub unsatisfied_requires {
    my ($urpm, $db, $state, $pkg, %options) = @_;
    my %unsatisfied;

    #- all requires should be satisfied according to selected packages or installed packages,
    #- or the package itself.
  REQUIRES: foreach my $prop ($pkg->requires) {
	my ($n, $s) = property2name_range($prop) or next;

	if (defined $options{name} && $n ne $options{name}) {
	    #- allow filtering on a given name (to speed up some search).
	} elsif (exists $unsatisfied{$prop}) {
	    #- avoid recomputing the same all the time.
	} else {
	    #- check for installed packages in the installed cache.
	    foreach (keys %{$state->{cached_installed}{$n} || {}}) {
		exists $state->{rejected}{$_} and next;
		next REQUIRES;
	    }

	    #- check on the selected package if a provide is satisfying the resolution (need to do the ops).
	    foreach (grep { exists $state->{selected}{$_} } keys %{$urpm->{provides}{$n} || {}}) {
		my $p = $urpm->{depslist}[$_];
		next if $p->arch eq 'src'; # ignore provides from SRPM (new in rpm-4.16)
		!$urpm->{provides}{$n}{$_} || $p->provides_overlap($prop) and next REQUIRES;
	    }

	    #- check if the package itself provides what is necessary.
	    $pkg->arch ne 'src' and $pkg->provides_overlap($prop) and next REQUIRES;

	    #- check on installed system if a package which is not obsoleted is satisfying the require.
	    my $satisfied = 0;
	    if ($n =~ m!^/!) {
		$db->traverse_tag('path', [ $n ], sub {
		    my ($p) = @_;
		    exists $state->{rejected}{$p->fullname} and return;
		    $state->{cached_installed}{$n}{$p->fullname} = undef;
		    ++$satisfied;
		});
	    } else {
		$db->traverse_tag('whatprovides', [ $n ], sub {
		    my ($p) = @_;
		    exists $state->{rejected}{$p->fullname} and return;
		    foreach ($p->provides) {
			if (my ($pn, $ps) = property2name_range($_)) {
			    $ps or $state->{cached_installed}{$pn}{$p->fullname} = undef;
			    $pn eq $n or next;
			    URPM::ranges_overlap($ps, $s) and ++$satisfied;
			}
		    }
		});
	    }
	    #- if nothing can be done, the require should be resolved.
	    $satisfied or $unsatisfied{$prop} = undef;
	}
    }

    keys %unsatisfied;
}

=item with_db_unsatisfied_requires($urpm, $db, $state, $name, $do)

This function is "recommends vs requires" safe:
Traversing DB on 'whatrequires' will give both requires & recommends, but ->unsatisfied_requires()
will check $p->requires and so filter out recommends

=cut

#- side-effects: only those done by $do
sub with_db_unsatisfied_requires {
    my ($urpm, $db, $state, $name, $do) = @_;

    $db->traverse_tag('whatrequires', [ $name ], sub {
	my ($p) = @_;
	if (my @l = unsatisfied_requires($urpm, $db, $state, $p, name => $name)) {
	    $urpm->{debug_URPM}("installed " . $p->fullname . " is conflicting because of unsatisfied @l") if $urpm->{debug_URPM};
	    $do->($p, @l);
	}
    });
}

=item with_state_unsatisfied_requires($urpm, $db, $state, $name, $do)

# LOG: do not ignore dropped provide from updated package (mdvbz#40842)
#	 		 (http://svn.mandriva.com/viewvc/soft/rpm/perl-URPM/trunk/URPM/Resolve.pm?r1=242655&r2=242656&)
# TV: was introduced in order to replace one with_db_unsatisfied_requires() call by with_any_unsatisfied_requires()

=cut

#- side-effects: only those done by $do
sub with_state_unsatisfied_requires {
    my ($urpm, $db, $state, $name, $do) = @_;

    foreach (whatrequires_id($state, $name)) {
	$state->{selected}{$_} or next;
	my $p = $urpm->{depslist}[$_];
	if (my @l = unsatisfied_requires($urpm, $db, $state, $p, name => $name)) {
	    $urpm->{debug_URPM}("selected " . $p->fullname . " is conflicting because of unsatisfied @l") if $urpm->{debug_URPM};
	    $do->($p, @l);
        }
    }
}


=item with_any_unsatisfied_requires($urpm, $db, $state, $name, $do)

See above...

=cut

sub with_any_unsatisfied_requires {
    my ($urpm, $db, $state, $name, $do) = @_;
    with_db_unsatisfied_requires($urpm, $db, $state, $name, sub { my ($p, @l) = @_; $do->($p, 0, @l) });
    with_state_unsatisfied_requires($urpm, $db, $state, $name, sub { my ($p, @l) = @_; $do->($p, 1, @l) });
}

=item backtrack_selected($urpm, $db, $state, $dep, $diff_provides, %options)

Used when a require is not available

=cut

#- side-effects: $state->{backtrack}, $state->{selected}
#-   + those of disable_selected_and_unrequested_dependencies ($state->{whatrequires}, flag_requested, flag_required)
#-   + those of _set_rejected_from ($state->{rejected})
#-   + those of set_rejected_and_compute_diff_provides ($state->{rejected}, $diff_provides_h)
#-   + those of _add_rejected_backtrack ($state->{rejected})
sub backtrack_selected {
    my ($urpm, $db, $state, $dep, $diff_provides, %options) = @_;

    if (defined $dep->{required}) {
	#- avoid deadlock here...
	if (!exists $state->{backtrack}{deadlock}{$dep->{required}}) {
	    $state->{backtrack}{deadlock}{$dep->{required}} = undef;

	    #- search for all possible packages, first is to try the selection, then if it is
	    #- impossible, backtrack the origin.
	    my @packages = find_candidate_packages($urpm, $dep->{required});

	    foreach (@packages) {
		    #- avoid dead loop.
		    exists $state->{backtrack}{selected}{$_->id} and next;
		    #- a package if found is probably rejected or there is a problem.
		    if ($state->{rejected}{$_->fullname}) {
			#- keep in mind a backtrack has happening here...
			exists $dep->{promote} and _add_rejected_backtrack($state, $_, { promote => [ $dep->{promote} ] });

			my $closure = $state->{rejected}{$_->fullname}{closure} || {};
			foreach my $p (grep { exists $closure->{$_}{avoid} } keys %$closure) {
				_add_rejected_backtrack($state, $_, { conflicts => [ $p ] });
			}
			#- backtrack callback should return a strictly positive value if the selection of the new
			#- package is preferred over the currently selected package.
			next;
		    }
		    $state->{backtrack}{selected}{$_->id} = undef;

		    #- in such case, we need to drop the problem caused so that rejected condition is removed.
		    #- if this is not possible, the next backtrack on the same package will be refused above.
		    my @l = map { $urpm->search($_, strict_fullname => 1) }
		      keys %{($state->{rejected}{$_->fullname} || {})->{closure}};

		    disable_selected_and_unrequested_dependencies($urpm, $db, $state, @l);

		    return { required => $_->id,
			     exists $dep->{from} ? (from => $dep->{from}) : @{[]},
			     exists $dep->{requested} ? (requested => $dep->{requested}) : @{[]},
			     exists $dep->{promote} ? (promote => $dep->{promote}) : @{[]},
			     exists $dep->{psel} ? (psel => $dep->{psel}) : @{[]},
			   };
	    }
	}
    }

    if (defined $dep->{from}) {
	if ($options{nodeps}) {
	    #- try to keep unsatisfied dependencies in requested.
	    if ($dep->{required} && exists $state->{selected}{$dep->{from}->id}) {
		push @{$state->{selected}{$dep->{from}->id}{unsatisfied}}, $dep->{required};
	    }
	} else {
	    #- at this point, dep cannot be resolved, this means we need to disable
	    #- all selection tree, re-enabling removed and obsoleted packages as well.
	    unless (exists $state->{rejected}{$dep->{from}->fullname}) {
		#- package is not currently rejected, compute the closure now.
		my @l = disable_selected_and_unrequested_dependencies($urpm, $db, $state, $dep->{from});
		foreach (@l) {
		    #- disable all these packages in order to avoid selecting them again.
		    _set_rejected_from($state, $_, $dep->{from}); 
		}
	    }
	    #- the package is already rejected, we assume we can add another reason here!
	    $urpm->{debug_URPM}("adding a reason to already rejected package " . $dep->{from}->fullname . ": unsatisfied " . $dep->{required}) if $urpm->{debug_URPM};
	    
	    _add_rejected_backtrack($state, $dep->{from}, { unsatisfied => [ $dep->{required} ] });
	}
    }

    if (defined $dep->{psel}) {
	if ($options{keep}) {
	    backtrack_selected_psel_keep($urpm, $db, $state, $dep->{psel}, $dep->{keep});

	    #- the package is already rejected, we assume we can add another reason here!
	    defined $dep->{promote} and _add_rejected_backtrack($state, $dep->{psel}, { promote => [ $dep->{promote} ] });
	} else {
	    #- the backtrack need to examine diff_provides promotion on $n.
	    with_db_unsatisfied_requires($urpm, $db, $state, $dep->{promote}, sub {
				      my ($p, @unsatisfied) = @_;
				      my %diff_provides_h;
				      set_rejected_and_compute_diff_provides($urpm, $state, \%diff_provides_h, {
							      rejected_pkg => $p, removed => 1,
							      from => $dep->{psel},
							      why => { unsatisfied => \@unsatisfied }
							  });
				      push @$diff_provides, map { +{ name => $_, pkg => $dep->{psel} } } keys %diff_provides_h;
			      });
	    with_state_unsatisfied_requires($urpm, $db, $state, $dep->{promote}, sub {
				      my ($p) = @_;
				      _set_rejected_from($state, $p, $dep->{psel});
				      disable_selected_and_unrequested_dependencies($urpm, $db, $state, $p);
			      });
	}
    }

    #- some packages may have been removed because of selection of this one.
    #- the rejected flags should have been cleaned by disable_selected above.
}

#- side-effects:
#-   + those of _set_rejected_from ($state->{rejected})
#-   + those of _add_rejected_backtrack ($state->{rejected})
#-   + those of disable_selected_and_unrequested_dependencies ($state->{selected}, $state->{whatrequires}, flag_requested, flag_required)
sub backtrack_selected_psel_keep {
    my ($urpm, $db, $state, $psel, $keep) = @_;

    #- we shouldn't try to remove packages, so psel which leads to this need to be unselected.
    unless (exists $state->{rejected}{$psel->fullname}) {
	#- package is not currently rejected, compute the closure now.
	my @l = disable_selected_and_unrequested_dependencies($urpm, $db, $state, $psel);
	foreach (@l) {
	    #- disable all these packages in order to avoid selecting them again.
	    _set_rejected_from($state, $_, $psel);
	}
    }
    #- to simplify, a reference to list or standalone elements may be set in keep.
    $keep and _add_rejected_backtrack($state, $psel, { keep => $keep });
}

#- side-effects: $state->{rejected}
sub _remove_all_rejected_from {
    my ($state, $from_fullname) = @_;

    grep {
	_remove_rejected_from($state, $_, $from_fullname);
    } keys %{$state->{rejected}};
}

#- side-effects: $state->{rejected}
sub _remove_rejected_from {
    my ($state, $fullname, $from_fullname) = @_;

    my $rv = $state->{rejected}{$fullname} or return;

    foreach (qw(removed obsoleted)) {
	if (exists $rv->{$_} && exists $rv->{$_}{$from_fullname}) {
	    delete $rv->{$_}{$from_fullname};
	    delete $rv->{$_} if !%{$rv->{$_}};
	}
    }

    exists $rv->{closure}{$from_fullname} or return;
    delete $rv->{closure}{$from_fullname};
    if (%{$rv->{closure}}) {
	0;
    } else {
	delete $state->{rejected}{$fullname};
	1;
    }
}

#- side-effects: $state->{rejected}
sub _add_rejected_backtrack {
    my ($state, $pkg, $backtrack) = @_;

    my $bt = $state->{rejected}{$pkg->fullname}{backtrack} ||= {};

    foreach (keys %$backtrack) {
	push @{$bt->{$_}}, @{$backtrack->{$_}};
    }
}

#- useful to reject packages in advance
#- eg when selecting "a" which conflict with "b", ensure we won't select "b"
#- but it's somewhat dangerous because it's sometimes called on installed packages,
#- and in that case, a real resolve_rejected_ must be done
#- (that's why set_rejected ignores the effect of _set_rejected_from)
#-
#- side-effects: $state->{rejected}
sub _set_rejected_from {
    my ($state, $pkg, $from_pkg) = @_;

    $pkg->fullname ne $from_pkg->fullname or return;

    $state->{rejected}{$pkg->fullname}{closure}{$from_pkg->fullname}{avoid} ||= undef;
}

#- side-effects: $state->{rejected}
sub _set_rejected_old_package {
    my ($state, $pkg, $new_pkg) = @_;

    if ($pkg->fullname eq $new_pkg->fullname) {
	$state->{rejected_already_installed}{$pkg->id} = $pkg;
    } else {
	push @{$state->{rejected}{$pkg->fullname}{backtrack}{keep}}, scalar $new_pkg->fullname;
    }
}

=item set_rejected($urpm, $state, $rdep)

Keep track of what causes closure.
Set removed and obsoleted level.

=cut

#- side-effects: $state->{rejected}
sub set_rejected {
    my ($urpm, $state, $rdep) = @_;

    my $fullname = $rdep->{rejected_pkg}->fullname;
    my $rv = $state->{rejected}{$fullname} ||= {};

    my $newly_rejected = !exists $rv->{size};

    if ($newly_rejected) {
	$urpm->{debug_URPM}("set_rejected: $fullname") if $urpm->{debug_URPM};
	#- keep track of size of package which are finally removed.
	$rv->{size} = $rdep->{rejected_pkg}->size;
    }

    #- keep track of what causes closure.
    if ($rdep->{from}) {
	my $closure = $rv->{closure}{scalar $rdep->{from}->fullname} ||= {};
	if (my $l = delete $rdep->{why}{unsatisfied}) {
	    my $unsatisfied = $closure->{unsatisfied} ||= [];
	    @$unsatisfied = uniq(@$unsatisfied, @$l);
	}
	$closure->{$_} = $rdep->{why}{$_} foreach keys %{$rdep->{why}};
    }

    #- set removed and obsoleted level.
    foreach (qw(removed obsoleted)) {
	if ($rdep->{$_}) {
	    if ($rdep->{from}) {
		$rv->{$_}{scalar $rdep->{from}->fullname} = undef;
	    } else {
		$rv->{$_}{asked} = undef;
	    }
	}
    }

    $newly_rejected;
}

#- side-effects:
#-   + those of set_rejected ($state->{rejected})
#-   + those of _compute_diff_provides_of_removed_pkg ($diff_provides_h)
sub set_rejected_and_compute_diff_provides {
    my ($urpm, $state, $diff_provides_h, $rdep) = @_;

    my $newly_rejected = set_rejected($urpm, $state, $rdep);

    #- no need to compute diff_provides if package was already rejected
    $newly_rejected or return;

    _compute_diff_provides_of_removed_pkg($urpm, $state, $diff_provides_h, $rdep->{rejected_pkg});
}

=item resolve_rejected($urpm, $db, $state, $pkg, %rdep)

Close rejected (as urpme previously) for package to be removable without error.

=cut

#- see resolve_rejected_ below
sub resolve_rejected {
    my ($urpm, $db, $state, $pkg, %rdep) = @_;
    $rdep{rejected_pkg} = $pkg;
    resolve_rejected_($urpm, $db, $state, $rdep{unsatisfied}, \%rdep);
}

#- close rejected (as urpme previously) for package to be removable without error.
#-
#- side-effects: $properties
#-   + those of set_rejected ($state->{rejected})
sub resolve_rejected_ {
    my ($urpm, $db, $state, $properties, $rdep) = @_;

    $urpm->{debug_URPM}("resolve_rejected: " . $rdep->{rejected_pkg}->fullname) if $urpm->{debug_URPM};

    #- check if the package has already been asked to be rejected (removed or obsoleted).
    #- this means only add the new reason and return.
    my $newly_rejected = set_rejected($urpm, $state, $rdep);

    $newly_rejected or return;

	my @pkgs_todo = $rdep->{rejected_pkg};

	while (my $cp = shift @pkgs_todo) {
	    #- close what requires this property, but check with selected package requiring old properties.
	    foreach my $n ($cp->provides_nosense) {
		    foreach my $pkg (whatrequires($urpm, $state, $n)) {
			if (my @l = unsatisfied_requires($urpm, $db, $state, $pkg, name => $n)) {
			    #- a selected package requires something that is no more available
			    #- and should be tried to be re-selected if possible.
			    if ($properties) {
				push @$properties, map { 
				    { required => $_, rejected => scalar $pkg->fullname }; # rejected is only there for debugging purpose (??)
				} @l;
			    }
			}
		    }
		    with_db_unsatisfied_requires($urpm, $db, $state, $n, sub {
			    my ($p, @unsatisfied) = @_;

			    my $newly_rejected = set_rejected($urpm, $state, {
				rejected_pkg => $p,
				from => $rdep->{rejected_pkg}, 
				why => { unsatisfied => \@unsatisfied },
				obsoleted => $rdep->{obsoleted},
				removed => $rdep->{removed},
			    });				

			    #- continue the closure unless already examined.
			    $newly_rejected or return;

			    $p->pack_header; #- need to pack else package is no longer visible...
			    push @pkgs_todo, $p;
		    });
	    }
	}
}

=item resolve_requested($urpm, $db, $state, $requested, %options)

Resolve dependencies of requested packages; keep resolution state to
speed up process.

A requested package is marked to be installed; once done, an upgrade flag or
an installed flag is set according to the needs of the installation of this
package.

Other required packages will have a required flag set along with an upgrade
flag or an installed flag.

Base flag should always be "installed" or "upgraded".

The following options are recognized :

=over

=item callback_choices : subroutine to be called to ask the user to choose
     between several possible packages. Returns an array of URPM::Package
     objects, or an empty list eventually.

=item keep :

=item nodeps :

=item no_recommends: ignore recommends tags

=back

It actually calls resolve_requested__no_recommends() and resolve_requested_recommends().

=cut

sub resolve_requested {
    my ($urpm, $db, $state, $requested, %options) = @_;

    my @selected = resolve_requested__no_recommends($urpm, $db, $state, $requested, %options);

    if (!$options{no_recommends}) {
        @selected = resolve_requested_recommends($urpm, $db, $state, \@selected, %options);
    }
    @selected;
}

=item resolve_requested_recommends($urpm, $db, $state, $selected, %options)

Select newly recommended package is installed as if (hard) required.

=cut

sub resolve_requested_suggests { goto \&resolve_requested_recommends } #COMPAT
sub resolve_requested_recommends {
    my ($urpm, $db, $state, $selected, %options) = @_;
	my @todo = @$selected;
	while (@todo) {
	    my $pkg = shift @todo;
	    my %recommends = map { $_ => 1 } $pkg->recommends_nosense or next;

	    #- do not install a package that has already been recommended
	    $db->traverse_tag_find('name', $pkg->name, sub {
		my ($p) = @_;
		delete $recommends{$_} foreach $p->recommends_nosense;
	    });

	    # workaround: if you do "urpmi virtual_pkg" and one virtual_pkg is already installed,
	    # it will ask anyway for the other choices
	    foreach my $recommend (keys %recommends) {
		$db->traverse_tag_find('whatprovides', $recommend, sub {
		    delete $recommends{$recommend};
		});
	    }

	    %recommends or next;

	    $urpm->{debug_URPM}("requested " . join(', ', keys %recommends) . " recommended by " . $pkg->fullname) if $urpm->{debug_URPM};
	    
	    my %new_requested = map { $_ => undef } keys %recommends;
	    my @new_selected = resolve_requested__no_recommends_($urpm, $db, $state, \%new_requested, %options);
	    $state->{selected}{$_->id}{recommended} = 1 foreach @new_selected;
	    push @$selected, @new_selected;
	    push @todo, @new_selected;
	}

    @$selected;
}

=item resolve_requested__no_recommends($urpm, $db, $state, $requested, %options)

Like resolve_requested() but doesn't handle recommends

=cut

# see resolve_requested above for information about usage (modulo 'no_recommends' option)
#- side-effects: flag_requested
#-   + those of resolve_requested__no_recommends_
sub resolve_requested__no_suggests { goto \&resolve_requested__no_recommends } #COMPAT
sub resolve_requested__no_recommends {
    my ($urpm, $db, $state, $requested, %options) = @_;

    foreach (keys %$requested) {
	#- keep track of requested packages by propagating the flag.
	foreach (find_candidate_packages($urpm, $_)) {
	    $_->set_flag_requested;
	}
    }

    resolve_requested__no_recommends_($urpm, $db, $state, $requested, %options);
}

# same as resolve_requested__no_recommends, but do not modify requested_flag
#-
#- side-effects: $state->{selected}, flag_required, flag_installed, flag_upgrade
#-   + those of backtrack_selected     (flag_requested, $state->{rejected}, $state->{whatrequires}, $state->{backtrack})
#-   + those of _unselect_package_deprecated_by (flag_requested, $state->{rejected}, $state->{whatrequires}, $state->{oldpackage}, $state->{unselected_uninstalled})
#-   + those of _handle_conflicts      ($state->{rejected})
#-   + those of _handle_conflict ($state->{rejected})
#-   + those of backtrack_selected_psel_keep (flag_requested, $state->{whatrequires})
#-   + those of _handle_diff_provides  (flag_requested, $state->{rejected}, $state->{whatrequires})
#-   + those of _no_more_recent_installed_and_providing ($state->{rejected})
sub resolve_requested__no_suggests_ { goto \&resolve_requested__no_recommends_ } #COMPAT
sub resolve_requested__no_recommends_ {
    my ($urpm, $db, $state, $requested, %options) = @_;

    my @properties = map {
	{ required => $_, requested => $requested->{$_} };
    } keys %$requested;

    my (@diff_provides, @selected, @choices);

    #- for each dep property evaluated, examine which package will be obsoleted on $db,
    #- then examine provides that will be removed (which need to be satisfied by another
    #- package present or by a new package to upgrade), then requires not satisfied and
    #- finally conflicts that will force a new upgrade or a remove.
    my $count = 1;
    do {
	while (my $dep = shift @properties) {
	    #- we need to avoid selecting packages if the source has been disabled.
	    if (exists $dep->{from} && !$urpm->{keep_unrequested_dependencies}) {
		exists $state->{selected}{$dep->{from}->id} or next;
	    }

	    my $pkg = _choose_required($urpm, $db, $state, $dep, \@properties, \@choices, \@diff_provides, %options) or next;

	    !$pkg || exists $state->{selected}{$pkg->id} and next;

	    if ($pkg->arch eq 'src') {
		$pkg->set_flag_upgrade;
	    } else {
		_set_flag_installed_and_upgrade_if_no_newer($db, $pkg);

		if ($pkg->flag_installed && !$pkg->flag_upgrade && !$urpm->{options}{downgrade} && !$urpm->{options}{reinstall}) {
		    _no_more_recent_installed_and_providing($urpm, $db, $state, $pkg, $dep->{required}) or next;
		}
	    }

	    _handle_conflicts_with_selected($urpm, $db, $state, $pkg, $dep, \@diff_provides, %options) or next;

	    $urpm->{debug_URPM}("selecting " . $pkg->fullname) if $urpm->{debug_URPM};

	    #- keep in mind the package has be selected, remove the entry in requested input hash,
	    #- this means required dependencies have undef value in selected hash.
	    #- requested flag is set only for requested package where value is not false.
	    push @selected, $pkg;
	    $state->{selected}{$pkg->id} = { exists $dep->{requested} ? (requested => $dep->{requested}) : @{[]},
					     exists $dep->{from} ? (from => $dep->{from}) : @{[]},
					     exists $dep->{promote} ? (promote => $dep->{promote}) : @{[]},
					     exists $dep->{psel} ? (psel => $dep->{psel}) : @{[]},
					     $pkg->flag_disable_obsolete ? (install => 1) : @{[]},
					   };

	    $pkg->set_flag_required;

	    #- check if the package is not already installed before trying to use it, compute
	    #- obsoleted packages too. This is valid only for non source packages.
	    my %diff_provides_h;
	    if ($pkg->arch ne 'src' && !$pkg->flag_disable_obsolete) {
		_unselect_package_deprecated_by($urpm, $db, $state, \%diff_provides_h, $pkg);
	    }

	    #- all requires should be satisfied according to selected package, or installed packages.
	    if (my @l = unsatisfied_requires($urpm, $db, $state, $pkg)) {
		$urpm->{debug_URPM}("requiring " . join(',', sort @l) . " for " . $pkg->fullname) if $urpm->{debug_URPM};
		unshift @properties, map { +{ required => $_, from => $pkg,
					  exists $dep->{promote} ? (promote => $dep->{promote}) : @{[]},
					  exists $dep->{psel} ? (psel => $dep->{psel}) : @{[]},
					} } @l;
	    }

	    #- keep in mind what is requiring each item (for unselect to work).
	    foreach ($pkg->requires_nosense) {
		$state->{whatrequires}{$_}{$pkg->id} = undef;
	    }

	    #- cancel flag if this package should be cancelled but too late (typically keep options).
	    my @keep;

	    _handle_conflicts($urpm, $db, $state, $pkg, \@properties, \%diff_provides_h, $options{keep} && \@keep);

	    #- examine if an existing package does not conflict with this one.
	    $db->traverse_tag('whatconflicts', [ $pkg->provides_nosense ], sub {
		@keep and return;
		my ($p) = @_;
		foreach my $property ($p->conflicts) {
		    if ($pkg->provides_overlap($property)) {
			_handle_conflict($urpm, $state, $pkg, $p, $property, $property, \@properties, \%diff_provides_h, $options{keep} && \@keep);
		    }
		}
	    });

	    #- keep existing package and therefore cancel current one.
	    if (@keep) {
		backtrack_selected_psel_keep($urpm, $db, $state, $pkg, \@keep);
	    }

	    push @diff_provides, map { +{ name => $_, pkg => $pkg } } keys %diff_provides_h;
	}
	if (my $diff = shift @diff_provides) {
	    _handle_diff_provides($urpm, $db, $state, \@properties, \@diff_provides, $diff->{name}, $diff->{pkg}, %options);
	} elsif (my $dep = shift @choices) {
	    push @properties, $dep;
	}

	# safety:
	if ($count++ > 50000) {
	    die("detecting looping forever while trying to resolve dependencies.\n"
		. "Aborting... Try again with '-vv --debug' options");
	}
    } while (@diff_provides || @properties || @choices);

    #- return what has been selected by this call (not all selected hash which may be not empty
    #- previously. avoid returning rejected packages which weren't selectable.
    grep { exists $state->{selected}{$_->id} } @selected;
}

#- pre-disables packages that $pkg has conflict entries for, and
#- unselects $pkg if such a package is already selected
#- side-effects:
#-   + those of _set_rejected_from ($state->{rejected})
#-   + those of _remove_all_rejected_from ($state->{rejected})
#-   + those of backtrack_selected ($state->{backtrack}, $state->{rejected}, $state->{selected}, $state->{whatrequires}, flag_requested, flag_required)
sub _handle_conflicts_with_selected {
    my ($urpm, $db, $state, $pkg, $dep, $diff_provides, %options) = @_;
    foreach ($pkg->conflicts) {
	if (my $n = property2name($_)) {
	    foreach my $p ($urpm->packages_providing($n)) {
		$pkg == $p and next;
		$p->provides_overlap($_) or next;
		if (exists $state->{selected}{$p->id}) {
		    $urpm->{debug_URPM}($pkg->fullname . " conflicts with already selected package " . $p->fullname) if $urpm->{debug_URPM};
		    _remove_all_rejected_from($state, $pkg);
		    _set_rejected_from($state, $pkg, $p);
		    backtrack_selected($urpm, $db, $state, $dep, $diff_provides, %options);
		    return;
		}
		_set_rejected_from($state, $p, $pkg);
	    }
	}
    }
    1;
}

#- side-effects:
#-   + those of set_rejected_and_compute_diff_provides ($state->{rejected}, $diff_provides_h)
#-   + those of _handle_conflict ($properties, $keep, $diff_provides_h)
sub _handle_conflicts {
    my ($urpm, $db, $state, $pkg, $properties, $diff_provides_h, $keep) = @_;

    #- examine conflicts, an existing package conflicting with this selection should
    #- be upgraded to a new version which will be safe, else it should be removed.
    foreach ($pkg->conflicts) {
	$keep && @$keep and last;
	if (my ($file) = m!^(/[^\s\[]*)!) {
	    $db->traverse_tag('path', [ $file ], sub {
		$keep && @$keep and return;
		my ($p) = @_;
		if ($keep) {
		    push @$keep, scalar $p->fullname;
		} else {
		    #- all these packages should be removed.
		    set_rejected_and_compute_diff_provides($urpm, $state, $diff_provides_h, {
				      rejected_pkg => $p, removed => 1,
				      from => $pkg,
				      why => { conflicts => $file },
				  });
		}
	    });
	} elsif (my $name = property2name($_)) {
	    my $property = $_;
	    $db->traverse_tag('whatprovides', [ $name ], sub {
		$keep && @$keep and return;
		my ($p) = @_;
		if ($p->provides_overlap($property)) {
		    _handle_conflict($urpm, $state, $pkg, $p, $property, scalar($pkg->fullname), $properties, $diff_provides_h, $keep);
		}
	    });
	}
    }
}

#- side-effects:
#-   + those of _unselect_package_deprecated_by_property (flag_requested, flag_required, $state->{selected}, $state->{rejected}, $state->{whatrequires}, $state->{oldpackage}, $state->{unselected_uninstalled})
sub _unselect_package_deprecated_by {
    my ($urpm, $db, $state, $diff_provides_h, $pkg) = @_;

    _unselect_package_deprecated_by_property($urpm, $db, $state, $pkg, $diff_provides_h, $pkg->name, '<', $pkg->epoch . ":" . $pkg->version . "-" . $pkg->release);

    foreach ($pkg->obsoletes) {
	my ($n, $o, $v) = property2name_op_version($_) or next;

	#- ignore if this package obsoletes itself
	#- otherwise this can cause havoc if: to_install=v3, installed=v2, v3 obsoletes < v2
	if ($n ne $pkg->name) {
	    _unselect_package_deprecated_by_property($urpm, $db, $state, $pkg, $diff_provides_h, $n, $o, $v);
	}
    }
}

#- side-effects: $state->{oldpackage}, $state->{unselected_uninstalled}
#-   + those of set_rejected ($state->{rejected})
#-   + those of _set_rejected_from ($state->{rejected})
#-   + those of disable_selected (flag_requested, flag_required, $state->{selected}, $state->{rejected}, $state->{whatrequires})
sub _unselect_package_deprecated_by_property {
    my ($urpm, $db, $state, $pkg, $diff_provides_h, $n, $o, $v) = @_;

    #- populate avoided entries according to what is selected.
    foreach my $p ($urpm->packages_providing($n)) {
	if ($p->name eq $pkg->name) {
	    #- all packages with the same name should now be avoided except when chosen.
	} else {
	    #- in case of obsoletes, keep track of what should be avoided
	    #- but only if package name equals the obsolete name.
	    $p->name eq $n && (!$o || eval($p->compare($v) . $o . 0)) or next;
	}
	#- these packages are not yet selected, if they happen to be selected,
	#- they must first be unselected.
	_set_rejected_from($state, $p, $pkg);
    }
	
    #- examine rpm db too (but only according to package names as a fix in rpm itself)
    $db->traverse_tag('name', [ $n ], sub {
	my ($p) = @_;

	#- without an operator, anything (with the same name) is matched.
	#- with an operator, check package EVR with the obsoletes EVR.
	#- $satisfied is true if installed package has version newer or equal.
	my $comparison = $p->compare($v);
	my $satisfied = !$o || eval($comparison . $o . 0);

	my $obsoleted;
	if ($p->name eq $pkg->name) {
	    #- all packages older than the current one are obsoleted,
	    #- the others are simply removed (the result is the same).
	    if ($o && $comparison > 0) {
		#- installed package is newer
		#- remove this package from the list of packages to install,
		#- unless urpmi was invoked with --allow-force 
		#- (in which case rpm could be invoked with --oldpackage)
		if (!$urpm->{options}{'allow-force'} && !$urpm->{options}{downgrade} && !$urpm->{options}{reinstall}) {
		    #- since the originally requested packages (or other
		    #- non-installed ones) could be unselected by the following
		    #- operation, remember them, to warn the user
		    $state->{unselected_uninstalled} = [ grep {
			!$_->flag_installed;
		    } disable_selected($urpm, $db, $state, $pkg) ];

		    return;
		}
	    } elsif ($satisfied) {
		$obsoleted = 1;
	    } elsif ($urpm->{options}{reinstall}) {
		# So that we do not ask for "The following package has to be removed for others to be upgraded:
		# foo-V-R (in order to install foo-V-R) (y/N)"
		return;
	    }
	} elsif ($satisfied) {
	    $obsoleted = 1;
	} else {
	    return;
	}

	set_rejected_and_compute_diff_provides($urpm, $state, $diff_provides_h, { 
	    rejected_pkg => $p,
	    obsoleted => $obsoleted, removed => !$obsoleted,
	    from => $pkg, why => $obsoleted ? undef : { old_requested => 1 },
	});
	$obsoleted or ++$state->{oldpackage};
    });
}

#- side-effects: $diff_provides
sub _compute_diff_provides_of_removed_pkg {
    my ($urpm, $state, $diff_provides_h, $p) = @_;

	foreach ($p->provides) {
	    #- check differential provides between obsoleted package and newer one.
	    my ($pn, $ps) = property2name_range($_) or next;

	    my $not_provided = 1;
	    foreach (grep { exists $state->{selected}{$_} }
		       keys %{$urpm->{provides}{$pn} || {}}) {
		my $pp = $urpm->{depslist}[$_];
		foreach ($pp->provides) {
		    my ($ppn, $pps) = property2name_range($_) or next;
		    $ppn eq $pn && $pps eq $ps
		      and $not_provided = 0;
		}
	    }
	    $not_provided and $diff_provides_h->{$pn} = undef;
	}
}

#- side-effects: none
sub _find_packages_obsoleting {
    my ($urpm, $state, $p) = @_;

    grep {
	$_ &&
	!$_->flag_skip
	  && $_->is_arch_compat
	    && !exists $state->{rejected}{$_->fullname}
	      && $_->obsoletes_overlap($p->name . " == " . $p->epoch . ":" . $p->version . "-" . $p->release)
		&& $_->fullname ne $p->fullname
		  && (!strict_arch($urpm) || strict_arch_check($p, $_));
    } $urpm->packages_obsoleting($p->name);
}

#- side-effects: $properties
#-   + those of backtrack_selected_psel_keep ($state->{rejected}, $state->{selected}, $state->{whatrequires}, flag_requested, flag_required)
#-   + those of resolve_rejected_ ($state->{rejected}, $properties)
#-   + those of disable_selected_and_unrequested_dependencies (flag_requested, flag_required, $state->{selected}, $state->{whatrequires}, $state->{rejected})
#-   + those of _set_rejected_from ($state->{rejected})
sub _handle_diff_provides {
    my ($urpm, $db, $state, $properties, $diff_provides, $n, $pkg, %options) = @_;

    with_any_unsatisfied_requires($urpm, $db, $state, $n, sub {
	my ($p, $from_state, @unsatisfied) = @_;

	#- try if upgrading the package will be satisfying all the requires...
	#- there is no need to avoid promoting epoch as the package examined is not
	#- already installed.
	my @packages = find_candidate_packages($urpm, $p->name, $state->{rejected});
	@packages = 
	  grep { ($_->name eq $p->name ? $p->compare_pkg($_) < 0 :
		    $_->obsoletes_overlap($p->name . " == " . $p->epoch . ":" . $p->version . "-" . $p->release))
		   && (!strict_arch($urpm) || strict_arch_check($p, $_));
	     } @packages;
	#- don't promote an obsolete package (mga#23223)
	@packages = grep { _find_packages_obsoleting($urpm, $state, $_) == 0 } @packages;

	if (!@packages) {
	    @packages = _find_packages_obsoleting($urpm, $state, $p);
	}

	if (@packages) {
	    my $best = join('|', sort { $a <=> $b } map { $_->id } @packages);
	    my @ids = split('\|', $best);
	    $urpm->{debug_URPM}("promoting " . join(' ', _ids_to_fullnames($urpm, @ids)) . " because of conflict above") if $urpm->{debug_URPM};
	    push @$properties, { required => $best, promote => $n, psel => $pkg };
	} else {
	    #- no package have been found, we may need to remove the package examined unless
	    #- there exists enough packages that provided the unsatisfied requires.
	    my @best;
	    foreach (@unsatisfied) {
		my @packages = find_candidate_packages($urpm, $_, $state->{rejected});
		if (@packages = grep { $_->fullname ne $p->fullname } @packages) {
		    push @best, join('|', map { $_->id } @packages);
		}
	    }

	    if (@best == @unsatisfied) {
		$urpm->{debug_URPM}("promoting " . join(' ', _ids_to_fullnames($urpm, map { split('\|', $_) } @best)) . " because of conflict above") if $urpm->{debug_URPM};
		push @$properties, map { +{ required => $_, promote => $n, psel => $pkg } } @best;
	    } else {
		if ($from_state) {
		    disable_selected_and_unrequested_dependencies($urpm, $db, $state, $p);
		    _set_rejected_from($state, $p, $pkg);
		} elsif ($options{keep}) {
		    backtrack_selected_psel_keep($urpm, $db, $state, $pkg, [ scalar $p->fullname ]);
		} else {
		    my %diff_provides_h;
		    set_rejected_and_compute_diff_provides($urpm, $state, \%diff_provides_h, {
				      rejected_pkg => $p, removed => 1,
				      from => $pkg,
				      why => { unsatisfied => \@unsatisfied },
				  });
		    push @$diff_provides, map { +{ name => $_, pkg => $pkg } } keys %diff_provides_h;
		}
	    }
	}
    });
}

#- side-effects: $properties, $keep
#-   + those of set_rejected_and_compute_diff_provides ($state->{rejected}, $diff_provides_h)
sub _handle_conflict {
    my ($urpm, $state, $pkg, $p, $property, $reason, $properties, $diff_provides_h, $keep) = @_;
    
    $urpm->{debug_URPM}("installed package " . $p->fullname . " is conflicting with " . $pkg->fullname . " (Conflicts: $property)") if $urpm->{debug_URPM};

    #- the existing package will conflict with the selection; check
    #- whether a newer version will be ok, else ask to remove the old.
    my $need_deps = $p->name . " > " . ($p->epoch ? $p->epoch . ":" : "") .
      $p->version . "-" . $p->release;
    my @packages = grep { $_->name eq $p->name } find_candidate_packages($urpm, $need_deps, $state->{rejected});
    @packages = grep { ! $_->provides_overlap($property) } @packages;
    #- don't promote an obsolete package (mga#23223)
    @packages = grep { _find_packages_obsoleting($urpm, $state, $_) == 0 } @packages;

    if (!@packages) {
	@packages = _find_packages_obsoleting($urpm, $state, $p);
	@packages = grep { ! $_->provides_overlap($property) } @packages;
    }

    if (@packages) {
	my $best = join('|', sort { $a <=> $b } map { $_->id } @packages);
	$urpm->{debug_URPM}("promoting " . join('|', map { scalar $_->fullname } @packages) . " because of conflict above") if $urpm->{debug_URPM};
	unshift @$properties, { required => $best, promote_conflicts => $reason };
    } else {
	if ($keep) {
	    push @$keep, scalar $p->fullname;
	} else {
	    #- no package has been found, we need to remove the package examined.
	    set_rejected_and_compute_diff_provides($urpm, $state, $diff_provides_h, {
		rejected_pkg => $p, removed => 1,
		from => $pkg,
		why => { conflicts => $reason },
	    });
	}
    }
}

=item disable_selected ($urpm, $db, $state, @pkgs_todo)

Do the opposite of the resolve_requested: unselect a package and
extend to any package not requested that is no longer needed by any
other package.

Return the packages that have been deselected.

=cut

#- side-effects: flag_requested, flag_required, $state->{selected}, $state->{whatrequires}
#-   + those of _remove_all_rejected_from ($state->{rejected})
sub disable_selected {
    my ($urpm, $db, $state, @pkgs_todo) = @_;
    my @unselected;

    #- iterate over package needing unrequested one.
    while (my $pkg = shift @pkgs_todo) {
	exists $state->{selected}{$pkg->id} or next;

	#- keep a trace of what is deselected.
	push @unselected, $pkg;

	#- perform a closure on rejected packages (removed, obsoleted or avoided).
	my @rejected_todo = scalar $pkg->fullname;
	while (my $fullname = shift @rejected_todo) {
	    push @rejected_todo, _remove_all_rejected_from($state, $fullname);
	}

	#- the package being examined has to be unselected.
	$urpm->{debug_URPM}("unselecting " . $pkg->fullname) if $urpm->{debug_URPM};
	$pkg->set_flag_requested(0);
	$pkg->set_flag_required(0);
	delete $state->{selected}{$pkg->id};

	#- determine package that requires properties no longer available, so that they need to be
	#- unselected too.
	foreach my $n ($pkg->provides_nosense) {
	    foreach my $p (whatrequires($urpm, $state, $n)) {
		exists $state->{selected}{$p->id} or next;
		if (unsatisfied_requires($urpm, $db, $state, $p, name => $n)) {
		    #- this package has broken dependencies and is selected.
		    push @pkgs_todo, $p;
		}
	    }
	}

	#- clean whatrequires hash.
	foreach ($pkg->requires_nosense) {
	    delete $state->{whatrequires}{$_}{$pkg->id};
	    %{$state->{whatrequires}{$_}} or delete $state->{whatrequires}{$_};
	}
    }

    #- return all unselected packages.
    @unselected;
}

=item disable_selected_and_unrequested_dependencies($urpm, $db, $state, @pkgs_todo)

Determine dependencies that can safely been removed and are not requested.
Return the packages that have been deselected.

=cut

#- side-effects:
#-   + those of disable_selected (flag_requested, flag_required, $state->{selected}, $state->{whatrequires}, $state->{rejected})
sub disable_selected_and_unrequested_dependencies {
    my ($urpm, $db, $state, @pkgs_todo) = @_;
    my @all_unselected;

    #- disable selected packages, then extend unselection to all required packages
    #- no longer needed and not requested.
    while (my @unselected = disable_selected($urpm, $db, $state, @pkgs_todo)) {
	my %required;

	#- keep in the packages that had to be unselected.
	@all_unselected or push @all_unselected, @unselected;

	last if $urpm->{keep_unrequested_dependencies};

	#- search for unrequested required packages.
	foreach (@unselected) {
	    foreach ($_->requires_nosense) {
		foreach my $pkg (grep { $_ } $urpm->packages_providing($_)) {
		    $state->{selected}{$pkg->id} or next;
		    $state->{selected}{$pkg->id}{psel} && $state->{selected}{$state->{selected}{$pkg->id}{psel}->id} and next;
		    $pkg->flag_requested and next;
		    $required{$pkg->id} = undef;
		}
	    }
	}

	#- check required packages are not needed by another selected package.
	foreach (keys %required) {
	    my $pkg = $urpm->{depslist}[$_] or next;
	    foreach ($pkg->provides_nosense) {
		foreach my $p_id (whatrequires_id($state, $_)) {
		    exists $required{$p_id} and next;
		    $state->{selected}{$p_id} and $required{$pkg->id} = 1;
		}
	    }
	}

	#- now required values still undefined indicates packages than can be removed.
	@pkgs_todo = map { $urpm->{depslist}[$_] } grep { !$required{$_} } keys %required;
    }

    @all_unselected;
}

=back

=head2 Dependancy related functions

=over 4

=item _dep_to_name($urpm, $dep)

Take a string of package ids (eg: "4897|4564|454") that represent packages providing some dependancy.
Return string of package names corresponding to package ids.
eg: "libgtk1-devel|libgtk2-devel|libgtk3-devel" for ids corresponding to "gtk-devel"

$dep is a hashref: { required => $ID, requested => $requested->{$ID} }
# CHECK IT REALLY IS AN ID HERE => WE SHOULD REALLY DOCUMENT $requested

=cut

#- side-effects: none
sub _dep_to_name {
    my ($urpm, $dep) = @_;
    join('|', map { _id_to_name($urpm, $_) } split('\|', $dep->{required}));
}

=item _id_to_name($urpm, $id_prop)

Returns package name corresponding to package ID (or ID if not numerical)

=cut

#- side-effects: none
sub _id_to_name {
    my ($urpm, $id_prop) = @_;
    if ($id_prop =~ /^\d+/) {
	my $pkg = $urpm->{depslist}[$id_prop];
	$pkg && $pkg->name;
    } else {
	$id_prop;
    }
}

=item _ids_to_names($urpm, @ids)

Return package names corresponding to package ids

=cut

#- side-effects: none
sub _ids_to_names {
    my $urpm = shift;

    map { $urpm->{depslist}[$_]->name } @_;
}

=item _ids_to_fullnames($urpm, @ids)

Return package fullnames corresponding to package ids.
identical to _ids_to_names() modulo short name vs full name

=cut

#- side-effects: none
sub _ids_to_fullnames {
    my ($urpm, @ids) = @_;

    map { scalar $urpm->{depslist}[$_]->fullname } @ids;
}

#- side-effects: flag_installed, flag_upgrade
sub _set_flag_installed_and_upgrade_if_no_newer {
    my ($db, $pkg) = @_;

    !$pkg->flag_upgrade && !$pkg->flag_installed or return;

    my $upgrade = 1;
    $db->traverse_tag('name', [ $pkg->name ], sub {
	my ($p) = @_;
	$pkg->set_flag_installed;
	$upgrade &&= $pkg->compare_pkg($p) > 0;
    });
    $pkg->set_flag_upgrade($upgrade);
}

#- side-effects:
#-   + those of _set_rejected_old_package ($state->{rejected})
sub _no_more_recent_installed_and_providing {
    my ($urpm, $db, $state, $pkg, $required) = @_;

    my $allow = 1;
    $db->traverse_tag('name', [ $pkg->name ], sub {
	my ($p) = @_;
	#- allow if a less recent package is installed,
	if ($allow && $pkg->compare_pkg($p) <= 0) {
	    if ($required =~ /^\d+/ || $p->provides_overlap($required)) {
		$urpm->{debug_URPM}("not selecting " . $pkg->fullname . " since the more recent " . $p->fullname . " is installed") if $urpm->{debug_URPM};
		_set_rejected_old_package($state, $pkg, $p);
		$allow = 0;
	    } else {
		$urpm->{debug_URPM}("the more recent " . $p->fullname . 
		  " is installed, but does not provide $required whereas " . 
		    $pkg->fullname . " does") if $urpm->{debug_URPM};
	    }
	}
    });
    $allow;
}

=back

=head2 Size related functions

=over 4

=item selected_size($urpm, $state)

Compute selected size by removing any removed or obsoleted package.
Returns total package size

=cut

#- side-effects: none
sub selected_size {
    my ($urpm, $state) = @_;
    my ($size) = _selected_size_filesize($urpm, $state, 0);
    $size;
}

=item selected_size_filesize($urpm, $state)

Compute selected size by removing any removed or obsoleted package.
Returns both total package size & total filesize.

=cut

#- side-effects: none
sub selected_size_filesize {
    my ($urpm, $state) = @_;
    _selected_size_filesize($urpm, $state, 1);
}

#- side-effects: none
sub _selected_size_filesize {
    my ($urpm, $state, $compute_filesize) = @_;
    my ($size, $filesize, $bad_filesize);

    foreach (keys %{$state->{selected} || {}}) {
	my $pkg = $urpm->{depslist}[$_];
	$size += $pkg->size;
	$compute_filesize or next;

	if (my $n = $pkg->filesize) {
	    $filesize += $n;
	} elsif (!$bad_filesize) {
	    $urpm->{debug} and $urpm->{debug}("no filesize for package " . $pkg->fullname);
	    $bad_filesize = 1;
	}
    }

    foreach (values %{$state->{rejected} || {}}) {
	$_->{removed} || $_->{obsoleted} or next;
	$size -= abs($_->{size});
    }

    foreach (@{$state->{orphans_to_remove} || []}) {
	$size -= $_->size;
    }

    $size, $bad_filesize ? 0 : $filesize;
}

=back

=head2 Other functions

=over 4

=cut

#- compute installed flags for all packages in depslist.
#-
#- side-effects: flag_upgrade, flag_installed
sub compute_installed_flags {
    my ($urpm, $db) = @_;

    #- first pass to initialize flags installed and upgrade for all packages.
    foreach (@{$urpm->{depslist}}) {
	$_->is_arch_compat or next;
	$_->flag_upgrade || $_->flag_installed or $_->set_flag_upgrade;
    }

    #- second pass to set installed flag and clean upgrade flag according to installed packages.
    $db->traverse(sub {
	my ($p) = @_;
	#- compute flags.
	foreach my $pkg ($urpm->packages_providing($p->name)) {
	    next if !defined $pkg;
	    $pkg->is_arch_compat && $pkg->name eq $p->name or next;
	    #- compute only installed and upgrade flags.
	    $pkg->set_flag_installed; #- there is at least one package installed (whatever its version).
	    $pkg->flag_upgrade and $pkg->set_flag_upgrade($pkg->compare_pkg($p) > 0);
	}
    });
}

#- side-effects: flag_skip, flag_disable_obsolete
sub compute_flag {
    my ($urpm, $pkg, %options) = @_;
    foreach (qw(skip disable_obsolete)) {
	if ($options{$_} && !$pkg->flag($_)) {
	    $pkg->set_flag($_, 1);
	    $options{callback} and $options{callback}->($urpm, $pkg, %options);
	}
    }
}

=item compute_flags($urpm, $val, %options)

Adds packages flags according to an array containing packages names.
$val is an array reference (as returned by get_packages_list) containing
package names, or a regular expression matching against the fullname, if
enclosed in slashes.
%options :

=over

=item callback : sub to be called for each package where the flag is set

=item skip : if true, set the 'skip' flag

=item disable_obsolete : if true, set the 'disable_obsolete' flag

=back

=cut

#- side-effects: 
#-   + those of compute_flag (flag_skip, flag_disable_obsolete)
sub compute_flags {
    my ($urpm, $val, %options) = @_;
    my @regex;

    #- unless a regular expression is given, search in provides
    foreach my $name (@$val) {
	if ($name =~ m,^/(.*)/$,) {
	    push @regex, $1;
	} else {
	    foreach my $pkg ($urpm->packages_providing($name)) {
		compute_flag($urpm, $pkg, %options);
	    }
	}
    }

    #- now search packages which fullname match given regexps
    if (@regex) {
	eval {
		my $large_re_s = join("|", map { "(?:$_)" } @regex);
		my $re = qr/$large_re_s/;

		foreach my $pkg (@{$urpm->{depslist}}) {
		    if ($pkg->fullname =~ $re) {
			compute_flag($urpm, $pkg, %options);
		    }
		}
	};
	$urpm->{error}("reg ex problem: " . $@) if $@;
    }
}

#- side-effects: none
sub _choose_best_pkg {
    my ($urpm, $pkg_installed, @pkgs) = @_;

    _choose_best_pkg_($urpm, $pkg_installed, grep { $_->compare_pkg($pkg_installed) > 0 } @pkgs);
}

#- side-effects: none
sub _choose_best_pkg_ {
    my ($urpm, $pkg_installed, @pkgs) = @_;

    my $best;
    foreach my $pkg (grep {
	!strict_arch($urpm) || strict_arch_check($pkg_installed, $_);
    } @pkgs) {
	if (!$best || ($pkg->compare_pkg($best) || $pkg->id < $best->id) > 0) {
	    $best = $pkg;
	}
    }
    $best;
}

#- side-effects: none
sub _choose_bests_obsolete {
    my ($urpm, $db, $pkg_installed, @pkgs) = @_;

    _set_flag_installed_and_upgrade_if_no_newer($db, $_) foreach @pkgs;

    my %by_name;
    push @{$by_name{$_->name}}, $_ foreach grep { $_->flag_upgrade } @pkgs;

    map { _choose_best_pkg_($urpm, $pkg_installed, @$_) } values %by_name;
}

=item request_packages_to_upgrade($urpm, $db, $state, $requested, %options)

Select packages to upgrade, according to package already registered.
By default, only takes best package and its obsoleted and compute
all installed or upgrade flag.
(used for --auto-select)

=cut

#- side-effects: $requisted, flag_installed, flag_upgrade
sub request_packages_to_upgrade {
    my ($urpm, $db, $state, $requested, %options) = @_;

    my %by_name;

    #- now we can examine all existing packages to find packages to upgrade.
    $db->traverse(sub {
	my ($pkg_installed) = @_;
	my $name = $pkg_installed->name;
	my $pkg;
	if (exists $by_name{$name}) {
	    if (my $p = $by_name{$name}) {
		#- here a pkg with the same name is installed twice
		if ($p->compare_pkg($pkg_installed) > 0) {
		    #- we selected $p, and it is still a valid choice
		    $pkg = $p;
		} else {
		    #- $p is no good since $pkg_installed is higher version,
		}
	    }
	} elsif ($pkg = _choose_best_pkg($urpm, $pkg_installed, $urpm->packages_by_name($name))) {
	    #- first try with package using the same name.
	    $pkg->set_flag_installed;
	    $pkg->set_flag_upgrade;
	}
	if (my @pkgs = _choose_bests_obsolete($urpm, $db, $pkg_installed, _find_packages_obsoleting($urpm, $state, $pkg_installed))) {
	    if (@pkgs == 1) {
		$pkg and $urpm->{debug_URPM}("auto-select: preferring " . $pkgs[0]->fullname . " obsoleting " .  $pkg_installed->fullname . " over " . $pkg->fullname) if $urpm->{debug_URPM};
		$pkg = $pkgs[0];
	    } elsif (@pkgs > 1) {
		$urpm->{debug_URPM}("auto-select: multiple packages (" . join(' ', sort(map { scalar $_->fullname } @pkgs)) . ") obsoleting " . $pkg_installed->fullname) if $urpm->{debug_URPM};
		$pkg = undef;
	    }
	}
	if ($pkg && $options{idlist} && !any { $pkg->id == $_ } @{$options{idlist}}) {
		$urpm->{debug_URPM}("not auto-selecting " . $pkg->fullname . "because it's not in search medias") if $urpm->{debug_URPM};
		$pkg = undef;
	} 

	$pkg and $urpm->{debug_URPM}("auto-select: adding " . $pkg->fullname . " replacing " .  $pkg_installed->fullname) if $urpm->{debug_URPM};
	    
	$by_name{$name} = $pkg;		    
    });

    foreach my $pkg (values %by_name) {
	$pkg or next;
	$pkg->set_flag_upgrade;
	$requested->{$pkg->id} = $options{requested};
    }

    $requested;
}

=back

=head2 Graph functions

=over 4

=cut

#- side-effects: none
sub _sort_by_dependencies_get_graph {
    my ($urpm, $state, $l) = @_;
    my %edges;
    foreach my $id (@$l) {
	my $pkg = $urpm->{depslist}[$id];
	my @provides = map { whatrequires_id($state, $_) } $pkg->provides_nosense;
	if (my $from = $state->{selected}{$id}{from}) {
	    unshift @provides, $from->id;
	}
	$edges{$id} = [ uniq(@provides) ];
    }
    \%edges;
}

#- side-effects: none
sub reverse_multi_hash {
    my ($h) = @_;
    my %r;
    my ($k, $v);
    while (($k, $v) = each %$h) {
	push @{$r{$_}}, $k foreach @$v;
    }
    \%r;
}

sub _merge_2_groups {
    my ($groups, $l1, $l2) = @_;
    my $l = [ @$l1, @$l2 ];
    $groups->{$_} = $l foreach @$l;
    $l;
}
sub _add_group {
    my ($groups, $group) = @_;

    my ($main, @other) = uniq(grep { $_ } map { $groups->{$_} } @$group);
    $main ||= [];
    if (@other) {
	$main = _merge_2_groups($groups, $main, $_) foreach @other;
    }
    foreach (grep { !$groups->{$_} } @$group) {
	$groups->{$_} ||= $main;
	push @$main, $_;
	my @l_ = uniq(@$main);
	@l_ == @$main or die '';
    }
    # warn "# groups: ", join(' ', map { join('+', @$_) } uniq(values %$groups)), "\n";
}

=item sort_graph($nodes, $edges)

Sort the graph

nb: this handles $nodes list not containing all $nodes that can be seen in $edges

=cut

#- side-effects: none
sub sort_graph {
    my ($nodes, $edges) = @_;

    #require Data::Dumper;
    #warn Data::Dumper::Dumper($nodes, $edges);

    my %nodes_h = map { $_ => 1 } @$nodes;
    my (%loops, %added, @sorted);

    my $recurse; $recurse = sub {
	my ($id, @ids) = @_;
#	warn "# recurse $id @ids\n";

	my $loop_ahead;
	foreach my $p_id (@{$edges->{$id}}) {
	    if ($p_id == $id) {
		# don't care
	    } elsif (exists $added{$p_id}) {
		# already done
	    } elsif (any { $_ == $p_id } @ids) {
		my $begin = 1;
		my @l = grep { $begin &&= $_ != $p_id } @ids;
		$loop_ahead = 1;
		_add_group(\%loops, [ $p_id, $id, @l ]);
	    } elsif ($loops{$p_id}) {
		my $take;
		if (my @l = grep { $take ||= $loops{$_} && $loops{$_} == $loops{$p_id} } reverse @ids) {
		    $loop_ahead = 1;
#		    warn "# loop to existing one $p_id, $id, @l\n";
		    _add_group(\%loops, [ $p_id, $id, @l ]);
		}
	    } else {
		$recurse->($p_id, $id, @ids);
		#- we would need to compute loop_ahead. we will do it below only once, and if not already set
	    }
	}
	if (!$loop_ahead && $loops{$id} && grep { exists $loops{$_} && $loops{$_} == $loops{$id} } @ids) {
	    $loop_ahead = 1;
	}

	if (!$loop_ahead) {
	    #- it's now a leaf or a loop we're done with
	    my @toadd = $loops{$id} ? @{$loops{$id}} : $id;
	    $added{$_} = undef foreach @toadd;
#	    warn "# adding ", join('+', @toadd), " for $id\n";
	    push @sorted, [ uniq(grep { $nodes_h{$_} } @toadd) ];
	}
    };
    !exists $added{$_} and $recurse->($_) foreach @$nodes;

#    warn "# result: ", join(' ', map { join('+', @$_) } @sorted), "\n";

    check_graph_is_sorted(\@sorted, $nodes, $edges) or die "sort_graph failed";
    
    @sorted;
}

=item check_graph_is_sorted($sorted, $nodes, $edges)

=cut

#- side-effects: none
sub check_graph_is_sorted {
    my ($sorted, $nodes, $edges) = @_;

    my $i = 1;
    my %nb;
    foreach (@$sorted) {
	$nb{$_} = $i foreach @$_;
	$i++;
    }
    my $nb_errors = 0;
    my $error = sub { $nb_errors++; warn "error: $_[0]\n" };

    foreach my $id (@$nodes) {
	$nb{$id} or $error->("missing $id in sort_graph list");
    }
    foreach my $id (keys %$edges) {
	my $id_i = $nb{$id} or next;
	foreach my $req (@{$edges->{$id}}) {
	    my $req_i = $nb{$req} or next;
	    $req_i <= $id_i or $error->("$req should be before $id ($req_i $id_i)");
	}
    }
    $nb_errors == 0;
}


#- side-effects: none
sub _sort_by_dependencies__add_obsolete_edges {
    my ($urpm, $state, $l, $requires) = @_;

    my @obsoletes = grep { $_->{obsoleted} } values %{$state->{rejected}} or return;
    my @groups = grep { @$_ > 1 } map { [ keys %{$_->{closure}} ] } @obsoletes;
    my %groups;
    foreach my $group (@groups) {
	_add_group(\%groups, $group);
	foreach (@$group) {
	    my $rej = $state->{rejected}{$_} or next;
	    _add_group(\%groups, [ $_, keys %{$rej->{closure}} ]);
	}
    }

    my %fullnames = map { scalar($urpm->{depslist}[$_]->fullname) => $_ } @$l;
    foreach my $group (uniq(values %groups)) {
	my @group = grep { defined $_ } map { $fullnames{$_} } @$group;
	foreach (@group) {
	    @{$requires->{$_}} = uniq(@{$requires->{$_}}, @group);
	}
    }
}

=item sort_by_dependencies($urpm, $state, @list_unsorted)

=cut

#- side-effects: none
sub sort_by_dependencies {
    my ($urpm, $state, @list_unsorted) = @_;
    @list_unsorted = sort { $a <=> $b } @list_unsorted; # sort by ids to be more reproducible
    $urpm->{debug_URPM}("getting graph of dependencies for sorting") if $urpm->{debug_URPM};
    my $edges = _sort_by_dependencies_get_graph($urpm, $state, \@list_unsorted);
    my $requires = reverse_multi_hash($edges);

    _sort_by_dependencies__add_obsolete_edges($urpm, $state, \@list_unsorted, $requires);

    $urpm->{debug_URPM}("sorting graph of dependencies") if $urpm->{debug_URPM};
    sort_graph(\@list_unsorted, $requires);
}

=item sorted_rpms_to_string($urpm, @sorted)

=cut

sub sorted_rpms_to_string {
    my ($urpm, @sorted) = @_;

    "rpms sorted by dependencies:\n" . join("\n", map { 
	join('+', _ids_to_names($urpm, @$_));
    } @sorted);
}

=item build_transaction_set($urpm, $db, $state, %options)

Build transaction set for given selection
Options: start, end, idlist, split_length, keep

=cut

#- side-effects: $state->{transaction}, $state->{transaction_state}
sub build_transaction_set {
    my ($urpm, $db, $state, %options) = @_;

    #- clean transaction set.
    $state->{transaction} = [];

    my %selected_id;
    @selected_id{$urpm->build_listid($options{start}, $options{end}, $options{idlist})} = ();
    
    if ($options{split_length}) {
	#- first step consists of sorting packages according to dependencies.
	my @sorted = sort_by_dependencies($urpm, $state,
	   keys(%selected_id) > 0 ? 
	      (grep { exists($selected_id{$_}) } keys %{$state->{selected}}) : 
	      keys %{$state->{selected}});
	$urpm->{debug_URPM}(sorted_rpms_to_string($urpm, @sorted)) if $urpm->{debug_URPM};

	#- second step consists of re-applying resolve_requested in the same
	#- order computed in first step and to update a list of packages to
	#- install, to upgrade and to remove.
	my %examined;
	my @todo = @sorted;
	while (@todo) {
	    my @ids;
	    while (@todo && @ids < $options{split_length}) {
		my $l = shift @todo;
		push @ids, @$l;
	    }
	    my %requested = map { $_ => undef } @ids;

		resolve_requested__no_recommends_($urpm,
		    $db, $state->{transaction_state} ||= {},
		    \%requested,
		    defined $options{start} ? (start => $options{start}) : @{[]},
		    defined $options{end}   ? (end   => $options{end}) : @{[]},
		    keep => $options{keep},
		);

		my @upgrade = grep { ! exists $examined{$_} } keys %{$state->{transaction_state}{selected}};
		my @remove = grep { ! exists $examined{$_} } packages_to_remove($state->{transaction_state});

		@upgrade || @remove or next;

		if (my @bad_remove = grep { !$state->{rejected}{$_}{removed} || $state->{rejected}{$_}{obsoleted} } @remove) {
		    $urpm->{error}(sorted_rpms_to_string($urpm, @sorted)) if $urpm->{error};
		    $urpm->{error}('transaction is too small: ' . join(' ', @bad_remove) . ' is rejected but it should not (current transaction: ' . join(' ', _ids_to_fullnames($urpm, @upgrade)) . ', requested: ' . join('+', _ids_to_fullnames($urpm, @ids)) . ')') if $urpm->{error};
		    $state->{transaction} = [];
		    last;
		}

		$urpm->{debug_URPM}(sprintf('transaction valid: remove=%s update=%s',
					    join(',', @remove),
					    join(',', _ids_to_names($urpm, @upgrade)))) if $urpm->{debug_URPM};
    
		$examined{$_} = undef foreach @upgrade, @remove;
		push @{$state->{transaction}}, { upgrade => \@upgrade, remove => \@remove };
	}

	#- check that the transaction set has been correctly created.
	#- (ie that no other package was removed)
	if (keys(%{$state->{selected}}) == keys(%{$state->{transaction_state}{selected}}) &&
	    scalar(packages_to_remove($state)) == scalar(packages_to_remove($state->{transaction_state}))
	) {
	    foreach (keys(%{$state->{selected}})) {
		exists $state->{transaction_state}{selected}{$_} and next;
		$urpm->{error}('using one big transaction') if $urpm->{error};
		$state->{transaction} = []; last;
	    }
	    foreach (packages_to_remove($state)) {
		$state->{transaction_state}{rejected}{$_}{removed} &&
		  !$state->{transaction_state}{rejected}{$_}{obsoleted} and next;
		$urpm->{error}('using one big transaction') if $urpm->{error};
		$state->{transaction} = []; last;
	    }
	}
    }

    #- fallback if something can be selected but nothing has been allowed in transaction list.
    if (%{$state->{selected} || {}} && !@{$state->{transaction}}) {
	$urpm->{debug_URPM}('using one big transaction') if $urpm->{debug_URPM};
	push @{$state->{transaction}}, {
					upgrade => [ keys %{$state->{selected}} ],
					remove  => [ packages_to_remove($state) ],
				       };
    }

    if ($state->{orphans_to_remove}) {
	my @l = map { scalar $_->fullname } @{$state->{orphans_to_remove}};
	push @{$state->{transaction}}, { remove  => \@l } if @l;
    }

    $state->{transaction};
}

1;

__END__

=back

=head1 COPYRIGHT

Copyright (C) 2002-2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2016 Mageia

=cut

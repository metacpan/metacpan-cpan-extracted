package urpm::select;


use strict;
use urpm::msg;
use urpm::util qw(any formatList intersection member min partition uniq);
use urpm::sys;
use URPM;

my $default_priority_list = 'rpm,perl-base,perl-URPM,perl-MDV-Distribconf,urpmi,meta-task,glibc,aria2';
my @priority_list = split(',', $default_priority_list);

my $evr_re = qr/[^\-]*-[^\-]*\.[^\.\-]*$/;


=head1 NAME

urpm::select - package selection routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut


sub add_packages_to_priority_upgrade_list {
    @priority_list = uniq(@priority_list, @_);
}

sub set_priority_upgrade_option {
    my ($urpm, $previous) = @_;

    exists $urpm->{options}{'priority-upgrade'} and return;

    # comma-separated list of packages that should be installed first,
    # and that trigger an urpmi restart
    my $list = join(',', @priority_list);
    if ($previous) {
	if ($previous eq $list) {
	    $list = '';
	    $urpm->{log}(N("urpmi was restarted, and the list of priority packages did not change"));
	} else {
	    $urpm->{log}(N("urpmi was restarted, and the list of priority packages did change: %s vs %s", $previous, $list));
	}
    }
    $urpm->{options}{'priority-upgrade'} = $list;
}

sub _findindeps {
    my ($urpm, $found, $qv, $v, $caseinsensitive, $src) = @_;

    foreach (keys %{$urpm->{provides}}) {
	#- search through provides to find if a provide matches this one;
	#- but manage choices correctly (as a provides may be virtual or
	#- defined several times).
	/$qv/ || !$caseinsensitive && /$qv/i or next;

	my @list = grep { defined $_ } map {
	    my $pkg = $_;
	    $pkg && ($src ? $pkg->arch eq 'src' : $pkg->arch ne 'src')
	      ? $pkg->id : undef;
	} $urpm->packages_providing($_);
	@list > 0 and push @{$found->{$v}}, join '|', @list;
    }
}

sub pkg_in_searchmedia {
    my ($urpm, $pkg) = @_;

    foreach my $medium (grep { $_->{searchmedia} } @{$urpm->{media}}) {
	$medium->{start} <= $pkg->id
	  && $medium->{end} >= $pkg->id and return 1;
    }
    0;
}
sub searchmedia_idlist {
    my ($urpm) = @_;
    $urpm->{searchmedia} && [ 
	map { $_->{start} .. $_->{end} } 
	  grep { $_->{searchmedia} } @{$urpm->{media}}
    ];
}
sub build_listid_ {
    my ($urpm) = @_;
    $urpm->build_listid(undef, undef, searchmedia_idlist($urpm));
}


=item search_packages($urpm, $packages, $names, %options)

Search packages registered by their names by storing their ids into the $packages hash.

Returns either 0 (error), 1 (OK) or 'substring' (fuzzy match).

Recognized options:

=over


=item * all

=item * caseinsensitive

=item * fuzzy

=item * no_substring: in --auto, do not allow to install a package substring match (you can use -a to force it)

=item * src

=item * use_provides

=back

=cut

#- side-effects: $packages, flag_skip
sub search_packages {
    my ($urpm, $packages, $names, %options) = @_;

    my ($name2ids, $result) = _search_packages($urpm, $names, %options) or return;

    foreach my $v (@$names) {
	my @ids = split /\|/, $name2ids->{$v};

	#- in case we have a substring match, we want individual selection (for urpmq --fuzzy)
	$packages->{$_} = 1 foreach $result eq 'substring' || $options{all} ? @ids : $name2ids->{$v};

	foreach (@ids) {
	    my $pkg = $urpm->{depslist}[$_] or next;
	    $urpm->{debug} and $urpm->{debug}("search_packages: found " . $pkg->fullname . " matching $v");
	    $pkg->set_flag_skip(0); #- reset skip flag as manually selected.
	}
    }
    $result;
}

#- side-effects: none
sub _search_packages {
    my ($urpm, $names, %options) = @_;
    my (%exact, %exact_a, %exact_ra, %found, %foundi);
    foreach my $v (@$names) {
	my $qv = quotemeta $v;
	my @found;
	$qv = '(?i)' . $qv if $options{caseinsensitive};

	# First: try to find an exact match
	if (!$options{fuzzy}) {
	    #- try to search through provides.
	    my @l = map {
		    $_
		    && ($options{src} ? $_->arch eq 'src' : $_->is_arch_compat)
		    && ($options{use_provides} || $_->name eq $v)
		    && defined($_->id)
		    && (!$urpm->{searchmedia} || pkg_in_searchmedia($urpm, $_))
		    ? $_ : @{[]};
	    } $urpm->packages_providing($v);

	    if (@l) {
		$exact{$v} = _search_packages_keep_best($v, \@l, $options{all});
		next;
	    }
	} elsif ($options{use_provides}) {
	    _findindeps($urpm, \%found, $qv, $v, $options{caseinsensitive}, $options{src});
	}

	# Second pass: try to find a partial match (substring) [slow]
	foreach my $id (build_listid_($urpm)) {
	    my $pkg = $urpm->{depslist}[$id];
	    ($options{src} ? $pkg->arch eq 'src' : $pkg->is_arch_compat) or next;
	    my $pack_name = $pkg->name;
	    my $pack_ra = $pack_name . '-' . $pkg->version;
	    my $pack_a = "$pack_ra-" . $pkg->release;
	    my $pack = "$pack_a." . $pkg->arch;
	    if (!$options{fuzzy}) {
		if ($pack eq $v) {
		    $exact{$v} = $id;
		} elsif ($pack_a eq $v) {
		    push @{$exact_a{$v}}, $id;
		} elsif ($pack_ra eq $v || $options{src} && $pack_name eq $v) {
		    push @{$exact_ra{$v}}, $id;
		}
		next;
	    }
	    if ($pack =~ /$qv/) {
		next if member($pack, @found);
		push @found, $pack;
		push @{$found{$v}}, $id;
	    }
	    next if !$options{caseinsensitive};
	    if ($pack =~ /$qv/i) {
		next if member($pack, @found);
		push @found, $pack;
		push @{$foundi{$v}}, $id;
	    }
	}
    }

    my $result = 1;
    my %name2ids;
    foreach my $v (@$names) {
	if (defined $exact{$v}) {  
	    $name2ids{$v} = $exact{$v};
	} else {
	    #- at this level, we need to search the best package given for a given name,
	    #- always prefer already found package.
	    my %l;
	    foreach (@{$exact_a{$v} || $exact_ra{$v} || $found{$v} || $foundi{$v} || []}) {
		my $pkg = $urpm->{depslist}[$_];
		push @{$l{$pkg->name}}, $pkg;
	    }
	    #- non-exact match?
	    my $is_substring_match = !@{$exact_a{$v} || $exact_ra{$v} || []};

	    if (values(%l) == 0
		  || !$options{all} && (values(%l) > 1 || $is_substring_match && $options{no_substring})) {
		$urpm->{error}(N("No package named %s", $v));
		values(%l) != 0 and $urpm->{error}(
		    N("The following packages contain %s: %s",
			$v, formatList(4, sort { $a cmp $b } keys %l)) . "\n" . 
		    N("You should use \"-a\" to use all of them")
		);
		$result = 0;
	    } else {
		$is_substring_match and $result = 'substring';

		$name2ids{$v} = join('|', map {
		    my $best;
		    foreach (@$_) {
			if ($best && $best != $_) {
			    $_->compare_pkg($best) > 0 and $best = $_;
			} else {
			    $best = $_;
			}
		    }
		    map { $_->id } grep { $_->fullname eq $best->fullname } @$_;
		} values %l);
	    }
	}
    }

    #- return 0 if error, 'substring' if fuzzy match, 1 if ok
    \%name2ids, $result;
}

#- side-effects: none
sub _search_packages_keep_best {
    my ($name, $pkgs, $all) = @_;

    #- find the lowest value of is_arch_compat
    my ($noarch, $arch) = partition { $_->arch eq 'noarch' } @$pkgs;
    my %compats;
    push @{$compats{$_->is_arch_compat}}, $_ foreach @$arch;
    
    delete $compats{0};		#- means not compatible
    #- if there are pkgs matching arch, prefer them
    if (%compats && !$all) {
	my $best_arch = min(keys %compats);
	%compats = ($best_arch => $compats{$best_arch});
    }
    my @l = %compats ? (@$noarch, map { @$_ } values %compats) : @$pkgs;

    #- we assume that if there is at least one package providing
    #- the resource exactly, this should be the best one; but we
    #- first check if one of the packages has the same name as searched.
    if (my @l2 = grep { $_->name eq $name } @l) {
	@l = @l2;
    }
    join('|', map { $_->id } @l);
}


=item resolve_dependencies($urpm, $state, $requested, %options)


Resolves dependencies between requested packages (and auto selection if any).
Handles parallel option if any.

The return value is true if program should be restarted (in order to take
care of important packages being upgraded (priority upgrades)

$state->{selected} will contain the selection of packages to be
installed or upgraded


%options :

=over

=item * auto_select

=item * install_src

=item * priority_upgrade

=back

%options passed to ->resolve_requested:

=over

=item * callback_choices

=item * keep

=item * nodeps

=item * no_recommends

=back

=cut

sub resolve_dependencies {
    #- $state->{selected} will contain the selection of packages to be
    #- installed or upgraded
    my ($urpm, $state, $requested, %options) = @_;
    my $need_restart;

    if ($urpm->{parallel_handler}) {
	require urpm::parallel; #- help perl_checker;
	urpm::parallel::resolve_dependencies($urpm, $state, $requested, %options);
    } else {
	my $db = urpm::db_open_or_die_($urpm);

	my $sig_handler = sub { undef $db; exit 3 };
	local $SIG{INT} = $sig_handler;
	local $SIG{QUIT} = $sig_handler;

	#- auto select package for upgrading the distribution.
	if ($options{auto_select}) {
	    $urpm->request_packages_to_upgrade($db, $state, $requested, requested => undef,
					       $urpm->{searchmedia} ? (idlist => searchmedia_idlist($urpm)) : (),
					   );
	}

	if ($options{priority_upgrade} && !$urpm->{env_rpmdb}) {
	    #- first check if a priority_upgrade package is requested
	    #- (it should catch all occurences in --auto-select mode)
	    #- (nb: a package "foo" may appear twice, and only one will be set flag_upgrade)
	    $need_restart = resolve_priority_upgrades_after_auto_select($urpm, $db, $state, $requested, %options);
	}

	if (!$need_restart) {
	    $urpm->resolve_requested($db, $state, $requested, %options);

	    #- now check if a priority_upgrade package has been required
	    #- by a requested package
	    if (my @l = grep { $state->{selected}{$_->id} } _priority_upgrade_pkgs($urpm, $options{priority_upgrade})) {
		$need_restart = _resolve_priority_upgrades($urpm, $db, $state, $state->{selected}, \@l, %options);
	    }
	}
	$urpm->{options}{'split-length'} = 0 if $need_restart;
    }
    $need_restart;
}

sub select_replacepkgs {
    my ($urpm, $state, $requested) = @_;

    my $db = urpm::db_open_or_die_($urpm);
    foreach my $id (keys %$requested) {
	my @pkgs = $urpm->find_candidate_packages($id);
	if (my ($pkg) = grep { URPM::is_package_installed($db, $_) } @pkgs) {
		$urpm->{debug_URPM}("selecting replacepkg " . $pkg->fullname) if $urpm->{debug_URPM};
		$pkg->set_flag_requested;
		$state->{selected}{$pkg->id} = undef;
	} else {
	    $urpm->{fatal}(1, N("found package(s) %s in urpmi db, but none are installed", join(', ', map { scalar($_->fullname) } @pkgs)));
	}
    }
}

sub _priority_upgrade_pkgs {
    my ($urpm, $priority_upgrade_string) = @_;

    map {
	$urpm->packages_by_name($_);
    } split(/,/, $priority_upgrade_string);
}


sub resolve_priority_upgrades_after_auto_select {
    my ($urpm, $db, $state, $selected, %options) = @_;

    my $need_restart;

    if (my @l = grep { $_->flag_upgrade } _priority_upgrade_pkgs($urpm, $options{priority_upgrade})) {
	$need_restart = _resolve_priority_upgrades($urpm, $db, $state, $selected, \@l, %options);
    }
    $need_restart;
}

sub _resolve_priority_upgrades {
    my ($urpm, $db, $state, $selected, $priority_pkgs, %options) = @_;

    my ($need_restart, %priority_state);
 
    my %priority_requested = map { $_->id => undef } @$priority_pkgs;

    $urpm->resolve_requested($db, \%priority_state, \%priority_requested, %options);
    if (any { ! exists $priority_state{selected}{$_} } keys %priority_requested) {
	#- some packages which were selected previously have not been selected, strange!
    } elsif (any { ! exists $priority_state{selected}{$_} } keys %$selected) {
	#- there are other packages to install after this priority transaction.
	%$state = %priority_state;
	$need_restart = 1;
    }
    $need_restart;
}

sub cooked_prefer {
    my ($urpm, $cmdline_prefer) = @_;

    $urpm->{prefer_regexps} ||= [
	map {
	    m!^/(.*)/$! ? "($1)" : '^' . quotemeta($_) . '$';
	} map { @$_ }
	  urpm::sys::get_packages_list($urpm->{prefer_list}, $cmdline_prefer),
	  urpm::sys::get_packages_list($urpm->{prefer_vendor_list})
    ];
    @{$urpm->{prefer_regexps}};
}

sub get_preferred {
    my ($urpm, $choices, $cmdline_prefer) = @_;

    my @prefer;
    my @l = @$choices;
    foreach my $re (cooked_prefer($urpm, $cmdline_prefer)) {
	my ($prefer, $other) = partition { $_->name =~ $re } @l;
	push @prefer, @$prefer;
	@l = @$other;

	if (@$prefer) {
	    my $prefer_s = join(',', map { $_->name } @$prefer);
	    my $other_s     = join(',', map { $_->name } @l);
	    $urpm->{log}("preferring $prefer_s over $other_s");
	}
    }
    
    #- only keep the best prefered
    #- then put the other prefered packages first 
    my $best = shift @prefer; 
    $best ? [$best] : [], [@prefer, @l];
}

=item find_packages_to_remove($urpm, $state, $l, %options)

Find packages to remove.

Options:

=over

=item * callback_base

=item * callback_fuzzy

=item * callback_notfound

=item * force

=item * matches

=item * test

=back

=cut 

sub find_packages_to_remove {
    my ($urpm, $state, $l, %options) = @_;

    if ($urpm->{parallel_handler}) {
	#- invoke parallel finder.
	$urpm->{parallel_handler}->parallel_find_remove($urpm, $state, $l, %options, find_packages_to_remove => 1);
    } else {
	my $db = urpm::db_open_or_die_($urpm);
	my (@m, @notfound);

	if (!$options{matches}) {
	    foreach (@$l) {
		my ($found);

		$db->traverse_tag('nvra', [ $_ ], sub {
			my ($p) = @_;
			$urpm->resolve_rejected($db, $state, $p, removed => 1);
			push @m, scalar $p->fullname;
			$found = 1;
		    });

		if ($found) {
		    next;
		} else {
		    push @notfound, $_;
		}
	    }
	    if (!$options{force} && @notfound && @$l > 1) {
		$options{callback_notfound} && $options{callback_notfound}->($urpm, @notfound)
		  or return ();
	    }
	}
	if ($options{matches} || @notfound) {
	    my $match = join "|", map { quotemeta } @$l;
	    my $qmatch = qr/$match/;

	    #- reset what has been already found.
	    %$state = ();
	    @m = ();

	    $urpm->{log}(qq(going through installed packages looking for "$match"...));
	    #- search for packages that match, and perform closure again.
	    $db->traverse(sub {
		    my ($p) = @_;
		    my $f = scalar $p->fullname;
		    $f =~ $qmatch or return;
		    $urpm->resolve_rejected($db, $state, $p, removed => 1);
		    push @m, $f;
		});
	    $urpm->{log}("...done, packages found [" . join(' ', @m) . "]");

	    if (!$options{force} && @notfound) {
		if (@m) {
		    $options{callback_fuzzy} && $options{callback_fuzzy}->($urpm, @$l > 1 ? $match : $l->[0], @m)
		      or return ();
		} else {
		    $options{callback_notfound} && $options{callback_notfound}->($urpm, @notfound)
		      or return ();
		}
	    }
	    if (!@m) {
		$options{callback_notfound} && $options{callback_notfound}->($urpm, @$l)
		  or return ();
	    }
	}

	#- check if something needs to be removed.
	find_removed_from_basesystem($urpm, $db, $state, $options{callback_base})
	    or return ();
    }
    removed_packages($state);
}

sub find_removed_from_basesystem {
    my ($urpm, $db, $state, $callback_base) = @_;
    $callback_base or return 1;

    if (my @l = _prohibit_packages_that_would_be_removed($urpm, $db, $state)) {
	$callback_base->($urpm, @l);
    } else {
	1;
    }

}
sub _prohibit_packages_that_would_be_removed {
    my ($urpm, $db, $state) = @_;

    my @to_remove = removed_packages($state) or return 1;

    my @dont_remove = ('basesystem', 'basesystem-minimal', 
		       split /,\s*/, $urpm->{global_config}{'prohibit-remove'});
    my (@base_fn, %base);
    $db->traverse_tag('whatprovides', \@dont_remove, sub {
	my ($p) = @_;
	$base{$p->name} = 1;
	push @base_fn, scalar $p->fullname;
    });

    grep {
	! any { $base{$_} } rejected_unsatisfied($state, $_);
    } intersection(\@to_remove, \@base_fn);
}


=item unselected_packages($state)

misc functions to help finding ask_unselect and ask_remove elements with their reasons translated.

=cut

sub unselected_packages {
    my ($state) = @_;
    grep { $state->{rejected}{$_}{backtrack} } keys %{$state->{rejected} || {}};
}

=item already_installed($state)

misc functions to help finding ask_unselect and ask_remove elements with their reasons translated.

=cut

sub already_installed {
    my ($state) = @_;
    uniq(map { scalar $_->fullname } values %{$state->{rejected_already_installed} || {}});
}

sub translate_already_installed {
    my ($state) = @_;

    my @l = already_installed($state) or return;

    @l == 1 ?
      N("Package %s is already installed", join(', ', @l)) :
      N("Packages %s are already installed", join(', ', @l));
}

sub translate_why_unselected {
    my ($urpm, $state, @fullnames) = @_;

    join("\n", map { translate_why_unselected_one($urpm, $state, $_) } sort @fullnames);
}

sub translate_why_unselected_one {
    my ($urpm, $state, $fullname) = @_;

    my $obj = $state->{rejected}{$fullname};
    my $rb = $obj->{backtrack};
    my @unsatisfied = @{$rb->{unsatisfied} || []};
    my @conflicts = @{$rb->{conflicts} || []};
    my $s = join ", ", (
	(map { N("due to conflicts with %s", $_) } @conflicts),
	(map { N("due to unsatisfied %s", $_) } uniq(map {
	    #- XXX in theory we shouldn't need this, dependencies (and not ids) should
	    #- already be present in @unsatisfied. But with biarch packages this is
	    #- not always the case.
	    /\D/ ? $_ : scalar($urpm->{depslist}[$_]->fullname);
	} @unsatisfied)),
	$rb->{promote} && !$rb->{keep} ? N("trying to promote %s", join(", ", @{$rb->{promote}})) : (),
	$rb->{keep} ? N("in order to keep %s", join(", ", @{$rb->{keep}})) : (),
    );
    $fullname . ($s ? " ($s)" : '');
}

sub selected_packages_providing {
    my ($urpm, $state, $name) = @_;
    map { $urpm->{depslist}[$_] } grep { $state->{selected}{$_} } keys %{$urpm->{provides}{$name} || {}};
}

sub was_pkg_name_installed {
    my ($rejected, $name) = @_;

    foreach (keys %$rejected) {
	/^\Q$name\E-$evr_re/ or next;
	$rejected->{$_}{obsoleted} and return 1;
    }
    0;
}

sub removed_packages {
    my ($state) = @_;
    grep {
	$state->{rejected}{$_}{removed} && !$state->{rejected}{$_}{obsoleted};
    } keys %{$state->{rejected} || {}};
}
sub rejected_closure {
    my ($state, $fullname) = @_;
    $state->{rejected} && $state->{rejected}{$fullname} && $state->{rejected}{$fullname}{closure};
}
sub rejected_unsatisfied {
    my ($state, $fullname) = @_;
    my $closure = rejected_closure($state, $fullname) or return;
    map { $_ ? @$_ : () } map { $_->{unsatisfied} } values %$closure;
}

sub conflicting_packages_msg_ {
    my ($removed_packages_msgs) = @_;

    my $list = join("\n", @$removed_packages_msgs) or return;
    @$removed_packages_msgs == 1 ? 
        N("The following package has to be removed for others to be upgraded:\n%s", $list)
	: N("The following packages have to be removed for others to be upgraded:\n%s", $list);
}
sub conflicting_packages_msg {
    my ($urpm, $state) = @_;
    conflicting_packages_msg_([ removed_packages_msgs($urpm, $state) ]);
}

sub removed_packages_msgs {
    my ($urpm, $state) = @_;
    map { translate_why_removed_one($urpm, $state, $_) } sort(removed_packages($state));
}

sub translate_why_removed {
    my ($urpm, $state, @fullnames) = @_;
    join("\n", map { translate_why_removed_one($urpm, $state, $_) } sort @fullnames);
}
sub translate_why_removed_one {
    my ($urpm, $state, $fullname) = @_;

    my $closure = rejected_closure($state, $fullname) or return $fullname;

    my ($from) = keys %$closure;
    my ($whyk) = sort { $b ne 'avoid' } keys %{$closure->{$from}};
    my $whyv = $closure->{$from}{$whyk};
    my $frompkg = $urpm->search($from, strict_fullname => 1);
    my $s = do {
	if ($whyk =~ /old_requested/) {
	    N("in order to install %s", $frompkg ? scalar $frompkg->fullname : $from);
	} elsif ($whyk =~ /unsatisfied/) {
	    join(",\n  ", map {
		if (/([^\[\s]*)(?:\[\*\])?(?:\[|\s+)([^\]]*)\]?$/ && $2 ne '*') {
		    N("due to unsatisfied %s", "$1 $2");
		} else {
		    N("due to missing %s", $_);
		}
	    } @$whyv);
	} elsif ($whyk =~ /conflicts/) {
	    N("due to conflicts with %s", $whyv);
	} else {
	    $whyk;
	}
    };
    #- now insert the reason if available.
    $fullname . ($s ? "\n ($s)" : '');
}

sub _libdb_version { $_[0] =~ /libdb-(\S+)\.so/ ? version->new("v$1") : () }
sub _rpm_version() { `rpm --version` =~ /version ([0-9.]+)(?:-(beta|rc).*)?$/ ? version->new("v$1") : () }

sub should_we_migrate_back_rpmdb_db_version {
    my ($urpm, $state) = @_;

    my ($pkg) = urpm::select::selected_packages_providing($urpm, $state, 'rpm') or return;
    urpm::select::was_pkg_name_installed($state->{rejected}, 'rpm') and return;
    my ($rooted_librpm_version) = map { _libdb_version($_) } $pkg->requires; # perl_checker: $self = revision
    my $rooted_rpm_version = version->new("v" . $pkg->version); # perl_checker: $self = revision

    my $urpmi_librpm_version = _libdb_version(scalar `ldd /bin/rpm`); # perl_checker: $self = revision

    if (_rpm_version() ge v4.9.0) { # perl_checker: $self = revision
	if ($rooted_rpm_version && $rooted_rpm_version ge v4.9) {
	    $urpm->{debug} and $urpm->{debug}("chrooted db version used by librpm is at least as good as non-rooted one");
	} else {
	    $urpm->{need_migrate_rpmdb} = '4.8';
	    return 1;
	}
    } elsif ($urpmi_librpm_version ge v4.6) {
	if ($rooted_librpm_version && $rooted_librpm_version ge v4.6) {
	    $urpm->{debug} and $urpm->{debug}("chrooted db version used by librpm is at least as good as non-rooted one");
	} else {
	    foreach my $bin ('db_dump', 'db42_load') {
		urpm::sys::whereis_binary($bin) 
		  or $urpm->{error}("can not migrate rpm db from Hash version 9 to Hash version 8 without $bin"), 
		    return;
	    }
	    $urpm->{need_migrate_rpmdb} = '4.6';
	    return 1;
	}
    }
    0;
}

1;

=back

=cut

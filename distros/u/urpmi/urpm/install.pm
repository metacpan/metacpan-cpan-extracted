package urpm::install; 


use strict;
use urpm;
use urpm::msg;
use urpm::util qw(cat_utf8 member);


=head1 NAME

urpm::install - Package installation transaction routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut

# size of the installation progress bar
my $progress_size = 45;
if (-t *STDOUT) {
  eval {
    require Term::ReadKey;
    ($progress_size) = Term::ReadKey::GetTerminalSize();
    $progress_size -= 35;
    $progress_size < 5 and $progress_size = 5;
  };
}


sub _hash_intersect_list {
    my ($h, $l) = @_;
    my %h;
    foreach (@$l) {
	exists $h->{$_} and $h{$_} = $h->{$_};
    }
    \%h;
}

=item prepare_transaction($set, $blists, $sources)

=cut


sub prepare_transaction {
    my ($set, $blists, $sources) = @_;

    my @blists_subset = map {
	+{ %$_, pkgs => _hash_intersect_list($_->{pkgs}, $set->{upgrade}) };
    } @$blists;

    \@blists_subset, _hash_intersect_list($sources, $set->{upgrade});
}

sub build_transaction_set_ {
    my ($urpm, $state, %options) = @_;

    if ($urpm->{parallel_handler} || !$options{split_length} ||
	keys %{$state->{selected}} < $options{split_level}) {
	#- build simplest transaction (no split).
	$urpm->build_transaction_set(undef, $state, split_length => 0);
    } else {
	my $db = urpm::db_open_or_die_($urpm);

	my $sig_handler = sub { undef $db; exit 3 };
	local $SIG{INT} = $sig_handler;
	local $SIG{QUIT} = $sig_handler;

	#- build transaction set...
	$urpm->build_transaction_set($db, $state, split_length => $options{split_length}, keep => $options{keep});
    }
}

sub transaction_set_to_string {
    my ($urpm, $set) = @_;

    my $format_list = sub { int(@_) . '=' . join(',', @_) };
    map {
	sprintf('remove=%s update=%s',
		$format_list->(@{$_->{remove} || []}),
		$format_list->(map { $urpm->{depslist}[$_]->name } @{$_->{upgrade} || []}));
    } @$set;
}

=item install_logger($urpm, $type, $id, $subtype, $amount, $total)

Standard logger for transactions

See L<URPM> for parameters

=cut

# install logger callback
my ($erase_logger, $index, $total_pkg, $uninst_count, $current_pkg);
sub install_logger {
    my ($urpm, $type, undef, $subtype, $amount, $total) = @_;
    local $| = 1;

    if ($subtype eq 'start') {
	$urpm->{logger_progress} = 0;
	if ($type eq 'trans') {
	    $total_pkg = $urpm->{nb_install};
	    $urpm->{logger_count} ||= 0;
	    $uninst_count = 0;
	    my $p = N("Preparing...");
	    print $p, " " x (33 - length $p);
	} else {
	    my $pname;
	    my $cnt;
	    if ($type eq 'uninst') {
		$total_pkg = $urpm->{trans}->NElements - $index if !$uninst_count;
		$cnt = ++$uninst_count;
		$pname = N("removing %s", $current_pkg);
		$erase_logger->($urpm, undef, undef, $subtype);
	    } else {
		$pname = $urpm->{trans}->Element_name($index);
		++$urpm->{logger_count} if $pname;
		$cnt = $pname ? $urpm->{logger_count} : '-';
	    }
	    my $s = sprintf("%9s: %-22s", $cnt . "/" . $total_pkg, $pname);
	    print $s;
	    $s =~ / $/ or printf "\n%9s  %-22s", '', '';
	}
    } elsif ($subtype eq 'stop') {
	if ($urpm->{logger_progress} < $progress_size) {
	    $urpm->{print}('#' x ($progress_size - $urpm->{logger_progress}));
	    $urpm->{logger_progress} = 0;
	}
    } elsif ($subtype eq 'progress') {
	my $new_progress = $total > 0 ? int($progress_size * $amount / $total) : $progress_size;
	if ($new_progress > $urpm->{logger_progress}) {
	    print '#' x ($new_progress - $urpm->{logger_progress});
	    $urpm->{logger_progress} = $new_progress;
	    $urpm->{logger_progress} == $progress_size and print "\n";
	}
    }
}

=item get_README_files($urpm, $trans, $pkg)

=cut

sub get_README_files {
    my ($urpm, $trans, $pkg) = @_;

    foreach my $file ($pkg->doc_files) { 
	my ($kind) = $file =~ m!/README([^/]*)\.urpmi$! or next;
	my $valid;
	if ($kind eq '') {
	    $valid = 1;
	} elsif ($kind eq '.install' && !$pkg->flag_installed) {
	    $valid = 1;
	} elsif ($kind =~ /(.*)\.(upgrade|update)$/ && $pkg->flag_installed) {
	    if (!$1) {
		$valid = 1;
	    } else {
		my $version = $1;
		foreach my $i (0 .. $trans->NElements - 1) {
		    $trans->Element_name($i) eq $pkg->name or next;

		    # handle README.<version>-<release>.upgrade.urpmi:
		    # the content is displayed when upgrading from rpm older than <version>
		    my $vr = $trans->Element_version($i) . '-' . $trans->Element_release($i);
		    if (URPM::ranges_overlap("== $vr", "< $version")) {
			$valid = 1;
			last;
		    }
		}
	    }
	}
	$valid and $urpm->{readmes}{$file} = $pkg->fullname;
    }
}

sub options {
    my ($urpm) = @_;

    (
	excludepath => $urpm->{options}{excludepath},
	excludedocs => $urpm->{options}{excludedocs},
	post_clean_cache => $urpm->{options}{'post-clean'},
	nosize => $urpm->{options}{ignoresize},
	ignorearch => $urpm->{options}{ignorearch},
	noscripts => $urpm->{options}{noscripts},
	replacefiles => $urpm->{options}{replacefiles},
    );
}

sub _schedule_packages_for_erasing {
    my ($urpm, $trans, $remove) = @_;
    foreach (@$remove) {
	if ($trans->remove($_)) {
	    $urpm->{debug} and $urpm->{debug}("trans: scheduling removal of $_");
	} else {
	    $urpm->{error}("unable to remove package " . $_);
	}
    }
}

sub _apply_delta_rpm {
    my ($urpm, $path, $mode, $pkg) = @_;
    my $true_rpm = urpm::sys::apply_delta_rpm($path, "$urpm->{cachedir}/rpms", $pkg);
    my $true_pkg;
    if ($true_rpm) {
	if (my ($id) = $urpm->parse_rpm($true_rpm)) {
	    $true_pkg = defined $id && $urpm->{depslist}[$id];
	    $mode->{$id} = $true_rpm;
	} else {
	    $urpm->{error}("Failed to parse $true_pkg");
	}
    } else {
	$urpm->{error}(N("unable to extract rpm from delta-rpm package %s", $path));
    }
    $true_rpm, $true_pkg;
}

sub _schedule_packages {
    my ($urpm, $trans, $install, $upgrade, %options) = @_;
    my $update = 0;
    my (@trans_pkgs, @produced_deltas);
    foreach my $mode ($install, $upgrade) {
	foreach (keys %$mode) {
	    my $pkg = $urpm->{depslist}[$_];
	    $pkg->update_header($mode->{$_}, keep_all_tags => 1);
	    my ($true_rpm, $true_pkg);
	    if ($pkg->payload_format eq 'drpm') { #- handle deltarpms
		($true_rpm, $true_pkg) = _apply_delta_rpm($urpm, $mode->{$_}, $mode, $pkg);
		push @produced_deltas, ($mode->{$_} = $true_rpm); #- fix path
	    }
	    if ($trans->add($true_pkg || $pkg, update => $update,
		    $options{excludepath} ? (excludepath => [ split /,/, $options{excludepath} ]) : ())) {
		$urpm->{debug} and $urpm->{debug}(
		    sprintf('trans: scheduling %s of %s (id=%d, file=%s)', 
		      $update ? 'update' : 'install', 
		      scalar($pkg->fullname), $_, $mode->{$_}));
		push @trans_pkgs, $pkg;

	    } else {
		$urpm->{error}(N("unable to install package %s", $mode->{$_}));
		my $cachefile = "$urpm->{cachedir}/rpms/" . $pkg->filename;
		if (-e $cachefile) {
		    $urpm->{error}(N("removing bad rpm (%s) from %s", $pkg->name, "$urpm->{cachedir}/rpms"));
		    unlink $cachefile or $urpm->{fatal}(1, N("removing %s failed: %s", $cachefile, $!));
		}
	    }
	}
	++$update;
    }
    \@produced_deltas, @trans_pkgs;
}

sub _get_callbacks {
    my ($urpm, $db, $trans, $options, $install, $upgrade, $have_pkgs) = @_;
    $index = 0;
    my $fh;

    my $is_test = $options->{test}; # fix circular reference
    #- assume default value for some parameter.
    $options->{delta} ||= 1000;

    #- ensure perl does not create a circular reference below, otherwise all this won't be collected,
    #  and rpmdb won't be closed:
    my ($callback_open_helper, $callback_close_helper) = ($options->{callback_open_helper}, $options->{callback_close_helper});
    $options->{callback_open} = sub {
	my ($_data, $_type, $id) = @_;
	$callback_open_helper and $callback_open_helper->(@_);
	$fh = urpm::sys::open_safe($urpm, '<', $install->{$id} || $upgrade->{$id});
	$fh ? fileno $fh : undef;
    };
    $options->{callback_close} = sub {
	my ($urpm, undef, $pkgid) = @_;
	return unless defined $pkgid;
	$callback_close_helper and $callback_close_helper->($db, @_);
	get_README_files($urpm, $trans, $urpm->{depslist}[$pkgid]) if !$is_test;
	close $fh if defined $fh;
    };

    #- ensure perl does not create a circular reference below, otherwise all this won't be collected,
    #  and rpmdb won't be closed
    my $verbose = $options->{verbose};
    $erase_logger = sub {
	my ($urpm, undef, undef, $subtype) = @_;

	if ($subtype eq 'start') {
	    my $name = $trans->Element_name($index);
	    my @previous = map { $trans->Element_name($_) } 0 .. ($index - 1);
	    # looking at previous packages in transaction
	    # we should be looking only at installed packages, but it should not give a different result
	    if (member($name, @previous)) {
		$urpm->{log}("removing upgraded package $current_pkg");
	    } else {
		$urpm->{print}(N("removing package %s", $current_pkg)) if $verbose >= 0;
	    }
	}
    };

    $options->{callback_uninst} ||= $options->{verbose} >= 0 ? \&install_logger : $erase_logger;

    $options->{callback_elem} ||= sub {
	my (undef, undef, undef, undef, $idx, undef) = @_;
	$index = $idx;
	$current_pkg = $trans->Element_fullname($idx);
    };
    $options->{callback_error} ||= sub {
	my ($urpm, undef, undef, $subtype, undef, undef) = @_;
	$urpm->{error}("ERROR: '$subtype' failed for $current_pkg");
    };

    if ($options->{verbose} >= 0 && $have_pkgs) {
	$options->{callback_inst}  ||= \&install_logger;
	$options->{callback_trans} ||= \&install_logger;
    }
}

=item install($urpm, $remove, $install, $upgrade, %options)

Install packages according to each hash (remove, install or upgrade).

options: 
     test, excludepath, nodeps, noorder (unused), delta, 
     callback_inst, callback_trans, callback_uninst,
     callback_open_helper, callback_close_helper,
     post_clean_cache, verbose
  (more options for trans->run)
     excludedocs, nosize, noscripts, oldpackage, replacepkgs, justdb, ignorearch

See L<URPM> for callback parameters

There's 2 callbacks that are specific to C<urpm::install> though:

=over

=item * open_helper($data, $type, $id)

=item * close_helper($db, $data, $type, $id)

=back

Those are called when opening/closing a package file, whether when rpmlib verify or install packages.

The C<close_helper> callback receives an extra $db parameter used in eg: drakx to check whether a package really was installed through a DB query.

=cut

#- side-effects: uses a $urpm->{readmes}
sub install {
    my ($urpm, $remove, $install, $upgrade, %options) = @_;
    $options{translate_message} = 1;

    my $db = urpm::db_open_or_die_($urpm, !$options{test}); #- open in read/write mode unless testing installation.

    my $trans = $db->create_transaction;
    if ($trans) {
	my ($rm_count, $inst_count, $up_count) = (scalar(@{$remove || []}), scalar(values %$install), scalar(values %$upgrade));
	sys_log("transaction on %s (remove=%d, install=%d, upgrade=%d)", $urpm->{root} || '/', $rm_count, $inst_count, $up_count);
	$urpm->{log}(N("created transaction for installing on %s (remove=%d, install=%d, upgrade=%d)", $urpm->{root} || '/',
		       $rm_count, $inst_count, $up_count));
    } else {
	return N("unable to create transaction");
    }

    $trans->set_script_fd($options{script_fd}) if $options{script_fd};

    my @errors;

    _schedule_packages_for_erasing($urpm, $trans, $remove);

    my ($produced_deltas, @trans_pkgs) = _schedule_packages($urpm, $trans, $install, $upgrade, %options);

    if (!$options{nodeps} && (@errors = $trans->check(%options))) {
    } elsif (!$options{noorder} && (@errors = $trans->order(%options))) {
    } else {
	$urpm->{readmes} = {};

	_get_callbacks($urpm, $db, $trans, \%options, $install, $upgrade, scalar @trans_pkgs);

	local $ENV{LD_PRELOAD}; # fix eatmydata & co
	local $urpm->{trans} = $trans;
	@errors = $trans->run($urpm, %options);
	delete $urpm->{trans};
	undef $erase_logger;

	#- don't clear cache if transaction failed. We might want to retry.
	if (!@errors && !$options{test} && $options{post_clean_cache}) {
	    #- examine the local cache to delete packages which were part of this transaction
	    my $cachedir = "$urpm->{cachedir}/rpms";
	    my @pkgs = grep { -e "$cachedir/$_" } map { $_->filename } @trans_pkgs;
	    $urpm->{log}(N("removing installed rpms (%s) from %s", join(' ', @pkgs), $cachedir)) if @pkgs;
	    foreach (@pkgs) {
		unlink "$cachedir/$_" or $urpm->{fatal}(1, N("removing %s failed: %s", $_, $!));
	    }
	}

	if ($options{verbose} >= 0 && !$options{justdb}) {
	    foreach (keys %{$urpm->{readmes}}) {
		$urpm->{print}("-" x 70 .  "\n" .
                                 N("More information on package %s", $urpm->{readmes}{$_}));
		$urpm->{print}(scalar cat_utf8(($urpm->{root} || '') . $_));
		$urpm->{print}("-" x 70);
	    }
	}
    }

    unlink @$produced_deltas;

    urpm::sys::may_clean_rpmdb_shared_regions($urpm, $options{test});

    # explicitely close the RPM DB (needed for drakx -- looks like refcount has hard work):
    undef $db;
    undef $trans;

    @errors;
}

1;

=back

=head1 COPYRIGHT

Copyright (C) 1999-2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut

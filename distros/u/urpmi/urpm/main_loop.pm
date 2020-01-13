package urpm::main_loop;


#- Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005 MandrakeSoft SA
#- Copyright (C) 2005-2010 Mandriva SA
#- Copyright (C) 2011-2020 Mageia
#-
#- This program is free software; you can redistribute it and/or modify
#- it under the terms of the GNU General Public License as published by
#- the Free Software Foundation; either version 2, or (at your option)
#- any later version.
#-
#- This program is distributed in the hope that it will be useful,
#- but WITHOUT ANY WARRANTY; without even the implied warranty of
#- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#- GNU General Public License for more details.
#-
#- You should have received a copy of the GNU General Public License
#- along with this program; if not, write to the Free Software
#- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

use strict;
use urpm;
use urpm::args;
use urpm::msg;
use urpm::install;
use urpm::media;
use urpm::select;
use urpm::orphans;
use urpm::get_pkgs;
use urpm::signature;
use urpm::util qw(find intersection member partition);

#- global boolean options
my ($auto_select, $no_install, $install_src, $clean, $noclean, $force, $parallel, $test);
#- global counters
my ($ok, $nok);
my $exit_code;


=head1 NAME

urpm::main_loop - The install/remove main loop for urpm based programs (urpmi, gurpmi, rpmdrake, drakx)

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut

sub _download_callback {
    my ($urpm, $callbacks, $raw_msg, $msg) = @_;
    if (my $download_errors = delete $urpm->{download_errors}) {
        $raw_msg = join("\n", @$download_errors, '');
    }
    $callbacks->{ask_yes_or_no}('', $raw_msg . "\n" . $msg . "\n" . N("Retry?"));
}

sub _download_packages {
    my ($urpm, $callbacks, $blists, $sources) = @_;
    my @error_sources;
    urpm::get_pkgs::download_packages_of_distant_media(
        $urpm,
        $blists,
        $sources,
        \@error_sources,
        quiet => $options{verbose} < 0,
        callback => $callbacks->{trans_log},
        ask_retry => !$urpm->{options}{auto} && ($callbacks->{ask_retry} || sub {
                                                     _download_callback($urpm, $callbacks, @_);
                                                 }),
    );
    my @msgs;
    if (@error_sources) {
        $_->[0] = urpm::download::hide_password($_->[0]) foreach @error_sources;
        my @bad = grep { $_->[1] eq 'bad' } @error_sources;
        my @missing = grep { $_->[1] eq 'missing' } @error_sources;

        if (@missing) {
            push @msgs, N("Installation failed, some files are missing:\n%s", 
                          join("\n", map { "    $_->[0]" } @missing))
              . "\n" .
                N("You may need to update your urpmi database.");
            $urpm->{nb_install} -= scalar @missing;
        }
        if (@bad) {
            push @msgs, N("Installation failed, bad rpms:\n%s",
                          join("\n", map { "    $_->[0]" } @bad));
        }
    }
    
    (\@error_sources, \@msgs);
}

sub _download_all {
    my ($urpm, $blists, $sources, $callbacks) = @_;
    if ($urpm->{options}{'download-all'}) {
        $urpm->{cachedir} = $urpm->{'urpmi-root'} . $urpm->{options}{'download-all'};
        urpm::init_dir($urpm, $urpm->{cachedir});
    }
    my (undef, $available) = urpm::sys::df("$urpm->{cachedir}/rpms");

    if (!$urpm->{options}{ignoresize}) {
        my ($download_size) = urpm::get_pkgs::get_distant_media_filesize($blists, $sources); 
        if ($download_size >= $available*1000) {
            my $p = N("There is not enough space on your filesystem to download all packages (%s needed, %s available).\nAre you sure you want to continue?", formatXiB($download_size), formatXiB($available*1000)); 
            $force || urpm::msg::ask_yes_or_no($p) or return 10;
        }	
    }

    #download packages one by one so that we don't try to download them again
    #and again if the user has to restart urpmi because of some failure
    my %downloaded_pkgs;
    foreach my $blist (@$blists) {
        foreach my $pkg (keys %{$blist->{pkgs}}) {
            next if $downloaded_pkgs{$pkg};
            my $blist_one = [{ pkgs => { $pkg => $blist->{pkgs}{$pkg} }, medium => $blist->{medium} }];
            my ($error_sources) = _download_packages($urpm, $callbacks, $blist_one, $sources);
            if (@$error_sources) {
                return 10;
            }
            $downloaded_pkgs{$pkg} = 1;
        }
    }
}

sub _verify_rpm {
    my ($urpm, $callbacks, $transaction_sources_install, $transaction_sources) = @_;
    $callbacks->{pre_check_sig} and $callbacks->{pre_check_sig}->();
    my @bad_signatures = urpm::signature::check($urpm, $transaction_sources_install, $transaction_sources,
                                                callback => $callbacks->{check_sig}, basename => $options{basename}
                                            );

    if (@bad_signatures) {
        my $msg = @bad_signatures == 1 ?
          N("The following package has bad signature")
            : N("The following packages have bad signatures");
        my $msg2 = N("Do you want to continue installation ?");
        my $p = join "\n", @bad_signatures;
        my $res = $callbacks->{bad_signature}->("$msg:\n$p\n", $msg2);
        return $res ? 0 : 16;
    }
}

sub _install_src {
    my ($urpm, $transaction_sources_install, $transaction_sources) = @_;
    if (my @l = grep { /\.src\.rpm$/ } values %$transaction_sources_install, values %$transaction_sources) {
        my $rpm_opt = $options{verbose} >= 0 ? 'vh' : '';
        push @l, "--root", $urpm->{root} if $urpm->{root};
        system("rpm", "-i$rpm_opt", @l);
        #- Warning : the following message is parsed in urpm::parallel_*
        if ($?) {
            $urpm->{print}(N("Installation failed"));
            ++$nok;
        } elsif ($urpm->{options}{'post-clean'}) {
            if (my @tmp_srpm = grep { urpm::is_temporary_file($urpm, $_) } @l) {
                $urpm->{log}(N("removing installed rpms (%s)", join(' ', @tmp_srpm)));
                unlink @tmp_srpm;
            }
        }
    }
}

sub clean_trans_sources_from_src_packages {
    my ($urpm, $transaction_sources_install, $transaction_sources) = @_;
    foreach ($transaction_sources_install, $transaction_sources) {
        foreach my $id (keys %$_) {
            my $pkg = $urpm->{depslist}[$id] or next;
            $pkg->arch eq 'src' and delete $_->{$id};
        }
    }
}

sub _continue_on_error {
    my ($urpm, $callbacks, $msgs, $error_sources, $formatted_errors) = @_;
    my $go_on;
    if ($urpm->{options}{auto}) {
        push @$formatted_errors, @$msgs;
    } else {
        my $sub = $callbacks->{ask_for_bad_or_missing} || $callbacks->{ask_yes_or_no};
        $go_on = $sub->(
            N("Installation failed"),
            join("\n\n", @$msgs, N("Try to continue anyway?")));
    }
    if (!$go_on) {
        my @missing = grep { $_->[1] eq 'missing' } @$error_sources;
        if (@missing) {
            $exit_code = $ok ? 13 : 14;
        }
        return 0;
    }
    return 1;
}

sub _handle_removable_media {
    my ($urpm, $callbacks, $blists, $sources) = @_;
    urpm::removable::try_mounting_non_cdroms($urpm, $blists);

    $callbacks->{pre_removable} and $callbacks->{pre_removable}->();
    require urpm::cdrom;
    urpm::cdrom::copy_packages_of_removable_media($urpm,
                                                  $blists, $sources,
                                                  $callbacks->{copy_removable});
    $callbacks->{post_removable} and $callbacks->{post_removable}->();
}

sub _init_common_options {
  my ($urpm, $state, $callbacks) = @_;
  (
      urpm::install::options($urpm),
      test => $test,
      deploops => $options{deploops},
      verbose => $options{verbose},
      script_fd => $urpm->{options}{script_fd},
      oldpackage => $state->{oldpackage},
      justdb => $options{justdb},
      replacepkgs => $options{replacepkgs},
      callback_close_helper => $callbacks->{close_helper},
      callback_error => $callbacks->{error},
      callback_inst => $callbacks->{inst},
      callback_open_helper => $callbacks->{open_helper},
      callback_trans => $callbacks->{trans},
      callback_uninst => $callbacks->{uninst},
      callback_verify => $callbacks->{verify},
      raw_message => 1,
  );
}

sub _log_installing {
    my ($urpm, $transaction_sources_install, $transaction_sources) = @_;
    if (my @packnames = (values %$transaction_sources_install, values %$transaction_sources)) {
        (my $common_prefix) = $packnames[0] =~ m!^(.*)/!;
        if (length($common_prefix) && @packnames == grep { m!^\Q$common_prefix/! } @packnames) {
            #- there's a common prefix, simplify message
            $urpm->{print}(N("installing %s from %s", join(' ', map { s!.*/!!; $_ } @packnames), $common_prefix));
        } else {
            $urpm->{print}(N("installing %s", join "\n", @packnames));
        }
    }
}

sub _run_parallel_transaction {
    my ($urpm, $state, $transaction_sources, $transaction_sources_install) = @_;
    $urpm->{print}(N("distributing %s", join(' ', values %$transaction_sources_install, values %$transaction_sources)));
    #- no remove are handle here, automatically done by each distant node.
    $urpm->{log}("starting distributed install");
    $urpm->{parallel_handler}->parallel_install(
        $urpm,
        [ keys %{$state->{rejected} || {}} ], $transaction_sources_install, $transaction_sources,
        test => $test,
        excludepath => $urpm->{options}{excludepath}, excludedocs => $urpm->{options}{excludedocs},
    );
}

sub _run_transaction {
    my ($urpm, $state, $callbacks, $set, $transaction_sources_install, $transaction_sources, $errors) = @_;

    my $options = $urpm->{options};
    my $allow_force = $options->{'allow-force'};

    my $to_remove = $allow_force ? [] : $set->{remove} || [];

    $urpm->{log}("starting installing packages");
	    
    urpm::orphans::add_unrequested($urpm, $state) if !$test;

    my %install_options_common = _init_common_options($urpm, $state, $callbacks);

  install:
    my @l = urpm::install::install($urpm,
                                   $to_remove,
                                   $transaction_sources_install, $transaction_sources,
                                   %install_options_common,
                               );

    if (!@l) {
        ++$ok;
        return 1;
    }

    my ($raw_error, $translated) = partition { /^(badarch|bados|installed|badrelocate|conflicts|installed|diskspace|disknodes|requires|conflicts|unknown)\@/ } @l;
    @l = @$translated;
    my $fatal = find { /^disk/ } @$raw_error;
    my $no_question = $fatal || $options->{auto};

    #- Warning : the following message is parsed in urpm::parallel_*
    my $msg = N("Installation failed:") . "\n" . join("\n",  map { "\t$_" } @l) . "\n";
    if (!$no_question && !$install_options_common{nodeps} && ($options->{'allow-nodeps'} || $allow_force)) {
        if ($callbacks->{ask_yes_or_no}->(N("Installation failed"), 
                                          $msg . N("Try installation without checking dependencies?"))) {
            $urpm->{log}("starting installing packages without deps");
            $install_options_common{nodeps} = 1;
            # try again:
            goto install;
        }
    } elsif (!$no_question && !$install_options_common{force} && $allow_force) {
        if ($callbacks->{ask_yes_or_no}->(N("Installation failed"),
                                          $msg . N("Try harder to install (--force)?"))) {
            $urpm->{log}("starting force installing packages without deps");
            $install_options_common{force} = 1;
            # try again:
            goto install;
        }
    }
    $urpm->{log}($msg);

    ++$nok;
    push @$errors, @l;

    !$fatal;
}

=item run($urpm, $state, $something_was_to_be_done, $ask_unselect, $callbacks)

Run the main urpm loop:

=over

=item * mount removable media if needed

=item * split the work in smaller transactions

=item * for each transaction:

=over

=item * prepare the transaction

=item * download packages needed for this small transaction

=item * verify packages

=item * split package that should be installed instead of upgraded,

=item * install source package only (whatever the user is root or not, but use rpm for that)

=item * install/remove other packages

=back

=item * migrate the chrooted rpmdb if needed

=item * display the final success/error message(s)

=back

Warning: locking is left to callers...

Parameters:

=over

=item $urpm: the urpm object

=item $state: the state object (see L<URPM>)

=item $something_was_to_be_done

=item $ask_unselect: an array ref of packages that could not be selected

=item $callbacks: a hash ref of callbacks :

=over

=item packages download:

=over

=item trans_log($mode, $file, $percent, $total, $eta, $speed): called for displaying download progress

=item post_download(): called after completing download of packages

=back

=item interaction with user:

=over

=item ask_yes_or_no($_title, $msg)

=item need_restart($need_restart_formatted) called when restarting urpmi is needed (priority upgrades)

=item message($_title, $msg): display a message (with a title for GUIes)

=back

=item signature management:

=over

=item pre_check_sig(): signature checking startup (for rpmdrake)

=item check_sig(): signature checking progress (for rpmdrake)

=item bad_signature($msg, $msg2): called when a package is not/badly signed

=back

=item removable media management:

=over

=item pre_removable(): called before handling removable media (for rpmdrake)

=item copy_removable($medium_name): called for asking inserting a CD/DVD

=item post_extract($set, $transaction_sources, $transaction_sources_install) called after handling removable media (for rpmdrake)

=back

=item packages installation callbacks (passed to urpm::install::install(), see L<URPM> for parameters)

=over

=item open_helper(): called when opening a package, must return a fd

=item close_helper(): called when package is closed

=item inst() called for package opening/progress/end

=item trans() called for transaction opening/progress/end

=item uninst(): called for erasure progress

=item error() called for cpio, script or unpacking errors

=back

=item finish callbacks (mainly GUI callbacks for rpmdrake/gurpmi/drakx)

=over

=item completed(): called when everything is completed (for cleanups)

=item trans_error_summary($nok, $errors) called to warn than $nok transactions failed with $errors messages

=item success_summary() called on success

=item already_installed_or_not_installable($msg1, $msg2)

=back

=back

=back

=cut


sub run {
    my ($urpm, $state, $something_was_to_be_done, $ask_unselect, $callbacks) = @_;

    #- global boolean options
    ($auto_select, $no_install, $install_src, $clean, $noclean, $force, $parallel, $test) =
      ($::auto_select, $::no_install, $::install_src, $::clean, $::noclean, $::force, $::parallel, $::test);

    urpm::get_pkgs::clean_all_cache($urpm) if $clean;

    my $options = $urpm->{options};

    my ($local_sources, $blists) = urpm::get_pkgs::selected2local_and_blists($urpm,
                                                                             $state->{selected},
                                                                             clean_other => !$noclean && $options->{'pre-clean'},
                                                                         );
    if (!$local_sources && !$blists) {
        $urpm->{fatal}(3, N("unable to get source packages, aborting"));
    }

    my %sources = %$local_sources;

    _handle_removable_media($urpm, $callbacks, $blists, \%sources);

    if (exists $options->{'download-all'}) {
        _download_all($urpm, $blists, \%sources, $callbacks);
    }

    #- now create transaction just before installation, this will save user impression of slowness.
    #- split of transaction should be disabled if --test is used.
    urpm::install::build_transaction_set_($urpm, $state,
                                          nodeps => $options->{'allow-nodeps'} || $options->{'allow-force'},
                                          keep => $options->{keep},
                                          split_level => $options->{'split-level'},
                                          split_length => !$test && $options->{'split-length'});

    if ($options{debug__do_not_install}) {
	$urpm->{debug} = sub { print STDERR "$_[0]\n" };
    }

    $urpm->{debug} and $urpm->{debug}(join("\n", "scheduled sets of transactions:", 
                                           urpm::install::transaction_set_to_string($urpm, $state->{transaction} || [])));

    $options{debug__do_not_install} and exit 0;

    ($ok, $nok) = (0, 0);
    my (@errors, @formatted_errors);
    $exit_code = 0;

    my $migrate_back_rpmdb_db_version = 
      $urpm->{root} && urpm::select::should_we_migrate_back_rpmdb_db_version($urpm, $state);

    #- now process each remove/install transaction
    foreach my $set (@{$state->{transaction} || []}) {

        #- put a blank line to separate with previous transaction or user question.
        $urpm->{print}("\n") if $options{verbose} >= 0;

        my ($transaction_blists, $transaction_sources) = 
          urpm::install::prepare_transaction($set, $blists, \%sources);

        #- first, filter out what is really needed to download for this small transaction.
        my ($error_sources, $msgs) = _download_packages($urpm, $callbacks, $transaction_blists, $transaction_sources);
        if (@$error_sources) {
            $nok++;
            last if !_continue_on_error($urpm, $callbacks, $msgs, $error_sources, \@formatted_errors);
        }

        $callbacks->{post_download} and $callbacks->{post_download}->();

        #- extract packages that should be installed instead of upgraded,
        my %transaction_sources_install = %{$urpm->extract_packages_to_install($transaction_sources) || {}};
        $callbacks->{post_extract} and $callbacks->{post_extract}->($set, $transaction_sources, \%transaction_sources_install);

        #- verify packages
        if (!$force && ($options->{'verify-rpm'} || grep { $_->{'verify-rpm'} } @{$urpm->{media}})) {
            my $res = _verify_rpm($urpm, $callbacks, \%transaction_sources_install, $transaction_sources);
            $res and return $res;
        }

        #- install source package only (whatever the user is root or not, but use rpm for that).
        if ($install_src) {
            _install_src($urpm, \%transaction_sources_install, $transaction_sources);
            next;
        }

        next if $no_install;

        #- clean to remove any src package now.
        clean_trans_sources_from_src_packages($urpm, \%transaction_sources_install, $transaction_sources);

        #- install/remove other packages
        if (keys(%transaction_sources_install) || keys(%$transaction_sources) || $set->{remove}) {
            if ($parallel) {
                _run_parallel_transaction($urpm, $state, $transaction_sources, \%transaction_sources_install);
            } else {
                if ($options{verbose} >= 0) {
                    _log_installing($urpm, \%transaction_sources_install, $transaction_sources);
                }
                bug_log(scalar localtime(), " ", join(' ', values %transaction_sources_install, values %$transaction_sources), "\n");

                _run_transaction($urpm, $state, $callbacks, $set, \%transaction_sources_install, $transaction_sources, \@errors)
                   or last;
            }
        }

        last if $callbacks->{is_canceled} && $callbacks->{is_canceled}->();
    }

    #- migrate the chrooted rpmdb if needed
    if ($migrate_back_rpmdb_db_version) {
        urpm::sys::migrate_back_rpmdb_db_version($urpm, $urpm->{root});
    }

    $callbacks->{completed} and $callbacks->{completed}->();

    _finish($urpm, $state, $callbacks, \@errors, \@formatted_errors, $ask_unselect, $something_was_to_be_done);

    $exit_code;
}

sub _finish {
    my ($urpm, $state, $callbacks, $errors, $formatted_errors, $ask_unselect, $something_was_to_be_done) = @_;

    if ($nok) {
        $callbacks->{trans_error_summary} and $callbacks->{trans_error_summary}->($nok, $errors);
        if (@$formatted_errors) {
            $urpm->{print}(join("\n", @$formatted_errors));
        }
        if (@$errors) {
            $urpm->{print}(N("Installation failed:") . join("\n", map { "\t$_" } @$errors));
        }
        $exit_code ||= $ok ? 11 : 12;
    } else {
        $callbacks->{success_summary} and $callbacks->{success_summary}->();
        if ($something_was_to_be_done || $auto_select) {
            if (@{$state->{transaction} || []} == 0 && @$ask_unselect == 0) {
                if ($auto_select) {
                    if ($options{verbose} >= 0) {
                        #- Warning : the following message is parsed in urpm::parallel_*
                        $urpm->{print}(N("Packages are up to date"));
                    }
                } else {
                    if ($callbacks->{already_installed_or_not_installable}) {
                        my $msg = urpm::select::translate_already_installed($state);
                        $callbacks->{already_installed_or_not_installable}->([$msg], []);
                    }
                }
                $exit_code = 15 if our $expect_install;
            } elsif ($test && $exit_code == 0) {
                #- Warning : the following message is parsed in urpm::parallel_*
                print N("Installation is possible"), "\n";
            } else {
                handle_need_restart($urpm, $state, $callbacks);
            }
        }
    }
    $exit_code;
}

sub handle_need_restart {
    my ($urpm, $state, $callbacks) = @_;

    return if $urpm->{root} && !$ENV{URPMI_TEST_RESTART};
    return if !$callbacks->{need_restart};

    if (intersection([ keys %{$state->{selected}} ],
                     [ keys %{$urpm->{provides}{'should-restart'}} ])) {
        if (my $need_restart_formatted = urpm::sys::need_restart_formatted($urpm->{root})) {
            $callbacks->{need_restart}($need_restart_formatted);

            # need_restart() accesses rpm db, so we need to ensure things are clean:
            urpm::sys::may_clean_rpmdb_shared_regions($urpm, $options{test});
        }
    }
}

1;

=back

=head1 COPYRIGHT

Copyright (C) 1999-2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut

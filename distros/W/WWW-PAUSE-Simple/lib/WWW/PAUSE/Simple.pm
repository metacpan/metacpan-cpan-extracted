package WWW::PAUSE::Simple;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Object;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       upload_file
                       list_files
                       delete_files
                       undelete_files
                       reindex_files
                       list_dists
                       delete_old_releases
                       set_password
                       set_account_info
               );

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-12'; # DATE
our $DIST = 'WWW-PAUSE-Simple'; # DIST
our $VERSION = '0.456'; # VERSION

our %SPEC;
my $access_log = Log::ger->get_logger(category => "_access");

our $re_archive_ext = qr/(?:tar|tar\.(?:Z|gz|bz2|xz)|zip|rar)/;

sub _access_log {
    my ($args, $action, $obj, $description) = @_;
    $access_log->info({
        time => time(),
        username => $args->{username},
        action => $action,
        object => $obj,
        description => $description,
    });
}

our %common_args = (
    username => {
        summary => 'PAUSE ID',
        schema  => ['str*', match=>'\A\w{2,9}\z', max_len=>9], # see also: Regexp::Pattern::CPAN
        description => <<'_',

If unset, default value will be searched from `~/.pause`. Encrypted `.pause` is
not yet supported.

_
        tags    => ['common'],
    },
    password => {
        summary => 'PAUSE password',
        schema  => 'str*',
        description => <<'_',

If unset, default value will be searched from `~/.pause`. Encrypted `.pause` is
not yet supported.

_
        is_password => 1,
        tags    => ['common'],
    },
    # 2016-07-13 - for a few months now, PAUSE has been giving random 500 errors
    # when uploading. i'm defaulting to a retries=2.
    # 2017-06-28 - increase default to retries=7.
    # 2017-06-28 - tune down retries to 5.
    # 2019-06-05 - now uses exponential backoff, increase retries to 35 to try
    #              for a little over a day
    # 2019-11-14 - PAUSE is now ok, tune down retries to 5
    retries => {
        summary => 'Number of retries when received 5xx HTTP error from server',
        description => <<'_',

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

_
        schema  => 'int*',
        default => 5,
        tags    => ['common'],
    },
);

our %detail_arg = (
    detail => {
        summary => 'Whether to return detailed records',
        schema  => 'bool',
    },
);

our %detail_l_arg = (
    detail => {
        summary => 'Whether to return detailed records',
        schema  => 'bool',
        cmdline_aliases => {l=>{}},
    },
);

our %files_arg = (
    files => {
        summary => 'File names/wildcard patterns',
        'summary.alt.plurality.singular' => 'File name/wildcard pattern',
        schema  => ['array*', of=>'str*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

our %file_opt_arg = (
    files => {
        summary => 'File names/wildcard patterns',
        'summary.alt.plurality.singular' => 'File name/wildcard pattern',
        schema  => ['array*', of=>'str*'],
        'x.name.is_plural' => 1,
        pos => 0,
        greedy => 1,
        tags => ['category:filtering'],
    },
);

our %mod_opt_arg = (
    modules => {
        summary => 'Module names/wildcard patterns',
        'summary.alt.plurality.singular' => 'Module name/wildcard pattern',
        schema  => ['array*', of=>'str*'],
        'x.name.is_plural' => 1,
        pos => 0,
        greedy => 1,
        tags => ['category:filtering'],
    },
);

our %protect_files_arg = (
    protect_files => {
        summary => 'Protect some files/wildcard patterns from delete/cleanup',
        schema  => ['array*', of=>'str*'],
        'x.name.is_plural' => 1,
        tags => ['category:filtering'],
    },
);

our %argspecsopt_filter_dev = (
    include_nondev => {
        summary => 'Whether to include cleaning up non-dev releases',
        schema => 'bool*',
        default => 1,
    },
    include_dev => {
        summary => 'Whether to include cleaning up non-dev releases',
        schema => 'bool*',
        default => 0,
    },
);

our %argspecsopt_filter_dists = (
    include_dists => {
        summary => 'Only include specified distributions',
        "x.name.is_plural" => 1,
        "x.name.singular" => "include_dist",
        schema => ['array*', of=>'str*'], # XXX perl::distname
    },
    exclude_dists => {
        summary => 'Exclude specified distributions',
        "x.name.is_plural" => 1,
        "x.name.singular" => "exclude_dist",
        schema => ['array*', of=>'str*'], # XXX perl::distname
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'An API for PAUSE',
};

sub _parse_release_filename {
    my $filename = shift;
    ## no critic: Subroutines::ProhibitExplicitReturnUndef
    return undef unless
        $filename =~ /\A
                      (\w+(?:-\w+)*)
                      -v?(\d+(?:\.\d+){0,}(_\d+|-TRIAL)?)
                      \.$re_archive_ext
                      \z/ix;
    return ($1, $2, $3); # (dist, version, is_dev)
}

sub _common_args {
    my $args = shift;
    (username=>$args->{username}, password=>$args->{password});
}

sub _request {
    require HTTP::Request::Common;

    state $deprecation_warned = 0;

    my %args = @_;
    # XXX schema
    $args{retries} //= 5;
    my $strategy;
    require Algorithm::Backoff::Exponential;
    $strategy = Algorithm::Backoff::Exponential->new(
        max_attempts  => $args{retries},
        initial_delay => 3,
        max_delay     => 3600,
    );

    # set default for username and password from ~/.pause
    my $username = $args{username};
    my $password = $args{password};
    {
        last if defined $username && defined $password;
        my $path = "$ENV{HOME}/.pause";
        last unless -f $path;
        open my($fh), "<", $path or last;
        while (defined(my $line = <$fh>)) {
            if ($line =~ /^user\s+(.+)/) { $username //= $1 }
            elsif ($line =~ /^password\s+(.+)/) { $password //= $1 }
        }
        unless (defined $username && defined $password) {
            die "Please specify username/password\n";
        }
    }

    state $ua = do {
        require LWP::UserAgent;
        LWP::UserAgent->new;
    };
    my $url = "https://pause.perl.org/pause/authenquery";
    my $req = HTTP::Request::Common::POST($url, @{ $args{post_data} });
    $req->authorization_basic($username, $password);

    my $tries = 0;
    my $resp;
  RETRY:
    while (1) {
        $resp = $ua->request($req);
        if ($resp->code =~ /^[5]/) {
            $tries++;
            my $delay = $strategy->failure;
            log_warn("Got error %s (%s) from server when POST-ing to %s%s, retrying (%d/%d) in %d second(s) ...",
                     $resp->code, $resp->message,
                     $url,
                     $args{note} ? " ($args{note})" : "",
                     $tries, $args{retries}, $delay);
            sleep $delay;
            next;
        }
        last;
    }
    $resp;
}

sub _htres2envres {
    my $res = shift;
    [$res->code, $res->message, $res->content];
}

$SPEC{upload_files} = {
    v => 1.1,
    summary => 'Upload file(s)',
    args_rels => {
        choose_one => [qw/delay/],
    },
    args => {
        %common_args,
        %files_arg,
        subdir => {
            summary => 'Subdirectory to put the file(s) into',
            schema  => 'str*',
            default => '',
        },
        delay => {
            summary => 'Pause a number of seconds between files',
            schema => ['duration*'],
            description => <<'_',

If you upload a lot of files (e.g. 7-10 or more) at a time, the PAUSE indexer
currently might choke with SQLite database locking problem and thus fail to
index your releases. Giving a delay of say 2-3 minutes (120-180 seconds) between
files will alleviate this problem.

_
        },
    },
    features => {dry_run=>1},
};
sub upload_files {
    require File::Basename;

    my %args = @_;
    my $files = $args{files}
        or return [400, "Please specify at least one file"];
    my $subdir = $args{subdir} // '';

    my $envres = envresmulti();

    my $i = 0;
    my $prev_group = 0;
    for my $file (@$files) {
        my $basename = File::Basename::basename($file);
        my $res;
        {
            unless (-f $file) {
                $res = [404, "No such file"];
                last;
            }

            if ($args{-dry_run}) {
                log_trace("[dry-run] (%d/%d) Uploading %s ...", $i+1, scalar(@$files), $file);
                goto DELAY;
            }

            log_trace("(%d/%d) Uploading %s ...", $i+1, scalar(@$files), $file);
            my $httpres = _request(
                note => "upload $file",
                %args,
                post_data => [
                    Content_Type => 'form-data',
                    Content => {
                        HIDDENNAME                        => $args{username},
                        CAN_MULTIPART                     => 0,
                        pause99_add_uri_upload            => $basename,
                        SUBMIT_pause99_add_uri_httpupload => " Upload this file from my disk ",
                        pause99_add_uri_uri               => "",
                        pause99_add_uri_httpupload        => [$file],
                        (length($subdir) ? (pause99_add_uri_subdirtext => $subdir) : ()),
                    },
                ]
            );
            if (!$httpres->is_success) {
                $res = _htres2envres($httpres);
                last;
            }
            $res = [200, "OK"];
        }
        $res->[3] //= {};
        $res->[3]{item_id} = $file;
        log_trace("Result of upload: %s", $res);
        if ($res->[0] =~ /^2/) {
            _access_log(\%args, upload => {name=>$basename, size=>(-s $file), subdir=>$subdir});
        } else {
            log_warn("Upload of %s failed: %s - %s", $file, $res->[0], $res->[1])
        }
        $envres->add_result($res->[0], $res->[1], $res->[3]);

      DELAY:
        {
            # it's the last file, no point in delaying, just exit
            last if ++$i >= @$files;
            if ($args{delay}) {
                log_trace("Sleeping between files for %d second(s) ...", $args{delay});
                sleep $args{delay};
                last;
            }
        }
    }
    $envres->as_struct;
}

$SPEC{list_files} = {
    v => 1.1,
    summary => 'List files',
    args => {
        %common_args,
        %detail_l_arg,
        %file_opt_arg,
        del => {
            summary => 'Only list files which are scheduled for deletion',
            'summary.alt.bool.not' => 'Only list files which are not scheduled for deletion',
            schema => 'bool',
            tags => ['category:filtering'],
        },
        size_min => {
            #schema => 'filesize*',
            schema => 'uint*',
            tags => ['category:filtering'],
        },
        size_max => {
            #schema => 'filesize*',
            schema => 'uint*',
            tags => ['category:filtering'],
        },
        mtime_min => {
            schema => ['date*', 'x.perl.coerce_to'=>'float(epoch)'],
            tags => ['category:filtering'],
        },
        mtime_max => {
            schema => ['date*', 'x.perl.coerce_to'=>'float(epoch)'],
            tags => ['category:filtering'],
        },
    },
};
sub list_files {
    require Date::Parse;
    require Regexp::Wildcards;
    require String::Wildcard::Bash;

    my %args  = @_;
    my $q   = $args{files} // [];
    my $del = $args{del};

    my $httpres = _request(
        note => "list files",
        %args,
        post_data => [{ACTION=>'show_files'}],
    );

    # convert wildcard patterns in arguments to regexp
    $q = [@$q];
    for (@$q) {
        next unless String::Wildcard::Bash::contains_wildcard($_);
        my $re = Regexp::Wildcards->new(type=>'unix')->convert($_);
        $re = qr/\A($re)\z/;
        $_ = $re;
    }

    return _htres2envres($httpres) unless $httpres->is_success;
    return [543, "Can't scrape list of files from response",
            $httpres->content]
        unless $httpres->content =~ m!<h3>Files in directory.+<tbody[^>]*>(.+)</tbody>!s;
    my $str = $1;
    my @files;
  REC:
    while ($str =~ m!<td class="file">(.+?)</td>\s+<td class="size">(.+?)</td>\s+<td class="modified">(.+?)</td>!gs) {
        my $rec = {
            name => $1,
            size => $2,
        };
        my $time0 = $3;
        if ($time0 =~ s/^Scheduled for deletion \(due at //) {
            $rec->{is_scheduled_for_deletion} = 1;
            $time0 =~ s/\)$//;
        }
        my $time = Date::Parse::str2time($time0, "UTC");
        if ($rec->{is_scheduled_for_deletion}) {
            $rec->{deletion_time} = $time;
        } else {
            $rec->{mtime} = $time;
        }

        # filter by requested file/wildcard
      FILTER_QUERY:
        {
            last unless @$q;
            for (@$q) {
                if (ref($_) eq 'Regexp') {
                    last FILTER_QUERY if $rec->{name} =~ $_;
                } else {
                    last FILTER_QUERY if $rec->{name} eq $_;
                }
            }
            # nothing matches
            next REC;
        }

      FILTER_SIZE:
        {
            next REC if defined $args{size_min} &&
                $rec->{size} < $args{size_min};
            next REC if defined $args{size_max} &&
                $rec->{size} > $args{size_max};
        }

      FILTER_MTIME:
        {
            next REC if defined $args{mtime_min} &&
                $rec->{mtime} < $args{mtime_min};
            next REC if defined $args{mtime_max} &&
                $rec->{mtime} > $args{mtime_max};
        }

      FILTER_DEL:
        {
            if (defined $del) {
                next REC if $del xor $rec->{is_scheduled_for_deletion};
            }
        }

        push @files, $args{detail} ? $rec : $rec->{name};

    }
    my %resmeta;
    if ($args{detail}) {
        $resmeta{'table.fields'} =
            [qw/name size mtime is_scheduled_for_deletion deletion_time/];
        $resmeta{'table.field_formats'} =
            [undef, undef, 'iso8601_datetime', undef, 'iso8601_datetime'];
    }
    [200, "OK", \@files, \%resmeta];
}

$SPEC{list_dists} = {
    v => 1.1,
    summary => 'List distributions',
    description => <<'_',

Distribution names will be extracted from tarball/zip filenames.

Unknown/unparseable filenames will be skipped.

_
    args => {
        %common_args,
        %detail_l_arg,
        newest => {
            schema => 'bool',
            summary => 'Only show newest non-dev version',
            description => <<'_',

Dev versions will be skipped.

_
        },
        newest_n => {
            schema => ['int*', min=>1],
            summary => 'Only show this number of newest versions',
            description => <<'_',

Dev versions will be skipped.

_
        },
        %argspecsopt_filter_dists,
        %argspecsopt_filter_dev,
    },
};
sub list_dists {
    require List::MoreUtils;

    my %args  = @_;

    my $res = list_files(_common_args(\%args), del=>0);
    return [500, "Can't list files: $res->[0] - $res->[1]"] if $res->[0] != 200;

    my $newest_n;
    if ($args{newest_n}) {
        $newest_n = $args{newest_n};
    } elsif ($args{newest}) {
        $newest_n = 1;
    }
    my $include_dev = $args{include_dev};
    my $include_nondev = $args{include_nondev} // 1;

    my @distrecs;
    for my $file (@{$res->[2]}) {
        if ($file =~ m!/!) {
            log_debug("Skipping %s: under a subdirectory", $file);
            next;
        }
        my ($distname, $version0, $dev) = _parse_release_filename($file);
        unless (defined $distname) {
            log_debug("Skipping %s: doesn't match release regex", $file);
            next;
        }
        if ($args{include_dists} && @{$args{include_dists}} && !(grep {$distname eq $_} @{$args{include_dists}})) {
            log_trace("Skipping %s: Distribution %s not in include_dists", $file, $distname);
            next;
        }
        if ($args{exclude_dists} && @{$args{exclude_dists}} &&  (grep {$distname eq $_} @{$args{exclude_dists}})) {
            log_trace("Skipping %s: Distribution %s in exclude_dists", $file, $distname);
            next;
        }

        next if $newest_n && (($dev && !$include_dev) || (!$dev && !$include_nondev));
        (my $version = $version0) =~ s/-TRIAL$/_001/;
        push @distrecs, {
            name => $distname,
            file => $file,
            version0 => $version0,
            version => $version,
        };
    } # for my $file

    my @old_files;
    if ($newest_n) {
        my %dist_versions;
        for my $distrec (@distrecs) {
            push @{ $dist_versions{$distrec->{name}} }, $distrec->{version};
        }
        for my $distname (keys %dist_versions) {
            $dist_versions{$distname} = [
                sort { version->parse($b) <=> version->parse($a) }
                    @{ $dist_versions{$distname} }];
            if (@{ $dist_versions{$distname} } > $newest_n) {
                $dist_versions{$distname} = [splice(
                    @{ $dist_versions{$distname} }, 0, $newest_n)];
            }
        }
        my @old_distrecs = @distrecs;
        @distrecs = ();
        my %dist_seen;
        for my $distrec (@old_distrecs) {
            log_trace "Distribution %s: Keeping these newest versions: %s", $distrec->{name}, $dist_versions{$distrec->{name}}
                unless $dist_seen{$distrec->{name}};
            if (grep { $_ eq $distrec->{version} } @{ $dist_versions{$distrec->{name}} }) {
                push @distrecs, $distrec;
            } else {
                push @old_files, $distrec->{file};
            }
        }
    }

    my @distnames;
    unless ($args{detail}) {
        @distnames = List::MoreUtils::uniq(map { $_->{name} } @distrecs);
    }

    my %resmeta;
    if ($newest_n) {
        $resmeta{"func.old_files"} = \@old_files;
    }
    if ($args{detail}) {
        $resmeta{'table.fields'} = [qw/name version is_dev_version file/];
    }
    [200, "OK", ($args{detail} ? \@distrecs : \@distnames), \%resmeta];
}

$SPEC{delete_old_releases} = {
    v => 1.1,
    summary => 'Delete older versions of distributions',
    description => <<'_',

Currently does not look for releases in subdirectories.

By default does not include developer (trial) releases. To include that, use
`--include-dev`.

To only cleanup developer releases, you can use `--include-dev` and
`--exclude-nondev`.

_
    args => {
        %common_args,
        %detail_l_arg,
        %protect_files_arg,
        %argspecsopt_filter_dists,
        %argspecsopt_filter_dev,
        num_keep => {
            schema => ['int*', min=>1],
            default => 1,
            summary => 'Number of new versions (including newest) to keep',
            cmdline_aliases => { n=>{} },
            description => <<'_',

1 means to only keep the newest version, 2 means to keep the newest and the
second newest, and so on.

_
        },
    },
    features => {dry_run=>1},
};
sub delete_old_releases {
    my %args = @_;

    my $res = list_dists(
        _common_args(\%args),
        newest_n=>$args{num_keep}//1,
        include_dev=>$args{include_dev},
        include_nondev=>$args{include_nondev},
        include_dists=>$args{include_dists},
        exclude_dists=>$args{exclude_dists},
    );
    return [500, "Can't list dists: $res->[0] - $res->[1]"] if $res->[0] != 200;
    my $old_files = $res->[3]{'func.old_files'};

    return [304, "No older releases", undef,
            {'cmdline.result'=>'There are no older releases to delete'}]
        unless @$old_files;
    my @to_delete;
    for my $file (@$old_files) {
        $file =~ s/\.$re_archive_ext\z//;
        push @to_delete, "$file.*";
    }
    $res = delete_files(
        _common_args(\%args),
        protect_files => $args{protect_files},
        files=>\@to_delete,
        -dry_run=>$args{-dry_run},
    );
    return $res if $res->[0] != 200 || $args{-dry_run};
    my $deleted_files = $res->[3]{'func.files'} // [];
    if (@$deleted_files) {
        $res->[3]{'cmdline.result'} = $deleted_files;
    } else {
        $res->[3]{'cmdline.result'} = 'Deleted 0 files';
    }
    $res;
}

sub _delete_or_undelete_or_reindex_files {
    require Regexp::Wildcards;
    require String::Wildcard::Bash;

    my $which = shift;
    my %args = @_;

    # to supply to pause server
    my $action;
    if ($which eq 'delete') {
        $action = 'delete_files';
    } elsif ($which eq 'undelete') {
        $action = 'delete_files'; # sic
    } elsif ($which eq 'reindex') {
        $action = 'reindex';
    } else {
        die "BUG: undefined action";
    }

    my $files0 = $args{files} // [];
    return [400, "Please specify at least one file"] unless @$files0;

    my $protect_files = $args{protect_files} // [];

    my @files;
    {
        my $listres;
        if (grep {String::Wildcard::Bash::contains_wildcard($_)}
            (@$files0, @$protect_files)) {

            if ($which eq 'delete' && (grep {$_ =~ /\A\*\.?/} @$files0)) {
                log_warn "Please make sure that you really want to delete ALL/many files using the '*' wildcard! ".
                    "Delaying 10s to give you chance to cancel (Ctrl-C on the terminal) ...";
                sleep 10;
                log_warn "Continuing ...";
            } elsif ($which eq 'reindex' && (grep {$_ =~ /\A\*(z|\.?gz|\.?tar\.gz)?\z/} @$files0)) {
                log_warn "Please make sure that you really want to reindex ALL files or ALL tarballs! ".
                    "If you want to fix certain distributions that are missing from the index, ".
                    "you should reindex just those distribution files. ".
                    "Delaying 10s to give you chance to cancel (Ctrl-C on the terminal) ...";
                sleep 10;
                log_warn "Continuing ...";
            }

            $listres = list_files(_common_args(\%args));
            return [500, "Can't list files: $listres->[0] - $listres->[1]"]
                unless $listres->[0] == 200;
        }

        for my $file (@$files0) {
            if (String::Wildcard::Bash::contains_wildcard($file)) {
                my $re = Regexp::Wildcards->new(type=>'unix')->convert($file);
                $re = qr/\A($re)\z/;
                for my $f (@{$listres->[2]}) {
                    push @files, $f if $f =~ $re && !(grep { $_ eq $f } @files);
                }
            } else {
                push @files, $file;
            }
        }

        for my $protect_file (@$protect_files) {
            if (String::Wildcard::Bash::contains_wildcard($protect_file)) {
                my $re = Regexp::Wildcards->new(type=>'unix')->convert(
                    $protect_file);
                $re = qr/\A($re)\z/;
                @files = grep {
                    if ($_ =~ $re) {
                        log_debug("Excluding %s (protected, wildcard %s)",
                                  $_, $protect_file);
                        0;
                    } else {
                        1;
                    }
                } @files;
            } else {
                @files = grep {
                    if ($_ eq $protect_file) {
                        log_debug("Excluding %s (protected)", $_);
                        0;
                    } else {
                        1;
                    }
                } @files;
            }
        }
    }

    unless (@files) {
        return [304, "No files to process"];
    }

    if ($args{-dry_run}) {
        log_warn("[dry-run] %s %s", $which, \@files);
        return [200, "OK (dry-run)"];
    } else {
        log_info("%s %s ...", $which, \@files);
    }

    my $httpres = _request(
        note => "$which files",
        %args,
        post_data => [
            [
                ACTION => $action,
                HIDDENNAME                => $args{username},
                ($which eq 'delete'   ? (SUBMIT_pause99_delete_files_delete   => "Delete"  ) : ()),
                ($which eq 'undelete' ? (SUBMIT_pause99_delete_files_undelete => "Undelete") : ()),
                ($which eq 'reindex'  ? (SUBMIT_pause99_reindex_delete        => "Reindex" ) : ()),
                ($which =~ /delete/   ? (pause99_delete_files_FILE => \@files) : ()),
                ($which eq 'reindex'  ? (pause99_reindex_FILE => \@files) : ()),
            ],
        ],
    );
    return _htres2envres($httpres) unless $httpres->is_success;
    _access_log(\%args, $which => {files=>\@files}) if $which =~ /delete|undelete/;
    [200,"OK", undef, {'func.files'=>\@files}];
}

$SPEC{delete_files} = {
    v => 1.1,
    summary => 'Delete files',
    description => <<'_',

When a file is deleted, it is not immediately deleted but has
scheduled_for_deletion status for 72 hours, then deleted. During that time, the
file can be undeleted.

_
    args => {
        %common_args,
        %files_arg,
        %protect_files_arg,
    },
    features => {dry_run=>1},
};
sub delete_files {
    my %args = @_; # only for DZP::Rinci::Wrap
    _delete_or_undelete_or_reindex_files('delete', @_);
}

$SPEC{undelete_files} = {
    v => 1.1,
    summary => 'Undelete files',
    description => <<'_',

When a file is deleted, it is not immediately deleted but has
scheduled_for_deletion status for 72 hours, then deleted. During that time, the
file can be undeleted.

_
    args => {
        %common_args,
        %files_arg,
    },
    features => {dry_run=>1},
};
sub undelete_files {
    my %args = @_; # only for DZP::Rinci::Wrap
    _delete_or_undelete_or_reindex_files('undelete', @_);
}

$SPEC{reindex_files} = {
    v => 1.1,
    summary => 'Force reindexing',
    args => {
        %common_args,
        %files_arg,
    },
    features => {dry_run=>1},
};
sub reindex_files {
    my %args = @_; # only for DZP::Rinci::Wrap
    _delete_or_undelete_or_reindex_files('reindex', @_);
}

$SPEC{set_password} = {
    v => 1.1,
    args => {
        %common_args,
    },
    'x.no_index' => 1,
};
sub set_password {
    my %args = @_;
    [501, "Not yet implemented"];
}

$SPEC{set_account_info} = {
    v => 1.1,
    args => {
        %common_args,
    },
    'x.no_index' => 1,
};
sub set_account_info {
    my %args = @_;
    [501, "Not yet implemented"];
}

$SPEC{list_modules} = {
    v => 1.1,
    summary => 'List modules (permissions)',
    args => {
        %common_args,
        %detail_l_arg,
        %mod_opt_arg,
        type => {
            summary => 'Only list modules matching certain type',
            schema => 'str*',
            tags => ['category:filtering'],
        },
    },
};
sub list_modules {
    my %args  = @_;
    require Regexp::Wildcards;
    require String::Wildcard::Bash;

    my $q = $args{modules} // [];

    my %post_data = (ACTION=>'peek_perms');

    # optimize: the PAUSE server can do SQL LIKE, if there is only a single
    # module argument we pass it to server to reduce traffic
    if (@$q == 1) {
        $post_data{pause99_peek_perms_by} = 'ml';
        $post_data{pause99_peek_perms_query} =
            String::Wildcard::Bash::convert_wildcard_to_sql($q->[0]);
        $post_data{pause99_peek_perms_sub} = 'Submit';
    }

    my $httpres = _request(
        %args,
        note => "list modules",
        post_data => [\%post_data],
    );

    return _htres2envres($httpres) unless $httpres->is_success;

    # convert wildcard patterns in arguments to regexp
    for (@$q) {
        next unless String::Wildcard::Bash::contains_wildcard($_);
        my $re = Regexp::Wildcards->new(type=>'unix')->convert($_);
        $re = qr/\A($re)\z/;
        $_ = $re;
    }

    my @mods;
    goto NO_MODS if $httpres->content =~ /No records found/;
    return [543, "Can't scrape list of modules from response",
            $httpres->content]
        unless $httpres->content =~ m!<th[^>]*>module</th>.+?<tbody[^>]*>(.+?)</tbody>!s;
    my $str = $1;

  REC:
    while ($str =~ m!<tr>\s*
                     <td\sclass="module"><a[^>]+>(.+?)</a></td>\s*
                     <td\sclass="userid"><a[^>]+>(.+?)</a></td>\s*
                     <td\sclass="type">(.+?)</td>\s*
                     <td\sclass="owner">(.*?)</td>\s*
                     </tr>!gsx) {
        my $rec = {module=>$1, userid=>$2, type=>$3, owner=>$4};

        # filter by requested file/wildcard
      FILTER_QUERY:
        {
            last unless @$q > 1;
            for (@$q) {
                if (ref($_) eq 'Regexp') {
                    last FILTER_QUERY if $rec->{module} =~ $_;
                } else {
                    last FILTER_QUERY if $rec->{module} eq $_;
                }
            }
            # nothing matches
            next REC;
        }

      FILTER_TYPE:
        if ($args{type}) {
            next REC unless $rec->{type} eq $args{type};
        }

        push @mods, $args{detail} ? $rec : $rec->{module};
    }

  NO_MODS:

    my %resmeta;
    if ($args{detail}) {
        $resmeta{'table.fields'} =[qw/module userid type owner/];
    }
    [200, "OK", \@mods, \%resmeta];
}

1;
# ABSTRACT: An API for PAUSE

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PAUSE::Simple - An API for PAUSE

=head1 VERSION

This document describes version 0.456 of WWW::PAUSE::Simple (from Perl distribution WWW-PAUSE-Simple), released on 2023-07-12.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides several functions for performing common tasks on PAUSE.
There is also a CLI script L<pause> distributed separately in L<App::pause>.

=head1 FUNCTIONS


=head2 delete_files

Usage:

 delete_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Delete files.

When a file is deleted, it is not immediately deleted but has
scheduled_for_deletion status for 72 hours, then deleted. During that time, the
file can be undeleted.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

File namesE<sol>wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<protect_files> => I<array[str]>

Protect some filesE<sol>wildcard patterns from deleteE<sol>cleanup.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 delete_old_releases

Usage:

 delete_old_releases(%args) -> [$status_code, $reason, $payload, \%result_meta]

Delete older versions of distributions.

Currently does not look for releases in subdirectories.

By default does not include developer (trial) releases. To include that, use
C<--include-dev>.

To only cleanup developer releases, you can use C<--include-dev> and
C<--exclude-nondev>.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<exclude_dists> => I<array[str]>

Exclude specified distributions.

=item * B<include_dev> => I<bool> (default: 0)

Whether to include cleaning up non-dev releases.

=item * B<include_dists> => I<array[str]>

Only include specified distributions.

=item * B<include_nondev> => I<bool> (default: 1)

Whether to include cleaning up non-dev releases.

=item * B<num_keep> => I<int> (default: 1)

Number of new versions (including newest) to keep.

1 means to only keep the newest version, 2 means to keep the newest and the
second newest, and so on.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<protect_files> => I<array[str]>

Protect some filesE<sol>wildcard patterns from deleteE<sol>cleanup.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_dists

Usage:

 list_dists(%args) -> [$status_code, $reason, $payload, \%result_meta]

List distributions.

Distribution names will be extracted from tarball/zip filenames.

Unknown/unparseable filenames will be skipped.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<exclude_dists> => I<array[str]>

Exclude specified distributions.

=item * B<include_dev> => I<bool> (default: 0)

Whether to include cleaning up non-dev releases.

=item * B<include_dists> => I<array[str]>

Only include specified distributions.

=item * B<include_nondev> => I<bool> (default: 1)

Whether to include cleaning up non-dev releases.

=item * B<newest> => I<bool>

Only show newest non-dev version.

Dev versions will be skipped.

=item * B<newest_n> => I<int>

Only show this number of newest versions.

Dev versions will be skipped.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_files

Usage:

 list_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

List files.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<del> => I<bool>

Only list files which are scheduled for deletion.

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<files> => I<array[str]>

File namesE<sol>wildcard patterns.

=item * B<mtime_max> => I<date>

(No description)

=item * B<mtime_min> => I<date>

(No description)

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<size_max> => I<uint>

(No description)

=item * B<size_min> => I<uint>

(No description)

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_modules

Usage:

 list_modules(%args) -> [$status_code, $reason, $payload, \%result_meta]

List modules (permissions).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<modules> => I<array[str]>

Module namesE<sol>wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<type> => I<str>

Only list modules matching certain type.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 reindex_files

Usage:

 reindex_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Force reindexing.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

File namesE<sol>wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 undelete_files

Usage:

 undelete_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Undelete files.

When a file is deleted, it is not immediately deleted but has
scheduled_for_deletion status for 72 hours, then deleted. During that time, the
file can be undeleted.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

File namesE<sol>wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 upload_files

Usage:

 upload_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Upload file(s).

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<delay> => I<duration>

Pause a number of seconds between files.

If you upload a lot of files (e.g. 7-10 or more) at a time, the PAUSE indexer
currently might choke with SQLite database locking problem and thus fail to
index your releases. Giving a delay of say 2-3 minutes (120-180 seconds) between
files will alleviate this problem.

=item * B<files>* => I<array[str]>

File namesE<sol>wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 5)

Number of retries when received 5xx HTTP error from server.

The retry uses an exponential backoff strategy of delaying 3, 6, 12, 24, ...,
3600, 3600, ... seconds.

=item * B<subdir> => I<str> (default: "")

Subdirectory to put the file(s) into.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage ^(upload_file|set_account_info|set_password)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WWW-PAUSE-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WWW-PAUSE-Simple>.

=head1 SEE ALSO

L<CPAN::Uploader> which also does uploading from CLI.

L<WWW::PAUSE::CleanUpHomeDir> which can clean old releases from your PAUSE
account (CLI script is provided in example).

L<App::PAUSE::cleanup> which also cleans old releases from your PAUSE account,
with CLI included L<pause-cleanup>.

L<https://perlancar.wordpress.com/2015/03/25/interacting-with-pause-using-cli/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-PAUSE-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

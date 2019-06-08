package WWW::PAUSE::Simple;

our $DATE = '2019-06-05'; # DATE
our $VERSION = '0.444'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

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

use Perinci::Object;

our %SPEC;

our $re_archive_ext = qr/(?:tar|tar\.(?:Z|gz|bz2|xz)|zip|rar)/;

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
    # 2017-06-28 - tone down retries to 5.
    # 2019-06-05 - now uses exponential backoff, increase retries to 35 to try
    #              for a little over a day
    retries => {
        summary => 'Number of retries when received 5xx HTTP error from server',
        schema  => 'int*',
        default => 35,
        tags    => ['common'],
    },
    retry_delay => {
        summary => 'How long to wait before retrying (deprecated)',
        schema  => 'duration*',
        tags    => ['common', 'deprecated'],
        description => <<'_',

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default `retries` of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via `retry_max_delay`.

_
    },
    retry_max_delay => {
        summary => 'How long to wait at most before retrying',
        schema  => 'duration*',
        default => 3600,
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

$SPEC{':package'} = {
    v => 1.1,
    summary => 'An API for PAUSE',
};

sub _parse_release_filename {
    my $filename = shift;
    return undef unless
        $filename =~ /\A
                      (\w+(?:-\w+)*)
                      -v?(\d+(?:\.\d+){0,2}(_\d+|-TRIAL)?)
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
    $args{retries} //= 35;
    if (defined $args{retry_delay}) {
        warn "retry_delay setting is deprecated, please use retry_max_delay from now on\n"
            unless $deprecation_warned++;
    } else {
        $args{retry_delay} = 3;
    }
    $args{retry_max_delay} //= 3600;

    my $strategy;
    if (defined $args{retry_delay}) {
        require Algorithm::Backoff::Constant;
        $strategy = Algorithm::Backoff::Constant->new(
            max_attempts  => $args{retries},
            delay         => $args{retry_delay},
        );
    } else {
        require Algorithm::Backoff::Exponential;
        $strategy = Algorithm::Backoff::Exponential->new(
            max_attempts  => $args{retries},
            initial_delay => 3,
            max_delay     => $args{retry_max_delay},
        );
    }

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
        my $res;
        {
            unless (-f $file) {
                $res = [404, "No such file"];
                last;
            }

            if ($args{-dry_run}) {
                log_trace("[dry-run] (%d/%d) Uploading %s ...", $i+1, ~~@$files, $file);
                goto DELAY;
            }

            log_trace("(%d/%d) Uploading %s ...", $i+1, ~~@$files, $file);
            my $httpres = _request(
                note => "upload $file",
                %args,
                post_data => [
                    Content_Type => 'form-data',
                    Content => {
                        HIDDENNAME                        => $args{username},
                        CAN_MULTIPART                     => 0,
                        pause99_add_uri_upload            => File::Basename::basename($file),
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
        log_warn("Upload of %s failed: %s - %s", $file, $res->[0], $res->[1])
            if $res->[0] !~ /^2/;
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
            summary => 'Only show this number of newest non-dev versions',
            description => <<'_',

Dev versions will be skipped.

_
        },
    },
};
sub list_dists {
    require List::MoreUtils;
    use experimental 'smartmatch';

    my %args  = @_;

    my $res = list_files(_common_args(\%args), del=>0);
    return [500, "Can't list files: $res->[0] - $res->[1]"] if $res->[0] != 200;

    my $newest_n;
    if ($args{newest_n}) {
        $newest_n = $args{newest_n};
    } elsif ($args{newest}) {
        $newest_n = 1;
    }

    my @dists;
    for my $file (@{$res->[2]}) {
        if ($file =~ m!/!) {
            log_debug("Skipping %s: under a subdirectory", $file);
            next;
        }
        my ($dist, $version, $is_dev) = _parse_release_filename($file);
        unless (defined $dist) {
            log_debug("Skipping %s: doesn't match release regex", $file);
            next;
        }
        next if $is_dev && $newest_n;
        push @dists, {
            name => $dist,
            file => $file,
            version => $version,
            is_dev_version => $is_dev ? 1:0,
        };
    }

    my @old_files;
    if ($newest_n) {
        my %dist_versions;
        for my $dist (@dists) {
            push @{ $dist_versions{$dist->{name}} }, $dist->{version};
        }
        for my $dist (keys %dist_versions) {
            $dist_versions{$dist} = [
                sort { version->parse($b) <=> version->parse($a) }
                    @{ $dist_versions{$dist} }];
            if (@{ $dist_versions{$dist} } > $newest_n) {
                $dist_versions{$dist} = [splice(
                    @{ $dist_versions{$dist} }, 0, $newest_n)];
            }
        }
        my @old_dists = @dists;
        @dists = ();
        for my $dist (@old_dists) {
            if ($dist->{version} ~~ @{ $dist_versions{$dist->{name}} }) {
                push @dists, $dist;
            } else {
                push @old_files, $dist->{file};
            }
        }
    }

    unless ($args{detail}) {
        @dists = List::MoreUtils::uniq(map { $_->{name} } @dists);
    }

    my %resmeta;
    if ($newest_n) {
        $resmeta{"func.old_files"} = \@old_files;
    }
    if ($args{detail}) {
        $resmeta{'table.fields'} = [qw/name version is_dev_version file/];
    }
    [200, "OK", \@dists, \%resmeta];
}

$SPEC{delete_old_releases} = {
    v => 1.1,
    summary => 'Delete older versions of distributions',
    description => <<'_',

Developer releases will not be deleted.

To delete developer releases, you can use `delete_files` (rm), e.g. from the
command line:

    % pause rm 'My-Module-*TRIAL*'; # delete a dist's trial releases
    % pause rm '*TRIAL*' '*_*'; # delete all files containing TRIAL or underscore

_
    args => {
        %common_args,
        %detail_l_arg,
        %protect_files_arg,
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

    my $res = list_dists(_common_args(\%args), newest_n=>$args{num_keep}//1);
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
    use experimental 'smartmatch';
    require Regexp::Wildcards;
    require String::Wildcard::Bash;

    my $which = shift;
    my %args = @_;

    my $files0 = $args{files} // [];
    return [400, "Please specify at least one file"] unless @$files0;

    my $protect_files = $args{protect_files} // [];

    my @files;
    {
        my $listres;
        if (grep {String::Wildcard::Bash::contains_wildcard($_)}
                (@$files0, @$protect_files)) {
            $listres = list_files(_common_args(\%args));
            return [500, "Can't list files: $listres->[0] - $listres->[1]"]
                unless $listres->[0] == 200;
        }

        for my $file (@$files0) {
            if (String::Wildcard::Bash::contains_wildcard($file)) {
                my $re = Regexp::Wildcards->new(type=>'unix')->convert($file);
                $re = qr/\A($re)\z/;
                for my $f (@{$listres->[2]}) {
                    push @files, $f if $f =~ $re && !($f ~~ @files);
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

    my $action;
    if ($which eq 'delete') {
        $action = 'delete_files';
    } elsif ($which eq 'undelete') {
        $action = 'delete_files';
    } elsif ($which eq 'reindex') {
        $action = 'reindex';
    } else {
        die "BUG: undefined action";
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

This document describes version 0.444 of WWW::PAUSE::Simple (from Perl distribution WWW-PAUSE-Simple), released on 2019-06-05.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides several functions for performing common tasks on PAUSE.
There is also a CLI script L<pause> distributed separately in L<App::pause>.

=head1 FUNCTIONS


=head2 delete_files

Usage:

 delete_files(%args) -> [status, msg, payload, meta]

Delete files.

When a file is deleted, it is not immediately deleted but has
scheduled_for_deletion status for 72 hours, then deleted. During that time, the
file can be undeleted.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

File names/wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<protect_files> => I<array[str]>

Protect some files/wildcard patterns from delete/cleanup.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 delete_old_releases

Usage:

 delete_old_releases(%args) -> [status, msg, payload, meta]

Delete older versions of distributions.

Developer releases will not be deleted.

To delete developer releases, you can use C<delete_files> (rm), e.g. from the
command line:

 % pause rm 'My-Module-*TRIAL*'; # delete a dist's trial releases
 % pause rm '*TRIAL*' '*_*'; # delete all files containing TRIAL or underscore

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<num_keep> => I<int> (default: 1)

Number of new versions (including newest) to keep.

1 means to only keep the newest version, 2 means to keep the newest and the
second newest, and so on.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<protect_files> => I<array[str]>

Protect some files/wildcard patterns from delete/cleanup.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_dists

Usage:

 list_dists(%args) -> [status, msg, payload, meta]

List distributions.

Distribution names will be extracted from tarball/zip filenames.

Unknown/unparseable filenames will be skipped.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<newest> => I<bool>

Only show newest non-dev version.

Dev versions will be skipped.

=item * B<newest_n> => I<int>

Only show this number of newest non-dev versions.

Dev versions will be skipped.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_files

Usage:

 list_files(%args) -> [status, msg, payload, meta]

List files.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<del> => I<bool>

Only list files which are scheduled for deletion.

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<files> => I<array[str]>

File names/wildcard patterns.

=item * B<mtime_max> => I<date>

=item * B<mtime_min> => I<date>

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

=item * B<size_max> => I<uint>

=item * B<size_min> => I<uint>

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_modules

Usage:

 list_modules(%args) -> [status, msg, payload, meta]

List modules (permissions).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to return detailed records.

=item * B<modules> => I<array[str]>

Module names/wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

=item * B<type> => I<str>

Only list modules matching certain type.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 reindex_files

Usage:

 reindex_files(%args) -> [status, msg, payload, meta]

Force reindexing.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

File names/wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 undelete_files

Usage:

 undelete_files(%args) -> [status, msg, payload, meta]

Undelete files.

When a file is deleted, it is not immediately deleted but has
scheduled_for_deletion status for 72 hours, then deleted. During that time, the
file can be undeleted.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

File names/wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

=item * B<username> => I<str>

PAUSE ID.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 upload_files

Usage:

 upload_files(%args) -> [status, msg, payload, meta]

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

File names/wildcard patterns.

=item * B<password> => I<str>

PAUSE password.

If unset, default value will be searched from C<~/.pause>. Encrypted C<.pause> is
not yet supported.

=item * B<retries> => I<int> (default: 35)

Number of retries when received 5xx HTTP error from server.

=item * B<retry_delay> => I<duration>

How long to wait before retrying (deprecated).

This setting is now deprecated. Will use a constant backoff strategy of delaying
this many seconds. The default (when this setting is not specified) is now to
use an exponential backoff strategy of delaying 3, 6, 12, 24, ..., 3600, 3600,
... seconds. The default C<retries> of 35 makes this strategy retries for a
little over a day (88941 seconds). The terminal delay setting (default 3600
seconds) can be set via C<retry_max_delay>.

=item * B<retry_max_delay> => I<duration> (default: 3600)

How long to wait at most before retrying.

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

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(upload_file|set_account_info|set_password)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WWW-PAUSE-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WWW-PAUSE-Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-PAUSE-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Uploader> which also does uploading from CLI.

L<WWW::PAUSE::CleanUpHomeDir> which can clean old releases from your PAUSE
account (CLI script is provided in example).

L<App::PAUSE::cleanup> which also cleans old releases from your PAUSE account,
with CLI included L<pause-cleanup>.

L<https://perlancar.wordpress.com/2015/03/25/interacting-with-pause-using-cli/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

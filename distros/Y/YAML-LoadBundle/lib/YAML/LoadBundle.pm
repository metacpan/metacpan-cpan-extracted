package YAML::LoadBundle;
# ABSTRACT: Load a directory of YAML files as a bundle
use version;
our $VERSION = 'v0.4.2'; # VERSION

use base qw(Exporter);
use warnings;
use strict;

use Carp;
use Cwd                 qw( abs_path );
use Digest::SHA1        qw( sha1_hex sha1 );
use File::Find          qw( find );
use Hash::Merge::Simple ();
use Scalar::Util        qw( reftype refaddr );
use Storable            qw( freeze dclone );
use YAML::XS            qw(Load);

our @EXPORT_OK = qw(
    load_yaml
    load_yaml_bundle
    add_yaml_observer
    remove_yaml_observer
);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

our $CacheDir;
$CacheDir = $ENV{YAML_LOADBUNDLE_CACHEDIR} unless defined $CacheDir;

my @load_yaml_observers;

sub add_yaml_observer {
    my $observer = shift;
    die "Observer must be a code ref." unless ref($observer) eq 'CODE';
    push @load_yaml_observers, $observer;
}

sub _notify_yaml_observers {
    my $file = shift;
    for my $observer (@load_yaml_observers) {
        $observer->($file);
    }
}

sub remove_yaml_observer {
    my $observer = shift;
    die "Observer must be a code ref." unless ref($observer) eq 'CODE';
    my $obref = refaddr $observer;

    @load_yaml_observers = grep {
        refaddr($_) != $obref
    } @load_yaml_observers;
}

our %seen;

sub load_yaml {
    my ($arg, $dont_cache) = @_;
    my @yaml;
    my $cache_mtime;
    my %params;

    # We clone references that appear more than once in the data
    # structure. (For compatibility with Data::Visitor.)
    local %seen = ();

    if (ref $arg) {
        @yaml = <$arg>;
    }
    elsif ($arg =~ /\n/) {
        my $digest      = sha1($arg);
           $cache_mtime = 1;
        my $perl        = _yaml_cache_peek($digest, $cache_mtime);
        return $perl if defined $perl;
        open my $fh, '<', \$arg;
        @yaml = <$fh>;
        $arg  = $digest;
        $params{no_disk_cache} = 1;
    }
    elsif (-f $arg and -s _) {
        # $arg is a file path.
        _notify_yaml_observers($arg);

        my $mtime = (stat _)[9];
        my $perl = _yaml_cache_peek($arg, $mtime);
        return $perl if defined $perl;

        open my $fh, $arg
            or croak "Can't open YAML file $arg: $!";
        @yaml = <$fh>;
        $cache_mtime = $mtime;
    }
    else {
        croak "Can't load empty/missing YAML file: $arg.";
    }

    my $perl;
    eval { $perl = Load(join '', @yaml) };

    die "$@\nYAML File: $arg\n" if $@;

    # Can't cache/flatten empty YAML
    return unless $perl;

    # TODO: this is a temporary fix. previous functionaly skipped caching if a
    # second arg was passed into load_yaml. a recent refactor introduced a bug
    # that caused the code to never cache. as a temporary workaround we will
    # just set $cache_mtime to 0 if there's a second arg to this method. this
    # will tell _unravel_and_cache to skip the caching step.
    $cache_mtime = 0 if $dont_cache;
    $perl = _unravel_and_cache($arg, $perl, $cache_mtime, %params);

    return $perl;
}

my $shallow_merge = sub {
    my ($left, $right) = @_;
    if (reftype($left) eq 'ARRAY') {
        $left = { map %$_, @$left };
    }
    return (
        (map { %$_ } (reftype($left) eq 'ARRAY' ? @$left : $left)),
        %$right
    );
};
my $deep_merge = sub {
    my ($left, $right) = @_;
    return %{ Hash::Merge::Simple->merge(
        (reftype($left) eq 'ARRAY' ? @$left : $left),
        $right,
    ) };
};

# in order of priority:
my @SPECIAL = qw(
    -merge
    export
    -export
    import
    -import
);
my %SPECIAL = (
    -import => $shallow_merge,
    import  => $shallow_merge,
    -export => $shallow_merge,
    export  => $shallow_merge,
    -merge  => $deep_merge,
);

# Note: This used to add a (heavy) dependency on Data::Visitor
# to do these simple transformations. I *think* this is exactly 
# equivalent to what it used to do.

sub _unravel {
    my $data = shift;

    if (ref $data) {
        $data = dclone($data) if $seen{$data}++;

        if (reftype $data eq 'HASH') {
            return _unravel_hash($data);
        }
        elsif (reftype $data eq 'ARRAY') {
            for my $elt (@$data) {
                $elt = _unravel($elt);
            }
            return $data;
        }
    }

    return $data;
}

# Note: this modifies the argument in place. But sometimes it returns 
# a different reference, in order to replace itself in the enclosing
# data structure. (If it encounters a "-flatten" entry.)

sub _unravel_hash {
    my $data = shift;
    
    while (my @keys = grep { exists $data->{$_} } @SPECIAL) {
        # Make sure that deeper -merges and such will be handled first
        for my $key ( grep { ! $SPECIAL{ $_ } } keys %$data ) {
            # False values can be skipped for performance
            next unless $data->{$key};
            $data->{$key} = _unravel($data->{$key})
        }

        for my $key (@keys) {
            my $handler = $SPECIAL{$key};
            my $val = delete $data->{$key};
            next unless $val;
            %$data = $handler->(_unravel($val), $data);
        }
    }

    if (keys %$data == 1) {
        if (my $arrs = $data->{-flatten}) {
            _unravel($arrs);
            return [ map @$_, @$arrs ];
        }
        elsif (my $hrefs = $data->{-flattenhash}) {
            _unravel($hrefs);
            return { map %$_, @$hrefs };
        }
    }

    for my $elt (values %$data) {
        $elt = _unravel($elt) if ref($elt);
    }

    $data = dclone($data) if $seen{$data}++;
    return $data;
}


{
my %YAML_cache;
sub _unravel_and_cache {
    my ($path, $perl, $cache_mtime, %params) = @_;

    _unravel($perl);

    # TODO: need a better way to explicitly not cache here
    if ($cache_mtime) {
        my $frozen = Storable::freeze($perl);
        $YAML_cache{$path} = [ $cache_mtime, $frozen ];
        if ($CacheDir and not $params{no_disk_cache}) {
            my $cache_file = join "/", $CacheDir, sha1_hex($path);

            eval { mkdir $CacheDir };
            if ($@) {
                warn "Can't write yaml cache: $@";
            }
            else {
                open my $fh, '>', $cache_file or die "Cannot open $cache_file for writing $!";
                print $fh $frozen;
            }
        }
    }

    return $perl;
}

sub _yaml_cache_peek {
    my ($path, $mtime) = @_;

    my $cache = $YAML_cache{$path};
    if ($cache) {
        my ($oldtime, $oldyaml) = @$cache;
        return Storable::thaw($oldyaml) if $oldtime == $mtime;
    }
    elsif ($CacheDir) {
        my $cache_file = join "/", $CacheDir, sha1_hex($path);
        if (-f $cache_file) {
            my $cache_time = (stat $cache_file)[9];
            if ($cache_time >= $mtime) {
                open my $fh, "<$cache_file";
                my $file_contents = do { local $/; <$fh> };
                my $thawed = Storable::thaw($file_contents);
                $YAML_cache{$path} = [ $mtime, $file_contents ];
                return $thawed if $cache_time >= $mtime;
            }
            else {
                unlink $cache_file;
            }
        }
    }

    return;
}
}

{
my %default_options = (
    follow_symlinks_when => 'bundled',
    follow_symlinks_fail => 'error',
    conf_suffixes => [ 'conf', 'yml' ],
    max_depth => 20,
);

my %symlink_skipper = (
    error  => sub { croak "Symlink $_[1] was skipped.\nYAML Bundle: $_[0]\n" },
    warn   => sub { carp  "Symlink $_[1] was skipped.\nYAML Bundle: $_[0]\n" },
    ignore => sub { },
);

sub _merge_bundle {
    my ($current, $nested) = @_;

    if (ref($nested) eq 'ARRAY') {
        $current = [] unless defined $current;
        return +{ $deep_merge->($current, $nested) };
    }
    else {
        $current = {} unless defined $current;
        return +{ $deep_merge->($current, $nested) };
    }
}

sub load_yaml_bundle {
    my ($path, $given_options) = @_;
    my $cache_mtime;

    # Setup the default configuration
    my %options = (
        %{ $given_options || {} },
        %default_options,
    );

    # Add _vars to the options to allow recursive calls to share state.
    $options{_match_suffix} = join "|", map { quotemeta } @{ $options{conf_suffixes} }
        unless defined $options{_match_suffix};
    $options{max_depth}--;

    # Calculate the absolute base path to start from
    unless (defined $options{_original_path}) {
        $options{_original_path} = abs_path($path);
        $options{_original_path_length} = length $options{_original_path};

        # This is the top call, so check the cache
        my $this_mtime;
        $cache_mtime = 0;
        find({
            follow_fast => 1,
            wanted      => sub {
                if (/^.*\.(?:$options{_match_suffix})\z/s) {
                    $this_mtime = (lstat _)[9];
                    $cache_mtime = $this_mtime if $this_mtime > $cache_mtime;
                }
            },
        },
            $options{_original_path},
            grep { -f $_ }
                map { "$options{_original_path}.$_" }
                @{ $options{conf_suffixes} }
        );
        my $perl = _yaml_cache_peek($path, $cache_mtime);

        return $perl if defined $perl;
    }

    my $symlink_skipper = $symlink_skipper{ $options{follow_symlinks_fail} };

    # Stop, we've gone too far.
    if ($options{max_depth} < 0) {
        carp "Reached maximum path search depth while at $path.\nYAML Bundle: $options{_original_path}\n";
        return;
    }

    my $perl;

    # Do we have a top level .conf/.yml/.whatever in the bundle?
    for my $suffix (@{ $options{conf_suffixes} }) {
        my $file = $path . '.' . $suffix;
        if (-f $file and -s _) {

            # If $perl is already defined, we have a case where multiple
            # configuration files are present, which is not a defined case.
            carp "Multiple configuration files match $path. This will lead to unexpected results.\nYAML Bundle: $options{_original_path}\n"
                if defined $perl;

            # We don't use load_yml because we don't want the intermediate
            # pieces cached and it does a lot of work we'd repeat anyway.

            open my $fh, $file
                or croak "Can't open YAML file $file: $!";
            my $yaml = do { local $/; <$fh> };

            $perl = eval { Load($yaml) };
            if ($@) {
                croak "Eror in file $file: $@\nYAML Bundle: $options{_original_path}\n";
            }
        }
    }

    # if no file found, we have to start somewhere
    $perl = {} unless defined $perl;

    # If this is a directory, let's suck in all the nested configs
    if (-d $path) {
        opendir my $dir_fh, $path or croak "Cannot opendir $path: $!";

        # Saves us from duplicating work while recursing...
        my %closed_list;

        ENTRY: while (my $entry = readdir $dir_fh) {

            # Ignore all dot files
            next if $entry =~ m{^[.]};

            my $nested_path = abs_path("$path/$entry");

            if (not defined $nested_path) {
                croak "Broken symlink or other problem while locating $path/$entry.\nYAML Bundle: $options{_original_path}\n";
            }

            # If bundled, make sure this abs path is in the root bas path
            if ($options{follow_symlinks_when} eq 'bundled') {
                unless (substr($nested_path, 0, $options{_original_path_length}) eq $options{_original_path}) {
                    $symlink_skipper->($options{_original_path}, "$path/$entry");
                    next ENTRY;
                }
            }

            # If never, skip any symlink
            elsif ($options{follow_symlinks_when} eq 'never') {
                if (-l "$path/$entry") {
                    $symlink_skipper->($options{_original_path}, "$path/$entry");
                    next ENTRY;
                }
            }

            # Is this a directory? If so, load that as a bundle.
            if (-d $nested_path) {
                next ENTRY if $closed_list{$nested_path};

                # We don't follow symlinks to directories. This is a naive way
                # to prevent infinite recursion.
                if (-l "$path/$entry") {
                    croak "Symlink to directory $path/$entry is not permitted.\nYAML Bundle: $options{_original_path}\n";
                }

                # Load the nested bundle and merge.
                $closed_list{$nested_path}++;
                $perl->{ $entry } = _merge_bundle(
                    $perl->{ $entry },
                    load_yaml_bundle($nested_path, \%options)
                );
            }

            # Is this a file with the right suffix?
            elsif (-f $nested_path and $entry =~ s/[.](?:$options{_match_suffix})$//) {
                my $nested_path_minus_suffix = $nested_path;
                $nested_path_minus_suffix =~ s/[.](?:$options{_match_suffix})$//;
                next ENTRY if $closed_list{$nested_path_minus_suffix};

                # Load the nested bundle and merge.
                $closed_list{$nested_path_minus_suffix}++;
                $perl->{ $entry } = _merge_bundle(
                    $perl->{ $entry },
                    load_yaml_bundle($nested_path_minus_suffix, \%options)
                );
            }

            # What the hey? Carp about this...
            else {
                carp "Ignoring unexpected path $nested_path of unknown type.\nYAML Bundle: $options{_original_path}\n";
            }
        }
    }

    # Only unravel our format layer and cache the top
    # $cache_mtime is only set in the call _original_path is set
    if ($cache_mtime) {
        $perl = _unravel_and_cache($options{_original_path}, $perl, $cache_mtime);
    }

    return $perl;
}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

YAML::LoadBundle - Load a directory of YAML files as a bundle

=head1 VERSION

version v0.4.2

=head1 SYNOPSIS

  use YAML::LoadBundle qw(:all);

  my $hash = load_yaml_bundle( "/path/to/yaml_bundle/dir/" );

=head1 DESCRIPTION

Adds additonal features to YAML::XS to allow splitting a YAML file into
multiple files in a common directory.
This helps with readability when the file is large.

It also provides more advanced merging features than the standard YAML spec.

=head1 Export

Nothing is exported by default, but all the functions listed
below are available for export.

All will be exported with :all.

=head1 Exported Functions

=head2 Load

=head3 load_yaml

  load_yaml($filename)
  load_yaml(\*FILEHANDLE)
  load_yaml($yaml_data)

Parses a YAML file (or string) with extra error-checking.

When passed a $filename, the %YAML_cache will cache a dclone'd
copy of the result for later retrieval, unless the file has
been modified since the last load. This can be prevented by
passing anything else as a 2nd parameter, if you know that the
file will never be reloaded.

When passed a string, the %YAML_cache will cache a copy of the result,
using the SHA1 digest of the string as the hash key.
Strings are only cached in memory, not on disk.

After loading the YAML into a Perl data structure, some postprocessing is done
on specially-named keys in hash references.  Each is merged into their
containing hash reference, though at different times and with different
strategies.

=over

=item * C<-import>

shallow merge (e.g. C<%x = (%y, %x)>)

=item * C<-export>

shallow merge

=item * C<-merge>

deep merge (see L<Hash::Merge::Simple>)

=item * <-flatten>

    some_key: { -flatten: [*SomeArrayRef, *SomeOtherArrayRef] }

Instead of doing any kind of special hash merging, this special key takes an
arrayref of arrayrefs, merges all their contents into one large arrayref, then
replaces its entire surrounding hash with the arrayref.

In other words, the example above would look like this in Perl:

    { some_key => [@$some_array_ref, @$some_other_array_ref] }

=item * C<-flattenhash>

    some_key: { -flattenhash: [*SomeHashRef, *SomeOtherHashRef] }

Sometimes it is desirable to import more than one hash object,
but cannot due to limitations of keynames like -import.
If you really want this behavior, add this flag.

=back

C<import> and C<export> are backwards-compatibility synonyms for C<-import>
and C<-export>.

Like normal list assignment in Perl, the right-hand side takes precedence
(pseudocode):

  %hash = deep_merge(%merge, shallow_merge(%import, %export, %hash));

Instead of a hash reference, any of these keys may contain an array reference
of hash references, in which case those hash references are merged using
whatever strategy normally applies (e.g. deep merge for C<-merge>).

=head3 load_yaml_bundle

  load_yaml_bundle($path, \%options)

Similar to L</load_yaml>, but loads YAML from a bundle of configuration files.
This may be a single file, a directory containing configuration files,
or a whole directory tree of configuration files.

The given path names the base location for the bundle.
This starts by loading a file with the given name followed by a configuration
prefix (either C<.yml> or C<.conf> by default).
It then checks to see if there is a directory with the same name as the path.
It then repeats the loading process for all nested files and directories where
the file and directory names become the keys into which the configuration is
injected.

For example, given a directory layout like this:

  conf/base.conf
  conf/base/common.conf
  conf/base/user.conf
  conf/base/user/accounts.conf

A hash would be returned mapped something like this (pseudo-code):

    {
        common => load_yaml("conf/base/common.conf"),
        user   => {
            accounts => load_yaml("conf/base/user/accounts.conf"),
            %{ load_yaml("conf/base/user.conf") }
        },
        %{ load_yaml("conf/base.conf") }
    }

However, the actual merge will be a deep merge.

The usual semantics related to import, export, and merging apply to these files
as they do in L</load_yaml>.

Symlinks can be used to share the data between multiple keys.
By default, symlinks will be followed, but will cause an error if any of them
are outside the root path of the bundle.
If a symlink is permitted, this will follow symlinks to files or directories as
if they were the files or directories set locally, allowing the original key to
be renamed in any way desired.
It also means that symlinks to files must have a correct configuraiton file
suffix.

This will ignore any file starting with a period.

There are some options to modify the default behaviors:

=over

=item C<follow_symlinks_when>

This may be set to any of the following strings:

=over

=item C<bundled>

This is the default. Symlinks are followed, but only within the root.

=item C<never>

Do not follow symlinks.

=item C<always>

Always follow symlinks. Use this with caution.

=back

=item C<follow_symlinks_fail>

This may be set to any of the following strings:

=over

=item C<error>

This is the default. When symlinks are found, but not followed, croak.

=item C<warn>

When symlinks are found, but not followed, carp.

=item C<ignore>

When symlinks are found, but not followed... take no action at all.

=back

=item C<conf_suffixes>

This routine only considers files that have the given suffxes. The default includes "conf" and "yml". The suffixes are given as an array reference of strings. (All directories will be followed, at least to the maximum depth.)

=item C<max_depth>

This defaults to 20 which is probably more than enough and mostly intended to prevent some sort of insane failure. If a directory is found at one further than the maximum depth, a warning will be issued.

=back

=head2 Observe

=head3 add_yaml_observer

    add_yaml_observer(sub {
        my $filename = shift;
        warn "Yaml file $filename was just loaded.";
    });

Adds an observer sub that will be notified just prior to a yaml
file being loaded.  Note that each observer is called even if
the yaml file is cached and does not need to be reloaded.

=head3 _notify_yaml_observers

Called internally to notify each waiting observer
that a new yaml file is being loaded.

=head3 remove_yaml_observer

    remove_yaml_observer($subref);

Removes an observer sub that was previously added via add_yaml_observer.

=head2 Cache

=head3 $YAML::LoadBundle::CacheDir

Set this to a path that already exists of where to cache loaded files.

    $YAML::LoadBundle::CacheDir
        = File::Spec->catdir( File::Spec->tmpdir, 'yaml-loadbundle' );

Defaults to C<$ENV{YAML_LOADBUNDLE_CACHEDIR}>.

If false, caching is disabled.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

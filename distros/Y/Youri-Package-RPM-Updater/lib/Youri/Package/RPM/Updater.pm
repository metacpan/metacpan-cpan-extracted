# $Id$

package Youri::Package::RPM::Updater;

=head1 NAME

Youri::Package::RPM::Updater - Update RPM packages

=head1 SYNOPSIS

    my $updater = Youri::Package::RPM::Updater->new();
    $updater->update_from_source('foo-1.0-1.src.rpm', '2.0');
    $updater->update_from_spec('foo.spec', '2.0');
    $updater->update_from_repository('foo', '2.0');

=head1 DESCRIPTION

This module updates rpm packages. When given an explicit new version, it
updates the spec file, and downloads new sources automatically. When not given
a new version, it just updates the spec file.

Warning, not every spec file syntax is supported. If you use specific syntax,
you'll have to ressort to additional processing with explicit perl expression
to evaluate for each line of the spec file.

Here is version update algorithm (only used when building a new version):

=over

=item * find the first definition of version

=item * replace it with new value

=back

Here is release update algorithm:

=over

=item * find the first definition of release

=item * if explicit B<newrelease> parameter given:

=over

=item * replace value

=back

=item * otherwise:

=over

=item * extract any macro occuring in the leftmost part (such as %mkrel)

=item * extract any occurence of B<release_suffix> option in the rightmost part

=item * if a new version is given:

=over

=item * replace with 1

=back

=item * otherwise:

=over

=item * increment by 1

=back

=back

=back

In both cases, both direct definition:

    Version:    X

or indirect definition:

    %define version X
    Version:    %{version}

are supported. Any more complex one is not.

=head1 CONFIGURATION

The following YAML-format configuration files are used:

=over

=item the system configuration file is F</etc/youri/updater.conf>

=item the user configuration file is F<$HOME/.youri/updater.conf>

=back

Allowed directives are the same as new method options.

=head1 AUTHORS

Julien Danjou <danjou@mandriva.com>

Michael Scherer <misc@mandriva.org>

Guillaume Rousse <guillomovitch@mandriva.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2007 Mandriva.

Permission to use, copy, modify, and distribute this software and its
documentation under the terms of the GNU General Public License is hereby 
granted. No representations are made about the suitability of this software 
for any purpose. It is provided "as is" without express or implied warranty.
See the GNU General Public License for more details.

=cut

use strict;
use Cwd;
use Carp;
use DateTime;
use File::Basename;
use File::Copy; 
use File::Spec;
use File::Path;
use File::Temp qw/tempdir/;
use List::MoreUtils qw/none/;
use LWP::UserAgent;
use SVN::Client;
use Readonly;
use YAML::AppConfig;
use Youri::Package::RPM 0.002;
use version; our $VERSION = qv('0.6.3');
use experimental qw/switch/;

# default values
Readonly::Scalar my $defaults => <<'EOF';
---
srpm_dirs:

timeout: 10

agent: youri-package-updater/VERSION

url_rewrite_rules:
    - 
        from: http://(.*)\.(?:sourceforge|sf)\.net/?(.*)
        to:   http://prdownloads.sourceforge.net/$1/$2
    -
        from: https?://gna.org/projects/([^/]*)/(.*)'
        to:   http://download.gna.org/$1/$2
    -
        from: http://(.*)\.berlios.de/(.*)
        to:   http://download.berlios.de/$1/$2
    -
        from: https?://savannah.nongnu.org/projects/([^/]*)/(.*)
        to:   http://savannah.nongnu.org/download/$1/$2
    -
        from: https?://savannah.gnu.org/projects/([^/]*)/(.*)
        to:   http://savannah.gnu.org/download/$1/$2
    -
        from: http://search.cpan.org/dist/([^-]+)-.*
        to:   http://www.cpan.org/modules/by-module/$1/

archive_content_types:
    tar: 
        - application/x-tar
    gz:
        - application/x-tar
        - application/x-gz
        - application/x-gzip
    tgz:
        - application/x-tar
        - application/x-gz
        - application/x-gzip
    bz2:
        - application/x-tar
        - application/x-bz2
        - application/x-bzip
        - application/x-bzip2
    tbz2:
        - application/x-tar
        - application/x-bz2
        - application/x-bzip
        - application/x-bzip2
    zip:
        - application/x-gzip
    lzma:
        - application/x-tar
        - application/x-lzma
    _all:
        - application/x-download
        - application/octet-stream
        - application/empty

alternate_extensions:
    - tar.gz
    - tgz
    - zip

sourceforge_mirrors:
    - ovh
    - mesh
    - switch

new_version_message: New version %%VERSION

new_release_message: Rebuild
EOF

my $wrapper_class = Youri::Package::RPM->get_wrapper_class();

=head1 CLASS METHODS

=head2 new(%options)

Creates and returns a new MDV::RPM::Updater object.

Available options:

=over

=item verbose $level

verbosity level (default: 0).

=item check_new_version <true/false>

check new version is really new before updating spec file (default: true).

=item topdir $topdir

rpm top-level directory (default: rpm %_topdir macro).

=item sourcedir $sourcedir

rpm source directory (default: rpm %_sourcedir macro).

=item release_suffix $suffix

suffix appended to numerical value in release tag. (default: none).

=item srpm_dirs $dirs

list of directories containing source packages (default: empty).

=item timeout $timeout

timeout for file downloads (default: 10)

=item agent $agent

user agent for file downloads (default: youri-package-updater/$VERSION)

=item alternate_extensions $extensions

alternate extensions to try when downloading source fails (default: tar.gz,
tgz, zip)

=item sourceforge_mirrors $mirrors

mirrors to try when downloading files hosted on sourceforge (default: ovh,
mesh, switch)

=item url_rewrite_rules $rules

list of rewrite rules to apply on source tag value for computing source URL
when the source is a local file, as hashes of two regexeps

=item archive_content_types $types

hash of lists of accepted content types when downloading archive files, indexed
by archive extension

=item new_version_message

changelog message for new version (default: New version %%VERSION)

=item new_release_message

changelog message for new release (default: Rebuild)

=back

=cut

sub new {
    my ($class, %options) = @_;

    # force internal rpmlib configuration
    my ($topdir, $sourcedir);
    if ($options{topdir}) {
        $topdir = File::Spec->rel2abs($options{topdir});
        $wrapper_class->add_macro("_topdir $topdir");
    } else {
        $topdir = $wrapper_class->expand_macro('%_topdir');
    }
    if ($options{sourcedir}) {
        $sourcedir = File::Spec->rel2abs($options{sourcedir});
        $wrapper_class->add_macro("_sourcedir $sourcedir");
    } else {
        $sourcedir = $wrapper_class->expand_macro('%_sourcedir');
    }

    my $config = YAML::AppConfig->new(string => $defaults);
    $config->merge(file => '/etc/youri/updater.conf')
        if -r '/etc/youri/updater.conf';
    $config->merge(file => "$ENV{HOME}/.youri/updater.conf")
        if -r "$ENV{HOME}/.youri/updater.conf";
     
    my $self = bless {
        _topdir               => $topdir,
        _sourcedir            => $sourcedir,
        _verbose              => $options{verbose}           // 0,
        _check_new_version    => $options{check_new_version} // 1,
        _release_suffix       => $options{release_suffix}    //  undef,
        _timeout              => $options{timeout} //
                                 $config->get('timeout'),
        _agent                => $options{agent} //
                                 $config->get('agent'),
        _srpm_dirs            => $options{srpm_dirs} //
                                 $config->get('srpm_dirs'),
        _alternate_extensions => $options{alternate_extensions} //
                                 $config->get('alternate_extensions'),
        _sourceforge_mirrors  => $options{sourceforge_mirrors} //
                                 $config->get('sourceforge_mirrors'),
        _new_version_message  => $options{new_version_message} //
                                 $config->get('new_version_message'),
        _new_release_message  => $options{new_release_message} //
                                 $config->get('new_release_message'),
        _url_rewrite_rules    => $options{url_rewrite_rules} //
                                 $config->get('url_rewrite_rules'),
        _archive_content_types => $options{archive_content_types} //
                                  $config->get('archive_content_types'),
    }, $class;

    $self->{_agent} =~ s/VERSION/$VERSION/;

    return $self;
}

=head1 INSTANCE METHODS

=head2 update_from_repository($name, $version, %options)

Update package with name $name to version $version.

Available options:

=over

=item release => $release

Force package release, instead of computing it.

=item download true/false

download new sources (default: true).

=item update_revision true/false

update spec file revision (release/history) (default: true).

=item update_changelog true/false

update spec file changelog (default: true).

=item spec_line_callback $callback

callback to execute as filter for each spec file line (default: none).

=item spec_line_expression $expression

perl expression (or list of expressions) to evaluate for each spec file line
(default: none). Takes precedence over previous option.

=item changelog_entries $entries

list of changelog entries (default: empty).

=back

=cut

sub update_from_repository {
    my ($self, $name, $new_version, %options) = @_;
    croak "Not a class method" unless ref $self;
    my $src_file;

    if ($self->{_srpm_dirs}) {
        foreach my $srpm_dir (@{$self->{_srpm_dirs}}) {
            $src_file = $self->_find_source_package($srpm_dir, $name);
            last if $src_file;
        }   
    }

    croak "No source available for package $name, aborting" unless $src_file;

    $self->update_from_source($src_file, $new_version, %options);
}

=head2 update_from_source($source, $version, %options)

Update package with source file $source to version $version.

See update_from_repository() for available options.

=cut

sub update_from_source {
    my ($self, $src_file, $new_version, %options) = @_;
    croak "Not a class method" unless ref $self;

    $wrapper_class->set_verbosity(0);
    my ($spec_file) = $wrapper_class->install_srpm($src_file);

    croak "Unable to install source package $src_file, aborting"
        unless $spec_file;

    $self->update_from_spec($spec_file, $new_version, %options);
}

=head2 update_from_spec($spec, $version, %options)

Update package with spec file $spec to version $version.

See update_from_repository() for available options.

=cut

sub update_from_spec {
    my ($self, $spec_file, $new_version, %options) = @_;
    croak "Not a class method" unless ref $self;

    $options{download}         = 1 unless defined $options{download};
    $options{update_revision}  = 1 unless defined $options{update_revision};
    $options{update_changelog} = 1 unless defined $options{update_changelog};

    my $spec = $wrapper_class->new_spec($spec_file, force => 1)
        or croak "Unable to parse spec $spec_file\n"; 

    $self->_update_spec($spec_file, $spec, $new_version, %options) if
        $options{update_revision}      ||
        $options{update_changelog}     ||
        $options{spec_line_callback}   ||
        $options{spec_line_expression};

    $spec = $wrapper_class->new_spec($spec_file, force => 1)
        or croak "Unable to parse updated spec file $spec_file\n"; 

    $self->_download_sources($spec, $new_version, %options) if
        $new_version       &&
        $options{download};
}

sub _update_spec {
    my ($self, $spec_file, $spec, $new_version, %options) = @_;

    my $header = $spec->srcheader();

    # return if old version >= new version
    my $old_version = $header->tag('version');
    return if $options{check_new_version} &&
              $new_version                &&
              $wrapper_class->compare_revisions($old_version, $new_version) >= 0;

    my $new_release = $options{release} || '';
    my $epoch       = $header->tag('epoch');

    if ($options{spec_line_expression}) {
        $options{spec_line_callback} =
            _get_callback($options{spec_line_expression});
    }

    open(my $in, '<', $spec_file)
        or croak "Unable to open file $spec_file: $!";

    my $content;
    my ($version_updated, $release_updated, $changelog_updated);
    while (my $line = <$in>) {
        if ($options{update_revision} && # update required
            $new_version              && # version change needed
            !$version_updated            # not already done
        ) {
            my ($directive, $spacing, $value) =
                _get_new_version($line, $new_version);
            if ($directive && $value) {
                $line = $directive . $spacing . $value . "\n";
                $new_version = $value;
                $version_updated = 1;
            }
        }

        if ($options{update_revision} && # update required
            !$release_updated            # not already done
        ) {
            my ($directive, $spacing, $value) =
                _get_new_release($line, $new_version, $new_release, $self->{_release_suffix});
            if ($directive && $value) {
                $line = $directive . $spacing . $value . "\n";
                $new_release = $value;
                $release_updated = 1;
            }
        }

        # apply global and local callbacks if any
        $line = $options{spec_line_callback}->($line)
            if $options{spec_line_callback};

        $content .= $line;

        if ($options{update_changelog} &&
            !$changelog_updated        && # not already done
            $line =~ /^\%changelog/
        ) {
            # skip until first changelog entry, as requested for bug #21389
            while ($line = <$in>) {
                last if $line =~ /^\*/;
                $content .= $line;
            }

            my @entries =
                $options{changelog_entries} ? @{$options{changelog_entries}} :
                $new_version                ? $self->{_new_version_message}  :
                                              $self->{_new_release_message}  ;
            foreach my $entry (@entries) {
                $entry =~ s/\%\%VERSION/$new_version/g;
            }

            my $title = $wrapper_class->expand_macro(
                DateTime->now()->strftime('%a %b %d %Y') .
                ' ' .
                $self->_get_packager() .
                ' ' .
                ($epoch ? $epoch . ':' : '') .
                ($new_version ? $new_version : $old_version) .
                '-' .
                $new_release
            );

            $content .= "* $title\n";
            foreach my $entry (@entries) {
                $content .= "- $entry\n";
            }
            $content .= "\n";

            # don't forget kept line
            $content .= $line;

            # just to skip test for next lines
            $changelog_updated = 1;
        }
    }
    close($in);

    open(my $out, '>', $spec_file)
        or croak "Unable to open file $spec_file: $!";
    print $out $content;
    close($out);
}

sub _download_sources {
    my ($self, $spec, $new_version, %options) = @_;

    foreach my $source ($self->_get_sources($spec, $new_version)) {
        my $found;

        if ($source->{url} =~ m!http://prdownloads.sourceforge.net!) {
            # if content is hosted on source forge, attempt to download
            # from all configured mirrors
            foreach my $mirror (@{$self->{_sourceforge_mirrors}}) {
                my $sf_url = $source->{url};
                $sf_url =~ s!prdownloads.sourceforge.net!$mirror.dl.sourceforge.net/sourceforge!;
                $found = $self->_fetch_tarball($sf_url);
                last if $found;
            }
        } else {
            $found = $self->_fetch($source->{url});
        }

        croak "Unable to download source: $source->{url}" unless $found;

        # recompress source if neeeded
        _bzme($found) if $source->{bzme};
    }

}

sub _fetch {
    my ($self, $url) = @_;
    # if you add a handler here, do not forget to add it to the body of build()
    return $self->_fetch_tarball($url) if $url =~ m!^(ftp|https?)://!;
    return $self->_fetch_svn($url) if $url =~ m!^svns?://!; 
}

sub _fetch_svn {
    my ($self, $url) = @_;
    my ($basename, $repos);

    $basename = basename($url);
    ($repos = $url) =~ s|/$basename$||;
    $repos =~ s/^svn/http/;
    croak "Cannot extract revision number from the name."
        if $basename !~ /^(.*)-([^-]*rev)(\d\d*).tar.bz2$/;
    my ($name, $prefix, $release) = ($1, $2, $3);

    # extract repository in a temp directory
    my $dir = tempdir(CLEANUP => 1);
    my $archive = "$name-$prefix$release";
    my $svn = SVN::Client->new();
    $svn->export($repos, "$dir/$archive", $release);

    # archive and compress result
    my $result = system("tar -cjf $archive.tar.bz2 -C $dir $archive");
    croak("Error during archive creation: $?\n")
        unless $result == 0;
}

sub _fetch_tarball {
    my ($self, $url) = @_;

    my $agent = LWP::UserAgent->new();
    $agent->env_proxy();
    $agent->timeout($self->{_timeout});
    $agent->agent($self->{_agent});

    my $file = $self->_fetch_potential_tarball($agent, $url);

    # Mandriva policy implies to recompress sources, so if the one that was
    # just looked for was missing, check with other formats
    if (!$file and $url =~ /\.tar\.bz2$/) {
        foreach my $extension (@{$self->{_alternate_extensions}}) {
            my $alternate_url = $url;
            $alternate_url =~ s/\.tar\.bz2$/.$extension/;
            $file = $self->_fetch_potential_tarball($agent, $alternate_url);
            if ($file) {
                $file = _bzme($file);
                last;
            }
        }
    }

    return $file;
}

sub _fetch_potential_tarball {
    my ($self, $agent, $url) = @_;

    my $filename = basename($url);
    my $dest = "$self->{_sourcedir}/$filename";

    # don't attempt to download file if already present
    return $dest if -f $dest;

    print "attempting to download $url\n" if $self->{_verbose};
    my $response = $agent->mirror($url, $dest);
    if ($response->is_success()) {
        print "response: OK\n" if $self->{_verbose} > 1;
        my ($extension) = $filename =~ /\.(\w+)$/;
        if ($self->{_archive_content_types}->{$extension}) {
            # check content type for archives
            my $type = $response->header('Content-Type');
            print "checking content-type $type: " if $self->{_verbose} > 1;
            if (
                none { $type eq $_ }
                @{$self->{_archive_content_types}->{$extension}},
                @{$self->{_archive_content_types}->{_all}}
            ) {
                # wrong type
                print "NOK\n" if $self->{_verbose} > 1;
                unlink $dest;
                return;
            } else {
                print "OK\n" if $self->{_verbose} > 1;
            }
        }
        return $dest;
    } else {
        print "response: NOK\n" if $self->{_verbose} > 1;
        return;
    }
}


sub _get_packager {
    my ($self) = @_;
    my $packager = $wrapper_class->expand_macro('%packager');
    if ($packager eq '%packager') {
        my $login = (getpwuid($<))[0];
        $packager = $ENV{EMAIL} ? "$login <$ENV{EMAIL}>" : $login;
    }
    return $packager;
}


sub _find_source_package {
    my ($self, $dir, $name) = @_;

    my $file;
    opendir(my $DIR, $dir) or croak "Unable to open $dir: $!";
    while (my $entry = readdir($DIR)) {
        if ($entry =~ /^\Q$name\E-[^-]+-[^-]+\.src.rpm$/) {
            $file = "$dir/$entry";
            last;
        }
    }
    closedir($DIR);
    return $file;
}

sub _get_sources {
    my ($self, $spec, $version) = @_;

    my $header = $spec->srcheader();
    my $name   = $header->tag('name');

    my @sources;

    # special cases: ignore sources defined in the spec file
    if ($name =~ /^perl-(\S+)/) {
        # source URL in the spec file can not be trusted, as it 
        # change for each release, so try to use CPAN metabase DB
        my $cpan_name = $1;
        $cpan_name =~ s/-/::/g;

        # ignore spec file URL, as it changes between releases
        my ($cpan_url, $cpan_version) = _get_cpan_package_info(
            $cpan_name
        );

        if ($cpan_url && $cpan_version && $cpan_version eq $version) {
            # use the result if available
            my $source = ($spec->sources_url())[0];
            @sources = ( { url => $cpan_url, bzme => $source =~ /\.tar\.bz2$/ } );
        }
    }

    return @sources if @sources;

    # default case: extract all sources defined with an URL in the spec file
    @sources =
        map { _fix_source($_, $version) }
        map { { url => $_, bzme => 0 } }
        grep { /(?:ftp|svns?|https?):\/\/\S+/ }
        $spec->sources_url();

    return @sources if @sources;

    # fallback case: try a single source, with URL deduced from package URL

    print "No remote sources were found, fall back on URL tag ...\n"
        if $self->{_verbose};

    my $url = $header->tag('url');

    foreach my $rule (@{$self->{_url_rewrite_rules}}) {
        # curiously, we need two level of quoting-evaluation here :(
        if ($url =~ s!$rule->{from}!qq(qq($rule->{to}))!ee) {
            last;
        }    
    }

    my $source = ($spec->sources_url())[0];
    @sources = ( { url => $url . '/' . $source, bzme => 0 } );

    return @sources;
}

sub _get_callback {
    my ($expressions) = @_;

    my ($code, $sub);;
    $code .= '$sub = sub {';
    $code .= '$_ = $_[0];';
    foreach my $expression (
        ref $expressions eq 'ARRAY' ?
            @{$expressions} : $expressions
    ) {
        $code .= $expression;
        $code .= ";\n" unless $expression =~ /;$/;
    }
    $code .= 'return $_;';
    $code .= '}';
    ## no critic ProhibitStringyEva
    eval $code;
    ## use critic
    warn "unable to compile given expression into code $code, skipping"
        if $@;

    return $sub;
}

sub _bzme {
    my ($file) = @_;

    system("bzme -f -F $file >/dev/null 2>&1");
    $file =~ s/\.(?:tar\.gz|tgz|zip)$/.tar.bz2/;

    return $file;
}

sub _get_new_version {
    my ($line, $new_version) = @_;

    return unless $line =~ /^
        (
            %(?:define|global) \s+   # macro
                (?:
                    version
                |
                    upstream_version
                )
        |
            (?i)Version:             # tag
        )
        (\s+)                        # spacing
        (\S+(?: \s+ \S+)*)           # value
    /ox;

    my ($directive, $spacing, $value) = ($1, $2, $3);

    if ($new_version) {
        $value = $new_version;
    }

    return ($directive, $spacing, $value);
}
sub _get_new_release {
    my ($line, $new_version, $new_release, $release_suffix) = @_;

    return unless $line =~ /^
    (
        %(?:define|global) \s+      # macro
            (?:
                rel
            |
                release
            )
    |
        (?i)Release:     # tag
    )
    (\s+)                # spacing
    (\S+(?: \s+ \S+)*)   # value
    /ox;

    my ($directive, $spacing, $value) = ($1, $2, $3);

    if ($new_release) {
        $value = $new_release;
    } else {
        if ($value =~ /^% (\w+) (\s+) (\S+) $/x) {
            my ($macro_name, $macro_spacing, $macro_value) = ($1, $2, $3);
            $macro_value = _get_new_release_number($macro_value, $new_version, $release_suffix);
            $value = '%' . $macro_name . $macro_spacing . $macro_value;
        } elsif ($value =~ /^% \{ (\w+) (\s+) (\S+) \} $/x) {
            my ($macro_name, $macro_spacing, $macro_value) = ($1, $2, $3);
            $macro_value = _get_new_release_number($macro_value, $new_version, $release_suffix);
            $value = '%{' . $macro_name . $macro_spacing . $macro_value . '}';
        } else {
            $value = _get_new_release_number($value, $new_version, $release_suffix);
        }
    }

    return ($directive, $spacing, $value);
}

sub _get_new_release_number {
    my ($value, $new_version, $release_suffix) = @_;

    my ($prefix, $number, $suffix); 
    if ($new_version) {
        $number = 1;
    } else {
        # optional suffix from configuration
        $release_suffix = $release_suffix ?
            quotemeta($release_suffix) : '';
        ($prefix, $number, $suffix) =
            $value =~ /^(.*?)(\d+)($release_suffix)?$/;

        croak "Unable to extract release number from value '$value'"
            unless defined($number);

        $number++;
    }

    return 
        ($prefix ? $prefix : "") .
        $number .
        ($suffix ? $suffix : "");

}

sub _fix_source {
    my ($source, $version) = @_;

    given ($source->{url}) {
        when (m!ftp.gnome.org/pub/GNOME/sources/!) {
            # the last part of the path should match current
            # major and minor version numbers:
            # ftp://ftp.gnome.org/pub/GNOME/sources/ORbit2/2.10/ORbit2-2.10.0.tar.bz2
            my ($major, $minor) = split('\.', $version);
            $source->{url} =~ m!(.+)/([^/]+)$!;
            my ($path, $file) = ($1, $2);
            if ($path =~ m!/(\d+)\.(\d+)$!) {
                # expected format found
                if ($1 != $major || $2 != $minor) {
                    # but not corresponding to the current version
                    $path =~ s!\d+\.\d+$!$major.$minor!;
                }
            } else {
                $path .= "/$major.$minor";
            }
            $source->{url} = "$path/$file";
        }
        when (m!\w+\.(perl|cpan)\.org/!) {
            # force http
            $source->{url} =~ s!ftp://ftp\.(perl|cpan)\.org/pub/CPAN!http://www.cpan.org!;
            # force .tar.gz
            $source->{bzme} = 1
                if $source->{url} =~ s!\.tar\.bz2$!.tar.gz!;
        }
        when (m!download.pear.php.net/!) {
            # PEAR: force tgz
            $source->{bzme} = 1
                if $source->{url} =~ s!\.tar\.bz2$!.tgz!;
        }
    }

    return $source;
}

sub _get_cpan_package_info {
    my ($name) = @_;

    my $agent = LWP::UserAgent->new();
    $agent->env_proxy();

    my $response = $agent->get(
        "http://cpanmetadb.appspot.com/v1.0/package/$name"
    ); 

    return unless $response->is_success();

    my $conf = YAML::AppConfig->new(
        string => $response->decoded_content()
    );

    return unless $conf->get('distfile');

    my $url =
        "http://search.cpan.org/CPAN/authors/id/" . $conf->get('distfile');
    my $version = $conf->get('version');

    return ($url, $version);
}

1;

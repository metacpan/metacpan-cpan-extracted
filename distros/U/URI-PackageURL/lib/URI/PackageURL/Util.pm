package URI::PackageURL::Util;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use File::Spec;
use File::Basename qw(dirname basename);
use Exporter       qw(import);

our $VERSION = '2.24';
our @EXPORT  = qw(purl_to_urls purl_types);

sub purl_types {

    my @list = ();

    my $spec_dir = File::Spec->catfile(dirname(__FILE__), 'types');

    opendir(my $dh, $spec_dir) or Carp::croak "Can't open spec dir: $!";

    while (my $file = readdir $dh) {
        next unless -f File::Spec->catfile($spec_dir, $file);
        $file =~ s/\-definition\.json//;
        push @list, $file;
    }

    closedir $dh;

    @list = sort @list;

    return wantarray ? @list : \@list;

}

sub purl_to_urls {

    my $purl = shift;

    if (ref $purl ne 'URI::PackageURL') {
        require URI::PackageURL;
        $purl = URI::PackageURL->from_string($purl);
    }

    my %TYPES = (
        bitbucket => \&_to_bitbucket_urls,
        cargo     => \&_to_cargo_urls,
        composer  => \&_to_composer_urls,
        cpan      => \&_to_cpan_urls,
        docker    => \&_to_docker_urls,
        gem       => \&_to_gem_urls,
        github    => \&_to_github_urls,
        gitlab    => \&_to_gitlab_urls,
        golang    => \&_to_golang_urls,
        luarocks  => \&_to_luarocks_urls,
        maven     => \&_to_maven_urls,
        npm       => \&_to_npm_urls,
        nuget     => \&_to_nuget_urls,
        pypi      => \&_to_pypi_urls,
    );

    my $urls = {};

    if (defined $TYPES{$purl->type}) {
        $urls = $TYPES{$purl->type}->($purl);
    }

    if (my $download_url = $purl->qualifiers->{download_url}) {
        $urls->{download} = $download_url;
    }

    return $urls;

}

sub _to_bitbucket_urls {

    my $purl = shift;

    my $name       = $purl->name;
    my $namespace  = $purl->namespace;
    my $version    = $purl->version;
    my $qualifiers = $purl->qualifiers;
    my $file_ext   = $qualifiers->{ext} || 'tar.gz';

    my $urls = {};

    if ($name && $namespace) {
        $urls->{repository} = "https://bitbucket.org/$namespace/$name";
    }

    if ($version) {
        $urls->{download} = "https://bitbucket.org/$namespace/$name/get/$version.$file_ext";
    }

    return $urls;

}

sub _to_cargo_urls {

    my $purl = shift;

    my $name    = $purl->name;
    my $version = $purl->version;

    if ($name && $version) {
        return {
            repository => "https://crates.io/crates/$name/$version",
            download   => "https://crates.io/api/v1/crates/$name/$version/download"
        };
    }

    return {repository => "https://crates.io/crates/$name"};

}

sub _to_composer_urls {

    my $purl = shift;

    my $name      = $purl->name;
    my $namespace = $purl->namespace;

    return unless ($name && $namespace);

    return {repository => "https://packagist.org/packages/$namespace/$name"};

}

sub _to_cpan_urls {

    my ($purl, $purl_type) = @_;

    my $name           = $purl->name;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $author         = $purl->namespace // $qualifiers->{author};
    my $file_ext       = $qualifiers->{ext}            || 'tar.gz';
    my $repository_url = $qualifiers->{repository_url} || $purl->definition->default_repository_url;
    my $distpath       = $qualifiers->{distpath};
    my $distdir        = $qualifiers->{distdir};

    $repository_url =~ s{/$}{};

    if ($repository_url !~ /^(http|https|file|ftp):\/\//) {
        $repository_url = 'https://' . $repository_url;
    }

    my $urls = {repository => "https://metacpan.org/dist/$name"};

    if ($name && $version && $author) {

        $urls->{repository} = "https://metacpan.org/release/$author/$name-$version";

        my $author_a  = substr($author, 0, 1);
        my $author_au = substr($author, 0, 2);

        my $download_base_url = "$repository_url/authors/id";

        if (!$distpath && !$distdir) {
            $urls->{download} = "$download_base_url/$author_a/$author_au/$author/$name-$version.$file_ext";
        }

        if ($distpath && !$distdir) {

            $distpath =~ s{^/}{};
            $distpath =~ s{^CPAN/}{};
            $distpath =~ s{^id/}{};
            $distpath =~ s{^authors/id/}{};

            if ($distpath !~ /^([A-Z]{1})\/([A-Z]{2})/) {

                my @parts     = split '/', $distpath;
                my $author_a  = substr($parts[0], 0, 1);
                my $author_au = substr($parts[0], 0, 2);

                $distpath = join '/', $author_a, $author_au, $distpath;

            }

            $urls->{download} = "$download_base_url/$distpath";

        }

        if ($distdir && !$distpath) {
            $urls->{download} = "$download_base_url/$author_a/$author_au/$author/$distdir/$name-$version.$file_ext";
        }

    }

    return $urls;

}

sub _to_docker_urls {

    my $purl = shift;

    my $name           = $purl->name;
    my $namespace      = $purl->namespace;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $repository_url = $qualifiers->{repository_url} || 'https://hub.docker.com';

    if ($repository_url !~ /^(http|https):\/\//) {
        $repository_url = 'https://' . $repository_url;
    }

    my $urls = {};

    if ($repository_url !~ /hub.docker.com/) {
        return $urls;
    }

    if (!$namespace) {
        $urls->{repository} = "$repository_url/_/$name";
    }

    if ($name && $namespace) {
        $urls->{repository} = "$repository_url/r/$namespace/$name";
    }

    return $urls;

}

sub _to_gem_urls {

    my $purl = shift;

    my $name    = $purl->name;
    my $version = $purl->version;

    if ($name && $version) {
        return {
            repository => "https://rubygems.org/gems/$name/versions/$version",
            download   => "https://rubygems.org/downloads/$name-$version.gem"
        };
    }

    return {repository => "https://rubygems.org/gems/$name"};

}

sub _to_github_urls {

    my $purl = shift;

    my $name       = $purl->name;
    my $namespace  = $purl->namespace;
    my $version    = $purl->version;
    my $qualifiers = $purl->qualifiers;
    my $file_ext   = $qualifiers->{ext} || 'tar.gz';

    my $urls = {};

    if ($name && $namespace) {
        $urls->{repository} = "https://github.com/$namespace/$name";
    }

    if ($version) {

        my $is_sha1 = ($version =~ /^[a-fA-F0-9]{40}$/);

        if ($is_sha1) {
            $urls->{download} = "https://github.com/$namespace/$name/archive/$version.$file_ext";
        }
        else {
            $urls->{download} = "https://github.com/$namespace/$name/archive/refs/tags/$version.$file_ext";
        }

    }

    return $urls;

}

sub _to_gitlab_urls {

    my $purl = shift;

    my $name       = $purl->name;
    my $namespace  = $purl->namespace;
    my $version    = $purl->version;
    my $qualifiers = $purl->qualifiers;
    my $file_ext   = $qualifiers->{ext} || 'tar.gz';

    my $urls = {};

    if ($name && $namespace) {
        $urls->{repository} = "https://gitlab.com/$namespace/$name";
    }

    if ($version) {
        $urls->{download} = "https://gitlab.com/$namespace/$name/-/archive/$version/$name-$version.$file_ext";
    }

    return $urls;

}

sub _to_golang_urls {

    my $purl = shift;

    my $name      = $purl->name;
    my $namespace = $purl->namespace;
    my $version   = $purl->version;

    my $urls = {};

    if ($name && $namespace) {
        $urls->{repository} = "https://pkg.go.dev/$namespace/$name";
    }

    # TODO  ???
    # if ($name && $namespace && $version) {
    #    $urls->{repository} = "https://pkg.go.dev/$namespace/$name\@v$version";
    # }

    return $urls;

}

sub _to_luarocks_urls {

    my $purl = shift;

    my $name           = $purl->name;
    my $namespace      = $purl->namespace;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $repository_url = $qualifiers->{repository_url} || 'https://luarocks.org';

    if ($repository_url !~ /^(http|https):\/\//) {
        $repository_url = 'https://' . $repository_url;
    }

    my $urls = {};

    if (!$namespace) {
        $urls->{repository} = "$repository_url/modules/$name";
    }

    if ($name && $namespace) {
        $urls->{repository} = "$repository_url/modules/$namespace/$name";
    }

    return $urls;

}

sub _to_maven_urls {

    my $purl = shift;

    my $namespace      = $purl->namespace;
    my $name           = $purl->name;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $extension      = $qualifiers->{extension}      // 'jar';
    my $repository_url = $qualifiers->{repository_url} // 'https://repo.maven.apache.org/maven2';

    if ($repository_url !~ /^(http|https):\/\//) {
        $repository_url = 'https://' . $repository_url;
    }

    if ($namespace && $name && $version) {

        (my $ns_url = $namespace) =~ s/\./\//g;

        return {
            repository => "https://mvnrepository.com/artifact/$namespace/$name/$version",
            download   => "$repository_url/$ns_url/$name/$version/$name-$version.$extension"
        };

    }

    if ($namespace && $name) {
        return {repository => "https://mvnrepository.com/artifact/$namespace/$name"};
    }

}

sub _to_npm_urls {

    my $purl = shift;

    my $namespace = $purl->namespace;
    my $name      = $purl->name;
    my $version   = $purl->version;

    if ($namespace && $name && $version) {
        return {
            repository => "https://www.npmjs.com/package/$namespace/$name/v/$version",
            download   => "https://registry.npmjs.org/$namespace/$name/-/$name-$version.tgz"
        };
    }

    if ($name && $version) {
        return {
            repository => "https://www.npmjs.com/package/$name/v/$version",
            download   => "https://registry.npmjs.org/$name/-/$name-$version.tgz"
        };
    }

    if ($namespace && $name) {
        return {repository => "https://www.npmjs.com/package/$namespace/$name"};
    }

    return {repository => "https://www.npmjs.com/package/$name"};

}

sub _to_nuget_urls {

    my $purl = shift;

    my $name    = $purl->name;
    my $version = $purl->version;

    if ($name && $version) {
        return {
            repository => "https://www.nuget.org/packages/$name/$version",
            download   => "https://www.nuget.org/api/v2/package/$name/$version"
        };
    }

    return {repository => "https://www.nuget.org/packages/$name"};

}

sub _to_pypi_urls {

    my $purl = shift;

    my $name    = $purl->name;
    my $version = $purl->version;

    if ($name && $version) {
        return {repository => "https://pypi.org/project/$name/$version"};
    }

    return {repository => "https://pypi.org/project/$name"};

}

1;

__END__
=head1 NAME

URI::PackageURL::Util - Utility for URI::PackageURL

=head1 SYNOPSIS

  use URI::PackageURL::Util qw(purl_to_urls);

  $urls = purl_to_urls('pkg:cpan/GDT/URI-PackageURL@2.24');

  $filename = basename($urls->{download});
  $ua->mirror($urls->{download}, "/tmp/$filename");


=head1 DESCRIPTION

URL::PackageURL::Util is the utility package for URL::PackageURL.

=over

=item $urls = purl_to_urls($purl_string | URI::PackageURL)

Converts the given Package URL string or L<URI::PackageURL> instance and return
the hash with C<repository> and/or C<download> URL.

B<NOTE>: This utility support few PURL types (C<bitbucket>,  C<cargo>, C<composer>,
C<cpan>, C<docker>, C<gem>, C<github>, C<gitlab>, C<luarocks>, C<maven>, C<npm>, C<nuget>, C<pypi>).

  +-----------+------------+--------------+
  | Type      | Repository | Download (*) |
  +-----------+------------+--------------|
  | bitbucket | YES        | YES          |
  | cargo     | YES        | YES          |
  | composer  | YES        | NO           |
  | cpan      | YES        | YES          |
  | docker    | YES        | NO           |
  | gem       | YES        | YES          |
  | generic   | NO         | YES (**)     |
  | github    | YES        | YES          |
  | gitlab    | YES        | YES          |
  | luarocks  | YES        | NO           |
  | maven     | YES        | YES          |
  | npm       | YES        | YES          |
  | nuget     | YES        | YES          |
  | pypi      | YES        | NO           |
  |-----------|------------|--------------+

(*)  Only with B<version> component
(**) Only if B<download_url> qualifier is provided

  $urls = purl_to_urls('pkg:cpan/GDT/URI-PackageURL@2.24');

  print Dumper($urls);

  # $VAR1 = {
  #   'repository' => 'https://metacpan.org/release/GDT/URI-PackageURL-2.24',
  #   'download'   => 'http://www.cpan.org/authors/id/G/GD/GDT/URI-PackageURL-2.24.tar.gz'
  # };

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-URI-PackageURL/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-URI-PackageURL>

    git clone https://github.com/giterlizzi/perl-URI-PackageURL.git


=head1 AUTHOR

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package URI::PackageURL::Util;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp;
use Exporter qw(import);

our $VERSION = '2.11';
our @EXPORT  = qw(purl_to_urls);

sub purl_to_urls {

    my $purl = shift;

    if (ref $purl ne 'URI::PackageURL') {
        require URI::PackageURL;
        $purl = URI::PackageURL->from_string($purl);
    }

    my %TYPES = (
        bitbucket => \&_bitbucket_urls,
        cargo     => \&_cargo_urls,
        composer  => \&_composer_urls,
        cpan      => \&_cpan_urls,
        docker    => \&_docker_urls,
        gem       => \&_gem_urls,
        github    => \&_github_urls,
        gitlab    => \&_gitlab_urls,
        golang    => \&_golang_urls,
        luarocks  => \&_luarocks_urls,
        maven     => \&_maven_urls,
        npm       => \&_npm_urls,
        nuget     => \&_nuget_urls,
        pypi      => \&_pypi_urls,
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

sub _github_urls {

    my $purl = shift;

    my $name           = $purl->name;
    my $namespace      = $purl->namespace;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $file_ext       = $qualifiers->{ext}            || 'tar.gz';
    my $version_prefix = $qualifiers->{version_prefix} || '';

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
            $urls->{download}
                = "https://github.com/$namespace/$name/archive/refs/tags/$version_prefix$version.$file_ext";
        }

    }

    return $urls;

}

sub _gitlab_urls {

    my $purl = shift;

    my $name           = $purl->name;
    my $namespace      = $purl->namespace;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $file_ext       = $qualifiers->{ext}            || 'tar.gz';
    my $version_prefix = $qualifiers->{version_prefix} || '';

    my $urls = {};

    if ($name && $namespace) {
        $urls->{repository} = "https://gitlab.com/$namespace/$name";
    }

    if ($version) {
        $urls->{download}
            = "https://gitlab.com/$namespace/$name/-/archive/$version_prefix$version/$name-$version_prefix$version.$file_ext";
    }

    return $urls;

}

sub _cargo_urls {

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

sub _gem_urls {

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

sub _pypi_urls {

    my $purl = shift;

    my $name    = $purl->name;
    my $version = $purl->version;

    if ($name && $version) {
        return {repository => "https://pypi.org/project/$name/$version"};
    }

    return {repository => "https://pypi.org/project/$name"};

}

sub _npm_urls {

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

sub _cpan_urls {

    my $purl = shift;

    my $name           = $purl->name;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $author         = $purl->namespace ? uc($purl->namespace) : undef;
    my $file_ext       = $qualifiers->{ext}            || 'tar.gz';
    my $repository_url = $qualifiers->{repository_url} || 'https://www.cpan.org';

    if ($repository_url !~ /^(http|https|file|ftp):\/\//) {
        $repository_url = 'https://' . $repository_url;
    }

    $name =~ s/\:\:/-/g;    # TODO

    my $urls = {repository => "https://metacpan.org/dist/$name"};

    if ($name && $version && $author) {

        my $author_1 = substr($author, 0, 1);
        my $author_2 = substr($author, 0, 2);

        $urls->{repository} = "https://metacpan.org/release/$author/$name-$version";
        $urls->{download}   = "$repository_url/authors/id/$author_1/$author_2/$author/$name-$version.$file_ext";

    }

    return $urls;

}

sub _nuget_urls {

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

sub _maven_urls {

    my $purl = shift;

    my $namespace  = $purl->namespace;
    my $name       = $purl->name;
    my $version    = $purl->version;
    my $qualifiers = $purl->qualifiers;
    my $extension  = $qualifiers->{extension}      // 'jar';
    my $repo_url   = $qualifiers->{repository_url} // 'repo1.maven.org/maven2';

    if ($namespace && $name && $version) {

        (my $ns_url = $namespace) =~ s/\./\//g;

        return {
            repository => "https://mvnrepository.com/artifact/$namespace/$name/$version",
            download   => "https://$repo_url/$ns_url/$name/$version/$name-$version.$extension"
        };

    }

    if ($namespace && $name) {
        return {repository => "https://mvnrepository.com/artifact/$namespace/$name"};
    }

}

sub _composer_urls {

    my $purl = shift;

    my $name      = $purl->name;
    my $namespace = $purl->namespace;

    return unless ($name && $namespace);

    return {repository => "https://packagist.org/packages/$namespace/$name"};

}

sub _bitbucket_urls {

    my $purl = shift;

    my $name           = $purl->name;
    my $namespace      = $purl->namespace;
    my $version        = $purl->version;
    my $qualifiers     = $purl->qualifiers;
    my $file_ext       = $qualifiers->{ext}            || 'tar.gz';
    my $version_prefix = $qualifiers->{version_prefix} || '';

    my $urls = {};

    if ($name && $namespace) {
        $urls->{repository} = "https://bitbucket.org/$namespace/$name";
    }

    if ($version) {
        $urls->{download} = "https://bitbucket.org/$namespace/$name/get/$version_prefix$version.$file_ext";
    }

    return $urls;

}

sub _docker_urls {

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

sub _golang_urls {

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

sub _luarocks_urls {

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

1;

__END__
=head1 NAME

URI::PackageURL::Util - Utility for URI::PackageURL

=head1 SYNOPSIS

  use URI::PackageURL::Util qw(purl_to_urls);

  $urls = purl_to_urls('pkg:cpan/GDT/URI-PackageURL@2.01');

  $filename = basename($urls->{download});
  $ua->mirror($urls->{download}, "/tmp/$filename");


=head1 DESCRIPTION

URL::PackageURL::Util is the utility package for URL::PackageURL.

=over

=item $urls = purl_to_urls($purl_string | URI::PackageURL);

Converts the given Package URL string or L<URI::PackageURL> instance and return
the hash with C<repository> and/or C<download> URL.

B<NOTE>: This utility support few purl types (C<bitbucket>,  C<cargo>, C<composer>,
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

  $urls = purl_to_urls('pkg:cpan/GDT/URI-PackageURL@2.11');

  print Dumper($urls);

  # $VAR1 = {
  #           'repository' => 'https://metacpan.org/release/GDT/URI-PackageURL-2.11',
  #           'download' => 'http://www.cpan.org/authors/id/G/GD/GDT/URI-PackageURL-2.11.tar.gz'
  #         };

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

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

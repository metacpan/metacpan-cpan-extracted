#!perl -T

use strict;
use warnings;

use Test::More;

use URI::PackageURL::Util qw(purl_to_urls);

my @tests = (
    {
        purl           => 'pkg:cpan/GDT/URI-PackageURL@2.01',
        download_url   => 'https://www.cpan.org/authors/id/G/GD/GDT/URI-PackageURL-2.01.tar.gz',
        repository_url => 'https://metacpan.org/release/GDT/URI-PackageURL-2.01'
    },

    {
        purl           => 'pkg:github/package-url/purl-spec@40d01e26f9ae0af6b50a1309e6b089c14d6d2244',
        repository_url => 'https://github.com/package-url/purl-spec',
        download_url   => 'https://github.com/package-url/purl-spec/'
            . 'archive/40d01e26f9ae0af6b50a1309e6b089c14d6d2244.tar.gz',
    },

    {
        purl           => 'pkg:gitlab/gitlab-org/gitlab-runner@v16.0.2',
        download_url   => 'https://gitlab.com/gitlab-org/gitlab-runner/-/archive/v16.0.2/gitlab-runner-v16.0.2.tar.gz',
        repository_url => 'https://gitlab.com/gitlab-org/gitlab-runner'
    },

    {
        purl           => 'pkg:bitbucket/birkenfeld/pygments-main@244fd47e07d1014f0aed9c',
        download_url   => 'https://bitbucket.org/birkenfeld/pygments-main/get/244fd47e07d1014f0aed9c.tar.gz',
        repository_url => 'https://bitbucket.org/birkenfeld/pygments-main'
    },

    {
        purl           => 'pkg:gem/ruby-advisory-db-check@0.0.4',
        repository_url => 'https://rubygems.org/gems/ruby-advisory-db-check/versions/0.0.4',
        download_url   => 'https://rubygems.org/downloads/ruby-advisory-db-check-0.0.4.gem'
    },

    {
        purl           => 'pkg:cargo/rand@0.7.2',
        repository_url => 'https://crates.io/crates/rand/0.7.2',
        download_url   => 'https://crates.io/api/v1/crates/rand/0.7.2/download'
    },

    {
        purl           => 'pkg:npm/%40angular/animations@12.2.17',
        repository_url => 'https://www.npmjs.com/package/@angular/animations/v/12.2.17',
        download_url   => 'https://registry.npmjs.org/@angular/animations/-/animations-12.2.17.tgz'
    },

    {
        purl           => 'pkg:nuget/EnterpriseLibrary.Common@6.0.1304',
        repository_url => 'https://www.nuget.org/packages/EnterpriseLibrary.Common/6.0.1304',
        download_url   => 'https://www.nuget.org/api/v2/package/EnterpriseLibrary.Common/6.0.1304'
    },

    {
        purl           => 'pkg:maven/org.apache.xmlgraphics/batik-anim@1.9.1?packaging=sources',
        repository_url => 'https://mvnrepository.com/artifact/org.apache.xmlgraphics/batik-anim/1.9.1',
        download_url   => 'https://repo.maven.apache.org/maven2/'
            . 'org/apache/xmlgraphics/batik-anim/1.9.1/batik-anim-1.9.1.jar'
    },

    {purl => 'pkg:pypi/django@1.11.1', repository_url => 'https://pypi.org/project/django/1.11.1'},

    {purl => 'pkg:composer/laravel/laravel@5.5.0', repository_url => 'https://packagist.org/packages/laravel/laravel'},

    {purl => 'pkg:docker/cassandra@latest', repository_url => 'https://hub.docker.com/_/cassandra'},

    {
        purl           => 'pkg:docker/smartentry/debian@dc437cc87d10',
        repository_url => 'https://hub.docker.com/r/smartentry/debian'
    },

    {
        purl           => 'pkg:github/nexb/scancode-toolkit@v3.1.1',
        download_url   => 'https://github.com/nexb/scancode-toolkit/archive/refs/tags/v3.1.1.tar.gz',
        repository_url => 'https://github.com/nexb/scancode-toolkit'
    }

);

foreach my $test (@tests) {

    my $purl           = $test->{purl};
    my $download_url   = $test->{download_url};
    my $repository_url = $test->{repository_url};

    subtest "'$purl' URLs" => sub {

        my $urls = purl_to_urls($purl);

        is($urls->{download},   $download_url,   'Download URL')   if defined $urls->{download};
        is($urls->{repository}, $repository_url, 'Repository URL') if defined $urls->{repository};

    };

}

done_testing();

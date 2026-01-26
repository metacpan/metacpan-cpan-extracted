#!perl -T

use strict;
use warnings;

use Test::More;

use URI::PackageURL::Util qw(purl_to_urls);

#<<<
my @tests = (
    {
        purl       => 'pkg:cpan/GDT/URI-PackageURL@2.01',
        download   => 'https://www.cpan.org/authors/id/G/GD/GDT/URI-PackageURL-2.01.tar.gz',
        repository => 'https://metacpan.org/release/GDT/URI-PackageURL-2.01'
    },
    {
        purl       => 'pkg:github/package-url/purl-spec@40d01e26f9ae0af6b50a1309e6b089c14d6d2244',
        repository => 'https://github.com/package-url/purl-spec',
        download   => 'https://github.com/package-url/purl-spec/archive/40d01e26f9ae0af6b50a1309e6b089c14d6d2244.tar.gz',
    },
    {
        purl       => 'pkg:gitlab/gitlab-org/gitlab-runner@v16.0.2',
        download   => 'https://gitlab.com/gitlab-org/gitlab-runner/-/archive/v16.0.2/gitlab-runner-v16.0.2.tar.gz',
        repository => 'https://gitlab.com/gitlab-org/gitlab-runner'
    },
    {
        purl       => 'pkg:bitbucket/birkenfeld/pygments-main@244fd47e07d1014f0aed9c',
        download   => 'https://bitbucket.org/birkenfeld/pygments-main/get/244fd47e07d1014f0aed9c.tar.gz',
        repository => 'https://bitbucket.org/birkenfeld/pygments-main'
    },
    {
        purl       => 'pkg:gem/ruby-advisory-db-check@0.0.4',
        repository => 'https://rubygems.org/gems/ruby-advisory-db-check/versions/0.0.4',
        download   => 'https://rubygems.org/downloads/ruby-advisory-db-check-0.0.4.gem'
    },
    {
        purl       => 'pkg:cargo/rand@0.7.2',
        repository => 'https://crates.io/crates/rand/0.7.2',
        download   => 'https://crates.io/api/v1/crates/rand/0.7.2/download'
    },
    {
        purl       => 'pkg:npm/%40angular/animations@12.2.17',
        repository => 'https://www.npmjs.com/package/@angular/animations/v/12.2.17',
        download   => 'https://registry.npmjs.org/@angular/animations/-/animations-12.2.17.tgz'
    },
    {
        purl       => 'pkg:nuget/EnterpriseLibrary.Common@6.0.1304',
        repository => 'https://www.nuget.org/packages/EnterpriseLibrary.Common/6.0.1304',
        download   => 'https://www.nuget.org/api/v2/package/EnterpriseLibrary.Common/6.0.1304'
    },
    {
        purl       => 'pkg:maven/org.apache.xmlgraphics/batik-anim@1.9.1?packaging=sources',
        repository => 'https://mvnrepository.com/artifact/org.apache.xmlgraphics/batik-anim/1.9.1',
        download   => 'https://repo.maven.apache.org/maven2/org/apache/xmlgraphics/batik-anim/1.9.1/batik-anim-1.9.1.jar'
    },
    {
        purl       => 'pkg:pypi/django@1.11.1',
        repository => 'https://pypi.org/project/django/1.11.1'
    },
    {
        purl       => 'pkg:composer/laravel/laravel@5.5.0',
        repository => 'https://packagist.org/packages/laravel/laravel'
    },
    {
        purl       => 'pkg:docker/cassandra@latest',
        repository => 'https://hub.docker.com/_/cassandra'
    },
    {
        purl       => 'pkg:docker/smartentry/debian@dc437cc87d10',
        repository => 'https://hub.docker.com/r/smartentry/debian'
    },
    {
        purl       => 'pkg:github/nexb/scancode-toolkit@v3.1.1',
        download   => 'https://github.com/nexb/scancode-toolkit/archive/refs/tags/v3.1.1.tar.gz',
        repository => 'https://github.com/nexb/scancode-toolkit'
    },
    {
        purl       => 'pkg:cpan/ILYAZ/Term-Gnuplot@0.90380906?distpath=I/IL/ILYAZ/modules/Term-Gnuplot-0.90380906.zip',
        download   => 'https://www.cpan.org/authors/id/I/IL/ILYAZ/modules/Term-Gnuplot-0.90380906.zip',
        repository => 'https://metacpan.org/release/ILYAZ/Term-Gnuplot-0.90380906',
    },
    {
        purl       => 'pkg:cpan/ILYAZ/Term-Gnuplot@0.90380906?distpath=authors/id/I/IL/ILYAZ/modules/Term-Gnuplot-0.90380906.zip',
        download   => 'https://www.cpan.org/authors/id/I/IL/ILYAZ/modules/Term-Gnuplot-0.90380906.zip',
        repository => 'https://metacpan.org/release/ILYAZ/Term-Gnuplot-0.90380906',
    },
    {
        purl       => 'pkg:cpan/ILYAZ/Term-Gnuplot@0.90380906?distpath=ILYAZ/modules/Term-Gnuplot-0.90380906.zip',
        download   => 'https://www.cpan.org/authors/id/I/IL/ILYAZ/modules/Term-Gnuplot-0.90380906.zip',
        repository => 'https://metacpan.org/release/ILYAZ/Term-Gnuplot-0.90380906',
    },
);
#>>>

foreach my $test (@tests) {

    my $purl = $test->{purl};
    my $urls = purl_to_urls($purl);

    for my $type (qw[download repository]) {

        next unless defined $urls->{$type};

        my $got      = $urls->{$type};
        my $expected = $test->{$type};
        my $label    = sprintf('%s - %s (%s URL)', $purl, $urls->{$type}, $type);

        is($got, $expected, $label);

    }

}

done_testing();

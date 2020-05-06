#!/usr/bin/perl

use strict;
use lib '.', 't';
use Config;
use helper;
use Test::More 'no_plan';
use Cwd;

set_path();

# fix bundled genhdlist2 & co to use the right perl on CPAN smokers:
system($^X, '-pi', '-e', qq(s@^#!/usr/bin/perl.*@#!$^X@), $_) foreach qw(gendistrib genhdlist2);

my $is_bsd = $Config{archname} =~ /bsd/;

warn ">> RPM version is: ", `LC_ALL=C rpm --version`, "\n";

chdir 't' if -d 't';
system('rm -rf tmp media');
foreach (qw(media tmp tmp/BUILD tmp/RPMS tmp/RPMS/noarch tmp/SRPMS)) {
    mkdir $_;
}
my $genhdlist2 = 'genhdlist2 --xml-info';

my $whereis_genhdlist2 = `whereis -b genhdlist2`;
$whereis_genhdlist2 =~ s/^genhdlist2:\s+//;
ok("whereis genhdlist2", "genhdlist2 emplacement=$whereis_genhdlist2");

# check that genhdlist2 actually works:
my $dir = "genhdlist2-test";
mkdir($dir);
my $out = `genhdlist2 $dir 2>&1`;
chomp($out);
is($out, "no *.rpm found in $dir (use --allow-empty-media?)", "genhdlist2 works");
$out = `genhdlist2 --help 2>&1`;
chomp($out);
my ($first) = split(/\n/, $out);
is($first, "Usage:", "genhdlist2 --help works");

# locally build test rpms

foreach my $dir (grep { -d $_ } glob("data/SPECS/*")) {
    my ($medium_name) = $dir =~ m!([^/]*)$!;
    next if $medium_name eq 'suggests' && !are_weak_deps_supported();
    rpmbuild($_, $medium_name) foreach glob("$dir/*.spec");
    genhdlist_std($medium_name);
}

foreach my $spec (glob("data/SPECS/*.spec")) {
    warn "SKIPPING /rpm-query-in-scriptlet/" if $spec =~ /rpm-query-in-scriptlet/ && $is_bsd;
    next if $spec =~ /rpm-query-in-scriptlet/ && $is_bsd;
    my $name = rpmbuild($spec);

    if ($name eq 'various') {
	system_("cp -r media/$name media/${name}_nohdlist");
	system_("cp -r media/$name media/${name}_no_subdir");
	system_("$genhdlist2 media/${name}_no_subdir");
	symlink "${name}_nohdlist", "media/${name} nohdlist";
    }
    genhdlist_std($name);
}
foreach my $spec (glob("data/SPECS/srpm*.spec")) {
    my $name = rpmbuild_srpm($spec);
    genhdlist_std($name);
}

{
    my $name = 'rpm-v3';
    system_("cp -r data/$name media");
    system_("cp -r media/$name media/${name}_nohdlist");
    system_("cp -r media/$name media/${name}_no_subdir");
    system_("$genhdlist2 media/${name}_no_subdir");
    genhdlist_std($name);
}

mkdir 'media/reconfig';
system_("cp -r data/reconfig.urpmi media/reconfig");

mkdir 'media/media_info';
system_("cp -r data/media.cfg media/media_info");
system_('gendistrib -s .');

sub genhdlist_std {
    my ($medium_name) = @_;
    system_("$genhdlist2 media/$medium_name");
}

sub rpmbuild {
    my ($spec, $o_medium_name) = @_;

    my $dir = getcwd();
    my ($target) = $spec =~ m!-(i586|x86_64)\.spec$!;
    my $extra_args = $target ? "--target $target" : '';
    # unsetting %__os_install_post fixes failure to build on FreeBSD:
    $extra_args .= " --define '__os_install_post %nil'";
    $extra_args .= qq( --define 'rpm_version %(rpm -q --queryformat "%{VERSION}" rpm|sed -e "s/\\\\.//g")' );
    # some FreeBSD CPAN smokers sometimes fails with:
    # error: Couldn't exec /usr/local/lib/rpm/elfdeps: No such file or directory
    $extra_args .= " --define '__elf_provides %nil' --define '__elf_requires %nil'" if $is_bsd;
    system_("rpmbuild --quiet --define '_topdir $dir/tmp' --define '_tmppath $dir/tmp' -bb --clean --nodeps $extra_args $spec");

    my ($name) = $spec =~ m!([^/]*)\.spec$!;

    my $medium_name = $o_medium_name || $name;
    mkdir "media/$medium_name";
    system_("mv tmp/RPMS/*/*.rpm media/$medium_name");

    $medium_name;
}

sub rpmbuild_srpm {
    my ($spec) = @_;

    system_("rpmbuild --quiet --define '_topdir tmp' -bs --clean --nodeps $spec");

    my ($name) = $spec =~ m!([^/]*)\.spec$!;

    my $medium_name = "SRPMS-$name";
    mkdir "media/$medium_name";
    system_("mv tmp/SRPMS/*.rpm media/$medium_name");

    $medium_name;
}

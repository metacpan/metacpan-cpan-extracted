#!/usr/bin/perl


use strict;
use warnings;
use Test::More tests => 41;
use MDV::Packdrakeng;
use URPM;
use URPM::Build;


chdir 't' if -d 't';

# shut up
URPM::setVerbosity(2);

my $a = URPM->new;
ok($a);

END { system('rm -rf hdlist.cz empty_hdlist.cz headers tmp') }

my ($start, $end) = $a->parse_rpms_build_headers(rpms => [ "tmp/RPMS/noarch/test-rpm-1.0-1mdk.noarch.rpm" ], keep_all_tags => 1);
ok(@{$a->{depslist}} == 1);
my $pkg = $a->{depslist}[0];
ok($pkg);
is($pkg->get_tag(1000), 'test-rpm', 'name');
is($pkg->get_tag(1001), '1.0', 'version');
is($pkg->get_tag(1002), '1mdk', 'release');

mkdir 'headers';
system('touch headers/empty');
is(URPM->new->parse_hdlist('headers/empty'), undef, 'empty header');
system('echo FOO > headers/bad');
is(URPM->new->parse_hdlist('headers/bad'), undef, 'bad rpm header');

$a->build_hdlist(
    start  => 0,
    end    => -1,
    hdlist => 'empty_hdlist.cz',
);
ok(-f 'empty_hdlist.cz');

($start, $end) = URPM->new->parse_hdlist('empty_hdlist.cz');
is("$start $end", "0 -1", 'empty hdlist');


$a->build_hdlist(
    start  => 0,
    end    => $#{$a->{depslist}},
    hdlist => 'hdlist.cz',
    ratio  => 9,
);

ok(-f 'hdlist.cz');

my $b = URPM->new;
($start, $end) = $b->parse_hdlist('hdlist.cz', keep_all_tags => 1);
is("$start $end", "0 0", 'parse_hdlist');
ok(@{$b->{depslist}} == 1);
$pkg = $b->{depslist}[0];
ok($pkg);
is($pkg->get_tag(1000), 'test-rpm', 'name');
is($pkg->get_tag(1001), '1.0', 'version');
is($pkg->get_tag(1002), '1mdk', 'release');
is($pkg->queryformat("%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}"), "test-rpm-1.0-1mdk.noarch",
    q(get headers from hdlist));

my $headers = eval { [ $b->parse_rpms_build_headers(rpms => [ "tmp/RPMS/noarch/test-rpm-1.0-1mdk.noarch.rpm" ], 
						    dir => 'headers') ] };
is($@, '', 'parse_rpms_build_headers');
is(int @$headers, 1, 'parse_rpms_build_headers');
ok(@{$b->{depslist}} == 2);
($start, $end) = eval { $b->parse_headers(dir => "headers", headers => $headers) };
is($@, '', 'parse_headers');
is("$start $end", "2 2", 'parse_headers');



# Version comparison
ok(URPM::rpmvercmp("1-1mdk",     "1-1mdk") ==  0, "Same value = 0");
ok(URPM::rpmvercmp("0:1-1mdk",   "1-1mdk") ==  -1, "Same value, epoch 0 on left = 1");
ok(URPM::rpmvercmp("1-1mdk",     "1-2mdk") == -1, "Right value win = -1");
ok(URPM::rpmvercmp("1-2mdk",     "1-1mdk") ==  1, "Left value win = 1");
ok(URPM::rpmvercmp("1:1-1mdk", "2:1-1mdk") == -1, "epoch 1 vs 2 = -1");

{
    open(my $hdfh, "zcat hdlist.cz 2>/dev/null |") or die $!;
    my $pkg = URPM::stream2header($hdfh);
    ok(defined $pkg, "Reading a header works");
    is($pkg->get_tag(1000), 'test-rpm');
    is($pkg->get_tag(1001), '1.0');
    is($pkg->get_tag(1002), '1mdk');
    is($pkg->queryformat("%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}"), "test-rpm-1.0-1mdk.noarch");
    ok($pkg->is_arch_compat(), "Arch compat works");
    close $hdfh;
}

{
    my $pkg = URPM::spec2srcheader("test-rpm.spec");
    ok(defined $pkg, "Parsing a spec works");
    is($pkg->arch, 'src', 'spec file arch is "src"');
    is($pkg->get_tag(1000), 'test-rpm', 'parsed correctly');
    $pkg = URPM::spec2srcheader("doesnotexist.spec");
    ok(!defined $pkg, "non-existent spec");
    open my $f, '>', 'bad.spec' or die "Can't write bad.spec: $!\n";
    print $f "Name: foo\nVerssion: 2\n";
    close $f;
    $pkg = URPM::spec2srcheader("bad.spec");
    ok(!defined $pkg, "bad spec");
    END { unlink "bad.spec" }
}

{
    my $c = URPM->new;
    $c->parse_rpm('tmp/SRPMS/test-rpm-1.0-1mdk.src.rpm');
    my $pkg = $c->{depslist}[0];
    ok(defined $pkg, "Parsing a srpm works");
    is($pkg->arch, 'src', 'srpm arch is "src"');
}

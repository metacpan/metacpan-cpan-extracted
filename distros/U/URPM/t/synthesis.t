#!/usr/bin/perl

use strict ;
use warnings ;
use Test::More tests => 116;
use URPM;

chdir 't' if -d 't';
my $file1 = 'synthesis.sample.cz';
my $file2 = 'synthesis.sample-xz.cz';

my $s = <<'EOF';
@provides@glibc-devel[== 6:2.2.4-25mdk]
@requires@/sbin/install-info@glibc[== 2.2.4]@kernel-headers@kernel-headers[>= 2.2.1]@/bin/sh@/bin/sh@/bin/sh@rpmlib(PayloadFilesHavePrefix)[<= 4.0-1]@rpmlib(CompressedFileNames)[<= 3.0.4-1]
@conflicts@texinfo[< 3.11]@gcc[< 2.96-0.50mdk]
@obsoletes@libc-debug@libc-headers@libc-devel@linuxthreads-devel@glibc-debug[< 3]
@info@glibc-devel-2.2.4-25mdk.i586@6@45692097@Development/C
EOF

open my $f, "| gzip -9 >$file1";
print $f $s;
close $f;

open $f, "| xz -9 >$file2";
print $f $s;
$s =~ s/-devel//g;
print $f $s;
close $f;

$s = <<'EOF';
@provides@python3-fonttools+ufo[== 4.18.2-4.mga9]@python3dist(fonttools[ufo])[== 4.18.2]
@summary@Metapackage for python3-fonttools: ufo extras
@info@python3-fonttools+ufo-4.18.2-4.mga9.noarch@0@221683@Development/Other
@provides@config(dovecot)[== 2.3.19.1-2.mga9]
@requires@openssl[*]@rpm-helper[*][>= 0.21]
@summary@Secure IMAP and POP3 server
@info@dovecot-2.3.19.1-2.mga9.x86_64@0@17815993@System/Servers
@provides@openimageio[== 2.3.20.0-2.mga9]@font(:lang=aa)
@summary@Library for reading and writing images
@info@openimageio-2.3.20.0-2.mga9.x86_64@0@42@Development/Other
EOF

my $file3 = 'synthesis.squarebrackets.cz';
open $f, "| gzip -9 >$file3";
print $f $s;
close $f;

END { unlink $file1, $file2, $file3 }

my $a = URPM->new;
ok($a);

my ($first, $end);

($first, $end) = URPM->new->parse_synthesis($file2);
ok($first == 0 && $end == 1, 'parse XZ synthesis');

($first, $end) = URPM->new->parse_synthesis('empty_synthesis.cz');
is("$first $end", "0 -1", 'parse empty synthesis');

is(URPM->new->parse_synthesis('buggy_synthesis.cz'), undef, 'parse buggy synthesis');

($first, $end) = $a->parse_synthesis($file1);
ok($first == 0 && $end == 0);
is(int @{$a->{depslist}}, 1);
ok(keys(%{$a->{provides}}) == 3);
ok(defined $a->{provides}{'glibc-devel'});
ok(exists $a->{provides}{'/bin/sh'});
ok(! defined $a->{provides}{'/bin/sh'});
ok(exists $a->{provides}{'/sbin/install-info'});
ok(! defined $a->{provides}{'/sbin/install-info'});

my $pkg = $a->{depslist}[0];
ok($pkg);
ok($pkg->name eq 'glibc-devel');
ok($pkg->version eq '2.2.4');
ok($pkg->release eq '25mdk');
ok($pkg->arch eq 'i586');
ok($pkg->fullname eq 'glibc-devel-2.2.4-25mdk.i586');
ok(!defined $pkg->buildarchs);
ok(!defined $pkg->buildhost);
is($pkg->buildtime,0);
ok(!defined $pkg->changelog_name);
ok(!defined $pkg->changelog_text);
ok(!defined $pkg->changelog_time);

my ($name, $version, $release, $arch, @l) = $pkg->fullname;
ok(@l == 0);
ok($name eq 'glibc-devel');
ok($version eq '2.2.4');
ok($release eq '25mdk');
ok($arch eq 'i586');

ok($pkg->epoch == 6);
ok($pkg->size == 45692097);
ok($pkg->group eq 'Development/C');
ok($pkg->filename eq 'glibc-devel-2.2.4-25mdk.i586.rpm');
ok(defined $pkg->id);
ok($pkg->id == 0);
ok($pkg->set_id(6) == 0);
ok($pkg->id == 6);
ok($pkg->set_id == 6);
ok(! defined $pkg->id);
ok(! defined $pkg->set_id(0));
ok(defined $pkg->id);
ok($pkg->id == 0);

my @obsoletes = $pkg->obsoletes;
ok(@obsoletes == 5);
ok($obsoletes[0] eq 'libc-debug');
ok($obsoletes[4] eq 'glibc-debug[< 3]');

my @obsoletes_nosense = $pkg->obsoletes_nosense;
ok(@obsoletes_nosense == 5);
ok($obsoletes_nosense[0] eq 'libc-debug');
ok($obsoletes_nosense[4] eq 'glibc-debug');

my @conflicts = $pkg->conflicts;
ok(@conflicts == 2);
ok($conflicts[0] eq 'texinfo[< 3.11]');
ok($conflicts[1] eq 'gcc[< 2.96-0.50mdk]');

my @requires = $pkg->requires;
ok(@requires == 9);
ok($requires[0] eq '/sbin/install-info');
ok($requires[8] eq 'rpmlib(CompressedFileNames)[<= 3.0.4-1]');

my @provides = $pkg->provides;
ok(@provides == 1);
ok($provides[0] eq 'glibc-devel[== 6:2.2.4-25mdk]');

my @files = $pkg->files;
ok(@files == 0);

ok($pkg->compare("6:2.2.4-25mdk") == 0);
ok($pkg->compare("2.2.4-25mdk") > 0);
ok($pkg->compare("6:2.2.4") == 0);
ok($pkg->compare("2.2.3") > 0);
ok($pkg->compare("2.2") > 0);
ok($pkg->compare("2") > 0);
ok($pkg->compare("2.2.4.0") > 0);
ok($pkg->compare("2.2.5") > 0);
ok($pkg->compare("2.1.7") > 0);
ok($pkg->compare("2.3.1") > 0);
ok($pkg->compare("2.2.31") > 0);
ok($pkg->compare("2.2.4-25") > 0);
ok($pkg->compare("2.2.4-25.1mdk") > 0);
ok($pkg->compare("2.2.4-24mdk") > 0);
ok($pkg->compare("2.2.4-26mdk") > 0);
ok($pkg->compare("6:2.2.4-25.1mdk") < 0);
ok($pkg->compare("6:2.2.4.0") < 0);
ok($pkg->compare("6:2.2.5") < 0);
ok($pkg->compare("6:2.2.31") < 0);
ok($pkg->compare("6:2.3.1") < 0);
ok($pkg->compare("6:2.2.4-24mdk") > 0);
ok($pkg->compare("6:2.2.4-26mdk") < 0);
ok($pkg->compare("7:2.2.4-26mdk") < 0);
ok($pkg->compare("7:2.2.4-24mdk") < 0);

ok($a->traverse() == 1);

my $test = 0;
ok($a->traverse(sub { my ($pkg) = @_; $test = $pkg->name eq 'glibc-devel' }) == 1);
ok($test);
ok($a->traverse_tag('name', [ 'glibc-devel' ]) == 1);
ok($a->traverse_tag('name', [ 'glibc' ]) == 0);

$test = 0;
ok($a->traverse_tag('name', [ 'glibc-devel' ], sub { my ($pkg) = @_; $test = $pkg->name eq 'glibc-devel' }) == 1);
ok($test);

@conflicts = $pkg->conflicts_nosense;
ok(@conflicts == 2);
ok($conflicts[0] eq 'texinfo');
ok($conflicts[1] eq 'gcc');

@requires = $pkg->requires_nosense;
ok(@requires == 9);
ok($requires[0] eq '/sbin/install-info');
ok($requires[1] eq 'glibc');
ok($requires[3] eq 'kernel-headers');
ok($requires[8] eq 'rpmlib(CompressedFileNames)');

@provides = $pkg->provides_nosense;
ok(@provides == 1);
ok($provides[0] eq 'glibc-devel');

my $b = URPM->new;
$b->parse_synthesis($file3);
$pkg = $b->{depslist}[0];
ok($pkg);
is($pkg->name, 'python3-fonttools+ufo');
@provides = $pkg->provides;
is(@provides, 2);
is($provides[1], 'python3dist(fonttools[ufo])[== 4.18.2]');
@provides = $pkg->provides_nosense;
is(@provides, 2);
is($provides[1], 'python3dist(fonttools[ufo])');
$pkg = $b->{depslist}[1];
ok($pkg);
is($pkg->name, 'dovecot');
@requires = $pkg->requires;
is(@requires, 2);
is($requires[0], 'openssl[*]');
is($requires[1], 'rpm-helper[*][>= 0.21]');
@requires = $pkg->requires_nosense;
is(@requires, 2);
is($requires[0], 'openssl');
is($requires[1], 'rpm-helper');
$pkg = $b->{depslist}[2];
ok($pkg);
is($pkg->name, 'openimageio');
@provides = $pkg->provides;
is(@provides, 2);
is($provides[1], 'font(:lang=aa)');


#!/usr/bin/perl

use strict;
use Test::More 'no_plan';
use File::Slurp;

BEGIN { use_ok 'urpm::cfg' }
BEGIN { use_ok 'urpm::download' }

my $file = 'testurpmi.cfg';
my $proxyfile = $urpm::download::PROXY_CFG = 'testproxy.cfg';
open my $f, '>', $file or die $!;
print $f (my $cfgtext = <<'URPMICFG');
{
  downloader: wget
  fuzzy: no
  verify-rpm: 0
}

update\ 1 http://foo/bar/$RELEASE {
  compress: 1
  fuzzy: 1
  keep: yes
  key-ids: "123"
  update
  verify-rpm: yes
}

update_2 ftp://foo/bar/ {
  ignore
  key_ids: 456 789
  priority-upgrade: 'kernel'
  with_synthesis: synthesis.hdlist.update2.cz
}
URPMICFG
close $f;

my $config = urpm::cfg::load_config($file);
ok( ref $config, 'config loaded' );

is($config->{global}{downloader}, 'wget', 'config is wget');
ok(my ($update_2) = (grep { $_->{name} eq 'update_2' } @{$config->{media}}), 'update_2 medium exists');
is($update_2->{url}, 'ftp://foo/bar/', 'url is ftp');
ok(my ($update_1) = (grep { $_->{name} eq 'update 1' } @{$config->{media}}), 'update_1 medium exists');
is($update_1->{url}, 'http://foo/bar/' . urpm::cfg::get_release(), 'url is http');

my $config_verbatim = urpm::cfg::load_config_raw($file, 1);
ok( ref $config_verbatim, 'config loaded' );

unlink "$file.verbatim", "$file.bad";
urpm::util::copy($file, "$file.state"); #- dump_config has a state
ok( urpm::cfg::dump_config_raw("$file.verbatim", $config_verbatim), 'config written' );
ok( urpm::cfg::dump_config("$file.bad", $config), 'config written' );
ok( urpm::cfg::dump_config("$file.state", $config), 'config written' );

# things that have been tidied up by dump_config
$cfgtext =~ s/\byes\b/1/g;
$cfgtext =~ s/\bno\b/0/g;
$cfgtext =~ s/\bkey_ids\b/key-ids/g;
$cfgtext =~ s/"123"/123/g;
$cfgtext =~ s/'kernel'/kernel/g;

{
my $cfgtext2 = read_file("$file.verbatim");
$cfgtext2 =~ s/# generated.*\n//;
is( $cfgtext, $cfgtext2, 'config is the same' )
    or system qw( diff -u ), $file, "$file.verbatim";
}
{
my $cfgtext2 = read_file("$file.bad");
$cfgtext2 =~ s/# generated.*\n//;
isnt( $cfgtext, $cfgtext2, 'config should differ' )
    or system qw( diff -u ), "$file.verbatim", "$file.bad";
}
{
my $cfgtext2 = read_file("$file.state");
$cfgtext2 =~ s/# generated.*\n//;
is( $cfgtext, $cfgtext2, 'config is the same' )
    or system qw( diff -u ), "$file.verbatim", "$file.state";
}



open $f, '>', $proxyfile or die $!;
print $f ($cfgtext = <<PROXYCFG);
http_proxy=http://foo:8080/
local:http_proxy=http://yoyodyne:8080/
local:proxy_user=rafael:richard
PROXYCFG
close $f;

my $p = get_proxy();
is( $p->{http_proxy}, 'http://foo:8080/', 'read proxy' );
ok( !defined $p->{user}, 'no user defined' );
$p = get_proxy('local');
is( $p->{http_proxy}, 'http://yoyodyne:8080/', 'read media proxy' );
is( $p->{user}, 'rafael', 'proxy user' );
is( $p->{pwd}, 'richard', 'proxy password' );
ok( dump_proxy_config(), 'dump_proxy_config' );
my $cfgtext2 = read_file($proxyfile);
$cfgtext2 =~ s/# generated.*\n//;
is( $cfgtext, $cfgtext2, 'dumped correctly' );
set_proxy_config(http_proxy => '');
ok( dump_proxy_config(), 'dump_proxy_config erased' );
$cfgtext2 = read_file($proxyfile);
$cfgtext2 =~ s/# generated.*\n//;
$cfgtext =~ s/^http_proxy.*\n//;
is( $cfgtext, $cfgtext2, 'dumped correctly' );

END { unlink $file, glob("$file.*"), $proxyfile }

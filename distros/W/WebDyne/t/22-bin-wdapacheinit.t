use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file write_module);
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Cwd qw(realpath);
use Config qw(%Config);

my $script=File::Spec->catfile('bin', 'wdapacheinit');
ok(-f $script, 'wdapacheinit script exists');

sub test_uname {

    foreach my $name (qw(nobody apache apache2 www wwwrun httpd httpd2 www-data daemon bin)) {
        my $uid=getpwnam($name);
        return $name if defined($uid) && $uid > 0;
    }
    setpwent();
    while (my @pw=getpwent()) {
        if (defined($pw[2]) && $pw[2] > 0) {
            endpwent();
            return $pw[0];
        }
    }
    endpwent();
    return;

}

sub test_gname {

    foreach my $name (qw(nobody apache apache2 www wwwrun httpd httpd2 www-data daemon bin)) {
        my $gid=getgrnam($name);
        return $name if defined($gid) && $gid > 0;
    }
    setgrent();
    while (my @gr=getgrent()) {
        if (defined($gr[2]) && $gr[2] > 0) {
            endgrent();
            return $gr[0];
        }
    }
    endgrent();
    return;

}

my $perl_bin=$^X;
unless (File::Spec->file_name_is_absolute($perl_bin)) {
    if (
        $Config{'perlpath'} &&
        File::Spec->file_name_is_absolute($Config{'perlpath'}) &&
        -f $Config{'perlpath'}
    ) {
        $perl_bin=$Config{'perlpath'};
    }
    else {
        foreach my $dir (grep {length} split(/:/, $ENV{'PATH'} || q())) {
            my $candidate=File::Spec->catfile($dir, $perl_bin);
            if (-f $candidate && -x $candidate) {
                $perl_bin=$candidate;
                last;
            }
        }
    }
}

my ($version_out, $version_err, $version_rc)=run_cmd($perl_bin, '-Ilib', $script, '--version');
is($version_rc, 0, 'wdapacheinit --version exits cleanly');
like($version_out, qr/wdapacheinit version: \S+/, 'wdapacheinit --version reports script version');
is($version_err, '', 'wdapacheinit --version writes no stderr');

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'WebDyne::Install::Apache::Constant', <<'END_MODULE');
package WebDyne::Install::Apache::Constant;
use strict;
use warnings;
our %Constant=(
    HTTPD_BIN => '/tmp/httpd',
    APXS_BIN => '/tmp/apxs',
    DIR_APACHE_CONF => '/tmp/apache-conf',
);
1;
END_MODULE
write_module($stub_dn, 'WebDyne::Install::Apache', <<'END_MODULE');
package WebDyne::Install::Apache;
use strict;
use warnings;
use WebDyne::Install::Apache::Constant;
sub install {
    my ($class, $prefix_dn, $realbin, $opt_hr)=@_;
    print "method=install\n";
    print "cache=$opt_hr->{webdyne_cache_dn}\n" if exists $opt_hr->{webdyne_cache_dn};
    print "text=$opt_hr->{text}\n" if exists $opt_hr->{text};
    print "dry_run=$opt_hr->{dry_run}\n" if exists $opt_hr->{dry_run};
    return \0;
}
sub uninstall {
    my ($class, $prefix_dn, $realbin, $opt_hr)=@_;
    print "method=uninstall\n";
    print "cache=$opt_hr->{webdyne_cache_dn}\n" if exists $opt_hr->{webdyne_cache_dn};
    print "text=$opt_hr->{text}\n" if exists $opt_hr->{text};
    print "dry_run=$opt_hr->{dry_run}\n" if exists $opt_hr->{dry_run};
    print "mp2=$opt_hr->{mp2}\n" if exists $opt_hr->{mp2};
    return \0;
}
1;
END_MODULE

my ($stdout, $stderr, $rc)=run_cmd(
    $perl_bin, '-I', $stub_dn, '-Ilib', $script,
    '--uninstall', '--cache', '/tmp/webdyne-cache', '--text', '--dry_run', '--mp2'
);
is($rc, 0, 'wdapacheinit stubbed uninstall exits cleanly');
like($stdout, qr/method=uninstall/, 'wdapacheinit dispatches uninstall mode');
like($stdout, qr/cache=\/tmp\/webdyne-cache/, 'wdapacheinit forwards cache option');
like($stdout, qr/text=1/, 'wdapacheinit forwards text option');
like($stdout, qr/dry_run=1/, 'wdapacheinit forwards dry_run option');
like($stdout, qr/mp2=1/, 'wdapacheinit forwards mp2 option');
is($stderr, '', 'wdapacheinit stubbed uninstall writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $perl_bin, '-I', $stub_dn, '-Ilib', $script,
    '--dump_opt',
    '--webdyne-cache-dn', '/tmp/webdyne-cache',
    '--dir-apache-conf', '/tmp/apache-conf',
    '--file-mod-perl-lib', '/tmp/mod_perl.so',
    '--apxs-bin', '/tmp/apxs',
    '--apachectl-bin', '/tmp/apachectl',
);
isnt($rc, 0, 'wdapacheinit --dump_opt aborts after dumping options');
is($stdout, '', 'wdapacheinit --dump_opt writes no stdout');
like($stderr, qr/'dump_opt'\s*=>\s*1/, 'wdapacheinit --dump_opt dumps dump_opt flag');
like($stderr, qr/'webdyne_cache_dn'\s*=>\s*'\/tmp\/webdyne-cache'/, 'wdapacheinit accepts hyphenated cache alias');
like($stderr, qr/'dir_apache_conf'\s*=>\s*'\/tmp\/apache-conf'/, 'wdapacheinit accepts hyphenated Apache config alias');
like($stderr, qr/'file_mod_perl_lib'\s*=>\s*'\/tmp\/mod_perl\.so'/, 'wdapacheinit accepts hyphenated mod_perl alias');
like($stderr, qr/'apxs_bin'\s*=>\s*'\/tmp\/apxs'/, 'wdapacheinit accepts hyphenated APXS alias');
like($stderr, qr/'apachectl_bin'\s*=>\s*'\/tmp\/apachectl'/, 'wdapacheinit accepts hyphenated apachectl alias');

($stdout, $stderr, $rc)=run_cmd(
    $perl_bin, '-I', $stub_dn, '-Ilib', $script,
    '--dump_config',
);
isnt($rc, 0, 'wdapacheinit --dump_config aborts after dumping discovered config');
is($stdout, '', 'wdapacheinit --dump_config writes no stdout');
like($stderr, qr/'HTTPD_BIN'\s*=>\s*'\/tmp\/httpd'/, 'wdapacheinit --dump_config dumps resolved Apache binary');
like($stderr, qr/'APXS_BIN'\s*=>\s*'\/tmp\/apxs'/, 'wdapacheinit --dump_config dumps resolved APXS binary');

my $fake_root=tempdir(CLEANUP => 1);
my $fake_bin_dn=File::Spec->catdir($fake_root, 'bin');
my $fake_apache_dn=File::Spec->catdir($fake_root, 'apache2');
my $fake_module_dn=File::Spec->catdir($fake_root, 'modules');
make_path(
    $fake_bin_dn,
    $fake_module_dn,
    File::Spec->catdir($fake_apache_dn, 'conf-available'),
    File::Spec->catdir($fake_apache_dn, 'conf-enabled'),
);
my $fake_httpd=write_file(File::Spec->catfile($fake_bin_dn, 'httpd'), <<"END_HTTPD");
#!/bin/sh
case "\$1" in
  -V)
    echo "Server version: Apache/2.4.99"
    echo " -D HTTPD_ROOT=\\"$fake_apache_dn\\""
    echo " -D SERVER_CONFIG_FILE=\\"apache2.conf\\""
    ;;
  -v)
    echo "Server version: Apache/2.4.99"
    ;;
esac
END_HTTPD
my $fake_apachectl=write_file(File::Spec->catfile($fake_bin_dn, 'apachectl'), <<"END_APACHECTL");
#!/bin/sh
exec "$fake_httpd" "\$@"
END_APACHECTL
my $fake_apxs=write_file(File::Spec->catfile($fake_bin_dn, 'apxs'), <<"END_APXS");
#!/bin/sh
case "\$2" in
  LIBEXECDIR) echo "$fake_module_dn" ;;
  SYSCONFDIR) echo "$fake_apache_dn" ;;
  *) exit 1 ;;
esac
END_APXS
chmod 0755, $fake_httpd, $fake_apachectl, $fake_apxs;

my $fake_apache_uname=test_uname();
my $fake_apache_gname=test_gname();

sub with_fake_apache_env {

    my $code=shift();
    local $ENV{'PATH'}=$fake_bin_dn;
    local $ENV{'HTTPD_BIN'}=$fake_httpd;
    local $ENV{'APACHE_TEST_HTTPD'}=$fake_httpd;
    local $ENV{'APACHECTL_BIN'}=$fake_apachectl;
    local $ENV{'APACHECTL'}=$fake_apachectl;
    local $ENV{'APXS_BIN'}=$fake_apxs;
    local $ENV{'APXS'}=$fake_apxs;
    local $ENV{'APACHE_TEST_APXS'}=$fake_apxs;
    local $ENV{'APACHE_UNAME'}=$fake_apache_uname;
    local $ENV{'APACHE_GNAME'}=$fake_apache_gname;
    local $ENV{'FILE_MOD_PERL_LIB'}=File::Spec->catfile($fake_module_dn, 'mod_perl.so');
    return $code->();

}

SKIP: {

skip 'no non-root local user/group available for fake Apache install tests', 42
    unless $fake_apache_uname && $fake_apache_gname;

with_fake_apache_env(sub {
    write_file($ENV{'FILE_MOD_PERL_LIB'}, '');
    ($stdout, $stderr, $rc)=run_cmd(
        $perl_bin, '-Ilib',
        '-MWebDyne::Install::Apache::Constant',
        '-MData::Dumper',
        '-e',
        'local $Data::Dumper::Sortkeys=1; print Data::Dumper::Dumper(\%WebDyne::Install::Apache::Constant::Constant)'
    );
});
is($rc, 0, 'Apache constant discovery works with fake httpd/apxs');
is($stderr, '', 'Apache constant discovery suppresses unsupported APXS query warnings');
like($stdout, qr/'APXS_BIN'\s*=>\s*'\Q$fake_apxs\E'/, 'Apache constant discovery finds APXS');
like($stdout, qr/'DIR_APACHE_MODULES'\s*=>\s*'\Q$fake_module_dn\E'/, 'Apache constant discovery uses APXS module directory');
my $fake_conf_available=realpath(File::Spec->catdir($fake_apache_dn, 'conf-available'));
my $fake_conf_enabled=realpath(File::Spec->catdir($fake_apache_dn, 'conf-enabled'));
like($stdout, qr/'DIR_APACHE_CONF'\s*=>\s*'\Q$fake_conf_available\E'/, 'Apache constant discovery prefers conf-available');
like($stdout, qr/'DIR_APACHE_CONF_ENABLED'\s*=>\s*'\Q$fake_conf_enabled\E'/, 'Apache constant discovery records conf-enabled');

my $dry_cache_dn=File::Spec->catdir($fake_root, 'cache-dry-run');
with_fake_apache_env(sub {
    ($stdout, $stderr, $rc)=run_cmd(
        $perl_bin, '-Ilib', $script,
        '--dry_run',
        '--cache', $dry_cache_dn,
    );
});
is($rc, 0, 'wdapacheinit --dry_run install exits cleanly with fake Apache');
is($stderr, '', 'wdapacheinit --dry_run install writes no stderr');
like($stdout, qr/Would create cache directory/, 'wdapacheinit --dry_run reports cache creation');
like($stdout, qr/Would write Apache config file/, 'wdapacheinit --dry_run reports Apache config write');
like($stdout, qr/Would write Webdyne config file/, 'wdapacheinit --dry_run reports WebDyne config write');
like($stdout, qr/Would enable Apache config link/, 'wdapacheinit --dry_run reports Debian enable link');
ok(!-e $dry_cache_dn, 'wdapacheinit --dry_run does not create cache directory');
ok(!-e File::Spec->catfile($fake_conf_available, 'webdyne.conf'), 'wdapacheinit --dry_run does not write Apache config');
ok(!-e File::Spec->catfile($fake_conf_available, 'webdyne_conf.pl'), 'wdapacheinit --dry_run does not write WebDyne config');
ok(!-e File::Spec->catfile($fake_conf_enabled, 'webdyne.conf'), 'wdapacheinit --dry_run does not create enabled config link');

my $text_cache_dn=File::Spec->catdir($fake_root, 'cache-text');
my $text_webdyne_conf=File::Spec->catfile($fake_conf_available, 'webdyne.conf');
with_fake_apache_env(sub {
    ($stdout, $stderr, $rc)=run_cmd(
        $perl_bin, '-Ilib', $script,
        '--text',
        '--cache', $text_cache_dn,
    );
});
is($rc, 0, 'wdapacheinit --text install exits cleanly with fake Apache');
is($stderr, '', 'wdapacheinit --text install writes no stderr');
like($stdout, qr/# \Q$text_webdyne_conf\E/, 'wdapacheinit --text prints Apache config fragment');
like($stdout, qr/\Q$text_cache_dn\E/, 'wdapacheinit --text uses resolved cache directory in output');
ok(!-e $text_cache_dn, 'wdapacheinit --text does not create cache directory');
ok(!-e $text_webdyne_conf, 'wdapacheinit --text does not write Apache config');

make_path($dry_cache_dn);
my $cache_file=write_file(File::Spec->catfile($dry_cache_dn, '0123456789abcdef0123456789abcdef'), 'cache');
my $cache_html_file=write_file(File::Spec->catfile($dry_cache_dn, '0123456789abcdef0123456789abcdef.html'), 'cache html');
my $cache_keep_file=write_file(File::Spec->catfile($dry_cache_dn, 'keep.txt'), 'keep');
my $apache_conf_file=write_file(File::Spec->catfile($fake_conf_available, 'webdyne.conf'), 'apache config');
my $webdyne_conf_file=write_file(File::Spec->catfile($fake_conf_available, 'webdyne_conf.pl'), 'webdyne config');
my $enabled_link=File::Spec->catfile($fake_conf_enabled, 'webdyne.conf');
symlink($apache_conf_file, $enabled_link) || die "unable to create test symlink $enabled_link, $!";
with_fake_apache_env(sub {
    ($stdout, $stderr, $rc)=run_cmd(
        $perl_bin, '-Ilib', $script,
        '--uninstall',
        '--dry_run',
        '--cache', $dry_cache_dn,
    );
});
is($rc, 0, 'wdapacheinit --dry_run uninstall exits cleanly with fake Apache');
is($stderr, '', 'wdapacheinit --dry_run uninstall writes no stderr');
like($stdout, qr/Would remove cache file/, 'wdapacheinit --dry_run uninstall reports cache file removal');
like($stdout, qr/Would remove config file/, 'wdapacheinit --dry_run uninstall reports config removal');
like($stdout, qr/Would remove enabled Apache config link/, 'wdapacheinit --dry_run uninstall reports enabled link removal');
ok(-e $cache_file, 'wdapacheinit --dry_run uninstall keeps cache file');
ok(-e $cache_html_file, 'wdapacheinit --dry_run uninstall keeps cache html file');
ok(-e $cache_keep_file, 'wdapacheinit --dry_run uninstall keeps non-cache file');
ok(-e $apache_conf_file, 'wdapacheinit --dry_run uninstall keeps Apache config');
ok(-e $webdyne_conf_file, 'wdapacheinit --dry_run uninstall keeps WebDyne config');
ok(-l $enabled_link, 'wdapacheinit --dry_run uninstall keeps enabled config link');

unlink($enabled_link) || die "unable to remove test symlink $enabled_link, $!";
symlink('/tmp/not-webdyne.conf', $enabled_link) || die "unable to create non-target test symlink $enabled_link, $!";
with_fake_apache_env(sub {
    ($stdout, $stderr, $rc)=run_cmd(
        $perl_bin, '-Ilib', $script,
        '--uninstall',
        '--cache', $dry_cache_dn,
    );
});
is($rc, 0, 'wdapacheinit uninstall exits cleanly with non-target enabled symlink');
is($stderr, '', 'wdapacheinit uninstall with non-target enabled symlink writes no stderr');
like($stdout, qr/Not removing enabled Apache config link/, 'wdapacheinit uninstall reports non-target enabled symlink');
ok(-l $enabled_link, 'wdapacheinit uninstall keeps non-target enabled symlink');
ok(!-e $apache_conf_file, 'wdapacheinit uninstall removes Apache config file');
ok(!-e $webdyne_conf_file, 'wdapacheinit uninstall removes WebDyne config file');
ok(!-e $cache_file, 'wdapacheinit uninstall removes cache file');
ok(!-e $cache_html_file, 'wdapacheinit uninstall removes cache html file');
ok(-e $cache_keep_file, 'wdapacheinit uninstall keeps non-cache file');

}

done_testing();

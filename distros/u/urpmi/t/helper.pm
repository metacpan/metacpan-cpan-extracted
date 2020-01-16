package helper;

use Test::More;
use urpm::select;
use urpm::util;
use base 'Exporter';
our @EXPORT = qw(need_root_and_prepare need_downloader
		 are_weak_deps_supported
		 start_httpd httpd_port
		 urpmi_addmedia urpmi_removemedia urpmi_update
		 urpm_cmd run_urpm_cmd urpmi_cmd urpmi urpmi_partial test_urpmi_fail urpme
		 urpmi_cfg set_urpmi_cfg_global_options
		 system_ system_should_fail
		 check_installed_fullnames check_installed_names check_nothing_installed
		 check_installed_and_remove check_installed_fullnames_and_remove check_installed_and_urpme
	    );

my $using_root;
sub need_root_and_prepare() {
    if ($< != 0) {
	#- can't test
	pass();
	exit(0);
    }
    -d 'media' or die "02create_pkgs.t not done\n";

    system('rm -rf root');
    isnt(-d 'root', "test root dir can not be removed $!");
    system('mkdir -p root/etc/rpm');
    system('echo "%_pkgverify_level none" >root/etc/rpm/macros');
    $using_root = 1;
    $ENV{LC_ALL} = 'C';
}

sub need_downloader() {
    my @dl_helpers = qw(wget curl prozilla aria2c);
    my $found;
    foreach (@dl_helpers) {
	-e "/bin/$_" and $found = 1;
    }
    if (!$found) {
	warn "SKIPing because we're missing a downloader. We need one of wget/curl/prozilla/aria2c";
	#plan skip_all => "*BSD fails those";
	exit 0;
    }
}


my $server_pid;
sub httpd_port() { 6969 }
sub start_httpd() {
    system('perl -MNet::Server::Single -e 1') == 0 or die "module Net::Server::Single is missing (package perl-Net-Server)\n";
    $server_pid = fork();
    if ($server_pid == 0) {
	exec './simple-httpd', $::pwd, "$::pwd/tmp", httpd_port();
	exit 1;
    }
    'http://localhost:' . httpd_port();
}

chdir 't' if -d 't';

mkdir 'tmp';
chomp($::pwd = `pwd`);
my $urpmi_debug_opt = '-q';
#$urpmi_debug_opt = '-v --debug';

sub urpm_cmd {
    my ($prog, $o_perl_para) = @_;
    $o_perl_para ||= '';
    "perl $o_perl_para -I.. ../$prog --urpmi-root $::pwd/root $urpmi_debug_opt";
}
sub urpm_cmd_no_quiet {
    my ($prog, $o_perl_para) = @_;
    $o_perl_para ||= '';
    "perl $o_perl_para -I.. ../$prog --urpmi-root $::pwd/root";
}
sub run_urpm_cmd {
    my ($prog, $o_perl_para) = @_;
    my $cmd = urpm_cmd_no_quiet($prog, $o_perl_para);
    print "# $cmd\n";
    `$cmd`;
}
sub urpmi_cmd() { urpm_cmd('urpmi') }

sub urpmi_addmedia {
    my ($para) = @_;
    system_(urpm_cmd('urpmi.addmedia --no-verify-rpm') . " $para");
}
sub urpmi_removemedia {
    my ($para) = @_;
    system_(urpm_cmd('urpmi.removemedia') . " $para");
}
sub urpmi_update {
    my ($para) = @_;
    system_(urpm_cmd('urpmi.update') . " $para");
}
sub urpmi_partial {
    my ($para) = @_;
    system_should_partially_fail(urpmi_cmd() . " --ignoresize $para");
}
sub urpmi {
    my ($para) = @_;
    system_(urpmi_cmd() . " --ignoresize $para");
}
sub test_urpmi_fail {
    my ($para) = @_;
    system_should_fail(urpmi_cmd() . " $para");
}
sub urpme {
    my ($para) = @_;
    system_(urpm_cmd('urpme') . " $para");
}
sub urpmi_cfg() {
    "$::pwd/root/etc/urpmi/urpmi.cfg";
}
sub set_urpmi_cfg_global_options {
    my ($options) = @_;
    require_ok('urpm::cfg');
    ok(my $config = urpm::cfg::load_config(urpmi_cfg()));
    $config->{global} = $options;
    ok(urpm::cfg::dump_config(urpmi_cfg(), $config), 'set_urpmi_cfg_global_options');
}

sub system_ {
    my ($cmd) = @_;
    system($cmd);
    ok($? == 0, $cmd);
}
sub system_should_partially_fail {
    my ($cmd) = @_;
    system($cmd);
    ok($? == 17 << 8, $cmd);
}
sub system_should_fail {
    my ($cmd) = @_;
    system($cmd);
    # on some error questions ("Do you want to... (y/N)?"), urpmi doesn't output "\n":
    print "\n";
    $? & 127 ? is($? & 127, 0, "should fail nicely but not get killed: $cmd")
             : ok($? != 0, "should fail: $cmd");
}

sub check_installed_fullnames {
    my (@names) = @_;
    is(`rpm -qa --qf '%{NVR}\\n' --root $::pwd/root | sort`, join('', map { "$_\n" } sort(@names)));
}

sub check_installed_names {
    my (@names) = @_;
    is(`rpm -qa --qf '%{name}\\n' --root $::pwd/root | sort`, join('', map { "$_\n" } sort(@names)));
}

sub check_nothing_installed() {
    is(`rpm -qa --root $::pwd/root`, '');    
}

sub check_installed_and_remove {
    my (@names) = @_;
    check_installed_names(@names);
    system_("rpm --root $::pwd/root -e " . join(' ', @names)) if @names;
    check_nothing_installed();
}

sub check_installed_fullnames_and_remove {
    my (@names) = @_;
    check_installed_fullnames(@names);
    system_("rpm --root $::pwd/root -e " . join(' ', @names)) if @names;
    check_nothing_installed();
}

sub check_installed_and_urpme {
    my (@names) = @_;
    check_installed_names(@names);
    urpme(join(' ', @names));
    check_nothing_installed();
}

sub are_weak_deps_supported() {
    return urpm::select::_rpm_version() gt 4.12.0
}

END { 
    $using_root and system('rm -rf root');
    $server_pid and kill(9, $server_pid);
    system('rm -rf tmp');
}

1;

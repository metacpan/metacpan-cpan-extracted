#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';
use Cwd 'getcwd';


need_root_and_prepare();

need_downloader();

my $url = start_httpd();
sleep(1); # give time to server to start
is(`cat tmp/error.log`, '', 'server error logs are empty');

my $name = 'various';

test($_) foreach 'various', 'various_no_subdir';
test_exotic_medium_name();

sub test {
    my ($medium_name) = @_;

    urpmi_addmedia("$medium_name $url/media/$medium_name");
    urpmi($name);
    check_installed_fullnames("$name-1-1");
    urpme($name);
    urpmi_removemedia($medium_name);
}

sub test_exotic_medium_name {
    if (getcwd() =~ m!^/root/!) {
        warn "SKIPing test_exotic_medium_name() due to nobody having no access to /root/rpm*\n";
	return;
    }
    my $medium_name = 'the medium (+name+)';
    urpmi_addmedia("'$medium_name' $url/media/various");

    # test urpmf/urpmq using synthesis
    is(run_urpm_cmd('urpmf --summary .'), "various:various\n");
    is(run_urpm_cmd('urpmq --summary various'), "various : various ( 1-1 )\n");

    # test urpmf/urpmq using info.xml.lzma as user
    mkdir 'root/tmp'; chmod 0777, 'root/tmp';
    is(run_urpm_cmd_as_user('urpmf --sourcerpm .'), "various:various-1-1.src.rpm\n", 'urpmf --sourcerpm works as user');
    is(run_urpm_cmd_as_user('urpmq --sourcerpm various'), "various: various-1-1.src.rpm\n", 'urpmq --sourcerpm works as user');

    # test urpmf/urpmq using info.xml.lzma as root
    is(run_urpm_cmd('urpmf --sourcerpm .'), "various:various-1-1.src.rpm\n", 'urpmf --sourcerpm works as root');
    is(run_urpm_cmd('urpmq --sourcerpm various'), "various: various-1-1.src.rpm\n", 'urpmq --sourcerpm works as root');

    urpmi($name);
    check_installed_fullnames("$name-1-1");
    urpme($name);

    urpmi_removemedia("'$medium_name'");
}

sub run_urpm_cmd_as_user {
    my ($cmd) = @_;
    my $full_cmd = "su nobody -s /bin/sh -c '" . urpm_cmd($cmd). "'";
    warn "# $full_cmd\n";
    `$full_cmd`;
}

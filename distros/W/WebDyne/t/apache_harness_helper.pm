package apache_harness_helper;

use strict;
use warnings;

use Cwd qw(fastcwd);
use File::Spec;
use WebDyne::Util qw(apache_startup apache_shutdown perl_inc_dn);


sub apache_prereq_missing {

    my @missing;
    for my $module (qw(Apache::Test Apache::TestRunPerl Apache::TestRequest mod_perl2 Apache2::RequestRec)) {
        eval "require $module; 1" or push @missing, $module;
    }
    push @missing, 'Apache httpd binary' unless apache_binary_available();
    push @missing, 'local socket bind permission' unless local_socket_available();
    return @missing;

}


sub apache_binary_available {

    for my $env (qw(APACHE_TEST_HTTPD HTTPD_BIN HTTPD APACHE_TEST_APXS APXS_BIN APXS)) {
        next unless $ENV{$env};
        return 1 if -f $ENV{$env};
    }

    my @dir=grep { defined && length && -d } (
        split(/:/, ($ENV{'PATH'} || q())),
        qw(/usr/sbin /usr/bin /usr/local/sbin /usr/local/bin /sbin /bin /opt/sbin /opt/bin)
    );
    my %seen;
    @dir=grep { !$seen{$_}++ } @dir;
    for my $dir (@dir) {
        for my $name (qw(httpd httpd2 httpd2.2 httpd2.4 apache apache2 apache2.2 apache2.4 apachectl apache2ctl)) {
            return 1 if -f File::Spec->catfile($dir, $name);
        }
    }
    return;

}


sub apache_startup_unavailable {

    my $err=shift() || q();
    return $err =~ /Operation not permitted|socket:|no ports available|port \d+ is in use|cannot determine server pid to shutdown/;

}


sub local_socket_available {

    require Socket;
    socket(my $socket, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) || return;
    bind($socket, Socket::sockaddr_in(0, Socket::inet_aton('127.0.0.1'))) || return;
    listen($socket, 1) || return;
    close($socket);
    return 1;

}


sub startup {


    #  Optional startup options are reserved for future use.
    #
    my $opt_hr=shift();


    #  Get postamble with WebDyne config
    #
    my $postamble=&startup_conf();


    #  Start Apache using Apache::Test.
    #
    return apache_startup({
        port         => 'select',
        documentroot => File::Spec->catdir(fastcwd(), 't'),
        postamble    => $postamble,
        die_on_error => 1,
    });

}


sub startup_conf {


    #  Get all WEBDYNE_CONF env vars
    #
    my @perl_inc_dn=@{&perl_inc_dn()};
    my $PerlSwitches=join("\n", map { sprintf('PerlSwitches -I%s', $_) } @perl_inc_dn);
    my @PerlSetEnv=map { sprintf('PerlSetEnv %s %s', $_, $ENV{$_}) }
        grep { defined($ENV{$_}) && $ENV{$_} ne '' }
        grep { /^WEBDYNE_/ } keys %ENV;
    push(@PerlSetEnv, 'PerlSetEnv WEBDYNE_ERROR_TEXT 1') unless defined($ENV{'WEBDYNE_ERROR_TEXT'});
    my $PerlSetEnv=join("\n", @PerlSetEnv);
    my $postamble= <<"END";
$PerlSetEnv
$PerlSwitches
PerlSetEnv WEBDYNE_CONF .
PerlSetEnv WEBDYNE_HEAD_INSERT 0
#PerlSwitches -I../lib
PerlModule WebDyne
AddHandler modperl .psp
PerlResponseHandler WebDyne
END
;
    return $postamble;
}


sub shutdown {

    return apache_shutdown(@_);

}


1;

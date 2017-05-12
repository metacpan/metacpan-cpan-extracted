# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-ConfixxBackup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;

use_ok('WWW::ConfixxBackup');

my $backup = WWW::ConfixxBackup->new();
isa_ok($backup,'WWW::ConfixxBackup');

$backup->user('username');
$backup->password('password');
$backup->server('server');

ok($backup->ftp_user() eq 'username');
ok($backup->confixx_password eq 'password');
ok($backup->server eq 'server');

my @methods = qw(
    user
    password
    server
    ftp_user
    ftp_password
    ftp_server
    confixx_user
    confixx_password
    confixx_server
    confixx_version
    detect_version
    http_proxy
    file_prefix
    backup
    download
    backup_download
    available_confixx_versions
    default_confixx_version
    new
    ftp_login
    confixx_login
    login
    waiter
    errstr
    debug
    DEBUG
);
can_ok($backup,@methods);


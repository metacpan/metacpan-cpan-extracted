# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-ConfixxBackup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use WWW::ConfixxBackup::FTP;
ok(1);

my $ftp = WWW::ConfixxBackup::FTP->new();
ok(ref($ftp) eq 'WWW::ConfixxBackup::FTP');

$ftp->user('user');
$ftp->server('server');
$ftp->password('password');

ok($ftp->user eq 'user');
ok($ftp->server eq 'server');
ok($ftp->password eq 'password');

my @methods = qw(
    new
    user
    server
    login
    password
    prefix
    download
    DESTROY
    ftp
    debug
    DEBUG
);
                
can_ok($ftp,@methods);

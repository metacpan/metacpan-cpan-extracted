#!perl

# this is an example of Test::SFTP usage

use strict;
use warnings;

use Test::More tests => 3;
use Test::SFTP;

# will use currently logged in user
my $sftp = Test::SFTP->new(
    host     => 'localhost',
    password => 'MyKick4$$p4$$w0rdz',
);

ok( ! $sftp->error(), 'Connected successfully!');
$sftp->can_ls( '/', 'We can see root' );
$sftp->can_put( 'myfile', '/home/me', 'Can upload myfile to destination' );


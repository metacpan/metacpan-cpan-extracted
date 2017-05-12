# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Formspring.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('WWW::Formspring::User') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $user = WWW::Formspring::User->new( username => 'worr2400',
                                       name => 'Will',
                                       answered_count => 2,
                                       is_following => 1,
                                       website => 'http://www.worrbase.com');
ok( defined $user );
ok( $user->username eq 'worr2400');
ok( $user->name eq 'Will');
ok( $user->has_website );
ok( not $user->has_location );
ok( not $user->has_bio );
ok( not $user->has_photo_url );
ok( $user->answered_count == 2 );
ok( $user->is_following );

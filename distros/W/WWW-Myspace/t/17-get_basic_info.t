#!perl -T

use Test::More tests => 18;  # SEE FOREACH LOOP BLOW
#use Test::More 'no_plan';

use lib 't';
use TestConfig;
login_myspace or die "Login Failed - can't run tests";

my $myspace = $CONFIG->{acct1}->{myspace}; # For sanity

#individual profile
my ( %info ) = $myspace->get_basic_info( $CONFIG->{acct1}->{friend_id} );
#foreach $key ( keys( %info ) ) {
#    warn "$key: $info{$key}\n";
#}

# If you change the number of keys here, change the number of tests above.
foreach my $key ( 'country', 'cityregion', 'city', 'region','headline', 'age', 'gender', 'lastlogin' ) {
    ok( $info{"$key"}, "individual: get_basic_info $key : $info{\"$key\"}" );
}

# Myspace began around 2003, last login should be after that time
ok ( $info{'lastlogin'} >= 1041379200 , 'Last login is 2003 or later' );


#bandprofile
( %info ) = $myspace->get_basic_info( 3327112 );
# If you change the number of keys here, change the number of tests above.
foreach my $key ( 'country', 'cityregion', 'city', 'region','headline','profileviews', 'lastlogin' ) {
    ok( $info{"$key"}, "band: get_basic_info $key : $info{\"$key\"}" );
}

# 2008-09-21 -- today the band's last login was 2008-09-21 (1221955200), so
#  check that the last login is now greater or equal to that date
ok( $info{'lastlogin'} >= 1221955200, 'Last login is 2008-09-21 or later' );

# 2008-09-21 -- today the band's profile views were 12908038, so check that
#  the profile views are now greater or qual to that value
ok( $info{'profileviews'} >= 12908038, 'Profile views are 12908038 or more'  );

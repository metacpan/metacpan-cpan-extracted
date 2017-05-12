#!perl -T

use strict;
use warnings;
use Test::More;

use WebService::EveOnline;

plan tests => 9;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;

my $eve = WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } );

my $eveskills = $eve->skill->all_eve_skills;

SKIP: {
    skip "Bad server response", 9 if defined($eveskills->{_status}) && $eveskills->{_status} eq "error";
    
	# do we get a recognised version?
    is( $eveskills->{version}, 2, 'EVE Version OK?' );

    # do we get a cachedtime of the right format?
    like( $eveskills->{cachedUntil}, qr/\d+-\d+-\d+ \d+:\d+:\d+/, 'Cached time looks OK?');

    # sanity check of returned data structure:
    is( ref($eveskills->{result}), 'HASH', 'Result is hashref?' );
    is( ref($eveskills->{result}->{rowset}), 'HASH', 'Rowset is hashref?' );
    is( ref($eveskills->{result}->{rowset}->{row}), 'ARRAY', 'Rowset is arrayref?' );
    is( ref($eveskills->{result}->{rowset}->{row}->[0]), 'HASH', 'Rowset row array elem is hashref?' );

    # does this look like skill data?
    like( $eveskills->{result}->{rowset}->{row}->[0]->{groupID}, qr/^\d+/, 'Does it look like a group ID?' );

    # if this passes, we're almost certainly getting the right data back :-)
    like( $eveskills->{result}->{rowset}->{row}->[0]->{rowset}->{row}->[0]->{typeID}, qr/^\d+/, 'Does it look like a type ID?' );

    # Again, if this passes, we're almost certainly AOK:
    is( $eve->{_evecache}->get_skill(11584)->{typeName}, 'Anchoring', 'Retrieve the correct skill name?' );
}

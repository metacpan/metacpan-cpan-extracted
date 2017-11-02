use strict;
use warnings;

use XML::Atom::SimpleFeed;

package XML::Atom::SimpleFeed;
use Test::More 0.88; # for done_testing

my $bigbang = '<d>1970-01-01T00:00:00Z</d>';

is date_construct( d => 0 ), $bigbang, 'correct RFC 3339 for Unix times';

SKIP: {
	skip 'missing Time::Piece', 1 unless eval { require Time::Piece };
	is date_construct( d => Time::Piece->gmtime(0) ),    $bigbang, 'correct RFC 3339 for Time::Piece objects';
	is date_construct( d => Time::Piece->localtime(0) ), $bigbang, '... regardless of local timezone';
};

SKIP: {
	skip 'missing DateTime', 1 unless eval { require DateTime };
	my @tz = ( time_zone => DateTime::TimeZone->new( name => 'local' ) );
	is date_construct( d => DateTime->from_epoch( epoch => 0 ) ),      $bigbang, 'correct RFC 3339 for DateTime objects';
	is date_construct( d => DateTime->from_epoch( epoch => 0, @tz ) ), $bigbang, '... regardless of local timezone';
};

SKIP: {
	skip 'missing Time::Moment', 1 unless eval { require Time::Moment };
	my $tm = Time::Moment->from_epoch(0);
	is date_construct( d => $tm ), $bigbang, 'correct RFC 3339 for Time::Moment objects';
	$tm = $tm->with_offset_same_instant( Time::Moment->now->offset );
	is date_construct( d => $tm ), $bigbang, '... regardless of local timezone';
};

SKIP: {
	skip 'missing Panda::Date', 1 unless eval { require Panda::Date };
	is date_construct( d => Panda::Date->new(0, 'UTC') ), $bigbang, 'correct RFC 3339 for Class::Date objects';
	is date_construct( d => Panda::Date->new(0) ),        $bigbang, '... regardless of local timezone';
};

SKIP: {
	skip 'missing Class::Date', 1 unless eval { require Class::Date };
	is date_construct( d => Class::Date::gmdate('00') ),    $bigbang, 'correct RFC 3339 for Class::Date objects';
	is date_construct( d => Class::Date::localdate('00') ), $bigbang, '... regardless of local timezone';
};

SKIP: {
	skip 'missing Time::Object', 1 unless eval { require Time::Object };
	is date_construct( d => Time::Object::gmtime(0) ),    $bigbang, 'correct RFC 3339 for Time::Object objects';
	is date_construct( d => Time::Object::localtime(0) ), $bigbang, '... regardless of local timezone';
};

SKIP: {
	skip 'missing Time::Date', 1 unless eval { require Time::Date; Time::Date->VERSION('0.05') };
	is date_construct( d => Time::Date->new_epoch(0) ),    $bigbang, 'correct RFC 3339 for Time::Date objects';
};

done_testing;

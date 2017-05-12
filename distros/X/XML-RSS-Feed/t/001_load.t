#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 27;

BEGIN {
    use_ok('XML::RSS::Feed');
    use_ok('XML::RSS::Headline');
    use_ok('Time::HiRes');
}

$SIG{__WARN__} = build_warn("Invalid argument");
isa_ok(
    XML::RSS::Feed->new(
        url     => "http://www.jbisbee.com/rdf/",
        name    => 'jbisbee',
        delay   => 7200,
        bad_arg => 1,
        debug   => 1,
    ),
    "XML::RSS::Feed"
);

$SIG{__WARN__} = build_warn("No cache file found");
isa_ok(
    XML::RSS::Feed->new(
        title  => "This is a fake RSS Title",
        name   => 'jbisbee_test',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => 'pretend_tmpdir',
        debug  => 1,
    ),
    "XML::RSS::Feed"
);

isa_ok(
    XML::RSS::Headline->new(
        url      => "http://www.jbisbee.com/testurl/1",
        headline => "Test Headline",
    ),
    "XML::RSS::Headline"
);

isa_ok(
    XML::RSS::Headline->new(
        url         => "http://www.jbisbee.com/testurl/1",
        description => "Test Headline",
    ),
    "XML::RSS::Headline"
);

$SIG{__WARN__} = build_warn("Failed to set headline");
ok( !XML::RSS::Headline->new(
        url         => "http://www.jbisbee.com/testurl/1",
        description => ".",
    ),
    "Bad description"
);

isa_ok(
    XML::RSS::Headline->new(
        url         => "http://www.jbisbee.com/testurl/1",
        headline    => "Test Headline",
        description => "Test Description",
    ),
    'XML::RSS::Headline',
    'via url/headline/description'
);

isa_ok(
    XML::RSS::Headline->new(
        url        => "http://www.jbisbee.com/testurl/1",
        headline   => "Test Headline",
        first_seen => Time::HiRes::time(),
    ),
    'XML::RSS::Headline',
    'set first_seen'
);

isa_ok(
    XML::RSS::Headline->new(
        item => {
            link  => "http://www.jbisbee.com/testurl/1",
            title => "Test Headline",
        },
    ),
    'XML::RSS::Headline',
    'via $args{item} - link/title'
);

isa_ok(
    XML::RSS::Headline->new(
        item => {
            link        => "http://www.jbisbee.com/testurl/1",
            title       => "Test Headline",
            description => "Test Description",
        },
    ),
    'XML::RSS::Headline',
    'via $args{item} - link/title/description'
);

$SIG{__WARN__} = build_warn("Invalid argument");
isa_ok(
    XML::RSS::Headline->new(
        url         => "http://www.jbisbee.com/testurl/1",
        headline    => "Test Headline",
        description => "Test Description",
        bad_arg     => "bad argument"
    ),
    "XML::RSS::Headline"
);

$SIG{__WARN__}
    = build_warn("item must contain either title/link or description/link");
ok( !XML::RSS::Headline->new(
        item => {
            title       => "Test Headline",
            description => "Test Description"
        }
    ),
    "Failed to instantiate"
);

$SIG{__WARN__}
    = build_warn("item must contain either title/link or description/link");
ok( !XML::RSS::Headline->new( item => { fake => 1 } ),
    "Failed to instantiate" );

$SIG{__WARN__} = build_warn(
    "Either item, url/headline. or url/description are required");
ok( !XML::RSS::Headline->new, "Failed to instantiate" );
ok( !XML::RSS::Headline->new( headline => "Test Headline" ),
    "Failed to instantiate" );
ok( !XML::RSS::Headline->new( url => "http://www.jbisbee.com/testurl/1" ),
    "Failed to instantiate" );

sub build_warn {
    my @args = @_;
    return sub { my ($warn) = @_; like( $warn, qr/$_/i, $_ ) for @args };
}

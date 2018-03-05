use strict;
use warnings;

my %v0_9_ok_fields = (
    channel => {
		title       => '',
		description => '',
		link        => '',
		},
    image  => {
		title => undef,
		url   => undef,
		link  => undef,
		},
    textinput => {
		title       => undef,
		description => undef,
		name        => undef,
		link        => undef,
		},
    items => [],
    num_items => 0,
    version         => '',
    encoding        => ''
);

my %v0_9_1_ok_fields = (
    channel => {
		title          => '',
		copyright      => undef,
		description    => '',
		docs           => undef,
		language       => undef,
		lastBuildDate  => undef,
		'link'         => '',
		managingEditor => undef,
		pubDate        => undef,
		rating         => undef,
		webMaster      => undef,
		},
    image  => {
		title       => undef,
		url         => undef,
		'link'      => undef,
		width       => undef,
		height      => undef,
		description => undef,
		},
    skipDays  => {
		day         => undef,
		},
    skipHours => {
		hour        => undef,
		},
    textinput => {
		title       => undef,
		description => undef,
		name        => undef,
		'link'      => undef,
		},
    items           => [],
    num_items       => 0,
    version         => '',
    encoding        => '',
    category        => ''
);

my %v1_0_ok_fields = (
    channel => {
		title       => '',
		description => '',
		link        => '',
		},
    image  => {
		title => undef,
		url   => undef,
		link  => undef,
		},
    textinput => {
		title       => undef,
		description => undef,
		name        => undef,
		link        => undef,
		},
    skipDays  => {
		day         => ''
		},
    skipHours => {
		hour        => undef,
		},
    items => [],
    num_items => 0,
    version         => '',
    encoding        => '',
    output          => '',
);

my %v2_0_ok_fields = (
    channel => {
        title          => '',
        'link'         => '',
        description    => '',
        language       => undef,
        copyright      => undef,
        managingEditor => undef,
        webMaster      => undef,
        pubDate        => undef,
        lastBuildDate  => undef,
        category       => undef,
        generator      => undef,
        docs           => undef,
        cloud          => '',
        ttl            => undef,
        image          => '',
        textinput      => '',
        skipHours      => '',
        skipDays       => '',
        },
    image  => {
        title       => undef,
        url         => undef,
        'link'      => undef,
        width       => undef,
        height      => undef,
        description => undef,
        },
    skipDays  => {
        day         => undef,
        },
    skipHours => {
        hour        => undef,
        },
    textinput => {
        title       => undef,
        description => undef,
        name        => undef,
        'link'      => undef,
        },
    items           => [],
    num_items       => 0,
    version         => '',
    encoding        => '',
    category        => '',
    cloud           => '',
    ttl             => ''
);

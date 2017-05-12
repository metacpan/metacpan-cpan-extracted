package Acme::Location;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'city_collection' => (
    isa         => 'ArrayRef[Acme::City]',
    is          => 'ro',
    init_arg    => 'citys',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_city => ['push'] },
    description => {
        LocalName    => "city",
        Prefix       => "",
        node_type    => "child",
        Name         => "city",
        NamespaceURI => "",
        sort_order   => 0,
    },
);
has 'continent_collection' => (
    isa         => 'ArrayRef[Acme::Continent]',
    is          => 'ro',
    init_arg    => 'continents',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_continent => ['push'] },
    description => {
        LocalName    => "continent",
        Prefix       => "",
        node_type    => "child",
        Name         => "continent",
        NamespaceURI => "",
        sort_order   => 1,
    },
);
has 'country_collection' => (
    isa         => 'ArrayRef[Acme::Country]',
    is          => 'ro',
    init_arg    => 'countrys',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_country => ['push'] },
    description => {
        LocalName    => "country",
        Prefix       => "",
        node_type    => "child",
        Name         => "country",
        NamespaceURI => "",
        sort_order   => 2,
    },
);
has 'latitude_collection' => (
    isa         => 'ArrayRef[Acme::Latitude]',
    is          => 'ro',
    init_arg    => 'latitudes',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_latitude => ['push'] },
    description => {
        LocalName    => "latitude",
        Prefix       => "",
        node_type    => "child",
        Name         => "latitude",
        NamespaceURI => "",
        sort_order   => 3,
    },
);
has 'longitude_collection' => (
    isa         => 'ArrayRef[Acme::Longitude]',
    is          => 'ro',
    init_arg    => 'longitudes',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_longitude => ['push'] },
    description => {
        LocalName    => "longitude",
        Prefix       => "",
        node_type    => "child",
        Name         => "longitude",
        NamespaceURI => "",
        sort_order   => 4,
    },
);
has 'region_collection' => (
    isa         => 'ArrayRef[Acme::Region]',
    is          => 'ro',
    init_arg    => 'regions',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_region => ['push'] },
    description => {
        LocalName    => "region",
        Prefix       => "",
        node_type    => "child",
        Name         => "region",
        NamespaceURI => "",
        sort_order   => 5,
    },
);
has 'state_collection' => (
    isa         => 'ArrayRef[Acme::State]',
    is          => 'ro',
    init_arg    => 'states',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_state => ['push'] },
    description => {
        LocalName    => "state",
        Prefix       => "",
        node_type    => "child",
        Name         => "state",
        NamespaceURI => "",
        sort_order   => 6,
    },
);
1;

__END__

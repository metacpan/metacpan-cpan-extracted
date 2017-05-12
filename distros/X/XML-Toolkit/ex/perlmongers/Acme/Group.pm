package Acme::Group;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'date_collection' => (
    isa         => 'ArrayRef[Acme::Date]',
    is          => 'ro',
    init_arg    => 'dates',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_date => ['push'] },
    description => {
        LocalName    => "date",
        Prefix       => "",
        node_type    => "child",
        Name         => "date",
        NamespaceURI => "",
        sort_order   => 0,
    },
);
has 'email_collection' => (
    isa         => 'ArrayRef[Acme::Email]',
    is          => 'ro',
    init_arg    => 'emails',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_email => ['push'] },
    description => {
        LocalName    => "email",
        Prefix       => "",
        node_type    => "child",
        Name         => "email",
        NamespaceURI => "",
        sort_order   => 1,
    },
);
has 'id' => (
    isa         => 'Str',
    is          => 'ro',
    traits      => ['XML'],
    description => {
        LocalName    => "id",
        Prefix       => "",
        node_type    => "attribute",
        Name         => "id",
        NamespaceURI => "",
        sort_order   => 2,
    },
);
has 'location_collection' => (
    isa         => 'ArrayRef[Acme::Location]',
    is          => 'ro',
    init_arg    => 'locations',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_location => ['push'] },
    description => {
        LocalName    => "location",
        Prefix       => "",
        node_type    => "child",
        Name         => "location",
        NamespaceURI => "",
        sort_order   => 3,
    },
);
has 'mailing_list_collection' => (
    isa         => 'ArrayRef[Acme::Mailing_list]',
    is          => 'ro',
    init_arg    => 'mailing_lists',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_mailing_list => ['push'] },
    description => {
        LocalName    => "mailing_list",
        Prefix       => "",
        node_type    => "child",
        Name         => "mailing_list",
        NamespaceURI => "",
        sort_order   => 4,
    },
);
has 'name_collection' => (
    isa         => 'ArrayRef[Acme::Name]',
    is          => 'ro',
    init_arg    => 'names',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_name => ['push'] },
    description => {
        LocalName    => "name",
        Prefix       => "",
        node_type    => "child",
        Name         => "name",
        NamespaceURI => "",
        sort_order   => 5,
    },
);
has 'status' => (
    isa         => 'Str',
    is          => 'ro',
    traits      => ['XML'],
    description => {
        LocalName    => "status",
        Prefix       => "",
        node_type    => "attribute",
        Name         => "status",
        NamespaceURI => "",
        sort_order   => 6,
    },
);
has 'tsar_collection' => (
    isa         => 'ArrayRef[Acme::Tsar]',
    is          => 'ro',
    init_arg    => 'tsars',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_tsar => ['push'] },
    description => {
        LocalName    => "tsar",
        Prefix       => "",
        node_type    => "child",
        Name         => "tsar",
        NamespaceURI => "",
        sort_order   => 7,
    },
);
has 'web_collection' => (
    isa         => 'ArrayRef[Acme::Web]',
    is          => 'ro',
    init_arg    => 'webs',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_web => ['push'] },
    description => {
        LocalName    => "web",
        Prefix       => "",
        node_type    => "child",
        Name         => "web",
        NamespaceURI => "",
        sort_order   => 8,
    },
);
1;

__END__

package Acme::Mailing_list;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

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
        sort_order   => 0,
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
        sort_order   => 1,
    },
);
has 'subscribe_collection' => (
    isa         => 'ArrayRef[Acme::Subscribe]',
    is          => 'ro',
    init_arg    => 'subscribes',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_subscribe => ['push'] },
    description => {
        LocalName    => "subscribe",
        Prefix       => "",
        node_type    => "child",
        Name         => "subscribe",
        NamespaceURI => "",
        sort_order   => 2,
    },
);
has 'unsubscribe_collection' => (
    isa         => 'ArrayRef[Acme::Unsubscribe]',
    is          => 'ro',
    init_arg    => 'unsubscribes',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_unsubscribe => ['push'] },
    description => {
        LocalName    => "unsubscribe",
        Prefix       => "",
        node_type    => "child",
        Name         => "unsubscribe",
        NamespaceURI => "",
        sort_order   => 3,
    },
);
1;

__END__

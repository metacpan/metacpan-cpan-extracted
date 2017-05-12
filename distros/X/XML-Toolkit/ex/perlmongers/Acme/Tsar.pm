package Acme::Tsar;
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
has 'pause_id_collection' => (
    isa         => 'ArrayRef[Acme::Pause_id]',
    is          => 'ro',
    init_arg    => 'pause_ids',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_pause_id => ['push'] },
    description => {
        LocalName    => "pause_id",
        Prefix       => "",
        node_type    => "child",
        Name         => "pause_id",
        NamespaceURI => "",
        sort_order   => 2,
    },
);
1;

__END__

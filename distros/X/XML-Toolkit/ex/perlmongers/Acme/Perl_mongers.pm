package Acme::Perl_mongers;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'group_collection' => (
    isa         => 'ArrayRef[Acme::Group]',
    is          => 'ro',
    init_arg    => 'groups',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_group => ['push'] },
    description => {
        LocalName    => "group",
        Prefix       => "",
        node_type    => "child",
        Name         => "group",
        NamespaceURI => "",
        sort_order   => 0,
    },
);
1;

__END__

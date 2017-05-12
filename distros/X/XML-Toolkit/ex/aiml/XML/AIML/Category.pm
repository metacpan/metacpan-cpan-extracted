package XML::AIML::Category;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'pattern_collection' => (
    isa         => 'ArrayRef[XML::AIML::Pattern]',
    is          => 'ro',
    init_arg    => 'patterns',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_pattern => ['push'] },
    description => {
        Prefix       => "",
        LocalName    => "pattern",
        node_type    => "child",
        Name         => "pattern",
        NamespaceURI => "",
        sort_order   => 0,
    },
);
has 'template_collection' => (
    isa         => 'ArrayRef[XML::AIML::Template]',
    is          => 'ro',
    init_arg    => 'templates',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_template => ['push'] },
    description => {
        Prefix       => "",
        LocalName    => "template",
        node_type    => "child",
        Name         => "template",
        NamespaceURI => "",
        sort_order   => 1,
    },
);
has 'that_collection' => (
    isa         => 'ArrayRef[XML::AIML::That]',
    is          => 'ro',
    init_arg    => 'thats',
    traits      => [qw(XML Array)],
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
    handles     => { add_that => ['push'] },
    description => {
        Prefix       => "",
        LocalName    => "that",
        node_type    => "child",
        Name         => "that",
        NamespaceURI => "",
        sort_order   => 2,
    },
);
1;

__END__

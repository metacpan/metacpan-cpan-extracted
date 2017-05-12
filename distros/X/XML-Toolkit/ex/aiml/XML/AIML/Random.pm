package XML::AIML::Random;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'li_collection' => (
     isa         => 'ArrayRef[XML::AIML::Li]',
     is          => 'ro',     init_arg    => 'lis',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_li => ['push'] },     description => {
        Prefix => "",
        LocalName => "li",
        node_type => "child",
        Name => "li",
        NamespaceURI => "",
        sort_order => 0,
     },
);
1;

__END__

package XML::Toolkit::RNG::Except;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'nsName_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::NsName]',
     is          => 'ro',     init_arg    => 'nsNames',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_nsName => ['push'] },     description => {
        Prefix => "",
        LocalName => "nsName",
        node_type => "child",
        Name => "nsName",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 0,
     },
);
1;

__END__

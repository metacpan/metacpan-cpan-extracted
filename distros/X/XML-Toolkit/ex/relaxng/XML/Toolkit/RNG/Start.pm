package XML::Toolkit::RNG::Start;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'ref_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Ref]',
     is          => 'ro',     init_arg    => 'refs',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_ref => ['push'] },     description => {
        Prefix => "",
        LocalName => "ref",
        node_type => "child",
        Name => "ref",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 0,
     },
);
1;

__END__

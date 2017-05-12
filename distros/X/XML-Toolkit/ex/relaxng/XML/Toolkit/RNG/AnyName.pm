package XML::Toolkit::RNG::AnyName;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'except_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Except]',
     is          => 'ro',     init_arg    => 'excepts',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_except => ['push'] },     description => {
        Prefix => "",
        LocalName => "except",
        node_type => "child",
        Name => "except",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 0,
     },
);
1;

__END__

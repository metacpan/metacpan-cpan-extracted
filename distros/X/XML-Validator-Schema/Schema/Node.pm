package XML::Validator::Schema::Node;
use base qw(Tree::DAG_Node);

=head1 NAME

XML::Validator::Schema::Node

=head1 DESCRIPTION

Base class for nodes in the schema tree.  Used by both temporary nodes
resolved during compilation (ex. ::ModelNode) and permanent nodes
(ex. ::ElementNode).

This is an abstract base class and may not be directly instantiated.

=cut

sub new {
    my $pkg = shift;
    croak("Illegal attempt to instantiate a Node directly!")
      if $pkg eq __PACKAGE__;
    return $pkg->SUPER::new(@_);
}

sub parse {
    my $pkg = shift;
    croak("$pkg neglected to supply a parse() implementation!");
}

# override to declare root-ness
sub is_root {
    return 0 if shift->{mother};
    return 1;
}

1;



package Tree::Simple::SAX::Handler;

use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = '0.01';

use Tree::Simple;

use base 'XML::SAX::Base';

sub new {
    my ($_class, $root_tree) = @_;
    (blessed($root_tree) && $root_tree->isa('Tree::Simple'))
        || die "The root tree must be a Tree::Simple tree"
            if defined($root_tree);
    my $class = ref($_class) || $_class;
    my $self = $class->SUPER::new();
    $self->{_root_tree}    = $root_tree || Tree::Simple->new();
    $self->{_current_tree} = $self->{_root_tree};
    return $self;
}

sub getRootTree { (shift)->{_root_tree} }

sub start_element {
    my ($self, $el) = @_;
    my $new_tree = $self->{_root_tree}->new();
    my $node_value = { tag_type => $el->{Name} };
    my $attrs = $el->{Attributes};
    $node_value->{$attrs->{$_}->{Name}} = $attrs->{$_}->{Value} foreach keys %{$attrs};
    $new_tree->setNodeValue($node_value);
    $self->{_current_tree}->addChild($new_tree);
    $self->{_current_tree} = $new_tree;
}   

sub end_element {
    my ($self) = @_;
    $self->{_current_tree} = $self->{_current_tree}->getParent();
}

sub characters {
    my ($self, $el) = @_;
    return if $el->{Data} =~ /^\s+$/;
    $self->{_current_tree}->addChild(
                $self->{_root_tree}->new({ 
                        tag_type => 'CDATA',
                        content  => $el->{Data} 
                    })
                );
} 

1;

__END__

=head1 NAME

Tree::Simple::SAX::Handler - An XML::SAX Handler to create Tree::Simple objects from XML

=head1 SYNOPSIS

  use Tree::Simple::SAX;
  use XML::SAX::ParserFactory;
  
  my $handler = Tree::Simple::SAX::Handler->new(Tree::Simple->new());
  
  my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
  $p->parse_string('<xml><string>Hello <world/>!</string></xml>');    
  
  # this will create a tree like this:
  # { tag_type => 'xml' }
  #         { tag_type => 'string' }
  #                 { content => 'Hello ', tag_type => 'CDATA' }
  #                 { tag_type => 'world' }
  #                 { content => '!', tag_type => 'CDATA' }

=head1 DESCRIPTION

This is a proof-of-concept L<XML::SAX> handler which can build L<Tree::Simple> hierarchies. See the L<Tree::Simple::SAX> for more information.

=head1 METHODS

=over 4

=item B<new ($root_tree)>

=item B<getRootTree>

=back

=head2 SAX Handler Methods

=over 4

=item B<start_element>

=item B<end_element>

=item B<characters>

=back

=head1 TO DO

=over 4 

=item Support more SAX handler hooks

I only support the basic C<start_element>, C<end_element> and C<character>. I need to add more hooks to handle more sophisticated XML documents.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the C<CODE COVERAGE> section of L<Tree::Simple::SAX> for more details.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

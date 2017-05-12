package Tree::Binary::XS;

use 5.018002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tree::Binary ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Tree::Binary::XS', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Tree::Binary::XS - Perl extension for manipulating binary tree structure

=head1 SYNOPSIS

  use Tree::Binary::XS;
  my $tree = Tree::Binary::XS->new({ by_key => 'id' });

  $tree->insert({ foo => 'bar', id => 11 });

  $tree->insert([{ foo => 'bar', id => 11 }, ... ]);

  $ret->exists(10);
  $ret->exists({ id => 10, 'name' => 'Bob' });

  # Use specified key instead of the key from payload
  $tree->insert(10, { foo => 'bar' });

  # to insert multiple keys one time.
  @ret = $tree->insert_those([{ id => 10, 'name' => 'Bob' },  { id => 3, 'name' => 'John' }, { id => 2, 'name' => 'Hank' } ]);

  $tree->update(10, { foo => 'bar' })

  $n = $tree->search(10);

  $tree->exists(10);
  $tree->exists({ foo => 'bar' , id => 10 });

  $tree->inorder_traverse(sub { 
        my ($key, $node) = @_;
    });

  $tree->postorder_traverse(sub { 
        my ($key, $node) = @_;
    });

  $tree->preorder_traverse(sub { 
        my ($key, $node) = @_;
    });

=head1 DESCRIPTION

Please note this extension is not compatible with the L<Tree::Binary> package,
this module was redesigned and simplified the interface of manipulating tree
structure.

=head1 FUNCTIONS

=over 4

=item $tree = Tree::Binary::XS->new({  by_key => $field_name })

The C<new> method constructs the Tree object, you may specify the C<by_key> option to let L<Tree::Binary::XS> 
get the key from the inserted objects.

=item $tree->insert(hashref $object)

Once you've defined the C<by_key>, you can simply pass the object to the insert method, for example:

    $tree->insert({
        id => 11,
        name => 'John',
    });

And C<11> will be the key of the object.

=item $tree->insert(IV key, hashref $object)

If you want to specify another key to insert the object, you may pass the C<key> as the first argument of the C<insert> method.

=item @ret = $tree->insert_those([ $obj1, $obj2, ... ])

=item $tree->update(IV key, $new_object)

=item $tree->exists(IV key)

=item $tree->exists(hashref $object)

=item $tree->search(IV key)

=item $tree->search(hashref $object)


=back


=head2 Tree Traversal

=over 4

=item $tree->postorder_traverse(sub { my ($key, $node) = @_; })

=item $tree->preorder_traverse(sub { my ($key, $node) = @_; })

=item $tree->inorder_traverse(sub { my ($key, $node) = @_; })

=cut

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Tree::Binary>, L<Tree::Binary::Search>

=head1 AUTHOR

Lin Yo-an, E<lt>c9s@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Lin Yo-an

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

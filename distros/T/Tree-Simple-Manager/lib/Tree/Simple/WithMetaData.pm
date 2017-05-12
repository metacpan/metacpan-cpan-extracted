
package Tree::Simple::WithMetaData;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Tree::Simple';

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->{meta_data} = {};
    return $self;
}

## meta data functions

sub addMetaData {
    my ($self, %data) = @_;
    my ($k, $v);
    while (($k, $v) = each %data) {
        $self->{meta_data}->{$k} = $v;
    }
}

sub hasMetaDataFor {
    my ($self, $key) = @_;
    exists $self->{meta_data}->{$key} ? 1 : 0;    
}

sub getMetaDataFor {
    my ($self, $key) = @_;
    return $self->{meta_data}->{$key};
}

sub fetchMetaData {
    my ($self, $key) = @_;
    return $self->{meta_data}->{$key} 
        if exists $self->{meta_data}->{$key};
    
    my $current = $self;
    until ($current->isRoot) {
        return $current->{meta_data}->{$key} 
            if exists $current->{meta_data}->{$key};        
        $current = $current->getParent();
    }    

    return undef;
}

1;

__END__

=pod

=head1 NAME

Tree::Simple::WithMetaData - A Tree::Simple subclass with added metadata handling

=head1 SYNOPSIS
  
  use Tree::Simple::WithMetaData;
  
  my $tree = Tree::Simple::WithMetaData->new('a node');
  $tree->addMetaData(
      foo => "bar",
      bar => "baz",
  );
  
  print $tree->fetchMetaData('foo'); # bar
  
  $tree->addChild(
      Tree::Simple::WithMetaData->new('another node');
  );
  
  # metadata is "inherited"
  print $tree->getChild(0)->fetchMetaData('foo'); # bar

=head1 DESCRIPTION

This is a very simple (but actually very handy) subclass of Tree::Simple. It 
adds node level metadata and the ability for tree's to "inherit" their parents
metadata as well. Read the source, it's really simple actually.

=head1 METHODS

=over 4

=item B<addMetaData (%metadata)>

Adds the C<%metadata> into the node.

=item B<hasMetaDataFor ($key)>

Checks for presence of metadata at C<$key> in the local metadata stash.

=item B<getMetaDataFor ($key)>

Returns any metadata at C<$key> in the local metadata stash.

=item B<fetchMetaData ($key)>

Looks in the local stash for metadata at C<$key>, if it is not found, then 
it will traverse up the tree until it finds something (or returns undef).

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, 
and I will be sure to fix it. 

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
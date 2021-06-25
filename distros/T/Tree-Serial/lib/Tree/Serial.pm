package Tree::Serial;

use warnings;
use v5.12;

use List::Util qw(min reduce sum zip);

our $VERSION=0.1;

sub new {
    my ($class,$data) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init($data);
    return $self;
}

sub _init {
    my ($self,$data) = @_;
    my %data = (
	separator => '.',
	degree => 2,
        traversal => 0,
	(defined $data) ? (%{$data}) : (),
	);
    (exists $data{showMissing}) && do {$self->{showMissing} = $data{showMissing}};
    $self->{separator} = $data{separator};
    $self->{degree} = $data{degree};
    $self->{traversal} = $data{traversal};
}

sub _eatWhileNot {
    my ($pred,$acc,$el) = @_;
    my @larger = (@{$acc->[1]}, $el);
    return ($pred->(\@larger)) ? ([[@{$acc->[0]}, \@larger],[]]) : ([$acc->[0], \@larger]);
}

sub _chunkBy {
    my ($pred,$aref) = @_;
    my $reduction = reduce { _eatWhileNot($pred, $a, $b) } [[],[]], @{$aref};
    return $reduction->[0];
}

sub _isKAry {
    my ($separator,$degree,$aref) = @_;
    return ((sum map { ($_ eq $separator) ? (-1) : ($degree-1) } @{$aref}) == -1);
}

sub _chunkKAry {
    my ($separator,$degree,$aref) = @_;
    my $pred = sub { _isKAry($separator,$degree,$_[0]) };
    return _chunkBy($pred,$aref);
}

sub strs2hash {
    my ($self, $aref) = @_;
    (! scalar @{$aref}) && return {};
    ($aref->[0] eq $self->{separator}) && do {
	(exists $self->{showMissing} && defined $self->{showMissing}) && return {name => $self->{showMissing}};
	(exists $self->{showMissing}) && return {};
	return;
    };
    my @rest = @{$aref}[1..scalar @{$aref}-1];
    my @chunks = @{_chunkKAry($self->{separator}, $self->{degree}, \@rest)};
    (! exists $self->{showMissing}) && do {@chunks = grep {$_->[0] ne $self->{separator}} @chunks};
    my %h = (
	name => $aref->[0],
	map {$_->[0] => strs2hash($self,$_->[1])} zip [0..$#chunks], \@chunks,
	);
    return \%h;
}

sub strs2lol {
    my ($self, $aref) = @_;
    (! scalar @{$aref}) && return [];
    ($aref->[0] eq $self->{separator}) && do {
	(exists $self->{showMissing} && defined $self->{showMissing}) && return [$self->{showMissing}];
	(exists $self->{showMissing}) && return [];
	return;
    };
    my @rest = @{$aref}[1..scalar @{$aref}-1];
    my $chunks = _chunkKAry($self->{separator}, $self->{degree}, \@rest);
    my @others = map {strs2lol($self,$_)} @{$chunks};
    splice(@others,min(scalar @others, $self->{traversal}),0,$aref->[0]);
    return \@others;
}

1;

__END__

=head1 NAME

Tree::Serial - Perl module for deserializing lists of strings into tree-like structures

=head1 SYNOPSIS

The following piece of code appears as C<script/tree-serial-general-examples.pl> in the present distribution. 

    #!/usr/bin/env perl
    use warnings;
    use v5.12;
    
    use Data::Dumper;
    $Data::Dumper::Indent = 0;
    
    use Tree::Serial;
    
    say Dumper(Tree::Serial->new());
    # $VAR1 = bless( {'separator' => '.','traversal' => 0,'degree' => 2}, 'Tree::Serial' );
    
    say Dumper(Tree::Serial->new({separator => "#", degree => 5, traversal => 4}));
    # $VAR1 = bless( {'degree' => 5,'separator' => '#','traversal' => 4}, 'Tree::Serial' );
    
    say Dumper(Tree::Serial->new()->strs2hash([qw(p q . . r . .)]));
    # $VAR1 = {'1' => {'name' => 'r'},'name' => 'p','0' => {'name' => 'q'}};
    
    say Dumper(Tree::Serial->new({traversal => 2})->strs2lol([qw(a b . c . . .)]));
    # $VAR1 = [[['c'],'b'],'a'];
    
    say Dumper(Tree::Serial->new({traversal => 2,showMissing => undef})->strs2lol([qw(a b . c . . .)]));
    # $VAR1 = [[[],[[],[],'c'],'b'],[],'a'];
    
    say Dumper(Tree::Serial->new({traversal => 2,showMissing => "X"})->strs2hash([qw(a b . c . . .)]));
    # $VAR1 = {'name' => 'a','0' => {'0' => {'name' => 'X'},'name' => 'b','1' => {'1' => {'name' => 'X'},'name' => 'c','0' => {'name' => 'X'}}},'1' => {'name' => 'X'}};
    
The list-of-lists format produced in post-order is meant to inter-operate with the already-existing (and excellent) L<Tree::DAG_Node|https://metacpan.org/pod/Tree::DAG_Node> (specifically, its L<lol_to_tree|https://metacpan.org/pod/Tree::DAG_Node#lol_to_tree($lol)> method). 

The following code, appearing as C<script/tree-serial-2dag.pl> in this distribution, illustrates.

    #!/usr/bin/env perl
    use warnings;
    use v5.12;
    
    use Data::Dumper;
    $Data::Dumper::Indent = 0;
    
    use Tree::Serial;
    use Tree::DAG_Node;
    
    my $lol = Tree::Serial->new({traversal => 2})->strs2lol([qw(1 2 4 . 7 . . . 3 5 . . 6 . .)]);
    
    say Dumper($lol);
    # $VAR1 = [[[['7'],'4'],'2'],[['5'],['6'],'3'],'1'];
    
    my $tree = Tree::DAG_Node->lol_to_tree($lol);
    my $diagram = $tree->draw_ascii_tree;
    say map "$_\n", @$diagram; 
    
    #         |
    #        <1>
    #     /-----\
    #     |     |
    #    <2>   <3>
    #     |   /---\
    #    <4>  |   |
    #     |  <5> <6>
    #    <7>
    # 

=head1 DESCRIPTION

The purpose of the module is to turn lists of strings (typically passed on the command line) into tree-like structures: hashes and lists of lists (of lists, etc.; i.e. nested). 

The idea is that you would instantiate the deserializer class that this package provides, passing it a number of parameters:

=over

=item *

the C<separator> meaning the dummy piece of string that indicates an empty node;

=item * 

the C<degree>, meaning the maximal degree the deserializer assumes all tree nodes have. Whatever missing nodes there are, you will then have to indicate by instances of the above-mentioned C<separator>;

=item * 

the C<traversal>: a non-negative integer between 0 and C<degree> that tells the deserializer where to place the root when producing a list of lists.

=back

You always specify the tree nodes in L<pre-order traversal|https://www.geeksforgeeks.org/tree-traversals-inorder-preorder-and-postorder/>; the C<traversal> attribute specifies what sort of I<output> to produce. An example: assuming the C<separator> is C<'.'> and the C<degree> is 2 (the default), the list 

    1 2 4 . 7 . . . 3 5 . . 6 . . 

would represent the binary tree

               `
        1
       / \
      2   3
     /   / \
    4   5   6
     \
      7

The initial inspiration was provided by L<this discussion|https://stackoverflow.com/questions/2675756/efficient-array-storage-for-binary-tree/2676849#2676849>, which applies to binary trees only. The present module handles C<k>-ary trees for arbitrary C<k E<ge> 2>.

=head1 INSTALLATION

Using L<cpanm|https://metacpan.org/dist/App-cpanminus/view/bin/cpanm>: clone this repo, C<cd> into it, and then:

    $ cpanm .

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=head1 ATTRIBUTES

=head2 separator

The string that will indicate a missing node to the deserializer, if you specify a C<k>-ary tree that is not L<full|https://xlinux.nist.gov/dads/HTML/fullBinaryTree.html>. It defauls to C<'.'>. 

=head2 degree

The common maximal degree assumed of the tree nodes. It defaults to 2 (i.e. to handling I<binary> trees):

    my $ts = Tree::Serial->new({degree => 2});

is the same as 

    my $ts = Tree::Serial->new();

but you can specify any other positive integer.

=head2 traversal

    my $ts = Tree::Serial->new({traversal => 1});

A non-negative integer, indicating where the root is placed as you deserialize the tree into a list of lists. It defaults to 0, meaning the root comes first, before the subtrees: what is usually called L<pre-order traversal|https://www.geeksforgeeks.org/tree-traversals-inorder-preorder-and-postorder/>.

If you've specified a C<k>-ary tree, then setting the C<traversal> attribute to C<k> means you are doing a L<post-order traversal|https://www.geeksforgeeks.org/tree-traversals-inorder-preorder-and-postorder/> instead:

    my $ts = Tree::Serial->new({degree => 3, traversal => 3});

=head2 showMissing

It tells the deserializer object what to do with missing nodes (which you enter as C<separator>). There are a number of options:

=over

=item *

Let it default to non-existent, in the sense that L<exists|> returns false on C<$deserializer{showMissing}>. Empty nodes will then not be rendered at all:

    say Dumper(Tree::Serial->new({traversal => 2})->strs2lol([qw(1 2 . 3 . . .)]));
    # $VAR1 = [[['3'],'2'],'1'];

=item * 

Set it to C<undef>, in which case you will get empty hashes/arrays for the missing nodes:

    say Dumper(Tree::Serial->new({traversal => 2,showMissing => undef})->strs2lol([qw(1 2 . 3 . . .)]));
    # $VAR1 = [[[],[[],[],'3'],'2'],[],'1'];

=item *

Finally, make sure it exists I<and> is defined, and the missing nodes will be rendered carrying that label (the value of C<$deserializer{showMissing}>):

    say Dumper(Tree::Serial->new({traversal => 2,showMissing => "X"})->strs2hash([qw(a b . c . . .)]));
    # $VAR1 = {'name' => 'a','0' => {'0' => {'name' => 'X'},'name' => 'b','1' => {'1' => {'name' => 'X'},'name' => 'c','0' => {'name' => 'X'}}},'1' => {'name' => 'X'}};

=back

=head1 METHODS

=head2 strs2hash

This will turn your list of strings into a nested hashref:

    say Dumper(Tree::Serial->new()->strs2hash([qw(p q . . r . .)]));
    # $VAR1 = {'1' => {'name' => 'r'},'name' => 'p','0' => {'name' => 'q'}};

=head2 strs2lol

This method produces a nested arrayref structure (list of lists, or 'lol'):

    say Dumper(Tree::Serial->new({traversal => 2})->strs2lol([qw(a b . c . . .)]));
    # $VAR1 = [[['c'],'b'],'a'];

=cut

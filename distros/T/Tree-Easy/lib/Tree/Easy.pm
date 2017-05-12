package Tree::Easy;

use warnings;
use strict;

use Scalar::Util qw(refaddr);
use List::Util   qw(max);
use Carp         qw(croak carp);

our $VERSION = '0.01';

my $_DUMPER_IS_LOADED = 0; # for dump method
my %_NODE_DATA;

sub new
{
    my $class = shift;
    my $self = bless [ ], $class;

    my $data = shift;
    if ( defined $data ) {
        $_NODE_DATA{ refaddr($self) } = $data;
    }
    return $self;
}

sub clone
{
    my $self = shift;

    # Make a shallow copy of any data references...
    my $data = $self->data;
    my $new_data = ( ! ref $data          ? $data      :
                     ref $data eq 'ARRAY' ? [ @$data ] :
                     ref $data eq 'HASH'  ? { %$data } :
                    die sprintf qq{Internal error, don't know how to clone data reference\n}.
                                 q{of type "%s"}, ref $data );

    my $new_root = __PACKAGE__->new($new_data);

    # Recursively clone any descendants...
    for my $child ( @$self ) {
        $new_root->push_node($child->clone);
    }

    return $new_root;
}

sub DESTROY {
    my $self = shift;
    my $key  = refaddr($self);
    delete $_NODE_DATA{$key};
}

sub data
{
    my ($self, $data) = @_;

    my $key = refaddr($self);
    if ( defined $data ) {
        $_NODE_DATA{$key} = $data;
    }

    return $_NODE_DATA{$key};
}

sub insert_node
{
    croak 'Invalid use of invoke_child method, not enough arguments'
        if ( @_ < 2 );
    my ($self, $child, $where) = @_;

    croak 'Child parameter must be a Tree::Easy object'
        unless ( $child->isa('Tree::Easy') );

    croak '$where parameter must be numeric'
        if ( defined $where && $where !~ /^-?\d$/ );

    if ( ! defined $where || $where > $#$self ) {
        carp '$where parameter is past end of children'
            if ( defined $where && $where > $#$self );
        push @{$self}, $child;
        return $child;
    }

    if ( $where < 0 ) {
        carp '$where parameter should not negative!';
        $where = 0;
    }

    splice @{$self}, $where, 0, $child;
    return $child;
}

sub push_node
{
    return $_[0]->insert_node( $_[1] );
}

sub unshift_node
{
    return $_[0]->insert_node( $_[1], 0 );
}

sub push_new
{
    my $self = shift;
    return $self->push_node( __PACKAGE__->new(@_) );
}

sub unshift_new
{
    my $self = shift;
    return $self->unshift_node( __PACKAGE__->new(@_) );
}

sub npush
{
    my $self = shift;
    my @new_nodes;

    for my $arg ( @_ ) {
        push @new_nodes, ( eval { $arg->isa(__PACKAGE__) }
                           ? $self->push_node($arg)
                           : $self->push_new($arg) );
    }

    return @new_nodes;
}

sub nunshift
{
    my $self = shift;
    my @new_nodes;

    for my $arg ( @_ ) {
        push @new_nodes, ( eval { $arg->isa(__PACKAGE__) }
                           ? $self->unshift_node($arg)
                           : $self->unshift_new($arg) );
    }

    return @new_nodes;
}

sub remove_node
{
    croak 'Invalid use of remove_node method, not enough parameters'
        if ( @_ < 2 );
    my ($self, $where) = @_;

    croak qq{Invalid \$where parameter ($where)...\nmust be a numeric index}
        unless ( $where =~ /\A \d+ \z/xms );

    croak qq{Invalid \$where parameter ($where)...\noutside of range}
        if ( ( $where < 0 && $where*-1 > $#$self ) || $where > $#$self );

    return splice @$self, $where, 1;
}

sub pop_node
{
    return $_[0]->remove_node( -1 );
}

sub shift_node
{
    return $_[0]->remove_node( 0 );
}

sub traverse
{
    croak 'Invalid use of traverse method, not enough arguments'
        if ( @_ < 2 );
    my ($self, $code_ref, $how) = @_;

    $how = 0 unless ( defined $how );

    croak "\$how parameter is invalid ($how)
must be -1, 0, or 1 for prefix, infix (default)), or postfix"
        unless ( $how eq '-1' || $how eq '0' || $how eq '1' );

    my $traverser_ref;
    $traverser_ref =
        ( $how == 0 ? sub { # infix
              my $node = shift;

              if ( @$node == 0 ) {
                  $code_ref->($node);
                  return;
              }

              if ( @$node == 1 ) {
                  # Treat one node like it's on the left...
                  $traverser_ref->($node->[0]);
                  $code_ref->($node);
                  return;
              }

              my $mid      = int( $#$node / 2 );
              my $odd_kids = @$node % 2;

              if ( $odd_kids ) { --$mid; }

              for my $i ( 0 .. $mid ) {
                  $traverser_ref->($node->[$i]);
              }

#               if ( $odd_kids ) {
#                   $traverser_ref->($node->[++$mid]);
#               }

              $code_ref->($node);

              for my $i ( ++$mid .. $#$node ) {
                  $traverser_ref->($node->[$i]);
              }
          } :
          $how == -1 ? sub { # preorder
              my $node = shift;

              $code_ref->($node);

              for my $i ( 0 .. $#$node ) {
                  $traverser_ref->($node->[$i]);
              }
          } :
          $how == 1 ? sub { # postorder
              my $node = shift;

              for my $i ( 0 .. $#$node ) {
                  $traverser_ref->($node->[$i]);
              }

              $code_ref->($node);
          } :
          die 'Internal error'
         );

    $traverser_ref->($self);
    return;
}

sub search
{
    croak 'Invalid use of search method, not enough arguments'
        if ( @_ < 2 );
    my ($self, $match, $how) = @_;

    $how = 'dfs' unless ( defined $how );
    $how = lc $how;

    croak qq{\$how parameter is invalid ($how)
must be 'dfs' or 'bfs' for depth-first or breadth-first search}
        if ( $how ne 'dfs' && $how ne 'bfs' );

    my $matcher_ref =
        ( ref $match eq 'CODE' ? $match
          : sub {
              my $node = shift;
              return $node->data eq $match;
          } );

    my $searcher_ref;
    $searcher_ref =
        ( $how eq 'dfs' ?
          sub {
              my $node = shift;
              return $node if ( $matcher_ref->($node) );
              for my $child ( @$node ) {
                  return $searcher_ref->($child);
              }
              return undef
          }
          :
          $how eq 'bfs' ?
          sub {
              my $node = shift;
              return $node if ( $matcher_ref->($node) );
              for my $child ( @$node ) {
                  return $child if ( $matcher_ref->($child) );
              }
              for my $child ( @$node ) {
                  return $searcher_ref->($child);
              }
              return undef;
          }
          :
          die 'Internal error'
         );

    return $searcher_ref->($self);
}

sub get_height
{
    my $self = shift;

    return 1 + ( @$self == 0 ? 0 :
                 max map { $_->get_height } @$self );
}

sub dump_node_data
{
    my $node = shift;

    my $data = $node->data;
    return 'undef' unless ( defined $data );

    my $reftype = ref $data;
    return ( ! $reftype ? $data :
             do {
                 unless ( $_DUMPER_IS_LOADED ) {
                     require Data::Dumper;
                     $Data::Dumper::Indent = 0;
                     $Data::Dumper::Terse  = 1;
                     $_DUMPER_IS_LOADED    = 1;
                 }
                 Data::Dumper::Dumper($data);
             } );
}

sub dumper
{
    my ($self, $file_handle, $col_limit) = @_;

    $file_handle = \*STDOUT unless ( defined $file_handle );
    $col_limit   = 78 unless ( defined $col_limit );

    croak "\$col_limit parameter ($col_limit) is invalid, must be numeric and positive"
        if ( $col_limit !~ /\A \d+ \z/xms );

    require Text::Wrap;

    my $dumper_ref;
    $dumper_ref = sub {
        my ($node, $depth_counts) = @_;

        my $node_text = $node->dump_node_data;
        my $prefix    = '';

        if ( @$depth_counts ) {
            # If there are no more items in a depth above us, they
            # won't need a line to represent their branch.
            for my $i ( 0 .. $#$depth_counts-1 ) {
                my $nodes_on_depth = $depth_counts->[$i];
                $prefix .= ( $nodes_on_depth > 0 ? '|   ' : '    ' );
            }

            # If this is the last item, make a curved "twig".
            my $more_siblings = --$depth_counts->[-1];
            $prefix .= ( $more_siblings ? '|-- ' : '`-- ' );
        }

        print $file_handle Text::Wrap::wrap( $prefix, ' ' x length($prefix), "$node_text\n" );

        # Recurse through the the children nodes...
        my $child_count = @$node;
        for my $child ( @$node ) {
            $dumper_ref->( $child,
                           [ @$depth_counts,
                             $child_count-- ] );
        }

        return;
    };

    $dumper_ref->( $self, [ ] );
    return;
}

1;

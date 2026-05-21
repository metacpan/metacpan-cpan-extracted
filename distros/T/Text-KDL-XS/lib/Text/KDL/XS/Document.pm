package Text::KDL::XS::Document;

use strict;
use warnings;

use Carp ();
use Text::KDL::XS::Node;
use Text::KDL::XS::Value;

sub new {
    my ($class, %args) = @_;
    return bless { nodes => $args{nodes} // [] }, $class;
}

sub nodes { $_[0]->{nodes} }

# Drive a parser to assemble a full document tree.
# Treats each event as a guarded transition; bails fast on illegal sequences.
sub _build_from_parser {
    my ($class, $parser) = @_;

    my $doc   = $class->new;
    my @stack;            # nodes whose children we're currently filling
    my $current;          # node we're attaching args/props to (top of stack)

    while (defined(my $ev = $parser->next_event)) {
        my $kind = $ev->{event};

        if ($kind eq 'start_node') {
            my $node = Text::KDL::XS::Node->new(
                name            => $ev->{name},
                type_annotation => $ev->{type},
            );
            if ($current) {
                $current->_push_child($node);
            }
            else {
                push @{ $doc->{nodes} }, $node;
            }
            push @stack, $node;
            $current = $node;
            next;
        }

        if ($kind eq 'end_node') {
            Carp::croak("KDL: end_node with empty stack") unless @stack;
            pop @stack;
            $current = $stack[-1];
            next;
        }

        if ($kind eq 'argument') {
            Carp::croak("KDL: argument outside any node") unless $current;
            $current->_push_arg(_value_from_event($ev->{value}));
            next;
        }

        if ($kind eq 'property') {
            Carp::croak("KDL: property outside any node") unless $current;
            $current->_push_prop($ev->{name}, _value_from_event($ev->{value}));
            next;
        }

        # Comments only appear when emit_comments is set; we currently
        # discard them at the tree layer. Streaming users can opt in.
        next if $kind eq 'comment';

        Carp::croak("KDL: unexpected event '$kind'");
    }

    Carp::croak("KDL: input ended with " . scalar(@stack) . " unclosed node(s)")
        if @stack;

    return $doc;
}

sub _value_from_event {
    my ($v) = @_;
    return $v if ref($v) eq 'Text::KDL::XS::Value';
    # XS already blesses; this guard exists only for hand-built events.
    return Text::KDL::XS::Value->new(%$v);
}

sub as_data {
    my ($self) = @_;
    return [ map { $_->as_data } @{ $self->{nodes} } ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Document - Top-level KDL document

=head1 METHODS

=over 4

=item C<nodes> - arrayref of top-level L<Text::KDL::XS::Node> objects

=item C<as_data> - lossy plain-Perl view; returns an arrayref

=back

=cut

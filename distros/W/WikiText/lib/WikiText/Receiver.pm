use strict; use warnings;
package WikiText::Receiver;

sub new {
    my $class = shift;
    my $self = bless {
        ref($class) ? (map {
            /^(?:output)$/ ? () : ($_, $class->{$_})
        } keys %$class) : (),
        @_
    }, ref($class) || $class;
}

sub content {
    my $self = shift;
    return $self->{output};
}

sub init {
    my $self = shift;
    die "You need to override WikiText::Receiver::init";
}

sub insert {
    my $self = shift;
    my $ast = shift;
    die "You need to override WikiText::Receiver::insert";
    # $self->{output} .= $ast->{output};
}

sub begin_node {
    my $self = shift;
    my $context = shift;
    die "You need to override WikiText::Receiver::begin_node";
    # $self->{output} .= "+" . $context->{type} . "\n";
}

sub end_node {
    my $self = shift;
    my $context = shift;
    die "You need to override WikiText::Receiver::end_node";
    # $self->{output} .= "-" . $context->{type} . "\n";
}

sub text_node {
    my $self = shift;
    my $text = shift;
    die "You need to override WikiText::Receiver::text_node";
    # $self->{output} .= " $text\n";
}

1;

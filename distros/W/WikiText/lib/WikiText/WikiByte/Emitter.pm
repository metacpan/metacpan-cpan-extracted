package WikiText::WikiByte::Emitter;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {
        @_,
        last_event => '',
    }, ref($class) || $class;
}

sub init {
    my $self = shift;
    $self->{output} = '';
}

sub content {
    my $self = shift;
    return $self->{output};
}

sub insert {
    my $self = shift;
    my $ast = shift;
    if ($self->{last_event} eq 'text') {
        chomp $self->{output};
        my $subtext = $ast->{output} || '';
        $subtext =~ s/^ //;
        $self->{output} .= $subtext;
    }
    else {
        $self->{output} .= $ast->{output} || '';
    }
}

sub begin_node {
    my $self = shift;
    my $node = shift;
    my $tag = $node->{type};
    $tag =~ s/-.*//;
    my $attributes = _get_attributes($node);
    $self->{output} .= "+$tag$attributes\n";
    $self->{last_event} = 'begin';
}

sub end_node {
    my $self = shift;
    my $node = shift;
    my $tag = $node->{type};

    $self->{last_event} = 'end';

    return if $self->{output} =~ s/^\+$tag\b(.*\n)\z/=$tag$1/m;

    $tag =~ s/-.*//;
    $self->{output} .= "-$tag\n";
}

sub text_node {
    my $self = shift;
    my $text = shift;
    $text =~ s/\n/\n /g;
    if ($self->{last_event} eq 'text') {
        chomp $self->{output};
        $self->{output} .= "$text\n";
    }
    else {
        $self->{output} .= " $text\n";
    }
    $self->{last_event} = 'text';
}

sub _get_attributes {
    my $node = shift;
    return "" unless exists $node->{attributes};
    return join "", map {
        qq{ $_="${\ $node->{attributes}->{$_}}"}
    } sort keys %{$node->{attributes}};
}

1;

package  WWW::Webrobot::Tree2Postfix;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use Data::Dumper;
use Carp;


sub _init {
    my ($self, $op, $attr_op, $attr_fun) = @_;
    $self->{$attr_op} = $op;
    $self->{$attr_fun} = sub {
        my ($operator) = @_;
        return $op -> {$operator} || sub {
            my $op = ref $operator ? Dumper($operator) : "<$operator>";
            Carp::confess "Operator $op not allowed";
        }
    };
}

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    my ($unary_op, $binary_op, $predicate, $default_binary_op) = @_;
    die '$default_binary_op must be an element of $binary_op'
        if defined $default_binary_op && !exists $binary_op->{$default_binary_op};
    $self->_init($unary_op, "unary_op", "unary_fun");
    $self->_init($binary_op, "binary_op", "binary_fun");
    $self->_init($predicate, "predicate", "predicate_fun");
    $self->{default_binary_op} = $default_binary_op;
    return $self;
}

sub tree2postfix {
    my ($self, $tree) = @_;
    $self->{postfix} = [];
    $self->tree2postfix0({}, $self->{default_binary_op}, $tree);
    #return $self->{postfix};
}

sub tree2postfix0 {
    my ($self, $p_attributes, $p_tag, $p_content) = @_;
    #print "ATT,TAG,CONTENT: $p_attributes, $p_tag, $p_content\n";
    #print Dumper($p_content);
    die "missing predicate" if ! $p_tag;
    my $attributes = $p_content->[0];
    if ($self->{binary_op}->{$p_tag}) {
        my $tag = $p_content->[1];
        my $content = $p_content->[2];
        $self->tree2postfix0($attributes, $tag, $content);
        for (my $i = 3; $i < scalar @$p_content; $i += 2) {
            $tag = $p_content->[$i];
            $content = $p_content->[$i+1];
            $self->tree2postfix0($attributes, $tag, $content);
            push @{$self->{postfix}}, $p_tag;
        }
    }
    elsif ($self->{unary_op}->{$p_tag}) {
        my $tag = $p_content->[1];
        my $content = $p_content->[2];
        $self->tree2postfix0($attributes, $tag, $content);
        push @{$self->{postfix}}, $p_tag;
        die "only one predicate allowed at this place: <$tag>" if @$p_content > 3;
    }
    else {
        my $attributes = $p_content->[0];
        if (@$p_content > 2 && ! $p_content->[1] && ! exists $attributes->{value}) {
            $attributes->{value} = $p_content->[2];
            # skip leading and trailing white space
            $attributes->{value} =~ s/^\s+//s;
            $attributes->{value} =~ s/\s+$//s;
        }
        push @{$self->{postfix}}, [$p_tag, $p_content];
    }
}


sub eval_postfix {
    my ($self, $r) = @_;
    my @stack = ();
    my @error = ();
    foreach my $entry (@{$self->{postfix}}) {
        if (ref $entry eq 'ARRAY') {
            my ($tag, $content) = @$entry;
            my $value = $self->{predicate_fun} -> ($tag) -> ($r, $content->[0]);
            my $stringified = do {
                my $dump = Data::Dumper->new([$content->[0]]);
                $dump->Indent(0);
                (my $tmp = $dump->Dump) =~ s/\$VAR1 *//;
                $tmp;
            };
            push(@error, "$value <$tag> $stringified");
            push @stack, $value;
        }
        elsif (!ref $entry) {
            my $operator = $entry;
            if ($self->{unary_op}->{$operator}) {
                my $operand = pop @stack;
                my $result = $self -> {unary_fun} -> ($entry) -> ($operand);
                push @stack, $result;
            }
            elsif ($self->{binary_op}->{$operator}) {
                my $op1 = pop @stack;
                my $op0 = pop @stack;
                my $result = $self -> {binary_fun} -> ($entry) -> ($op0, $op1);
                push @stack, $result;
            }
            else {
                die "Operator <$operator> not implemented";
            }
        }
        else {
            die "Programmer error: Predicate (ARRAY) or operator (scalar) expected";
        }
    }

    my $result = pop @stack;
    die "Stack not empty after evaluation, stack = " . Dumper(\@stack) if @stack;
    return ($result, \@error);
}

sub postfix {
    my ($self) = @_;
    return $self->{postfix};
}


1;


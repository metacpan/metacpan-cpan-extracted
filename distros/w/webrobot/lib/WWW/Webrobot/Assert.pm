package WWW::Webrobot::Assert;
use strict;
use warnings;

use WWW::Webrobot::Tree2Postfix;
use WWW::Webrobot::XHtml; # for method HTTP::Headers->xpath


my $unary_operator = {
    'not' => sub { ! $_[0] },
};

my $binary_operator = {
    'and' => sub { $_[0] && $_[1] },
    'or'  => sub { $_[0] || $_[1] },
};

my $predicate = {
    status => sub {
        my ($r, $tree) = @_;
        my $expect = $tree->{value};
        my $rc = $r->code;
        return $expect == $rc || 100*$expect <= $rc && $rc < 100*($expect+1) ? 1 : 0;
    },
    string => sub {
        my ($r, $tree) = @_;
        #use Data::Dumper; print STDERR Dumper $tree;
        my $pattern = quotemeta($tree->{value});
        return $r->content_encoded =~ m/$pattern/ ? 1 : 0;
    },
    regex => sub {
        my ($r, $tree) = @_;
        my $pattern = $tree->{value};
        return $r->content_encoded =~ m/$pattern/ ? 1 : 0;
    },
    xpath => sub {
        my ($r, $tree) = @_;
        my $xpath = $tree->{xpath};
        my $value = $tree->{value};
        # ??? quotemeta in pattern?
        return $r->xpath($xpath) =~ /$value/ ? 1 : 0;
    },
    timeout => sub {
        my ($r, $tree) = @_;
        return $r->elapsed_time() < $tree->{value} ? 1 : 0;
    },
    header => sub {
        my ($r, $tree) = @_;
        my $name = $tree->{name};
        my $pattern = $tree->{value};
        my $h = $r->header($name);
        return $h && $h =~ m/$pattern/ ? 1 : 0;
    },
    file => sub {
        my ($r, $tree) = @_;
        local *FILE;
        open FILE, "<", $tree->{value} or die "Can't open file: $tree->{value}";
        local $/;             # enable slurp mode
        my $text = <FILE>;    # read complete file
        close FILE;
        my $pattern = quotemeta($text);
        return $r->content_encoded =~ m/$pattern/ ? 1 : 0;
    },
};


sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    my ($tree) = @_;
    #use Data::Dumper; print STDERR "ASSERT: ", Dumper $tree;
    $self->{evaluator} = WWW::Webrobot::Tree2Postfix -> new(
        $unary_operator, $binary_operator, $predicate, "and"
    );
    $self->{evaluator} -> tree2postfix($tree);
    #use Data::Dumper; print STDERR "EVALUATOR: ", Dumper $self->{evaluator}->postfix;
    return $self;
}


sub check {
    my ($self, $r) = @_;
    my ($value, $error) = $self -> {evaluator} -> eval_postfix($r);
    return $value ? (0, $error) : (1, $error);
}

sub postfix {
    my ($self) = @_;
    return $self->{evaluator}->postfix;
}


1;

=head1 NAME

WWW::Webrobot::Assert - Assertions for (http) requests

=head1 Predicates

=over

=item status

=item regex

=item xpath

=item timeout

=back

=head1 Binary Operators

=over

=item and

=item or

=back

=head1 Unary Operators

=over

=item not

=back

=cut

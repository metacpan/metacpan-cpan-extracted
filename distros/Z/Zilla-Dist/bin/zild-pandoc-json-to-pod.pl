#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use XXX;

my $o = bless {};

sub run {
    my ($self) = @_;
    my $json = do { local $/; <> };
    my $ast = decode_json $json;
    binmode(STDOUT, ":utf8");
    print $self->fmt_pod($ast);
}

sub fmt_pod {
    my ($self, $ast) = @_;

    my $text =
        "=pod\n\n" .
        "=encoding utf8\n\n" .
        $self->fmt($ast->{blocks}) .
        "=cut\n";

    return $self->fix_name_heading($text);
}

sub fix_name_heading {
    my ($self, $text) = @_;

    $text =~ s{\A
        =head1\s+(.*) \n\n
        (\S.*) \n\n
        (?==head)
    }{
        "=head1 NAME\n\n" .
        "$1 - $2\n\n"
    }ex;

    return $text;
}

sub tc {
    my ($self, $node) = @_;
    ZZZ $node unless ref($node) eq 'HASH';
    my ($t, $c) = @{$node}{qw't c'};
    ZZZ $node unless $t;
    $t = lc($t);
    $c //= [];
    return ($t, $c);
}

sub fmt {
    my ($self, $nodes) = @_;
    my $o = '';
    for my $node (@$nodes) {
        my ($t, $c) = $self->tc($node);
        my $method = "fmt_$t";
        $o .= $self->$method($c);
    }
    return $o;
}

sub fmt_header {
    my ($self, $args) = @_;
    my ($level, $x, $list) = @$args;
    my $heading = $self->fmt($list);
    $heading = uc $heading if $level <= 2;
    return "=head$level $heading\n\n";
}

sub fmt_str {
    my ($self, $str) = @_;
    $str;
}

sub fmt_space {
    ' ';
}

sub fmt_para {
    my ($self, $list) = @_;
    $self->fmt($list) . "\n\n";
}

sub phrase {
    my ($self, $style, $text) = @_;
    $text =~ /(<<<<<|<<<<|<<<|<<|<|)/ or die;
    my $num = length($1) + 1;
    return (
        $style .
        ('<' x $num) .
        $text .
        ('>' x $num)
    )
}

sub fmt_link {
    my ($self, $args) = @_;
    my ($x, $text, $link) = @$args;
    $link = $link->[0];
    if ($text) {
        $text = $self->fmt($text);
        return $self->phrase(L => "$text|$link");
    }
    else {
        return $self->phrase(L => "$link");
    }
}

sub fmt_code {
    my ($self, $args) = @_;
    my ($x, $text) = @$args;
    $self->phrase(C => $text);
}

sub fmt_strong {
    my ($self, $list) = @_;
    $self->phrase(B => $self->fmt($list));
}

sub fmt_emph {
    my ($self, $list) = @_;
    $self->phrase(I => $self->fmt($list));
}

sub fmt_strikeout {
    my ($self, $list) = @_;
    $self->fmt($list);
}

sub fmt_codeblock {
    my ($self, $args) = @_;
    my ($x, $code) = @$args;
    my $o = "$code\n";
    $o =~ s/^(.)/    $1/gm;
    return $o;
}

sub make_list {
    my ($self, $bullet, $items) = @_;

    my $o = "=over\n\n";
    for my $item (@$items) {
        $o .= "=item $bullet " .
            $self->fmt($item)
    }
    $o .= "=back\n\n";
    return $o;
}

sub fmt_bulletlist {
    my ($self, $items) = @_;

    return $self->make_list('*' => $items);
}

sub fmt_orderedlist {
    my ($self, $args) = @_;
    my ($x, $items) = @$args;

    return $self->make_list('1.' => $items);
}

sub fmt_plain {
    my ($self, $list) = @_;
    $self->fmt($list) . "\n\n";
}

sub fmt_horizontalrule {
    "=for html <hr/>\n\n";
}

sub fmt_softbreak {
    ' ';
}

$o->run(@ARGV);

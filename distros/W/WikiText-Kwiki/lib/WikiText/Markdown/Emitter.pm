##
# name:      WikiText::Markdown::Emitter
# abstract:  A WikiText Receiver That Generates Markdown
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2008, 2011

package WikiText::Markdown::Emitter;
use strict;
use warnings;
use base 'WikiText::Emitter';

# use XXX;

use constant N => "\n";
use constant NN => "\n\n";
my $pre = 0;
my $link = '';
my $list_stack = [];
my $list_depth = 0;

sub reset {
    $pre = $list_depth = 0;
    $list_stack = [];
    $link = '';
}

use constant markdown => {
    h1 => ['# ', NN],
    h2 => ['## ', NN],
    h3 => ['### ', NN],
    h4 => ['#### ', NN],
    h5 => ['##### ', NN],
    h6 => ['###### ', NN],
    p => ['', N],
    hr => ['---', NN],
    ul => [undef, undef],
    ol => [undef, undef],
    li => [undef, ''],
    text => ['', ''],
    link => [undef, undef],
    b => ['**', '**'],
    i => ['_', '_'],
    tt => ['`', '`'],
    table => ['', N],
    tr => ['', "|\n"],
    td => ['| ', ' '],
    pre => [undef, N],
};

sub begin_node {
    my ($self, $node) = @_;
    my $type = $node->{type};
    # print "BEGIN $type\n";
    my $markdown = markdown()->{$type}
        or die "Unhandled markup '$type'";
    my $method = "begin_$type";
    $self->{output} .= defined $markdown->[0]
        ? $markdown->[0]
        : $self->$method($node);
}

sub end_node {
    my ($self, $node) = @_;
    my $type = $node->{type};
    # print "END $type\n";
    my $markdown = markdown()->{$type}
        or die "Unhandled markup '$type'";
    my $method = "end_$type";
    $self->{output} .= defined $markdown->[1]
        ? $markdown->[1]
        : $self->$method($node);
}

sub text_node {
    my ($self, $text) = @_;
    # print "TEXT $text\n";
    if ($link) {
        return;
    }
    elsif ($pre) {
        $pre = 0;
        $text =~ s/^/    /gm;
        $text =~ s/^ *$//gm;
        $self->{output} .= $text;
    }
    else {
        $self->{output} .= $text;
    }
}

sub begin_pre {
    $pre = 1;
    '';
}

sub begin_link {
    my ($self, $node) = @_;
    $link = $node->{attributes}{target};
    return '';
}

sub end_link {
    my ($self, $node) = @_;
    my $l = $link;
    $link = '';
    if ($l =~ /^\w+$/) {
        return "[$l](/$l)";
    }
    elsif ($l =~ /^(https?|ftp|irc|file):[^\ ]+$/) {
        return $l;
    }
    elsif ($l =~ /(.*?) *((?:https?|ftp|irc|file):[^\ ]+) *(.*)/) {
        my $t = $1;
        $t .= " " if length $t and length $3;
        $t .= $3 if length $3;
        return "[$t]($2)";
    }
    elsif ($l =~ /^(?:\w+)(\ \w+)+$/) {
        my $t = $l;
        $l =~ s/ /_/g;
        return "[$t](/$l)";
    }
    else {
        warn "Invalid link: '$l'";
        return '$l';
    }
}

sub begin_ol {
    my ($self) = @_;
    $list_stack->[$list_depth++] = 'ol';
    '';
}

sub begin_ul {
    my ($self) = @_;
    $list_stack->[$list_depth++] = 'ul';
    '';
}

sub begin_li {
    my ($self) = @_;
    my $indent = ' ' x (($list_depth - 1) * 2);
    return $indent . '* '
        if $list_stack->[$list_depth - 1] eq 'ul';
    return $indent . '1. ';
}

sub end_ol {
    my ($self) = @_;
    $list_depth--;
    return($list_depth ? "" : "\n");
}

sub end_ul {
    my ($self) = @_;
    $list_depth--;
    return($list_depth ? "" : "\n");
}

1;

=head1 SYNOPSIS

    use WikiText::Markdown::Emitter;

=head1 DESCRIPTION

This receiver module, when hooked up to a parser, produces Markdown.

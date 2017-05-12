#!/usr/bin/env perl

=encoding utf-8

=head1 NAME

make_dict.pl - Dictionary generator

=head1 SYNOPSIS

    $ make_dict.pl [options] <source text> <source text> ...

=cut

use strict;
use warnings;
use utf8;

package MarkovCalculator;

use List::MoreUtils qw( all );

sub new {
    my ($class, %options) = @_;
    my $self = bless {}, $class;
    $self->{chain}        = $options{chain} || 1;
    $self->{ignore_type}  = $options{ignore_type};
    $self->{term_bracket} = $options{term_bracket};
    $self->{skip_bracket} = $options{skip_bracket} || $self->{term_bracket};

    $self->{bracket_level} = 0;

    # word dictionary
    $self->{dict} = { "" => { id => 0, word => "", next => [] } };
    $self->{word_id} = 1;

    # probability (candidates)
    $self->{tree} = {};

    $self->clear_stack();

    return $self;
}

sub input_line {
    my ($self, $line) = @_;
    chomp $line;
    return if $line eq 'EOS';

    my ($word, $type) = split /\s+/, $line;

    if ($self->{term_bracket}) {
        if ($word eq '」') {
            $self->sentence_is_terminated();
            return;
        }
    }

    if ($self->{skip_bracket}) {
        return if $word eq '「' || $word eq '」';
    } else {
        if ($word eq '「') {
            $self->{bracket_level} ||= 0;
            $self->{bracket_level} ++;
        } elsif ($word eq '」') {
            $self->{bracket_level} ||= 0;
            $self->{bracket_level} --;
        }
    }

    if ($self->{ignore_type}) {
        $line = $word;
    }

    # register word to dictionary
    my $id;
    if (exists $self->{dict}->{$line}) {
        $id = $self->{dict}->{$line}->{id};
    } else {
        $id = $self->{word_id} ++;
        $self->{dict}->{$line} = { id => $id, word => $word };
    }

    # add to candidates
    $self->add_word_to_candidate($id);

    shift @{$self->{stack}};
    push @{$self->{stack}}, $id;

    # termination
    if ($word =~ m{\A [。？！] \z}xmso && ! $self->{bracket_level}) {
        $self->sentence_is_terminated();
    }

    return;
}

sub input {
    my ($self, @lines) = @_;

    foreach my $line (@lines) {
        chomp $line;
        $self->input_line($line);
    }
}

sub output_dictionary {
    my ($self, $handle) = @_;

    # chains
    print {$handle} $self->{chain}, "\n";

    # word dictionary
    $self->output_words($handle);

    # separator
    print {$handle} "\n";

    # probabilities
    $self->output_tree($handle);
}

sub output_words {
    my ($self, $handle) = @_;

    foreach my $item (sort { $a->{id} <=> $b->{id} } values %{$self->{dict}}) {
        print {$handle} $item->{word}, "\n";
    }
}

sub output_tree {
    my ($self, $handle) = @_;
    $self->output_tree_node($handle, $self->{tree}, 0);
}

sub output_tree_node {
    my ($self, $handle, $node, $depth) = @_;
    foreach my $key (sort { $a <=> $b } keys %$node) {
        my $child = $node->{$key};

        print {$handle} " " x $depth;
        print {$handle} $key;

        if (exists $child->{cands}) {
            print {$handle} "=";

            my @cands = sort { $a <=> $b } @{ $child->{cands} };
            my $first = $cands[0];
            if (all { $_ eq $first } @cands) {
                @cands = ( $first );
            }

            print {$handle} join(",", @cands), "\n";
        } else {
            print {$handle} "\n";

            $self->output_tree_node($handle, $child, $depth + 1);
        }
    }
}

sub sentence_is_terminated {
    my ($self) = @_;

    if (@{$self->{stack}} && $self->{stack}->[0] != 0) {
        while ($self->{stack}->[0] != -1) {
            $self->add_word_to_candidate(-1);   # EOS

            shift @{$self->{stack}};
            push @{$self->{stack}}, -1;
        }
    }

    $self->clear_stack();
}

sub add_word_to_candidate {
    my ($self, $word_id) = @_;
    my $node = $self->{tree};
    my @s = @{$self->{stack}};
    while (@s) {
        my $wid = shift @s;
        $node->{$wid} ||= {};
        $node = $node->{$wid};
    }

    $node->{cands} ||= [];
    push @{$node->{cands}}, $word_id;
}

sub clear_stack {
    my ($self) = @_;
    $self->{stack} = [ (0) x $self->{chain} ];
}

package main;

use Encode ();
use Getopt::Long qw( :config posix_default no_ignore_case bundling auto_help );
use Pod::Usage qw( pod2usage );

my %opt = (
    chain       => 2,
    ignore_type => 0,
);

GetOptions(\%opt, qw(
    chain|c=i
    ignore-type|i
    term-bracket|b
    skip-bracket|s
    help|h|?
)) or pod2usage(2);
pod2usage( -exitval => 2, -verbose => 1 ) if $opt{help};

foreach my $key (keys %opt) {
    my $new_key = $key;
    $new_key =~ s/-/_/go;
    if ($new_key ne $key) {
        $opt{$new_key} = delete $opt{$key};
    }
}

my $utf8 = Encode::find_encoding('UTF-8');

my @lines;
while (my $line = <>) {
    push @lines, $utf8->decode($line);
}

my $calculator = MarkovCalculator->new(%opt);
$calculator->input(@lines);
binmode \*STDOUT, ':encoding(UTF-8)';
$calculator->output_dictionary(\*STDOUT);

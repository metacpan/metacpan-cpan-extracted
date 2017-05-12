#: FAST.pm
#: Global application class for FAST
#: Copyright (c) 2006 Agent Zhang
#: 2006-03-08 2006-04-03

package FAST;

use 5.006001;
use strict;
use warnings;

#use GraphViz;
use FAST::Struct::Seq;
use FAST::Struct::While;
use FAST::Struct::If;
#use Clone;

#use Data::Dumper::Simple;

our $VERSION = '0.01';

our %FluxNodeStyle = (
    shape => 'circle',
    style => 'filled',
    filllcolor => 'yellow',
);

our $Error;

our $NodeIdPat = qr/(?:\d+:)?/;

sub new {
    my ($proto, $src) = @_;
    if (not $src) {
        $Error = "FAST::new: error: No input source specified.";
        return undef;
    }
    my $class = ref $proto || $proto;
    my $self = bless {
    }, $class;
    return $self->parse($src) ? $self : undef;
}

sub parse {
    my ($self, $src) = @_;
    my ($fname, $in);
    if (ref $src) {
        open $in, '<', $src;
        $fname = 'STRING';
    } else {
        $fname = $src;
        if (not open $in, $fname) {
            $Error = "FAST::parse: Can't open `$fname' for reading: $!";
            return undef;
        }
    }
    my (%edge_from, %edge_to);
    local $/ = "\n";
    my $done = 1;
    while (<$in>) {
        next if /^\s*$/;
        if (/^\s* (.*\S) \s* => \s* (.*\S) \s*$/xo) {
            my ($from, $to) = ($1, $2);
            if (not _check_node_name($from)) {
                parse_error(
                    $fname,
                    "syntax error: Use of invalid node name `$from'"
                );
                $done = 0;
                last;
            } elsif (not _check_node_name($to)) {
                parse_error(
                    $fname,
                    "syntax error: Use of invalid node name `$to'"
                );
                $done = 0;
                last;
            }
            if ($to eq 'entry') {
                parse_error(
                    $fname,
                    "syntax error: `entry' node used on right-hand-side"
                );
                $done = 0;
                last;
            }
            if ($from eq 'exit') {
                parse_error(
                    $fname,
                    "syntax error: `exit' node used on left-hand-side"
                );
                $done = 0;
                last;
            }

            $edge_from{$to} ||= [];
            $edge_from{$from} ||= [];
            $edge_to{$from} ||= [];
            $edge_to{$to}   ||= [];

            if ($from eq 'entry' and @{ $edge_to{entry} } > 0) {
                parse_error($fname, "error: More than one `entry' node specified");
                $done = 0;
                last;
            }
            if ($from =~ /^<.*>$/ and @{ $edge_to{$from} } == 2) {
                parse_error(
                    $fname,
                    "error: Predicate node `$from' has more than two descendants"
                );
                $done = 0;
                last;
            }
            if ($from =~ /^\[.*\]$/ and @{ $edge_to{$from} } == 1) {
                parse_error(
                    $fname,
                    "error: Function node `$from' has more than one descendant"
                );
                $done = 0;
                last;
            }

            push @{ $edge_from{$to} }, $from;
            push @{ $edge_to{$from} }, $to;
        } else {
            chomp $_;
            parse_error($fname, "syntax error: `$_'");
            $done = 0;
            last;
        }
    }
    close $in;
    return undef if not $done;

    if (! $edge_to{entry}) {
        parse_error($fname, "error: No `entry' node found");
        return undef;
    }
    if (! $edge_from{exit}) {
        parse_error($fname, "error: No `exit' node found");
        return undef;
    }
    while (my ($k, $v) = each %edge_to) {
        if ($k ne 'entry' and @{ $edge_from{$k} } == 0) {
            parse_error(
                $fname,
                "error: There is no way to reach node $k",
            );
            return undef;
        }
        if ($k =~ /^<.*>$/ and @$v != 2) {
            if (@$v == 1) {
                parse_error(
                    $fname,
                    "error: Predicate node `$k' has only one descendant"
                );
            } elsif (@$v == 0) {
                parse_error(
                    $fname,
                    "error: Predicate node `$k' has no descendants"
                );
            }
            return undef;
        } elsif ($k =~ /^\[.*\]$/ and @$v != 1) {
            if (@$v == 0) {
                parse_error(
                    $fname,
                    "error: Function node `$k' has no descendants"
                );
            }
            return undef;
        }
    }

    $self->{edge_from} = \%edge_from;
    $self->{edge_to}   = \%edge_to;
    return 1;
}

sub _check_node_name {
    my $name = shift;
    return $name =~ /^\[.*\]$/ ||
        $name =~ /^<.*>$/ ||
        $name eq 'exit' || $name eq 'entry';
}

sub parse_error {
    my ($fname, $msg) = @_;
    if ($.) {
        $Error = "FAST::parse: $fname: line $.: $msg.";
    } else {
        $Error = "FAST::parse: $fname: $msg.";
    }
}

sub error {
    return $Error;
}

sub as_png {
    my ($self, $outfile) = @_;
    my $gv = $self->as_img;
    $gv->as_png($outfile);
}

sub as_debug {
    my ($self, $outfile) = @_;
    my $gv = $self->as_img;
    my $content = $gv->as_debug($outfile);
    if ($outfile) {
        open my $out, "> $outfile" or
            die "Can't open $outfile for writing: $!";
        print $out $content;
        close $out;
    } else {
        return $content;
    }
}

sub as_img {
    my ($self) = @_;
    my %edge_from = %{ Clone::clone($self->{edge_from}) };
    my %edge_to   = %{ Clone::clone($self->{edge_to}) };

    my $gv = GraphViz->new(
        layout => 'neato',
        edge => {color => 'red'},
        node => {
            fillcolor => '#f1e1f4',
            color => '#918194',
            style => 'filled',
        },
    );

    my $c = 0;
    while (my ($key, $val) = each %edge_from) {
        if (@$val > 1) {
            my $flux_node = "flux_" . $c++;
            $self->plot_node($gv, '', $flux_node);
            $self->plot_node($gv, $key);
            $gv->add_edge($flux_node => $key);
            for my $from (@$val) {
                if ($edge_to{$from}->[0] eq $key) {
                    $edge_to{$from}->[0] = $flux_node;
                } else {
                    $edge_to{$from}->[1] = $flux_node;
                }
                $self->_plot_edge($gv, $from => $flux_node, \%edge_to);
            }
        } elsif (@$val == 1) {
            $self->plot_node($gv, $key);
            $self->_plot_edge($gv, $val->[0] => $key, \%edge_to);
        } else {
            $self->plot_node($gv, $key);
        }
    }
    return $gv;
}

sub _plot_edge {
    my ($self, $gv, $from, $to, $redge_to) = @_;
    my @to_nodes = @{ $redge_to->{$from} };
    my $label;
    if (@to_nodes > 1) {
        $label = $to eq $to_nodes[0] ? 'Y' : 'N';
    }
    if ($label) {
        $gv->add_edge($from => $to, label => $label);
    } else {
        $gv->add_edge($from => $to);
    }
}

sub plot_node {
    my ($self, $gv, $node, $id) = @_;
    die if not $gv;
    $id = $node if not defined $id;
    if ($node =~ /^\s*$/) {
        $gv->add_node($id, label => ' ', %FluxNodeStyle);
    } elsif ($node =~ /^\[$NodeIdPat?(.*)\]$/) {
        $gv->add_node($id, label => $1, shape => 'box');
    } elsif ($node =~ /^<$NodeIdPat?(.*)>$/) {
        $gv->add_node($id, label => $1, shape => 'diamond');
    } else {
        $gv->add_node(
            $id,
            label => $node,
            shape => 'plaintext',
            style => 'filled',
            fillcolor => 'white',
        );
    }
}

sub as_asm {
    my ($self, $outfile) = @_;
    my ($out, $buf);
    if ($outfile) {
        if (!open $out, ">$outfile") {
            $Error = "as_asm: Can't open `$outfile' for writing: $!";
        }
    } else {
        $buf = '';
        open $out, '>', \$buf;
    }

    my %edge_from = %{ Clone::clone($self->{edge_from}) };
    my %edge_to   = %{ Clone::clone($self->{edge_to}) };

    my (%labels, %visited, @tasks);
    if (! $edge_to{entry}) {
        $Error = "as_asm: No `entry' node found.";
        return undef;
    }

    my $cur = $edge_to{entry}->[0];
    if ($cur eq 'exit') {
        print $out "    exit\n";
        close $out;
        return $outfile ? 1 : $buf;
    }

    my $c = 1;
    my $head = 1;
    while ($cur) {
        if ($visited{$cur}) {
            my $label = $labels{$cur};
            #warn "JMP!!! $prev - $cur - $label";
            if (!$head) {
                print $out "    jmp  $label\n";
                $head = 1;
            }
            $cur = shift @tasks;
            next;
        }
        my $r_prev = $edge_from{$cur};
        warn "$cur" if not $r_prev;
        if (@{ $r_prev } > 1) {
            $labels{$cur} ||= 'L' . $c++;
            my $label = $labels{$cur};
            print $out "$label:\n";
            $visited{$cur} = 1;
        } elsif ($labels{$cur}) {
            print $out "$labels{$cur}:\n";
        }
        my $cmd = $self->node2asm($cur);
        print $out "    $cmd\n";
        $head = $cmd eq 'exit';
        my @next = @{ $edge_to{$cur} };
        if (@next > 1) {
            $labels{$next[1]} ||= 'L'.$c++;
            my $label = $labels{$next[1]};
            print $out "    jno  $label\n";
            push @tasks, $next[1];
            $cur = $next[0];
        } elsif (@next == 1) {
            $cur = $next[0];
        } else {
            $cur = shift @tasks;
        }
    }
    close $out;
    return $outfile ? 1 : $buf;
}

sub node2asm {
    my ($self, $node) = @_;
    if ($node =~ /^<$NodeIdPat?(.*)>$/) {
        return "test $1";
    } elsif ($node =~ /^\[$NodeIdPat?(.*)\]$/) {
        return "do   $1";
    } else {
        return $node;
    }
}

sub structured {
    my $self = shift;
    my %opts = @_;
    if (%opts and not exists $opts{optimized}) {
        my @opts = %opts;
        die "FAST::structured: Options @opts not recognized";
    }
    my %edge_to   = %{ $self->{edge_to} };
    my $entry = $edge_to{entry}->[0];
    if ($entry eq 'exit') {
        return FAST::Struct::Seq->new('', '');
    }
    my @nodes =
        grep { $_ ne $entry and (/^\[.*\]$/ or /^<.*>$/) }
            keys %edge_to;
    @nodes = sort { _core_label($a) cmp _core_label($b) } @nodes;
    unshift @nodes, $entry;
    #warn Dumper(@nodes);
    my %ids;
    for (0..$#nodes) {
        $ids{ $nodes[$_] } = $_ + 1;
    }
    #warn Dumper(%ids);

    my @g;
    my $i = 1;
    for my $node (@nodes) {
        my @next = map { $ids{$_} || 0 } @{ $edge_to{$node} };
        #warn "$node with @next";
        if (@next == 1) {
            $g[$i] = FAST::Struct::Seq->new($node, "[L:=$next[0]]");
        } else {
            $g[$i] = FAST::Struct::If->new($node, "[L:=$next[0]]", "[L:=$next[1]]");
        }
        $i++;
    }
    #warn Dumper(@g);
    if (not $opts{optimized}) {
        return _gen_unoptimized_ast(@g);
    } else {
        return _gen_optimized_ast(@g);
    }
}

sub _core_label {
    my $node = shift;
    if ($node =~ /^<(.*)>$/) {
        return $1;
    } elsif ($node =~ /^\[(.*)\]$/) {
        return $1;
    } else {
        return $node;
    }
}

sub _gen_unoptimized_ast {
    my @g = @_;
    my $i = $#g;
    my $prev = '';
    while ($i >= 1) {
        next if not defined $g[$i];
        $prev = FAST::Struct::If->new("<L=$i>", $g[$i], $prev);
    } continue {
        $i--;
    }
    my $loop = FAST::Struct::While->new('<L>0>', $prev);
    my $ast = FAST::Struct::Seq->new('[L:=1]', $loop);
    return $ast;
}

sub _gen_optimized_ast {
    my @g = @_;
    my $i = $#g;
    while ($i > 1) {
        if ($g[$i]->might_pass("[L:=$i]")) {
            #warn "info: g[$i] is recursive";
            next;
        }
        #warn "info: g[$i] should be substituted out";
        map {
            defined $_ and $_ ne $g[$i] and
            $_->subs("[L:=$i]", $g[$i])
        } @g;
        $g[$i] = undef;
    } continue {
        $i--;
    }
    if ((grep { defined $_ } @g) > 1) {
        if (not $g[1]->might_pass('[L:=1]')) {
            my $g1 = $g[1];
            $g[1] = undef;
            my $ast = _gen_unoptimized_ast(@g);
            $ast->subs('[L:=1]', $g1);
            return $ast;
        } else {
            return _gen_unoptimized_ast(@g);
        }
    }
    my $g = $g[1];
    if ($g->must_pass('[L:=0]')) {
        $g->subs('[L:=0]', '');
        return $g;
    }
    $g->subs('[L:=1]', '');
    my $loop = FAST::Struct::While->new('<L>0>', $g);
    my $ast = FAST::Struct::Seq->new('[L:=1]', $loop);
    return $ast;
}

package FAST::Util;

# nothing here...

1;
__END__

=head1 NAME

FAST - Library for Flowchart Abstract Syntax Tree

=head1 SYNOPSIS

    use FAST;

    $src = <<'.';
    entry => <p>
    <p> => [c]
    [c] => <q>
    <p> => [a]
    <q> => <p>
    <q> => exit
    [a] => [b]
    [b] => exit
    .

    # Load from string:
    $g = FAST->new(\$src) or
        die FAST->error;

    # Load from disk file:
    $g = FAST->new('foo.in') or
        die FAST->error;

    # Generate PNG image:
    $g->as_png('blah.png');

    # Or return the image data directly:
    $bin_data = $g->as_png;

    # Generate pseud assembly code dipicting the flowchart:
    $g->as_asm('blah.asm');

    # Or return the ASM code directly:
    $asm_src = $g->as_asm;

=head1 DESCRIPTION

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below is the
L<Devel::Cover> report on this module's test suite (version 0.01 rev 317):

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/FAST.pm               97.6   91.1   90.0  100.0    0.0   34.2   93.5
    blib/lib/FAST/Element.pm      100.0    n/a   33.3  100.0    0.0   18.4   88.7
    blib/lib/FAST/Node.pm         100.0  100.0  100.0  100.0    0.0   18.4   87.1
    blib/lib/FAST/Struct.pm       100.0  100.0  100.0  100.0    0.0    2.6   95.2
    blib/lib/FAST/Struct/If.pm    100.0   75.0  100.0  100.0    0.0   18.4   86.9
    blib/lib/FAST/Struct/Seq.pm    98.1   83.3   77.8  100.0    0.0    7.9   84.7
    .../lib/FAST/Struct/While.pm  100.0   50.0  100.0  100.0    0.0    0.0   84.9
    Total                          98.5   90.4   86.7  100.0    0.0  100.0   90.6
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang

This library is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.

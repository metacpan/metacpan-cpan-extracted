# ABSTRACT: Tidy YAML files
use strict;
use warnings;
use v5.20;
use experimental qw/ signatures /;
package YAML::Tidy;

our $VERSION = '0.003'; # VERSION

use YAML::Tidy::Node;
use YAML::Tidy::Config;
use YAML::LibYAML::API::XS;
use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE
    YAML_DOUBLE_QUOTED_SCALAR_STYLE YAML_LITERAL_SCALAR_STYLE
    YAML_FOLDED_SCALAR_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE
/;
use YAML::PP::Parser;
use YAML::PP::Highlight;
use Data::Dumper;

use constant DEBUG => $ENV{YAML_TIDY_DEBUG} ? 1 : 0;

sub new($class, %args) {
    my $cfg = delete $args{cfg} || YAML::Tidy::Config->new();
    my $self = bless {
        partial => delete $args{partial},
        cfg => $cfg,
    }, $class;
    return $self;
}

sub cfg($self) { $self->{cfg} }

sub tidy($self, $yaml) {
    local $Data::Dumper::Sortkeys = 1;
    my @lines = split /\n/, $yaml, -1;
    my $tree = $self->_tree($yaml, \@lines);
    $self->{lines} = \@lines;
    $self->_process(undef, $tree);
    $yaml = join "\n", @{ $self->{lines} };
    return $yaml;
}

sub _process($self, $parent, $node) {
    my $type = $node->{type} || '';
    if ($node->{flow}) {
        $self->_process_flow($parent, $node);
        return;
    }
    my $level = $node->{level};
    my $indent = $self->cfg->indent;
    my $lines = $self->{lines};
    return unless @$lines;
    my $indenttoplevelscalar = 1;
    my $trimtrailing = $self->cfg->trimtrailing;

    my $col = $node->indent;
    my $lastcol = $parent ? $parent->indent : -99;
    my $realindent = $col - $lastcol;
    my $startline = $node->line;
    my $line = $lines->[ $startline ];
    unless (defined $line) {
        die "Line $startline not found";
    }
    my $before = substr($line, 0, $col);

    my $start = $node->start;
    if ($trimtrailing) {
        my $pre = $parent ? $parent->pre($node) : undef;
        if ($pre) {
            if ($pre->{line} <= $start->{line}) {
                my ($from, $to) = ($pre->{line}, $start->{line});
                $self->_trim($from, $to);
            }
        }
        if ($level < 1 and $type ne '') {
            # trim trailing spaces at the end of the node
            my $last = $node->{children}->[-1];
            my $from;
            if ($last) {
                my $end = $last->closestart;
                $from = $end->{line} + 1;
            }
            else {
                # empty node
                $from = $node->open->{end}->{line};
            }

            my $end2 = $node->closestart;
            my $to = $end2->{line};
            if ($from <= $to) {
                $self->_trim($from, $to);
            }
        }
    }

    if ($node->is_collection) {
        my $ignore_firstlevel = ($self->{partial} and $level == 0);
        if ($level < 0 or $ignore_firstlevel) {
            for my $c (@{ $node->{children} }) {
                $self->_process($node, $c);
            }
            return;
        }

        if ($level == 0) {
            $indent = 0;
        }
        if ($type eq 'MAP') {
            if ($before =~ tr/ //c) {
                if ($indent == 1) {
                    $indent = 2;
                }
            }
        }
        elsif ($type eq 'SEQ') {
            if ($before =~ tr/ //c) {
                if ($indent == 1) {
                    $indent = 2;
                }
            }
            else {
                if ($parent->{type} eq 'MAP' and not $node->{index} % 2) {
                    # zero indented sequence
                    if ($indent == 1) {
                        $indent = 2;
                    }
                    $indent -= 2;
                }
            }

        }
        my $diff = $indent - $realindent;
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$diff], ['diff']);
        if ($diff) {
            $self->_fix_indent($node, $diff, $col);
            $node->fix_node_indent($diff);
        }
        for my $c (@{ $node->{children} }) {
            $self->_process($node, $c);
        }
        return;
    }
    else {
        my $ignore_firstlevel = ($self->{partial} and $level == 0);
        my $multiline = $node->multiline;
        if ($parent->{type} eq 'MAP' and ($node->{index} % 2 and not $multiline)) {
            return;
        }
        if ($node->empty_scalar) {
            return;
        }
        if ($node->{name} eq 'alias_event') {
            return;
        }
        my $new_indent = $parent->indent + $indent;
        my $new_spaces = ' ' x $new_indent;

        my ($anchor, $tag, $comments, $scalar) = $self->_find_scalar_start($node);
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$lines], ['lines']);
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$scalar], ['scalar']);
        my $explicit_indent = 0;
        if ($scalar->[2] =~ m/[>|]/) {
            my $l = $lines->[ $scalar->[0] ];
            my ($ind) = substr($l, $scalar->[1]) =~ m/^[|>][+-]?([0-9]*)/;
            $explicit_indent = $ind;
        }
        my $skipfirst = 0;
        my $before = substr($line, 0, $col);
        if ($before =~ tr/ \t//c) {
            # same line as key
            $before =~ s/[\t ]+$/ /;
            $line = $before . substr($line, $col);
            $lines->[ $startline ] = $line;
            $skipfirst = 1;
        }
        my $realstart = $scalar->[0];
        if ($trimtrailing) {
            $self->_trim($startline, $realstart);
        }
        unless ($ignore_firstlevel) {
        for my $i ($startline .. $realstart) {
            my $line = $lines->[ $i ];
            if ($i == $startline and $col > 0) {
                my $before = substr($line, 0, $col);
                if ($before =~ tr/ //c) {
                    next;
                }
            }
            unless ($line =~ tr/ //c) {
                next;
            }
            $line =~ s/^ */$new_spaces/;
            $lines->[ $i] = $line;
        }
        }
        # leave alone explicitly indented block scalars
        return if $explicit_indent;

        $startline = $realstart;
        my $endline = $node->realendline;

        my $line = $lines->[ $startline ];
        my $realcol = $scalar->[1];
        $col = $realcol;

        my $nextline = $node->{nextline};

        my $block = ($node->{style} eq YAML_LITERAL_SCALAR_STYLE
            or $node->{style} eq YAML_FOLDED_SCALAR_STYLE);
        if ($block) {

            $startline++;
            while ($startline < $endline and $lines->[ $startline ] !~ tr/ //c) {
                if ($trimtrailing) {
                    $self->_trim($startline, $startline);
                }
                $startline++;
            }
            if ($nextline > $endline + 1) {
                $endline = $nextline - 1;
            }
            my @slice = @$lines[$startline .. $endline ];
            my ($sp) = $lines->[ $startline ] =~ m/^( *)/;
            if (not $ignore_firstlevel and length($sp) != $new_indent) {
                for my $line (@slice) {
                    unless (length $line) {
                        next;
                    }
                    if ($line !~ tr/ //c and length($line) <= length($sp)) {
                        if ($trimtrailing) {
                            $line = '';
                        }
                        next;
                    }
                    if ($line =~ m/^( *)\#/) {
                        my $cindent = length $1;
                        my $diff = $new_indent - length $sp;
                        $cindent += $diff;
                        if ($diff > 0) {
                            $line = (' ' x $diff) . $line;
                        }
                        elsif ($diff < 0) {
                            if ($cindent < 0) {
                                $cindent = 0;
                            }
                            $new_spaces = ' ' x $cindent;
                            $line =~ s/^ */$new_spaces/;
                        }
                    }
                    else {
                        $line =~ s/^$sp/$new_spaces/;
                    }
                }
                @$lines[$startline .. $endline ] = @slice;
            }
            elsif ($trimtrailing) {
                for my $line (@slice) {
                    if ($line !~ tr/ //c and length($line) <= length($sp)) {
                        $line = '';
                    }
                }
                @$lines[$startline .. $endline ] = @slice;
            }
        }
        elsif ($node->{style} == YAML_PLAIN_SCALAR_STYLE or
                $node->{style} == YAML_SINGLE_QUOTED_SCALAR_STYLE or
                $node->{style} == YAML_DOUBLE_QUOTED_SCALAR_STYLE) {
            $startline++ if $skipfirst;
            $endline = $node->close->{line};
            return if $startline >= @$lines;
            if ($trimtrailing) {
                $self->_trim($startline, $endline);
            }
            my $line = $lines->[ $startline ];
            my ($sp) = $line =~ m/^( *)/;
            if ($ignore_firstlevel) {
                $new_indent = length $sp;
                $new_spaces = ' ' x $new_indent;
            }
            my @slice = @$lines[$startline .. $endline ];
            if ($level == 0 and not $indenttoplevelscalar) {
                $new_spaces = ' ' x ($new_indent - $indent);
            }
            for my $line (@slice) {
                if ($line =~ tr/ //c) {
                    $line =~ s/^[\t ]*/$new_spaces/;
                }
            }
            @$lines[$startline .. $endline ] = @slice;
        }
    }
}

sub _process_flow($self, $parent, $node, $block_indent = undef) {
    return unless $parent;
    my $level = $node->{level};
    my $flow = $node->{flow} || 0;
    $block_indent //= $parent->indent + $self->cfg->indent;
    $block_indent = 0 if $level == 0;

    unless ($node->is_collection) {
        $self->_process_flow_scalar($parent, $node, $block_indent);
        return;
    }
    if ($parent->{type} eq 'MAP' and $node->{index} % 2) {
        return;
    }
    my $lines = $self->{lines};
    my $startline = $node->start->{line};
    my $end = $node->end;
    my $endline = $end->{line};
    if ($flow == 1 and $self->cfg->trimtrailing) {
        $self->_trim($startline, $endline);
    }

    my $before = substr($lines->[ $startline ], 0, $node->start->{column});
    if ($before =~ tr/ \t//c) {
        $startline++;
    }
    my @lines = ($startline .. $node->open->{end}->{line});
    my $before_end = substr($lines->[ $endline ], 0, $end->{column} - 1);
    unless ($before_end =~ tr/ \t//c) {
        push @lines, $endline;
    }
    for my $i (@lines) {
        my $new_spaces = ' ' x $block_indent;
        $lines->[ $i ] =~ s/^([ \t]*)/$new_spaces/;
        my $old = length $1;
        $node->_fix_flow_indent(line => $i, diff => $block_indent - $old);
    }

    for my $c (@{ $node->{children} }) {
        $self->_process_flow($node, $c, $block_indent + $self->cfg->indent);
    }
}

sub _process_flow_scalar($self, $parent, $node, $block_indent) {
    if ($node->empty_scalar) {
        return;
    }
    my $startline = $node->line;
    my $lines = $self->{lines};
    my $line = $lines->[ $startline ];
    my $col = $node->start->{column};
    my $before = substr($line, 0, $col);
    if ($before =~ tr/ \t//c) {
        $startline++;
    }
    my $endline = $node->end->{line};
    for my $i ($startline .. $endline) {
        my $line = $lines->[ $i ];
        my $new_spaces = ' ' x $block_indent;
        $line =~ s/^([ \t]*)/$new_spaces/;
        my $old = length $1;
        $node->_fix_flow_indent(line => $i, diff => $block_indent - $old);
        $lines->[ $i ] = $line;
    }
}

sub _find_scalar_start($self, $node) {
    my $lines = $self->{lines};
    my $from = $node->line;
    my $to = $node->realendline;
    my $col = $node->indent;
    my $end = $node->end;
    my $endcol = $end->{column};
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$endcol], ['endcol']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$col], ['col']);
    my @slice = @$lines[ $from .. $to ];
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@slice], ['slice']);
    my $anchor;
    my $tag;
    my @comments;
    my $start;
    my $scalar;
    for my $i (0 .. $#slice) {
        my $line = $slice[ $i ];
        my $f = $i == 0 ? $col : 0;
        my $t = $i == $#slice ? ($endcol || length($line)) : length($line);
        my $part = substr($line, $f, $t - $f);
        if ($part =~ m/^ *(\#.*)$/g) {
            my $comment = $1;
            my $pos1 = length($line) - length($comment);
            push @comments, [$i + $from, $pos1, $comment];
            next;
        }
        my $cur;
        while ($part =~ m/\G\s*([&!])(\S+)/g) {
            my $type = $1;
            my $name = $2;
            $cur = pos $part;
            my $pos = $cur - 1;
            my $pos1 = $pos - length $name;
            my $prop = substr($part, $pos1, 1+ length $name);
            if ($type eq '&') {
                $anchor = [$i + $from, $pos1 + $f, $prop];
            }
            elsif ($type eq '!') {
                $tag = [$i + $from, $pos1 + $f, $prop];
            }
        }
        pos($part) = $cur;
        if ($part =~ m/\G *(\#.*)$/g) {
            my $comment = $1;
            $cur = pos $part;
            my $pos1 = length($line) - length($comment);
            push @comments, [$i + $from, $pos1, $comment];
            next;
        }
        pos($part) = $cur;
        if ($part =~ m/\G *(\S)/g) {
            $scalar = $1;
            my $pos1 = (pos $part) - 1;
            $scalar = [$i + $from, $pos1 + $f, $scalar];
            last;
        }
    }
    $scalar ||= [$to, length($slice[ -1 ]), ''];
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$anchor], ['anchor']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$tag], ['tag']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@comments], ['comments']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$scalar], ['scalar']);
    return ($anchor, $tag, \@comments, $scalar);
}

sub _trim($self, $from, $to) {
    my $lines = $self->{lines};
    for my $line (@$lines[ $from .. $to ]) {
        $line =~ s/[\t ]+$//;
    }
}

sub _fix_indent($self, $node, $fix, $offset) {
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$fix], ['fix']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$offset], ['offset']);
    $offset ||= 0;
    my $startline = $node->line;
    my $lines = $self->{lines};
    my $endline = $node->realendline;
    my @slice = @$lines[$startline .. $endline];
    for my $line (@slice) {
        next unless length $line;
        if ($fix < 0) {
            my $offset = $offset;
            my $fix = -$fix;
            if ($offset > length $line) {
                $offset = -1 + length $line;
            }
            if ($line =~ tr/ //c) {
                if ($line =~ m/^ *\#/) {
                    $line =~ s/ {1,$fix}//;
                    next;
                }
            }
            else {
                $line =~ s/ {1,$fix}//;
                next;
            }
            my $before = substr($line, 0, $offset);
            $before =~ s/ {$fix,$fix}$//;
            $line = $before . substr($line, $offset);
        }
        else {
            unless ($line =~ tr/ //c) {
                next;
            }
            substr($line, $offset, 0, ' ' x $fix);
        }
    }
    @$lines[$startline .. $endline] = @slice;
}

sub _tree($self, $yaml, $lines) {
    my $events = $self->_parse($yaml);
    $self->{events} = $events;
    my $first = shift @$events;
    my $end = pop @$events;
    $_->{level} = -1 for ($first, $end);
    $first->{id} = -1;
    _pp($first) if DEBUG;
    my @stack;

    my $level = -1;
    my $docs = YAML::Tidy::Node::Collection->new(
        type => 'STR',
        children => [],
        indent => -1,
        line => 0,
        level => $level,
        start => YAML::Tidy::Node::Collection->new(%$first),
        end => YAML::Tidy::Node::Collection->new(%$end),
    );
    my $ref = $docs;
    my $id = 0;
    my $flow = 0;
    for my $i (0 .. $#$events) {
        my $event = $events->[ $i ];
        my $name = $event->{name};
        $id++;

        my $type;
        if ($name =~ m/document_start/) {
            $type = 'DOC';
        }
        elsif ($name =~ m/sequence_start/) {
            $type = 'SEQ';
        }
        elsif ($name =~ m/mapping_start/) {
            $type = 'MAP';
        }

        $event->{id} = $id;
        if ($name =~ m/_start_event/) {
            $event->{level} = $level;
            if ($name eq 'sequence_start_event') {
                # inconsistency in libyaml events?
                my $col = $event->{end}->{column};
                if ($col > 0) {
                    my $line = $lines->[ $event->{end}->{line} ];
                    my $chr = substr($line, $col - 1, 1);
                    if ($chr eq '-') {
                        $event->{end}->{column}--;
                    }
                }
            }
            if ($flow or ($event->{style} // -1) == YAML_FLOW_SEQUENCE_STYLE
                or ($event->{style} // -1) == YAML_FLOW_MAPPING_STYLE) {
                $flow++;
            }
            my $node = YAML::Tidy::Node::Collection->new(
                children => [],
                type => $type,
                level => $level,
                start => $event,
                flow => $flow,
            );
            push @{ $ref->{children} }, $node;
            $ref->{elements}++;
            $node->{index} = $ref->{elements};
            push @stack, $ref;
            $ref = $node;
            $level++;
        }
        elsif ($name =~ m/_end_event/) {
            my $last = pop @stack;

            $ref->{end} = $event;

            $ref = $last;

            $level--;
            $event->{level} = $level;
            $flow-- if $flow;
        }
        else {
            $event = YAML::Tidy::Node::Scalar->new(%$event);
            $ref->{elements}++;
            $event->{index} = $ref->{elements};
            $event->{level} = $level;
            push @{ $ref->{children} }, $event;
        }
        $event->{nextline} = -1;
        if ($i < $#$events) {
            my $next = $events->[ $i + 1 ];
            my $nextline = $next->{start}->{line};
            $event->{nextline} = $nextline;
        }
        _pp($event) if DEBUG;
    }
    $end->{id} = $id + 1;
    _pp($end) if DEBUG;
    $self->{tree} = $docs;
    return $docs;
}

sub _parse($self, $yaml) {
    my @events;
    YAML::LibYAML::API::XS::parse_string_events($yaml, \@events);
    return \@events;
}

sub _pp($event) {
    my $name = $event->{name};
    my $level = $event->{level};
    $name =~ s/_event$//;
    my $fmt = '%2d %-10s) <L %2d C %2d> <L %2d C %2d> %-14s';
    my $indent = $level*2+2;
    my $lstr = (' ' x $indent) . $level;
    my @args = (
        $event->{id}, $lstr,
        $event->{start}->{line}, $event->{start}->{column},
        $event->{end}->{line}, $event->{end}->{column},
        $name,
    );
    if ($name =~ m/scalar|alias/) {
        local $Data::Dumper::Useqq = 1;
        my $str = Data::Dumper->Dump([$event->{value}], ['value']);
        chomp $str;
        $str =~ s/^\$value = //;
        $fmt .= " %s";
        push @args, $str;
    }
    elsif ($name =~ m/end/) {
    }
    else {
    }
    $fmt .= "\n";
    printf $fmt, @args;
}

sub highlight($self, $yaml, $type = 'ansi') {
    my ($error, $tokens) = YAML::PP::Parser->yaml_to_tokens(string => $yaml);
    if ($error) {
        $tokens = [];
        my @lines = split m/(?<=\n)/, $yaml;
        for my $line (@lines) {
            if ($line =~ s/( +\n)//) {
                push @$tokens, { value => $line, name => 'PLAIN' };
                push @$tokens, { value => $1, name => 'TRAILING_SPACE' };
                next;
            }
            push @$tokens, { value => $line, name => 'PLAIN' };
        }
    }
    if ($type eq 'html') {
        return YAML::PP::Highlight->htmlcolored($tokens);
    }
    return YAML::PP::Highlight->ansicolored($tokens);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::Tidy - Tidy YAML files

=head1 SYNOPSIS

    % cat in.yaml
    a: # a comment
        b:
         c: d
    % yamltidy in.yaml
    a: # a comment
      b:
        c: d

For documentation see L<https://github.com/perlpunk/yamltidy>

For examples see L<https://perlpunk.github.io/yamltidy>

=head1 DESCRIPTION

yamltidy can automatically tidy formatting in your YAML files, for example
adjust indentation and remove trailing spaces.

For more information, see L<https://github.com/perlpunk/yamltidy>.

=head1 METHODS

=over

=item C<new>

    my $yt = YAML::Tidy->new;

=item C<tidy>

    my $outyaml = $yt->tidy($inyaml);

=item C<highlight>

    my $ansicolored = $yt->highlight($yaml, 'ansi');
    my $html = $yt->highlight($yaml, 'html');

=item C<cfg>

    my $cfg = $yt->cfg;

Return L<YAML::Tidy::Config>

=back

=head1 AUTHOR

Tina Müller E<lt>tinita@cpan.orgE<gt>

=head1 SEE ALSO

=over

=item yamllint L<https://yamllint.readthedocs.io/en/stable/>

=item perltidy L<Perl::Tidy>

=item L<YAML::LibYAML::API>

=item L<https://github.com/yaml/libyaml>

=item L<https://www.yaml.info/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut

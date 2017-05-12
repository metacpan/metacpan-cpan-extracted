use strict; use warnings;
package WikiText::Parser;

sub new {
    my $class = shift;
    return bless { @_ }, ref($class) || $class;
}

sub parse {
    my $self = shift;
    $self->{input} ||= shift;
    $self->{input} .= "\n"
        if substr($self->{input}, -1) ne "\n";
    $self->{grammar} ||= $self->set_grammar;
    $self->{receiver} ||= $self->set_receiver;
    $self->{receiver}->init;
    $self->parse_blocks('top');
    return $self->{receiver}->content;
}

sub set_receiver {
    my $self = shift;
    $self->{receiver} = shift || $self->create_receiver;
}

sub set_grammar {
    my $self = shift;
    $self->{grammar} = shift || $self->create_grammar;
}

sub parse_blocks {
    my $self = shift;
    my $container_type = shift;
    my $types = $self->{grammar}{$container_type}{blocks};
    while (my $length = length $self->{input}) {
        for my $type (@$types) {
            my $matched = $self->find_match(matched_block => $type) or next;
            substr($self->{input}, 0, $matched->{end}, '');
            $self->handle_match($type, $matched);
            last;
        }
        die $self->reduction_error
            unless length($self->{input}) < $length;
    }
    return;
}

sub parse_phrases {
    my $self = shift;
    my $container_type = shift;
    my $types = $self->{grammar}{$container_type}{phrases};
    while (defined $self->{input} and length $self->{input}) {
        my $match;
        for my $type (@$types) {
            my $matched = $self->find_match(matched_phrase => $type) or next;
            if (not defined $match or $matched->{begin} < $match->{begin}) {
                $match = $matched;
                $match->{type} = $type;
                last if $match->{begin} == 0;
            }
        }
        if (! $match) {
            $self->{receiver}->text_node($self->{input});
            last;
        }
        my ($begin, $end, $type) = @{$match}{qw(begin end type)};
        $self->{receiver}->text_node(substr($self->{input}, 0, $begin))
          unless $begin == 0;
        substr($self->{input}, 0, $end, '');
        $type = $match->{type};
        $self->handle_match($type, $match);
    }
    return;
}

sub find_match {
    my ($self, $matched_func, $type) = @_;
    my $matched;
    if (my $regexp = $self->{grammar}{$type}{match}) {
        if (ref($regexp) eq 'ARRAY') {
            for my $re (@$regexp) {
                if ($self->{input} =~ $re) {
                    $matched = $self->$matched_func;
                    last;
                }
            }
            return unless $matched;
        }
        else {
            return unless $self->{input} =~ $regexp;
            $matched = $self->$matched_func;
        }
    }
    else {
        my $func = "match_$type";
        $matched = $self->$func or return;
    }
    return $matched;
}

sub handle_match {
    my ($self, $type, $match) = @_;
    my $func = "handle_$type";
    if ($self->can($func)) {
        $self->$func($match, $type);
    }
    else {
        my $grammar = $self->{grammar}{$type};
        my $parse = $grammar->{blocks}
        ? 'parse_blocks'
        : 'parse_phrases';
        my @filter = $grammar->{filter}
        ? ($grammar->{filter})
        : ();
        $self->subparse($parse, $match, $type, @filter);
    }
}

sub subparse {
    my ($self, $func, $match, $type, $filter) = @_;
    $match->{type} = 
        exists $self->{grammar}{$type}{type} 
        ? $self->{grammar}{$type}{type}
        : $type;

    my $parser = $self->new(
        grammar => $self->{grammar},
        receiver => $self->{receiver}->new,
        input => $filter
        ? do { $_ = $match->{text}; &$filter($match); $_ }
        : $match->{text},
    );
    $self->{receiver}->begin_node($match)
      if $match->{type};
    $parser->$func($type);
    $self->{receiver}->insert($parser->{receiver});
    $self->{receiver}->end_node($match)
      if $match->{type};
}

sub reduction_error {
    my $self = shift;
    my $input = $self->{input};
    $input =~ s/^((.*\n){2}).*/$1/;
    chomp $input;
    return ref($self) . qq[ reduction error for:\n"$input"];
}

sub matched_block {
    my $begin = defined $_[2] ? $_[2] : $-[0];
    die "All blocks must match at position 0"
      if "$begin" ne "0";

    return +{
        text => ($_[1] || $1),
        end => ($_[3] || $+[0]),
        1 => $1,
        2 => $2,
        3 => $3,
    };
}

sub matched_phrase {
    return +{
        text => ($_[1] || $1),
        begin => (defined $_[2] ? $_[2] : $-[0]),
        end => ($_[3] || $+[0]),
        1 => $1,
        2 => $2,
        3 => $3,
    };
}

1;

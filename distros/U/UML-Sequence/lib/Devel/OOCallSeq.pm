package Devel::OOCallSeq;

=head1 NAME

OOCallSeq - produces call sequence outlines (like dprofpp -T)

=head1 SYNOPSIS

    perl -d:OOCallSeq script
    cat tmon.out

=head1 DESCRIPTION

This profiler is designed to aid in the production of UML sequence diagrams.
It is used by UML::Sequence through genericseq.pl and UML::Sequence::PerlOOSeq.
(See UML::Sequence::PerlOOSeq for how to use it in practice.)

The key differences between the output of this program and dprofpp -T are
these:

    subroutine names show up correctly (DiePair::new not DiePair::BEGIN)
    subroutine names are preceded by instance names (die1:Die::roll)

Output goes to tmon.out and looks like this:

main
  diePair1:DiePair::new
    die1:Die::new
    die2:Die::new
  diePair1:DiePair::roll
    die1:Die::roll
    die2:Die::roll
  diePair1:DiePair::total
  diePair1:DiePair::doubles

=cut

package DB;

# %next_object_number is keyed by package name storing number of objects seen
#                     in it so far (to use it preincrement it)
our %next_object_number;
# %objects is keyed by object reference (like HASH(0x1a6f26c)) storing the
#          number of the object in its class
our %objects;
our $stack_depth = 0;

our $previous_frame;
our $depth;
our @output;

BEGIN {
    $single = 0;
    open TMON, ">tmon.out" or die "Couldn't open tmon.out\n";
}
END {
    local $" = "";
    print TMON "@output";
    close TMON;
}

sub sub {
    local $stack_depth = $stack_depth + 1;
    my $i = 0;
    if (wantarray) {  # list context
        @ret = &$DB::sub;
    }
    elsif (defined wantarray) {  # scalar context
        $ret = &$DB::sub;
        if (defined $ret and "$ret" =~ /([^=]*)=(.*)/) {
            my ($type, $key) = ($1, $2);
            # put it in the hash
            unless (defined $objects{$key}) {
                $objects{$key} = ++$next_object_number{$type};
            }
            # to find the constructor, walk back through the output until we
            # see the most recent call at the current stack level
            for (my $i = scalar @output - 1; $i >= 0; $i--) {
                $output[$i] =~ /(\s+)(.*)/;
                my ($indent, $rest) = ($1, $2);
                if ( length($indent)/2 == $stack_depth) {
                    # indents have two spaces, that's why length is over 2
                    my $instance_name = "\l$type$objects{$key}";
                    $output[$i] = "$indent$instance_name:$rest\n";
                    last;
                }
            }
        }
        $ret;
    }
    else {  # void context
        &$DB::sub;
    }
}

sub DB {
    my ($pack) = caller(0);
    return if ($pack =~ /Dumper/);
    my $frame = DB->new();

    unless ($frame->compare($previous_frame)) {
        my $old_depth = $previous_frame->depth() if ref $previous_frame;
        my $new_depth = $frame         ->depth();

        if (not defined $old_depth or $new_depth > $old_depth) {
            my $output = "  " x ($new_depth - 1);
            if (defined $frame->element(1)) {  # if someone called, say so
                my $arg = $frame->arg(1);
                if ($arg) {
                    $arg =~ /([^=]*)=(.*)/;
                    my ($type, $key) = ($1, $2);
                    if (defined $key and defined $objects{$key}) {
                        $output .= "\l$type$objects{$key}:";
                    }
                }
                $output .= $frame->subname(1); # . " " . $frame->arg(1);
            }
            else {  # first call only, it has no parent
                $output .= $frame->package(0);
            }
            $output .= "\n";
            push @output, $output;
        }
    }

    $previous_frame = $frame;
}

# I can't use the following package statement, caller doesn't set DB::args
# unless it's called from the DB package.
# package StackFrame;

sub new {
    my $class = shift;
    my $i     = 1;
    my $frame = [];

    while (my ($package, $file, $line, $subname) = caller($i++)) {
        my $arg = $DB::args[-1];
        push @$frame, { pack    => $package,
                        file    => $file,
                        subname => $subname,
                        arg     => $arg,
                      };
    }
    return bless $frame, $class;
}

sub compare {
    my $self  = shift;
    my $other = shift;

    return 0 unless (ref $self and ref $other);
    return 0 if (@$self != @$other);
    foreach my $element (1 .. @$self) {
        my $self_element  = $self ->[$element];
        my $other_element = $other->[$element];
        no warnings;
        return 0 if ($self_element->{pack}    ne $other_element->{pack});
        return 0 if ($self_element->{file}    ne $other_element->{file});
        return 0 if ($self_element->{subname} ne $other_element->{subname});
    }
    return 1;
}

sub depth {
    my $self = shift;

    return 0 unless ref $self;
    return @$self;
}

sub element {
    my $self = shift;
    my $number = shift;

    return undef unless ref $self;
    if (defined $self->[$number]) {
        return $self->[$number];
    }
    else {
        return undef;
    }
}

sub package {
    my $self    = shift;
    my $element = shift;
    return undef unless ref $self;

    return $self->[$element]{pack};
}

sub subname {
    my $self    = shift;
    my $element = shift;
    return undef unless ref $self;

    return $self->[$element]{subname};
}

sub arg {
    my $self    = shift;
    my $element = shift;
    return undef unless ref $self;

    return $self->[$element]{arg};
}

1;

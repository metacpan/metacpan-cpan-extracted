package Devel::CallSequence;

=head1 NAME

CallSeq - produces call sequence outlines (like dprofpp -T)

=head1 SYNOPSIS

    perl -d:CallSeq script
    cat tmon.out

=head1 DESCRIPTION

This profiler is designed to aid UML::Sequence in producing diagrams.
See UML::Sequence::PerlSeq for instructions in its use.

The key difference between the output of this program and dprofpp -T is:

    subroutine names show up correctly (DiePair::new not DiePair::BEGIN)

The output goes to tmon.out and looks like this:

main
  DiePair::new
    Die::new
    Die::new
  DiePair::roll
    Die::roll
    Die::roll
  DiePair::total
  DiePair::doubles

=cut

package DB;

use strict;

BEGIN {
    open TMON, ">tmon.out" or die "Couldn't open tmon.out\n";
}
END {
    close TMON;
}

my $previous_frame;
my $depth;

sub DB {
    my ($pack) = caller(0);
    return if ($pack =~ /Dumper/);
    my $frame = DB->new();

    unless ($frame->compare($previous_frame)) {
        my $old_depth = $previous_frame->depth() if ref $previous_frame;
        my $new_depth = $frame         ->depth();

        if (not defined $old_depth or $new_depth > $old_depth) {
            print TMON "  " x ($new_depth - 1);
            if (defined $frame->element(1)) {
                print TMON $frame->subname(1);
            }
            else {
                print TMON $frame->package(0);
            }
            print TMON "\n";
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
        my $arg = $DB::args[0];
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

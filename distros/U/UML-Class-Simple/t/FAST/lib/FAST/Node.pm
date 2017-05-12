#: FAST/Node.pm
#: Non-structured FAST node
#: Copyright (c) 2006 Agent Zhang
#: 2006-03-08 2006-03-23

package FAST::Node;

use strict;
use warnings;
use base 'FAST::Element';

our $VERSION = '0.01';

sub new {
    my ($proto, $label) = @_;
    $label = '' if not defined $label;
    my $self = $proto->SUPER::new;
    $self->{label} = $label;
    return $self;
}

sub label {
    return $_[0]->{label};
}

sub exit { return $_[0]; }

sub entry { return $_[0]; }

sub might_pass {
    my ($self, $label) = @_;
    return $label eq $self->label;
}

sub must_pass {
    my ($self, $label) = @_;
    return $label eq $self->label;
}

sub as_c {
    my ($self, $level) = @_;
    $level ||= 0;
    my $indent = ' ' x (4 * $level);
    my $label = $self->label;
    return '' if $label eq '';
    if ($label =~ /^\[$FAST::NodeIdPat?(.*)\]$/) {
        return "${indent}do $1\n";
    } elsif ($label =~ /^\<$FAST::NodeIdPat?(.*)\>$/) {
        return $1;
    } else {
        return "${indent}$label\n";
    }
}

sub visualize {
    my ($self, $gv) = @_;
    FAST->plot_node($gv, $self->label, $self->id);
}

1;
__END__

=head1 NAME

FAST::Node - Non-structured FAST node class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang

This library is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.

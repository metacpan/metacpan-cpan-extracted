#: FAST/Element.pm
#: Common base class for all FAST DOM tree entities
#: Copyright (c) 2006 Agent Zhang
#: 2006-03-08 2006-04-03

package FAST::Element;

use strict;
use warnings;
use base 'Clone';
#use GraphViz;
use Carp 'confess';

sub new {
    my ($proto) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {
        id => undef,
    }, $class;
    $self->{id} = "$self";
    return $self;
}

#sub might_pass { confess "Not implemented"; }

#sub must_pass { confess "Not implemented"; }

sub id {
    return $_[0]->{id};
}

sub clone {
    my $self = shift;
    my $clone = $self->SUPER::clone;
    $clone->_update_id;
    return $clone;
}

sub _update_id {
    my $self = shift;
    $self->{id} = "$self";
}

#sub entry { confess "Not implemented"; }

#sub exit { confess "Not implemented"; }

#sub visualize { confess "Not implemented"; }

#sub as_c { confess "Not implemented"; }

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
    my $gv = GraphViz->new(
        layout => 'dot',
        edge => {color => 'red'},
        node => {
            fillcolor => '#f1e1f4',
            color => '#918194',
            style => 'filled',
        },
    );
    $self->visualize($gv);
    require 'FAST.pm';
    FAST->plot_node($gv, 'entry');
    FAST->plot_node($gv, 'exit');
    $gv->add_edge('entry' => $self->entry);
    $gv->add_edge($self->exit => 'exit');
    return $gv;
}

1;
__END__

=head1 NAME

FAST::Element - Common virtual class for FAST DOM tree structures

=head1 INHERITANCE

    FAST::Element
        isa Clone

=head1 DESCRIPTION

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang

This library is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.

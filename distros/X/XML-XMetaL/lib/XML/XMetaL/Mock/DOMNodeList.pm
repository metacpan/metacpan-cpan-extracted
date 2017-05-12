package XML::XMetaL::Mock::DOMNodeList;

use 5.008;
use strict;
use warnings;

use Carp;
use Hash::Util qw(lock_keys);

use constant TRUE  => 1;
use constant FALSE => 0;

sub new {
    my ($class, @items) = @_;
    my $self;
    eval {
        #lock_keys(%args,qw());
        $self = bless {
            length     => undef,
            _node_list => [],
        }, ref($class) || $class;
        lock_keys(%$self, keys %$self);
        $self->add(@items) if @items;
    };
    croak $@ if $@;
    return $self;
}

sub add {
    my ($self, @items) = @_;
    my $node_list = $self->{_node_list};
    #push @$node_list, grep {eval{$_->isa('XML::XMetaL::Mock::DOMNode')}} @items;
    my $last_node_in_list;
    foreach my $item (@items) {
        if (scalar(@$node_list)) {
            $last_node_in_list = $$node_list[-1];
            $self->_link_to_next($last_node_in_list, $item);
            #$self->_link_to_previous($last_node_in_list, $item);
        }
        push @$node_list, $item;
    }
    $self->{length} = scalar @$node_list;
}

sub _link_to_next {
    my ($self, $previous_node, $next_node) = @_;
    $previous_node->{nextSibling} = $next_node;
}

sub item {
    my ($self, $index) = @_;
    my $node_list = $self->{_node_list};
    return $$node_list[$index];
}

#cloneNode 

sub hasChildNodes {
    my $self = shift @_;
    my XML::XMetaL::Mock::DOMNodeList $child_node_list = $self->{_node_list};
    return scalar(@$child_node_list) ? TRUE : FALSE;
}

#insertBefore 
#removeChild 
#replaceChild 


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL::Mock::DOMNode - Mock XMetaL DOMNode class

=head1 SYNOPSIS

 use base qw(XML::XMetaL::Base);

=head1 DESCRIPTION


=head2 Class Methods

None.

=head2 Public Methods


=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

A lot, I am sure.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.


=head1 SEE ALSO

See L<XML::XMetaL>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

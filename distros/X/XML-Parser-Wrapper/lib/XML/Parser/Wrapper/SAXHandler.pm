# Creation date: 2008-12-02T09:05:03Z
# Authors: don
# $Revision: 1599 $

# Copyright (c) 2005-2009 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

XML::Parser::Wrapper::SAXHandler - SAX handler for XML::Parser::Wrapper

=head1 SYNOPSIS

Not meant be used externally.

=head1 DESCRIPTION

=cut

use strict;
use warnings;

package XML::Parser::Wrapper::SAXHandler;

our $VERSION = '0.01';

use base qw(XML::SAX::Base);

=pod

=head1 METHODS


=cut
sub new {
    my ($class, $params) = @_;
    $params = { } unless $params;

    my $self = bless { params => { %$params }, _cur_depth => 0 }, ref($class) || $class;
    
    unless ($params->{start_tag}) {
        $self->{data} = [ ];
        $self->{stack} = [$self->{data} ];
        $self->{extra_data} = { };
    }

    # print Data::Dumper->Dump([ $self ], [ 'self' ]) . "\n\n";
    
    return $self;
}

sub get_tree {
    my ($self) = @_;

    return $self->{data};
}

sub characters {
    my ($self, $chars) = @_;
    
    if ($self->{params}{start_tag}) {
        if ($self->{_in_tag} and $self->{_in_section}) {
            my $data = [ 0, $chars->{Data} ];
            my $stack = $self->{stack};
            my $cur_data = $stack->[$#$stack];
            
            if (ref($cur_data->[$#$cur_data])) {
                push @$cur_data, @$data;
            } elsif ($cur_data and @$cur_data) {
                $cur_data->[$#{$cur_data}] .= $chars->{Data};
            }
        }
    }
    else {
        my $data = [ 0, $chars->{Data} ];
        my $stack = $self->{stack};
        my $cur_data = $stack->[$#$stack];
        
        if (ref($cur_data->[$#$cur_data])) {
            push @$cur_data, @$data;
        } elsif ($cur_data and @$cur_data) {
            $cur_data->[$#{$cur_data}] .= $chars->{Data};
        }
    }
        
}

sub _do_section_chunk {
    my ($self, $e) = @_;

    my %attrs_data = %{$e->{Attributes}};
    my $name = $e->{Name};

    my %attrs = map { ($_->{Name} => XML::Parser::Wrapper::AttributeVal->new($_)) }
        values %attrs_data;

    my $data = [ $name, [ \%attrs ] ];
    my $stack = $self->{stack};
    my $cur_data = $stack->[$#$stack];
    push @$cur_data, @$data;
    push @$stack, $data->[1];            

    return 1;
}

sub _do_start_section {
    my ($self, $e) = @_;

    my %attrs = map { ($_->{Name} => XML::Parser::Wrapper::AttributeVal->new($_)) }
        values %{$e->{Attributes}};
    my $name = $e->{Name};

    $self->{data} = [ $name, [ \%attrs ] ];
    $self->{stack} = [ $self->{data}, $self->{data}[1] ];

    return 1;
}

sub start_element {
    my ($self, $e) = @_;
    my $name = $e->{Name};

    $self->{_in_tag} = 1;

    $self->{_cur_depth}++;

    my $start_tag = $self->{params}{start_tag};

    if ($start_tag) {
        if ($name eq $start_tag) {
            $self->{_start_tag_levels}++;
        }
        
        if ($name eq $start_tag
            and (not $self->{_start_depth} or $self->{_cur_depth} == $self->{_start_depth})) {

            unless ($self->{_start_depth}) {
                # how many of the same tag name deep to start
                my $user_depth = $self->{params}{start_depth};

                if ($user_depth) {
                    if ($self->{_start_tag_levels} == $user_depth) {
                        $self->{_in_section} = 1;
                        $self->{_start_depth} = $self->{_cur_depth};
                        return $self->_do_start_section($e);
                    }
                    else {
                        return $self->_do_section_chunk($e);
                    }
                }
                
                $self->{_start_depth} = $self->{_cur_depth};
            }

            $self->{_in_section} = 1;
            return $self->_do_start_section($e);
        } elsif ($self->{_in_section}) {
            return $self->_do_section_chunk($e);
        }
    }
    else {
        return $self->_do_section_chunk($e);
    }
}
    
sub end_element {
    my ($self, $e) = @_;
    my $name = $e->{Name};

    my $last_entry = pop @{$self->{stack}};
 
    $self->{_in_tag} = 0;

    my $start_tag = $self->{params}{start_tag};
    
    if ($start_tag and $name eq $start_tag
        and defined($self->{_start_depth}) and $self->{_cur_depth} == $self->{_start_depth}) {
        $self->{_in_section} = 0;

        my $listing = XML::Parser::Wrapper->new_from_tree([ @{$self->{data}} ]);

        my $handler = $self->{params}{handler};
        if ($handler) {
            if (ref($handler) eq 'ARRAY') {
                my ($obj, $method) = @$handler;
                $obj->$method($listing);
            } else {
                $handler->($listing);
            }
        }
    }

    $self->{_cur_depth}--;

    if ($start_tag eq $name) {
        $self->{_start_tag_levels}--;
    }
}

# sub doctype_decl {
#     my ($self, @args) = @_;

#      use Data::Dumper;

#     print STDERR Data::Dumper->Dump([ \@args ], [ 'doctype_args' ]) . "\n\n";

#     return $self->SUPER::doctype_decl(@args);
# }

sub xml_decl {
    my ($self, $data) = @_;

    $self->{extra_data}{xml_decl} = { version => $data->{Version}, encoding => $data->{Encoding},
                                      standalone => $data->{Standalone} };
    
#     use Data::Dumper;

#     print STDERR Data::Dumper->Dump([ $data ], [ 'xml_decl_arg' ]) . "\n\n";

    return $self->SUPER::xml_decl($data);
}

# sub notation_decl {
#     my ($self, $data) = @_;

#     use Data::Dumper;
#     print STDERR Data::Dumper->Dump([ $data ], [ 'notation_decl' ]) . "\n\n";

    
#     return $self->SUPER::notation_decl($data);
# }

# sub start_document {
#     my ($self, $data) = @_;

#    print STDERR Data::Dumper->Dump([ $data ], [ 'start_document' ]) . "\n\n";

    
#     return $self->SUPER::start_document($data);
# }

=pod

=head1 AUTHOR

Don Owens <don@regexguy.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Don Owens <don@owensnet.com>.  All rights reserved.

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See perlartistic.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

=cut

1;

# Local Variables: #
# mode: perl #
# tab-width: 4 #
# indent-tabs-mode: nil #
# cperl-indent-level: 4 #
# perl-indent-level: 4 #
# End: #
# vim:set ai si et sta ts=4 sw=4 sts=4:

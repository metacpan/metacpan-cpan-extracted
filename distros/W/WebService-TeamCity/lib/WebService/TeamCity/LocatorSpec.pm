package WebService::TeamCity::LocatorSpec;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.03';

use Type::Params qw( compile );
use Types::Standard qw( ArrayRef Bool Dict HashRef Int Optional Str slurpy );
use String::CamelSnakeKebab qw( lower_camel_case );
use WebService::TeamCity::Types qw( DateTimeObject );

use Moo;

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has type_spec => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

sub validator {
    my $self = shift;
    return compile( slurpy $self->as_dict(@_) );
}

my %PagingArgs = (
    count => Int,
    start => Int,
);

sub as_dict {
    my $self = shift;
    my %args = @_;

    my %spec
        = $args{include_paging_args}
        ? ( %{ $self->type_spec }, %PagingArgs )
        : %{ $self->type_spec };

    return Dict [
        map {
            $_ => Optional [
                  $spec{$_}->isa('WebService::TeamCity::LocatorSpec')
                ? $spec{$_}->as_dict
                : $spec{$_}
                ]
            }
            keys %spec
    ];
}

sub locator_string_for_args {
    my $self = shift;
    my %args = @_;

    return unless $args{search_args} && keys %{ $args{search_args} };

    my %spec
        = $args{include_paging_args}
        ? ( %{ $self->type_spec }, %PagingArgs )
        : %{ $self->type_spec };

    my @l;
    for my $key (
        sort { $a cmp $b }
        grep { exists $args{search_args}{$_} } keys %spec
        ) {

        my $type = $spec{$key};

        my $v;
        if ( $type->isa(__PACKAGE__) ) {
            $v
                = '('
                . $type->locator_string_for_args(
                search_args => $args{search_args}{$key} )
                . ')';
        }
        elsif ( $type->equals(Bool) ) {
            $v = $args{search_args}{$key} ? 'true' : 'false';
        }
        elsif ( $type->is_subtype_of(ArrayRef) ) {
            $v = '(' . ( join ',', @{ $args{search_args}{$key} } ) . ')';
        }
        elsif ( $type->equals(DateTimeObject) ) {
            $v = $args{search_args}{$key}->strftime('%Y%m%dT%H%M%S%z');
        }
        else {
            # Str, Int, etc.
            $v = $args{search_args}{$key};
        }

        push @l, join ':', lower_camel_case($key), $v;
    }

    return join ',', @l;
}

1;

# ABSTRACT: Class to represent locator specifications

__END__

=pod

=head1 NAME

WebService::TeamCity::LocatorSpec - Class to represent locator specifications

=head1 VERSION

version 0.03

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

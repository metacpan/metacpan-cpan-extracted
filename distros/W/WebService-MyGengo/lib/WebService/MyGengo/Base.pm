package WebService::MyGengo::Base;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::DateTime;# qw(DateTime Duration);
use Scalar::Util qw(blessed);
use namespace::autoclean;

use DateTime;

=head1 NAME

WebService::MyGengo::Base - Generic base class for all objects in the
WebService::MyGengo namespace

=head1 DESCRIPTION

Provides custom subtypes and coercions used by child classes.

=cut
#todo These are supposed to be global. So can I just define them
#in the classes in which they're used, instead?
subtype 'WebService::MyGengo::LanguageCode'
    , as 'Str'
    , where { my $len = length($_); ($len == 2 || $len ==  5) }
    , message { "Valid language codes are 2 or 5 characters: '$_'" }
    ;

# todo Not all values in this range are valid error codes
subtype 'WebService::MyGengo::ErrorCode'
    , as 'Num'
    , where { $_ == 0 || ($_ > 999 && $_ < 2801) }
    , message { "Invalid API error code: $_" }
    ;

subtype 'WebService::MyGengo::Tier'
    , as 'Str'
    , where {
        my $val = shift;
        grep { $val eq $_ } qw/machine standard pro ultra ultra_pro/;
        }
    , message { "Valid tiers are: machine, standard, pro, ultra, ultra_pro" }
    ;

# todo Do we still need this?
subtype 'WebService::MyGengo::CommentThread'
    , as 'ArrayRef[WebService::MyGengo::Comment]'
    ;

subtype 'WebService::MyGengo::DateTime'
    , as "DateTime";
coerce 'WebService::MyGengo::DateTime'
    , from 'Undef'
    , via { 'DateTime'->from_epoch( epoch => 0 ) }
    , from 'Num', via { 'DateTime'->from_epoch( epoch => $_ ) }
    , from 'Str'
    , via {
        my ( $datetime ) = ( @_ );
        $datetime =~ s!JST$!Asia/Tokyo!;
        $datetime =~ m!^
            (?:\s+)?(\d{4,4})[/-](\d{1,2})[/-](\d{1,2}) # Required date portion
            (?:[T\s](\d{1,2}):(\d{1,2}):(\d{1,2}))?     # Optional time portion
            (?:\s?([\w/\+:]+))?                         # Optional timezone
            $!x;
        my ($y, $m, $d, $H, $M, $S, $tz) = ($1, $2, $3, $4, $5, $6, $7);

        return unless $y && $m && $d;
    
        $tz ||= 'UTC'; # todo assume UTC OK?
 
        return eval {
            return DateTime->new(
                year      => $y,
                month     => $m,
                day       => $d,
                hour      => $H || 0,
                minute    => $M || 0,
                second    => $S || 0,
                time_zone => $tz,
            );
        };
        }
    ;

subtype 'WebService::MyGengo::DateTime::Duration'
    , as 'DateTime::Duration';
coerce 'WebService::MyGengo::DateTime::Duration'
    , from 'Undef', via { DateTime::Duration->new( seconds => 0 ) }
    , from 'Str', via { s/\D/0/g; DateTime::Duration->new( seconds => $_ ) }
    ;

subtype 'WebService::MyGengo::Num'
    , as 'Num';
coerce 'WebService::MyGengo::Num'
    , from 'Undef', via { 0.0 }
    ;

# todo Convenient, but do they belong here?
coerce 'WebService::MyGengo::Comment'
    , from 'Str'
    , via { return WebService::MyGengo::Comment->new( body => shift ) }
    ;
coerce 'WebService::MyGengo::CommentThread'
    , from 'ArrayRef[HashRef]'
    , via {
        my $obj = shift;
        my @a;
        push @a, WebService::MyGengo::Comment->new( $_ )
            foreach ( @$obj );
        return \@a;
        }
    ;

subtype 'WebService::MyGengo::body_tgt'
    , as 'Str';
coerce 'WebService::MyGengo::body_tgt'
    , from 'Undef' , via { '' } ;

subtype 'WebService::MyGengo::Job::Status'
    , as 'Str'
    , where {
        my $val = shift;
        grep { $val eq $_ } qw/unpaid available pending reviewable revising
                                approved rejected cancelled held/;
    }
    , message { "Valid statuses are: unpaid, available, pending, reviewable"
                . ", revising, approved, rejected, cancelled, held"
    }
    ;

subtype 'WebService::MyGengo::UnitType'
    , as 'Str'
    , where { m/word|character/ }
    , message { "Invalid translation unit: '$_'" }
    ;

subtype 'WebService::MyGengo::URI'
    , as 'URI';
coerce 'WebService::MyGengo::URI'
    , from 'Str'
    , via { URI->new(shift) }
    ;

=head1 ATTRIBUTES

=head2 attributes_to_serialize

A list of attribute names to be serialized by the `to_struct` method.

Override `_build_attributes_to_serialize` in subclasses.

=cut
#todo Use traits for serializable attributes.
has attributes_to_serialize => (
    is      => 'ro'
    , isa   => 'ArrayRef'
    , lazy  => 1
    , builder => '_build_attributes_to_serialize'
    );
sub _build_attributes_to_serialize {
    return [
        grep { $_ ne 'attributes_to_serialize' }
            map { $_->name }
                shift->meta->get_all_attributes
        ];
}

=head1 METHODS

=head2 to_hash( \@attributes? )

Returns a reference to a hash of object attributes and values.

By default, the attributes to serialize are obtained from the
`attributes_to_serialize` attribute of the object.

A custom set of attributes can be retrieved by supplying the optional
\@attributes argument

If you supply an empty arrayref for `\@attributes` then all public attributes of
the object will be supplied.

=cut
#todo Again: use traits for serializable attributes.
sub to_hash {
    my ( $self, $attrs ) = ( shift, @_ );

    if ( defined($attrs) && ! @$attrs ) {
        @$attrs = grep { $_ ne 'attributes_to_serialize' && $_ !~ /^_/ }
                  map { $_->name }
                  $self->meta->get_all_attributes;
    }

    $attrs ||= $self->attributes_to_serialize;

    # We can't use a hashslice because the API complains
    #   if we submit empty values.
    my %hash;
    my $val;
    foreach ( @$attrs ) {
        $val = $self->$_;
        defined($val) and $hash{$_} = ''.$val;
    }

    return \%hash;
}


__PACKAGE__->meta->make_immutable();
1;

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

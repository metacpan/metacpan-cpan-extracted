package cPanel::APIClient::Response::WHM1;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Response::WHM1

=head1 DESCRIPTION

This class represents a response to a WHM API v1 call.

=cut

#----------------------------------------------------------------------

use parent qw( cPanel::APIClient::Response );

#----------------------------------------------------------------------

=head1 METHODS

=head2 $scalar = I<OBJ>->get_error()

Returns an error message, or undef if the API call succeeded.
Note that this accommodates the case of a malformed API response
and will give appropriate generic error messages in those cases.

This method is how you should determine whether an API call succeeded.

=cut

sub get_error {
    my ($self) = @_;

    my $reason;

    if ( my $md = $self->{'metadata'} ) {
        if ( !$md->{'result'} ) {
            $reason = $md->{'reason'};
            $reason = 'No failure “reason” given in response' if !length $reason;
        }
    }
    else {
        $reason = 'Missing “metadata” in response';
    }

    return $reason;
}

#----------------------------------------------------------------------

=head2 $thing = I<OBJ>->get_data()

Returns the API payload.

This “reduces” the API
payload when the raw payload from the API is a single-member hash
whose only value is an array reference. So if the API’s raw C<data> is:

    { payload => [ 'foo', 'bar' ] }

… then the return from this accessor will be:

    [ 'foo', 'bar' ]

This “reduction” only happens for this particular pattern;
it doesn’t happen, for example, when the single-member hash’s value
is any other data type.

=cut

sub get_data {
    my ($self) = @_;

    my $data = $self->{'data'};

    # WHM v1 customarily stores array data in a single-key hash.
    # This serves no useful end, so it’s customary to reduce that
    # to just the array.
    #
    # Note that it may end up being unhelpful in cases like
    # the “domainuserdata” call, which nests its hash payload
    # inside a single-member hash. But it’s longstanding practice
    # (in CJT, anyway) to apply this reduction only when the
    # outer hash’s single member is an array.
    #
    if ( 'HASH' eq ref($data) && 1 == keys %$data ) {
        my $data2 = ( values %$data )[0];

        if ( 'ARRAY' eq ref $data2 ) {
            $data = $data2;
        }
    }

    return $data;
}

=head2 $data = I<OBJ>->get_raw_data()

Like C<get_data()> but gives the verbatim data structure.
Intended for use in proxying situations; application logic should
usually prefer C<get_data()>.

=cut

sub get_raw_data {
    my ($self) = @_;

    return $self->{'data'};
}

#----------------------------------------------------------------------

=head2 @results = I<OBJ>->parse_batch()

Interprets the API response as from the C<batch> API call and returns
a list of instances of this class that represents the elements of that
response.

=cut

sub parse_batch {
    my ($self) = @_;

    Cpanel::Context::must_be_list();

    my $class = ref $self;

    return map { $class->new($_) } @{ $self->get_data() };
}

#----------------------------------------------------------------------

=head2 $messages_ar = I<OBJ>->get_nonfatal_messages()

Returns a reference to an array of two-member arrays, thus:

    [
        [ info => 'Hey, by the way …' ],
        [ warn => 'Hey, this might cause a problem …' ],
    ]

The first value of each two-member array is either C<info> or C<warn>,
and the value is the actual message. Note that error messages are not
part of this structure; for that, use C<get_error()>.

This follows a pattern from CJT1 and CJT2.

=cut

my %type_xform = qw(
  warnings    warn
  messages    info
);

sub get_nonfatal_messages {
    my ($self) = @_;

    my @messages;

    my $metadata = $self->{'metadata'};

    if ( $metadata && ( my $output = $metadata->{'output'} ) ) {
        for my $type (qw( warnings messages )) {
            my $msgs = $output->{$type};

            next if !$msgs;

            if ( !ref $msgs ) {
                $msgs = [ split m<\n>, $msgs ];
            }

            if ( 'ARRAY' eq ref $msgs ) {
                push @messages, [ $type_xform{$type} => $_ ] for @$msgs;
            }
            else {
                warn "Unexpected type for metadata.output.$type: $msgs";
            }
        }
    }

    return \@messages;
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;

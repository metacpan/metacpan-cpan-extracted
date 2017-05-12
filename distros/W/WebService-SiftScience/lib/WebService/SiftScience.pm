package WebService::SiftScience;
$WebService::SiftScience::VERSION = '0.0100';
use Moo;
with 'WebService::Client';

# VERSION

use Method::Signatures;

has '+base_url' => ( default => 'http://api.siftscience.com/v203' );
has api_key     => ( is => 'ro', required => 1                    );
has events_uri  => ( is => 'ro', default => '/events'             );
has score_uri   => ( is => 'ro', default => '/score'              );
has users_uri   => ( is => 'ro', default => '/users'              );

method get_score (Str $user_id) {
    return $self->get($self->_score_uri($user_id) .
        '?api_key=' . $self->api_key);
}

method create_event (Str $user_id, Str $type, Maybe[HashRef] $data = {}) {
    return $self->post($self->events_uri, {
        '$type'      => $type,
        '$api_key'   => $self->api_key,
        '$user_id'   => $user_id,
        ( %$data ) x!! $data,
    });
}

method create_account (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$create_account', $data);
}

method update_account (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$update_account', $data);
}

method create_order (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$create_order', $data);
}

method transaction (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$transaction', $data);
}

method link_session_to_user (Str $user_id, $data) {
    return $self->create_event($user_id, '$link_session_to_user', $data);
}

method add_item_to_cart (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$add_item_to_cart', $data);
}

method remove_item_from_cart (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$remove_item_from_cart', $data);
}

method submit_review (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$submit_review', $data);
}

method send_message (Str $user_id, Maybe[HashRef] $data) {
    return $self->create_event($user_id, '$send_message', $data);
}

method login (Str $user_id, Maybe[HashRef] $data = {}) {
    return $self->create_event($user_id, '$login', $data);
}

method logout (Str $user_id) {
    return $self->create_event($user_id, '$logout');
}

method custom_event (Str $user_id, Str $type, Maybe[HashRef] $data) {
    return $self->create_event($user_id, $type, $data);
}

method label_user (Str $user_id, $data) {
    return $self->post($self->_label_uri($user_id), {
        '$api_key'  => $self->api_key,
        ( %$data ) x!! $data,
    });
}

method unlabel_user (Str $user_id) {
    return $self->delete($self->_label_uri($user_id) .
        '?api_key=' . $self->api_key);
}

method _score_uri (Str $user_id) {
    return $self->score_uri . "/$user_id";
}

method _label_uri (Str $user_id) {
    return $self->users_uri . "/$user_id/labels";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SiftScience

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

    use WebService::SiftScience;

    my $ss = WebService::SiftScience->new(
        api_key => 'YOUR_API_KEY_HERE',
    );

    $ss->create_account(...);

=head1 DESCRIPTION

This module provides bindings for the
L<SiftScience|https://www.siftscience.com/resources/references/> API.

=for markdown [![Build Status](https://travis-ci.org/aanari/WebService-SiftScience.svg?branch=master)](https://travis-ci.org/aanari/WebService-SiftScience)

=head1 METHODS

=head2 new

Instantiates a new WebService::SiftScience client object.

    my $ss = WebService::SiftScience->new(
        api_key    => $api_key,
        timeout    => $retries,    # optional
        retries    => $retries,    # optional
    );

B<Parameters>

=over 4

=item - C<api_key>

I<Required>E<10> E<8>

A valid SiftScience API key for your account.

=item - C<timeout>

I<Optional>E<10> E<8>

The number of seconds to wait per request until timing out.  Defaults to C<10>.

=item - C<retries>

I<Optional>E<10> E<8>

The number of times to retry requests in cases when SiftScience returns a 5xx response.  Defaults to C<0>.

=back

=head2 add_item_to_cart

Record when a user adds an item to their shopping cart or list.

B<Request:>

    add_item_to_cart('billy_jones_301', {
        '$session_id' => 'gigtleqddo84l8cm15qe4il',
        '$item'       => {
            '$item_id'       => 'B004834GQO',
            '$product_title' => 'The Slanket Blanket-Texas Tea',
            '$price'         => '39990000',
            '$currency_code' => 'USD',
            ...
        },
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 create_account

Capture account creation and user details.

B<Request:>

    create_account('billy_jones_301', {
        '$session_id'       => 'gigtleqddo84l8cm15qe4il',
        '$user_email'       => 'bill@gmail.com',
        '$name'             => 'Bill Jones',
        '$phone'            => '1-415-555-6040',
        '$referrer_user_id' => 'janejane101',
        ...
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 create_order

Record when a user submits an order for products or services they intend to purchase. This API event should contain the products/services ordered, the payment instrument proposed, and user identification data.

B<Request:>

    create_order('billy_jones_301', {
        '$session_id'    => 'gigtleqddo84l8cm15qe4il',
        '$order_id'      => 'ORDER-28168441',
        '$user_email'    => 'bill@gmail.com',
        '$amount'        => 506790000,
        '$currency_code' => 'USD',
        ...
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 custom_event

Event that you can come up with on your own, in order to capture user behavior not currently captured in Sift Science's supported set of events.

B<Request:>

    custom_event('billy_jones_301', 'make_call', {
        recipient_user_id => 'marylee819',
        call_duration     => 4428,
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 get_score

Retrieve a Sift Score for a particular user on your site, including a list of signals that describe the reasoning behind the score, and the latest label information if the user has been labeled.

B<Request:>

    get_score('billy_jones_301');

B<Response:>

    {
        user_id       => 'billy_jones_301',
        score         => 0.93,
        error_message => 'OK',
        status        => 0,
        reasons       => [
            name      => 'UsersPerDevice',
            value     => 4,
            details   => {
                users => 'a, b, c, d',
            },
        ],
        latest_label => {
            is_bad  => JSON::true,
            time    => 1350201660000,
            reasons => [
                '$chargeback',
                '$spam',
            ],
            description => 'known fraudster',
        },
    }

=head2 label_user

Label a user as bad (or not bad).

B<Request:>

    label_user('billy_jones_301', {
        '$is_bad'      => JSON::true,
        '$reasons'     => ['$chargeback'],
        '$description' => 'Freeform text describing the user or incident.',
        '$source'      => 'Payment Gateway',
        '$analyst'     => 'someone@your-site.com',
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 link_session_to_user

Associate data from a specific session to a user. Generally used only in anonymous checkout workflows.

B<Request:>

    link_session_to_user('billy_jones_301', {
        '$session_id'   => 'gigtleqddo84l8cm15qe4il',
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 login

Record when a user attempts to log in.

B<Request:>

    login('billy_jones_301', {
        '$session_id'   => 'gigtleqddo84l8cm15qe4il',
        '$login_status' => '$success',
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 logout

Record when a user logs out.

B<Request:>

    logout('billy_jones_301');

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 transaction

Record attempts to exchange money, credit or other tokens of value. This is most commonly used to record the results of interactions with a payment gateway, e.g., recording that a credit card authorization attempt failed.

B<Request:>

    transaction('billy_jones_301', {
        '$session_id'         => 'gigtleqddo84l8cm15qe4il',
        '$order_id'           => 'ORDER-28168441',
        '$user_email'         => 'bill@gmail.com',
        '$transaction_type'   => '$sale',
        '$transaction_status' => '$success',
        '$transaction_id'     => '719637215',
        '$amount'             => 506790000,
        '$currency_code'      => 'USD',
        ...
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 remove_item_from_cart

Record when a user removes an item from their shopping cart or list.

B<Request:>

    remove_item_from_cart('billy_jones_301', {
        '$session_id' => 'gigtleqddo84l8cm15qe4il',
        '$item'       => {
            '$item_id'       => 'B004834GQO',
            '$product_title' => 'The Slanket Blanket-Texas Tea',
            '$price'         => '39990000',
            '$currency_code' => 'USD',
            ...
        },
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 send_message

Record when a user sends a message to another user i.e., the recipient.

B<Request:>

    send_message('billy_jones_301', {
        '$recipient_user_id' => '512924123',
        '$subject'           => 'Subject line of the message.',
        '$content'           => 'Text content of the message.',
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 submit_review

Record a user-submitted review of a product or other users. e.g., a seller on your site.

B<Request:>

    submit_review('billy_jones_301', {
        '$content'           => 'Text content of submitted review goes here',
        '$review_title'      => 'Title of Review Goes Here',
        '$item_id'           => 'V4C3D5R2Z6',
        '$reviewed_user_id'  => 'billy_jones_301',
        '$submission_status' => '$success',
        'rating'             => 5,
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head2 unlabel_user

Remove a label from a user programatically.

B<Request:>

    unlabel_user('billy_jones_301');

B<Response:>

    204 No Content

=head2 update_account

Record changes to the user's account information.

B<Request:>

    update_account('billy_jones_301', {
        '$session_id'       => 'gigtleqddo84l8cm15qe4il',
        '$user_email'       => 'bill@gmail.com',
        '$name'             => 'Bill Jones',
        '$phone'            => '1-415-555-6040',
        '$referrer_user_id' => 'janejane101',
        '$changed_password' => JSON::true,
        ...
    });

B<Response:>

    {
        error_message => 'OK',
        status        => 0,
        time          => 1428607810,
        request       => { ... }
    }

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/WebService-SiftScience/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package WebService::MyAffiliates;

use strict;
use warnings;
our $VERSION = '0.10';

use Carp;
use Mojo::Util qw(b64_encode url_escape);
use XML::Simple 'XMLin';    ## no critic
use JSON::MaybeUTF8 qw(encode_json_utf8);
use HTTP::Tiny;
use Mojo::URL;

use vars qw/$errstr/;
sub errstr { return $errstr }

sub new {    ## no critic (ArgUnpacking)
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    for (qw/user pass host/) {
        $args{$_} || croak "Param $_ is required.";
    }

    # fix host with schema
    $args{host} = 'http://' . $args{host} unless $args{host} =~ m{^https?\://};
    $args{host} =~ s{/$}{};

    $args{timeout} ||= 300;    # for HTTP::Tiny timeout

    return bless \%args, $class;
}

sub __http_tiny {
    my $self = shift;

    return $self->{http_tiny} if exists $self->{http_tiny};

    my $http_tiny = HTTP::Tiny->new(timeout => $self->{timeout});
    $self->{http_tiny} = $http_tiny;

    return $http_tiny;
}

## https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+1%3A+Users+Feed
sub get_users {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    my $url  = Mojo::URL->new('/feeds.php?FEED_ID=1');
    $url->query(\%args) if %args;
    return $self->request($url->to_string);
}

sub get_users_status {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    my $url  = Mojo::URL->new('/feeds.php?FEED_ID=3');
    $url->query(\%args) if %args;
    return $self->request($url->to_string);
}

sub create_affiliate {    ## no critic (ArgUnpacking)
    my $self       = shift;
    my %args       = @_ % 2 ? %{$_[0]} : @_;
    my $parameters = +{map { ('PARAM_' . $_ => $args{$_}) } keys %args};

    my $url = Mojo::URL->new('/feeds.php?FEED_ID=26');
    $url->query($parameters);
    my $res = $self->request($url->to_string);

    my $error_count = $res->{INIT}->{ERROR_COUNT};
    if ($error_count) {
        my $init = $res->{INIT};
        my @errors =
            ref $init->{ERROR} eq 'ARRAY'
            ? $init->{ERROR}->@*
            : ($init->{ERROR});
        $errstr = map { $_->{MSG} . " " . $_->{DETAIL} } @errors;
        return;
    }

    delete $res->{PASSWORD};

    return $res;
}

sub get_user {
    my ($self, $id) = @_;

    $id                                         or croak "id is required.";
    my $user = $self->get_users(USER_ID => $id) or return;
    return $user->{USER};
}

sub get_users_status_by_affiliate_id {
    my ($self, $ids) = @_;
    $ids or croak "id is required.";
    my $user = $self->get_users_status(USER_IDS => $ids);
    return $user->{USER};
}

## https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+4%3A+Decode+Token
sub decode_token {
    my $self   = shift;
    my @tokens = @_ or croak 'Must pass at least one token.';

    return $self->request('/feeds.php?FEED_ID=4&TOKENS=' . url_escape(join(',', @tokens)));
}

## https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+5%3A+Encode+Token
sub encode_token {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{USER_ID}  or croak "USER_ID is required.";
    $args{SETUP_ID} or croak "SETUP_ID is required.";

    my $url = Mojo::URL->new('/feeds.php?FEED_ID=5');
    $url->query(\%args) if %args;
    return $self->request($url->to_string);
}

## https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+6%3A+User+Transactions+Feed
sub get_user_transactions {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{FROM_DATE} or croak 'FROM_DATE is reqired.';

    my $url = Mojo::URL->new('/feeds.php?FEED_ID=6');
    $url->query(\%args) if %args;
    return $self->request($url->to_string);
}

sub get_customers {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = Mojo::URL->new('/feeds.php?FEED_ID=10');
    $url->query(\%args) if %args;

    my $res = $self->request($url->to_string);

    my $customers =
         !exists $res->{PLAYER}         ? []
        : ref $res->{PLAYER} eq 'ARRAY' ? $res->{PLAYER}
        :                                 [$res->{PLAYER}];

    return $customers;
}

sub request {
    my ($self, $url, $method, %params) = @_;

    $method ||= 'GET';

    my $http_tiny = $self->__http_tiny;
    my $header    = {Authorization => 'Basic ' . b64_encode($self->{user} . ':' . $self->{pass}, '')};
    my @extra     = %params ? (form => \%params) : ();
    my $response =
        $http_tiny->get($self->{host} . $url, {headers => $header});

    unless ($response->{success}) {
        $errstr = $response->{reason};
        return;
    }

    if (    $response->{headers}{"content-type"}
        and $response->{headers}{"content-type"} =~ 'text/xml')
    {
        return XMLin($response->{content});
    }

    $errstr = $response->{content};
    return;
}

## un-documented helper
sub get_affiliate_id_from_token {
    my ($self, $token) = @_;

    $token or croak 'Must pass a token to get_affiliate_id_from_token.';

    my $token_info = $self->decode_token($token) or return;
    return $token_info->{TOKEN}->{USER_ID};
}

=head2 get_affiliate_details

Get affiliate detail from user token

=over 4

=item * C<token> - token to get detail from

=back

Returns token_info hash

=cut

sub get_affiliate_details {
    my ($self, $token) = @_;

    croak 'Must pass a token to get_affiliate_email_from_token.' unless $token;

    my $token_info = $self->decode_token($token) or return;
    return $token_info;
}

sub reset_errstr {
    $errstr = '';
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::MyAffiliates - Interface to myaffiliates.com API

=head1 SYNOPSIS

    use WebService::MyAffiliates;

    my $aff = WebService::MyAffiliates->new(
        user => 'user',
        pass => 'pass',
        host => 'admin.example.com'
    );

    my $token; # initial it
    my $token_info = $aff->decode_token($token) or die $aff->errstr;

=head1 DESCRIPTION

WebService::MyAffiliates is Perl interface to L<http://www.myaffiliates.com/xmlapi>

It's incompleted. patches are welcome with pull-requests of L<https://github.com/binary-com/perl-WebService-MyAffiliates>

=head1 METHODS

=head2 new

=over 4

=item * user

required. the Basic Auth username.

=item * pass

required. the Basic Auth password.

=item * host

required. the Basic Auth url/host.

=back

=head2 get_users

Feed 1: Users Feed

L<https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+1%3A+Users+Feed>

    my $user_info = $aff->get_users(USER_ID => $id);
    my $user_info = $aff->get_users(STATUS => 'new');
    my $user_info = $aff->get_users(VARIABLE_NAME => 'n', VARIABLE_VALUE => 'v');

=head2 get_user

    my $user_info = $aff->get_user($id); # { ID => ... }

call get_users(USER_ID => $id) with the top evel USER key removed.

=head2 decode_token

Feed 4: Decode Token

L<https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+4%3A+Decode+Token>

    my $token_info = $aff->decode_token($token); # $token_info is a HASH which contains TOKEN key
    my $token_info = $aff->decode_token($tokenA, $tokenB);

=head2 encode_token

Feed 5: Encode Token

L<https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+5%3A+Encode+Token>

    my $token_info = $aff->encode_token(
        USER_ID  => 1,
        SETUP_ID => 7
    );

=head2 get_user_transactions

Feed 6: User Transactions Feed

L<https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+6%3A+User+Transactions+Feed>

    my $transactions = $aff->get_user_transactions(
        'USER_ID'   => $id,
        'FROM_DATE' => '2011-12-31',
        'TO_DATE'   => '2012-01-31',
    );

=head2 get_customers

Feed 10: User Customers Feed.
Returns Array ref with customer list.

    my $customers = $aff->get_customers( AFFILIATE_ID => $affiliate_id );


=head2 create_affiliate

Feed 26:Create Affiliate

L<https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+26%3A+Create+Affiliate>

    my $res = $aff->create_affiliate({
        'first_name'     => 'Chales',
        'last_name'     => 'Babbage',
        'date_of_birth' => '1871-10-18',
        'individual'    => 'individual',
        'phone_number'  => '+4412341234',
        'address'       => 'Some street',
        'city'          => 'Some City',
        'state'         => 'Some State',
        'postcode'      => '1234',
        'website'       => 'https://www.example.com/',
        'agreement'     => 1,
        'username'      => 'charles_babbage.com',
        'email'         => 'charles@babbage.com',
        'country'       => 'GB',
        'password'      => 's3cr3t',
        'plans'         => '2,4'
    });

    $res->{USERID};

It expects a hashref with all the required parameters for account creation. Other fields may be required depending on your installation.

=over 4

=item * username: A non-empty string with the username, must be an alphanumeric unique string.

=item * password: A non-empty string with the password, following configured the password policy.

=item * email: A non-empty string with a valid e-mail account. It must be unique.

=item * referrer_token: Optional. A non-empty string with subaffiliate token.

=item * plans: Optional. A non-empty string with CSV with the channel numeric IDs to subscribe the client. MyAffiliates will also subscribe the client to any default channel unless B<PLAN_FORCE> is set to 1.

=item * PLAN_FORCE: Optional. For use with plans, if 1 is set here the client will be subscribe to the channels listed in C<plans> parameters only, and won't be subscribed to any other channel. By default this is is 0.

=back

Returns a hashref with the details for the created account, in particular a numeric user_id will be returned in the hashref.

=head2 errstr

=head2 get_affiliate_id_from_token

=head2 request

=head2 reset_errstr

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

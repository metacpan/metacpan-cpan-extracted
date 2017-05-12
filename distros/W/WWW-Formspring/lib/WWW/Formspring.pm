package WWW::Formspring;

=pod

=head1 NAME

WWW::Formspring - Perl interface for formspring.me

=head1 SYNOPSIS

 use WWW::Formspring;
 my $fs = WWW::Formspring->new({
                        access_token => "xxx",
                        access_secret => "yyy",
                        consumer_secret => "aaa",
                        consumer_key => "bbb",
                        username => "johndoe",
                    });

 $fs->profile_ask("worr2400", "Hey, what's up?");

=head1 DESCRIPTION

This is a Perl interface for the very beta formspring.me API. This module is subject to breakage as they play with the 
final spec of their API.
Most methods share names with the paths of the API counterparts, making the formspring API documentation on dev.formspring.me
just as useful as this documentation. 

=head2 EXPORT

None by default.

=cut

use Moose;
use Moose::Util::TypeConstraints;

use 5.010001;

require Exporter;

use Carp;
use LWP::UserAgent;
use Net::OAuth;
use URI;
use XML::Simple;

use WWW::Formspring::User;
use WWW::Formspring::Question;
use WWW::Formspring::Response;

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::Formspring ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.03';


# Preloaded methods go here.
subtype 'WWW::Formspring::URI' => as class_type('URI');

coerce 'WWW::Formspring::URI'
    => from 'Object'
        => via { $_->isa('URI') ? $_ :
            Params::Coerce::coerce('URI', $_); }
    => from 'Str'
        => via { URI->new($_) };

has 'username' => (is => 'rw', isa => 'Str', predicate => 'has_username');
has 'consumer_key' => (is => 'rw', isa => 'Str', predicate => 'has_consumer_key');
has 'consumer_secret' => (is => 'rw', isa => 'Str', predicate => 'has_consumer_secret');
has 'access_token' => (is => 'rw', isa => 'Str', predicate => 'has_access_token');
has 'access_secret' => (is => 'rw', isa => 'Str', predicate => 'has_access_secret');
has 'request_url' => (is => 'ro', isa => 'WWW::Formspring::URI', default => 'http://www.formspring.me/oauth/request_token', coerce => 1);
has 'auth_url' => (is => 'ro', isa => 'WWW::Formspring::URI', default => 'http://www.formspring.me/oauth/authorize', coerce => 1);
has 'access_url' => (is => 'ro', isa => 'WWW::Formspring::URI', default => 'http://www.formspring.me/oauth/access_token', coerce => 1);
has 'callback_url' => (is => 'rw', isa => 'Str', default => 'oob');
has 'api_url' => (is => 'ro', isa => 'WWW::Formspring::URI', default => 'http://beta-api.formspring.me', coerce => 1);
has 'ua' => (is => 'ro', 
             isa => 'LWP::UserAgent',
             default => sub {
                 LWP::UserAgent->new
             });

=pod

=head1 ATTRIBUTES

The constructor can take any of these attributes in a hashref, just like normal Moose objects. Read-only attributes that are not
for use outside of the module are not described here, and it is not recommended that you change their values on construction.

=over

=item username

Supply a default username. Any method that takes a username may use this username if none is provided. Also used when posting questions
non-anonymously.

=item consumer_key

OAuth consumer key for authentication.

=item consumer_secret 

OAuth consumer secret for authentication. Be sure to keep this safe somewhere.

=item access_token

OAuth access token for a user after they have successfully authorized your app to access their account.

=item access_secret

OAuth access token secret for a user after they have successfully authorized your app to access their account. Like the consumer secret,
you should try and keep this safe somewhere.

=item callback_url

URL for OAuth to redirect to in after authorization has occurred. Defaults to 'oob' for desktop apps, which means that no redirection occurs,
and that they are provided a pin to manually enter into your application.

=back

=cut

# Shamelessly ripped from http://www.social.com/main/twitter-oauth-using-perl/
sub _nonce {
    my ($self) = @_;
    my $lower = 999999;
    my $upper = 2 ** 31;
    
    return int(rand($upper - $lower + 1) + $lower);
}

sub get_request_token {
    my $self = shift;

    if (not $self->has_consumer_key or not $self->has_consumer_secret) {
        croak "Missing consumer_key or consumer_secret";
    }

    my $req = Net::OAuth->request("request token")->new(
        consumer_key => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
        request_url => $self->request_url,
        request_method => 'POST',
        signature_method => 'HMAC-SHA1',
        timestamp => time,
        nonce => $self->_nonce,
        callback => $self->callback_url,
        version => '1.0',
    );

    $req->sign;

    my $res = $self->ua->post($req->request_url, Content => $req->to_post_body);

    if ($res->is_success) {
        my $response = Net::OAuth->response("request token")->from_post_body($res->content);
        my $token = $response->token;
        my $secret = $response->token_secret;

        return { token => $token, token_secret => $secret };
    } else {
        croak "Could not get request tokens";
    }
}

=pod

=head1 OAUTH AUTHENTICATION

WWW::Formspring uses Net::OAuth to handle authentication. It abstracts away some of the messy details, of using formspring's OAuth from the
programmer.

To outline the process, first you need to get a request token, then redirect the user to the Formspring authorization page. Your app
will either get a PIN from the user, or a get a PIN as a parameter to your callback_url. Then, with the request token info and the 
PIN, you can get access tokens which will allow your app to authenticate as the user again and again. So it would be a good idea
to store these somewhere persistent.

=head2 Getting a request token

NOTE: consumer_key and consumer_secret must be set for this function call to work.

 my $request_token = $fs->get_request_token

=head2 Redirecting the user

Redirect the user to formspring authorization page:

 my $auth_url = $fs->auth_url."?token=".$request_token->{token}."&secret="$request_token->{token_secret}

=head2 Getting the access token

Depending on the value of callback_url, you will either have to prompt the user for a PIN, or get the pin as a parameter to your
callback_url. Pass this in with the request token and secret to get_access_token, and you'll get your access token and secret.

 $fs->get_access_token($request_token->{token}, $request_token->{token_secret}, $pin)

=head1 METHODS

=over

=item get_request_token

Gets a request token from formspring.me as the first step of OAuth authentication. Returns a hashref with keys token and token_secret. 
consumer_key, consumer_secret, and callback_url must be set before you call this method.

=cut

sub get_access_token {
    my ($self, $request_token, $request_token_secret, $oauth_verifier) = @_;

    croak "Missing request_token" if (not $request_token);
    croak "Missing request_token_secret" if (not $request_token_secret);
    croak "Missing oauth_verifier" if (not $oauth_verifier);

    if (not $self->has_consumer_key or not $self->has_consumer_secret) {
        croak "Missing consumer_key or consumer_secret";
    }

    my $req = Net::OAuth->request("access token")->new(
        consumer_key => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
        token => $request_token,
        token_secret => $request_token_secret,
        request_url => $self->access_url,
        request_method => 'POST',
        signature_method => 'HMAC-SHA1',
        timestamp => time,
        nonce => $self->_nonce,
        version => '1.0',
        verifier => $oauth_verifier
    );

    $req->sign;

    my $res = $self->ua->post($req->request_url, Content => $req->to_post_body);

    if ($res->is_success) {
        my $response = Net::OAuth->response("access token")->from_post_body($res->content);
        my $token = $response->token;
        my $secret = $response->token_secret;
        return { token => $token, token_secret => $secret };
    } else {
        croak $res->code.": ".$res->message;
    }
}

=pod

=item get_access_token($request_token, $request_token_secret, $verifier)

Gets an access token from formspring.me as the last step of OAuth verification. Takes the token and secret from get_request_token, as well
as the oauth_verifier that was received as a parameter to your callback URL, or as a PIN from the formspring site.

=cut

sub _unauth_connect {
    my ($self, $suffix, $type) = @_;
    my $params;

    if ($self->has_access_secret and 
        $self->has_access_token and 
        $self->has_consumer_key and 
        $self->has_consumer_secret) {
        return $self->_auth_connect(@_[1..@_-1]);
    }

    $params = $_[3] if (@_ > 3);
    my $api_url = $self->api_url;

    my $req = HTTP::Request->new($type => "$api_url$suffix");
    $req->headers($params) if ($params);

    my $res = $self->ua->request($req);

    croak $res->code.": ".$res->message if ($res->is_error);

    return $self->_xmlify($res->content);
}

sub _auth_connect {
    my ($self, $suffix, $type) = @_;
    my $params;
    my $res;

    $params = $_[3] if (@_ > 3);
    my $api_url = $self->api_url->as_string;

    if (not $self->has_consumer_key or not $self->has_consumer_secret) {
        croak "Missing consumer_key or consumer_secret";
    }

    if (not $self->has_access_token or not $self->has_access_secret) {
        croak "Missing access_token or access_secret";
    }

    my $req = Net::OAuth->request("protected resource")->new(
        consumer_key => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
        token => $self->access_token,
        token_secret => $self->access_secret,
        request_url => $api_url.$suffix,
        request_method => $type,
        signature_method => 'HMAC-SHA1',
        timestamp => time,
        nonce => $self->_nonce,
        version => 1.0,
    );

    $req->extra_params($params) if ($params);
    $req->sign;

    if ($type eq "POST") {
        $res = $self->ua->post($req->request_url, Content => $req->to_post_body);
    } else {
        $res = $self->ua->get($req->to_url);
    }

    croak $res->code.": ".$res->message if (not $res->is_success);

    return $self->_xmlify($res->content);
}

sub _xmlify {
    my ($self, $data) = @_;
    my ($user, $ret);
    my $xml = XMLin($data, SuppressEmpty => '', ForceArray => [ 'item' ]);

    if ($xml->{'item'}) {
        my @ret_items;

        foreach my $id (keys %{$xml->{'item'}}) {
            if ($xml->{'item'}->{$id}->{'asked_by'} ne '') {
                $user = WWW::Formspring::User->new($xml->{'item'}->{$id}->{'asked_by'});
            } else {
                $user = WWW::Formspring::User->new;
            }

            $xml->{'item'}->{$id}->{'asked_by'} = $user;
            $xml->{'item'}->{$id}->{'id'} = $id;

            my $response = WWW::Formspring::Response->new($xml->{'item'}->{$id});
            if (defined $xml->{'item'}->{$id}->{'profile'}) {
                $response->asked_to(WWW::Formspring::User->new($xml->{'item'}->{$id}->{'profile'}));
            }

            push @ret_items, $response;
        }

        $ret = \@ret_items;
    } elsif (defined $xml->{'count'}) {
        $ret = $xml->{'count'};
    } elsif ($xml->{'profiles'}) {
        my @results;
        if ($xml->{'profiles'}->{'profile'}->{'name'}) {
            return [ WWW::Formspring::User->new($xml->{'profiles'}->{'profile'}) ];
        }
        foreach my $name (keys %{$xml->{'profiles'}->{'profile'}}) {
            $xml->{'profiles'}->{'profile'}->{$name}->{'name'} = $name;
            $user = WWW::Formspring::User->new($xml->{'profiles'}->{'profile'}->{$name});
            push @results, $user;
        }

        $ret = \@results;
    } elsif ($xml->{'profile'}) {
        $ret = WWW::Formspring::User->new($xml->{'profile'});

        if (not defined $ret->username) {
            my @results;

            foreach my $name (keys %{$xml->{'profile'}}) {
                $xml->{'profile'}->{$name}->{'name'} = $name;
                $user = WWW::Formspring::User->new($xml->{'profile'}->{$name});
                push @results, $user;
            }

            $ret = \@results;
        }
    } elsif ($xml->{'username'}) {
        $ret = WWW::Formspring::User->new($xml);
    } elsif ((keys %$xml) == 1) {
        return 0;
    }

    return $ret;
}

sub answered_count {
    my $self = shift;
    my $username = $self->username;

    $username = shift if (@_);

    my $count = $self->_unauth_connect("/answered/count/$username.xml", "GET");

    return $count;
}

=pod

=item answered_count

=item answered_count($username)

Gets the answer count, as an int, of the provided (or default) username. 

=cut

sub answered_details {
    my $self = shift;
    my $id = shift;
    my $username = $self->username;
    my $response;

    $username = shift if (@_);

    if (ref($id) eq "WWW::Formspring::Response") {
        $response = $self->_unauth_connect("/answered/details/".$id->asked_to->username."/".$id->id.".xml", "GET");
    } else {
        $response = $self->_unauth_connect("/answered/details/$username/$id.xml", "GET");
    }

    return $response->[0];
}

=pod

=item answered_details($id)

=item answered_details($response)

=item answered_details($id, $username)

Gets the all of the information you could ever want about a specific question of the id and username provided. Returns a 
filled out WWW::Formspring::Response object.

Can also fill out a user created WWW::Formspring::Response object if at least the asked_to and the id are present.

=cut

sub answered_list {
    my $self = shift;
    my $username = $self->username;
    my $params = {};
    my ($response, $user);

    $username = shift if (@_);
    $params->{max_id} = shift if (@_);
    $params->{since_id} = shift if (@_);

    if (ref($username) eq "WWW::Formspring::User") {
        $response = $self->_unauth_connect("/answered/list/".$username->username.".xml", "GET", $params);
        $user = $self->profile_details($username->username);
    } else {
        $response = $self->_unauth_connect("/answered/list/$username.xml", "GET", $params);
        $user = $self->profile_details($username);
    }


    $_->asked_to($user) foreach (@$response);

    return $response;
}

=pod

=item answered_list

=item answered_list($user)

=item answered_list($username)

=item answered_list($username, $max_id)

=item answered_list($username, $max_id, $since_id)

Gets a list of questions and answers from given (or default) username. Returns an arrayref of WWW::Formspring::Response objects.
If max_id parameter is provided, it will get all responses from before the given id. Can also take a WWW::Formspring::User object.
If since_id is also set, it will get only posts after the id passed.

=cut

sub answered_remove {
    my ($self, $id) = @_;
    my $response;

    if (ref($id) eq "WWW::Formspring::Response") {
        $response = $self->_auth_connect("/answered/remove/".$id->id.".xml", "POST");
    } else {
        $response = $self->_auth_connect("/answered/remove/$id.xml", "POST");
    }

    return $response;
}

=pod

=item answered_remove($id)

=item answered_remove($question)

Deletes an answered question from the authenticated user by id and returns it to the inbox. Takes either a numeric question id or a
WWW::Formspring::Response object. Returns 0 on success.

=cut

sub follow_add {
    my ($self, $username) = @_;
    my $response;

    if (ref($username) eq "WWW::Formspring::User") {
        $response = $self->_auth_connect("/follow/add/".$username->username.".xml", "POST");
    } else {
        $response = $self->_auth_connect("/follow/add/$username.xml", "POST");
    }

    return $response;
}

=pod

=item follow_add($user)

=item follow_add($username)

Adds the provided user to the authenticated users followed list. Takes either a string or a WWW::Formspring::User object.
Returns a 0 on success.

=cut

sub follow_answers {
    my $self = shift;
    my $params = {};

    $params->{max_id} = shift if (@_);
    $params->{since_id} = shift if (@_);

    my $response = $self->_auth_connect("/follow/answers.xml", "GET", $params);
    return $response;
}

=pod

=item follow_answers

=item follow_answers($max_id)

=item follow_answers($max_id, $since_id)

Gets all of the questions and answers from the authenticated user's friends. Returns an arrayref of WWW::Formspring::Response objects.
If $max_id is provided, then it only fetches questions from before the passed in id. If $since_id is also passed in, it will get only
posts after the post of the id specified.

=cut

sub follow_count {
    my $self = shift;

    my $count = $self->_auth_connect("/follow/count.xml", "GET");
    return $count;
}

=pod

=item follow_count

Returns the number of people the authenticated user is following.

=cut

sub follow_list {
    my $self = shift;
    my $params = {};

    $params->{page} = shift if (@_);
    my $followees = $self->_auth_connect("/follow/list.xml", "GET", $params);
    return $followees;
}

=pod

=item follow_list

=item follow_list($page)

Get list of people the authenticated use is following. If page is provided, get that page of results (100 per page). Else,
returns the first page. Returns an arrayref of WWW::Formspring::User objects.

=cut

sub follow_remove {
    my ($self, $username) = @_;
    my $ret;

    if (ref($username) eq "WWW::Formspring::User") {
        $ret = $self->_auth_connect("/follow/remove/".$username->username.".xml", "GET");
    } else {
        $ret = $self->_auth_connect("/follow/remove/$username.xml", "GET");
    }

    return $ret;
}

=pod

=item follow_remove($username)

Removes the passed in user from the authenticated user's follower list. Returns 0 on success.

=cut

sub inbox_block {
    my ($self, $id) = @_;
    my $params = {};
    my $ret;

    $params->{reason} = $_[2] if (@_ > 2);

    if (ref($id) eq "WWW::Formspring::Response") {
        $ret = $self->_auth_connect("/inbox/block/".$id->id.".xml", "POST", $params);
    } else {
        $ret = $self->_auth_connect("/inbox/block/$id.xml", "POST", $params);
    }

    return $ret;
}

=pod

=item inbox_block($question)

=item inbox_block($id)

=item inbox_block($id, $reason)

Deletes a question from the authenticated user's inbox and blocks the user from asking anymore questions to the authenticated
user. A numeric id can be provided as well as a WWW::Formspring::Response. $reason can be either "spam" or "abuse," but does 
not need to be provided at all. Returns 0 on success.

=cut

sub inbox_count {
    my $self = shift;

    my $ret = $self->_auth_connect("/inbox/count.xml", "GET");
    return $ret;
}

=pod

=item inbox_count

Returns the number of questions in the authenticated user's inbox.

=cut

sub inbox_list {
    my $self = shift;
    my $params = {};

    $params->{max_id} = $_[1] if (@_ > 1 and $_[1]);
    $params->{since_id} = $_[2] if (@_ > 2 and $_[2]);
    my $questions = $self->_auth_connect("/inbox/list.xml", "GET", $params);
    return $questions;
}

=pod

=item inbox_list

=item inbox_list($max_id)

=item inbox_list($max_id, $since_id)

Returns a list of questions in the authenticated user's inbox. If $max_id is provided, then no questions later than $max_id will be
returned. If $since_id is provided, no questions before $since_id will be returned. Either value can be 0 to indicate that you do not
wish to use that parameter.

Returns an arrayref of WWW::Formspring::Response objects.

=cut

sub inbox_random {
    my $self = shift;

    my $question = $self->_auth_connect("/inbox/random.xml", "GET");
    return $question;
}

=pod

=item inbox_random

Asks the authenticated user a random questions generated by the site. Returns a WWW::Formspring object.

=cut

sub inbox_remove {
    my ($self, $id) = @_;
    my $ret;

    if (ref($id) eq "WWW::Formspring::Response") {
        $ret = $self->_auth_connect("/inbox/remove/".$id->id.".xml", "POST");
    } else {
        $ret = $self->_auth_connect("/inbox/remove/$id.xml", "POST");
    }

    return $ret;
}

=pod

=item inbox_remove($question)

=item inbox_remove($id)

Removes a question from the authenticated user's inbox. Takes either a numeric id or a WWW::Formspring::Response object. Returns 
0 on success.

=cut

# TODO: Add posting to services
sub inbox_respond {
    my $self = shift;
    my $ret;

    if (ref $_[0] eq "WWW::Formspring::Response") {
        my $question = shift;
        $ret = $self->_auth_connect("/inbox/respond/".$question->id.".xml", "POST", { response => $question->answer });
    } elsif (@_ >= 2) {
        my ($id, $response) = @_;
        $ret = $self->_auth_connect("/inbox/respond/$id.xml", "POST", { response => $response });
    } else {
        carp "inbox_respond called with improper arguments";
        $ret = -1;
    }

    return $ret;
}

=pod

=item inbox_respond($question)

=item inbox_respond($id, $response)

Respond to a question in the authenticated user's inbox. $question must be a WWW::Formspring::Question object, however you can also
just provide the id of the question and the user's response. Returns 0 on success.

=cut

sub profile_ask {
    my $self = shift;
    my $ret;

    if (@_ == 1) {
        my $quest = shift;
        $ret = $self->_auth_connect("/profile/ask/".$quest->asked_to->username.".xml", "POST", { question => $quest->question,
                                                                                                 anonymous => not $quest->has_asked_by });
    } elsif (@_ == 3) {
        my ($username, $question, $anonymous) = @_;
        $ret = $self->_auth_connect("/profile/ask/$username.xml", "POST", { question => $question, anonymous => $anonymous });
    } else {
        carp "profile_ask called with improper arguments";
        $ret = -1;
    }

    return $ret;
}

=pod 

=item profile_ask($question)

=item profile_ask($username, $question, $anonymous)

Ask a question to a user. $question must be a WWW::Formspring::Response object. In this case, anonymity is determined by whether or not
the WWW::Formspring::Response object contains a valid WWW::Formspring::User object in the asked_by field. The user that the question
is directed at goes in the asked_to field as a WWW::Formspring::User object.

Alternatively, strings can be provided in the place of objects. $anonymous can be 1 or 0 to represent true or false.

=cut

sub profile_details {
    my $self = shift;
    my ($user, $username);

    $username = shift if (@_);

    if (defined $username) {
        if (ref($username) eq "WWW::Formspring::User") {
            $user = $self->_unauth_connect("/profile/details/".$username->username.".xml", "GET");
        } else {
            $user = $self->_unauth_connect("/profile/details/$username.xml", "GET");
        }
    } else {
        $user = $self->_auth_connect("/profile/details.xml", "GET");
    }

    return $user;

}

=pod

=item profile_details

=item profile_details($user)

=item profile_details($username)

Get user details based on passed in username. If no username is provided, then the default username IS NOT used, and the details on the
authenticated user is provided instead (as directed by the formspring API). Returns a WWW::Formspring::User object.

=cut

sub search_profiles {
    my $self = shift;
    my $params = { query => shift };

    $params->{page} = shift if (@_);

    my $results = $self->_unauth_connect("/search/profiles.xml", "GET", $params);
    return $results;
}

=pod

=item search_profiles($query)

=item search_profiles($query, $page)

Searches profiles based on $query. If $page is provided, that page is returned. Returns page 1 by default, 50 results per page.
A max of 20 pages will be returned by the search function.

=cut

__PACKAGE__->meta->make_immutable;
1;
__END__

=pod

=back

=head1 WWW::Formspring::User

This object represents a formspring.me user, and it has the following accessors/mutators

=over

=item username

=item name

=item website

=item location

=item bio

=item photo_url

=item answered_count

=item is_following

=back

=head1 WWW::Formspring::Question

This represents a formspring.me question, and has the following accessors/mutators

=over

=item id

=item question

=item time

=item asked_by

=item asked_to

=item ask

This asks the user in the ask_to field the question. You can fill out a Question object and just call ask on it and it will submit the question.

=back

=head1 WWW::Formspring::Response

This represents a response to a question, and inherits from WWW::Formspring::Question. Additionally it includes the following

=over

=item answer

=item respond

Like the Question object, you can fill out a response object that references a formspring question and a response and then call respond on it to respond to it.

=back

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

William Orr, E<lt>will@worrbase.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by William Orr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

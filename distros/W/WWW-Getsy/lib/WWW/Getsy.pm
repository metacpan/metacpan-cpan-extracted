use MooseX::Declare;
use 5.008008;

our $VERSION = '0.999007';

=head1 NAME
    
WWW::Getsy - Command line interface to Etsy V2 OAuth API

=head1 SYNOPSIS

Command line interface to Etsy V2 OAuth API

Register for a developer account here: http://developer.etsy.com/member/register
Then register your app for a V2 Sandbox key: http://developer.etsy.com/apps/register

Then define your consumer key and secret environment variables

    export OAUTH_CONSUMER_KEY='your_key'
    export OAUTH_CONSUMER_SECRET='your_secret'

Finally start making some api calls

Get a list of all methods

    getsy --sandbox --path '/'

Get your user info

    getsy --sandbox --path '/users/__SELF__'

You can use the --method paramter to make post, put, and delete calls (get is default)
and --params to pass in a JSON string of parameters

    getsy --sandbox --path '/listings/51455722' --params '{"title" : "changing the title"}' --method put

A full list of methods available here

    http://developer.etsy.com/docs/methods

=cut

class WWW::Getsy with MooseX::Getopt {
    use WWW::Getsy::OAuth;
    use File::HomeDir qw(home);
    use File::Spec::Functions qw(catfile);
    use JSON::XS;
    use MooseX::Getopt;
    use MooseX::Types::Moose qw/Str HashRef/;
    use WWW::Getsy::Types qw(
        EnvConsumerKey 
        EnvConsumerSecret 
        RequestParams 
        RequestMethod
        );
    use Data::Dumper;

    has 'sandbox' => (
        is => 'rw', 
        isa => 'Bool',
        default => 0,
    );

    has 'debug' => (
        is => 'rw', 
        isa => 'Bool',
        default => 0,
    );

    has 'path' => (
        is => 'rw', 
        isa => Str, 
        required => 1
    );

    has 'url' => (
        metaclass => 'NoGetopt',
        is => 'rw', 
        isa => Str, 
        required => 1,
        lazy => 1,
        default => method {
            return "http://". $self->api_domain ."/v2/private".$self->path;
        }
    );

    has 'api_domain' => (
        metaclass => 'NoGetopt',
        is => 'ro',
        isa => Str,
        required => 1,
        lazy => 1,
        default => method {
            my $api_domain = 'openapi.etsy.com';
            if ($self->sandbox) {
                $api_domain = 'sandbox.openapi.etsy.com';
            }
            return $api_domain;
        }
    );

    has 'params' => (
        is => 'rw', 
        isa => RequestParams, 
        coerce => 1,
        required => 0,
        default => sub { {} }
    );

    has 'method' => (
        is => 'rw', 
        isa => RequestMethod, 
        coerce => 1,
        required => 1,
        default => "get",
    );

    has 'conf_file' => (
        metaclass => 'NoGetopt',
        isa => Str,
        is => 'ro',
        lazy => 1,
        default => method { 
            my $configfile = ".getsy";
            if ($self->sandbox) {
                $configfile .= "_sandbox";
            }
            catfile( home(), $configfile ) 
        },
    );

    has 'consumer_key' => ( 
        metaclass => 'NoGetopt',
        isa => EnvConsumerKey, 
        is => 'ro', 
        default => sub {
            $ENV{OAUTH_CONSUMER_KEY}
        },
    );

    has 'consumer_secret' => (
        metaclass => 'NoGetopt',
        isa => EnvConsumerSecret, 
        is => 'ro', 
        default => sub {
            $ENV{OAUTH_CONSUMER_SECRET}
        }
    );

    has 'oauth_client' => ( 
        metaclass => 'NoGetopt',
        isa => 'WWW::Getsy::OAuth',
        is => 'ro', 
        lazy_build => 1,
        handles => [qw/ 
            authorized
        /],
    );

    method _build_oauth_client {
        WWW::Getsy::OAuth->new(
            tokens => {
                consumer_key => $self->consumer_key,
                consumer_secret => $self->consumer_secret,
            }, 
            protocol_version => '1.0a',
            urls   => {
                authorization_url => "http://www.etsy.com/oauth/signin",
                request_token_url => "http://". $self->api_domain ."/v2/oauth/request_token",
                access_token_url  => "http://". $self->api_domain ."/v2/oauth/access_token",
            },
            callback => 'oob',
        );
    }

    before authorized { 
        my %tokens = $self->oauth_client->load_tokens($self->conf_file);

        if (grep {defined && length} %tokens) {
            $self->oauth_client->{'tokens'}->{'access_token'} = $tokens{'access_token'};
            $self->oauth_client->{'tokens'}->{'access_token_secret'} = $tokens{'access_secret'};
        } else {
            $self->get_access_tokens;
        }
    };

    method get_access_tokens {
        print "Go to ".$self->oauth_client->get_authorization_url(callback => 'oob') ."\n";
        print "Then enter the verifier token\n";
        my $verifier = <STDIN>;
        chomp $verifier;

        my ($access_token, $access_secret) = $self->oauth_client->request_access_token(verifier => $verifier);

        # Now save those values
        $self->oauth_client->save_tokens($self->conf_file, access_token=>$access_token, access_secret=>$access_secret);

    }

    method oauth_request() {
        if ($self->debug) {
            print "request: ". uc($self->method) ." ". $self->url."\n";
            print "params: ". (%{$self->params} ? Dumper($self->params) : "none") ."\n";
        }
        my $method = 'oauth_'. $self->method;
        $self->$method();
    }

    method oauth_get() {
        return $self->oauth_client->make_restricted_request($self->url, 'GET', %{$self->params});
    }

    method oauth_post() {
        return $self->oauth_client->make_restricted_request($self->url, 'POST', %{$self->params});
    }

    method oauth_put() {
        return $self->oauth_client->make_restricted_request($self->url, 'PUT', %{$self->params});
    }

    method oauth_delete() {
        return $self->oauth_client->make_restricted_request($self->url, 'DELETE', %{$self->params});
    }

    method decode(Str $json) {
        decode_json $json;
    }

    method encode(HashRef $json) {
        JSON::XS->new->utf8->pretty->encode($json);
    }

    method pretty_print(Str $json) {
        print $self->encode($self->decode($json));
    }

}



=head1 AUTHOR

John Goulah, C<< <jgoulah at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-getsy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Getsy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Getsy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Getsy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Getsy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Getsy>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Getsy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Goulah.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

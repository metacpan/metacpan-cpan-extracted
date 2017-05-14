use MooseX::Declare;

class WWW::Getsy::Client {
    use Net::OAuth; 
    use MooseX::Types::Moose qw/Str HashRef/;

    has 'tokens' => (
        isa => HashRef,
        is => 'rw',
        default => undef, 
    );

    has 'request_token' => (
        isa => Str,
        is => 'rw',
        default => undef,
    );

    has 'authorization_url' => (
        isa => Str,
        is => 'ro',
        default => "http://www.etsy.com/oauth/signin",
    );

    has 'request_token_url' => (
        isa => Str,
        is => 'ro',
        default => "http://openapi.etsy.com/v2/oauth/request_token",
    );

    has 'access_token_url' => (
        isa => Str,
        is => 'ro',
        default => "http://openapi.etsy.com/v2/oauth/access_token",
    );

    method authorized {
        foreach my $param ( qw(access_token access_token_secret) ) {
            return 0 unless defined $self->tokens->{$param} && length $self->tokens->{$param};
        }
        return 1;
    }

    method get_authorization_url(Str :$callback) {
#        my $self   = shift;
#        my %params = @_;
        my $url  = $self->authorization_url;
        if (!defined $self->request_token) {
            $self->request_request_token(%params);
        }
        $params{oauth_token} = $self->request_token;
        $url->query_form(%params);
        return $url;
    }

    sub request_request_token {
        my $self   = shift;
        my %params = @_;
        my $url    = $self->request_token_url; 

        $params{callback} = $self->callback                             unless defined $params{callback};
        die "You must pass a callback parameter when using OAuth v1.0a" unless defined $params{callback};

        my $request_token_response = $self->_make_request(
                'Net::OAuth::RequestTokenRequest',
                $url, 'GET', 
                %params);

        die "GET for $url failed: ".$request_token_response->status_line
            unless ( $request_token_response->is_success );

        # Cast response into CGI query for EZ parameter decoding
        my $request_token_response_query =
            new CGI( $request_token_response->content );

        # Split out token and secret parameters from the request token response
        $self->request_token($request_token_response_query->param('oauth_token'));
        $self->request_token_secret($request_token_response_query->param('oauth_token_secret'));
        $self->callback_confirmed($request_token_response_query->param('oauth_callback_confirmed'));

        die "Response does not confirm to OAuth1.0a. oauth_callback_confirmed not received"
            if $self->oauth_1_0a && !$self->callback_confirmed;

    }

    method load_tokens(Str $file) {
        my %tokens = ();
        return %tokens unless -f $file;

        open(my $fh, $file) || die "Couldn't open $file: $!\n";
        while (<$fh>) {
            chomp;
            next if /^#/;
            next if /^\s*$/;
            next unless /=/;
            s/(^\s*|\s*$)//g;
            my ($key, $val) = split /\s*=\s*/, $_, 2;
            $tokens{$key} = $val;
        }
        close($fh);
        return %tokens;
    }

    method save_tokens(Str $file) {
        my %tokens = @_;

        my $max    = 0;
        foreach my $key (keys %tokens) {
            $max   = length($key) if length($key)>$max;
        }

        open(my $fh, ">$file") || die "Couldn't open $file for writing: $!\n";
        foreach my $key (sort keys %tokens) {
            my $pad = " "x($max-length($key));
            print $fh "$key ${pad}= ".$tokens{$key}."\n";
        }
        close($fh);
    }

}

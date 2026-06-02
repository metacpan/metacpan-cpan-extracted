#! perl

use v5.36;
use Object::Pad;

class Weenect::Connect;

=head1 NAME

Weenect::Connect - Low level server communications

=head1 SYNOPSIS

    my $api = Weenect::Connect->new;
    $api->request( ... )

=head1 DESCRIPTION

This modules handles low level communication (REST API) with the
Weenect server.

At the application level, use Weenect::API.

=cut

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON::PP;
use DDP;

field $json;
field $ua;

field $auth :mutator;
field $debug :mutator;
field $cache :mutator;

ADJUST {
    $json = JSON::PP->new;
    $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0");
    # $ua->default_header( );
};

method get_endpoint( $u = undef ) {
    my $url = "https://apiv4.weenect.com/v4";
    $url .= "/" . $u if defined $u;
    $url;
}

=head1 METHODS

Supported methods include:

=head2 request( $path, [ %keys ] )

Performs a REST API request.

If %keys contains C<Content>, then a POST is made, otherwise it will GET.

=cut

method request( $path, %keys ) {
    my $u = $self->get_endpoint($path);
    $u = "https://my.weenect.com/en/$path" if $path eq "logout";

    my $req;
    my @common =
      ( Accept => "application/json, text/plain, */*",
	Origin => "https://my.weenect.com",
	Referer => "https://my.weenect.com",
	"x-app-version" => "0.1.0",
	"x-app-user-id" => "",
	"x-app-type" => "userspace",
	DNT => 1,
      );
    push( @common, Authorization => "JWT ".$auth->access_token ) if $auth;

    my $op = delete $keys{OP} || (defined($keys{Content}) ? 'POST' : 'GET');

    if ( $op eq 'PUT' ) {
	my $content = delete $keys{Content} // {};
	$content = $json->encode($content) if ref($content);
	$req = HTTP::Request::Common::PUT
	  ( $u,
	    @common,
	    Content_Type => "application/json",
	    Content => $content,
	    %keys
	  );
    }
    elsif ( $op eq 'POST' ) {
	my $content = delete $keys{Content} // {};
	$content = $json->encode($content) if ref($content);
	$req = HTTP::Request::Common::POST
	  ( $u,
	    @common,
	    Content_Type => "application/json",
	    Content => $content,
	    %keys
	  );
    }
    elsif ( $op eq 'GET' ) {
	$req = HTTP::Request::Common::GET
	  ( $u,
	    @common,
	    %keys
	  );
    }
    elsif ( $op eq 'DELETE' ) {
	$req = HTTP::Request::Common::DELETE
	  ( $u,
	    @common,
	    %keys
	  );
    }

    p($req) if $debug;
    my $res = $ua->request($req); # res1.json.raw
    unless ( $res->is_success ) {
	p($res) if $debug;
	return;
    }

    return 1 if $path eq "logout"; # res is HTML login page
    return $json->decode( $res->decoded_content || "{}" );
}

1;

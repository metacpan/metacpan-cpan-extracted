# Copyrights 2016-2020 by [Mark Overmeer <markov@overmeer.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP-Mojolicious.
# Meta-POD processed with # OODoc into POD and HTML manual-pages. See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Transport::SOAPHTTP_MojoUA;
use vars '$VERSION';
$VERSION = '0.05';

use base 'XML::Compile::Transport';

use warnings;
use strict;

use Log::Report 'xml-compile-soap-mojolicious';

use XML::Compile::Transport::SOAPHTTP ();

BEGIN {
    # code mixin from  XML::Compile::Transport::SOAPHTTP
    no strict 'refs';
    foreach (qw/_prepare_xop_call _prepare_simple_call _prepare_for_no_answer/) {
        *{ __PACKAGE__ . "::$_" } = \&{"XML::Compile::Transport::SOAPHTTP::$_"};
    }
}

use XML::Compile::SOAP::Util qw/SOAP11ENV SOAP11HTTP/;
use XML::Compile    ();

use Mojolicious     ();    # only for version info?!
use Mojo::UserAgent ();
use Mojo::IOLoop    ();
use HTTP::Request   ();
use HTTP::Response  ();
use HTTP::Headers   ();
use Scalar::Util    qw(blessed reftype);

# (Microsofts HTTP Extension Framework)
my $http_ext_id = SOAP11ENV;

__PACKAGE__->register(SOAP11HTTP);


sub init($) {
    my ($self, $args) = @_;
    if(my $cb = $self->{ua_start_cb} = delete $args->{ua_start_callback}) {
		panic "callback not a code" if reftype $cb ne 'CODE';
	}

    $self->{mojo_ua} = $args->{mojo_ua};
    $self->SUPER::init($args);
    $self;
}

sub initWSDL11($) {
    my ($class, $wsdl) = @_;
    trace "initialize SOAPHTTP-MojoUA transporter for WSDL11";
}

#-------------------------------------------


sub uaStartCallback { shift->{ua_start_cb} }

#-------------------------------------------


sub compileClient(@) {
    my ( $self, %args ) = @_;
    my $call   = $self->_prepare_call( \%args );
    my $kind   = $args{kind} || 'request-response';
    my $parser = XML::LibXML->new;

    sub {
        my ($xmlout, $trace, $mtom, $callback) = @_;
        my $start = time;
        my $textout = ref $xmlout ? $xmlout->toString : $xmlout;

        #warn $xmlout->toString(1);   # show message sent

        my $stringify = time;
        $trace->{transport_start} = $start;

        my $handler = sub {
            my ($textin, $xops) = @_;
            my $connected = time;

            my $xmlin;
            if($textin) {
                $xmlin = eval { $parser->parse_string($$textin) };
                $trace->{error} = $@ if $@;
            }

            my $answer;
            if($kind eq 'one-way') {
                my $response = $trace->{http_response};
                my $code = defined $response ? $response->code : -1;
                if($code == 202) { $answer = $xmlin || {} }
                else  { $trace->{error} = "call failed with code $code" }
            }
            elsif($xmlin) { $answer = $xmlin }
            else          { $trace->{error} ||= 'no xml as answer' }

            my $end = $trace->{transport_end} = time;

            $trace->{stringify_elapse} = $stringify - $start;
            $trace->{connect_elapse}   = $connected - $stringify;
            $trace->{parse_elapse}     = $end - $connected;
            $trace->{transport_elapse} = $end - $start;

            return ( $answer, $trace, $xops );
        };

        $call->( \$textout, $trace, $mtom, sub { $callback->( $handler->(@_) ) } );
    };
} ## end sub compileClient(@)


sub _prepare_call($) {
    my ($self, $args) = @_;
    my $method   = $args->{method} || 'POST';
    my $soap     = $args->{soap}   || 'SOAP11';
    my $version  = ref $soap ? $soap->version : $soap;
    my $mpost_id = $args->{mpost_id} || 42;
    my $action   = $args->{action};
    my $mime     = $args->{mime};
    my $kind     = $args->{kind} || 'request-response';
    my $expect   = $kind ne 'one-way' && $kind ne 'notification-operation';

    my $charset = $self->charset;

    # Prepare header
    my $header = $args->{header} || HTTP::Headers->new;
    $self->headerAddVersions($header);

    my $content_type;
    if($version eq 'SOAP11') {
        $mime ||= ref $soap ? $soap->mimeType : 'text/xml';
        $content_type = qq{$mime; charset=$charset};
    }
    elsif($version eq 'SOAP12') {
        $mime ||= ref $soap ? $soap->mimeType : 'application/soap+xml';
        my $sa = defined $action ? qq{; action="$action"} : '';
        $content_type = qq{$mime; charset=$charset$sa};
        $header->header( Accept => $mime );    # not the HTML answer
    }
    else {
        error __x"SOAP version {version} not implemented", version => $version;
    }

    if($method eq 'POST') {
        $header->header( SOAPAction => qq{"$action"} )
            if defined $action;
    }
    elsif($method eq 'M-POST') {
        $header->header( Man => qq{"$http_ext_id"; ns=$mpost_id} );
        $header->header( "$mpost_id-SOAPAction", qq{"$action"} )
            if $version eq 'SOAP11';
    }
    else {
        error __x"SOAP method must be POST or M-POST, not {method}"
          , method => $method;
    }

    # Prepare request

    # Ideally, we should change server when one fails, and stick to that
    # one as long as possible.
    my $server  = $self->address;
    my $request = HTTP::Request->new(
        $method => $server,
        $header
    );
    $request->protocol('HTTP/1.1');

    # Create handler

    my ($create_message, $parse_message)
      = exists $INC{'XML/Compile/XOP.pm'}
      ? $self->_prepare_xop_call($content_type)
      : $self->_prepare_simple_call($content_type);

    $parse_message = $self->_prepare_for_no_answer($parse_message)
        unless $expect;

    # Needs to be outside the sub so it does not go out of scope
    # when the sub is left (which would cause the termination of
    # the request)
    my $ua = $self->{mojo_ua} || Mojo::UserAgent->new;

    if(my $callback = $self->uaStartCallback) {
       $ua->on(start => $callback);
    }

    # async call
    sub {
        my ( $content, $trace, $mtom, $callback ) = @_;
        $create_message->($request, $content, $mtom);

        $trace->{http_request} = $request;

        my $handler = sub {
            my $tx = shift;

            unless(blessed $tx && $tx->isa('Mojo::Transaction::HTTP')) {
                $trace->{error} = "Did not receive a transaction object";
                return $callback->(undef, undef, $trace);
            }

			my $res     = $tx->res;
            my $headers = $res->headers->to_hash(1);
            foreach my $h ( keys %{$headers} ) {
                if ( reftype $headers->{$h} eq 'ARRAY') {
                    $headers->{$h} = join ', ', @{$headers->{$h}};
                }
            }

			my $err      = $res->error;
            $headers->{'Client-Warning'} = 'Client side error: '.$err->{message}
                if $err && !$err->{code};

            my $response = $trace->{http_response} = HTTP::Response->new(
                $res->code, $res->message, [%$headers], $res->body
            );

            if($response->header('Client-Warning')) {
                $trace->{error} = $response->message;
                return $callback->(undef, undef, $trace);
            }

            if($response->is_error) {
                $trace->{error} = $response->message;

                # still try to parse the response for Fault blocks
            }

            my ($parsed, $mtom) = try { $parse_message->($response) };
            if ($@) {
                $trace->{error} = $@->wasFatal->message;
                return $callback->(undef, undef, $trace);
            }

            try { $callback->($parsed, $mtom, $trace) };
        };

        my $tx = $ua->build_tx($request->method => $request->uri->as_string);

        foreach my $hdr_name ($request->headers->header_field_names) {
            next if $hdr_name eq "Content-Length";

            foreach my $hdr ( $request->headers->header($hdr_name) ) {
                $tx->req->headers->append( $hdr_name => $hdr );
            }
        }
        $tx->req->body($request->content);

        $ua->start(
            $tx => sub {
                my ($ua, $tx) = @_;
                $handler->($tx);
            },
        );
    };
}



sub headerAddVersions($) {
    my ( $thing, $h ) = @_;
    foreach my $pkg (
        qw/XML::Compile
           XML::Compile::Cache
           XML::Compile::SOAP
           XML::LibXML
           Mojolicious/ )
    {
        no strict 'refs';
        my $version = ${"${pkg}::VERSION"} || 'undef';
        ( my $field = "X-$pkg-Version" ) =~ s/\:\:/-/g;
        $h->header($field => $version);
    }
}

1;

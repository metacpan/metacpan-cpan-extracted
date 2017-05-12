# XML::RPC::Fast
#
# Copyright (c) 2008-2009 Mons Anderson <mons@cpan.org>, all rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package XML::RPC::Fast;

=head1 NAME

XML::RPC::Fast - Fast and modular implementation for an XML-RPC client and server

=cut

our $VERSION   = '0.8'; $VERSION = eval $VERSION;

=head1 SYNOPSIS

Generic usage

    use XML::RPC::Fast;
    
    my $server = XML::RPC::Fast->new( undef, %args );
    my $client = XML::RPC::Fast->new( $uri,  %args );

Create a simple XML-RPC service:

    use XML::RPC::Fast;
    
    my $rpc = XML::RPC::Fast->new(
        undef,                         # the url is not required by server
        external_encoding => 'koi8-r', # any encoding, accepted by Encode
        #internal_encoding => 'koi8-r', # not supported for now
    );
    my $xml = do { local $/; <STDIN> };
    length($xml) == $ENV{CONTENT_LENGTH} or warn "Content-Length differs from actually received";
    
    print "Content-type: text/xml; charset=$rpc->{external_encoding}\n\n";
    print $rpc->receive( $xml, sub {
        my ( $methodname, @params ) = @_;
        return { you_called => $methodname, with_params => \@params };
    } );

Make a call to an XML-RPC service:

    use XML::RPC::Fast;
    
    my $rpc = XML::RPC::Fast->new(
        'http://your.hostname/rpc/url'
    );
    
    # Syncronous call
    my @result = $rpc->req(
        call => [ 'examples.getStateStruct', { state1 => 12, state2 => 28 } ],
        url => 'http://...',
    );
    
    # Syncronous call (compatibility method)
    my @result = $rpc->call( 'examples.getStateStruct', { state1 => 12, state2 => 28 } );
    
    # Syncronous or asyncronous call
    $rpc->req(
        call => ['examples.getStateStruct', { state1 => 12, state2 => 28 }],
        cb   => sub {
            my @result = @_;
        },
    );
    
    # Syncronous or asyncronous call (compatibility method)
    $rpc->call( sub {
        my @result = @_;
        
    }, 'examples.getStateStruct', { state1 => 12, state2 => 28 } );
    

=head1 DESCRIPTION

XML::RPC::Fast is format-compatible with XML::RPC, but may use different encoders to parse/compose xml.
Curerntly included encoder uses L<XML::LibXML>, and is 3 times faster than XML::RPC and 75% faster, than XML::Parser implementation

=head1 METHODS

=head2 new ($url, %args)

Create XML::RPC::Fast object, server if url is undef, client if url is defined

=head2 req( %ARGS )

Clientside. Make syncronous or asyncronous call (depends on UA).

If have cb, will invoke $cb with results and should not croak

If have no cb, will return results and croak on error (only syncronous UA)

Arguments are

=over 4

=item call => [ methodName => @args ]

array ref of call arguments. Required

=item cb => $cb->(@results)

Invocation callback. Optional for syncronous UA. Behaviour is same as in call with C<$cb> and without

=item url => $request_url

Alternative invocation URL. Optional. By default will be used defined from constructor

=item headers => { http-headers hashref }

Additional http headers to request

=item external_encoding => '...,

Specify the encoding, used inside XML container just for this request. Passed to encoder

=back

=head2 call( 'method_name', @arguments ) : @results

Clientside. Make syncronous call and return results. Croaks on error. Just a simple wrapper around C<req>

=head2 call( $cb->(@res), 'method_name', @arguments ): void

Clientside. Make syncronous or asyncronous call (depends on UA) and invoke $cb with results. Should not croak. Just a simple wrapper around C<req>

=head2 receive ( $xml, $handler->($methodName,@args) ) : xml byte-stream

Serverside. Process received XML and invoke $handler with parameters $methodName and @args and returns response XML

On error conditions C<$handler> could set C<$XML::RPC::Fast::faultCode> and die, or return C<rpcfault($faultCode,$faultString)>

    ->receive( $xml, sub {
        # ...
        return rpcfault( 3, "Some error" ) if $error_condition
        $XML::RPC::Fast::faultCode = 4 and die "Another error" if $another_error_condition;

        return { call => $methodname, params => \@params };
    })

=head2 registerType

Proxy-method to encoder. See L<XML::RPC::Enc>

=head2 registerClass

Proxy-method to encoder. See L<XML::RPC::Enc>

=head1 OPTIONS

Below is the options, accepted by new()

=head2 ua

Client only. Useragent object, or package name

    ->new( $url, ua => 'LWP' ) # same as XML::RPC::UA::LWP
    # or 
    ->new( $url, ua => 'XML::RPC::UA::LWP' )
    # or 
    ->new( $url, ua => XML::RPC::UA::LWP->new( ... ) )
    # or 
    ->new( $url, ua => XML::RPC::UA::Curl->new( ... ) )

=head2 timeout

Client only. Timeout for calls. Passed directly to UA

    ->new( $url, ua => 'LWP', timeout => 10 )

=head2 useragent

Client only. Useragent string. Passed directly to UA

    ->new( $url, ua => 'LWP', useragent => 'YourClient/1.11' )

=head2 encoder

Client and server. Encoder object or package name

    ->new( $url, encoder => 'LibXML' )
    # or 
    ->new( $url, encoder => 'XML::RPC::Enc::LibXML' )
    # or 
    ->new( $url, encoder => XML::RPC::Enc::LibXML->new( ... ) )

=head2 internal_encoding B<NOT IMPLEMENTED YET>

Specify the encoding you are using in your code. By default option is undef, which means flagged utf-8
For translations is used Encode, so the list of accepted encodings fully derived from it.

=head2 external_encoding

Specify the encoding, used inside XML container. By default it's utf-8. Passed directly to encoder

    ->new( $url, encoder => 'LibXML', external_encoding => 'koi8-r' )

=head1 ACCESSORS

=head2 url

Get or set client url

=head2 encoder

Direct access to encoder object

=head2 ua

Direct access to useragent object

=head1 FUNCTIONS

=head2 rpcfault(faultCode, faultString)

Returns hash structure, that may be returned by serverside handler, instead of die. Not exported by default

=head1 CUSTOM TYPES

=head2 sub {{ 'base64' => encode_base64($data) }}

When passing a CODEREF as a value, encoder will simply use the returned hashref as a type => value pair.

=head2 bless( do{\(my $o = encode_base64('test') )}, 'base64' )

When passing SCALARREF as a value, package name will be taken as type and dereference as a value

=head2 bless( do{\(my $o = { something =>'complex' } )}, 'base64' )

When passing REFREF as a value, package name will be taken as type and L<XML::Hash::LX>C<::hash2xml(deref)> would be used as value

=head2 customtype( $type, $data )

Easily compose SCALARREF based custom type

=cut

use 5.008003; # I want Encode to work
use strict;
use warnings;

#use Time::HiRes qw(time);
use Carp qw(carp croak);

BEGIN {
	eval {
		require Sub::Name;
		Sub::Name->import('subname');
	1 } or do { *subname = sub { $_[1] } };

	no strict 'refs';
	for my $m (qw(url encoder ua)) {
		*$m = sub {
			local *__ANON__ = $m;
			my $self = shift;
			$self->{$m} = shift if @_;
			$self->{$m};
		};
	}
}

our $faultCode = 0;

#sub encoder { shift->{encoder} }
#sub ua      { shift->{ua} }

sub import {
	my $me = shift;
	my $pkg = caller;
	no strict 'refs';
	@_ or return;
	for (@_) {
		if ( $_ eq 'rpcfault' or $_ eq 'customtype') {
			*{$pkg.'::'.$_} = \&$_;
		} else {
			croak "$_ is not exported by $me";
		}
	}
}

sub rpcfault($$) {
	my ($code,$string) = @_;
	return {
		fault => {
			faultCode   => $code,
			faultString => $string,
		},
	}
}
sub customtype($$) {
	my $type = shift;
	my $data = shift;
	bless( do{\(my $o = $data )}, $type )
}

sub _load {
	my $pkg = shift;
	my ($prefix,$req,$default,@args) = @_;
	if (defined $req) {
		my @fail;
		eval {
			require join '/', split '::', $prefix.$req.'.pm';
			$req = $prefix.$req;
			1;
		}
		or do {
			push @fail, [ $prefix.$req,$@ ];
			eval{ require join '/', split '::', $req.'.pm'; 1 }
		}
		or do {
			push @fail, [ $req,$@ ];
			croak "Can't load any of:\n".join("\n\t",map { "$$_[0]: $$_[1]" } @fail)."\n";
		}
	} else {
		eval {
			$req = $prefix.$default;
			require join '/', split '::', $req.'.pm'; 1
		}
		or do {
			croak "Can't load $req: $@\n";
		}
	}
	return $req->new(@args);
}

sub new {
	my $package = shift;
	my $url  = shift;
	local $SIG{__WARN__} = sub { local $_ = shift; s{\n$}{};carp $_ };
	my $self = {
		@_,
	};
	unless ( ref $self->{encoder} ) {
		$self->{encoder} = $package->_load(
			'XML::RPC::Enc::', $self->{encoder}, 'LibXML',
			internal_encoding => $self->{internal_encoding},
			external_encoding => $self->{external_encoding},
		);
	}
	if ( $url and !ref $self->{ua} ) {
		$self->{ua} = $package->_load(
			'XML::RPC::UA::', $self->{ua}, 'LWP',
			ua      => $self->{useragent} || 'XML-RPC-Fast/'.$VERSION,
			timeout => $self->{timeout},
		);
	}
	$self->{url} = $url;
	bless $self, $package;
	return $self;
}

sub registerType {
	shift->encoder->registerType(@_);
}

sub registerClass {
	shift->encoder->registerClass(@_);
}

sub call {
	my $self = shift;
	my $cb;$cb = shift if ref $_[0] and ref $_[0] eq 'CODE';
	$self->req(
		call => [@_],
		$cb ? ( cb => $cb ) : (),
	);
}

sub req {
	my $self = shift;
	my %args = @_;
	my $cb = $args{cb};
	if ($self->ua->async and !$cb) {
		croak("Call have no cb and useragent is async");
	}
	my ( $methodname, @params ) = @{ $args{call} };
	my $url = $args{url} || $self->{url};

	unless ( $url ) {
		if ($cb) {
			$cb->(rpcfault(500, "No url"));
			return;
		} else {
			croak('No url');
		}
	};
	my $uri = "$url#$methodname";

	$faultCode = 0;
	my $body;
	{
		local $self->encoder->{external_encoding} = $args{external_encoding} if exists $args{external_encoding};
		my $newurl;
		($body,$newurl) = $self->encoder->request( $methodname, @params );
		$url = $newurl if defined $newurl;
	}

	$self->{xml_out} = $body;

	#my $start = time;
	my @data;
	#warn "Call $body";
	$self->ua->call(
		($args{method} || 'POST')    => $url,
		$args{headers} ? ( headers => $args{headers} ) : (),
		body    => $body,
		cb      => sub {
			my $res = shift;
			{
				( my $status = $res->status_line )=~ s/:?\s*$//s;
				$res->code == 200 or @data = 
					(rpcfault( $res->code, "Call to $uri failed: $status" ))
					and last;
				my $text = $res->content;
				length($text) and $text =~ /^\s*<\?xml/s or @data = 
					({fault=>{ faultCode => 499,        faultString => "Call to $uri failed: Response is not an XML: \"$text\"" }})
					and last;
				eval {
					$self->{xml_in} = $text;
					@data = $self->encoder->decode( $text );
					1;
				} or @data = 
					({fault=>{ faultCode => 499,     faultString => "Call to $uri failed: Bad Response: $@, \"$text\"" }})
					and last;
			}
			#warn "Have data @data";
			if ($cb) {{
				local $faultCode = $data[0]{fault}{faultCode} if ref $data[0] eq 'HASH' and exists $data[0]{fault};
				$cb->(@data);
				return;
			}}
		},
	);
	$cb and defined wantarray and carp "Useless use of return value for ".__PACKAGE__."->call(cb)";
	return if $cb;
	if ( ref $data[0] eq 'HASH' and exists $data[0]{fault} ) {
		$faultCode = $data[0]{fault}{faultCode};
		croak( "Remote Error [$data[0]{fault}{faultCode}]: ".$data[0]{fault}{faultString} );
	}
	return @data == 1 ? $data[0] : @data;
}

sub receive { # ok
	my $self   = shift;
	my $result = eval {
		my $xml_in = shift or return $self->encoder->fault(400,"Bad Request: No XML");
		my $handler = shift or return $self->encoder->fault(501,"Server Error: No handler");;
		my ( $methodname, @params ) = $self->encoder->decode($xml_in);
		local $self->{xml_in} = $xml_in;
		subname( 'receive.handler.'.$methodname,$handler );
		my @res = $handler->( $methodname, @params );
		if (ref $res[0] eq 'HASH' and exists $res[0]{fault}) {
			$self->encoder->fault( $res[0]{fault}{faultCode},$res[0]{fault}{faultString} );
		} else {
			$self->encoder->response( @res );
		}
	};
	if ($@) {
		(my $e = "$@") =~ s{\r?\n+$}{}s;
		$result = $self->encoder->fault(defined $faultCode ? $faultCode : 500,$e);
	}
	return $result;
}

=head1 BUGS & SUPPORT

Bugs reports and testcases are welcome.

It you write your own Enc or UA, I may include it into distribution

If you have propositions for default custom types (see Enc), send me patches

See L<http://rt.cpan.org> to report and view bugs.

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

# $Id$

package WebService::Validator::HTML::W3C;

use strict;
use base qw( Class::Accessor );
use LWP::UserAgent;
use HTTP::Request::Common 'POST';
use URI::Escape;
use WebService::Validator::HTML::W3C::Error;
use WebService::Validator::HTML::W3C::Warning;

__PACKAGE__->mk_accessors(
    qw( http_timeout validator_uri proxy ua _http_method
      is_valid num_errors num_warnings uri _content _output _response ) );

use vars qw( $VERSION $VALIDATOR_URI $HTTP_TIMEOUT );

$VERSION       = 0.28;
$VALIDATOR_URI = 'http://validator.w3.org/check';
$HTTP_TIMEOUT  = 30;

=head1 NAME

WebService::Validator::HTML::W3C - Access the W3Cs online HTML validator

=head1 SYNOPSIS

    use WebService::Validator::HTML::W3C;

    my $v = WebService::Validator::HTML::W3C->new(
                detailed    =>  1
            );

    if ( $v->validate("http://www.example.com/") ) {
        if ( $v->is_valid ) {
            printf ("%s is valid\n", $v->uri);
        } else {
            printf ("%s is not valid\n", $v->uri);
            foreach my $error ( @{$v->errors} ) {
                printf("%s at line %d\n", $error->msg,
                                          $error->line);
            }
        }
    } else {
        printf ("Failed to validate the website: %s\n", $v->validator_error);
    }

=head1 DESCRIPTION

WebService::Validator::HTML::W3C provides access to the W3C's online
Markup validator. As well as reporting on whether a page is valid it 
also provides access to a detailed list of the errors and where in
the validated document they occur.

=head1 METHODS

=head2 new

    my $v = WebService::Validator::HTML::W3C->new();

Returns a new instance of the WebService::Validator::HTML::W3C object. 

There are various options that can be set when creating the Validator 
object like so:

    my $v = WebService::Validator::HTML::W3C->new( http_timeout => 20 );

=over 4

=item validator_uri

The URI of the validator to use.  By default this accesses the W3Cs validator at http://validator.w3.org/check. If you have a local installation of the validator ( recommended if you wish to do a lot of testing ) or wish to use a validator at another location then you can use this option. Please note that you need to use the full path to the validator cgi.

=item ua    

The user agent to use. Should be an LWP::UserAgent object or something that provides the same interface. If this argument is provided, the C<http_timeout> and C<proxy> arguments are ignored.

=item http_timeout

How long (in seconds) to wait for the HTTP connection to timeout when
contacting the validator. By default this is 30 seconds.

=item detailed

This fetches the XML response from the validator in order to provide information for the errors method. You should set this to true if you intend to use the errors method.

=item proxy

An HTTP proxy to use when communicating with the validation service.

=item output

Controls which output format is used. Can be either xml or soap12.

The default is soap12 as the XML format is deprecated and is likely to be removed in the future.

The default will always work so unless you're using a locally installed Validator you can safely ignore this.

=back 

=cut

sub new {
    my $ref   = shift;
    my $class = ref $ref || $ref;
    my $obj   = {};
    bless $obj, $class;
    $obj->_init(@_);
    return $obj;
}

sub _init {
    my $self = shift;
    my %args = @_;

    $self->http_timeout( $args{http_timeout}   || $HTTP_TIMEOUT );
    $self->validator_uri( $args{validator_uri} || $VALIDATOR_URI );
    $self->ua( $args{ua} );
    $self->_http_method( $args{detailed} ? 'GET' : 'HEAD' );
    $self->_output( $args{output} || 'soap12' );
    $self->proxy( $args{proxy} || '' );
}

=head2 validate

    $v->validate( 'http:://www.example.com/' );

Validate a URI. Returns 0 if the validation fails (e.g if the 
validator cannot be reached), otherwise 1.

=head2 validate_file

    $v->validate_file( './file.html' );

Validate a file by uploading it to the W3C Validator. NB This has only been tested on a Linux box so may not work on non unix machines.

=head2 validate_markup

    $v->validate_markup( $markup );

Validate a scalar containing HTML. 

=head2 Alternate interface

You can also pass a hash in to specify what you wish to validate. This is provided to ensure compatibility with the CSS validator module.

	$v->validate( uri => 'http://example.com/' );
	$v->validate( string => $markup );
	$v->validate( file => './file.html' );
	
=cut

sub validate_file {
    my $self = shift;
    my $file = shift;

    return $self->validator_error("You need to supply a file to validate")
        unless $file;

    return $self->_validate( { file => $file } );
}

sub validate_markup {
    my $self = shift;
    my $markup = shift;

    return $self->validator_error("You need to supply markup to validate")
        unless $markup;

    return $self->_validate( { markup => $markup } );
}

sub validate {
    my $self = shift;

	my ( %opts, $uri );
	if ( scalar( @_ ) > 1 ) {
		%opts = @_;
		
		if ( $opts{ 'uri' } ) {
			$uri = $opts{ 'uri' };	
		} elsif ( $opts{ 'string' } ) {
			return $self->validate_markup( $opts{ 'string' } );
		} elsif( $opts{ 'file' } ) {
			return $self->validate_file( $opts{ 'file' } );
		} else {
			return $self->validator_error( "You need to provide a uri, string or file to validate" );
		}
	} else {
	    $uri = shift;		
	}

    return $self->validator_error("You need to supply a URI to validate")
      unless $uri;

    return $self->validator_error("You need to supply a URI scheme (e.g http)")
      unless $uri =~ m(^.*?://);

    return $self->_validate( $uri );
}

sub _validate {
    my $self = shift;
    my $uri  = shift;

    my $uri_orig = $uri;

	$self->uri($uri_orig);

    my $ua = $self->ua;
    if ( ! $ua ) {
       $ua = LWP::UserAgent->new( agent   => __PACKAGE__ . "/$VERSION",
                                  timeout => $self->http_timeout );

       if ( $self->proxy ) { $ua->proxy( 'http', $self->proxy ); }
    }

    my $request = $self->_get_request( $uri );

    my $response = $ua->request($request);

    if ( $response->is_success )    # not an error, we could contact the server
    {

        # set both valid and error number according to response

		$self->_response( $response );
		
        my $res = $self->_parse_validator_response();
        $self->_content( $response->content() )
          if $self->_http_method() !~ /HEAD/;

        # we know the validator has been able to (in)validate if
        # $self->valid is not NULL

		if ( $res ) {
			return 1;
		} else {
			return 0;
		}
    }
    else {
        return $self->validator_error('Could not contact validator');
    }
}

=head2 is_valid 

    $v->is_valid;

Returns true (1) if the URI validated otherwise 0.


=head2 uri

    $v->uri();

Returns the URI of the last page on which validation succeeded.


=head2 num_errors

    $num_errors = $v->num_errors();

Returns the number of errors that the validator encountered.

=head2 errorcount

Synonym for num_errors. There to match CSS Validator interface.

=head2 warningcount 

    $num_errors = $v->warningcount();

Returns the number of warnings that the validator encountered.

=head2 errors

    $errors = $v->errors();
    
    foreach my $err ( @$errors ) {
        printf("line: %s, col: %s\n\terror: %s\n", 
                $err->line, $err->col, $err->msg);
    }

Returns an array ref of WebService::Validator::HTML::W3C::Error objects.
These have line, col and msg methods that return a line number, a column 
in that line and the error that occurred at that point.

Note that you need XML::XPath for this to work and you must have initialised
WebService::Validator::HTML::W3C with the detailed option. If you have not
set the detailed option a warning will be issued, the detailed option will
be set and a second request made to the validator in order to fetch the
required information. 

If there was a problem processing the detailed information then this method 
will return 0.

=head2 warnings

    $warnings = $v->warnings();

Works exactly the same as errors only returns an array ref of 
WebService::Validator::HTML::W3C::Warning objects. In all other respects it's the same.

=cut

sub errors {
    my $self = shift;

    return undef unless $self->num_errors();

    unless ( $self->_http_method() eq 'GET' ) {
        warn "You should set detailed when initalising if you intend to use the errors method";
        $self->_http_method( 'GET' );
        $self->validate( $self->uri() );
    }

    my @errs;

    eval { require XML::XPath; };
    if ($@) {
        warn "XML::XPath must be installed in order to get detailed errors";
        return undef;
    }

    my $xp       = XML::XPath->new( xml => $self->_content() );

    if ( $self->_output eq 'xml' ) {
        if ( ! $xp->findnodes('/result') ) {
            return $self->validator_error( 'Result format does not appear to be XML' );
        }
        my @messages = $xp->findnodes('/result/messages/msg');

        foreach my $msg (@messages) {
            my $err = WebService::Validator::HTML::W3C::Error->new({
                          line => $msg->getAttribute('line'),
                          col  => $msg->getAttribute('col'),
                          msg  => $msg->getChildNode(1)->getValue(),
                      });

            push @errs, $err;
        }
    } else { # assume soap...
        if ( ! $xp->findnodes('/env:Envelope') ) {
            return $self->validator_error( 'Result format does not appear to be SOAP' );
        }
       my @messages = $xp->findnodes( '/env:Envelope/env:Body/m:markupvalidationresponse/m:errors/m:errorlist/m:error' );

       foreach my $msg ( @messages ) {
           my $err = WebService::Validator::HTML::W3C::Error->new({ 
                          line          => $xp->find( './m:line', $msg )->get_node(1)->getChildNode(1)->getValue,
                          col           => $xp->find( './m:col', $msg )->get_node(1)->getChildNode(1)->getValue,
                          msg           => $xp->find( './m:message', $msg )->get_node(1)->getChildNode(1)->getValue,
                          msgid         => $xp->find( './m:messageid', $msg )->get_node(1)->getChildNode(1)->getValue,
                          explanation   => $xp->find( './m:explanation', $msg )->get_node(1)->getChildNode(1)->getValue,
                      });
                  
            if ( $xp->find( './m:source' ) ) {
                $err->source( $xp->find( './m:source', $msg )->get_node(1)->getChildNode(1)->getValue );
            }

            push @errs, $err;
        }
    }

    return \@errs;
}

sub errorcount {
	shift->num_errors;
}

sub warningcount {
    shift->num_warnings;
}

sub warnings {
    my $self = shift;

    unless ( $self->_http_method() eq 'GET' ) {
        warn "You should set detailed when initalising if you intend to use the warnings method";
        $self->_http_method( 'GET' );
        $self->validate( $self->uri() );
    }


    eval { require XML::XPath; };
    if ($@) {
        warn "XML::XPath must be installed in order to get warnings";
        return undef;
    }

    my $xp       = XML::XPath->new( xml => $self->_content() );

    my @warnings;

    if ( $self->_output eq 'soap12' ) {
        if ( ! $xp->findnodes('/env:Envelope') ) {
            return $self->validator_error( 'Result format does not appear to be SOAP' );
        }
        my @messages = $xp->findnodes( '/env:Envelope/env:Body/m:markupvalidationresponse/m:warnings/m:warninglist/m:warning' );

        foreach my $msg ( @messages ) {
            my ($line, $col);

            if( ($line = $xp->findvalue('./m:line', $msg)) eq "") {
                $line = undef;
            }

            if( ($col = $xp->findvalue('./m:col', $msg)) eq "") {
                $col = undef;
            }

            my $warning = WebService::Validator::HTML::W3C::Warning->new({ 
                          line   => $line,
                          col    => $col,
                          msg    => $xp->find( './m:message', $msg )->get_node(1)->getChildNode(1)->getValue,
                      });

            # we may not get a source element if, e.g the only error is a
            # missing doctype so check first
            if ( $xp->find( './m:source' ) ) {
                $warning->source( $xp->find( './m:source', $msg )->get_node(1)->getChildNode(1)->getValue );
            }

            push @warnings, $warning;
        }
        return \@warnings;
    } else {
        return $self->validator_error( 'Warnings only available with SOAP output format' );

    }
}

=head2 validator_error

    $error = $v->validator_error();

Returns a string indicating why validation may not have occurred. This is not
the reason that a webpage was invalid. It is the reason that no meaningful 
information about the attempted validation could be obtained. This is most
likely to be an HTTP error

Possible values are:

=over 4

=item You need to supply a URI to validate

You didn't pass a URI to the validate method

=item You need to supply a URI with a scheme

The URI you passed to validate didn't have a scheme on the front. The 
W3C validator can't handle URIs like www.example.com but instead
needs URIs of the form http://www.example.com/.

=item Not a W3C Validator or Bad URI

The URI did not return the headers that WebService::Validator::HTML::W3C 
relies on so it is likely that there is not a W3C Validator at that URI. 
The other possibility is that it didn't like the URI you provided. Sadly
the Validator doesn't give very useful feedback on this at the moment.

=item Could not contact validator

WebService::Validator::HTML::W3C could not establish a connection to the URI.

=item Did not get a sensible result from the validator

Should never happen and most likely indicates a problem somewhere but
on the off chance that WebService::Validator::HTML::W3C is unable to make
sense of the response from the validator you'll get this error.

=item Result format does not appear to be SOAP|XML

If you've asked for detailed results and the reponse from the validator 
isn't in the expected format then you'll get this error. Most likely to 
happen if you ask for SOAP output from a validator that doesn't
support that format.

=item You need to provide a uri, string or file to validate

You've passed in a hash ( or in fact more than one argument ) to validate
but the hash does not contain one of the three expected keys.

=back

=cut

sub validator_error {
    my $self            = shift;
    my $validator_error = shift;

    if ( defined $validator_error ) {
        $self->{'validator_error'} = $validator_error;
        return 0;
    }

    return $self->{'validator_error'};
}

=head2 validator_uri

    $uri = $v->validator_uri();
    $v->validator_uri('http://validator.w3.org/check');

Returns or sets the URI of the validator to use. Please note that you need
to use the full path to the validator cgi.


=head2 http_timeout

    $timeout = $v->http_timeout();
    $v->http_timeout(10);

Returns or sets the timeout for the HTTP request.

=cut

sub _construct_uri {
    my $self            = shift;
    my $uri_to_validate = shift;

    # creating the HTTP query string with all parameters
    my $req_uri =
      join ( '', "?uri=", uri_escape($uri_to_validate), ";output=", $self->_output );

    return $self->validator_uri . $req_uri;
}

sub _parse_validator_response {
    my $self     = shift;
    my $response = $self->_response();

    my $valid         = $response->header('X-W3C-Validator-Status');
    my $valid_err_num = $response->header('X-W3C-Validator-Errors');
    $self->num_warnings($response->header('X-W3C-Validator-Warnings'));

    # remove non digits to fix output bug in some versions of validator
    $valid_err_num =~ s/\D+//g if $valid_err_num;

    if ( $valid and $valid_err_num ) {
        $self->is_valid(0);
        $self->num_errors($valid_err_num);
        return 1;
    }
    elsif ( !defined $valid ) {
        return $self->validator_error('Not a W3C Validator or Bad URI');
    }
    elsif ( $valid =~ /\bvalid\b/i ) {
        $self->is_valid(1);
        $self->num_errors($valid_err_num);
        return 1;
    }

    return $self->validator_error(
                        'Did not get a sensible result from the Validator');
}

sub _get_request {
    my $self = shift;
    my $uri = shift;

    if ( ref $uri ) {
        if ( $uri->{ file } ) {
            return POST $self->validator_uri, 
                        Content_Type  =>  'form-data', 
                        Content       =>  [
                                           output => $self->_output,
                                           uploaded_file => [ $uri->{ file } ],
                                          ];
        } elsif ( $uri->{ markup } ) {
            return POST $self->validator_uri, 
                        Content_Type  =>  'form-data', 
                        Content       =>  [
                                           output => $self->_output,
                                           fragment => $uri->{ markup },
                                          ];
        }
    } else {
        return new HTTP::Request( $self->_http_method(), $self->_construct_uri( $uri ) );
    }
}
        
1;

__END__

=head1 OTHER MODULES

Please note that there is also an official W3C module that is part of the
L<W3C::LogValidator> distribution. However that module is not very useful outside
the constraints of that package. WebService::Validator::HTML::W3C is meant as a more general way to access the W3C Validator.

L<HTML::Validator> uses nsgmls to validate against
the W3Cs DTDs. You have to fetch the relevant DTDs and so on.

There is also the L<HTML::Parser> based L<HTML::Lint> which mostly checks for 
known tags rather than XML/HTML validity.

L<WebService::Validator::CSS::W3C> provides the same functionality as this module
for the W3C's CSS validator. 

=head1 IMPORTANT

This module is not in any way associated with the W3C so please do not 
report any problems with this module to them. Also please remember that
the online Validator is a shared resource so do not abuse it. This means
sleeping between requests. If you want to do a lot of testing against it
then please consider downloading and installing the Validator software
which is available from the W3C. Debian testing users will also find that 
it is available via apt-get.

=head1 BUGS

While the interface to the Validator is fairly stable it may be 
updated. I will endeavour to track any changes with this module so please
check on CPAN for new versions if you find things break. Also note that this 
module is only guaranteed to work with the currently stable version of the 
validator. It will most likely work with any Beta versions but don't rely 
on it.

If in doubt please try and run the test suite before reporting bugs. Note
that in order to run tests against the validator service you will need to
have a connection to the internet and also set an environment variable called
TEST_AUTHOR.

That said I'm very happy to hear about bugs. All the more so if they come
with patches ;).

Please use L<http://rt.cpan.org/> for filing bug reports, and indeed feature
requests. The code can also be found on L<github|https://github.com/struan/webservice-validator-html-w3c>.

=head1 THANKS

To the various people on the code review ladder mailing list who 
provided useful suggestions.

Carl Vincent provided a patch to allow for proxy support.

Chris Dolan provided a patch to allow for custom user agents.

Matt Ryder provided a patch for support of the explanations in the SOAP output. 

=head1 SUPPORT

author email or via L<http://rt.cpan.org/>.

=head1 AUTHOR

Struan Donald E<lt>struan@cpan.orgE<gt>

L<http://www.exo.org.uk/code/>

=head1 COPYRIGHT

Copyright (C) 2003-2008 Struan Donald. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut


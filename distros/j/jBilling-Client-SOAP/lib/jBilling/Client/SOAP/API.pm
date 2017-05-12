package jBilling::Client::SOAP::API;
use strict;
use warnings;
use jBilling::Client::SOAP::Exception ( VERBOSE => 1 );
use 5.010;
our $VERSION =  0.02;
#use SOAP::Lite +trace => [ transport => sub { print $_[0]->as_string } ];
use SOAP::Lite;
sub new {
    my $class = shift;
    my $self  = {};
    bless( $self, $class );
    my %input = @_;

    if (    (defined($input{'url'}) and $input{'url'} ne '')
	and (defined($input{'username'}) and $input{'username'} ne '')
	and (defined($input{'password'}) and $input{'password'} ne '')
       )
    {

	# All needed values are supplied
        my %address = $self->stripURL( $input{'url'} ); # Strip the URL Parts
	my $proxyurl =
	    $address{'protocol'}
	  . $input{'username'} . ':'
	  . $input{'password'} . '@'
	  . $address{'url'}; # Assemble the proxy URL
	my $soap =
	  SOAP::Lite->new->proxy($proxyurl)
	  ->ns( 'http://jbilling.com/', 'jbilling' )
	  ->readable('1')
	  ->on_fault( sub { my($soap, $res) = @_;
			    throw jBilling::Client::SOAP::Exception $res->faultstring . " : " . $soap->transport->status; }
	); # Initiate a new SOAP::Lite object
	return $soap; # Return the object
    }
    else {
	throw jBilling::Client::SOAP::Exception 'Username, Password and URL are needed but not supplied!';
    }
}


sub stripURL {

    # This function stips HTTP/S etc from url and stores for re-assembly
    my $self  = shift;
    my $input = shift;
    my %parts;
    $input =~ m/(https:\/\/|http:\/\/)/;

    if ($1) {

	# This is the value we are removing so need to put back
	$parts{'protocol'} = $1;
    }
    $input =~ s/(https:\/\/|http:\/\/)//;
    $parts{'url'} = $input;

    # Return the hash contining the protocol and remaining URL parts.
    return %parts;
}
1;

=pod

=encoding UTF-8

=head1 NAME

jBilling::Client::SOAP::API

=head1 VERSION

version 0.02

=head1 AUTHOR

Aaron Guise <guisea@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aaron Guise.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

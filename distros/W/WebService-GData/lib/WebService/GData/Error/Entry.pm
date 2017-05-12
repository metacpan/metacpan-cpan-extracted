package WebService::GData::Error::Entry;
use WebService::GData 'private';
use base 'WebService::GData';

our $VERSION  = 1.02;

WebService::GData::install_in_package([qw(internalreason domain code location)],
	sub {
		my $func=shift;
	    return sub {
			my $this = shift;
			if(@_==1){
				$this->{$func}=$_[0];
			}
			return $this->{$func};
		};
});

	sub __init {
		my ($this,$xmlerror) = @_;
		$this->_parse($xmlerror);
	}

	sub serialize {
		my $this = shift;
		my $xml='<error>';
		   $xml.='<internalreason>'.$this->internalreason.'</internalreason>' if($this->internalreason);
		   $xml.='<code>'.$this->code.'</code>' if($this->code);
		   $xml.='<domain>'.$this->domain.'</domain>' if($this->domain);	
		   $xml.="<location type='".$this->location->{type}."'>".$this->location->{content}.'</location>' if($this->location);
	       $xml.='</error>';
		return $xml;
	}
	
	private _parse => sub {
		my ($this,$error) = @_;
		if($error){
			my ($domain)  = $error=~m/<domain>(.+?)<\/domain>/;
			my ($code)    = $error=~m/<code>(.+?)<\/code>/;
			my $location  = {};
			($location->{type})    = $error=~m/<location\s+type='(.+?)'>/gmxi;

			($location->{content}) = $error=~m/'>(.+?)<\/location>/gmxi;
			my ($internalreason)   = $error=~m/<internalreason>(.+?)<\/internalreason>/gmxi;
			$this -> code($code);
			$this -> internalreason($internalreason);
			$this -> domain($domain);
			$this -> location($location);
		}
	};

"The earth is blue like an orange.";

__END__

=pod

=head1 NAME

WebService::GData::Error::Entry - Wrap an xml error sent back by Google data APIs v2.


=head1 SYNOPSIS

    use WebService::GData::Error;

    #parse an error from a Google data API server...
    my $entry = new WebService::GData::Error::Entry($xmlerror);
    $entry->code;
    $entry->internalreason;
    $entry->domain;
    $entry->location->{type};#this is just a hash
    $entry->location->{content};#this is just a hash

    #create an error from a Google data API server...
    my $entry = new WebService::GData::Error::Entry();
    $entry->code('too_long');
    $entry->domain('your_domain');
    $entry->location({type=>'header',content=>'Missing Version header'});
    print $entry->serialize()#return <error>...</error> 




=head1 DESCRIPTION

I<inherits from L<WebService::GData>>

This package can parse error response from Google APIs service. You can also create your own basic xml error.
All WebService::GData::* classes die a WebService::GData::Error object when something went wrong.

XML error Example:

    <error>
         <domain>yt:validation</domain>
         <code>invalid_character</code>
         <location type='xpath'>media:group/media:title/text()</location>
    </error>

Example:

    use WebService::GData::Error;

    #parse an error from a Google data API server...
    my $entry = new WebService::GData::Error::Entry($xmlerror);
    $entry->code;
    $entry->internalreason;
    $entry->domain;
    $entry->location->{type};#this is just a hash
    $entry->location->{content};#this is just a hash

    #create an error from a Google data API server...
    my $entry = new WebService::GData::Error::Entry();
    $entry->code('too_long');
    $entry->domain('your_domain');
    $entry->location({type=>'header',content=>'Missing Version header'});



=head2 Constructor

=head3 new 

=over

Create a L<WebService::GData::Error::Entry> instance.
If the content is an xml following the Google data API format, it will get parse.


B<Parameters>

=over 4

=item C<content:Scalar>(optional)

=back

B<Returns> 

=over 4 

=item L<WebService::GData::Error::Entry>

=back

=back


=head2 GET/SET METHODS

These methods return their content if no parameters is passed or set their content if a parameter is set.

=head3 code

=over

Get/set an error code.

B<Parameters>

=over 4

=item C<none> - Work as a getter

=item C<content:Scalar> - Work as a setter

=back

B<Returns> 

=over 4 

=item C<content:Scalar> (as a getter)

=back

=back


=head3 location

=over

Get/set the error location as an xpath.It requires a ref hash with type and content as keys.

B<Parameters>

=over 4

=item C<none> - Work as a getter

=item C<content:HashRef> - Work as a setter. the hash must be in contain the following : {type=>'...',content=>'...'}.

=back

B<Returns> 

=over 4 

=item C<content:HashRef> (as a getter)

=back

Example:

    $error->location({type=>'invalid_character',content=>'The string contains an unsupported character.'});

=back

=head3 domain

=over

Get/set the type of error. Google data API has validation,quota,authentication,service errors.

B<Parameters>

=over 4

=item C<none> - Work as a getter

=item C<content:Scalar> - Work as a setter. 

=back

B<Returns> 

=over 4 

=item C<content:Scalar> (as a getter)

=back

=back


=head3 serialize

=over

Send back an xml representation of an error.

B<Parameters>

=over 4

=item C<none>

=back

B<Returns> 

=over 4

=item C<content:Scalar> -  xml representation of the error.

=back

=back

=head2 SEE ALSO

XML format overview and explanation of the different kind of errors you can encounter:

L<http://code.google.com/intl/en/apis/youtube/2.0/developers_guide_protocol_error_responses.html>


=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
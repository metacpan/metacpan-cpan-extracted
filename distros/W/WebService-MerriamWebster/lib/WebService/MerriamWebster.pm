package WebService::MerriamWebster;
use v5.10;
our $VERSION = '0.11';
use Moose;
use XML::LibXML;
use URI::Escape;

has 'dict' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has 'word' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has 'key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

## the query format
## http://www.dictionaryapi.com/api/v1/references/$dic/xml/$word?key=$key

has 'url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        "http://www.dictionaryapi.com/api/v1/references/"
          . uri_escape( $self->dict ) . "/xml/"
          . uri_escape( lc $self->word ) . "?key=" #enforce lowercase 
          . uri_escape( $self->key );
    }
);

has 'raw_xml' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_raw_xml',
);

sub _build_raw_xml {
    use HTTP::Tiny;
    my $self     = shift;
    my $response = HTTP::Tiny->new->get( $self->url );
    die "Failed!\n" unless $response->{success};
    $response->{content} if length $response->{content};
}

has 'dom' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $xml = shift->raw_xml;
        my $dom = XML::LibXML->load_xml( string => $xml );
    },
);

sub entries {
    my $self    = shift;
    my @entries = $self->dom->getElementsByTagName("entry");
}

#In the XML, audio references look like this:
#<wav>heart001.wav</wav>

#These need to be converted to a URL like this:
#http://media.merriam-webster.com/soundc11/h/heart001.wav

#Start with the base URL: http://media.merriam-webster.com/soundc11/
#Add the first letter of the wav file as a subdirectory ("h" in the example above).*
#Add the name of the wav file.
#* Regarding the subdirectory element of the URL there are three exceptions:

#If the file name begins with "bix", the subdirectory should be "bix".
#If the file name begins with "gg", the subdirectory should be "gg".
#If the file name begins with a number, the subdirectory should be "number".

sub _subdir {
    my $filename = shift;
    if ( $filename =~ /^bix/ )     { return "bix" }
    if ( $filename =~ /^gg/ )      { return "gg" }
    if ( $filename =~ /^(\d+).*/ ) { return $1 }
    return substr $filename, 0, 1;
}

sub audio_url {
    my $self = shift;
    my $tag = $self->dom->getElementsByTagName("wav") or die "can not find the audio uril for " .  $self->word;
    my $wave = $tag->[0]->string_value;
    "http://media.merriam-webster.com/soundc11/" . _subdir($wave) . "/$wave";
}

1;
__END__

=encoding utf-8

=head1 NAME 

WebService::MerriamWebster - use Merriam-Webster dictionary API in Perl 

=begin html

<a href="https://travis-ci.org/swuecho/WebService_MerriamWebster"><img src="https://travis-ci.org/swuecho/WebService_MerriamWebster.svg?branch=0.09"></a>

=end html

=head1 SYNOPSIS

	use WebService::MerriamWebster;
	my $mw = WebService::MerriamWebster->new(dict => "collegiate", word => "$the-word-to-query", key => "$your-key-here");
	my $xml = $mw->raw_xml;	 # a string
	my $dom = $mw->dom; # XML::LibXML::Document
	my @entries = $mw->entries(); # @entries is list of XML::LibXML::Element
	my $audio_uri = $mw->audio_url;  # ex. http://media.merriam-webster.com/soundc11/t/test0001.wav
	

=head1 DESCRIPTION

WebService::MerriamWebster is an api to merriam-webster.com dictionary. It gives you xml result based on your query.
it use XML::LibXML to process the XML result (very basic). If you need to get the value of specific node, probably
you need to deal with the xml yourself.  


=head1 Attributes

=head2 dict

	has 'dict' => (
    		is => 'rw',
    		isa => 'Str',
    		required => 1
	);

the dictionary you want to use

=head2 word

	has 'word' => (
	    is => 'rw',
	    isa => 'Str',
	    required => 1
	);

the word to query

=head2 key

	has 'key' => (
	    is => 'ro',
	    isa => 'Str',
	    required => 1
	);

=head2 url 

the query url based on $dict, $word, $key

	reference: http://www.dictionaryapi.com/api/v1/references/$dic/xml/$word?key=$key

=head2 raw_xml

the xml you get based on your query


=head2 dom

the dom (XML::LibXML::Document) base on your query  

=head1 Method

=head2 entries

the @entries of dom 

=head2 audio_url 

the audio url of the query word
    
=head1 AUTHOR

Hao Wu E<lt>echowuhao@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Hao Wu

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::LibXML>

=cut

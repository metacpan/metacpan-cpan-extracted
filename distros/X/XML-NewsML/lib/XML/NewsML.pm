package XML::NewsML;

use vars qw ($VERSION);
$VERSION = '0.5';

use XML::LibXML;

sub new {
	my $who = shift;
	my %args = @_;

	my $class = ref $who || $who;
	my $this = {
		provider => $args{provider},
		timezone => $args{timezone} || 'Z',
	};
	bless $this, $class;

	$this->{datetime} = $args{datetime} . $this->{timezone} || $this->datetime(),
	$this->_create_doc();

	return $this;
}

sub toString {
	my $this = shift;

	return $this->{document}->toString(1);
}

sub addNews {
	my $this = shift;
	my %args = @_;

	$args{datetime} = $this->datetime() unless $args{datetime};
	$args{id} = 1 unless $args{id};
	$args{revision} = 1 unless $args{revision};

	my $NewsItem = new XML::LibXML::Element('NewsItem');
	$this->{root}->appendChild($NewsItem);

	my $Identification = new XML::LibXML::Element('Identification');
	$NewsItem->appendChild($Identification);

	my $NewsIdentifier = new XML::LibXML::Element('NewsIdentifier');
	$Identification->appendChild($NewsIdentifier);

	my $ProviderId = new XML::LibXML::Element('ProviderId');
	$ProviderId->appendText($this->{provider});
	$NewsIdentifier->appendChild($ProviderId);

	my $DateId = new XML::LibXML::Element('DateId');
	$DateId->appendText(substr $args{datetime}, 0, 8);
	$NewsIdentifier->appendChild($DateId);

	my $NewsItemId = new XML::LibXML::Element('NewsItemId');
	$NewsItemId->appendText($args{id});
	$NewsIdentifier->appendChild($NewsItemId);

	my $RevisionId = new XML::LibXML::Element('RevisionId');
	$RevisionId->appendText($args{revision});
	$RevisionId->setAttribute('PreviousRevision', '0');
	$RevisionId->setAttribute('Update', 'N');
	$NewsIdentifier->appendChild($RevisionId);

	my $PublicIdentifier = new XML::LibXML::Element('PublicIdentifier');
	$NewsIdentifier->appendChild($PublicIdentifier);


	my $NewsManagement = new XML::LibXML::Element('NewsManagement');
	$NewsItem->appendChild($NewsManagement);

	my $NewsItemType = new XML::LibXML::Element('NewsItemType');
	$NewsItemType->setAttribute('FormalName', 'News');
	$NewsManagement->appendChild($NewsItemType);

	my $FirstCreated = new XML::LibXML::Element('FirstCreated');
	$FirstCreated->appendText($args{datetime} . $this->{timezone});
	$NewsManagement->appendChild($FirstCreated);

	my $ThisRevisionCreated = new XML::LibXML::Element('ThisRevisionCreated');
	$ThisRevisionCreated->appendText($args{datetime} . $this->{timezone});
	$NewsManagement->appendChild($ThisRevisionCreated);

	my $Status = new XML::LibXML::Element('Status');
	$Status->setAttribute('FormalName', 'Usable');
	$NewsManagement->appendChild($Status);


	my $NewsComponent = new XML::LibXML::Element('NewsComponent');
	$NewsItem->appendChild($NewsComponent);

	my $NewsLines = new XML::LibXML::Element('NewsLines');
	$NewsComponent->appendChild($NewsLines);

	my $HeadLine = new XML::LibXML::Element('HeadLine');
	$HeadLine->appendText($args{title});
	$NewsLines->appendChild($HeadLine);

	my $KeywordLine = new XML::LibXML::Element('KeywordLine');
	$KeywordLine->appendText($args{keywords});
	$NewsLines->appendChild($KeywordLine);


	my $ContentItem = new XML::LibXML::Element('ContentItem');
	$NewsComponent->appendChild($ContentItem);
	
	my $MediaType = new XML::LibXML::Element('MediaType');
	$MediaType->setAttribute('FormalName', 'Text');
	$ContentItem->appendChild($MediaType);

	my $MimeType = new XML::LibXML::Element('MimeType');
	$MimeType->setAttribute('FormalName', 'text/plain');
	$ContentItem->appendChild($MimeType);

	my $Format = new XML::LibXML::Element('Format');
	$Format->setAttribute('FormalName', 'Text');
	$ContentItem->appendChild($Format);

	my $DataContent = new XML::LibXML::Element('DataContent');
	$DataContent->appendText($args{content});
	$ContentItem->appendChild($DataContent);

	if ($args{image}) {
		if (ref $args{image} eq 'ARRAY') {
			foreach (@{$args{image}}) {
				$NewsComponent->appendChild($this->_image_node($_));
			}
		}
		else {
			$NewsComponent->appendChild($this->_image_node($args{image}));
		}
	}
}

sub _image_node {
	my $this = shift;
	my $uri = shift;

	my $ContentItem = new XML::LibXML::Element('ContentItem');
	$ContentItem->setAttribute('Href', $uri);
	
	my $MediaType = new XML::LibXML::Element('MediaType');
	$MediaType->setAttribute('FormalName', 'Photo');
	$ContentItem->appendChild($MediaType);
	
	my $MimeType = new XML::LibXML::Element('MimeType');

	my $mimetype = 'image/';
	my $formalname;
	if ($uri =~ /\.jpe?g$/i){$mimetype .= 'jpeg'; $formalname = 'JPEG Baseline';}
	elsif ($uri =~ /\.gif$/i){$mimetype .= 'gif'; $formalname = 'GIF';}
	elsif ($uri =~ /\.png$/i){$mimetype .= 'png'; $formalname = 'PNG';}

	$MimeType->setAttribute('FormalName', $mimetype);
	$ContentItem->appendChild($MimeType);

	my $Format = new XML::LibXML::Element('Format');
	$Format->setAttribute('FormalName', $formalname);
	$ContentItem->appendChild($Format);

	return $ContentItem;
}

sub _mime_type {
}

sub _create_doc {
	my $this = shift;

	$this->{document} = new XML::LibXML::Document;

	$this->{root} = new XML::LibXML::Element('NewsML');
	$this->{document}->setDocumentElement($this->{root});

	$this->{root}->appendChild($this->_envelope_node());
}

sub datetime {
	$this = shift;

	my ($sec, $min, $hour, $mday, $mon, $year);
	if (@_) {
		($sec, $min, $hour, $mday, $mon, $year) = @_;
	}
	else {
		($sec, $min, $hour, $mday, $mon, $year) = localtime time;
		$year += 1900;
		$mon++;
	}

	return sprintf "%4i%02i%02iT%02i%02i%02i%s", $year, $mon, $mday, $hour, $min, $sec, $this->{timezone};
}

sub _envelope_node {
	my $this = shift;

	my $NewsEnvelope = new XML::LibXML::Element('NewsEnvelope');
	
	my $DateAndTime = new XML::LibXML::Element('DateAndTime');
	$DateAndTime->appendText($this->{datetime});
	
	my $Priority = new XML::LibXML::Element('Priority');
	$Priority->setAttribute('FormalName', '1');
	
	my $NewsProduct = new XML::LibXML::Element('NewsProduct');
	$NewsProduct->setAttribute('FormalName', '1');

	$NewsEnvelope->appendChild($DateAndTime);
	$NewsEnvelope->appendChild($Priority);
	$NewsEnvelope->appendChild($NewsProduct);

	return $NewsEnvelope;
}

1;

__END__
=head1 NAME

XML::NewsML - Simple interface for creating NewsML documents

=head1 SYNOPSIS

	use XML::NewsML;

	my $newsml = new XML::NewsML(
		provider	=> 'example.com',
		timezone	=> '+0300',
	);

	$newsml->addNews(
		datetime	=> '20070913T102417',
		title		=> 'News Title',
		keywords	=> 'keyword line, first',
		content		=> 'News Content',
	);

	$newsml->addNews(
		title		=> 'News Title 2',
		keywords	=> 'keyword line, second',
		content		=> 'News Content 2',
		image		=> '/img/x.jpg',
	);

	$newsml->addNews(
		datetime	=> undef,
		title		=> 'News Title 3',
		keywords	=> 'alpha, beta, gamma',
		content		=> 'News Content 2',
		image		=> ['/img/y.jpg', '/img/z.png'],
	);

=head1 ABSTRACT

XML::NewsML helps creating very simple NewsML documents which contain text 
combined with common web graphics.

=head1 DESCRIPTION

XML::NewsML supports only a tiny part of the entire specification published 
at www.newsml.org. Anyhow it provides valid XML code that may be used 
for news exchange.

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE

XML::NewsML module is a free software. 
You may redistribute and (or) modify it under the same terms as Perl.

=cut

package Web::Sitemap::Url;

our $VERSION = '0.012';

use strict;
use warnings;
use utf8;


sub new {
	my ($class, $data, %p) = @_;
	
	my $self = {
		mobile     => $p{mobile} || 0,
		loc_prefix => $p{loc_prefix} || ''
	};

	if (not ref $data) {
		$self->{loc} = $data;
	}
	elsif (ref $data eq 'HASH') {
		unless (defined $data->{loc}) {
			die __PACKAGE__.'->new($data): not defined $data->{loc}';
		}
		$self = { %$self, %$data };
	}
	else {
		die __PACKAGE__. '->new($data): $data must be scalar or hash ref';
	}

	return bless $self, $class;
}

sub to_xml_string {
	my ($self, %p) = @_;

	return sprintf(
		"\n<url><loc>%s%s</loc>%s%s%s</url>", 
			$self->{loc_prefix}, 
			$self->{loc}, 
			$self->{changefreq} ? sprintf('<changefreq>%s</changefreq>', $self->{changefreq}) : '',
			$self->{mobile}     ? '<mobile:mobile/>' : '',
			$self->_images_xml_string
	);
}

sub _images_xml_string {
	my ($self) = @_;
	
	my $result = '';

	if (defined $self->{images}) {
		my $i = 1;
		for my $image (@{$self->{images}->{loc_list}}) {
			my $loc = ref $image eq 'HASH' ? $image->{loc} : $image;
			
			my $caption = '';
			if (ref $image eq 'HASH' and defined $image->{caption}) {
				$caption = $image->{caption};
			}
			elsif (defined $self->{images}->{caption_format_simple}) {
				$caption = $self->{images}->{caption_format_simple}. " $i";
			}
			elsif (defined $self->{images}->{caption_format}) {
				$caption = &{$self->{images}->{caption_format}}($i);
			}

			$result .= sprintf(
				"\n<image:image><loc>%s</loc><caption><![CDATA[%s]]></caption></image:image>",
				$loc, $caption
			);
			$i++;
		}
	}

	return $result;
}

1

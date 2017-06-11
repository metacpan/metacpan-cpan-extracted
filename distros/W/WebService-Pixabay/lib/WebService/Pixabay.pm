package WebService::Pixabay;

use Modern::Perl '2009';
use Moo;
use Function::Parameters;
use Data::Dumper 'Dumper';

with 'WebService::Client';

# ABSTRACT: Perl 5 interface to Pixabay API.
our $VERSION = '2.0.1';    our $VERSION = '2.0.1'; # VERSION

# token key
has api_key => (
    is       => 'ro',
    required => 1
);

has '+base_url' => ( default => 'https://pixabay.com/api/' );

# get image metadata from JSON
method image_search(
    : $q              = "yellow flower",
    : $lang           = "en",
    : $id             = "",
    : $response_group = "image_details",
    : $image_type     = "all",
    : $orientation    = "all",
    : $category       = "",
    : $min_width      = 0,
    : $min_height     = 0,
    : $editors_choice = "false",
    : $safesearch     = "false",
    : $order          = "popular",
    : $page           = 1,
    : $per_page       = 20,
    : $callback       = "",
    : $pretty         = "false"
  )
{
	return $self->get(
                "?key="
              . $self->api_key
              . "&q=$q&lang=$lang&id=$id&response_group=$response_group&image_type=$image_type"
              . "&orientation=$orientation&category=$category&min_width=$min_width&mind_height=$min_height"
              . "&editors_choice=$editors_choice&safesearch=$safesearch&order=$order&page=$page"
              . "&per_page=$per_page&callback=$callback&pretty=$pretty"
        );
}

# get image metadata from JSON
method video_search(
    : $q              = "yellow flower",
    : $lang           = "en",
    : $id             = "",
    : $video_type     = "all",
    : $category       = "",
    : $min_width      = 0,
    : $min_height     = 0,
    : $editors_choice = "false",
    : $safesearch     = "false",
    : $order          = "popular",
    : $page           = 1,
    : $per_page       = 20,
    : $callback       = "",
    : $pretty         = "false"
  )
{
	return $self->get(
                "videos/?key="
              . $self->api_key
              . "&q=$q&lang=$lang&id=$id&video_type=$video_type"
              . "&category=$category&min_width=$min_width&mind_height=$min_height"
              . "&editors_choice=$editors_choice&safesearch=$safesearch&order=$order&page=$page"
              . "&per_page=$per_page&callback=$callback&pretty=$pretty"
        );
}

# pretty print the JSON data structure
method show_data_structure($method_name) {
    print Dumper $method_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Pixabay - Perl 5 interface to Pixabay API.

=head1 VERSION

version 2.0.1

=head1 SYNOPSIS

	use strict;
	use warnings;

	use WebService::Pixabay;
	
	my $pix = WebService::Pixabay->new(api_key => 'secret');
	
	# default searches
	my $img1 = $pix->image_search;
	my $vid1 = $pix->video_search;
	
	# print JSON structure using Data::Dumper's 'Dumper'
	$pix->show_data_structure($img1);
	$pix->show_data_structure($vid1);
	
	###################################################
	# The parameters of the method have the same name #
	# and default values as in Pixabay API docs       #
	###################################################

	# example custom image search and printing
	my $cust_img = $pix->image_search(
		q => 'cats dog',
		lang => 'es',
		response_group => 'high_resolution',
		image_type => 'illustration',
		category => 'animals',
		safesearch => 'true',
		order => 'latest',
		page => 2,
		per_page => 5,
		pretty => 'true'
	);

	$pix->show_data_structure($cust_img);

	# -or with video_search-

	# example custom video search and printing
	my $cust_vid = $pix->video_search(
		q => 'tree',
		lang => 'en',
		pretty => 'false',
		page => 3,
		order => 'popular'
	);

	$pix->show_data_structure($cust_vid);

	# Handling specific hashes and arrays of values from the image_search JSON
	# example retrieving webformatURL from each arrays
	my @urls = undef;
	
	foreach my $url (@{$cust_img->{hits}}) {

		# now has link of photo urls (non-preview photos)
		push(@urls, $url->{webformatURL});		
	}
	
	say $urls[3]; # image URL in the fourth row

	# Getting a specific single hash or array value from video_search JSON
	say $cust_vid->{hits}[0]{medium}{url};

=head1 SEE ALSO

L<Pixabay API documentations|https://pixabay.com/api/docs>

L<Moo>

L<Function::Parameters>

L<Test::More>

L<WebService::Client>

L<LWP::Online>

L<Data::Printer>

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by faraco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

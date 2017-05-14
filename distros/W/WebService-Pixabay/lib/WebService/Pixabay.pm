package WebService::Pixabay;

use Modern::Perl '2010';
use Moo;
use Function::Parameters;
use Data::Printer;

with 'WebService::Client';
# ABSTRACT: Perl 5 interface to Pixabay API.
our $VERSION = '0.0.4'; # VERSION

has api_key =>
(
	is => 'ro', 
	required => 1
);

has '+base_url' =>
(
	default => 'https://pixabay.com/api/'
);

method image_search
(
	:$q = "yellow flower", :$lang = "en", :$id = "", :$response_group = "image_details",
	:$image_type = "all", :$orientation = "all", :$category = "", :$min_width = 0, :$min_height = 0,
	:$editors_choice = "false", :$safesearch = "false", :$order = "popular",
	:$page = 1, :$per_page = 20, :$callback = "", :$pretty = "false"
)
{
	return $self->get
	(
		"?key=" . $self->api_key .
						 "&q=$q&lang=$lang&id=$id&response_group=$response_group&image_type=$image_type" .
						 "&orientation=$orientation&category=$category&min_width=$min_width&mind_height=$min_height" .
					     "&editors_choice=$editors_choice&safesearch=$safesearch&order=$order&page=$page" .
					     "&per_page=$per_page&callback=$callback&pretty=$pretty"
	);
}

method video_search
(	:$q = "yellow flower", :$lang = "en", :$id = "", :$video_type = "all",
	:$category = "", :$min_width = 0, :$min_height = 0,
	:$editors_choice = "false", :$safesearch = "false", :$order = "popular",
	:$page = 1, :$per_page = 20, :$callback = "", :$pretty = "false"
)
{
	return $self->get
	(
		"videos/?key=" . $self->api_key .
						 "&q=$q&lang=$lang&id=$id&video_type=$video_type" .
					     "&category=$category&min_width=$min_width&mind_height=$min_height" .
					     "&editors_choice=$editors_choice&safesearch=$safesearch&order=$order&page=$page" .
					     "&per_page=$per_page&callback=$callback&pretty=$pretty"
	);
}

method show_data_structure($method_name)
{
	return p $method_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Pixabay - Perl 5 interface to Pixabay API.

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

	use WebService::Pixabay;
	
	my $pix = WebService::Pixabay->new(api_key => 'secret');
	
	# default searches
	my $img_search = $pix->image_search();
	my $vid_search = $pix->video_search();

	$pix->show_data_structure($img_search);
	$pix->show_data_structure($vid_search);
	
	###################################################
	# The parameters of the method have the same name #
	# and default values as in Pixabay API docs       #
	###################################################

	# example custom image search
	my $nis = $pix->image_search(
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

	# example custom video search
	my $nvs = $pix->video_search(
		q => 'tree',
		lang => 'en',
		pretty => 'false',
		page => 3,
		order => 'popular'
	);


	$pix->show_data_structure($nis);
	$pix->show_data_structure($nvs);

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

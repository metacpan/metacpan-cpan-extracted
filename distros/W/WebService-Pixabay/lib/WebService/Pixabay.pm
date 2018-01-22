#This software is Copyright (c) 2017-2018 by faraco.
#
#This is free software, licensed under:
#
#  The MIT (X11) License

package WebService::Pixabay;
$WebService::Pixabay::VERSION = '2.2.3';
# ABSTRACT: Perl 5 interface to Pixabay API.

use strict;
use warnings;

use Moo;
use Function::Parameters;

with 'WebService::Client';

# api_key
has api_key => (
    is       => 'ro',
    required => 1
);

has '+base_url' => ( default => 'https://pixabay.com/api/' );

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
    return $self->get( "?key="
          . $self->api_key
          . "&q=$q&lang=$lang&id=$id&response_group=$response_group&image_type=$image_type"
          . "&orientation=$orientation&category=$category&min_width=$min_width&mind_height=$min_height"
          . "&editors_choice=$editors_choice&safesearch=$safesearch&order=$order&page=$page"
          . "&per_page=$per_page&callback=$callback&pretty=$pretty" );
}

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
    return $self->get( "videos/?key="
          . $self->api_key
          . "&q=$q&lang=$lang&id=$id&video_type=$video_type"
          . "&category=$category&min_width=$min_width&mind_height=$min_height"
          . "&editors_choice=$editors_choice&safesearch=$safesearch&order=$order&page=$page"
          . "&per_page=$per_page&callback=$callback&pretty=$pretty" );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Pixabay - Perl 5 interface to Pixabay API.

=head1 VERSION

version 2.2.3

=head1 SYNOPSIS

    use strict;
    use warnings;
    use feature qw(say);

    use WebService::Pixabay;
    use Data::Dumper 'Dumper';

    my $pix = WebService::Pixabay->new(api_key => 'secret');

    # default searches
    my $img1 = $pix->image_search;
    my $vid1 = $pix->video_search;

    # print data structure using Data::Dumper's 'Dumper'
    say Dumper($img1);
    say Dumper($vid1);

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

    say Dumper($cust_img);

    # -or with video_search-

    # example custom video search and printing
    my $cust_vid = $pix->video_search(
        q => 'tree',
        lang => 'en',
        pretty => 'false',
        page => 3,
        order => 'popular'
    );

    say Dumper($cust_vid);

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

=head2 Methods

=over 4

=item C<image_search>

Description: Get image search metadata with default values as shown above.

Parameter: q str A URL encoded search term.
If omitted, all images are returned.
This value may not exceed 100 characters.Example: "yellow+flower"

Parameter: lang str Language code of the language to be searched in.
Accepted values: cs, da, de, en, es, fr, id, it, hu, nl, no, pl, pt, ro, sk, fi, sv, tr, vi, th, bg, ru, el, ja, ko, zh
Default: "en"

Parameter: id str ID, hash ID, or a comma separated list of values for retrieving specific images. In a comma separated
list, IDs and hash IDs cannot be used together.

Parameter: response_group str Choose between retrieving high resolution images and image details. When selecting details
, you can access images up to a dimension of 960 x 720 px.
Accepted values: "image_details", "high_resolution"
Default: "image_details"

Parameter: image_type str Filter results by image type.
Accepted values: "all", "photo", "illustration", "vector"
Default: "all"

Parameter: orientation str Whether an image is wider than it is tall, or taller than it is wide.
Accepted values: "all", "horizontal", "vertical"
Default: "all"

Parameter: category str Filter results by category.
Accepted values: fashion, nature, backgrounds, science, education, people, feelings, religion, health, places, animals,
 industry, food, computer, sports, transportation, travel, buildings, business, music

Parameter: min_width int Minimum image width.
Default: "0"

Parameter: min_height int Minimum image height.
Default: "0"

Parameter: editors_choice bool Select images that have received an Editor's Choice award.
Accepted values: "true", "false"
Default: "false"

Parameter: safesearch bool A flag indicating that only images suitable for all ages should be returned.
 Accepted values: "true", "false"
 Default: "false"

Parameter: order str How the results should be ordered.
 Accepted values: "popular", "latest"
 Default: "popular"

Parameter: page int Returned search results are paginated. Use this parameter to select the page number.
 Default: 1

Parameter: per_page int Determine the number of results per page.
 Accepted values: 3 - 200
 Default: 20

Parameter: callback string JSONP callback function name

Parameter: pretty bool Indent JSON output. This option should not be used in production.
 Accepted values: "true", "false"
 Default: "false"

Returns: Image search metadata.

=item C<video_search>

Description: Get video search metadata with default values as shown above.

Parameter: q str A URL encoded search term. If omitted, all images are returned.
 This value may not exceed 100 characters.
 Example: "yellow+flower"

Parameter: lang str Language code of the language to be searched in.
 Accepted values: cs, da, de, en, es, fr, id, it, hu, nl, no, pl, pt, ro, sk, fi, sv, tr, vi, th, bg, ru, el, ja, ko, zh
 Default: "en"

Parameter: id str ID, hash ID, or a comma separated list of values for retrieving specific images. In a comma separated
 list, IDs and hash IDs cannot be used together.

Parameter: video_type str Filter results by video type.
 Accepted values: "all", "film", "animation"
 Default: "all"

Parameter: orientation str Whether an image is wider than it is tall, or taller than it is wide.
 Accepted values: "all", "horizontal", "vertical"
 Default: "all"

Parameter: category str Filter results by category.
 Accepted values: fashion, nature, backgrounds, science, education, people, feelings, religion, health, places, animals,
 industry, food, computer, sports, transportation, travel, buildings, business, music

Parameter: min_width int Minimum image width.
 Default: "0"

Parameter: min_height int Minimum image height.
 Default: "0"

Parameter: editors_choice bool Select images that have received an Editor's Choice award.
 Accepted values: "true", "false"
 Default: "false"

Parameter: safesearch bool A flag indicating that only images suitable for all ages should be returned.
 Accepted values: "true", "false"
 Default: "false"

Parameter: order str How the results should be ordered.
 Accepted values: "popular", "latest"
 Default: "popular"

Parameter: page int Returned search results are paginated. Use this parameter to select the page number.
 Default: 1

Parameter: per_page int Determine the number of results per page.
 Accepted values: 3 - 200
 Default: 20

Parameter: callback string JSONP callback function name

Parameter: pretty bool Indent JSON output. This option should not be used in production.
 Accepted values: "true", "false"
 Default: "false"

Returns: Video search metadata.

=back

=for html <p>
<a href="https://kritika.io/users/faraco/repos/3011578832649479/heads/master/">
<img src="https://kritika.io/users/faraco/repos/3011578832649479/heads/master/status.svg" />
</a>
</p>

=head1 SEE ALSO

L<Pixabay API documentation|https://pixabay.com/api/docs>

L<Moo>

L<Function::Parameters>

L<Test::More>

L<WebService::Client>

L<LWP::Online>

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by faraco.

This is free software, licensed under:

  The MIT (X11) License

=cut

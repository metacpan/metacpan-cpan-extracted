package WebService::Kramerius::API4::Struct;

use base qw(WebService::Kramerius::API4);
use strict;
use warnings;

use JSON;
use XML::Simple;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, %params) = @_;
	my $xml_callback = sub {
		my $xml = shift;
		return XML::Simple->new->XMLin($xml);
	};
	$params{'output_dispatch'} = {
		'application/json' => sub {
			my $json = shift;
			return JSON->new->decode($json);
		},
		'application/xml' => $xml_callback,
		'text/xml' => $xml_callback,
	};
	return $class->SUPER::new(%params);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::Kramerius::API4::Struct - Class to Kramerius v4+ API, which returns Perl structures instead raw data.

=head1 DESCRIPTION

 Instead returning raw data this class returns Perl structures for these content-types:
 - application/json - Decode JSON via JSON->decode() to Perl structure.
 - application/xml - Decode XML via XML::Simple->XMLin() to Perl structure.
 - text/xml - Decode XML via XML::Simple->XMLin() to Perl structure.

=head1 SYNOPSIS

 use WebService::Kramerius::API4;
 my $obj = WebService::Kramerius::API4->new(%params);
 my $item_json_hr = get_item($item_id)
 my $item_children_json_hr = get_item_children($item_id);
 my $item_siblings_json_hr = get_item_siblings($item_id);
 my $item_streams_json_hr = get_item_streams($item_id);
 my $item_stream = get_item_streams_one($item_id, $stream_id);
 my $item_image = get_item_image($item_id);
 my $item_preview_image = get_item_preview($item_id);
 my $thumb_image = get_item_thumb($item_id);
 my $foxml_xml_hr = get_item_foxml($item_id);

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<library_url>

 Library URL.
 This parameter is required.
 Default value is undef.

=item * C<output_dispatch>

 Output dispatch hash structure.
 Key is content-type and value is subroutine, which converts content to what do you want.
 Default value is blank hash array.

=back

=item C<get_item($item_id)>

 Get item JSON structure as Perl structure.
 Returns reference to HASH.

=item C<get_item_children($item_id)>

 Get item children JSON structure as Perl structure.
 Returns reference to HASH.

=item C<get_item_siblings($item_id)>

 Get item siblings JSON structure as Perl structure..
 Returns reference to HASH.

=item C<get_item_streams($item_id)>

 Get item streams JSON structure as Perl structure.
 Returns reference to HASH.

=item C<get_item_streams_one($item_id, $stream_id)>

 Get item stream.
 Returns stream value when particular output dispatch doesn't set.
 Otherwise returns value from output dispatch.

=item C<get_item_image($item_id)>

 Get item image.
 Returns image.

=item C<get_item_preview($item_id)>

 Get item preview image.
 Returns image.

=item C<get_item_thumb($item_id)>

 Get item thumbnail image.
 Returns image.

=item C<get_item_foxml($item_id)>

 Get item foxml XML structure as Perl structure.
 Returns reference to HASH.

=back

=head1 ERRORS

 new():
         Parameter 'library_url' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 get_item():
         Cannot get '%s' URL.

 get_item_children():
         Cannot get '%s' URL.

 get_item_siblings():
         Cannot get '%s' URL.

 get_item_streams():
         Cannot get '%s' URL.

 get_item_streams_one():
         Cannot get '%s' URL.

 get_item_image():
         Cannot get '%s' URL.

 get_item_preview():
         Cannot get '%s' URL.

 get_item_thumb():
         Cannot get '%s' URL.

 get_item_foxml()
         Cannot get '%s' URL.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use WebService::Kramerius::API4::Struct;

 if (@ARGV < 2) {
         print STDERR "Usage: $0 library_url work_id\n";
         exit 1;
 }
 my $library_url = $ARGV[0];
 my $work_id = $ARGV[1];

 my $obj = WebService::Kramerius::API4::Struct->new(
         'library_url' => $library_url,
 );

 # Get item JSON structure as Perl hash.
 my $item_json = $obj->get_item($work_id);

 p $item_json;

 # Output for 'http://kramerius.mzk.cz/' and '314994e0-490a-11de-ad37-000d606f5dc6'
 # \ {
 #     context      [
 #         [0] [
 #             [0] {
 #                 model   "periodical",
 #                 pid     "uuid:5a2dd690-54b9-11de-8bcd-000d606f5dc6"
 #             },
 #             [1] {
 #                 model   "periodicalvolume",
 #                 pid     "uuid:303c91b0-490a-11de-921d-000d606f5dc6"
 #             },
 #             [2] {
 #                 model   "periodicalitem",
 #                 pid     "uuid:bf1d5df0-49d8-11de-8cb4-000d606f5dc6"
 #             },
 #             [3] {
 #                 model   "page",
 #                 pid     "uuid:314994e0-490a-11de-ad37-000d606f5dc6"
 #             }
 #         ]
 #     ],
 #     datanode     JSON::PP::Boolean  {
 #         Parents       Types::Serialiser::BooleanBase
 #         public methods (0)
 #         private methods (0)
 #         internals: 1
 #     },
 #     details      {
 #         pagenumber   "[1] 
 #                         ",
 #         type         "TitlePage"
 #     },
 #     handle       {
 #         href   "http://kramerius.mzk.cz/search/handle/uuid:314994e0-490a-11de-ad37-000d606f5dc6"
 #     },
 #     iiif         "http://kramerius.mzk.cz/search/iiif/uuid:314994e0-490a-11de-ad37-000d606f5dc6",
 #     model        "page",
 #     pid          "uuid:314994e0-490a-11de-ad37-000d606f5dc6",
 #     policy       "public",
 #     root_pid     "uuid:5a2dd690-54b9-11de-8bcd-000d606f5dc6",
 #     root_title   "Davidova houpačka",
 #     title        "[1]",
 #     zoom         {
 #         type   "zoomify",
 #         url    "http://kramerius.mzk.cz/search/zoomify/uuid:314994e0-490a-11de-ad37-000d606f5dc6"
 #     }
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Data::Printer;
 use WebService::Kramerius::API4::Struct;

 if (@ARGV < 2) {
         print STDERR "Usage: $0 library_url work_id\n";
         exit 1;
 }
 my $library_url = $ARGV[0];
 my $work_id = $ARGV[1];

 my $obj = WebService::Kramerius::API4::Struct->new(
         'library_url' => $library_url,
 );

 # Get item Dublin Core stream JSON structure as Perl hash.
 my $item_stream_dc_hr = $obj->get_item_streams_one($work_id, 'DC');

 p $item_stream_dc_hr;

 # Output for 'http://kramerius.mzk.cz/' and '314994e0-490a-11de-ad37-000d606f5dc6'
 # \ {
 #     dc:identifier        [
 #         [0] "uuid:314994e0-490a-11de-ad37-000d606f5dc6",
 #         [1] "handle:BOA001/914810"
 #     ],
 #     dc:rights            "policy:public",
 #     dc:title             "[1]",
 #     dc:type              "model:page",
 #     xmlns:dc             "http://purl.org/dc/elements/1.1/",
 #     xmlns:oai_dc         "http://www.openarchives.org/OAI/2.0/oai_dc/",
 #     xmlns:xsi            "http://www.w3.org/2001/XMLSchema-instance",
 #     xsi:schemaLocation   "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd"
 # }

=head1 DEPENDENCIES

L<JSON>.
L<WebService::Kramerius::API4>,
L<XML::Simple>.

=head1 SEE ALSO

=over

=item L<WebService::Kramerius::API4>

Class to Kramerius v4+ API.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/WebService-Kramerius-API4>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Josef Špaček 2015-2017
 BSD 2-Clause License

=head1 VERSION

0.01

=cut

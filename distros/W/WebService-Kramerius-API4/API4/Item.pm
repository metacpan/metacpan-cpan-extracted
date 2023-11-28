package WebService::Kramerius::API4::Item;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

# Get item.
sub get_item {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id");
}

sub get_item_children {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/children");
}

sub get_item_siblings {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/siblings");
}

sub get_item_streams {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/streams");
}

sub get_item_streams_one {
	my ($self, $item_id, $stream_id) = @_;

	# XXX Hack for bad content type for alto.
	if ($stream_id eq 'alto' || $stream_id eq 'ALTO') {
		$self->{'_force_content_type'} = 'text/xml';
	}

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/streams/$stream_id");
}

sub get_item_image {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/full");
}

sub get_item_preview {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/preview");
}

sub get_item_thumb {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/thumb");
}

sub get_item_foxml {
	my ($self, $item_id) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/item/'.
		"uuid:$item_id/foxml");
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::Kramerius::API4::Item - Class to item endpoint in Kramerius v4+ API.

=head1 SYNOPSIS

 use WebService::Kramerius::API4::Item;

 my $obj = WebService::Kramerius::API4::Item->new(%params);
 my $item_json = $obj->get_item($item_id)
 my $item_children_json = $obj->get_item_children($item_id);
 my $item_siblings_json = $obj->get_item_siblings($item_id);
 my $item_streams_json = $obj->get_item_streams($item_id);
 my $item_stream = $obj->get_item_streams_one($item_id, $stream_id);
 my $item_image = $obj->get_item_image($item_id);
 my $item_preview_image = $obj->get_item_preview($item_id);
 my $thumb_image = $obj->get_item_thumb($item_id);
 my $foxml_xml = $obj->get_item_foxml($item_id);

=head1 METHODS

=head2 C<new>

 my $obj = WebService::Kramerius::API4::Item->new(%params);

Constructor.

Returns instance of object.

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

=head2 C<get_item>

 my $item_json = $obj->get_item($item_id)

Get item JSON structure.

Returns JSON string when JSON output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_children>

 my $item_children_json = $obj->get_item_children($item_id);

Get item children JSON structure.

Returns JSON string when JSON output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_siblings>

 my $item_siblings_json = $obj->get_item_siblings($item_id);

Get item siblings JSON structure.

Returns JSON string when JSON output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_streams>

 my $item_streams_json = $obj->get_item_streams($item_id);

Get item streams JSON structure.

Returns JSON string when JSON output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_streams_one>

 my $item_stream = $obj->get_item_streams_one($item_id, $stream_id);

Get item stream.

Returns stream value when particular output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_image>

 my $item_image = $obj->get_item_image($item_id);

Get item image.

Returns image when particular output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_preview>

 my $item_preview_image = $obj->get_item_preview($item_id);

Get item preview image.

Returns image when particular output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_thumb>

 my $thumb_image = $obj->get_item_thumb($item_id);

Get item thumbnail image.

Returns image when particular output dispatch doesn't set.
Otherwise returns value from output dispatch.

=head2 C<get_item_foxml>

 my $foxml_xml = $obj->get_item_foxml($item_id);

Get item foxml XML structure.

Returns XML string when XML output dispatch doesn't set.
Otherwise returns value from output dispatch.

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

=for comment filename=get_item.pl

 use strict;
 use warnings;

 use WebService::Kramerius::API4::Item;

 if (@ARGV < 2) {
         print STDERR "Usage: $0 library_url work_id\n";
         exit 1;
 }
 my $library_url = $ARGV[0];
 my $work_id = $ARGV[1];

 my $obj = WebService::Kramerius::API4::Item->new(
         'library_url' => $library_url,
 );

 # Get item JSON structure.
 my $item_json = $obj->get_item($work_id);

 print $item_json."\n";

 # Output for 'http://kramerius.mzk.cz/' and '314994e0-490a-11de-ad37-000d606f5dc6', pretty print
 # {
 #   "dnnt-labels": [
 #     "dnnto"
 #   ],
 #   "datanode": true,
 #   "pid": "uuid:314994e0-490a-11de-ad37-000d606f5dc6",
 #   "handle": {
 #     "href": "https://kramerius.mzk.cz/search/handle/uuid:314994e0-490a-11de-ad37-000d606f5dc6"
 #   },
 #   "zoom": {
 #     "type": "zoomify",
 #     "url": "https://kramerius.mzk.cz/search/zoomify/uuid:314994e0-490a-11de-ad37-000d606f5dc6"
 #   },
 #   "title": "[1]",
 #   "iiif": "https://kramerius.mzk.cz/search/iiif/uuid:314994e0-490a-11de-ad37-000d606f5dc6",
 #   "collections": [
 #     "vc:7f5e94b5-7b6a-4a48-acaa-059096e4f1ae"
 #   ],
 #   "context": [
 #     [
 #       {
 #         "pid": "uuid:5a2dd690-54b9-11de-8bcd-000d606f5dc6",
 #         "model": "periodical"
 #       },
 #       {
 #         "pid": "uuid:303c91b0-490a-11de-921d-000d606f5dc6",
 #         "model": "periodicalvolume"
 #       },
 #       {
 #         "pid": "uuid:bf1d5df0-49d8-11de-8cb4-000d606f5dc6",
 #         "model": "periodicalitem"
 #       },
 #       {
 #         "pid": "uuid:314994e0-490a-11de-ad37-000d606f5dc6",
 #         "model": "page"
 #       }
 #     ]
 #   ],
 #   "model": "page",
 #   "details": {
 #     "type": "TitlePage",
 #     "pagenumber": "[1] \n                        "
 #   },
 #   "root_title": "Davidova houpačka",
 #   "root_pid": "uuid:5a2dd690-54b9-11de-8bcd-000d606f5dc6",
 #   "policy": "private",
 #   "dnnt": true
 # }

=head1 EXAMPLE2

=for comment filename=get_item_perl_struct_dump.pl

 use strict;
 use warnings;

 use Data::Printer;
 use JSON;
 use WebService::Kramerius::API4::Item;

 if (@ARGV < 2) {
         print STDERR "Usage: $0 library_url work_id\n";
         exit 1;
 }
 my $library_url = $ARGV[0];
 my $work_id = $ARGV[1];

 my $obj = WebService::Kramerius::API4::Item->new(
         'library_url' => $library_url,
         'output_dispatch' => {
                 'application/json' => sub {
                         my $json = shift;
                         return JSON->new->decode($json);
                 },
         },
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

=head1 EXAMPLE3

=for comment filename=get_item_streams_perl_struct_dump.pl

 use strict;
 use warnings;

 use Data::Printer;
 use JSON;
 use WebService::Kramerius::API4::Item;

 if (@ARGV < 2) {
         print STDERR "Usage: $0 library_url work_id\n";
         exit 1;
 }
 my $library_url = $ARGV[0];
 my $work_id = $ARGV[1];

 my $obj = WebService::Kramerius::API4::Item->new(
         'library_url' => $library_url,
         'output_dispatch' => {
                 'application/json' => sub {
                         my $json = shift;
                         return JSON->new->decode($json);
                 },
         },
 );

 # Get item streams JSON structure as Perl hash.
 my $item_streams_json = $obj->get_item_streams($work_id);

 p $item_streams_json;

 # Output for 'http://kramerius.mzk.cz/' and '314994e0-490a-11de-ad37-000d606f5dc6'
 # \ {
 #     BIBLIO_MODS    {
 #         label      "BIBLIO_MODS description of current object",
 #         mimeType   "text/xml"
 #     },
 #     DC             {
 #         label      "Dublin Core Record for this object",
 #         mimeType   "text/xml"
 #     },
 #     IMG_FULL       {
 #         label      "",
 #         mimeType   "image/jpeg"
 #     },
 #     IMG_FULL_ADM   {
 #         label      "Image administrative metadata",
 #         mimeType   "text/xml"
 #     },
 #     IMG_PREVIEW    {
 #         label      "",
 #         mimeType   "image/jpeg"
 #     },
 #     IMG_THUMB      {
 #         label      "",
 #         mimeType   "image/jpeg"
 #     },
 #     TEXT_OCR       {
 #         label      "",
 #         mimeType   "text/plain"
 #     },
 #     TEXT_OCR_ADM   {
 #         label      "Image administrative metadata",
 #         mimeType   "text/xml"
 #     }
 # }

=head1 DEPENDENCIES

L<WebService::Kramerius::API4::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WebService-Kramerius-API4>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2015-2023

BSD 2-Clause License

=head1 VERSION

0.02

=cut

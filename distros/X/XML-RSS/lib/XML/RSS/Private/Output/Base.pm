package XML::RSS::Private::Output::Base;
$XML::RSS::Private::Output::Base::VERSION = '1.62';
use strict;
use warnings;

use Carp qw/ confess /;

use HTML::Entities qw(encode_entities_numeric encode_entities);
use DateTime::Format::Mail   ();
use DateTime::Format::W3CDTF ();

use XML::RSS ();

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

# _main() is a reference to the main XML::RSS module
sub _main {
    my $self = shift;

    if (@_) {
        $self->{_main} = shift;
    }

    return $self->{_main};
}

sub _encode_cb {
    my $self = shift;

    if (@_) {
        $self->{_encode_cb} = shift;
    }

    return $self->{_encode_cb};
}

sub _item_idx {
    my $self = shift;

    if (@_) {
        $self->{_item_idx} = shift;
    }

    return $self->{_item_idx};
}

sub _initialize {
    my $self = shift;
    my $args = shift;

    $self->{_output} = "";
    $self->_main($args->{main});

    # TODO : Remove once we have inheritance proper.
    $self->_rss_out_version($args->{version});
    if (defined($args->{encode_cb})) {
        $self->_encode_cb($args->{encode_cb});
    }
    else {
        $self->_encode_cb(\&_default_encode);
    }

    $self->_item_idx(-1);

    return 0;
}

sub _rss_out_version {
    my $self = shift;

    if (@_) {
        $self->{_rss_out_version} = shift;
    }
    return $self->{_rss_out_version};
}

sub _encode {
    my ($self, $text) = @_;
    return $self->_encode_cb()->($self, $text);
}

sub _default_encode {
    my ($self, $text) = @_;

    #return "" unless defined $text;
    if (!defined($text)) {
        confess "\$text is undefined in XML::RSS::_encode(). We don't know how " . "to handle it!";
    }

    return $text if (!$self->_main->_encode_output);

    my $encoded_text = '';

    while ($text =~ s/(.*?)(\<\!\[CDATA\[.*?\]\]\>)//s) {

        # we use &named; entities here because it's HTML
        $encoded_text .= encode_entities($1) . $2;
    }

    # we use numeric entities here because it's XML
    $encoded_text .= encode_entities_numeric($text);

    return $encoded_text;
}

sub _out {
    my ($self, $string) = @_;
    $self->{_output} .= $string;
    return;
}

sub _out_tag {
    my ($self, $tag, $inner) = @_;
    my $content = $inner;
    my $attr    = "";
    if (ref($inner) eq 'HASH') {
        my %inner_copy = %$inner;
        $content = delete $inner_copy{content};
        foreach my $key (keys %inner_copy) {
            my $value = $inner->{$key};
            if (defined($value)) {
                $attr .= " " . $self->_encode($key) . qq{="} . $self->_encode($value) . '"';
            }
        }
    }
    return $self->_out("<$tag$attr>" . $self->_encode($content) . "</$tag>\n");
}

# Remove non-alphanumeric elements and return the modified string.
# Useful for user-specified tags' attributes.

sub _sanitize {
    my ($self, $string) = @_;

    $string =~ s{[^a-zA-Z_\-0-9]}{}g;
    return $string;
}

sub _out_ns_tag {
    my ($self, $prefix, $tag, $inner) = @_;

    my @subtags;

    if (ref($inner) eq "HASH") {
        $self->_out("<${prefix}:${tag}");
        foreach my $attr (sort { $a cmp $b } keys(%{$inner})) {
            if (ref($inner->{$attr}) eq '') {
                $self->_out(q{ }
                      . $self->_sanitize($attr) . q{="}
                      . $self->_encode($inner->{$attr})
                      . q{"});
            }
            else {
                push(@subtags, $attr);
            }
        }

        if (!@subtags) {
            $self->_out("/>\n");
        }
        else {
            $self->_out(">\n");

            foreach my $attr (sort { $a cmp $b } @subtags) {
                if (ref($inner->{$attr})) {
                    _out_ns_tag($self, $prefix, $tag, $inner->{$attr});
                }
            }

            $self->_out("</${prefix}:${tag}>\n");
        }
    }
    elsif (ref($inner) eq 'ARRAY') {
        map { $self->_out_ns_tag($prefix, $tag, $_) } @{$inner};
    }
    else {
        return $self->_out_tag("${prefix}:${tag}", $inner);
    }
}

sub _out_defined_tag {
    my ($self, $tag, $inner) = @_;

    if (defined($inner)) {
        $self->_out_tag($tag, $inner);
    }

    return;
}

sub _out_array_tag {
    my ($self, $tag, $inner) = @_;

    if (ref($inner) eq "ARRAY") {
        foreach my $elem (@$inner) {
            $self->_out_defined_tag($tag, $elem);
        }
    }
    else {
        $self->_out_defined_tag($tag, $inner);
    }

    return;
}

sub _out_inner_tag {
    my ($self, $params, $tag) = @_;

    if (ref($params) eq "") {
        $params = {'ext' => $params, 'defined' => 0,};
    }

    my $ext_tag = $params->{ext};

    if (ref($ext_tag) eq "") {
        $ext_tag = $self->$ext_tag();
    }

    my $value = $ext_tag->{$tag};

    if ($params->{defined} ? defined($value) : 1) {
        $self->_out_tag($tag, $value);
    }

    return;
}

sub _output_item_tag {
    my ($self, $item, $tag) = @_;

    return $self->_out_tag($tag, $item->{$tag});
}

sub _output_def_image_tag {
    my ($self, $tag) = @_;

    return $self->_out_inner_tag({ext => "image", 'defined' => 1}, $tag);
}

sub _output_multiple_tags {
    my ($self, $ext_tag, $tags_ref) = @_;

    foreach my $tag (@$tags_ref) {
        $self->_out_inner_tag($ext_tag, $tag);
    }

    return;
}

sub _output_common_textinput_sub_elements {
    my $self = shift;

    $self->_output_multiple_tags("textinput", [qw(title description name link)],);
}


sub _get_top_elem_about {
    return "";
}

sub _start_top_elem {
    my ($self, $tag, $about_sub) = @_;

    my $about = $self->_get_top_elem_about($tag, $about_sub);

    return $self->_out("<$tag$about>\n");
}

sub _out_textinput_rss_1_0_elems {
}

sub _get_textinput_tag {
    return "textinput";
}

sub _output_complete_textinput {
    my $self = shift;

    my $master_tag = $self->_get_textinput_tag();

    if (defined(my $link = $self->textinput('link'))) {
        $self->_start_top_elem($master_tag, sub {$link});

        $self->_output_common_textinput_sub_elements();

        $self->_out_textinput_rss_1_0_elems();

        $self->_end_top_level_elem($master_tag);
    }

    return;
}

sub _flush_output {
    my $self = shift;

    my $ret = $self->{_output};
    $self->{_output} = "";

    # Detach _main to avoid referencing loops.
    $self->_main(undef);

    return $ret;
}


sub _date_from_dc_date {
    my ($self, $string) = @_;
    my $f = DateTime::Format::W3CDTF->new();
    return $f->parse_datetime($string);
}

sub _date_from_rss2 {
    my ($self, $string) = @_;
    my $f = DateTime::Format::Mail->new();
    return $f->parse_datetime($string);
}

sub _date_to_rss2 {
    my ($self, $date) = @_;

    my $pf = DateTime::Format::Mail->new();
    return $pf->format_datetime($date);
}

sub _date_to_dc_date {
    my ($self, $date) = @_;

    my $pf = DateTime::Format::W3CDTF->new();
    return $pf->format_datetime($date);
}

sub _channel_dc {
    my ($self, $key) = @_;

    if ($self->channel('dc')) {
        return $self->channel('dc')->{$key};
    }
    else {
        return undef;
    }
}

sub _channel_syn {
    my ($self, $key) = @_;

    if ($self->channel('syn')) {
        return $self->channel('syn')->{$key};
    }
    else {
        return undef;
    }
}

sub _calc_lastBuildDate {
    my $self = shift;
    if (defined(my $d = $self->_channel_dc('date'))) {
        return $self->_date_to_rss2($self->_date_from_dc_date($d));
    }
    else {
        # If lastBuildDate is undef we can still return it because we
        # need to return undef.
        return $self->channel("lastBuildDate");
    }
}

sub _calc_pubDate {
    my $self = shift;

    if (defined(my $d = $self->channel('pubDate'))) {
        return $d;
    }
    elsif (defined(my $d2 = $self->_channel_dc('date'))) {
        return $self->_date_to_rss2($self->_date_from_dc_date($d2));
    }
    else {
        return undef;
    }
}

sub _get_other_dc_date {
    my $self = shift;

    if (defined(my $d1 = $self->channel('pubDate'))) {
        return $d1;
    }
    elsif (defined(my $d2 = $self->channel('lastBuildDate'))) {
        return $d2;
    }
    else {
        return undef;
    }
}

sub _calc_dc_date {
    my $self = shift;

    if (defined(my $d1 = $self->_channel_dc('date'))) {
        return $d1;
    }
    else {
        my $date = $self->_get_other_dc_date();

        if (!defined($date)) {
            return undef;
        }
        else {
            return $self->_date_to_dc_date($self->_date_from_rss2($date));
        }
    }
}

sub _output_xml_declaration {
    my $self = shift;

    my $encoding =
      (defined $self->_main->_encoding()) ? ' encoding="' . $self->_main->_encoding() . '"' : "";
    $self->_out('<?xml version="1.0"' . $encoding . '?>' . "\n");
    if (defined(my $stylesheet = $self->_main->_stylesheet)) {
        my $style_url = $self->_encode($stylesheet);
        $self->_out(qq{<?xml-stylesheet type="text/xsl" href="$style_url"?>\n});
    }

    $self->_out("\n");

    return undef;
}

sub _out_image_title_and_url {
    my $self = shift;

    return $self->_output_multiple_tags({ext => "image"}, [qw(title url)]);
}

sub _start_image {
    my $self = shift;

    $self->_start_top_elem("image", sub { $self->image('url') });

    $self->_out_image_title_and_url();

    $self->_output_def_image_tag("link");

    return;
}

sub _start_item {
    my ($self, $item) = @_;

    my $tag  = "item";
    my $base = $item->{'xml:base'};
    $tag .= qq{ xml:base="$base"} if defined $base;
    $self->_start_top_elem($tag, sub { $self->_get_item_about($item) });

    $self->_output_common_item_tags($item);

    return;
}

sub _end_top_level_elem {
    my ($self, $elem) = @_;

    $self->_out("</$elem>\n");
}

sub _end_item {
    shift->_end_top_level_elem("item");
}

sub _end_image {
    shift->_end_top_level_elem("image");
}

sub _end_channel {
    shift->_end_top_level_elem("channel");
}

sub _output_array_item_tag {
    my ($self, $item, $tag) = @_;

    if (defined($item->{$tag})) {
        $self->_out_array_tag($tag, $item->{$tag});
    }

    return;
}

sub _output_def_item_tag {
    my ($self, $item, $tag) = @_;

    if (defined($item->{$tag})) {
        $self->_output_item_tag($item, $tag);
    }

    return;
}

sub _get_item_defined {
    return 0;
}

sub _out_item_desc {
    my ($self, $item) = @_;
    return $self->_output_def_item_tag($item, "description");
}

# Outputs the common item tags for RSS 0.9.1 and above.
sub _output_common_item_tags {
    my ($self, $item) = @_;

    my @fields = (qw( title link ));

    my $defined = $self->_get_item_defined;

    if (!$defined) {
        foreach my $f (@fields) {
            if (!defined($item->{$f})) {
                die qq/Item No. / . $self->_item_idx() . qq/ is missing the "$f" field./;
            }
        }
    }

    $self->_output_multiple_tags(
        {ext => $item, type => 'item', idx => $self->_item_idx(), 'defined' => $defined,},
        [@fields],);

    $self->_out_item_desc($item);

    return;
}

sub _output_common_channel_elements {
    my $self = shift;

    $self->_output_multiple_tags("channel", [qw(title link description)],);
}


sub _out_language {
    my $self = shift;

    return $self->_out_channel_self_dc_field("language");
}

sub _start_channel {
    my $self = shift;

    $self->_start_top_elem("channel", sub { $self->_get_channel_rdf_about });

    $self->_output_common_channel_elements();

    $self->_out_language();

    return;
}

# Calculates a channel field that has a dc: and non-dc alternative,
# prefering the dc: one.
sub _calc_channel_dc_field {
    my ($self, $dc_key, $non_dc_key) = @_;

    my $dc_value = $self->_channel_dc($dc_key);

    return defined($dc_value) ? $dc_value : $self->channel($non_dc_key);
}

sub _prefer_dc {
    my $self = shift;

    if (@_) {
        $self->{_prefer_dc} = shift;
    }
    return $self->{_prefer_dc};
}

sub _calc_channel_dc_field_params {
    my ($self, $dc_key, $non_dc_key) = @_;

    return (
        $self->_prefer_dc() ? "dc:$dc_key" : $non_dc_key,
        $self->_calc_channel_dc_field($dc_key, $non_dc_key)
    );
}

sub _out_channel_dc_field {
    my ($self, $dc_key, $non_dc_key) = @_;

    return $self->_out_defined_tag($self->_calc_channel_dc_field_params($dc_key, $non_dc_key),);
}

sub _out_channel_array_self_dc_field {
    my ($self, $key) = @_;

    $self->_out_array_tag($self->_calc_channel_dc_field_params($key, $key),);
}

sub _out_channel_self_dc_field {
    my ($self, $key) = @_;

    return $self->_out_channel_dc_field($key, $key);
}

sub _out_managing_editor {
    my $self = shift;

    return $self->_out_channel_dc_field("publisher", "managingEditor");
}

sub _out_webmaster {
    my $self = shift;

    return $self->_out_channel_dc_field("creator", "webMaster");
}

sub _out_copyright {
    my $self = shift;

    return $self->_out_channel_dc_field("rights", "copyright");
}

sub _out_editors {
    my $self = shift;

    $self->_out_managing_editor;
    $self->_out_webmaster;
}

sub _get_channel_rdf_about {
    my $self = shift;

    if (defined(my $about = $self->channel('about'))) {
        return $about;
    }
    else {
        return $self->channel('link');
    }
}

sub _output_taxo_topics {
    my ($self, $elem) = @_;

    if (my $list = $elem->{'taxo'}) {
        $self->_out("<taxo:topics>\n  <rdf:Bag>\n");
        foreach my $taxo (@{$list}) {
            $self->_out("    <rdf:li resource=\"" . $self->_encode($taxo) . "\" />\n");
        }
        $self->_out("  </rdf:Bag>\n</taxo:topics>\n");
    }

    return;
}

# Output the Dublin core properties of a certain elements (channel, image,
# textinput, item).

sub _get_dc_ok_fields {
    my $self = shift;

    return $self->_main->_get_dc_ok_fields();
}

sub _out_dc_elements {
    my $self      = shift;
    my $elem      = shift;
    my $skip_hash = shift || {};

    foreach my $dc (@{$self->_get_dc_ok_fields()}) {
        next if $skip_hash->{$dc};

        $self->_out_array_tag("dc:$dc", $elem->{dc}->{$dc});
    }

    return;
}

sub _out_module_prefix_elements_hash {
    my ($self, $args) = @_;

    my $prefix = $args->{prefix};
    my $data   = $args->{data};
    my $url    = $args->{url};

    while (my ($el, $value) = each(%$data)) {
        $self->_out_module_prefix_pair(
            {   %$args,
                el  => $el,
                val => $value,
            }
        );
    }

    return;
}

sub _out_module_prefix_pair {
    my ($self, $args) = @_;

    my $prefix = $args->{prefix};
    my $url    = $args->{url};

    my $el    = $args->{el};
    my $value = $args->{val};

    if ($self->_main->_is_rdf_resource($el, $url)) {
        $self->_out(qq{<${prefix}:${el} rdf:resource="} . $self->_encode($value) . qq{" />\n});
    }
    else {
        $self->_out_ns_tag($prefix, $el, $value);
    }

    return;
}

sub _out_module_prefix_elements_array {
    my ($self, $args) = @_;

    my $prefix = $args->{prefix};
    my $data   = $args->{data};
    my $url    = $args->{url};

    foreach my $element (@$data) {
        $self->_out_module_prefix_pair(
            {   %$args,
                el  => $element->{'el'},
                val => $element->{'val'},
            }
        );
    }

    return;
}

sub _out_module_prefix_elements {
    my ($self, $args) = @_;

    my $data = $args->{'data'};

    if (!$data) {

        # Do nothing - empty data
        return;
    }
    elsif (ref($data) eq "HASH") {
        return $self->_out_module_prefix_elements_hash($args);
    }
    elsif (ref($data) eq "ARRAY") {
        return $self->_out_module_prefix_elements_array($args);
    }
    else {
        die "Don't know how to handle module data of type " . ref($data) . "!";
    }
}

# Output the Ad-hoc modules
sub _out_modules_elements {
    my ($self, $super_elem) = @_;

    # Ad-hoc modules
    while (my ($url, $prefix) = each %{$self->_modules}) {
        next if $prefix =~ /^(dc|syn|taxo)$/;

        $self->_out_module_prefix_elements(
            {   prefix => $prefix,
                url    => $url,
                data   => $super_elem->{$prefix},
            }
        );

    }

    return;
}

sub _out_complete_outer_tag {
    my ($self, $outer, $inner) = @_;

    my $value = $self->_main->{$outer}->{$inner};

    if (defined($value)) {
        $self->_out("<$outer>\n");
        $self->_out_array_tag($inner, $value);
        $self->_end_top_level_elem($outer);
    }
}

sub _out_skip_tag {
    my ($self, $what) = @_;

    return $self->_out_complete_outer_tag("skip\u${what}s", $what);
}

sub _out_skip_hours {
    return shift->_out_skip_tag("hour");
}

sub _out_skip_days {
    return shift->_out_skip_tag("day");
}

sub _get_item_about {
    my ($self, $item) = @_;
    return defined($item->{'about'}) ? $item->{'about'} : $item->{'link'};
}

sub _out_image_dc_elements {
}

sub _out_modules_elements_if_supported {
}

sub _out_image_dims {
}

sub _output_defined_image {
    my $self = shift;

    $self->_start_image();

    $self->_out_image_dims;

    # image width
    #$output .= '<rss091:width>'.$self->{image}->{width}.'</rss091:width>'."\n"
    #    if $self->{image}->{width};

    # image height
    #$output .= '<rss091:height>'.$self->{image}->{height}.'</rss091:height>'."\n"
    #    if $self->{image}->{height};

    # description
    #$output .= '<rss091:description>'.$self->{image}->{description}.'</rss091:description>'."\n"
    #    if $self->{image}->{description};

    $self->_out_image_dc_elements;

    $self->_out_modules_elements_if_supported($self->image());

    $self->_end_image();
}

sub _is_image_defined {
    my $self = shift;

    return defined($self->image('url'));
}

sub _output_complete_image {
    my $self = shift;

    if ($self->_is_image_defined()) {
        $self->_output_defined_image();
    }
}

sub _out_seq_items {
    my $self = shift;

    # Seq items
    $self->_out("<items>\n <rdf:Seq>\n");

    my $idx = 0;
    foreach my $item (@{$self->_main->_get_items()}) {

        my $about_text = $self->_get_item_about($item);

        if (!defined($about_text)) {
            die qq/Item No. $idx is missing "about" or "link" fields./;
        }

        $self->_out('  <rdf:li rdf:resource="' . $self->_encode($about_text) . '" />' . "\n");
    }
    continue {
        $idx++;
    }

    $self->_out(" </rdf:Seq>\n</items>\n");
}

sub _get_first_rdf_decl_mappings {
    return ();
}

sub _get_rdf_decl_mappings {
    my $self = shift;

    my $modules = $self->_modules();

    return [
        $self->_get_first_rdf_decl_mappings(),
        sort { $a->[0] cmp $b->[0] } map { [$modules->{$_}, $_] } keys(%$modules)
    ];
}

sub _render_xmlns {
    my ($self, $prefix, $url) = @_;

    my $pp = defined($prefix) ? ":$prefix" : "";

    return qq{ xmlns$pp="$url"\n};
}

sub _get_rdf_xmlnses {
    my $self = shift;

    return join("", map { $self->_render_xmlns(@$_) } @{$self->_get_rdf_decl_mappings});
}

sub _get_rdf_decl_open_tag {
    return qq{<rss version="2.0"\n};
}


sub _get_rdf_decl {
    my $self      = shift;
    my $base      = $self->_main()->{'xml:base'};
    my $base_decl = (defined $base) ? qq{ xml:base="$base"\n} : "";
    return $self->_get_rdf_decl_open_tag() . $base_decl . $self->_get_rdf_xmlnses() . ">\n\n";
}

sub _out_rdf_decl {
    my $self = shift;

    return $self->_out($self->_get_rdf_decl);
}

sub _out_guid {
    my ($self, $item) = @_;

    # The unique identifier. Use 'permaLink' for an external
    # identifier, or 'guid' for a internal string.
    # (I call it permaLink in the hash for purposes of clarity.)

    for my $guid (qw(permaLink guid)) {
        if (defined $item->{$guid}) {
            $self->_out('<guid isPermaLink="'
                  . ($guid eq 'permaLink' ? 'true' : 'false') . '">'
                  . $self->_encode($item->{$guid})
                  . '</guid>'
                  . "\n");
            last;
        }
    }
}

sub _out_item_source {
    my ($self, $item) = @_;

    if (defined $item->{source} && defined $item->{sourceUrl}) {
        $self->_out('<source url="'
              . $self->_encode($item->{sourceUrl}) . '">'
              . $self->_encode($item->{source})
              . "</source>\n");
    }
}

sub _out_single_item_enclosure {
    my ($self, $item, $enc) = @_;

    return $self->_out("<enclosure "
          . join(' ', map { "$_=\"" . $self->_encode($enc->{$_}) . '"' } keys(%$enc))
          . " />\n");
}

sub _out_item_enclosure {
    my ($self, $item) = @_;

    if (my $enc = $item->{enclosure}) {
        foreach my $sub ((ref($enc) eq "ARRAY") ? @$enc : ($enc)) {
            $self->_out_single_item_enclosure($item, $sub);
        }
    }
}

sub _get_items {
    return shift->_main->{items};
}

sub _get_filtered_items {
    return shift->_get_items;
}

sub _out_item_2_0_tags {
}

sub _out_item_1_0_tags {
}

sub _output_single_item {
    my ($self, $item) = @_;

    $self->_start_item($item);

    $self->_out_item_2_0_tags($item);

    $self->_out_item_1_0_tags($item);

    $self->_out_modules_elements_if_supported($item);

    $self->_end_item($item);
}

sub _output_items {
    my $self = shift;

    $self->_item_idx(0);
    foreach my $item (@{$self->_get_filtered_items}) {
        $self->_output_single_item($item);
    }
    continue {
        $self->_item_idx($self->_item_idx() + 1);
    }
}

sub _output_main_elements {
    my $self = shift;

    $self->_output_complete_image();

    $self->_output_items;

    $self->_output_complete_textinput();
}

# Outputs the last elements - for RSS versions 0.9.1 and 2.0 .
sub _out_last_elements {
    my $self = shift;

    $self->_out("\n");

    $self->_output_main_elements;

    $self->_out_skip_hours();

    $self->_out_skip_days();

    $self->_end_channel;
}

sub _calc_prefer_dc {
    return 0;
}

sub _output_xml_start {
    my ($self) = @_;

    $self->_prefer_dc($self->_calc_prefer_dc());

    $self->_output_xml_declaration();

    $self->_out_rdf_decl;

    $self->_start_channel();
}

sub _get_end_tag {
    return "rss";
}

sub _out_end_tag {
    my $self = shift;

    return $self->_out("</" . $self->_get_end_tag() . ">");
}

sub _out_all_modules_elems {
    my $self = shift;

    # Dublin Core module
    $self->_out_dc_elements($self->channel(),
        {map { $_ => 1 } qw(language creator publisher rights date)},
    );

    # Syndication module
    foreach my $syn (@{$self->_main->_get_syn_ok_fields}) {
        if (defined(my $value = $self->_channel_syn($syn))) {
            $self->_out_ns_tag("syn", $syn, $value);
        }
    }

    # Taxonomy module
    $self->_output_taxo_topics($self->channel());

    $self->_out_modules_elements($self->channel());
}

sub _out_dates {
    my $self = shift;

    $self->_out_defined_tag("pubDate",       $self->_calc_pubDate());
    $self->_out_defined_tag("lastBuildDate", $self->_calc_lastBuildDate());
}

sub _out_def_chan_tag {
    my ($self, $tag) = @_;
    return $self->_output_multiple_tags({ext => "channel", 'defined' => 1}, [$tag],);
}

# $self->_render_complete_rss_output($xml_version)
#
# This function is the workhorse of the XML output and does all the work of
# rendering the RSS, delegating the work to specialised functions.
#
# It accepts the requested version number as its argument.

sub _render_complete_rss_output {
    my ($self) = @_;

    $self->_output_xml_start();

    $self->_output_rss_middle;

    $self->_out_end_tag;

    return $self->_flush_output();
}

###
### Delegate the XML::RSS accessors to _main
###

sub channel {
    return shift->_main->channel(@_);
}

sub image {
    return shift->_main->image(@_);
}

sub textinput {
    return shift->_main->textinput(@_);
}

sub _modules {
    return shift->_main->_modules();
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 1.62

=head1 METHODS

=head2 channel

Internal use.

=head2 image

Internal use.

=head2 new

Internal use.

=head2 textinput

Internal use.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-RSS>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-RSS>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-RSS>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-RSS>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-RSS>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::RSS>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-rss at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-RSS>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-RSS>

  git clone git://github.com/shlomif/perl-XML-RSS.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-XML-RSS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Various.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

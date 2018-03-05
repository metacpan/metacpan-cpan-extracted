package XML::RSS;
$XML::RSS::VERSION = '1.60';
use strict;
use warnings;

use Carp;
use XML::Parser;

use XML::RSS::Private::Output::Base;
use XML::RSS::Private::Output::V0_9;
use XML::RSS::Private::Output::V0_91;
use XML::RSS::Private::Output::V1_0;
use XML::RSS::Private::Output::V2_0;

use vars qw($VERSION $AUTOLOAD @ISA $AUTO_ADD);

require 5.008;

$VERSION = '1.59';

$AUTO_ADD = 0;

sub _get_ok_fields {
    return {
        "0.9" => {
            channel => {
                title       => undef,
                description => undef,
                link        => undef,
            },
            image => {
                title => undef,
                url   => undef,
                link  => undef,
            },
            textinput => {
                title       => undef,
                description => undef,
                name        => undef,
                link        => undef,
            },
        },
        "0.91" => {
            channel => {
                title          => undef,
                copyright      => undef,
                description    => undef,
                docs           => undef,
                language       => undef,
                lastBuildDate  => undef,
                'link'         => undef,
                managingEditor => undef,
                pubDate        => undef,
                rating         => undef,
                webMaster      => undef,
            },
            image => {
                title       => undef,
                url         => undef,
                'link'      => undef,
                width       => undef,
                height      => undef,
                description => undef,
            },
            skipDays  => {day  => undef,},
            skipHours => {hour => undef,},
            textinput => {
                title       => undef,
                description => undef,
                name        => undef,
                'link'      => undef,
            },
        },
        "2.0" => {
            channel => {
                title          => undef,
                'link'         => undef,
                description    => undef,
                language       => undef,
                copyright      => undef,
                managingEditor => undef,
                webMaster      => undef,
                pubDate        => undef,
                lastBuildDate  => undef,
                category       => undef,
                generator      => undef,
                docs           => undef,
                cloud          => '',
                ttl            => undef,
                image          => '',
                textinput      => '',
                skipHours      => '',
                skipDays       => '',
            },
            image => {
                title       => undef,
                url         => undef,
                'link'      => undef,
                width       => undef,
                height      => undef,
                description => undef,
            },
            skipDays  => {day  => undef,},
            skipHours => {hour => undef,},
            textinput => {
                title       => undef,
                description => undef,
                name        => undef,
                'link'      => undef,
            },
        },
        'default' => {
            channel => {
                title       => undef,
                description => undef,
                link        => undef,
            },
            image => {
                title => undef,
                url   => undef,
                link  => undef,
            },
            textinput => {
                title       => undef,
                description => undef,
                name        => undef,
                link        => undef,
            },
        },
    };
}

# define required elements for RSS 0.9
my $_REQ_v0_9 = {
    channel => {
        "title"       => [1, 40],
        "description" => [1, 500],
        "link"        => [1, 500]
    },
    image => {
        "title" => [1, 40],
        "url"   => [1, 500],
        "link"  => [1, 500]
    },
    item => {
        "title" => [1, 100],
        "link"  => [1, 500]
    },
    textinput => {
        "title"       => [1, 40],
        "description" => [1, 100],
        "name"        => [1, 500],
        "link"        => [1, 500]
    }
};

# define required elements for RSS 0.91
my $_REQ_v0_9_1 = {
    channel => {
        "title"          => [1, 100],
        "description"    => [1, 500],
        "link"           => [1, 500],
        "language"       => [1, 5],
        "rating"         => [0, 500],
        "copyright"      => [0, 100],
        "pubDate"        => [0, 100],
        "lastBuildDate"  => [0, 100],
        "docs"           => [0, 500],
        "managingEditor" => [0, 100],
        "webMaster"      => [0, 100],
    },
    image => {
        "title"       => [1, 100],
        "url"         => [1, 500],
        "link"        => [0, 500],
        "width"       => [0, 144],
        "height"      => [0, 400],
        "description" => [0, 500]
    },
    item => {
        "title"       => [1, 100],
        "link"        => [1, 500],
        "description" => [0, 500]
    },
    textinput => {
        "title"       => [1, 100],
        "description" => [1, 500],
        "name"        => [1, 20],
        "link"        => [1, 500]
    },
    skipHours => {"hour" => [1, 23]},
    skipDays  => {"day"  => [1, 10]}
};

# define required elements for RSS 2.0
my $_REQ_v2_0 = {
    channel => {
        "title"          => [1, 100],
        "description"    => [1, 500],
        "link"           => [1, 500],
        "language"       => [0, 5],
        "rating"         => [0, 500],
        "copyright"      => [0, 100],
        "pubDate"        => [0, 100],
        "lastBuildDate"  => [0, 100],
        "docs"           => [0, 500],
        "managingEditor" => [0, 100],
        "webMaster"      => [0, 100],
    },
    image => {
        "title"       => [1, 100],
        "url"         => [1, 500],
        "link"        => [0, 500],
        "width"       => [0, 144],
        "height"      => [0, 400],
        "description" => [0, 500]
    },
    item => {
        "title"       => [1, 100],
        "link"        => [1, 500],
        "description" => [0, 500]
    },
    textinput => {
        "title"       => [1, 100],
        "description" => [1, 500],
        "name"        => [1, 20],
        "link"        => [1, 500]
    },
    skipHours => {"hour" => [1, 23]},
    skipDays  => {"day"  => [1, 10]}
};

my $namespace_map = {
    rss10 => 'http://purl.org/rss/1.0/',
    rss09 => 'http://my.netscape.com/rdf/simple/0.9/',

    # rss091 => 'http://purl.org/rss/1.0/modules/rss091/',
    rss20 => 'http://backend.userland.com/blogChannelModule',
};

sub _rdf_resource_fields {
    return {
        'http://webns.net/mvcb/' => {
            'generatorAgent' => 1,
            'errorReportsTo' => 1
        },
        'http://purl.org/rss/1.0/modules/annotate/' => {'reference' => 1},
        'http://my.theinfo.org/changed/1.0/rss/'    => {'server'    => 1}
    };
}

my %empty_ok_elements = (enclosure => 1);
my %hashref_ok_elements = (description => 1);

sub _get_default_modules {
    return {
        'http://purl.org/rss/1.0/modules/syndication/' => 'syn',
        'http://purl.org/dc/elements/1.1/'             => 'dc',
        'http://purl.org/rss/1.0/modules/taxonomy/'    => 'taxo',
        'http://webns.net/mvcb/'                       => 'admin',
        'http://purl.org/rss/1.0/modules/content/'     => 'content',
    };
}

sub _get_default_rss_2_0_modules {
    return {'http://backend.userland.com/blogChannelModule' => 'blogChannel',};
}

sub _get_syn_ok_fields {
    return [qw(updateBase updateFrequency updatePeriod)];
}

sub _get_dc_ok_fields {
    return [qw(
        contributor
        coverage
        creator
        date
        description
        format
        identifier
        language
        publisher
        relation
        rights
        source
        subject
        title
        type
    )];
}

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

sub _get_init_default_key_assignments {
    return [
        {key => "version",       default => '1.0',},
        {key => "encode_output", default => 1,},
        {key => "output",        default => "",},
        {key => "encoding",      default => "UTF-8",},
        {key => "encode_cb",     default => undef(),},
        {key => "xml:base",      default => undef(),},
    ];
}

# This method resets the contents of the instance to an empty one (with no
# items, empty keys, etc.). Useful before parsing or during initialization.

sub _reset {
    my $self = shift;

    # internal hash
    $self->{_internal} = {};

    # init num of items to 0
    $self->{num_items} = 0;

    # initialize items
    $self->{items} = [];

    delete $self->{_allow_multiple};

    my $ok_fields = $self->_get_ok_fields();

    my $ver_ok_fields =
      exists($ok_fields->{$self->{version}})
      ? $ok_fields->{$self->{version}}
      : $ok_fields->{default};

    while (my ($k, $v) = each(%$ver_ok_fields)) {
        $self->{$k} = +{%{$v}};
    }

    return;
}

sub _initialize {
    my $self = shift;
    my %hash = @_;

    # adhere to Netscape limits; no by default
    $self->{'strict'} = 0;

    # namespaces
    $self->{namespaces}    = {};
    $self->{rss_namespace} = '';
    foreach my $k (@{$self->_get_init_default_key_assignments()})
    {
        my $key = $k->{key};
        $self->{$key} = exists($hash{$key}) ? $hash{$key} : $k->{default};
    }

    # modules
    $self->{modules} = (
        ($self->{version} eq "2.0")
        ? $self->_get_default_rss_2_0_modules()
        : $self->_get_default_modules()
    );

    # stylesheet
    if (exists($hash{stylesheet})) {
        $self->{stylesheet} = $hash{stylesheet};
    }

    if ($self->{version} eq "2.0") {
        $self->{namespaces}->{'blogChannel'} = "http://backend.userland.com/blogChannelModule";
    }

    $self->_reset;

    return;
}

sub add_module {
    my $self = shift;
    my $hash = {@_};

    $hash->{prefix} =~ /^[a-z_][a-z0-9.\-_]*$/i
      or croak "a namespace prefix should look like [A-Za-z_][A-Za-z0-9.\\-_]*";

    $hash->{uri}
      or croak "a URI must be provided in a namespace declaration";

    $self->{modules}->{$hash->{uri}} = $hash->{prefix};
}

sub add_item {
    my $self = shift;
    my $hash = {@_};

    # strict Netscape Netcenter length checks
    if ($self->{'strict'}) {

        # make sure we have a title and link
        croak "title and link elements are required"
          unless ($hash->{title} && $hash->{'link'});

        # check string lengths
        croak "title cannot exceed 100 characters in length"
          if (length($hash->{title}) > 100);
        croak "link cannot exceed 500 characters in length"
          if (length($hash->{'link'}) > 500);
        croak "description cannot exceed 500 characters in length"
          if (exists($hash->{description})
            && length($hash->{description}) > 500);

        # make sure there aren't already 15 items
        croak "total items cannot exceed 15 " if (@{$self->{items}} >= 15);
    }

    # add the item to the list
    if (defined($hash->{mode}) && $hash->{mode} eq 'insert') {
        unshift(@{$self->{items}}, $hash);
    }
    else {
        push(@{$self->{items}}, $hash);
    }

    # return reference to the list of items
    return $self->{items};
}


# $self->_render_complete_rss_output($xml_version)
#
# This function is the workhorse of the XML output and does all the work of
# rendering the RSS, delegating the work to specialised functions.
#
# It accepts the requested version number as its argument.

sub _get_rendering_class {
    my ($self, $ver) = @_;

    if ($ver eq "1.0")
    {
        return "XML::RSS::Private::Output::V1_0";
    }
    elsif ($ver eq "0.9")
    {
        return "XML::RSS::Private::Output::V0_9";
    }
    elsif ($ver eq "0.91")
    {
        return "XML::RSS::Private::Output::V0_91";
    }
    else
    {
        return "XML::RSS::Private::Output::V2_0";
    }
}

sub _get_encode_cb_params
{
    my $self = shift;

    return
        defined($self->{encode_cb}) ?
            ("encode_cb" => $self->{encode_cb}) :
            ()
            ;
}

sub _get_rendering_obj {
    my ($self, $ver) = @_;

    return $self->_get_rendering_class($ver)->new(
        {
            main => $self,
            version => $ver,
            $self->_get_encode_cb_params(),
        }
    );
}

sub _render_complete_rss_output {
    my ($self, $ver) = @_;

    return $self->_get_rendering_obj($ver)->_render_complete_rss_output();
}

sub as_rss_0_9 {
    return shift->_render_complete_rss_output("0.9");
}

sub as_rss_0_9_1 {
    return shift->_render_complete_rss_output("0.91");
}

sub as_rss_1_0 {
    return shift->_render_complete_rss_output("1.0");
}

sub as_rss_2_0 {
    return shift->_render_complete_rss_output("2.0");
}



sub _get_output_methods_map {
    return {
        '0.9'  => "as_rss_0_9",
        '0.91' => "as_rss_0_9_1",
        '2.0'  => "as_rss_2_0",
        '1.0'  => "as_rss_1_0",
    };
}

sub _get_default_output_method {
    return "as_rss_1_0";
}

sub _get_output_method {
    my ($self, $version) = @_;

    if (my $output_method = $self->_get_output_methods_map()->{$version}) {
        return $output_method;
    }
    else {
        return $self->_get_default_output_method();
    }
}

sub _get_output_version {
    my $self = shift;
    return ($self->{output} =~ /\d/) ? $self->{output} : $self->{version};
}

# This is done to preserve backwards compatibility with older versions
# of XML-RSS that had the channel/{link,description,title} as the empty
# string by default.
sub _output_env {
    my $self = shift;
    my $callback = shift;

    local $self->{channel}->{'link'} = $self->{channel}->{'link'};
    local $self->{channel}->{'description'} = $self->{channel}->{'description'};
    local $self->{channel}->{'title'} = $self->{channel}->{'title'};

    foreach my $field (qw(link description title))
    {
        if (!defined($self->{channel}->{$field}))
        {
            $self->{channel}->{$field} = '';
        }
    }

    return $callback->();
}

sub as_string {
    my $self = shift;

    my $version = $self->_get_output_version();

    my $output_method = $self->_get_output_method($version);

    return $self->_output_env(
        sub { return $self->$output_method(); }
    );
}

# Checks if inside a possibly namespaced element
# TODO : After increasing test coverage convert all such conditionals to this
# method.
sub _my_in_element {
    my ($self, $elem) = @_;

    my $parser = $self->_parser;

    return $parser->within_element($elem)
        || $parser->within_element(
            $parser->generate_ns_name($elem, $self->{rss_namespace})
        );
}

sub _get_elem_namespace_helper {
    my ($self, $el) = @_;

    my $ns = $self->_parser->namespace($el);

    return (defined($ns) ? $ns : "");
}

sub _get_elem_namespace {
    my $self = shift;

    my ($el) = @_;

    my $ns = $self->_get_elem_namespace_helper(@_);

    my $verdict = (!$ns && !$self->{rss_namespace})
      || ($ns eq $self->{rss_namespace});

    return ($ns, $verdict);
}

sub _current_element {
    my $self = shift;

    return $self->_parser->current_element;
}

sub _get_current_namespace {
    my $self = shift;

    return $self->_get_elem_namespace($self->_current_element);
}

sub _is_rdf_resource {
    my $self = shift;
    my $el = shift;

    my $ns = shift;
    if (!defined($ns))
    {
        $ns = $self->_parser->namespace($el);
    }

    return (
           exists($self->_rdf_resource_fields->{ $ns })
        && exists($self->_rdf_resource_fields->{ $ns }{ $el })
    );
}

sub _get_ns_arrayity {
    my ($self, $ns) = @_;

    my $is_array =
           $self->_parse_options()->{'modules_as_arrays'}
        && (!exists($self->_get_default_modules()->{$ns}))
        # RDF
        && ($ns ne "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
        ;

    my $default_ref = sub { $is_array ? [] : {} };

    return ($is_array, $default_ref);
}

sub _append_text_to_elem_struct {
    my ($self, $struct, $cdata, $mapping_sub, $is_array_sub) = @_;

    my $elem = $self->_current_element;

    my ($ns, $verdict) = $self->_get_current_namespace;

    # If it's in the default namespace
    if ($verdict) {
        $self->_append_struct(
            $struct,
            scalar($mapping_sub->($struct, $elem)),
            scalar($is_array_sub->($struct, $elem)),
            $cdata
        );
    }
    else {
        my $prefix = $self->{modules}->{$ns};

        my ($is_array, $default_ref) = $self->_get_ns_arrayity($ns);

        $self->_append_struct(
            ($struct->{$ns} ||= $default_ref->()),
            $elem,
            (defined($prefix) && $prefix eq "dc"),
            $cdata
        );

        # If it's in a module namespace, provide a friendlier prefix duplicate
        if ($prefix) {
            $self->_append_struct(
                ($struct->{$prefix} ||= $default_ref->()),
                $elem,
                ($prefix eq "dc"),
                $cdata
            );
        }
    }

    return;
}

sub _append_struct {
    my ($self, $struct, $key, $can_be_array, $cdata) = @_;

    if (ref($struct) eq 'ARRAY') {
        $struct->[-1]->{'val'} .= $cdata;
        return;
    }
    elsif (defined $struct->{$key}) {
        if (ref($struct->{$key}) eq 'HASH') {
            $struct->{$key}->{content} .= $cdata;
            return;
        }
        elsif ($can_be_array && ref($struct->{$key}) eq 'ARRAY') {
            $struct->{$key}->[-1] .= $cdata;
            return;
        }
    }

    $struct->{$key} .= $cdata;
    return;
}

sub _return_elem {
    my ($struct, $elem) = @_;
    return $elem;
}

sub _return_elem_is_array {
    my ($struct, $elem) = @_;

    # Always return false because no element should be an array.
    return;
}

sub _append_text_to_elem {
    my ($self, $ext_tag, $cdata) = @_;

    return $self->_append_text_to_elem_struct(
        $self->$ext_tag(),
        $cdata,
        \&_return_elem,
        \&_return_elem_is_array,
    );
}

sub _within_topics {
    my $self = shift;

    my $parser = $self->_parser;

    return $parser->within_element(
        $parser->generate_ns_name(
            "topics", 'http://purl.org/rss/1.0/modules/taxonomy/'
        )
    );
}

sub _return_item_elem {
    my ($item, $elem) = @_;
    if ($elem eq "guid") {
        return $item->{isPermaLink} ? "permaLink" : "guid";
    }
    else {
        return $elem;
    }
}

sub _return_item_elem_is_array {
    my ($item, $elem) = @_;

    return ($elem eq "category");
}

sub _append_text_to_item {
    my ($self, $cdata) = @_;

    if (@{$self->{'items'}} < $self->{num_items}) {
        push @{$self->{items}}, {};
    }

    $self->_append_text_to_elem_struct(
        $self->_last_item,
        $cdata,
        \&_return_item_elem,
        \&_return_item_elem_is_array
    );
}

sub _append_to_array_elem {
    my ($self, $category, $cdata) = @_;

    if (! $self->_my_in_element($category))
    {
        return;
    }

    my $el = $self->_current_element;

    if (ref($self->{$category}->{$el}) eq "ARRAY") {
        $self->{$category}->{$el}->[-1] .= $cdata;
    }
    else {
        $self->{$category}->{$el} .= $cdata;
    }

    return 1;
}

sub _handle_char {
    my ($self, $cdata) = (@_);

    # image element
    if ($self->_my_in_element("image")) {
        $self->_append_text_to_elem("image", $cdata);
    }
    # item element
    elsif (defined($self->{_inside_item_elem})) {
        return if $self->_within_topics;

        $self->_append_text_to_item($cdata);
    }
    # textinput element
    elsif (
        $self->_my_in_element("textinput") || $self->_my_in_element("textInput")
      )
    {
        $self->_append_text_to_elem("textinput", $cdata);
    }
    # skipHours element
    elsif ($self->_append_to_array_elem("skipHours", $cdata)) {
        # Do nothing - already done in the predicate.
    }
    elsif ($self->_append_to_array_elem("skipDays", $cdata)) {
        # Do nothing - already done in the predicate.
    }
    # channel element
    elsif ($self->_my_in_element("channel")) {
        if ($self->_within_topics() || $self->_my_in_element("items")) {
            return;
        }

        if ($self->_current_element eq "category") {
            $self->_append_to_array_elem("channel", $cdata);
        }
        else {
            $self->_append_text_to_elem("channel", $cdata);
        }
    }
}

sub _handle_dec {
    my ($self, $version, $encoding, $standalone) = (@_);
    $self->{encoding} = $encoding;

    #print "ENCODING: $encoding\n";
}

sub _should_be_hashref {
    my ($self, $el) = @_;

    return
    (
        $empty_ok_elements{$el}
        || ($self->_parse_options()->{'hashrefs_instead_of_strings'}
            && $hashref_ok_elements{$el}
        )
    );
}

sub _start_array_element_in_struct {
    my ($self, $input_struct, $el, $prefix) = @_;

    my ($el_ns, $el_verdict) = $self->_get_elem_namespace($el);

    my ($is_array, $default_ref) = $self->_get_ns_arrayity($el_ns);

    my @structs = (!$el_verdict)
        ? (
            (exists($self->{modules}->{$el_ns})
                ? ($input_struct->{$self->{modules}->{$el_ns}} ||= $default_ref->())
                : ()
            ),
            ($input_struct->{$el_ns} ||= $default_ref->()),
        )
        : ($input_struct)
        ;

    foreach my $struct (@structs)
    {
        if (ref($struct) eq 'ARRAY') {
            push @$struct, { el => $el, val => "", };
        }
        # If it's an array - append a new empty element because a new one
        # was started.
        elsif (ref($struct->{$el}) eq "ARRAY") {
            push @{$struct->{$el}}, "";
        }
        # If it's not an array but still full (i.e: it's only the second
        # element), then turn it into an array
        elsif (defined($struct->{$el}) && length($struct->{$el})) {
            $struct->{$el} = [$struct->{$el}, ""];
        }
        # Else - do nothing and let the function append to the new value
        #
    }
    return 1;
}

sub _start_array_element {
    my ($self, $cat, $el) = @_;

    if (!$self->_my_in_element($cat)) {
        return;
    }

    $self->_start_array_element_in_struct($self->{$cat}, $el);
    return 1;
}

sub _last_item {
    my $self = shift;

    return ($self->{'items'}->[$self->{num_items} - 1] ||= {});
}

sub _handle_start {
    my $self    = shift;
    my $el      = shift;
    my %attribs = @_;

    my $parser = $self->_parser;

    my ($el_ns, $el_verdict) = $self->_get_elem_namespace($el);

    if ($el eq "image")
    {
        if (exists($attribs{'resource'}))
        {
            $self->image("rdf:resource", $attribs{'resource'});
        }
    }

    # beginning of RSS 0.91
    if ($el eq 'rss') {
        if (exists($attribs{version})) {
            $self->{_internal}->{version} = $attribs{version};
        }
        else {
            croak "Malformed RSS: invalid version\n";
        }

        # handle xml:base
        $self->{'xml:base'} = $attribs{'base'} if exists $attribs{'base'};

    # beginning of RSS 1.0 or RSS 0.9
    }
    elsif ($el eq 'RDF') {
        my @prefixes = $parser->new_ns_prefixes;
        foreach my $prefix (@prefixes) {
            my $uri = $parser->expand_ns_prefix($prefix);
            $self->{namespaces}->{$prefix} = $uri;

            #print "$prefix = $uri\n";
        }

        # removed assumption that RSS is the default namespace - kellan, 11/5/02
        #
        foreach my $uri (values %{$self->{namespaces}}) {
            if ($namespace_map->{'rss10'} eq $uri) {
                $self->{_internal}->{version} = '1.0';
                $self->{rss_namespace} = $uri;
                last;
            }
            elsif ($namespace_map->{'rss09'} eq $uri) {
                $self->{_internal}->{version} = '0.9';
                $self->{rss_namespace} = $uri;
                last;
            }
        }

        # failed to match a namespace
        if (!defined($self->{_internal}->{version})) {
            croak "Malformed RSS: invalid version\n";
        }

        #if ($self->expand_ns_prefix('#default') =~ /\/1.0\//) {
        #    $self->{_internal}->{version} = '1.0';
        #} elsif ($self->expand_ns_prefix('#default') =~ /\/0.9\//) {
        #    $self->{_internal}->{version} = '0.9';
        #} else {
        #    croak "Malformed RSS: invalid version\n";
        #}

        # handle xml:base
        $self->{'xml:base'} = $attribs{'base'} if exists $attribs{'base'};

    # beginning of item element
    }
    elsif ($self->_start_array_element("skipHours", $el)) {
        # Do nothing - already done in the predicate.
    }
    elsif ($self->_start_array_element("skipDays", $el)) {
        # Do nothing - already done in the predicate.
    }
    elsif ($el eq 'cloud') {
        if (keys %attribs) {
            $self->{channel}{cloud} = \%attribs;
        }
    }
    elsif ($el eq 'item') {

        # deal with trouble makers who use mod_content :)

        my ($ns, $verdict) = $self->_get_elem_namespace($el);

        if ($verdict) {

            # Sanity check to make sure we don't have nested elements that
            # can confuse the parser.
            if (!defined($self->{_inside_item_elem})) {

                # increment item count
                $self->{num_items}++;
                $self->{_inside_item_elem} = $parser->depth();
            }
        }
        # handle xml:base
        $self->_last_item->{'xml:base'} = $attribs{'base'} if exists $attribs{'base'};


        # guid element is a permanent link unless isPermaLink attribute is set to false
    }
    elsif ($el eq 'guid') {
        $self->_last_item->{'isPermaLink'} =
          ( (!exists($attribs{'isPermaLink'})) || (lc($attribs{'isPermaLink'}) ne 'false') );

        # beginning of taxo li element in item element
        #'http://purl.org/rss/1.0/modules/taxonomy/' => 'taxo'
    }
    elsif (
           $self->_current_element eq "item"
        && (($el eq "category") ||
            (
                   exists($self->{modules}->{$el_ns})
                && ($self->{modules}->{$el_ns} eq "dc")
            )
        )
    ) {
        $self->_start_array_element_in_struct($self->_last_item, $el);
    }
    elsif (
        $parser->within_element(
            $parser->generate_ns_name("topics", 'http://purl.org/rss/1.0/modules/taxonomy/')
        )
        && $parser->within_element($parser->generate_ns_name("item", $namespace_map->{'rss10'}))
        && $self->_current_element eq 'Bag'
        && $el                    eq 'li'
      )
    {

        #print "taxo: ", $attribs{'resource'},"\n";
        push(@{$self->_last_item->{'taxo'}}, $attribs{'resource'});
        $self->{'modules'}->{'http://purl.org/rss/1.0/modules/taxonomy/'} = 'taxo';

        # beginning of taxo li in channel element
    }
    elsif (
        $parser->within_element(
            $parser->generate_ns_name("topics", 'http://purl.org/rss/1.0/modules/taxonomy/')
        )
        && $parser->within_element($parser->generate_ns_name("channel", $namespace_map->{'rss10'}))
        && $self->_current_element eq 'Bag'
        && $el                    eq 'li'
      )
    {
        push(@{$self->{'channel'}->{'taxo'}}, $attribs{'resource'});
        $self->{'modules'}->{'http://purl.org/rss/1.0/modules/taxonomy/'} = 'taxo';
    }

    # beginning of a channel element that stores its info in rdf:resource
    elsif ( $parser->namespace($el)
        && $self->_is_rdf_resource($el)
        && $self->_current_element eq 'channel')
    {
        my $ns = $parser->namespace($el);

        # Commented out by shlomif - the RSS namespaces are not present
        # in the 'rdf_resource_fields' so this condition always evaluates
        # to false.
        # if ( $ns eq $self->{rss_namespace} ) {
        #     $self->{channel}->{$el} = $attribs{resource};
        # }
        # else

        {
            $self->{channel}->{$ns}->{$el} = $attribs{resource};

            # add short cut
            #
            if (exists($self->{modules}->{$ns})) {
                $ns = $self->{modules}->{$ns};
                $self->{channel}->{$ns}->{$el} = $attribs{resource};
            }
        }
    }
    # beginning of an item element that stores its info in rdf:resource
    elsif ( $parser->namespace($el)
        && $self->_is_rdf_resource($el)
        && $self->_current_element eq 'item')
    {
        my $ns = $parser->namespace($el);

        # Commented out by shlomif - the RSS namespaces are not present
        # in the 'rdf_resource_fields' so this condition always evaluates
        # to false.
        # if ( $ns eq $self->{rss_namespace} ) {
        #   $self->_last_item->{ $el } = $attribs{resource};
        # }
        # else
        {
            $self->_last_item->{$ns}->{$el} = $attribs{resource};

            # add short cut
            #
            if (exists($self->{modules}->{$ns})) {
                $ns = $self->{modules}->{$ns};
                $self->_last_item->{$ns}->{$el} = $attribs{resource};
            }
        }
    }
    elsif ($self->_should_be_hashref($el) and $self->_current_element eq 'item') {
        if (defined $attribs{base}) {
            $attribs{'xml:base'} = delete $attribs{base};
        }
        if (keys(%attribs)) {
            if ($el_verdict) {
                $self->_last_item->{$el} =
                  $self->_make_array($el, $self->_last_item->{$el}, \%attribs);
            }
            else {
                $self->_last_item->{$el_ns}->{$el} =
                  $self->_make_array($el, $self->_last_item->{$el_ns}->{$el}, \%attribs);

                my $prefix = $self->{modules}->{$el_ns};

                if ($prefix) {
                    $self->_last_item->{$prefix}->{$el} =
                      $self->_make_array($el, $self->_last_item->{$prefix}->{$el}, \%attribs);
                }
            }
        }
    }
    elsif ($self->_start_array_element("image", $el)) {
        # Do nothing - already done in the predicate.
    }
    elsif (($el eq "category") &&
        (!$parser->within_element("item")) &&
        $self->_start_array_element("channel", $el)) {
        # Do nothing - already done in the predicate.
    }
    elsif (($self->_current_element eq 'channel') &&
           ($el_verdict))
           {
        # Make sure an opening tag signifies that the element has been
        # encountered.
        if (   exists($self->{'channel'}->{$el})
            && (!defined($self->{'channel'}->{$el})))
        {
            $self->{'channel'}->{$el} = "";
        }
    }
}

sub _make_array {
    my $self = shift;
    my $el   = shift;
    my $old  = shift;
    my $new  = shift;

    if (!$self->_allow_multiple($el)) {
      return $new;
    }

    if (!defined $old) {
        $old = [];
    } elsif (ref($old) ne 'ARRAY') {
        $old = [$old];
    }
    push @$old, $new;
    return $old;
}

sub _allow_multiple {
    my $self = shift;
    my $el   = shift;

    $self->{_allow_multiple} ||=
        {
            map { $_ => 1 }
            @{$self->_parse_options->{allow_multiple} || []}
        };

    return $self->{_allow_multiple}->{$el};
}

sub _handle_end {
    my ($self, $el) = @_;

    if (defined($self->{_inside_item_elem})
        && $self->{_inside_item_elem} == $self->_parser->depth())
    {
        delete($self->{_inside_item_elem});
    }
}

sub _auto_add_modules {
    my $self = shift;

    for my $ns (keys %{$self->{namespaces}}) {

        # skip default namespaces
        next
          if $ns eq "rdf"
          || $ns eq "#default"
          || exists $self->{modules}{$self->{namespaces}{$ns}};
        $self->add_module(prefix => $ns, uri => $self->{namespaces}{$ns});
    }

    $self;
}

sub _parser {
    my $self = shift;

    if (@_) {
        $self->{_parser} = shift;
    }
    return $self->{_parser};
}

sub _get_parser {
    my $self = shift;

    return XML::Parser->new(
        Namespaces    => 1,
        NoExpand      => 1,
        ParseParamEnt => 0,
        Handlers      => {
            Char    => sub {
                my ($parser, $cdata) = @_;
                $self->_parser($parser);
                $self->_handle_char($cdata);
                # Detach the parser to avoid reference loops.
                $self->_parser(undef);
            },
            XMLDecl => sub {
                my $parser = shift;
                $self->_parser($parser);
                $self->_handle_dec(@_);
                # Detach the parser to avoid reference loops.
                $self->_parser(undef);
            },
            Start   => sub {
                my $parser = shift;
                $self->_parser($parser);
                $self->_handle_start(@_);
                # Detach the parser to avoid reference loops.
                $self->_parser(undef);
            },
            End     => sub {
                my $parser = shift;
                $self->_parser($parser);
                $self->_handle_end(@_);
                # Detach the parser to avoid reference loops.
                $self->_parser(undef);
            },
            ExternEnt => sub {
                return '';
            },
        }
    );
}

sub _parse_options {
    my $self = shift;

    if (@_) {
        $self->{_parse_options} = shift;
    }

    return $self->{_parse_options};
}

sub _empty {}

sub _generic_parse {
    my $self = shift;
    my $method = shift;
    my $arg = shift;
    my $options = shift;

    $self->_reset;

    $self->_parse_options($options || {});

    # Workaround to make sure that if we were defined with version => "2.0"
    # then we can still parse 1.0 and 0.9.x feeds correctly.
    if ($self->{version} eq "2.0") {
        $self->{modules} = +{%{$self->_get_default_modules()}, %{$self->{modules}}};
    }

    {
        my $parser = $self->_get_parser();

        eval {
            $parser->$method($arg);
        };

        if ($@)
        {
            my $err = $@;

            # Cleanup so perl-5.6.2 will be happy.
            $parser->setHandlers(
                map { ($_ => \&_empty) } (qw(Char XMLDecl Start End))
            );
            $self->_parser(0);

            undef($parser);

            die $err;
        }
    }

    $self->_auto_add_modules if $AUTO_ADD;
    $self->{version} = $self->{_internal}->{version};

    return $self;
}

sub parse {
    my $self = shift;
    my $text_to_parse = shift;
    my $options = shift;

    return $self->_generic_parse("parse", $text_to_parse, $options);
}

sub parsefile {
    my $self = shift;
    my $file_to_parse = shift;
    my $options = shift;

    return $self->_generic_parse("parsefile", $file_to_parse, $options);
}

sub _untaint {
    my $self = shift;

    my $value = shift;

    my ($untainted) = ($value =~ m{(.*)}s);

    return $untainted;
}

sub _get_save_output_mode {
    my $self = shift;

    return (">:encoding(" . $self->_untaint($self->_encoding()) . ")");
}

sub save {
    my ($self, $file) = @_;

    local (*OUT);

    open(OUT, $self->_get_save_output_mode(), "$file")
      or croak "Cannot open file $file for write: $!";
    print OUT $self->as_string;
    close OUT;
}

sub strict {
    my ($self, $value) = @_;
    $self->{'strict'} = $value;
}

sub _handle_accessor {
    my $self = shift;
    my $name = shift;

    my $type = ref($self);

    croak "Unregistered entity: Can't access $name field in object of class $type"
      unless (exists $self->{$name});

    # return reference to RSS structure
    if (@_ == 1) {
        return $self->{$name}->{$_[0]};

        # we're going to set values here
    }
    elsif (@_ > 1) {
        my %hash = @_;
        my $_REQ;

        # make sure we have required elements and correct lengths
        if ($self->{'strict'}) {
            ($self->{version} eq '0.9')
              ? ($_REQ = $_REQ_v0_9)
              : ($_REQ = $_REQ_v0_9_1);
        }

        # store data in object
        foreach my $key (keys(%hash)) {
            if ($self->{'strict'}) {
                my $req_element = $_REQ->{$name}->{$key};
                confess "$key cannot exceed " . $req_element->[1] . " characters in length"
                  if defined $req_element->[1] && length($hash{$key}) > $req_element->[1];
            }
            $self->{$name}->{$key} = $hash{$key};
        }

        # return value
        return $self->{$name};

        # otherwise, just return a reference to the whole thing
    }
    else {
        return $self->{$name};
    }

    # make sure we have all required elements
    #foreach my $key (keys(%{$_REQ->{$name}})) {
    #my $element = $_REQ->{$name}->{$key};
    #croak "$key is required in $name"
    #if ($element->[0] == 1) && (!defined($hash{$key}));
    #croak "$key cannot exceed ".$element->[1]." characters in length"
    #unless length($hash{$key}) <= $element->[1];
    #}
}

sub _modules {
    my $self = shift;
    return $self->_handle_accessor("modules", @_);;
}

sub channel {
    my $self = shift;

    return $self->_handle_accessor("channel", @_);
}

sub image {
    my $self = shift;

    return $self->_handle_accessor("image", @_);
}

sub textinput {
    my $self = shift;

    return $self->_handle_accessor("textinput", @_);
}

sub skipDays {
    my $self = shift;

    return $self->_handle_accessor("skipDays", @_);
}

sub skipHours {
    my $self = shift;

    return $self->_handle_accessor("skipHours", @_);
}

### Read only, scalar accessors

sub _encode_output {
    my $self = shift;

    return $self->{'encode_output'};
}

sub _encoding {
    my $self = shift;

    return $self->{'encoding'};
}

sub _stylesheet {
    my $self = shift;

    return $self->{'stylesheet'};
}

sub _get_items {
    my $self = shift;

    return $self->{items};
}

1;

__END__

=pod

=head1 NAME

XML::RSS - creates and updates RSS files

=head1 VERSION

version 1.60

=head1 SYNOPSIS

 # create an RSS 1.0 file (http://purl.org/rss/1.0/)
 use XML::RSS;
 my $rss = XML::RSS->new(version => '1.0');
 $rss->channel(
   title        => "freshmeat.net",
   link         => "http://freshmeat.net",
   description  => "the one-stop-shop for all your Linux software needs",
   dc => {
     date       => '2000-08-23T07:00+00:00',
     subject    => "Linux Software",
     creator    => 'scoop@freshmeat.net',
     publisher  => 'scoop@freshmeat.net',
     rights     => 'Copyright 1999, Freshmeat.net',
     language   => 'en-us',
   },
   syn => {
     updatePeriod     => "hourly",
     updateFrequency  => "1",
     updateBase       => "1901-01-01T00:00+00:00",
   },
   taxo => [
     'http://dmoz.org/Computers/Internet',
     'http://dmoz.org/Computers/PC'
   ]
 );

 $rss->image(
   title  => "freshmeat.net",
   url    => "http://freshmeat.net/images/fm.mini.jpg",
   link   => "http://freshmeat.net",
   dc => {
     creator  => "G. Raphics (graphics at freshmeat.net)",
   },
 );

 $rss->add_item(
   title       => "GTKeyboard 0.85",
   link        => "http://freshmeat.net/news/1999/06/21/930003829.html",
   description => "GTKeyboard is a graphical keyboard that ...",
   dc => {
     subject  => "X11/Utilities",
     creator  => "David Allen (s2mdalle at titan.vcu.edu)",
   },
   taxo => [
     'http://dmoz.org/Computers/Internet',
     'http://dmoz.org/Computers/PC'
   ]
 );

 $rss->textinput(
   title        => "quick finder",
   description  => "Use the text input below to search freshmeat",
   name         => "query",
   link         => "http://core.freshmeat.net/search.php3",
 );

 # Optionally mixing in elements of a non-standard module/namespace

 $rss->add_module(prefix=>'my', uri=>'http://purl.org/my/rss/module/');

 $rss->add_item(
   title       => "xIrc 2.4pre2",
   link        => "http://freshmeat.net/projects/xirc/",
   description => "xIrc is an X11-based IRC client which ...",
   my => {
     rating    => "A+",
     category  => "X11/IRC",
   },
 );

  $rss->add_item (title=>$title, link=>$link, slash=>{ topic=>$topic });

 # create an RSS 2.0 file
 use XML::RSS;
 my $rss = XML::RSS->new (version => '2.0');
 $rss->channel(title          => 'freshmeat.net',
               link           => 'http://freshmeat.net',
               language       => 'en',
               description    => 'the one-stop-shop for all your Linux software needs',
               rating         => '(PICS-1.1 "http://www.classify.org/safesurf/" 1 r (SS~~000 1))',
               copyright      => 'Copyright 1999, Freshmeat.net',
               pubDate        => 'Thu, 23 Aug 1999 07:00:00 GMT',
               lastBuildDate  => 'Thu, 23 Aug 1999 16:20:26 GMT',
               docs           => 'http://www.blahblah.org/fm.cdf',
               managingEditor => 'scoop@freshmeat.net',
               webMaster      => 'scoop@freshmeat.net'
               );

 $rss->image(title       => 'freshmeat.net',
             url         => 'http://freshmeat.net/images/fm.mini.jpg',
             link        => 'http://freshmeat.net',
             width       => 88,
             height      => 31,
             description => 'This is the Freshmeat image stupid'
             );

 $rss->add_item(title => "GTKeyboard 0.85",
        # creates a guid field with permaLink=true
        permaLink  => "http://freshmeat.net/news/1999/06/21/930003829.html",
        # alternately creates a guid field with permaLink=false
        # guid     => "gtkeyboard-0.85"
        enclosure   => { url=>$url, type=>"application/x-bittorrent" },
        description => 'blah blah'
);

 $rss->textinput(title => "quick finder",
                 description => "Use the text input below to search freshmeat",
                 name  => "query",
                 link  => "http://core.freshmeat.net/search.php3"
                 );

 # create an RSS 0.9 file
 use XML::RSS;
 my $rss = XML::RSS->new( version => '0.9' );
 $rss->channel(title => "freshmeat.net",
               link  => "http://freshmeat.net",
               description => "the one-stop-shop for all your Linux software needs",
               );

 $rss->image(title => "freshmeat.net",
             url   => "http://freshmeat.net/images/fm.mini.jpg",
             link  => "http://freshmeat.net"
             );

 $rss->add_item(title => "GTKeyboard 0.85",
                link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
                );

 $rss->textinput(title => "quick finder",
                 description => "Use the text input below to search freshmeat",
                 name  => "query",
                 link  => "http://core.freshmeat.net/search.php3"
                 );

 # print the RSS as a string
 print $rss->as_string;

 # or save it to a file
 $rss->save("fm.rdf");

 # insert an item into an RSS file and removes the oldest ones if
 # there are already 15 items or more
 my $rss = XML::RSS->new;
 $rss->parsefile("fm.rdf");

 while (@{$rss->{'items'}} >= 15)
 {
     shift (@{ $rss->{'items'} });
 }

 $rss->add_item(title => "MpegTV Player (mtv) 1.0.9.7",
                link  => "http://freshmeat.net/news/1999/06/21/930003958.html",
                mode  => 'insert'
                );

 # parse a string instead of a file
 $rss->parse($string);

 # print the title and link of each RSS item
 foreach my $item (@{$rss->{'items'}}) {
     print "title: $item->{'title'}\n";
     print "link: $item->{'link'}\n\n";
 }

 # output the RSS 0.9 or 0.91 file as RSS 1.0
 $rss->{output} = '1.0';
 print $rss->as_string;

=head1 DESCRIPTION

This module provides a basic framework for creating and maintaining
RDF Site Summary (RSS) files. This distribution also contains many
examples that allow you to generate HTML from an RSS, convert between
0.9, 0.91, and 1.0 version, and other nifty things.
This might be helpful if you want to include news feeds on your Web
site from sources like Slashdot and Freshmeat or if you want to syndicate
your own content.

XML::RSS currently supports 0.9, 0.91, and 1.0 versions of RSS.
See http://backend.userland.com/rss091 for information on RSS 0.91.
See http://www.purplepages.ie/RSS/netscape/rss0.90.html for RSS 0.9.
See http://web.resource.org/rss/1.0/ for RSS 1.0.

RSS was originally developed by Netscape as the format for
Netscape Netcenter channels, however, many Web sites have since
adopted it as a simple syndication format. With the advent of RSS 1.0,
users are now able to syndication many different kinds of content
including news headlines, threaded messages, products catalogs, etc.

B<Note:> In order to parse and generate dates (such as C<pubDate>
and C<dc:date>) it is recommended to use L<DateTime::Format::Mail> and
L<DateTime::Format::W3CDTF> , which is what L<XML::RSS> uses internally
and requires.

=head1 VERSION

version 1.60

=head1 METHODS

=over 4

=item XML::RSS->new(version=>$version, encoding=>$encoding, output=>$output, stylesheet=>$stylesheet_url, 'xml:base'=>$base)

Constructor for XML::RSS. It returns a reference to an XML::RSS object.
You may also pass the RSS version and the XML encoding to use. The default
B<version> is 1.0. The default B<encoding> is UTF-8. You may also specify
the B<output> format regardless of the input version. This comes in handy
when you want to convert RSS between versions. The XML::RSS modules
will convert between any of the formats.  If you set <encode_output> XML::RSS
will make sure to encode any entities in generated RSS.  This is now on by
default.

You can also pass an optional URL to an XSL stylesheet that can be used to
output an C<<< <?xsl-stylesheet ... ?> >>> meta-tag in the header that will
allow some browsers to render the RSS file as HTML.

You can also set C<encode_cb> to a reference to a subroutine that will
encode the output in a custom way. This subroutine accepts two parameters:
a reference to the C<XML::RSS::Private::Output::Base>-derived object (which
should normally not concern you) and the text to encode. It should return
the text to encode. If not set, then the module will encode using its
custom encoding routine.

xml:base will set an C<xml:base> property as per

    http://www.w3.org/TR/xmlbase/

Note that in order to encode properly, you need to handle "CDATA" sections
properly. Look at L<XML::RSS::Private::Output::Base>'s C<_default_encode()>
method for how to do it properly.

=item add_item (title=>$title, link=>$link, description=>$desc, mode=>$mode)

Adds an item to the XML::RSS object. B<mode> and B<description> are optional.
The default B<mode>
is append, which adds the item to the end of the list. To insert an item, set the mode
to B<insert>.

The items are stored in the array C<< @{$obj->{'items'}} >> where
B<$obj> is a reference to an XML::RSS object.

One can specify a category by using the B<'category'> key. B<'category'> can
point to an array reference of categories:

    $rss->add_item(
        title => "Foo&Bar",
        link => "http://www.my.tld/",
        category => ["OneCat", "TooCat", "3Kitties"],
    );

=item as_string;

Returns a string containing the RSS for the XML::RSS object.  This
method will also encode special characters along the way.

=item channel (title=>$title, link=>$link, description=>$desc, language=>$language, rating=>$rating, copyright=>$copyright, pubDate=>$pubDate, lastBuildDate=>$lastBuild, docs=>$docs, managingEditor=>$editor, webMaster=>$webMaster)

Channel information is required in RSS. The B<title> cannot
be more the 40 characters, the B<link> 500, and the B<description>
500 when outputting RSS 0.9. B<title>, B<link>, and B<description>,
are required for RSS 1.0. B<language> is required for RSS 0.91.
The other parameters are optional for RSS 0.91 and 1.0.

To retrieve the values of the channel, pass the name of the value
(title, link, or description) as the first and only argument
like so:

$title = channel('title');

=item image (title=>$title, url=>$url, link=>$link, width=>$width, height=>$height, description=>$desc)

Adding an image is not required. B<url> is the URL of the
image, B<link> is the URL the image is linked to. B<title>, B<url>,
and B<link> parameters are required if you are going to
use an image in your RSS file. The remaining image elements are used
in RSS 0.91 or optionally imported into RSS 1.0 via the rss091 namespace.

The method for retrieving the values for the image is the same as it
is for B<channel()>.

=item parse ($string, \%options)

Parses an RDF Site Summary which is passed into B<parse()> as the first
parameter. Returns the instance of the object so one can say
C<< $rss->parse($string)->other_method() >>.

See the add_module() method for instructions on automatically adding
modules as a string is parsed.

%options is a list of options that specify how parsing is to be done. The
available options are:

=over 4

=item * allow_multiple

Takes an array ref of names which indicates which elements should
be allowed to have multiple occurrences. So, for example, to parse
feeds with multiple enclosures

   $rss->parse($xml, { allow_multiple => ['enclosure'] });

=item * hashrefs_instead_of_strings

If true, then some items (so far "C<description>") will become hash-references
instead of strings (with a B<content> key containing their content , B<if>
they have XML attributes. Without this key, the attributes will be ignored
and there will only be a string. Thus, specifying this option may break
compatibility.

=item * modules_as_arrays

This option when true, will parse the modules key-value-pairs as an arrayref of
C<<< { el => $key_name, value => $value, } >>> hash-refs to gracefully
handle duplicate items (see below). It will not affect the known modules such
as dc ("Dublin Core").

=back

=item parsefile ($file, \%options)

Same as B<parse()> except it parses a file rather than a string.

See the add_module() method for instructions on automatically adding
modules as a string is parsed.

=item save ($file)

Saves the RSS to a specified file.

=item skipDays (day => $day)

Populates the skipDays element with the day $day.

=item skipHours (hour => $hour)

Populates the skipHours element, with the hour $hour.

=item strict ($boolean)

If it's set to 1, it will adhere to the lengths as specified
by Netscape Netcenter requirements. It's set to 0 by default.
Use it if the RSS file you're generating is for Netcenter.
strict will only work for RSS 0.9 and 0.91. Do not use it for
RSS 1.0.

=item textinput (title=>$title, description=>$desc, name=>$name, link=>$link);

This RSS element is also optional. Using it allows users to submit a Query
to a program on a Web server via an HTML form. B<name> is the HTML form name
and B<link> is the URL to the program. Content is submitted using the GET
method.

Access to the B<textinput> values is the same as B<channel()> and
B<image()>.

=item add_module(prefix=>$prefix, uri=>$uri)

Adds a module namespace declaration to the XML::RSS object, allowing you
to add modularity outside of the standard RSS 1.0 modules.  At present,
the standard modules Dublin Core (dc) and Syndication (syn) are predefined
for your convenience. The Taxonomy (taxo) module is also internally supported.

The modules are stored in the hash %{$obj->{'modules'}} where
B<$obj> is a reference to an XML::RSS object.

If you want to automatically add modules that the parser finds in
namespaces, set the $XML::RSS::AUTO_ADD variable to a true value.  By
default the value is false. (N.B. AUTO_ADD only updates the
%{$obj->{'modules'}} hash.  It does not provide the other benefits
of using add_module.)

=back

=head2 RSS 1.0 MODULES

XML-Namespace-based modularization affords RSS 1.0 compartmentalized
extensibility.  The only modules that ship "in the box" with RSS 1.0
are Dublin Core (http://purl.org/rss/1.0/modules/dc/), Syndication
(http://purl.org/rss/1.0/modules/syndication/), and Taxonomy
(http://purl.org/rss/1.0/modules/taxonomy/).  Consult the appropriate
module's documentation for further information.

Adding items from these modules in XML::RSS is as simple as adding other
attributes such as title, link, and description.  The only difference
is the compartmentalization of their key/value paris in a second-level
hash.

  $rss->add_item (title=>$title, link=>$link, dc=>{ subject=>$subject, creator=>$creator, date=>$date });

For elements of the Dublin Core module, use the key 'dc'.  For elements
of the Syndication module, 'syn'.  For elements of the Taxonomy module,
'taxo'. These are the prefixes used in the RSS XML document itself.
They are associated with appropriate URI-based namespaces:

  syn:  http://purl.org/rss/1.0/modules/syndication/
  dc:   http://purl.org/dc/elements/1.1/
  taxo: http://purl.org/rss/1.0/modules/taxonomy/

The Dublin Core ('dc') hash keys may be point to an array
reference, which in turn will specify multiple such keys, and render them
one after the other. For example:

    $rss->add_item (
        title => $title,
        link => $link,
        dc => {
            subject=> ["Jungle", "Desert", "Swamp"],
            creator=>$creator,
            date=>$date
        },
    );

Dublin Core elements may occur in channel, image, item(s), and textinput
-- albeit uncomming to find them under image and textinput.  Syndication
elements are limited to the channel element. Taxonomy elements can occur
in the channel or item elements.

Access to module elements after parsing an RSS 1.0 document using
XML::RSS is via either the prefix or namespace URI for your convenience.

  print $rss->{items}->[0]->{dc}->{subject};

  or

  print $rss->{items}->[0]->{'http://purl.org/dc/elements/1.1/'}->{subject};

XML::RSS also has support for "non-standard" RSS 1.0 modularization at
the channel, image, item, and textinput levels.  Parsing an RSS document
grabs any elements of other namespaces which might appear.  XML::RSS
also allows the inclusion of arbitrary namespaces and associated elements
when building  RSS documents.

For example, to add elements of a made-up "My" module, first declare the
namespace by associating a prefix with a URI:

  $rss->add_module(prefix=>'my', uri=>'http://purl.org/my/rss/module/');

Then proceed as usual:

  $rss->add_item (title=>$title, link=>$link, my=>{ rating=>$rating });

You can also set the value of the module's prefix to an array reference
of C<<< { el => , val => } >>> hash-references, in which case duplicate
elements are possible:

  $rss->add_item(title=>$title, link=>$link, my=> [
    {el => "rating", value => $rating1, }
    {el => "rating", value => $rating2, },
  ]

Non-standard namespaces are not, however, currently accessible via a simple
prefix; access them via their namespace URL like so:

  print $rss->{items}->[0]->{'http://purl.org/my/rss/module/'}->{rating};

XML::RSS will continue to provide built-in support for standard RSS 1.0
modules as they appear.

=head1 Non-API Methods

=head2 $rss->as_rss_0_9()

B<WARNING>: this function is not an API function and should not be called
directly. It is kept as is for backwards compatibility with legacy code. Use
the following code instead:

    $rss->{output} = "0.9";
    my $text = $rss->as_string();

This function renders the data in the object as an RSS version 0.9 feed,
and returns the resultant XML as text.

=head2 $rss->as_rss_0_9_1()

B<WARNING>: this function is not an API function and should not be called
directly. It is kept as is for backwards compatibility with legacy code. Use
the following code instead:

    $rss->{output} = "0.91";
    my $text = $rss->as_string();

This function renders the data in the object as an RSS version 0.91 feed,
and returns the resultant XML as text.

=head2 $rss->as_rss_1_0()

B<WARNING>: this function is not an API function and should not be called
directly. It is kept as is for backwards compatibility with legacy code. Use
the following code instead:

    $rss->{output} = "1.0";
    my $text = $rss->as_string();

This function renders the data in the object as an RSS version 1.0 feed,
and returns the resultant XML as text.

=head2 $rss->as_rss_2_0()

B<WARNING>: this function is not an API function and should not be called
directly. It is kept as is for backwards compatibility with legacy code. Use
the following code instead:

    $rss->{output} = "2.0";
    my $text = $rss->as_string();

This function renders the data in the object as an RSS version 2.0 feed,
and returns the resultant XML as text.

=head2 $rss->handle_char()

Needed for XML::Parser. Don't use this directly.

=head2 $rss->handle_dec()

Needed for XML::Parser. Don't use this directly.

=head2 $rss->handle_start()

Needed for XML::Parser. Don't use this directly.

=head1 BUGS

Please use rt.cpan.org for tracking bugs.  The list of current open
bugs is at
    L<http://rt.cpan.org/Dist/Display.html?Queue=XML-RSS>.

To report a new bug, go to
    L<http://rt.cpan.org/Ticket/Create.html?Queue=XML-RSS>

Please include a failing test in your bug report.  I'd much rather
have a well written test with the bug report than a patch.

When you create diffs (for tests or patches), please use the C<-u>
parameter to diff.

=head1 SOURCE AVAILABILITY

The source is available from the GitHub repository:

L<https://github.com/shlomif/perl-XML-RSS>

=head1 AUTHOR

Original code: Jonathan Eisenzopf <eisen@pobox.com>

Further changes: Rael Dornfest <rael@oreilly.com>, Ask Bjoern Hansen
<ask@develooper.com>

Currently: Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2001 Jonathan Eisenzopf <eisen@pobox.com> and Rael
Dornfest <rael@oreilly.com>, Copyright (C) 2006-2007 Ask Bjoern Hansen
<ask@develooper.com>.

=head1 LICENSE

XML::RSS is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 CREDITS

 Wojciech Zwiefka <wojtekz@cnt.pl>
 Chris Nandor <pudge@pobox.com>
 Jim Hebert <jim@cosource.com>
 Randal Schwartz <merlyn@stonehenge.com>
 rjp@browser.org
 Kellan Elliott-McCrea <kellan@protest.net>
 Rafe Colburn <rafe@rafe.us>
 Adam Trickett <atrickett@cpan.org>
 Aaron Straup Cope <asc@vineyard.net>
 Ian Davis <iand@internetalchemy.org>
 rayg@varchars.com
 Shlomi Fish <shlomif@cpan.org>

=head1 SEE ALSO

perl(1), XML::Parser(3).

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Various.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-XML-RSS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::RSS

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-RSS>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-RSS>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-RSS>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-RSS>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-RSS>

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

=cut

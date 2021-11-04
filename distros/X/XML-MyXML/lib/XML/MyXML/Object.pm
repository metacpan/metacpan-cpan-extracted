package XML::MyXML::Object;

use strict;
use warnings;

use XML::MyXML::Util 'trim', 'strip_ns';

use Encode;
use Carp;
use Scalar::Util 'weaken';

our $VERSION = "1.08";

sub new {
    my $class = shift;
    my $xml = shift;

    return bless XML::MyXML::xml_to_object($xml), $class;
}

my $ch0 = chr(0);
sub _string_unescape {
    my $string = shift;

    defined $string or return undef;

    my $ret = eval "qq${ch0}$string${ch0}";
    defined $ret or croak "Can't unescape this string: $string";

    return $ret;
}

sub _parse_description {
    my ($desc) = @_;

    my ($el_name, $el_ns, $attrs_str) = $desc =~ /
        # start anchor
        ^

        # element name
        (
            (?:
                    \\ \[
                |
                    \\ \{
                |
                    [^\[\{]
            )*
        )

        # element namespace
        (?:
            # opening curly bracket
            \{

                # namespace name
                ((?:   \\ \}   |   [^\}]   )*)

            # closing curly bracket
            \}
        )?

        # attributes string
        (.*)

        # end anchor
        \z
    /x;

    my @attrs = $attrs_str =~ /
        # opening square bracket
        \[

            # attribute name
            (
                # attribute characters
                (?:   \\ \]   |   \\ \=   |   \\ \{   |   [^\]\=\{]   )+
            )

            # optional namespace
            (?:
                # opening curly bracket
                \{

                    # namespace name
                    ((?:   \\ \}   |   [^\}]   )*)

                # closing curly bracket
                \}
            )?

            # value option
            (?:
                # equals sign
                \=

                # value
                (
                    (?:   \\ \]   |   [^\]]   )*
                )
            )?

        # closing square bracket
        \]
    /gx;

    my %attrs;
    while (@attrs) {
        my ($attr_name, $attr_ns, $attr_value) = splice @attrs, 0, 3;
        # $attr_value =~ s/^\"|\"\z//g if defined $attr_value;
        $attrs{_string_unescape $attr_name} = {
            ns    => _string_unescape($attr_ns),
            value => _string_unescape($attr_value),
        };
    }

    return ($el_name, $el_ns, \%attrs);
}

sub cmp_element {
    my ($self, $desc) = @_;

    my ($el_name, $el_ns, $attrs) = ref $desc
        ? @$desc{qw/ el_name el_ns attrs /}
        : _parse_description($desc);

    # check element name
    if (length $el_name) {
        if (! defined $el_ns) {
            $self->{el_name} eq $el_name or return 0;
        } elsif (length $el_ns) {
            $el_name !~ /\:/ or croak 'You can either have a ns requirement, or a ":" in your path segment';
            exists $self->{ns_data}{"$el_ns:"}      or return 0;
            strip_ns($self->{el_name}) eq $el_name  or return 0;
        } else {
            # ! grep /\:\z/, keys %{ $self->{ns_data} }   or return 0;
            # $self->{el_name} eq $el_name                or return 0;
            croak 'empty ns in path segment';
        }
    }

    # check attributes
    foreach my $attr_name (keys %$attrs) {
        my ($attr_ns, $attr_value) = @{ $attrs->{$attr_name} }{qw/ ns value /};
        if (! defined $attr_ns) {
            my $actual_attr_value = $self->attr($attr_name);
            defined $actual_attr_value                                  or return 0;
            ! defined $attr_value or $attr_value eq $actual_attr_value  or return 0;
        } elsif (length $attr_ns) {
            $attr_name !~ /\:/ or croak 'You can either have a ns requirement, or a ":" in your path segment';
            my $actual_attr_value = $self->{ns_data}{"$attr_ns:$attr_name"};
            defined $actual_attr_value                                  or return 0;
            ! defined $attr_value or $attr_value eq $actual_attr_value  or return 0;
        } else {
            # my $actual_attr_value = $self->attr($attr_name);
            # defined $actual_attr_value or return 0;
            # ! exists $self->{ns_data}{}
            croak 'empty ns in path segment';
        }
    }

    return 1;
}

sub children {
    my $self = shift;
    my $path_segment = shift;

    $path_segment = '' if ! defined $path_segment;

    my @all_children = grep { defined $_->{el_name} } @{$self->{content}};
    length $path_segment or return @all_children;

    my ($el_name, $el_ns, $attrs) = _parse_description($path_segment);
    my $desc = { el_name => $el_name, el_ns => $el_ns, attrs => $attrs };

    return grep $_->cmp_element($desc), @all_children;
}

sub path {
    my $self = shift;
    my $path = shift;

    my $original_path = $path;
    my $path_starts_with_root = $path =~ m|^/|;
    $path = "/$path" unless $path_starts_with_root;
    my @path_segments = $path =~ m!
        # slash
        \/

        (
            # allowed strings
            (?:
                    # escaped "/"
                    \\ \/
                |
                    # escaped "["
                    \\ \[
                |
                    # escaped "{"
                    \\ \{
                |
                    # non- "/", "[", "]"
                    [^\/\[\{]
                |
                    # attribute
                    \[
                        (?:   \\ \]   |   [^\]]   )*
                    \]
                |
                    # namespace
                    \{
                        (?:   \\ \}   |   [^\}]   )*
                    \}
            )*
        )
    !gx;

    my @result = ($self);
    $self->cmp_element(shift @path_segments) or return if $path_starts_with_root;
    foreach my $path_segment (@path_segments) {
        @result = map $_->children($path_segment), @result or return;
    }
    return wantarray ? @result : $result[0];
}

sub text {
    my $self = shift;
    my $flags = (@_ and ref $_[-1]) ? pop : {};
    my $set_value = @_ ? (defined $_[0] ? shift : '') : undef;

    if (! defined $set_value) {
        my $value = '';
        if ($self->{content}) {
            $value .= $_->text($flags) foreach @{ $self->{content} };
        }
        if ($self->{text}) {
            my $temp_value = $self->{text};
            $temp_value = trim $temp_value if $flags->{strip};
            $value .= $temp_value;
        }
        return $value;
    } else {
        if (length $set_value) {
            my $entry = bless {
                text => $set_value,
                parent => $self
            }, 'XML::MyXML::Object';
            weaken $entry->{parent};
            $self->{content} = [ $entry ];
        } else {
            $self->{content} = [];
        }
    }
}

*value = \&text;

sub inner_xml {
    my $self = shift;
    my $flags = (@_ and ref $_[-1]) ? pop : {};
    my $set_xml = @_ ? defined $_[0] ? shift : '' : undef;

    if (! defined $set_xml) {
        my $xml = $self->to_xml($flags);
        $xml =~ s/^\<.*?\>//s;
        $xml =~ s/\<\/[^\>]*\>\z//s; # nothing to remove if empty element
        return $xml;
    } else {
        my $xml = "<div>$set_xml</div>";
        my $obj = XML::MyXML::xml_to_object($xml, $flags);
        $self->{content} = [];
        foreach my $child (@{ $obj->{content} || [] }) {
            $child->{parent} = $self;
            weaken $child->{parent};
            push @{ $self->{content} }, $child;
            $child->_apply_namespace_declarations if $child->{el_name};
        }
    }
}

sub attr {
    my $self = shift;
    my $attr_name = shift;
    my $flags = ref $_[-1] ? pop : {};
    my ($set_to, $must_set);
    if (@_) {
        $set_to = shift;
        $must_set = 1;
    }

    if (defined $attr_name) {
        if ($must_set) {
            if (defined ($set_to)) {
                $self->{attrs}{$attr_name} = $set_to;
            } else {
                delete $self->{attrs}{$attr_name};
            }
            if ($attr_name =~ /^xmlns(\:|\z)/) {
                $self->_apply_namespace_declarations;
            }
            return $set_to;
        } else {
            return $self->{attrs}->{$attr_name};
        }
    } else {
        return %{$self->{attrs}};
    }
}

sub tag {
    my $self = shift;
    my $flags = shift || {};

    my $el_name = $self->{el_name};
    if (defined $el_name) {
        $el_name =~ s/^.*\:// if $flags->{strip_ns};
        return $el_name;
    } else {
        return undef;
    }
}

*name = \&tag;

sub parent {
    my $self = shift;

    return $self->{parent};
}

sub simplify {
    my $self = shift;
    my $flags = shift || {};

    my $simple = XML::MyXML::_objectarray_to_simple([$self], $flags);

    if ($flags->{internal}) {
        $simple =
            ref $simple eq 'HASH' ? (values %$simple)[0]
            : ref $simple eq 'ARRAY' ? $simple->[1]
            : croak;
    }

    return $simple;
}

sub to_xml {
    my $self = shift;
    my $flags = shift || {};

    my $decl = '';
    $decl .= qq'<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>\n' if $flags->{complete};
    my $xml = XML::MyXML::_objectarray_to_xml([$self]);
    $xml = XML::MyXML::tidy_xml($xml, {
        %$flags,
        bytes => 0,
        complete => 0,
        save => undef
    }) if $flags->{tidy};
    $xml = $decl . $xml;
    if (defined $flags->{save}) {
        open my $fh, '>', $flags->{save} or croak "Error: Couldn't open file '$flags->{save}' for writing: $!";
        binmode $fh, ':encoding(UTF-8)';
        print $fh $xml;
        close $fh;
    }
    $xml = encode_utf8 $xml if $flags->{bytes};
    return $xml;
}

sub to_tidy_xml {
    my $self = shift;
    my $flags = shift || {};

    return $self->to_xml({ %$flags, tidy => 1 });
}

sub _apply_namespace_declarations {
    my $self = shift;

    # only elements
    $self->{el_name} or return;

    my %attr = $self->attr;

    # parse namespace declarations
    my ($ns_info, @cancel_declarations) = ({});
    foreach my $ns_decl_attr_name (grep /^xmlns(\:|\z)/, keys %attr) {
        my ($ns_prefix) = $ns_decl_attr_name =~ /^xmlns(?:\:(.+))?\z/;
        $ns_prefix = '' if ! defined $ns_prefix;
        if (length $attr{$ns_decl_attr_name}) {
            $ns_info->{$ns_prefix} = $attr{$ns_decl_attr_name};
        } else {
            push @cancel_declarations, $ns_prefix;
        }
    }

    # insert these declarations into the full_ns_info hashref
    $self->{full_ns_info} = (%$ns_info or @cancel_declarations) ? {
        %{ $self->{parent}{full_ns_info} },
        %$ns_info,
    } : $self->{parent}{full_ns_info};

    # remove cancelled declarations (can cancel with ns name = "")
    delete @{ $self->{full_ns_info} }{@cancel_declarations};

    # ns_data is...
    #   $ns_name:                => undef           for element name
    #   $ns_name:$attr_localpart => $attr_value     for attributes
    $self->{ns_data} = {};

    # apply all active declarations to element
    my $el_name = $self->{el_name};
    my $num_colons = () = $el_name =~ /(\:)/g;
    my $ns_name = do {
        if ($num_colons == 0) {
            $self->{full_ns_info}{''};
        } elsif ($num_colons == 1) {
            my ($prefix) = $el_name =~ /^(.+)?\:./; # colon must not be at start or end
            defined $prefix ? $self->{full_ns_info}{$prefix} : undef;
        } else {
            undef;
        }
    };
    $self->{ns_data}{"$ns_name:"} = undef if defined $ns_name and length $ns_name;

    # apply all active declarations to attributes
    foreach my $attr_name (keys %attr) {
        if ($attr_name =~ /^([^\:]+)\:([^\:]+)\z/) { # if has one colon, not at the edges
            my ($prefix, $localpart) = ($1, $2);
            my $ns_name = $self->{full_ns_info}{$prefix};
            $self->{ns_data}{"$ns_name:$localpart"} = $attr{$attr_name}
                if defined $ns_name and length $ns_name;
        }
    }

    # continue by applying to all children (and further ancestors)
    $_->_apply_namespace_declarations foreach $self->children;
}

1;

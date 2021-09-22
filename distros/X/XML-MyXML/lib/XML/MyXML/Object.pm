package XML::MyXML::Object;

use strict;
use warnings;

use Encode;
use Carp;
use Scalar::Util qw/ weaken /;

our $VERSION = "1.07";

sub new {
    my $class = shift;
    my $xml = shift;

    my $obj = XML::MyXML::xml_to_object($xml);
    bless $obj, $class;
    return $obj;
}

sub _parse_description {
    my ($desc) = @_;

    my ($tag, $attrs_str) = $desc =~ /\A([^\[]*)(.*)\z/g;
    my %attrs = $attrs_str =~ /\[([^\]=]+)(?:=(\"[^"]*\"|[^"\]]*))?\]/g;
    foreach my $value (values %attrs) {
        $value =~ s/\A\"//;
        $value =~ s/\"\z//;
    }

    return ($tag, \%attrs);
}

sub cmp_element {
    my ($self, $desc) = @_;

    my ($tag, $attrs) = ref $desc
        ? @$desc{qw/ tag attrs /}
        : _parse_description($desc);

    ! length $tag or $self->{element} =~ /(\A|\:)\Q$tag\E\z/    or return 0;
    foreach my $attr (keys %$attrs) {
        my $val = $self->attr($attr);
        defined $val                                            or return 0;
        ! defined $attrs->{$attr} or $attrs->{$attr} eq $val    or return 0;
    }

    return 1;
}

sub children {
    my $self = shift;
    my $tag = shift;

    $tag = '' if ! defined $tag;

    my @all_children = grep { defined $_->{element} } @{$self->{content}};
    length $tag     or return @all_children;

    ($tag, my $attrs) = _parse_description($tag);
    my $desc = { tag => $tag, attrs => $attrs };

    my @results = grep $_->cmp_element($desc), @all_children;

    return @results;
}

sub path {
    my $self = shift;
    my $path = shift;

    my @path;
    my $orig_path = $path;
    my $start_root = $path =~ m!\A/!;
    $path = "/" . $path     unless $start_root;
    while (length $path) {
        my $success = $path =~ s!\A/((?:[^/\[]*)?(?:\[[^\]=]+(?:=(?:\"[^"]*\"|[^"\]]*))?\])*)!!;
        my $seg = $1;
        if ($success) {
            push @path, $seg;
        } else {
            croak "Invalid XML path: $orig_path";
        }
    }

    my @result = ($self);
    if ($start_root) {
        $self->cmp_element(shift @path)     or return;
    }
    for (my $i = 0; $i <= $#path; $i++) {
        @result = map $_->children( $path[$i] ), @result;
        @result     or return;
    }
    return wantarray ? @result : $result[0];
}

sub text {
    my $self = shift;
    my $flags = (@_ and ref $_[-1]) ? pop() : {};
    my $set_value = @_ ? defined $_[0] ? shift() : '' : undef;

    if (! defined $set_value) {
        my $value = '';
        if ($self->{content}) {
            foreach my $child (@{ $self->{content} }) {
                $value .= $child->value($flags);
            }
        }
        if ($self->{value}) {
            my $temp_value = $self->{value};
            if ($flags->{strip}) { $temp_value = XML::MyXML::_strip($temp_value); }
            $value .= $temp_value;
        }
        return $value;
    } else {
        if (length $set_value) {
            my $entry = { value => $set_value, parent => $self };
            weaken( $entry->{parent} );
            bless $entry, 'XML::MyXML::Object';
            $self->{content} = [ $entry ];
        } else {
            $self->{content} = [];
        }
    }
}

*value = \&text;

sub inner_xml {
    my $self = shift;
    my $flags = (@_ and ref $_[-1]) ? pop() : {};
    my $set_xml = @_ ? defined $_[0] ? shift() : '' : undef;

    if (! defined $set_xml) {
        my $xml = $self->to_xml($flags);
        $xml =~ s/\A\<.*?\>//s;
        $xml =~ s/\<\/[^\>]*\>\z//s;
        return $xml;
    } else {
        my $xml = "<div>$set_xml</div>";
        my $obj = XML::MyXML::xml_to_object($xml, $flags);
        $self->{content} = [];
        foreach my $child (@{ $obj->{content} || [] }) {
            $child->{parent} = $self;
            weaken( $child->{parent} );
            push @{ $self->{content} }, $child;
        }
    }
}

sub attr {
    my $self = shift;
    my $attrname = shift;
    my ($set_to, $must_set, $flags);
    if (@_) {
        my $next = shift;
        if (! ref $next) {
            $set_to = $next;
            $must_set = 1;
            $flags = shift;
        } else {
            $flags = $next;
        }
    }
    $flags ||= {};

    if (defined $attrname) {
        if ($must_set) {
            if (defined ($set_to)) {
                $self->{attrs}{$attrname} = $set_to;
                return $set_to;
            } else {
                delete $self->{attrs}{$attrname};
                return;
            }
        } else {
            my $attrvalue = $self->{attrs}->{$attrname};
            return $attrvalue;
        }
    } else {
        return %{$self->{attrs}};
    }
}

sub tag {
    my $self = shift;
    my $flags = shift || {};

    my $tag = $self->{element};
    if (defined $tag) {
        $tag =~ s/\A.*\://  if $flags->{strip_ns};
        return $tag;
    } else {
        return undef;
    }
}

sub parent {
    my $self = shift;

    return $self->{parent};
}

sub simplify {
    my $self = shift;
    my $flags = shift || {};

    my $simple = XML::MyXML::_objectarray_to_simple([$self], $flags);
    if (! $flags->{internal}) {
        return $simple;
    } else {
        if (ref $simple eq 'HASH') {
            return (values %$simple)[0];
        } elsif (ref $simple eq 'ARRAY') {
            return $simple->[1];
        }
    }
}

sub to_xml {
    my $self = shift;
    my $flags = shift || {};

    my $decl = $flags->{complete} ? '<?xml version="1.1" encoding="UTF-8" standalone="yes" ?>'."\n" : '';
    my $xml = XML::MyXML::_objectarray_to_xml([$self]);
    if ($flags->{tidy}) { $xml = XML::MyXML::tidy_xml($xml, { %$flags, bytes => 0, complete => 0, save => undef }); }
    $xml = $decl . $xml;
    if (defined $flags->{save}) {
        open my $fh, '>', $flags->{save} or croak "Error: Couldn't open file '$flags->{save}' for writing: $!";
        binmode $fh, ':encoding(UTF-8)';
        print $fh $xml;
        close $fh;
    }
    $xml = encode_utf8($xml)    if $flags->{bytes};
    return $xml;
}

sub to_tidy_xml {
    my $self = shift;
    my $flags = shift || {};

    return $self->to_xml({ %$flags, tidy => 1 });
}

1;
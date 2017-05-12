sub html_title {
    return $schema->data->{html_title} if $schema->data->{html_title};
    return sprintf("%s_%s", $tmpl->get('company_name'), $tmpl->get('service_name'));
}

sub html_bool {
    return sub {
        my $text = shift;
        return $text ? '○' : '';
    };
}

sub footnotes_link_filter_factory {
    my $type = shift;
    my $method_num = shift;

    return sub {
        sub {
            my $text = shift;
            $text =~ s|\*(\d+)|<a href="#wsst_method_${type}_footnotes_${method_num}_$1">*$1</a>|g;
            return $text;
        };
    };
}

1;

package WWW::Mechanize::Boilerplate::BBC;

use base 'WWW::Mechanize::Boilerplate';

__PACKAGE__->create_fetch_method(
    method_name => 'home',
    page_description => 'BBC home page',
    page_url => 'http://bbc.co.uk/',
);

__PACKAGE__->create_link_method(
    method_name => 'tv_link',
    link_description => 'TV',
    find_link => { text => 'TV' },
);

__PACKAGE__->create_link_method(
    method_name => 'iplayer_link',
    link_description => 'iPlayer',
    find_link => { text => 'iPlayer' },
);

__PACKAGE__->create_fetch_method(
    method_name => 'tv',
    page_description => 'BBC TV page',
    page_url => 'http://bbc.co.uk/tv/',
);

__PACKAGE__->create_fetch_method(
    method_name => 'weather',
    page_description => 'BBC weather page',
    page_url => 'http://bbc.co.uk/weather/',
    required_param => 'Location ID',
);

__PACKAGE__->create_fetch_method(
    method_name => 'news',
    page_description => 'BBC News page',
    page_url => 'http://bbc.co.uk/news/',
);

__PACKAGE__->create_form_method(
    method_name => 'search_news',
    form_id     => 'blq-search-form',
    form_description => 'News search',
    assert_location => '/news/',
    transform_fields => sub {
        return {
            go => 'toolbar',
            uri => 'http://www.bbc.co.uk/news/',
            scope => 'news',
            q => $_[1],
        }
    }
);

1;

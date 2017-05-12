requires 'Carp';
requires 'Data::UUID';
requires 'JSON::Any';
requires 'LWP::UserAgent';
requires 'URI';
requires 'perl', '5.006';

on build => sub {
    requires 'Test::Exception';
    requires 'Test::More';
};

on test => sub {
    requires 'Plack';
    requires 'Test::More', '0.96';
};

on develop => sub {
    requires 'Dist::Milla', 'v1.0.8';
    requires 'Test::Pod', '1.41';
};

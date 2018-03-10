requires 'Moo';
requires 'Email::Valid';
requires 'Mojo::UserAgent';
requires 'indirect',    '>= 0.37';

on test => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::Exception', '>= 0.43';
    requires 'Mojolicious::Lite';
    requires 'Test::Mojo';
};

on develop => sub {
    requires 'Devel::Cover', '>= 1.23';
    requires 'Devel::Cover::Report::Codecov', '>= 0.14';
};

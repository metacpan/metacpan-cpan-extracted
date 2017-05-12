use strict;
use warnings;
use lib '../../lib/';
use lib 'lib';
use Sinatraish;

view_opt 'TT' => {
    INCLUDE_PATH => 'tmpl/'
};

get '/' => sub {
    my $c = shift;
    $c->render('index.tt', {name => 'John'});
};

walk;

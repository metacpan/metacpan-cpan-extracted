package t::lib::WithoutRules;
use Mojolicious::Lite;

get '/', sub { $_[0]->render(text => 'ROOT') };
get '/other', sub { $_[0]->render(text => 'OTHER') };

app->start;

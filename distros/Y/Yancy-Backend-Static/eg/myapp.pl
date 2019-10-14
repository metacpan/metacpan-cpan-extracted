#!/usr/bin/env perl
use Mojolicious::Lite;
plugin Yancy => {
    backend => 'static:.',
    read_schema => 1,
    schema => {
        pages => {
            properties => {
                author => { type => [ 'string', 'null' ] },
            },
        },
    },
};

get '/*id', {
    controller => 'yancy',
    action => 'get',
    schema => 'pages',
    template => 'default',
    layout => 'default',
    id => 'index', # Default to index page
};

app->start;

__DATA__
@@ default.html.ep
% title $item->{title};
<%== $item->{html} %>
by <%= $item->{author} %>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
    <title><%= title %></title>
    <link rel="stylesheet" href="/yancy/bootstrap.css">
</head>
<body>
    <main class="container">
        %= content
    </main>
    <script src="/yancy/jquery.js"></script>
    <script src="/yancy/bootstrap.js"></script>
</body>
</html>

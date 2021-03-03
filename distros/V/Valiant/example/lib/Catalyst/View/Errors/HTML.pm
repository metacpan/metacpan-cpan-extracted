package Catalyst::View::Errors::HTML;

use Moose;
extends 'Catalyst::View';

sub http_400 {
  my ($self, $c, %args) = @_;
}




HTTP400
HTTP401
HTTP403
HTTP404
HTTP500
HTTP501
HTTP502
HTTP503
HTTP520
HTTP521



 
__PACKAGE__->meta->make_immutable;

__DATA__

<!DOCTYPE html>
<html lang="<%= vars.language %>">
<head>
    <meta charset="utf-8" /><meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= vars.pagetitle %></title>
</head>
<body>
    <div class="cover"><h1><%= vars.title %> <small><%= vars.code %></small></h1><p class="lead"><%= vars.message %></p></div>
    <% if (vars.footer){ %><footer><p><%- vars.footer %></p></footer><% } %>
</body>
</html>

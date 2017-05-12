#!/usr/bin/env perl

use Encode qw(decode_utf8);
use File::Basename qw(fileparse);
use File::Spec::Functions qw(catdir splitdir);
use Mojolicious::Lite;
use Try::Tiny;
use YAML::Any qw(Dump);

my (@BasePath, $Path, $BaseName, $Suffix);

BEGIN {
    ($BaseName, $Path, $Suffix) = fileparse __FILE__, qr/\.[^.]*/;
    @BasePath = splitdir($Path . '..');

    my $lib = join '/', @BasePath, 'lib';
    -e catdir(@BasePath, 't') ? unshift(@INC, $lib) : push(@INC, $lib);
}

use WebService::XING;

my $DEFAULT_EXPIRE = 365 * 24 * 60 * 60;    # 1 year

sub empty ($) { !(defined $_[0] && length $_[0]) }

my $config = try {
    plugin 'Config';
}
catch {
    create_config_file($Path . $BaseName . '.conf');
    exit;
};

app->secret($config->{session_secret});
app->sessions->default_expiration($config->{session_expire} || $DEFAULT_EXPIRE);

helper xing => sub {
    $_[0]->stash->{xing} ||= WebService::XING->new(
        key => $config->{key},
        secret => $config->{secret},
    );
};

helper yaml => sub { decode_utf8 Dump($_[1]) };

helper readable_name => sub { ucfirst join ' ', split '_', $_[1] };

get '/static' => 'static';  # inline /static.*

get '/auth_callback' => sub  {
    my $self = shift;
    my $s = $self->session;
    my $oauth_token  = $self->param('oauth_token');

    $oauth_token eq delete $s->{oauth_token}
        or die 'Unknown OAuth request token';

    my $xing = $self->xing;
    my $res = $xing->auth(
        token => $oauth_token,
        token_secret => delete $s->{oauth_token_secret},
        verifier => scalar $self->param('oauth_verifier')
    );
    $res or die $res;

    @$s{qw(access_token access_secret user_id)} = $xing->access_credentials;

    $self->redirect_to(delete $s->{redirect_after_login});
};

get '/logout' => sub {
    my $self = shift;

    delete @{$self->session}{qw(access_token access_secret user_id)};

    $self->redirect_to($self->url_for('/'));
};

get '/' => 'index';

get '/login' => my $Login = sub {
    my $self = shift;
    my $s = $self->session;

    return $self->xing->access_credentials(@$s{qw(access_token access_secret user_id)})
        if $s->{access_token} and $s->{access_secret} and $s->{user_id};

    my $res;
    $res = $self->xing->login(callback => $self->url_for('/auth_callback')->to_abs)
        or die $res;

    my $content = $res->content;
    my $current_path = $self->url_for->path;

    @$s{qw(oauth_token oauth_token_secret)} = @$content{qw(token token_secret)};
    $s->{redirect_after_login} =
        $self->req->method eq 'GET' && $current_path ne '/login' ?
            $current_path : $self->url_for('/');

    $self->redirect_to($content->{url});

    return;
};

under $Login;

get '/:function' => sub {
    my $self = shift;
    my $xing = $self->xing;
    my $function = $xing->function($self->param('function'))
        or return $self->render_not_found($self->url_for('/'));

    $self->stash(
        function => $function,
        response => undef,
        error => []
    );
} => 'function';

post '/:function' => sub {
    my $self = shift;
    my $p = $self->req->body_params;
    my $xing = $self->xing;
    my $function = $xing->function($self->param('function'))
        or return $self->render_not_found($self->url_for('/'));
    my $function_name = $function->name;
    my (@args, $response, @error);

    for (@{$function->params}) {
        my $k = $_->name;
        my $v = $p->param($k);
        if (empty $v) {
            push @error, sprintf 'Parameter "%s" is required', $self->readable_name($k)
                if $_->is_required;
        }
        else {
            push @args, $k, $v;
        }
    }

    $response = try {
        $xing->$function_name(@args);
    }
    catch {
        push @error, $_;
        return; # sic!
    } unless @error;

    $self->stash(
        function => $function,
        response => $response,
        error => \@error,
    );
} => 'function';

app->start;

sub create_config_file {
    my $config = shift;
    my $program = __FILE__;
    my $nonce = WebService::XING::nonce;
    my $fh;
    
    print <<'_EOT_';

Configuration file does not exist yet.

_EOT_

    open $fh, '>', $config
        or die "Can't open $config: $!\n";
    print $fh <<"";
{
  key => 'CONSUMER KEY HERE',
  secret => 'CONSUMER SECRET HERE',
  session_secret => '$nonce',
  session_expire => $DEFAULT_EXPIRE,    # 1 year in seconds
}

    close $fh;

    print <<"_EOT_";
I have created one for you:

  $config

Please open it in your favorite editor to insert the consumer key and
the consumer secret. You find them at https://dev.xing.com/applications

Then run

  perl $program daemon

_EOT_

}

__DATA__

@@ index.html.ep
%  layout 'default';
%  my $column = begin
<div class="span4">
<ul class="unstyled">
%  for (@_) {
<li><%= link_to readable_name($_), "/$_" %></li>
%  }
</ul>
</div>
%  end
%  my @a = @{xing->functions};
%  my @c = splice @a, -(@a / 3);
%  my @b = splice @a, -(@a / 2);
<h1>API Function Overview</h1>
<div class="row">
%= $column->(@a);
%= $column->(@b);
%= $column->(@c);
</div>

@@ function.html.ep
%   layout 'default';
<h1><%= readable_name $function->name %></h1>
%   if (@$error) {
<div class="alert alert-error">
%     for (@$error) {
<div><%= $_ %></div>
%     }
</div>
%   }
<div class="row">
<div class="span3">
%=  form_for url_for() => (method => 'post') => begin
<fieldset>
%     for my $p (@{$function->params}) {
%       my $name = $p->name;
<div class="control-group">
%       if ($p->is_boolean) {
%         my @args = ($name => 1, id => $name);
%         push @args, checked => 'checked' if $p->default;
<label class="checkbox" for="<%= $name %>">
<%= check_box @args %> <%= readable_name $name %>
</label>
%       } else {
<label for="<%= $name %>">
%         if ($p->is_required) {
<strong><%= readable_name $name %></strong>
%         } else {
<%= readable_name $name %>
%         }
</label>
<div>
%=        text_field $name, id => $name, type => 'text';
</div>
%       }
</div>
%     }
<div class="form-actions">
%= submit_button 'Send', class => 'btn btn-primary'
</div>
</fieldset>
%  end
</div>
%  if (defined $response) {
<div class="span9">
<div class="alert <%= $response->is_success ? 'alert-success' : 'alert-error' %>"><strong><%= $response %></strong></div>
<pre>
%=   yaml $response->content;
</pre>
</div>
%  }
</div>

@@ layouts/default.html.ep
<!doctype html>
<html>
<head>
%=  stylesheet '/static.css'
%=  stylesheet begin
body {
  padding-top: 60px;
  padding-bottom: 40px;
}
%   end
%=  content_for 'header'
<title>XING API Test App</title>
</head>
<body>
<div class="navbar navbar-fixed-top">
<div class="navbar-inner">
<div class="container">
<a class="brand" href="/">Mojo XING Browser</a>
<ul class="nav">
<li><a href="/">Home</a></li>
</ul>
<ul class="nav pull-right">
<li><% if (session 'access_token') { %><%= link_to Logout => 'logout' %><% } else { %><%= link_to Login => 'login' %><% } %></li>
</ul>
</div>
</div>
</div>
<div class="container">
%== content
</div>
</body>
</html>

@@ static.css.ep
/*!
 * Bootstrap v2.0.2
 *
 * Copyright 2012 Twitter, Inc
 * Licensed under the Apache License v2.0
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Designed and built with all the love in the world @twitter by @mdo and @fat.
 */
html {
  font-size: 100%;
  -webkit-text-size-adjust: 100%;
  -ms-text-size-adjust: 100%;
}
a:focus {
  outline: thin dotted #333;
  outline: 5px auto -webkit-focus-ring-color;
  outline-offset: -2px;
}
a:hover,
a:active {
  outline: 0;
}
button,
input {
  margin: 0;
  font-size: 100%;
  vertical-align: middle;
}
button,
input {
  *overflow: visible;
  line-height: normal;
}
button::-moz-focus-inner,
input::-moz-focus-inner {
  padding: 0;
  border: 0;
}
button,
input[type="button"],
input[type="reset"],
input[type="submit"] {
  cursor: pointer;
  -webkit-appearance: button;
}
body {
  margin: 0;
  font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
  font-size: 14px;
  line-height: 20px;
  color: #333333;
  background-color: #ffffff;
}
a {
  color: #0088cc;
  text-decoration: none;
}
a:hover {
  color: #005580;
  text-decoration: underline;
}
.row {
  margin-left: -20px;
  *zoom: 1;
}
.row:before,
.row:after {
  display: table;
  content: "";
}
.row:after {
  clear: both;
}
[class*="span"] {
  float: left;
  margin-left: 20px;
}
.container,
.navbar-fixed-top .container,
.navbar-fixed-bottom .container {
  width: 940px;
}
.span9 {
  width: 700px;
}
.span4 {
  width: 300px;
}
.span3 {
  width: 220px;
}
.container {
  margin-left: auto;
  margin-right: auto;
  *zoom: 1;
}
.container:before,
.container:after {
  display: table;
  content: "";
}
.container:after {
  clear: both;
}
p {
  margin: 0 0 10px;
  font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
  font-size: 14px;
  line-height: 20px;
}
p small {
  font-size: 12px;
  color: #999999;
}
h1,
h2,
h3,
h4,
h5,
h6 {
  margin: 0;
  font-family: inherit;
  font-weight: bold;
  color: inherit;
  text-rendering: optimizelegibility;
}
h1 {
  font-size: 30px;
  line-height: 40px;
}
h1 small {
  font-size: 18px;
}
h2 {
  font-size: 24px;
  line-height: 40px;
}
h2 small {
  font-size: 18px;
}
h3 {
  line-height: 30px;
  font-size: 18px;
}
h3 small {
  font-size: 14px;
}
h4,
h5,
h6 {
  line-height: 20px;
}
h4 {
  font-size: 14px;
}
h4 small {
  font-size: 12px;
}
h5 {
  font-size: 12px;
}
h6 {
  font-size: 11px;
  color: #999999;
  text-transform: uppercase;
}
.page-header {
  padding-bottom: 19px;
  margin: 20px 0;
  border-bottom: 1px solid #eeeeee;
}
.page-header h1 {
  line-height: 1;
}
ul,
ol {
  padding: 0;
  margin: 0 0 10px 25px;
}
ul ul,
ul ol,
ol ol,
ol ul {
  margin-bottom: 0;
}
ul {
  list-style: disc;
}
ol {
  list-style: decimal;
}
li {
  line-height: 22px;
}
ul.unstyled,
ol.unstyled {
  margin-left: 0;
  list-style: none;
}
strong {
  font-weight: bold;
}
em {
  font-style: italic;
}
abbr[title] {
  border-bottom: 1px dotted #ddd;
  cursor: help;
}
code,
pre {
  padding: 0 3px 2px;
  font-family: Menlo, Monaco, "Courier New", monospace;
  font-size: 13px;
  color: #333333;
  -webkit-border-radius: 3px;
  -moz-border-radius: 3px;
  border-radius: 3px;
}
code {
  padding: 2px 4px;
  color: #d14;
  background-color: #f7f7f9;
  border: 1px solid #e1e1e8;
}
pre {
  display: block;
  padding: 9.5px;
  margin: 0 0 10px;
  font-size: 12.950000000000001px;
  line-height: 20px;
  background-color: #f5f5f5;
  border: 1px solid #ccc;
  border: 1px solid rgba(0, 0, 0, 0.15);
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  white-space: pre;
  white-space: pre-wrap;
  word-break: break-all;
  word-wrap: break-word;
}
pre.prettyprint {
  margin-bottom: 20px;
}
pre code {
  padding: 0;
  color: inherit;
  background-color: transparent;
  border: 0;
}
.pre-scrollable {
  max-height: 340px;
  overflow-y: scroll;
}
form {
  margin: 0 0 20px;
}
fieldset {
  padding: 0;
  margin: 0;
  border: 0;
}
label,
input,
button {
  font-size: 14px;
  font-weight: normal;
  line-height: 20px;
}
input,
button {
  font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
}
label {
  display: block;
  margin-bottom: 5px;
  color: #333333;
}
input {
  display: inline-block;
  width: 210px;
  height: 20px;
  padding: 4px;
  margin-bottom: 9px;
  font-size: 14px;
  line-height: 20px;
  color: #555555;
  border: 1px solid #cccccc;
  -webkit-border-radius: 3px;
  -moz-border-radius: 3px;
  border-radius: 3px;
}
label input {
  display: block;
}
input[type="checkbox"],
input[type="radio"] {
  width: auto;
  height: auto;
  padding: 0;
  margin: 3px 0;
  *margin-top: 0;
  /* IE7 */

  line-height: normal;
  cursor: pointer;
  -webkit-border-radius: 0;
  -moz-border-radius: 0;
  border-radius: 0;
  border: 0 \9;
  /* IE9 and down */

}
input[type="button"],
input[type="reset"],
input[type="submit"] {
  width: auto;
  height: auto;
}
input[type="hidden"] {
  display: none;
}
.radio,
.checkbox {
  padding-left: 18px;
}
.radio input[type="radio"],
.checkbox input[type="checkbox"] {
  float: left;
  margin-left: -18px;
}
.controls > .radio:first-child,
.controls > .checkbox:first-child {
  padding-top: 5px;
}
.radio.inline,
.checkbox.inline {
  display: inline-block;
  padding-top: 5px;
  margin-bottom: 0;
  vertical-align: middle;
}
.radio.inline + .radio.inline,
.checkbox.inline + .checkbox.inline {
  margin-left: 10px;
}
input {
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
  -moz-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
  box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
  -webkit-transition: border linear 0.2s, box-shadow linear 0.2s;
  -moz-transition: border linear 0.2s, box-shadow linear 0.2s;
  -ms-transition: border linear 0.2s, box-shadow linear 0.2s;
  -o-transition: border linear 0.2s, box-shadow linear 0.2s;
  transition: border linear 0.2s, box-shadow linear 0.2s;
}
input:focus {
  border-color: rgba(82, 168, 236, 0.8);
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075), 0 0 8px rgba(82, 168, 236, 0.6);
  -moz-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075), 0 0 8px rgba(82, 168, 236, 0.6);
  box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075), 0 0 8px rgba(82, 168, 236, 0.6);
  outline: 0;
  outline: thin dotted \9;
  /* IE6-9 */

}
input[type="radio"]:focus,
input[type="checkbox"]:focus,
select:focus {
  -webkit-box-shadow: none;
  -moz-box-shadow: none;
  box-shadow: none;
  outline: thin dotted #333;
  outline: 5px auto -webkit-focus-ring-color;
  outline-offset: -2px;
}
input[class*="span"] {
  float: none;
  margin-left: 0;
}
input {
  margin-left: 0;
}
input.span9 {
  width: 690px;
}
input.span4 {
  width: 290px;
}
input.span3 {
  width: 210px;
}
.control-group.warning > label,
.control-group.warning .help-block,
.control-group.warning .help-inline {
  color: #c09853;
}
.control-group.warning input {
  color: #c09853;
  border-color: #c09853;
}
.control-group.warning input:focus {
  border-color: #a47e3c;
  -webkit-box-shadow: 0 0 6px #dbc59e;
  -moz-box-shadow: 0 0 6px #dbc59e;
  box-shadow: 0 0 6px #dbc59e;
}
.control-group.warning .input-prepend .add-on,
.control-group.warning .input-append .add-on {
  color: #c09853;
  background-color: #fcf8e3;
  border-color: #c09853;
}
.control-group.error > label,
.control-group.error .help-block,
.control-group.error .help-inline {
  color: #b94a48;
}
.control-group.error input {
  color: #b94a48;
  border-color: #b94a48;
}
.control-group.error input:focus {
  border-color: #953b39;
  -webkit-box-shadow: 0 0 6px #d59392;
  -moz-box-shadow: 0 0 6px #d59392;
  box-shadow: 0 0 6px #d59392;
}
.control-group.error .input-prepend .add-on,
.control-group.error .input-append .add-on {
  color: #b94a48;
  background-color: #f2dede;
  border-color: #b94a48;
}
.control-group.success > label,
.control-group.success .help-block,
.control-group.success .help-inline {
  color: #468847;
}
.control-group.success input {
  color: #468847;
  border-color: #468847;
}
.control-group.success input:focus {
  border-color: #356635;
  -webkit-box-shadow: 0 0 6px #7aba7b;
  -moz-box-shadow: 0 0 6px #7aba7b;
  box-shadow: 0 0 6px #7aba7b;
}
.control-group.success .input-prepend .add-on,
.control-group.success .input-append .add-on {
  color: #468847;
  background-color: #dff0d8;
  border-color: #468847;
}
input:focus:required:invalid {
  color: #b94a48;
  border-color: #ee5f5b;
}
input:focus:required:invalid:focus {
  border-color: #e9322d;
  -webkit-box-shadow: 0 0 6px #f8b9b7;
  -moz-box-shadow: 0 0 6px #f8b9b7;
  box-shadow: 0 0 6px #f8b9b7;
}
.form-actions {
  padding: 19px 20px 20px;
  margin-top: 20px;
  margin-bottom: 20px;
  background-color: #eeeeee;
  border-top: 1px solid #ddd;
  *zoom: 1;
}
.form-actions:before,
.form-actions:after {
  display: table;
  content: "";
}
.form-actions:after {
  clear: both;
}
:-moz-placeholder {
  color: #999999;
}
::-webkit-input-placeholder {
  color: #999999;
}
.help-block,
.help-inline {
  color: #555555;
}
.help-block {
  display: block;
  margin-bottom: 10px;
}
.help-inline {
  display: inline-block;
  *display: inline;
  /* IE7 inline-block hack */

  *zoom: 1;
  vertical-align: middle;
  padding-left: 5px;
}
.input-prepend,
.input-append {
  margin-bottom: 5px;
}
.input-prepend input,
.input-append input,
.input-prepend select,
.input-append select,
.input-prepend .uneditable-input,
.input-append .uneditable-input {
  *margin-left: 0;
  -webkit-border-radius: 0 3px 3px 0;
  -moz-border-radius: 0 3px 3px 0;
  border-radius: 0 3px 3px 0;
}
.input-prepend input:focus,
.input-append input:focus,
.input-prepend select:focus,
.input-append select:focus,
.input-prepend .uneditable-input:focus,
.input-append .uneditable-input:focus {
  position: relative;
  z-index: 2;
}
.input-prepend .uneditable-input,
.input-append .uneditable-input {
  border-left-color: #ccc;
}
.input-prepend .add-on,
.input-append .add-on {
  display: inline-block;
  width: auto;
  min-width: 16px;
  height: 20px;
  padding: 4px 5px;
  font-weight: normal;
  line-height: 20px;
  text-align: center;
  text-shadow: 0 1px 0 #ffffff;
  vertical-align: middle;
  background-color: #eeeeee;
  border: 1px solid #ccc;
}
.input-prepend .add-on,
.input-append .add-on,
.input-prepend .btn,
.input-append .btn {
  -webkit-border-radius: 3px 0 0 3px;
  -moz-border-radius: 3px 0 0 3px;
  border-radius: 3px 0 0 3px;
}
.input-prepend .active,
.input-append .active {
  background-color: #a9dba9;
  border-color: #46a546;
}
.input-prepend .add-on,
.input-prepend .btn {
  margin-right: -1px;
}
.input-append input,
.input-append select .uneditable-input {
  -webkit-border-radius: 3px 0 0 3px;
  -moz-border-radius: 3px 0 0 3px;
  border-radius: 3px 0 0 3px;
}
.input-append .uneditable-input {
  border-left-color: #eee;
  border-right-color: #ccc;
}
.input-append .add-on,
.input-append .btn {
  margin-left: -1px;
  -webkit-border-radius: 0 3px 3px 0;
  -moz-border-radius: 0 3px 3px 0;
  border-radius: 0 3px 3px 0;
}
.input-prepend.input-append input,
.input-prepend.input-append select,
.input-prepend.input-append .uneditable-input {
  -webkit-border-radius: 0;
  -moz-border-radius: 0;
  border-radius: 0;
}
.input-prepend.input-append .add-on:first-child,
.input-prepend.input-append .btn:first-child {
  margin-right: -1px;
  -webkit-border-radius: 3px 0 0 3px;
  -moz-border-radius: 3px 0 0 3px;
  border-radius: 3px 0 0 3px;
}
.input-prepend.input-append .add-on:last-child,
.input-prepend.input-append .btn:last-child {
  margin-left: -1px;
  -webkit-border-radius: 0 3px 3px 0;
  -moz-border-radius: 0 3px 3px 0;
  border-radius: 0 3px 3px 0;
}
.form-horizontal input,
.form-horizontal .help-inline,
.form-horizontal .input-prepend,
.form-horizontal .input-append {
  display: inline-block;
  margin-bottom: 0;
}
.control-group {
  margin-bottom: 10px;
}
legend + .control-group {
  margin-top: 20px;
  -webkit-margin-top-collapse: separate;
}
.form-horizontal .control-group {
  margin-bottom: 20px;
  *zoom: 1;
}
.form-horizontal .control-group:before,
.form-horizontal .control-group:after {
  display: table;
  content: "";
}
.form-horizontal .control-group:after {
  clear: both;
}
.form-horizontal .control-label {
  float: left;
  width: 140px;
  padding-top: 5px;
  text-align: right;
}
.form-horizontal .controls {
  margin-left: 160px;
  /* Super jank IE7 fix to ensure the inputs in .input-append and input-prepend don't inherit the margin of the parent, in this case .controls */

  *display: inline-block;
  *margin-left: 0;
  *padding-left: 20px;
}
.form-horizontal .help-block {
  margin-top: 10px;
  margin-bottom: 0;
}
.form-horizontal .form-actions {
  padding-left: 160px;
}
.btn {
  display: inline-block;
  *display: inline;
  /* IE7 inline-block hack */

  *zoom: 1;
  padding: 4px 10px 4px;
  margin-bottom: 0;
  font-size: 14px;
  line-height: 20px;
  color: #333333;
  text-align: center;
  text-shadow: 0 1px 1px rgba(255, 255, 255, 0.75);
  vertical-align: middle;
  background-color: #f5f5f5;
  background-image: -moz-linear-gradient(top, #ffffff, #e6e6e6);
  background-image: -ms-linear-gradient(top, #ffffff, #e6e6e6);
  background-image: -webkit-gradient(linear, 0 0, 0 100%, from(#ffffff), to(#e6e6e6));
  background-image: -webkit-linear-gradient(top, #ffffff, #e6e6e6);
  background-image: -o-linear-gradient(top, #ffffff, #e6e6e6);
  background-image: linear-gradient(top, #ffffff, #e6e6e6);
  background-repeat: repeat-x;
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffff', endColorstr='#e6e6e6', GradientType=0);
  border-color: #e6e6e6 #e6e6e6 #bfbfbf;
  border-color: rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.25);
  filter: progid:dximagetransform.microsoft.gradient(enabled=false);
  border: 1px solid #cccccc;
  border-bottom-color: #b3b3b3;
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  -webkit-box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2), 0 1px 2px rgba(0, 0, 0, 0.05);
  -moz-box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2), 0 1px 2px rgba(0, 0, 0, 0.05);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2), 0 1px 2px rgba(0, 0, 0, 0.05);
  cursor: pointer;
  *margin-left: .3em;
}
.btn:hover,
.btn:active,
.btn.active,
.btn.disabled,
.btn[disabled] {
  background-color: #e6e6e6;
}
.btn:active,
.btn.active {
  background-color: #cccccc \9;
}
.btn:first-child {
  *margin-left: 0;
}
.btn:hover {
  color: #333333;
  text-decoration: none;
  background-color: #e6e6e6;
  background-position: 0 -15px;
  -webkit-transition: background-position 0.1s linear;
  -moz-transition: background-position 0.1s linear;
  -ms-transition: background-position 0.1s linear;
  -o-transition: background-position 0.1s linear;
  transition: background-position 0.1s linear;
}
.btn:focus {
  outline: thin dotted #333;
  outline: 5px auto -webkit-focus-ring-color;
  outline-offset: -2px;
}
.btn.active,
.btn:active {
  background-image: none;
  -webkit-box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.15), 0 1px 2px rgba(0, 0, 0, 0.05);
  -moz-box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.15), 0 1px 2px rgba(0, 0, 0, 0.05);
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.15), 0 1px 2px rgba(0, 0, 0, 0.05);
  background-color: #e6e6e6;
  background-color: #d9d9d9 \9;
  outline: 0;
}
.btn-primary,
.btn-primary:hover {
  text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.25);
  color: #ffffff;
}
.btn-primary.active {
  color: rgba(255, 255, 255, 0.75);
}
.btn-primary {
  background-color: #0074cc;
  background-image: -moz-linear-gradient(top, #0088cc, #0055cc);
  background-image: -ms-linear-gradient(top, #0088cc, #0055cc);
  background-image: -webkit-gradient(linear, 0 0, 0 100%, from(#0088cc), to(#0055cc));
  background-image: -webkit-linear-gradient(top, #0088cc, #0055cc);
  background-image: -o-linear-gradient(top, #0088cc, #0055cc);
  background-image: linear-gradient(top, #0088cc, #0055cc);
  background-repeat: repeat-x;
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#0088cc', endColorstr='#0055cc', GradientType=0);
  border-color: #0055cc #0055cc #003580;
  border-color: rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.25);
  filter: progid:dximagetransform.microsoft.gradient(enabled=false);
}
.btn-primary:hover,
.btn-primary:active,
.btn-primary.active,
.btn-primary.disabled,
.btn-primary[disabled] {
  background-color: #0055cc;
}
.btn-primary:active,
.btn-primary.active {
  background-color: #004099 \9;
}
button.btn,
input[type="submit"].btn {
  *padding-top: 2px;
  *padding-bottom: 2px;
}
button.btn::-moz-focus-inner,
input[type="submit"].btn::-moz-focus-inner {
  padding: 0;
  border: 0;
}
.navbar {
  *position: relative;
  *z-index: 2;
  overflow: visible;
  margin-bottom: 20px;
}
.navbar-inner {
  padding-left: 20px;
  padding-right: 20px;
  background-color: #2c2c2c;
  background-image: -moz-linear-gradient(top, #333333, #222222);
  background-image: -ms-linear-gradient(top, #333333, #222222);
  background-image: -webkit-gradient(linear, 0 0, 0 100%, from(#333333), to(#222222));
  background-image: -webkit-linear-gradient(top, #333333, #222222);
  background-image: -o-linear-gradient(top, #333333, #222222);
  background-image: linear-gradient(top, #333333, #222222);
  background-repeat: repeat-x;
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#333333', endColorstr='#222222', GradientType=0);
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  -webkit-box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25), inset 0 -1px 0 rgba(0, 0, 0, 0.1);
  -moz-box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25), inset 0 -1px 0 rgba(0, 0, 0, 0.1);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25), inset 0 -1px 0 rgba(0, 0, 0, 0.1);
}
.navbar .container {
  width: auto;
}
.navbar {
  color: #999999;
}
.navbar .brand:hover {
  text-decoration: none;
}
.navbar .brand {
  float: left;
  display: block;
  padding: 8px 20px 12px;
  margin-left: -20px;
  font-size: 20px;
  font-weight: 200;
  line-height: 1;
  color: #ffffff;
}
.navbar .navbar-text {
  margin-bottom: 0;
  line-height: 40px;
}
.navbar .btn,
.navbar .btn-group {
  margin-top: 5px;
}
.navbar-fixed-top {
  position: fixed;
  right: 0;
  left: 0;
  z-index: 1030;
  margin-bottom: 0;
}
.navbar-fixed-top .navbar-inner {
  padding-left: 0;
  padding-right: 0;
  -webkit-border-radius: 0;
  -moz-border-radius: 0;
  border-radius: 0;
}
.navbar-fixed-top .container {
  width: 940px;
}
.navbar-fixed-top {
  top: 0;
}
.navbar .nav {
  position: relative;
  left: 0;
  display: block;
  float: left;
  margin: 0 10px 0 0;
}
.navbar .nav.pull-right {
  float: right;
}
.navbar .nav > li {
  display: block;
  float: left;
}
.navbar .nav > li > a {
  float: none;
  padding: 10px 10px 11px;
  line-height: 19px;
  color: #999999;
  text-decoration: none;
  text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.25);
}
.navbar .nav > li > a:hover {
  background-color: transparent;
  color: #ffffff;
  text-decoration: none;
}
.navbar .nav .active > a,
.navbar .nav .active > a:hover {
  color: #ffffff;
  text-decoration: none;
  background-color: #222222;
}
.navbar .divider-vertical {
  height: 40px;
  width: 1px;
  margin: 0 9px;
  overflow: hidden;
  background-color: #222222;
  border-right: 1px solid #333333;
}
.navbar .nav.pull-right {
  margin-left: 10px;
  margin-right: 0;
}
.alert {
  padding: 8px 35px 8px 14px;
  margin-bottom: 20px;
  text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5);
  background-color: #fcf8e3;
  border: 1px solid #fbeed5;
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  color: #c09853;
}
.alert-heading {
  color: inherit;
}
.alert .close {
  position: relative;
  top: -2px;
  right: -21px;
  line-height: 18px;
}
.alert-success {
  background-color: #dff0d8;
  border-color: #d6e9c6;
  color: #468847;
}
.alert-danger,
.alert-error {
  background-color: #f2dede;
  border-color: #eed3d7;
  color: #b94a48;
}
.alert-info {
  background-color: #d9edf7;
  border-color: #bce8f1;
  color: #3a87ad;
}
.alert-block {
  padding-top: 14px;
  padding-bottom: 14px;
}
.alert-block > p,
.alert-block > ul {
  margin-bottom: 0;
}
.alert-block p + p {
  margin-top: 5px;
}
.nav {
    list-style: none outside none;
    margin-bottom: 18px;
    margin-left: 0;
}
.nav > li > a {
    display: block;
}
.nav > li > a:hover {
    background-color: #EEEEEE;
    text-decoration: none;
}
.nav .nav-header {
    color: #999999;
    display: block;
    font-size: 11px;
    font-weight: bold;
    line-height: 18px;
    padding: 3px 15px;
    text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5);
    text-transform: uppercase;
}
.nav li + .nav-header {
    margin-top: 9px;
}
.well {
  min-height: 20px;
  padding: 19px;
  margin-bottom: 20px;
  background-color: #f5f5f5;
  border: 1px solid #eee;
  border: 1px solid rgba(0, 0, 0, 0.05);
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.05);
  -moz-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.05);
  box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.05);
}

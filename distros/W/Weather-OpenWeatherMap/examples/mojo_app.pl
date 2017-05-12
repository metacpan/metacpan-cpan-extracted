#!/usr/bin/env perl
use strict; use warnings FATAL => 'all';

my $api_key = '';  # http://www.openweathermap.org/api

use Mojolicious::Lite;

use Weather::OpenWeatherMap;
use LWP::UserAgent;

my $wx = Weather::OpenWeatherMap->new(
  ua      => LWP::UserAgent->new(timeout => 20),
  (
    $api_key ? (api_key => $api_key) : ()
  ),
);

get '/:location' 
  => { location => 'Manchester, NH' } 
  => sub {
    my $self = shift;

    my $where = $self->param('location');

    my $current = $wx->get_weather( location => $where );
    $self->stash( current => $current );

    my $forecast = $wx->get_weather(
      location => $where,
      forecast => 1,
      days     => 14,
    );
    $self->stash( forecast => $forecast );
      
    $current->is_success && $forecast->is_success ?
      $self->render('weather') 
      : $self->render_exception($current->error || $forecast->error)
};

post '/' 
  => sub {
    my $self = shift;
    my $where = $self->param('location');
    $self->redirect_to("/$where")
};

app->start;


__DATA__
@@ weather.html.ep
<html>
<head>
  <title>Weather-OpenWeatherMap</title>
</head>

<body>
  <form action="/" method="post">
   <input type="text" name="location">
   <input type="submit" value="Go">
  </form>

  <h2>Current: <%= $current->name %></h2>
  <p>
    <b><%= $current->temp_f %>F;</b>
    Wind is <%= $current->wind_speed_mph %>mph <%= $current->wind_direction %>
    (<%= ucfirst $current->conditions_verbose %>)
  </p>

  <h2>Forecast:</h2>
  % for my $day ($forecast->list) {
  %  my $img_url = "http://openweathermap.org/img/w/".$day->conditions_icon;
    <p>
      <img src="<%= $img_url %>" />
      <b><%= $day->dt->day_name %></b>
        (<%= $day->dt->month %>-<%= $day->dt->day %>):
      high <%= $day->temp_max_f %>F, low <%= $day->temp_min_f %>F
      (<%= $day->conditions_terse %>: <%= $day->conditions_verbose %>)
    </p>
  % }

<br/><br/>
<i>
 Weather source:
 <a href="http://www.openweathermap.org">http://www.openweathermap.org</a>
</i>
</body>
</html>


@@ exception.html.ep
<html>
<head>
  <title>Error in weather retrieval</title>
</head>
<body>
<p><b>The weather backend returned an error:</b></p>
<p><%= $exception->message %></p>
<p><a href="/">Back to index</a></p>
</body>
</html>

package WWW::Jawbone::Up::Mock;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up';

use Carp;

use constant URI_BASE => 'https://jawbone.com';
use constant URI_API  => URI_BASE . '/nudge/api/v.1.32';

sub bad_request {
  croak '400 BAD REQUEST';
}

sub unauthorized {
  croak '401 UNAUTHORIZED';
}

sub not_found {
  croak '404 NOT FOUND';
}

our %_RESPONSE = (
  profile => {
    data => {
      last           => 'Berndt',
      name           => 'Alan Berndt',
      short_name     => 'Alan',
      image          => 'user/image/i/photo.png',
      first          => 'Alan',
      user_is_friend => 1,
    },
  },
  feed => {
    data => {
      feed => [ {
          time_updated => 1366008300,
          title        => '9,885 steps',
          image        => '/nudge/api/v.1.32/moves/xid/image/time',
          reached_goal => undef,
          time_created => 1366008300,
          tz           => 'America/Phoenix',
          type         => 'move',
          user         => {
            last       => 'Berndt',
            name       => 'Alan Berndt',
            short_name => 'Alan',
            image      => 'user/image/i/photo.png',
            first      => 'Alan',
          },
        }, {
          time_updated => 1365960060,
          title        => 'for 8h 17m',
          image        => '/nudge/api/v.1.32/sleeps/xid/image/time',
          reached_goal => 1,
          time_created => 1365960060,
          tz           => 'America/Phoenix',
          type         => 'sleep',
          user         => {
            last       => 'Berndt',
            name       => 'Alan Berndt',
            short_name => 'Alan',
            image      => 'user/image/i/photo.png',
            first      => 'Alan',
          },
        },
      ],
    },
  },
  score => {
    data => {
      move => {
        distance       => 7.553,
        longest_idle   => 9000,
        calories       => 608.235829421,
        bg_steps       => 9885,
        longest_active => 932,
        bmr_calories   => 2201.52221491,
        active_time    => 5135,
      },
      sleep => {
        awakenings    => 2,
        light         => 10243,
        time_to_sleep => 693,
        goals         => {
          bedtime => [ 10,    undef ],
          deep    => [ 15190, undef ],
        },
        awake => 2091,
      },
    },
  },
  band => {
    data => {
      ticks => [ {
          value => {
            distance    => 25,
            active_time => 15,
            aerobic     => undef,
            calories    => 1.54764223099,
            steps       => 31,
            time        => 1365980040,
            speed       => 1,
          },
        },
      ],
    },
  },
  workouts => {
    data => {
      items => [ {
          time_completed => 1364827020,
          title          => 'Workout',
          is_complete    => 1,
          time_updated   => 1364828785,
          details        => {
            intensity => undef,
            tz        => 'America/Phoenix',
            calories  => 236.39623734,
            km        => 2.156,
            steps     => 3221,
            time      => 1781,
          },
          time_created => 1364825239,
        },
      ],
    },
  },
  auth_failure => {
    error => {
      msg => 'Email or Password cannot be validated',
    },
  },
  auth_success => {
    token => '123abc',
  },
);

sub _get {
  my ($self, $uri, $data) = @_;

  unauthorized unless $self->{token};

  if ($uri eq URI_API . '/users/@me') {
    return $_RESPONSE{profile};
  } elsif ($uri eq URI_API . '/users/@me/social') {
    return $_RESPONSE{feed};
  } elsif ($uri eq URI_API . '/users/@me/score') {
    return $_RESPONSE{score};
  } elsif ($uri eq URI_API . '/users/@me/band') {
    return $_RESPONSE{band};
  } elsif ($uri eq URI_API . '/users/@me/workouts') {
    return $_RESPONSE{workouts};
  } else {
    not_found;
  }
}

sub _post {
  my ($self, $uri, $data) = @_;

  if ($uri eq URI_BASE . '/user/signin/login') {
    bad_request unless $data->{service};
    bad_request unless $data->{email};
    bad_request unless $data->{pwd};

    return $_RESPONSE{auth_failure} unless $data->{pwd} eq 's3kr3t';
    return $_RESPONSE{auth_success};
  } else {
    not_found;
  }
}

1;

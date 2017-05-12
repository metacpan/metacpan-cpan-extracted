package WebService::Moodle::Simple::CLI;

use strict;
use warnings;
use OptArgs;

opt help => (
    isa     => 'Bool',
    comment => 'print a help message and exit',
    ishelp  => 1,
);


arg command => (
  isa     => 'SubCmd',
  comment => 'sub command to run',
  required => 1,
);

opt domain => (
  isa     => 'Str',
  alias   => 'd',
  comment => 'something like moodle.server.name.com',
  default => sub { die '--domain [-d] - the moodle server like moodle.server.name.com is required' },
);

opt port => (
  isa     => 'Int',
  comment => '--port - The port on which the Moodle service listens',
);

opt timeout => (
  isa     => 'Int',
  comment => '--timeout - Seconds we wait for the server to respond',
);

opt target => (
  isa     => 'Str',
  alias   => 't',
  comment => '--target [-t] - The name of the target Moodle service to access',
  default => sub { die '--target [-t] - name of the target moodle service is required' },
);


opt scheme => (
  isa     => 'Str',
  comment => '--scheme - The uri scheme - defaults to "http"',
);


subcmd (
  cmd     => 'login',
  comment => 'Check password and retrieve token',
);

opt username => (
  isa     => 'Str',
  alias   => 'u',
  comment => '--username [-u] - The Moodle username accessing the service',
  default => sub { die '--username [-u] - username is required' },
);

opt password => (
  isa      => 'Str',
  alias    => 'p',
  comment  => '--password [-p] - user password',
  default => sub { die '--password [-p] - user password is required' },
);

subcmd (
  cmd     => 'add_user',
  comment => 'Create a Moodle user account',
);

opt username => (
  isa     => 'Str',
  alias   => 'u',
  comment => '--username [-u] - The Moodle username being created',
  default => sub { die '--username [-u] - username is required' },
);

opt firstname => (
  isa      => 'Str',
  alias    => 'f',
  comment  => '--firstname [-f] - user firstname',
  default => sub { die '--firstname [-f] - firstname is required' },
);

opt lastname => (
  isa      => 'Str',
  alias    => 'l',
  comment  => '--lastname [-l] - user lastname',
  default => sub { die '--lastname [-l] - lastname required' },
);

opt email => (
  isa      => 'Str',
  alias    => 'e',
  comment  => '--email [-e] - email (required)',
  default => sub { die '--email [-e] - email required' },
);

opt token => (
  isa      => 'Str',
  alias    => 'o',
  comment  => '--token [-o] - user token (required)',
  default => sub { die '--token [-o] - token required' },
);

opt password => (
  isa      => 'Str',
  alias    => 'p',
  comment  => '--password [-p] - user password (required)',
  default => sub { die '--password [-p] - user password required' },
);
  
subcmd (
  cmd     => 'get_users',
  comment => 'Get all users',
);

opt token => (
  isa      => 'Str',
  alias    => 'o',
  comment  => '--token [-o] - token (required)',
  default => sub { die '--token [-o] - token required' },
);

subcmd (
  cmd     => 'enrol',
  comment => 'Enrol student into a course',
);

opt username => (
  isa     => 'Str',
  alias   => 'u',
  comment => '--username [-u] - username being enrolled',
  default => sub { die '--username [-u] - username required' },
);

opt course => (
  isa     => 'Str',
  comment => '--course - The Moodle course being enrolled in',
  default => sub { die '--course required' },
);

opt token => (
  isa      => 'Str',
  alias    => 'o',
  comment  => '--token [-o] - token (required)',
  default => sub { die '--token [-o] - token required' },
);

subcmd (
  cmd     => 'set_password',
  comment => 'Update a user account password',
);

opt username => (
  isa     => 'Str',
  alias   => 'u',
  comment => '--username [-u] - username requiring a password reset',
  default => sub { die '--username [-u] - username required' },
);

opt password => (
  isa      => 'Str',
  alias    => 'p',
  comment  => '--password [-p] - user password',
  default => sub { die '--password [-p] - password required' },
);

opt token => (
  isa      => 'Str',
  alias    => 'o',
  comment  => '--token [-o] - user token',
  default => sub { die '--token [-o] - token required' },
);
  

1;

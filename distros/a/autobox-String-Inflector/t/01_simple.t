use strict;
use warnings;
use autobox::String::Inflector;
use Test::More;

is 'users'->singularize->camelize, 'User';
is 'statuses'->singularize->camelize, 'Status';
is 'Entry'->decamelize->pluralize, 'entries';
is 'Status'->decamelize->pluralize, 'statuses';

done_testing;

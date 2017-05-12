package Test::UsedModules::Constants;
use strict;
use warnings;
use utf8;
use parent 'Exporter';

our @EXPORT = qw/PRAGMAS/;

use constant PRAGMAS => (
    'attributes',
    'autodie',
    'autouse',
    'base',
    'bigint',
    'bignum',
    'bigrat',
    'blib',
    'bytes',
    'charnames',
    'constant',
    'diagnostics',
    'encoding',
    'feature',
    'fields',
    'filetest',
    'if',
    'integer',
    'less',
    'lib',
    'locale',
    'mro',
    'open',
    'ops',
    'overload',
    'overloading',
    'parent',
    're',
    'sigtrap',
    'sort',
    'strict',
    'subs',
    'threads',
    'threads::shared',
    'utf8',
    'vars',
    'vmsish',
    'warnings',
    'warnings::register',
);
1;

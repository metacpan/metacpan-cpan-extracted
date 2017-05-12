use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 5;

use_ok 'UUID::Generator::PurePerl';
use_ok 'UUID::Generator::PurePerl::Compat';
use_ok 'UUID::Generator::PurePerl::NodeID';
use_ok 'UUID::Generator::PurePerl::RNG';
use_ok 'UUID::Generator::PurePerl::Util';

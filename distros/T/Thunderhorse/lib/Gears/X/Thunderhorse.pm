package Gears::X::Thunderhorse;
$Gears::X::Thunderhorse::VERSION = '0.001';
use v5.40;
use Mooish::Base;

# use all Gears exceptions for convenience
use Gears::X;
use Gears::X::HTTP;
use Gears::X::Config;
use Gears::X::Template;

Gears::X->add_ignored_namespace('Thunderhorse');

extends 'Gears::X';


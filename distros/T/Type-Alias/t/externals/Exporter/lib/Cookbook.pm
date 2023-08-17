package Cookbook;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(hello Message);

use Type::Alias -alias => [qw(Message)];
use Types::Common -types;

type Message => StrLength[1, 100];

sub hello { ... }

1;

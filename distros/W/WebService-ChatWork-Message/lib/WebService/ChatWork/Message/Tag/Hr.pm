use strict;
use warnings;
package WebService::ChatWork::Message::Tag::Hr;
use overload q{""} => \&as_string;
use Mouse;

extends "WebService::ChatWork::Message::Tag";

sub new { bless { }, shift }

sub as_string { "[hr]" }

1;

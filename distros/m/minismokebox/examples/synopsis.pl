#!/usr/binperl
use strict;
use warnings;
BEGIN { eval "use Event;"; }
use App::SmokeBox::Mini;
App::SmokeBox::Mini->run();

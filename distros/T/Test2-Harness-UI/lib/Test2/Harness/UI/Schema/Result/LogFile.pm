package Test2::Harness::UI::Schema::Result::LogFile;
use utf8;
use strict;
use warnings;

use Carp qw/confess/;
confess "You must first load a Test2::Harness::UI::Schema::NAME module"
    unless $Test2::Harness::UI::Schema::LOADED;

our $VERSION = '0.000144';

require "Test2/Harness/UI/Schema/${Test2::Harness::UI::Schema::LOADED}/LogFile.pm";
require "Test2/Harness/UI/Schema/Overlay/LogFile.pm";

1;

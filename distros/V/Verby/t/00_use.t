#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use constant HAVE_DBD_MYSQL => scalar eval { require DBD::mysql; require Time::Piece::MySQL; 1 };
use constant HAVE_FILE_RSYNC => scalar eval { require File::Rsync; 1 };
use constant HAVE_GETOPT_CASUAL => scalar eval { require Getopt::Casual; 1 };

use ok "Verby";

use ok "Verby::Dispatcher";

use ok "Verby::Context";
use ok "Verby::Config::Data";
use ok "Verby::Config::Data::Mutable";
use ok "Verby::Config::Source";
use if HAVE_GETOPT_CASUAL, ok => "Verby::Config::Source::ARGV";
use ok "Verby::Config::Source::Prompt";

use ok "Verby::Action";

use ok "Verby::Action::Stub";

use ok "Verby::Action::MkPath";

use ok "Verby::Action::Run";
use ok "Verby::Action::Run::Unconditional";

use ok "Verby::Action::Make";
use ok "Verby::Action::BuildTool";

use ok "Verby::Step";

use ok "Verby::Step::Closure";

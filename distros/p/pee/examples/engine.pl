#!/usr/bin/perl -w

use strict;
use Pee::FileRunner;


# Get the template file from environment
my $template = $ENV{'PATH_TRANSLATED'};

my $runner = Pee::FileRunner->new("$template");
# Use this if you'd like to enable writing of compiled code to
# a scratch directory.  Make sure it exists and is writeable by
# the web server user.  See the FAQ for more information
#my $runner = Pee::FileRunner->new("$template", {debug=>1, scratchdir=>'/tmp/pee'});

if (!$runner->compile()) {
  print "Content-type: text/html\n\n";
  print "Error compiling template: $template\n";
  print "<br>$runner->{errmsg}\n";
  exit(0);
}

if (!$runner->run('main')) {
  print "Content-type: text/html\n\n";
  print "<br><br><p>Error running template: $template\n";
  print "<br>$runner->{errmsg}\n";
  exit(0);
}

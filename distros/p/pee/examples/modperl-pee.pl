#!/usr/bin/perl -w

use strict;
use vars qw(%pet %compiled_code);


# Change to 0 if you don't want to have any debug output to server log
my $debug = 1;

# %pet is a hash of PET files with their checksum (for caching)
# %compiled_code is a hash of PET files with their code (for caching)


# Get the template file from environment
my $template = $ENV{'PATH_TRANSLATED'};

print STDERR "[$$] modperl-pee.pl: TEMPLATE='$template'\n" if ($debug);

if (! -r $template) {
  print STDERR "[$$] cannot read template: $!\n" if ($debug);
}

my @fstat = stat ($template);

# we either haven't seen this template before OR that it has changed
if (!(exists $pet{$template}) || ($pet{$template} ne "$fstat[7]|$fstat[9]")) {

  print STDERR "[$$] modperl-pee.pl: RE-compiling template\n" if ($debug);

  # Use this instead if you'd like to enable writing of compiled code to
  # a scratch directory.  Make sure it exists and is writeable by
  # the web server user.  See the FAQ for more information
  #my $runner = Pee::FileRunner->new("$template", {debug=>1, scratchdir=>'/tmp/pee'});
  my $runner = Pee::FileRunner->new("$template");

  if (!$runner->compile()) {
    print "Content-type: text/html\n\n";
    print "Error compiling template: $template\n";
    print "<br>$runner->{errmsg}\n";
    exit(0);
  }

  # remember the checksum and compiled code
  $pet{$template} = "$fstat[7]|$fstat[9]";
  $compiled_code{$template} = $runner;
}


my $runner = $compiled_code{$template};
my $rv = $runner->run();
if (!$rv) {
  print "Content-type: text/html\n\n";
  print "<br><br><p>Error running template: $template\n";
  print "<br>$runner->{errmsg}\n";
  exit(0);
}

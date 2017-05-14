#!/usr/local/bin/perl -w

use strict;
use GO::Parser;
use Getopt::Long;
use Data::Dumper;

my $opt = {};
GetOptions($opt,
           "format|p=s",
           "handler|h=s",
           "force_namespace=s",
           "replace_underscore",
           "litemode|l",
           "multifile",
           "expand|e");

my @fns = @ARGV;

my $fmt = $opt->{format};

my $parser =
  new GO::Parser (format=>$fmt, handler=>'prolog');
if ($opt->{force_namespace}) {
    $parser->force_namespace($opt->{force_namespace});
}
if ($opt->{replace_underscore}) {
    $parser->replace_underscore(' ');
}
$parser->litemode(1) if $opt->{litemode};
if ($opt->{multifile}) {
    print <<EOM
:- multifile class/2, subclass/2, restriction/3, def/2, belongs/2.
restriction(id,type,to):- fail.
EOM
      ;
}
$parser->parse (@fns);

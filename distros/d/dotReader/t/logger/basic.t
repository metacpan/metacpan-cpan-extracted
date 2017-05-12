#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use lib 'inc';
use dtRdrTestUtil qw(error_catch);

use Test::More (
  'no_plan'
  );
use dtRdr::Logger ();
dtRdr::Logger->init(filename => 't/logger/basic.conf');

{
  #diag("check the root package");
  {
    my ($error) = error_catch(sub 
    {
      package Foo;
      use dtRdr::Logger;
      L->warn("a warning");
      L->debug("a debug message");
    });
    is($error, "WARN - a warning\n");
    0 and warn $error;
  }
  {
    my ($error) = error_catch(sub 
    {
      package Ploink;
      use dtRdr::Logger;
      L->warn("a warning");
      L->debug("a debug message");
    });
    is($error, "WARN - a warning\n");
    0 and warn $error;
  }
}
{
  #diag("check the Foo.#thing package");
  {
    {
      my $l;
      {
        package Foo;
        $l = L('thing');
      }
      #warn "cat $l->{category}";
      is($l, Log::Log4perl->get_logger('Foo.#thing'), "correct logger");
    }
    my ($error) = error_catch(sub 
    {
      package Foo;
      use dtRdr::Logger;
      L('thing')->warn("a warning");
      L('thing')->info("some info");
      L('thing')->debug("a debug message");
    });
    is($error, "WARN - a warning\nINFO - some info\n");
    0 and warn $error;
  }
}

{
  #diag("check the in-package spec");
  { # why we prepend '#' to your tags
    my ($error) = error_catch(sub 
    {
      package Foo::deal;
      use dtRdr::Logger;
      L->debug("a debug message from Foo::deal");
      package Foo;
      use dtRdr::Logger;
      L('deal')->debug('a debug message from Foo.#deal');
      L('thing')->info('an info message from Foo.#thing');
    });
    is($error, "DEBUG - a debug message from Foo::deal\n" .
      "INFO - an info message from Foo.#thing\n");
  }
}

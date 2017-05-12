#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Test::Tester tests => 48;

use Test::Glade;

# Simple name tests
{
  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        name => 'window1',
      });
    }, {
      ok => 1,
      name => 'has window1',
    },
    'found window1',
  );
  
  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        name => 'window2',
      });
    }, {
      ok => 0,
      name => 'has window2',
    },
    'can not find window2'
  );

  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        type => 'GtkWindow',
      }, 'test name');
    }, {
      ok => 1,
      name => 'test name',
    },
    'name properly'
  );
}

# Dig into properties and children
{
  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        properties => { title => 'window1' },
      }, 'test name');
    }, {
      ok => 1,
      name => 'test name',
    },
    'properties',
  );

  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        children => [ { name => 'hbox1' } ],
      }, 'test name');
    }, {
      ok => 1,
      name => 'test name',
    },
    'children',
  );

  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        packing => {expand => 0},
      }, 'test name');
    }, {
      ok => 1,
      name => 'test name',
    },
    'packing',
  );

  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        packing => {foo => 'bar'},
      }, 'test name');
    }, {
      ok => 0,
      name => 'test name',
    },
    'packing 2',
  );
}

# can go very deep
{
  check_test(
    sub {
      has_widget("$FindBin::Bin/test.glade", {
        children => [{ children => [{ name => 'button1' }] }],
      }, 'test name');
    }, {
      ok => 1,
      name => 'test name',
    },
    'deep',
  );  
}

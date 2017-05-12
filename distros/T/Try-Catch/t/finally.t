#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 25;

use Try::Catch;

try {
  my $a = 1+1;
} catch {
  fail('Cannot go into catch block because we did not throw an exception')
} finally {
  pass('Moved into finally from try');
};

try {
  die('Die');
} catch {
  ok($_ =~ /Die/, 'Error text as expected');
  pass('Into catch block as we died in try');
} finally {
  pass('Moved into finally from catch');
};

try {
  die('Die');
} catch {
  ok($_ =~ /Die/, 'Error text as expected');
} finally {
  pass('Moved into finally from catch');
};

try {
  try {
    die('Die');
  } finally {
    pass('Moved into finally block when try throws an exception and we have no catch block');
  };
} catch {};

try {
  try {
    die('Die');
  } finally {
    pass('First finally clause run');
  };
} catch {};

try {
  # do not die
} finally {
  if (@_) {
    fail("errors reported: @_");
  } else {
    pass("no error reported") ;
  }
};

try {
  try {
    die("Die\n");
  } finally {
    is_deeply(\@_, [ "Die\n" ], "finally got passed the exception");
  };
} catch {};

try {
  try {
    die "foo";
  }
  catch {
    die "bar";
  }
  finally {
    pass("finally called");
  };
} catch {};

$_ = "foo";
try {
  is($_, "foo", "not localized in try");
}
catch {
}
finally {
  #is(scalar(@_), 0, "nothing in \@_ (finally)");
  is($_, "foo", "\$_ not localized (finally)");
};
is($_, "foo", "same afterwards");

$_ = "foo";
try {
  is($_, "foo", "not localized in try");
  die "bar\n";
}
catch {
  is($_[0], "bar\n", "error in \@_ (catch)");
  is($_, "bar\n", "error in \$_ (catch)");
}
finally {
  is(scalar(@_), 1, "error in \@_ (finally)");
  is($_[0], "bar\n", "error in \@_ (finally)");
  is($_, "foo", "\$_ not localized (finally)");
};
is($_, "foo", "same afterwards");

$@ = "previous error";
try {
} finally {
  eval { "ok" };
};
is($@, "previous error", "finally does not modify previous \$@");

$@ = "previous error";
try {
  die "foo";
} catch {
} finally {
  eval { "ok" };
};
is($@, "previous error", "finally does not modify previous \$@");

$@ = "previous error";
try {
  try {
    die "foo";
  } catch {
    die "bar";
  } finally {
    eval { "ok" };
  }
} catch {
  like($_[0], qr/^bar at/, "finally does not modify error from catch");
  like($_, qr/^bar at/, "finally does not modify error from catch");
};

1;

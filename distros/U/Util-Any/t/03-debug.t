use lib qw(./lib ./t/lib);

BEGIN {
  close STDERR;
  open STDERR, ">", \$err or die $!;
}

BEGIN {
  use MyUtil qw/error/, {debug => 1};
  print $err =~ m{Ktat} ? "ok\n" : "not ok\n# $err\n";
}

BEGIN {
  eval 'use MyUtil qw/error/, {debug => 2};';
  print $@ =~ m{locate Ktat} ? "ok\n" : "not ok\n# $@\n";
}

print "1..2\n";


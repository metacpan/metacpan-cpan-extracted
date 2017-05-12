#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use YATT::Lite::Util qw/define_const/;

sub make_type_alias {
  my $callpack = caller;
  foreach my $name (@_) {
    my $fullname = join("::", $callpack, $name);
    {
      local $@; eval "package $fullname"; die $@ if $@;
    }
    define_const($fullname, $fullname);
  }
}

use Test::More;

my $common = <<'END';
package testing::dummy%d; sub MY () {__PACKAGE__}
use strict;
BEGIN {::make_type_alias(qw/Foo Bar Baz/)}
END

{
  my $script = sprintf($common, 1). <<'END';
sub t1 {
  join(", ", Foo);
}
1;
END

  ok eval($script), "use of constant sub";
  is $@, '', "no error";
}

{
  my $script = sprintf($common, 2). <<'END';
sub t2 {
  (my Foo $foo) = @_;
}
1;
END

  ok eval($script), "use of constant sub for my Dog \$spot";
  is $@, '', "no error";
}

{
  my $script = sprintf($common, 3). <<'END';
sub t3 {
  (my MY $foo) = @_;
}
1;
END

  ok eval($script), "use of constant sub for my Dog \$spot";
  is $@, '', "no error";
}

done_testing();

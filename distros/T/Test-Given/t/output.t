use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);

describe 'Output of failing tests' => sub {
  Given lines => sub { run_spec('t/t/output.t') };

  Then sub { contains($lines, qr/#   \$hash->\{'a'\} == \$array->\[1\]/) };
  And  sub { contains($lines, qr/#     1\t<- \$hash\->\{'a'\}/) };
  And  sub { contains($lines, qr/#     2\t<- \$array\->\[1\]/) };

  Then sub { contains($lines, qr/#   "\$hash->\{'b'\}" eq "\$array->\[2\]"/) };
  And  sub { contains($lines, qr/#     2\t<- "\$hash->\{'b'\}"/) };
  And  sub { contains($lines, qr/#     3\t<- "\$array->\[2\]"/) };

  Then sub { contains($lines, qr/#   \&sub\(\) eq \(keys \%\$hash\)\[0\]/) };
  And  sub { contains($lines, qr/#     a sub\t<- \&sub\(\)/) };
  And  sub { contains($lines, qr/#     a\t<- \(keys \%\$hash\)\[0\]/) };

  context 'with return keyword' => sub {
    Then sub { contains($lines, qr/#     1\t<- \$a/) };
  };

  context 'with undefined value' => sub {
    Then sub { contains($lines, qr/#     <undef>\t<- \$c/) };
  };

  context 'with comparison that fails on one side' => sub {
    Then sub { contains($lines, qr/#     <Error: Illegal division by zero.*\t<-/) };
  };

  context 'with comparison that fails on both sides' => sub {
    Then sub { not contains($lines, qr/\t<- die\('hard'\)/) };
    And  sub { not contains($lines, qr/\t<- die\('vengeance'\)/) };
  };

  context 'with no recognized expression' => sub {
    Then sub { contains($lines, qr/\t<-/) == 10 };
  };
};

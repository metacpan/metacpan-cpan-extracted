use Test::More tests => 4;

# This script tests whether UML::Class::Simple draws a diagram
# that only includes modules that appear when using the target module.

# UML::Class::Simple should not draw any modules that appear
# only as a side effect of using UML::Class::Simple, PPI, etc.

#use Smart::Comments;
use lib "lib";
use lib "t/data";

use_ok UML::Class::Simple;
use_ok UMLClassTest;

{
  my @expected = map { chomp; $_ } sort { $a cmp $b }
                 `$^X -It/data t/data/classes-from-runtime.pl`;
  my @got = grep { $_ } sort { $a cmp $b } classes_from_runtime("UMLClassTest");
  ## @expected
  ## @got
  ok contain(\@got, \@expected), 'Find the modules that are loaded';
}

{
  my @expected = map { chomp; $_ } sort { $a cmp $b } `$^X t/data/filespec.pl`;
  my @got = grep { $_ } sort { $a cmp $b } classes_from_runtime("File::Spec");
  ok contain(\@got, \@expected), 'Same test; dependency overlap with U::C::S';
}

sub contain {
    my ($got, $expected) = @_;
    my $pass = 1;
    for my $a (@$expected) {
      my $done;
      for my $b (@$got) {
          if ($a eq $b) {
              ### found a: $a
              ### found b: $b
              $done = 1;
              last;
          }
      }
      next if $done;
      undef $pass;
      last;
    }
    return $pass;
}


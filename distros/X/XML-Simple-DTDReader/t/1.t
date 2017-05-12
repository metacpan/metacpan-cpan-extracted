use Test::More;
my @xml;
BEGIN { 
  chdir "t";
  @xml = <*.xml>;
  plan tests => (2 + @xml);
}

use XML::Simple::DTDReader;
ok(1);

is_deeply(XMLin("<!DOCTYPE data [<!ELEMENT data EMPTY>]><data />"), {}, "Text input");

for my $file (@xml) {
  my($output) = $file =~ /(.*)\./;

  my $base = eval join "", do {local @ARGV = ("$output.pl"); <>};
  
  my $actual = eval {XMLin($file)};
  unless ($@) {
    is_deeply($actual, $base, $output);
  } elsif ($@ =~ /(.*) at \S+ line \d/) {
    is($1, $base)
  } else {
    fail($output);
  }
  
  
}

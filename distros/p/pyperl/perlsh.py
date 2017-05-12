import perl

perl.eval("""

use Term::ReadLine;
my $term = Term::ReadLine->new("perlsh");


use Python @Python::EXPORT_OK;

sub shell {
   my $prompt = shift || "perlsh> ";
   while (defined($_ = $term->readline($prompt))) {
      chomp;
      my $res = eval $_;
      print "$res\n" if defined $res;
      print $@ if $@;
   }
   print "\n";
}

""")

perl.call("shell")



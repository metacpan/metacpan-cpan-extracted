use Test::More tests => 56;

use strict;

# XXX suppress silly warnings untill fixed!
$SIG{__WARN__}=sub{};

use VCS::Rcs::Parser;

while (my $f = <t/data/[0-9][0-9][0-9]>) {

  open my $fh, '<', $f or die $!;
  my $text = do {local $/; <$fh>};
  close $fh or die $!;

  my $rcs = VCS::Rcs::Parser->new(\$text);

  #print $rcs->co(rev => '1.1');
  ok $rcs->co(rev => '1.1');

  my $d = $rcs->revs(index => 'date');

  for (sort keys(%$d)) {
    #print $_, " ", $d->{$_}, "\n";
    ok $d->{$_};
  }

}


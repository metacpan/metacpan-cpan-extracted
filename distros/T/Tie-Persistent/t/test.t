# -*-perl-*-
#
# some easy tests for Tie::Persistent
#

use vars qw(@list $pfile $ixpfile $have_ixhash);

BEGIN {
  $| = 1;
  @list = qw/foo bar baz xxx otto susi hugo/;
  $pfile = 'persistentfile.pd';
  $ixpfile = 'persistentixfile.pd';
  unlink $pfile, $ixpfile, $pfile.'~', $ixpfile.'~';

  # Tie::IxHash might not be installed, but we can do some tests anyway
  eval { require Tie::IxHash; };
  $have_ixhash = not $@;

  my $total_tests = 17;
  # adjust number of tests
  $total_tests -= 1 if $] < 5.005; # no tied arrays
  $total_tests -= 8 if not $have_ixhash;
  $total_tests *= 2;
  print "1..$total_tests\n";
}

END {
  print "not ok 1\n" unless $loaded;
  # remove used files
  unlink $pfile, $ixpfile, $pfile.'~', $ixpfile.'~';
}
$loaded = 1;

use Tie::Persistent;

my $n = 1;

foreach $Tie::Persistent::Readable (0..1) {

  unlink $pfile, $ixpfile, $pfile.'~', $ixpfile.'~';

  {
    my %h;
    tie %h, 'Tie::Persistent', $pfile, 'rw';

    for (my $i = $#list; $i >= 0; $i--) {
      $h{$i} = $list[$i];
      $h{$list[$i]} = $i;
    }

    untie %h;
  }

  {
    my %h;
    tie %h, 'Tie::Persistent', $pfile, 'r';

    my $notok;
    for (my $i = $#list; $i >= 0; $i--) {
      next if ($h{$i} eq $list[$i] and $h{$list[$i]} eq $i);
      $notok = 1;
      last;
    }

    print $notok? 'not ok ': 'ok ', $n++, "\n";

    $h{$list[0]} = '';

    untie %h;			# must not write back, tied read-only
  }

  {
    my (%h, %h2);
    tie %h, 'Tie::Persistent', $pfile, 'rw';

    my $notok;
    for (my $i = $#list; $i >= 0; $i--) {
      next if ($h{$i} eq $list[$i] and $h{$list[$i]} eq $i);
      $notok = 1;
      last;
    }

    print $notok? 'not ok ': 'ok ', $n++, "\n";

    $h{$list[0]} = 'XXX';		# now modify

    # modification must not be in the file
    tie %h2, 'Tie::Persistent', $pfile, 'r';
    for (my $i = $#list; $i >= 0; $i--) {
      next if ($h2{$i} eq $list[$i] and $h2{$list[$i]} eq $i);
      $notok = 1;
      last;
    }
    print $notok? 'not ok ': 'ok ', $n++, "\n";
    untie %h2;

    (tied %h)->sync();          # write back

    tie %h2, 'Tie::Persistent', $pfile, 'r';
    for (my $i = $#list; $i > 0; $i--) {
      next if ($h2{$i} eq $list[$i] and $h2{$list[$i]} eq $i);
      $notok = 1;
      last;
    }
    $notok = 1 if $h2{$list[0]} ne 'XXX';
    print $notok? 'not ok ': 'ok ', $n++, "\n";
    untie %h2;

    (tied %h)->autosync(1);     # enable auto write back

    $h{$list[0]} = 'yyy';	# now modify again

    # modification must now be in the file
    tie %h2, 'Tie::Persistent', $pfile, 'r';
    for (my $i = $#list; $i > 0; $i--) {
      next if ($h2{$i} eq $list[$i] and $h2{$list[$i]} eq $i);
      $notok = 1;
      last;
    }
    $notok = 1 if $h2{$list[0]} ne 'yyy';
    print $notok? 'not ok ': 'ok ', $n++, "\n";
    untie %h2;

    (tied %h)->autosync(0);     # disable auto write back

    $h{$list[0]} = '';		# now modify again
    untie %h;			# must write back
  }

  {
    my %h;
    tie %h, 'Tie::Persistent', $pfile, 'r';

    my $notok;
    for (my $i = $#list; $i > 0; $i--) {
      next if ($h{$i} eq $list[$i] and $h{$list[$i]} eq $i);
      $notok = 1;
      last;
    }
    $notok = 1 if $h{$list[0]} ne '';

    print $notok? 'not ok ': 'ok ', $n++, "\n";

    untie %h;
  }

  {
    my (%h, %hp);
    tie %hp, 'Tie::Persistent', $pfile, 'r', \%h;

    my $notok;
    for (my $i = $#list; $i > 0; $i--) {
      next if ($h{$i} eq $list[$i] and $h{$list[$i]} eq $i);
      $notok = 1;
      last;
    }
    $notok = 1 if $h{$list[0]} ne '';

    for (my $i = $#list; $i > 0; $i--) {
      next if ($hp{$i} eq $list[$i] and $hp{$list[$i]} eq $i);
      $notok = 1;
      last;
    }
    $notok = 1 if $hp{$list[0]} ne '';

    print $notok? 'not ok ': 'ok ', $n++, "\n";

    untie %hp;
  }

  # now with IxHash...
  if ($have_ixhash) {
    {
      my %ixh;
      tie %ixh, 'Tie::Persistent', $ixpfile, 'w', 'Tie::IxHash';

      for (my $i = 0; $i <= $#list; $i++) {
	$ixh{$list[$i]} = $i;
      }

      for (my $i = $#list; $i >= 0; $i--) {
	$ixh{$i} = $list[$i];
      }

      # does it work like an IxHash?
      print eqlists([keys %ixh], [@list, reverse(0..$#list)]) ?
	'ok ': 'not ok ', $n++, "\n";

      untie %ixh;
    }

    {
      my %ixh;
      tie %ixh, 'Tie::Persistent', $ixpfile, 'r';

      my @k = keys %ixh;
      my $notok;
      for (my $i = 0; $i <= $#list; $i++) {
	next if $ixh{$list[$i]} == $i and $k[$i] eq $list[$i];
	$notok = 1;
	last;
      }
      for (my $i = $#list; $i > 0; $i--) {
	next if $ixh{$i} eq $list[$i];
	$notok = 1;
	last;
      }

      print $notok? 'not ok ': 'ok ', $n++, "\n";

      print eqlists([keys %ixh], [@list, reverse(0..$#list)]) ?
	'ok ': 'not ok ', $n++, "\n";

      untie %ixh;
    }

    {
      my %ixh;
      tie %ixh, 'Tie::Persistent', $ixpfile, 'r', 'Tie::IxHash';

      my @k = keys %ixh;
      my $notok;
      for (my $i = 0; $i <= $#list; $i++) {
	next if $ixh{$list[$i]} == $i and $k[$i] eq $list[$i];
	$notok = 1;
	last;
      }
      for (my $i = $#list; $i > 0; $i--) {
	next if $ixh{$i} eq $list[$i];
	$notok = 1;
	last;
      }

      print $notok? 'not ok ': 'ok ', $n++, "\n";

      print eqlists([keys %ixh], [@list, reverse(0..$#list)]) ?
	'ok ': 'not ok ', $n++, "\n";

      untie %ixh;
    }

    {
      my %ixh;
      my %h;
      tie %ixh, 'Tie::IxHash';
      tie %h, 'Tie::Persistent', $ixpfile, 'r', \%ixh;

      my @k = keys %ixh;
      my $notok;
      for (my $i = 0; $i <= $#list; $i++) {
	next if $ixh{$list[$i]} == $i and $k[$i] eq $list[$i];
	$notok = 1;
	last;
      }
      for (my $i = $#list; $i > 0; $i--) {
	next if $ixh{$i} eq $list[$i];
	$notok = 1;
	last;
      }

      print $notok? 'not ok ': 'ok ', $n++, "\n";

    print eqlists([keys %h], [@list, reverse(0..$#list)]) ?
      'ok ': 'not ok ', $n++, "\n";

    print eqlists([keys %ixh], [@list, reverse(0..$#list)]) ?
      'ok ': 'not ok ', $n++, "\n";

    untie %ixh;
  }
  }
  # arrays
  unlink $pfile, $ixpfile, $pfile.'~', $ixpfile.'~';

  unless ($] < 5.005) {
    my $notok;
    {
      {
	my @a;
	tie @a, 'Tie::Persistent', $pfile, 'rw';
	@a = ("stringA".."stringZ");
	untie @a;
      }
      {
	my @b;
	tie @b, 'Tie::Persistent', $pfile, 'r';
	$notok++ if not eqlists(\@b, [("stringA".."stringZ")]);
	$b[0] = '';
	untie @b;
      }
      {
	my @c;
	tie @c, 'Tie::Persistent', $pfile, 'r';
	$notok++ if not eqlists(\@c, [("stringA".."stringZ")]);
	untie @c;
      }
    }
    print $notok? 'not ok ': 'ok ', $n++, "\n";
  }

  # scalars
  unlink $pfile, $ixpfile, $pfile.'~', $ixpfile.'~';

  {
    my $notok;
    foreach my $x ("stringA".."stringG") {
      {
	my $s;
	tie $s, 'Tie::Persistent', $pfile, 'rw';
	$s = $x;
	untie $s;
      }
      {
	my $t;
	tie $t, 'Tie::Persistent', $pfile, 'r';
	$notok += ($t ne $x);
	$t = '';
	untie $t;
      }
      {
	my $u;
	tie $u, 'Tie::Persistent', $pfile, 'r';
	$notok += ($u ne $x);
	untie $u;
      }
    }
    print $notok? 'not ok ': 'ok ', $n++, "\n";
  }

}

exit(0);

sub eqlists {
  my @al = @{$_[0]};
  my @bl = @{$_[1]};

  return undef if $#al != $#bl;
  while(scalar(@al) and shift(@al) eq shift(@bl)) { }
  return (scalar(@al) == 0);
}

__END__

## util.pl - utils
use vars qw($GREP_HEADERS);
$GREP_HEADERS = 'From,To,Subject,Sender';

sub set_m {
  $F = $FOLDER if $FOLDER;
  return $M if $M;
  return $FOLDER->get_message($FOLDER->current_message) if ($FOLDER && defined($FOLDER->current_message));
  return undef;
}

sub grep_array {
  my $re = shift(@_);
  foreach my $elt (@_) {
    return 1 if ($elt =~ /$re/i);
  }
  return 0;
}

sub grep_array2 {
  my $pats = shift(@_);
  foreach my $re (@$pats) {
    foreach my $elt (@_) {
      return 1 if ($elt =~ /$re/i);
    }
  }
  return 0;
}


sub slurp1 {
  my $re = shift(@_);
  my $outf = shift(@_);
  if ($outf) {
    open(OUTF, ">>$outf") || die "$outf: $!\n";
  }
  $M = set_m();
  my $body = $M->body();
  foreach my $line (@$body) {
    if ($line =~ /$re/i) {
      if ($outf) {
        print OUTF "$1\n";
      } else {
        print "$1\n";
      }
    }
  }
}

sub grep_msg {
  $M = set_m();
  say "grep_msg(@_) N=$N M=$M";
  my $re = "@_";
  my $body = $M->body();
  my $line_no = 0;
#  init_pager();
  foreach my $line (@$body) {
    ++$line_no;
    chomp($line);
    if ($line =~ /$re/) {
      my $line = colored_("$N", "cyan") . ":" . colored_("$line_no", "blue") .
                 ": " . colored_("$line", "red");
#      print_paged_line($line);
      print "$line\n";
      $F->add_label($N, "matched");
    }
  }
}

sub grep_headers {
  $M = set_m();
  say "grep_headers(@_) N=$N M=$M";
  my $fieldstr = shift(@_);
  $fieldstr = $GREP_HEADERS unless ($fieldstr ne '_');
  my @fields = split(',', $fieldstr);
  say "grep_headers: @fields";
  my $re = "@_";
  my $head = $M->head();
#  init_pager();
  foreach my $tag (@fields) {
    say "grepping header $tag for /$re/";
    my $n = $head->count($tag);
    my $j = 0;
    while ($j < $n) {
      my $v = $head->get($tag, $j);
      ++$j;
      chomp($v);
      if ($v =~ /$re/) {
        my $line = colored_("$N", "cyan") . ":" . colored_("$tag", "blue") .
                   ": " . colored_("$v", "red");
#        print_paged_line($line);
        print "$line\n";
        $F->add_label($N, "matched");
        last;
      }
    }
  }
}

1;
__END__

# Local variables:
# mode: perl
# indent-tabs-mode: nil
# tab-width: 4
# perl-indent-level: 4
# End:

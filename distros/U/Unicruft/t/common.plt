# -*- Mode: CPerl -*-
# File: t/common.plt
# Description: re-usable test subs for Math::PartialOrder
use Test;
$| = 1;

# codeok($label,\&sub)
sub codeok {
  my ($label,$code) = @_;
  print "$label:\n";
  ok(&$code());
}

# evalok($code_string)
sub evalok {
  my ($code) = @_;
  print "eval: {$code}\n";
  ok(eval($code));
}

# isok($label,@_) -- prints helpful label
sub isok {
  my $label = shift;
  print "$label:\n";
  ok(@_);
}

# slistok($label,\@got,\@expect)
# slistok($label,\@got,\@expect, $sep='$,')
sub slistok {
  my ($label,$got,$expect,$sep) = @_;
  $sep = $, if (!defined($sep));
  isok($label,
       ( '('.join($sep,@$got).')' ) eq ( '('.join($sep,@$got).')' )
      );
}

# ulistok($label,\@got,\@expect)
# --> ok() for unsorted lists
sub ulistok {
  my ($label,$l1,$l2) = @_;
  isok($label,join(',',sort(@$l1)),join(',',sort(@$l2)));
}

# fileok($got_file, $expect_file, $do_sort)
sub fileok {
  my ($gotf,$expectf,$sorted) = @_;
  $sorted = 1 if (!defined($sorted));
  print "file($gotf)===file($expectf) [sorted=", ($sorted ? "yes" : "no"), "]:\n";
  open(GOT,"<$gotf") or die("open failed for got-file '$gotf': $!");
  my $gots = join('',($sorted ? <GOT> : sort(<GOT>)));
  close(GOT);
  open(EXPECT,"$expectf") or die("open failed for expect-file '$expectf': $!");
  my $expects = join('',($sorted ? <EXPECT> : sort(<EXPECT>)));
  close(EXPECT);
  ok($gots eq $expects);
}

# fileok($got_file, $expect_file)
sub ufileok { return fileok(@_[0,1],0); }

# fsmok($label,$fsm1,$fsm2) : uses print_att, ufileok()
sub fsmok {
  my ($label,$fsm1,$fsm2) = @_;
  $fsm1->print_att("$TEST_DIR/tmp1.tfst");
  $fsm2->print_att("$TEST_DIR/tmp2.tfst");
  ufileok("$TEST_DIR/tmp1.tfst", "$TEST_DIR/tmp2.tfst");
  #unlink("tmp1.tfst", "tmp2.tfst");
}

# fsmfileok($fsm,$file) : uses print_att(), ufileok(): check $fsm (got) vs. $file (wanted)
sub fsmfileok {
  my ($fsm1,$file2) = @_;
  $fsm1->print_att("$TEST_DIR/tmp1.tfst");
  ufileok("$TEST_DIR/tmp1.tfst", "$TEST_DIR/$file2");
  #unlink("tmp1.tfst", "tmp2.tfst");
}


print "common.plt loaded.\n";

1;


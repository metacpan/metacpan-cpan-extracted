# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Language-Lisp-ECL.t'

#########################

BEGIN{$ENV{PERL_DL_NONLAZY}=0}# Temporary  fix:) oh, don't ask why....  
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ('no_plan'); # tests => 30?;
BEGIN { use_ok('ecl') };

#########################

my $cl = new ecl;


$cl->eval(<<"EOS");
(defun si::universal-error-handler (cformat eformat &rest args)
  (progn
    (prin1 (format nil "hej-hoj-huj [c=~A] [e=~A] ~A" cformat eformat args))
    ;;(tpl-print-current)
    (invoke-debugger t)
    nil
  ))
EOS

  my $p = 't/tests';
ok('progn ok' eq 
  $cl->eval(qq(
    (progn
      (ext:chdir #P"$p")
      (load "tests")
      (ext:chdir #P"../..")
      ()()()()
      "progn ok"
    )
    )
  )
);

  # alltest
  # strings
  # symbol10
  ##OK open my $fh, "<$p/symbols.tst"
  #setf
  #format
  #?? macro8
  # lists152
for my $tn (qw(symbols lists151 list-set)) {
  open my $fh, "<$p/$tn.tst" or die "$@: $!";

  my $es = $cl->makeStringInputStream(join '', <$fh>);
  my $os = $cl->makeStringOutputStream();
  $cl->doTest($es, $os); # this calls do-test

  print STDERR "\@$tn, unmatched are: [", $cl->getOutputStreamString($os), "]\n";

  ok($cl->getOutputStreamString($os) eq '');
}


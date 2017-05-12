#!perl -w
BEGIN {
  print "1..3\n";
  eval "use ex::lib::zip q($0)";
  print "ok 1\n";
}
use Llama;
print "ok 2\n";
if (&Llama::name eq 'llama') {
  print "ok 3\n";
} else {
  print "not ok 3\n";
}
__END__

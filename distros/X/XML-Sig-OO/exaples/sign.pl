use XML::Sig::OO;
use File::Spec;
use FindBin qw($Bin);

my $s=new XML::Sig::OO(
  xml=>'<?xml version="1.0" standalone="yes"?><data><test ID="A" /><test ID="B" /></data>',
  key_file=>File::Spec->catfile($Bin,'x509_key.pem'),
  cert_file=>File::Spec->catfile($Bin,'x509_cert.pem'),
);
my $result=$s->sign;
die "Failed to sign the xml, error was: $result" unless $result;


my $xml=$result->get_data;

print "Our Signed XML IS: \n",$xml,"\n";
# Example checking a signature
my $v=new XML::Sig::OO(xml=>$xml);

my $result=$v->validate;

if($result) {
  print "Everything checks out\n";
  result_check($result);
} else {
  print "Something went wrong, $result\n";
  result_check($result);
}

sub result_check {
  my ($result)=@_;
  foreach my $chunk (@{$result->get_data}) {
    my ($nth,$signature,$digest)=@{$chunk}{qw(nth signature digest)};

    print "Results for processing chunk $nth\n";
    print "Signature State: ".($signature ? "OK\n" : "Failed, error was $signature\n");
    print "Digest State: ".($digest ? "OK\n" : "Failed, error was $digest\n");
  }
}


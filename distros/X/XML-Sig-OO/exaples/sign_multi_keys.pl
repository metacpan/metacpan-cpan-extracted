use Modern::Perl;
use XML::Sig::OO;
use File::Spec;
use FindBin qw($Bin);
use Crypt::OpenSSL::DSA;
use Crypt::OpenSSL::RSA;

# create our signign object
my $s=new XML::Sig::OO(
  xml=>'<?xml version="1.0" standalone="yes"?><data><test ID="A" /><test ID="B" /></data>',
);

my $x=$s->build_xpath;

# sign our first xml chunk with our rsa key!
my $rsa_str=join '',IO::File->new(File::Spec->catfile($Bin,'x509_key.pem'))->getlines;
my $rsa=Crypt::OpenSSL::RSA->new_private_key($rsa_str);
$rsa->use_pkcs1_padding();
my $cert_str=join '',IO::File->new(File::Spec->catfile($Bin,'x509_cert.pem'))->getlines;
$s->sign_cert($rsa);
$s->key_type('rsa');
$s->cert_string($cert_str);
my $result=$s->sign_chunk($x,1);
die $result unless $result;

# Sign our 2nd chunk with our dsa key
my $dsa = Crypt::OpenSSL::DSA->read_priv_key(File::Spec->catfile($Bin,'dsa_priv.pem'));
$s->cert_string(undef);
$s->sign_cert($dsa);
$s->key_type('dsa');
$result=$s->sign_chunk($x,2);
die $result unless $result;

my ($node)=$x->findnodes($s->xpath_Root);
my $xml=$node->toString;

print "Our Signed XML IS: \n",$xml,"\n";
# Example checking a signature
my $v=new XML::Sig::OO(xml=>$xml);

$result=$v->validate;

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


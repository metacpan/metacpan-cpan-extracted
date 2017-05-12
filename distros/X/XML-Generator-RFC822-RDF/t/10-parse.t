use strict;
use Test::More;

plan tests => 7;

my $msg = "t/example.txt";

use_ok("XML::Generator::RFC822::RDF");
use_ok("Email::Simple");

ok((-f $msg),"found $msg");

my $txt = undef;

{
  local $/;
  undef $/;

  open FH, $msg;
  $txt = <FH>;
  close FH;
}

ok($txt,"read $msg");

my $email = Email::Simple->new($txt);
isa_ok($email,"Email::Simple");

my $parser = XML::Generator::RFC822::RDF->new();
isa_ok($parser,"XML::Generator::RFC822::RDF");

ok($parser->parse($email),"parsed $msg");

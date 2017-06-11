use JSON::XS;
use Devel::Peek;

use YAML::XS ();
use YAML ();
    $YAML::Numify = 1; # since version 1.23
use YAML::Syck ();
    $YAML::Syck::ImplicitTyping = 1;
use YAML::Tiny ();
use YAML::PP::Loader;

my $yaml = "foo: 23";

my $d1 = YAML::XS::Load($yaml);
my $d2 = YAML::Load($yaml);
my $d3 = YAML::Syck::Load($yaml);
my $d4 = YAML::Tiny->read_string($yaml)->[0];
my $d5 = YAML::PP::Loader->new->load($yaml);

Dump $d1->{foo};
Dump $d2->{foo};
Dump $d3->{foo};
Dump $d4->{foo};
Dump $d5->{foo};

say encode_json($d1);
say encode_json($d2);
say encode_json($d3);
say encode_json($d4);
say encode_json($d5);

__END__
SV = PVIV(0x55bbaff2bae0) at 0x55bbaff26518
  REFCNT = 1
  FLAGS = (IOK,POK,pIOK,pPOK)
  IV = 23
  PV = 0x55bbb06e67a0 "23"\0
  CUR = 2
  LEN = 10
SV = PVMG(0x55bbb08959b0) at 0x55bbb08fc6e8
  REFCNT = 1
  FLAGS = (IOK,pIOK)
  IV = 23
  NV = 0
  PV = 0
SV = IV(0x55bbaffcb3b0) at 0x55bbaffcb3c0
  REFCNT = 1
  FLAGS = (IOK,pIOK)
  IV = 23
SV = PVMG(0x55bbaff2f1f0) at 0x55bbb08fc8c8
  REFCNT = 1
  FLAGS = (POK,pPOK,UTF8)
  IV = 0
  NV = 0
  PV = 0x55bbb0909d00 "23"\0 [UTF8 "23"]
  CUR = 2
  LEN = 10
SV = PVMG(0x55bbaff2f6d0) at 0x55bbb08b2c10
  REFCNT = 1
  FLAGS = (IOK,pIOK)
  IV = 23
  NV = 0
  PV = 0
{"foo":"23"}
{"foo":23}
{"foo":23}
{"foo":"23"}
{"foo":23}


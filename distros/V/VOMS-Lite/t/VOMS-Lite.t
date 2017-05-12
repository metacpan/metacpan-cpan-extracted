# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VOMS-Lite.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Cwd;
use Test;
use Sys::Hostname;
my $host = hostname;
if ( ! defined $host ) { $host = "localhost.localdomain"; }
$host =~ y/A-Z/a-z/;
if ( $host !~ /\./ ) { $host.=".localdomain"; }

BEGIN { plan tests => 21 };

my $cwd = getcwd;
my $etc="$cwd/etc";
my $capath="$etc/certificates";

if ( ! -d $etc ) { mkdir($etc) or die "no test etc directory"; }
if ( ! -d $capath ) { mkdir($capath) or die "no test etc/certificates directory"; }

#Make CA cert here


#----------------1
eval "require VOMS::Lite::X509"; 
if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }

#----------------2
my $refCA;
eval '$refCA = VOMS::Lite::X509::Create( { Serial=>0,
                                               DN=>["C=ACME","O=VOMS::Lite","CN=VOMS::Lite Test CA"],
                                                CA=>"True",
                                              Bits=>512,
                                          Lifetime=>172800 } );';
if ($@) { print STDERR "$@"; ok(0); } else { ok(1); }

my %CA = %{ $refCA };


#----------------3
if (defined $CA{Cert} && defined $CA{Key} && ! defined $CA{Errors} && $CA{Cert} =~ /^\060/s && $CA{Key} =~ /^\060/s) { ok(1); } 
else { 
  ok(0);
  print STDERR "#Not Able to create a CA certificate\n";
  if ($CA{Cert} =~ /^\060/s ) {print STDERR "#CA cert did not begin with 0x30\n"; my $tmp=$CA{Cert}; $tmp =~ s/./sprintf("%X ",ord($&))/seg; print "#$tmp\n";}
  if ($CA{Key} =~ /^\060/s )  {print STDERR "#CA key did not begin with 0x30\n";  my $tmp=$CA{Key};  $tmp =~ s/./sprintf("%X ",ord($&))/seg; print "#$tmp\n";}
  if ( defined $CA{Errors} )   { print STDERR "ERROR: ".join("\nERROR: ",@{ $CA{Errors} })."\n"; }
  if ( defined $CA{Warnings} ) { print STDERR "WARN: ".join("\nWARN: ",@{ $CA{Warnings} })."\n"; }
}


#----------------4
eval "require VOMS::Lite::PEMHelper"; 
if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }

my $CAcert="$capath/$CA{'Hash'}.0";
my $CAkey="$capath/$CA{'Hash'}.k0";


#----------------5
eval { VOMS::Lite::PEMHelper::writeCert("$CAcert", $CA{'Cert'});          }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }


#----------------6
eval { VOMS::Lite::PEMHelper::writeKey("$CAkey", $CA{'Key'}, 'testpass'); }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }


#Make host certificate here

#----------------7
my %host = %{ VOMS::Lite::X509::Create( { Serial=>1,
                                          CACert=>$CA{'Cert'},
                                           CAKey=>$CA{'Key'},
                                              DN=>["C=ACME","O=VOMS::Lite","CN=$host"],
                                              CA=>"False",
                                            Bits=>512,
                                  subjectAltName=>["dNSName=$host"],
                                        Lifetime=>86400 } ) };
if (defined $host{Cert} &&  defined $host{Key} && ! defined $host{Errors} ) { ok(1); } 
else { 
  ok(0); 
  print STDERR "Not Able to create a host certificate\n".@{ $host{Errors} }; 
  if ( defined $host{Errors} )   { print STDERR "ERROR: ".join("\nERROR: ",@{ $host{Errors} })."\n"; }
  if ( defined $host{Warnings} ) { print STDERR "WARN: ".join("\nWARN: ",@{ $host{Warnings} })."\n"; }
}


#----------------8
eval { VOMS::Lite::PEMHelper::writeCert("$etc/vomscert.pem", $host{'Cert'});  }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }


#----------------9
eval { VOMS::Lite::PEMHelper::writeKey("$etc/vomskey.pem", $host{'Key'}, ''); }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }

#Make user certificate here


#----------------10
my %user = %{ VOMS::Lite::X509::Create( { Serial=>2,
                                          CACert=>$CA{'Cert'},
                                           CAKey=>$CA{'Key'},
                                              DN=>["C=ACME","O=VOMS::Lite","CN=A Perl User"],
                                              CA=>"False",
                                            Bits=>512,
                                  subjectAltName=>["rfc822Name=root\@$host"],
                                        Lifetime=>86400 } ) };
if (defined $user{Cert} &&  defined $user{Key} && ! defined $user{Errors} ) { ok(1); } 
else { 
  ok(0); print STDERR "Not Able to create a user certificate\n"; 
  if ( defined $user{Errors} )   { print STDERR "ERROR: ".join("\nERROR: ",@{ $user{Errors} })."\n"; }
  if ( defined $user{Warnings} ) { print STDERR "WARN: ".join("\nWARN: ",@{ $user{Warnings} })."\n"; }
}


#----------------11
eval { VOMS::Lite::PEMHelper::writeCert("$etc/usercert.pem", $user{'Cert'}); }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }


#----------------12
eval { VOMS::Lite::PEMHelper::writeKey("$etc/userkey.pem", $user{'Key'}, 'testing'); }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }

#Make proxy certificate here


#----------------13
eval "require VOMS::Lite::PROXY"; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }


#----------------14
my %proxy = %{ VOMS::Lite::PROXY::Create( { Cert=>$user{'Cert'},
                                             Key=>$user{'Key'},
                                            Type=>"Legacy",
                                        Lifetime=>36000 } ) };
if (defined $proxy{ProxyCert} &&  defined $proxy{ProxyKey} && ! defined $proxy{Errors} ) { ok(1); } 
else { 
  ok(0); 
  print STDERR "Not Able to create a proxy certificate\n"; 
  if ( defined $proxy{Errors} )   { print STDERR "ERROR: ".join("\nERROR: ",@{ $proxy{Errors} })."\n"; }
  if ( defined $proxy{Warnings} ) { print STDERR "WARN: ".join("\nWARN: ",@{ $proxy{Warnings} })."\n"; }
}


#----------------15
eval { VOMS::Lite::PEMHelper::writeCertKey("$etc/proxy", $proxy{'ProxyCert'}, $proxy{'ProxyKey'}, ( $user{'Cert'} ) ); }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }


open (CONF,">$etc/voms.conf") or die "Failed to create $etc/voms.conf";
print CONF <<EOF;
CertDir=$etc/certificates
VOMSCert=$etc/vomscert.pem
VOMSKey=$etc/vomskey.pem
AttribType=Dummy
Lifetime=3600
Server=$host
Code=15000
Port=15000
EOF
close CONF;
chmod 0600, "$etc/voms.conf";

# Test VOMS::Lite
$ENV{'VOMS_CONFIG_FILE'} = "$etc/voms.conf";


#----------------16
eval "use VOMS::Lite"; if ($@) { ok(0); print STDERR "$@";  } else { ok(1); }
my $ref=VOMS::Lite::Issue( [$user{Cert}, $CA{Cert}], "/Dummy" );
my %AC=%$ref;


#----------------17
if (defined $AC{Errors}  ) { ok(0); print STDERR "There were errors producing the AC\n"; foreach ( @{$AC{Errors}} ) { print STDERR "$_\n"; } } else { ok(1); }


#----------------18
if (defined $AC{AC}      ) { ok(1); } else { ok(0); print STDERR "No AC was produced\n"; }


#----------------19
if (defined $AC{Attribs} && "@{ $AC{Attribs} }" eq "/Dummy/Role=NULL/Capability=NULL" ) { ok(1); } else { ok(0); print STDERR "No Attributes were returned from VOMS::Lite::Issue\n"; }

foreach my $key (keys %AC) {
  if ( ref($AC{$key}) eq "ARRAY" ) {
    my $arrayref=$AC{$key};
    my @array=@$arrayref;
    my $tmp=$key;
    foreach (@array) { printf STDERR "%-15s %s\n", "$tmp:","$_"; $tmp=""; }
  }
}

my $ACpemstr;


#----------------20
eval { $ACpemstr=VOMS::Lite::PEMHelper::encodeAC($AC{AC}); }; if ($@) { ok(0); print STDERR "$@";  } else { ok(1); }
#print $ACpemstr;


#----------------21
eval { VOMS::Lite::PEMHelper::writeAC("$etc/AC",$AC{AC}); }; if ($@) { ok(0); print STDERR "$@"; } else { ok(1); }


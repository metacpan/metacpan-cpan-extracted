#!/usr/bin/perl

use VOMS::Lite::PEMHelper;
use VOMS::Lite::CertKeyHelper qw(buildchain);

my @certs=VOMS::Lite::PEMHelper::readCert("/tmp/x509up_u$<");

my %Chain = %{ buildchain( { trustedCAdirs => [ "/etc/grid-security/certificates" ], suppliedcerts => \@certs } ) };

my @returnedCerts = @{ $Chain{Certs} };
my @IHash         = @{ $Chain{IssuerHashes} };
my @Hash          = @{ $Chain{SubjectHashes} };
my @SKID          = @{ $Chain{SubjectKeyIdentifiers} };
my @AKID          = @{ $Chain{AuthorityKeyIdentifiersSKIDs} };
my @DNs           = @{ $Chain{DistinguishedNames} };
my @IDNs          = @{ $Chain{IssuerDistinguishedNames} };
my @Trust         = @{ $Chain{TrustedCA} };
my @GSI           = @{ $Chain{GSIType} };
my @Errors        = @{ $Chain{Errors} };
my $Err           = 0;

while ( $#returnedCerts >= 0 ) {
  print "DN          ".(shift @DNs)."\n";
  print "Hash        ".(shift @Hash)."\n";
  print "Issuer DN   ".(shift @IDNs)."\n";
  print "Issuer Hash ".(shift @IHash)."\n";
  print "GSI Status  ".(shift @GSI)."\n";
  print "Locally Trusted\n" if (shift @Trust == 1);
  my @certErrors=@{ shift @Errors };
  if ( $#certErrors >=0 ) { $Err=1; foreach (@certErrors) { print "ERROR:      $_\n"; } }
  print VOMS::Lite::PEMHelper::encodeCert(shift @returnedCerts);
  print "\n";
}
print "Chain is complete.\n" if ( $self == 1 );
print "But there were errors.\n" if ( $Err == 1 );

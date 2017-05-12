package VOMS::Lite;

#This package issues VOMS credentials
use 5.004;
use strict;
use VOMS::Lite::PEMHelper qw(readCert readPrivateKey);
use VOMS::Lite::CertKeyHelper qw(buildchain);
use VOMS::Lite::ASN1Helper qw(Hex);
use VOMS::Lite::AC;
use Digest::MD5 qw(md5_hex);

require Exporter;
use vars qw($VERSION @EXPORT_OK @EXPORT);
BEGIN {
  @EXPORT = qw( %conf );
  @EXPORT_OK = qw( Issue );
}

$VERSION = '0.20';

###########################################################

my $configfile;
my %conf;
if (defined $ENV{'VOMS_CONFIG_FILE'}) { $configfile=$ENV{'VOMS_CONFIG_FILE'}; }
elsif ( $< == 0 )                     { $configfile="/etc/grid-security/voms.config"; }
else                                  { $configfile=$ENV{'HOME'}."/.grid-security/voms.config"; }

# Check for config file
if ( -r $configfile ) {
  if ( (stat($configfile))[2] & 077 ) { 
    if ( $^O =~ /^MSWin/ ) { print STDERR "WARNING: VOMS::Lite: Inapropriate permissions on config file: $configfile\n"; }
    else                   { die "VOMS::Lite: Inapropriate permissions on config file: $configfile"; }
  }
  if ( open(CONF,"<$configfile") ) {
    while (<CONF>) {
      chomp;
      if ( /^\s*([a-zA-Z0-9_-]+)\s*=\s*(.+?)\s*$/ ) { $conf{"$1"} = $2; }
    }
    close CONF;
  } 
  else { 
    die "VOMS::Lite: Unable to open config file: $configfile";
  }
}
else { die "VOMS::Lite: Unable to open config file: $configfile"; }

# Set CertDir (where the CAs are stored
if (! defined $conf{CertDir}) { 
  if (-d "$ENV{HOME}/.grid-security/certificates" ) { $conf{CertDir} = "$ENV{HOME}/.grid-security/certificates"; }
  elsif (-d "/etc/grid-security/certificates" ) { $conf{CertDir} = "/etc/grid-security/certificates"; }
}

# Set VOMS Certificate
if (defined $conf{VOMSCert}) { $conf{VOMSCert} = readCert("$conf{VOMSCert}"); }
else {
  if (-d "$ENV{HOME}/.grid-security/vomscert.pem" ) { $conf{VOMSCert} = readCert("$ENV{HOME}/.grid-security/vomscert.pem"); }
  elsif (-d "/etc/grid-security/vomscert.pem" ) { $conf{VOMSCert} = readCert("/etc/grid-security/vomscert.pem"); }
}

# Set VOMS Key
if (defined $conf{VOMSKey}) { $conf{VOMSKey} = readPrivateKey("$conf{VOMSKey}"); }
else {
  if (-d "$ENV{HOME}/.grid-security/vomskey.pem" ) { $conf{VOMSKey} = readPrivateKey("$ENV{HOME}/.grid-security/vomskey.pem"); }
  elsif (-d "/etc/grid-security/vomskey.pem" ) { $conf{VOMSKey} = readPrivateKey("/etc/grid-security/vomskey.pem"); }
}

# Set Type of VO user database
my $AttribCodeRef;
if (defined $conf{'AttribType'}) {
  if    ($conf{'AttribType'} eq "Database") { 
    require VOMS::Lite::Attribs::DBHelper;
    $AttribCodeRef = \&GetDBAttribs; 
    if (!defined $conf{'DBHost'}) { $conf{'DBHost'}="localhost"; }
    if (!defined $conf{'DBPort'}) { $conf{'DBPort'}="3306"; }
    if (!defined $conf{'DBUser'}) { die "VOMS::Lite: Database username not specified."}
    if (!defined $conf{'DBPass'}) { die "VOMS::Lite: Database password not specified."}
  }
  elsif ($conf{'AttribType'} eq "GridMap") { 
    $AttribCodeRef = \&GetGridMapping;  
    if (!defined $conf{'grid-mapfiles'}) {
      if (-d "$ENV{HOME}/.grid-security/grid-mapfile.d" ) { $conf{'grid-mapfiles'}="$ENV{HOME}/.grid-security/grid-mapfile.d"; }
      elsif (-d "/etc/grid-security/grid-mapfile.d" ) { $conf{'grid-mapfiles'}="/etc/grid-security/grid-mapfile.d"; }
      else { die "VOMS::Lite: grid-mapfile method specified but no grid-mapfile.d directory found"; }
    }
  }
  elsif ($conf{'AttribType'} eq "GridSite") { 
    $AttribCodeRef = \&GetGridSiteAttribs; 
    if (!defined $conf{'GridSiteURI'}) { die "VOMS::Lite: GridSite method specified but no GridSiteURI specified."; }
  }
  elsif ($conf{'AttribType'} eq "Shibboleth") { 
    require VOMS::Lite::Attribs::SHIBHelper;
    $AttribCodeRef = \&GetShibAttribs;  
  }
  elsif ($conf{'AttribType'} eq "Dummy")      { $AttribCodeRef = \&GetDummyAttribs; }
  else { die "VOMS::Lite: Attribute Method unknown."; }
}
else {
  die "VOMS::Lite: Attribute method unspecified in config file $configfile";
}

###########################################################

sub UserCert {
#This function takes in an array of certificates, completes the chain if necessary and returns
#The reference to the chain 
  my @certs=@_;
  my %Chain = %{ buildchain( { trustedCAdirs => [ $conf{CertDir} ], suppliedcerts => \@certs} ) };
  return ($Chain{Certs},$Chain{EndEntityDN},$Chain{EndEntityIssuerDN},$Chain{EndEntityCert});
}

###########################################################

sub Issue {

  my ($CertsRef,$ReqAttribs)=@_;
  my @Certs=@$CertsRef;
  my ($CertChainRef,$DN,$CA,$CERT)=UserCert(@Certs);

# Get the attributes
  my $AttribRef=&$AttribCodeRef($DN,$CA,$ReqAttribs);
  my %Attribs=%$AttribRef;

  if ( defined $Attribs{'Errors'} ) { return $AttribRef; }

# Get AC
  return VOMS::Lite::AC::Create( { Cert     => $CERT,
                                   VOMSCert => $conf{'VOMSCert'},
                                   VOMSKey  => $conf{'VOMSKey'},
                                   Lifetime => $conf{'Lifetime'},
                                   Server   => $conf{'Server'},
                                   Port     => $conf{'Port'},
                                   Serial   => $Attribs{'Serial'},
                                   Code     => $conf{'Code'},
                                   Attribs  => $Attribs{'Attribs'},
                                   Broken   => 1 } );
}

###########################################################

sub GetDBAttribs {
  my ($DN,$CA,$ReqAttrib)=@_;

  my $DB=undef;
  my ($VO,$subGroup,$Role,$Capability) = $ReqAttrib =~ m#^(/[^/]+)(/.*)?(/Role=[^/]*)?(/Capability=[^/]*)?$#;
  if (! defined $VO ) { return { Errors => [ "VOMS::Lite: No VO specified" ] }; }

  my $function;

  if    ( defined $subGroup && defined $Role )  { $function="groupandrole"; }
  elsif ( defined $Role )                       { $function="role"; }
  elsif ( defined $subGroup )                   { $function="attributes"; } # or maybe all
  else                                          { $function="group";}

  $DB=$VO;
  $DB=~s/^\///;

  foreach (keys %conf) {
    if ( /^(DBMapping_[0-9]+)$/ ) {
      if ( $conf{$1} =~ /^$DB\s+(\S*)\s*$/ ) { $DB = $1; print "------ $1\n"  }
    }
  }

  if ( $DB =~ /^[\000\377\\\/.]$/ || $DB =~/ $/ || length($DB) > 64) { return { Errors => [ "VOMS::Lite: Bad Database name $DB" ] }; }

 # Get VO data from Database
  my @Attribs=VOMS::Lite::Attribs::DBHelper::GetAttrib($DB,$conf{'DBHost'},$conf{'DBPort'},$conf{'DBUser'},$conf{'DBPass'},$Role,"$VO$subGroup",$CA,$DN,$function);
  my $Serial=hex(shift @Attribs); #stored as hex in DB

  return { Serial => $Serial, Attribs=>\@Attribs};
}

###########################################################

sub GetGridMapping {
  my ($DN,$CA,$ReqAttrib)=@_;

  my @Attribs;
  my ($VO,$subGroup,$Role,$Capability) = $ReqAttrib =~ m#^(/[^/]+)(/.*)?(/Role=[^/]*)?(/Capability=[^/]*)?$#;
  if (! defined $VO ) { return { Errors => [ "VOMS::Lite: No VO specified" ] }; }
  open GRIDMAP,"<$conf{'grid-mapfiles'}$VO" or return  { Errors => [ "VOMS::Lite: No Gridmapfile for VO" ] };
  foreach (<GRIDMAP>) { if ( m|^\s*"$DN"\s+(.*)| ) { @Attribs= split(/,/,$1); last; } }
  close GRIDMAP;

  my $serial=0;
  open(SERIAL, "+>> $conf{'grid-mapfiles'}$VO.serial") or return  { Errors => [ "VOMS::Lite: Unable to open/create serial file $conf{'grid-mapfiles'}/$VO.serial, Check Permissions" ] };
  seek(SERIAL,0,0);
  my @lines=<SERIAL>;

  if ( $lines[0] =~ /^[0-9]+$/ ) { $serial=$1; }
  seek(SERIAL,0,0);
  print SERIAL ++$serial;
  close SERIAL;

  my @Roles;
  my @Capabilities;
  my @Groups;
  foreach (@Attribs) { 
    s/^\s*//; 
    s/\s*$//;
    if    ( defined $Role       && /Role=$Role/o )             { push @Roles,$Role; }
    if    ( defined $Capability && /Capability=$Capability/o ) { push @Capabilities,$Capability; }
    if    ( defined $subGroup   && /$VO$subGroup^/o )          { push @Groups,$_; }
    elsif ( /^$VO(?:\/|$)/ )                                   { push @Groups,$_; }
  }
  push @Roles,"/Role=NULL";
  push @Capabilities,"/Capability=NULL";
  my @RetAttribs=();
  foreach my $group (@Groups) { 
    foreach my $role (@Roles) { 
      foreach my $capability (@Capabilities) { push @RetAttribs,"$group$role$capability"; }
    }
  }

  return { Serial => $serial, Attribs=>\@RetAttribs};
}

###########################################################

sub GetGridSiteAttribs {
#    eval "use use LWP::UserAgent;";
#    voms-proxy-init.pl:    
#    my $agent    = LWP::UserAgent->new;
#
### Cert, 
### get https://www.blah/primary.group/subgroup/Role=nuff
#
#
#
    return { Serial => 01, Attribs=> [ "/GridSiteDummy/Role=NULL/Capability=NULL" ] };
}

###########################################################

sub GetShibAttribs {
# If ShibExportAssertion is on in your http.conf The following Env variable should be set it will be XML
  my @Attribs=VOMS::Lite::Attribs::SHIBHelper::GetAttrib($ENV{'HTTP_SHIB_ATTRIBUTES'});
  my $Serial=shift @Attribs;
  return { Serial => 01, Attribs=> [ "/ShibDummy/Role=NULL/Capability=NULL" ] };
}

###########################################################

sub GetDummyAttribs {
    return { Serial => 01, Attribs => [ "/Dummy/Role=NULL/Capability=NULL" ] };
}


1;


__END__

=head1 NAME

VOMS::Lite - Perl extension for VOMS Attribute certificate creation

=head1 SYNOPSIS

  use VOMS::Lite qw( Issue );;
  my $ref=VOMS::Lite::Issue( \@certs, $ReqAttribs );
  my %hash=%$ref;
  my $derAC=%hash{AC};
  my @errors=%hash{Errors};
  my @warnings=%hash{Warnings};
  my @attributes=%hash{Attribs};
  my @targets=%hash{Targets};

=head1 DESCRIPTION

VOMS::Lite Provides an Issue routine which reads a configuration file in $ENV{'VOMS_CONFIG_FILE'} or else (if root) /etc/grid-security/voms.config, or else ~/.grid-security/voms.conf.

Active lines in the config file must have the form:
^\s*([a-zA-Z0-9_-]+)\s*=\s*(.+?)\s*$
i.e.
  $1 = $2
This will set values in the %conf hash (which is exported).

  CertDir    = Path to Trusted CAs
  VOMSCert   = Path to VOMS Issuing Certificate
  VOMSKey    = Path to VOMS Issuing Key
  AttribType = (Database|GridMap) 
    DBHost=fqdn.of.database.host    \
    DBPort=port.of.database.host     }
    DBUser=username                  }- If AttribType=Database
    DBPass=password                  }
    DBMapping_N=vo.full.name DBNAME / - where N is [0-9]+ and unique
  Lifetime   = Lifetime of AC in seconds
  Server     = FQDN of VOMS server (used in AC itself)
  Port       = Port of VOMS server (used in AC itself)


If AttribType=GridMap is specified then the files
~/.grid-security/grid-mapfile.d/VOname or /etc/grid-security/grid-mapfile.d/VOname must exist.  
VOMS::Lite supports any number of VOs specified this way.  The format of a VOMS grid-mapfile is similar to the Globus grid-mapfile:

"/Slash/delimited/DN/of/EEC" Group(, OtherGroup)*(, Role=role)*(, Capability=capability)*
...

=head2 EXPORT

%conf by default.
Issue if specified.

=head1 SEE ALSO

VOMS::Lite::AC

RFC3281 and the VOMS Attribute Specification document from the OGSA Athuz Working Group of the Open Grid Forum http://www.ogf.org.
Also see gLite from the EGEE.

This module was originally designed for the SHEBANGS project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/
E<0x0a>now http://www.rcs.manchester.ac.uk/projects/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

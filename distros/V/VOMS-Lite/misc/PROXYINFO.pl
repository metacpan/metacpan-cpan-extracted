#!/usr/bin/perl

use MIME::Base64;

my $myCert="/tmp/x509up_u$<";
my $myCertData="";
my $read=0;
my $type="";

open(CERT,"<$myCert");
while (<CERT>) {
  my $line=$_;
  if ( $line =~ /^-----BEGIN ([A-Z0-9 ]*)-----$/ ) {$read=1; $type=$1;}
  if ( $line =~ /^-----END $type-----$/ ) {last;}
  if ( $read==1 && $line =~ /^([A-Za-z0-9+\/=]*)$/ ) {$myCertData.=$1;}
}
close(CERT);

my $decoded = decode_base64($myCertData);
my $certlen=length($decoded);

@bits = split(//, unpack("B*", $decoded));

my @ConLen=();
my @LenStart=();
my $inheader=1;
my $lenlen=0;
my $reallen=0;

my $Class;
my $Constructed=0;
my $Tag=0;
my $oid="";

for ( my $i = 0 ; $i < $certlen ; $i++ ) {
#  printf "%d\t0x%02x\t",$i,ord(substr($decoded, $i,1));
  printf "0x%02x\t",ord(substr($decoded, $i,1));
  for(my $a=0;$a<8;$a++) { print $bits[($i*8+$a)]; }

  print " ";
  if (@ConLen < 20) {
    print "|" x scalar(@ConLen);
    print " " x (21 - scalar(@ConLen));
  } else {
    print "                  -> ";
  }
  if ( $inheader!=1 ) { print "\t";} 

  if ( $inheader==1 ) { # ID
    $Class= $bits[($i*8)]*2 + $bits[($i*8 + 1)];
    $Constructed=$bits[($i*8 + 2)];

    print "U "  if ($Class == 0);
    print "A "  if ($Class == 1);
    print "C "  if ($Class == 2);
    print "P "  if ($Class == 3);
    print "P " if ($Constructed == 0);
    print "C " if ($Constructed == 1);

    $Tag=0;
    for (my $a=3;$a<8;$a++) { $Tag += $bits[($i*8+$a)]*(2**(7-$a)); } #Tag from these 5 bits

    $lenlen=0;
    if ($Tag==31) {
      $inheader=2;
      print "\"Tag (next byte)\"\t";
      $Tag=0;
    } else {
      $inheader=3;
        if ($Class == 0 ) {
         if ( $Tag == 1 ) { print "[BOOLEAN]\t"; }
      elsif ( $Tag == 2 ) { print "[INTEGER]\t"; }
      elsif ( $Tag == 3 ) { print "[BIT STRING]\t"; }
      elsif ( $Tag == 4 ) { print "[OCTET STRING]\t"; }
      elsif ( $Tag == 5 ) { print "[NULL]\t"; }
      elsif ( $Tag == 6 ) { print "[OID]\t"; }
      elsif ( $Tag == 7 ) { print "[ODT]\t"; }
      elsif ( $Tag == 8 ) { print "[EXTERNAL/INSTANCE]\t"; }
      elsif ( $Tag == 9 ) { print "[REAL]\t"; }
      elsif ( $Tag == 10 ) { print "[ENUM]\t"; }
      elsif ( $Tag == 11 ) { print "[EMBEDDED-PDV]\t"; }
      elsif ( $Tag == 12 ) { print "[UTF-8 String]\t"; }
      elsif ( $Tag == 13 ) { print "[ROID]\t"; }
      elsif ( $Tag == 16 ) { print "[SEQUENCE]\t"; }
      elsif ( $Tag == 17 ) { print "[SET]\t"; }
      elsif ( $Tag == 19 ) { print "[PRINTABLESTRING]\t"; }
      elsif ( $Tag == 22 ) { print "[IA5String]\t"; }
      elsif ( $Tag == 23 ) { print "[UTCTIME]\t"; }
      elsif ( $Tag == 24 ) { print "[GENERALISED TIME]\t"; }
      elsif ( $Tag>=18 && $Tag<=22 ) { print "[UNKNOWN STRING]\t"; }
      elsif ( $Tag>=25 && $Tag<=30 ) { print "[UNKNOWN STRING]\t"; }
      else { print "[Tag=$Tag]\t"; }
        } else {print "[Tag=$Tag]\t"; }
    }
  } elsif ( $inheader==2 ) {
    $Tag *= 128; #Shift by 7 bits!
    for (my $a=1;$a<8;$a++) { $Tag += $bits[($i*8+$a)]*(2**(7-$a)); } #Add these 7 bits
 
    if ($bits[($i*8)] == 0) {
      $inheader=3;
      print "\"Tag=$Tag\"\t";
    } else {
      print "\"Tag (next byte)\"\t";
    }
  } elsif ( $inheader==3 ) { # Length
    for (my $a=1;$a<8;$a++) { $lenlen += $bits[($i*8+$a)]*(2**(7-$a)); }

    $reallen=0;
    if ( $bits[($i*8 + 0)] == 0 ) { #encoded here
      print "Length = $lenlen\t";
      $inheader=-1;
      $reallen=$lenlen;
      push @ConLen,$reallen;
      push @LenStart,$i;
    } else {
      print "Length (encoded $lenlen bytes) =\t";
      $inheader=4;
    }
  } elsif ( $inheader==4 ) {
    $lenlen--;
    my $len=0;
    for (my $a=0;$a<8;$a++) { $len += $bits[($i*8+$a)]*(2**(7-$a)); }
    $len*=(256**$lenlen);
    $reallen+=$len;
    if ( $lenlen == 0 ) { 
      $inheader=-1;
      push @ConLen,$reallen;
      push @LenStart,$i;
      print "$len = $reallen\t";
    } else {
      print "$len + ";
    }
  } else {
    print "\t";
    my $char=substr $decoded,$i,1;
    if ( $Tag == 1 ) {                     ################# Boolean type
      print (( ord($char) == 0 )?"FALSE":"TRUE")."\t";

    } elsif ( $Tag == 2 ) {                ################# Integer type
      printf "0x%02X\t",ord($char);
      if ( $i - $LenStart[-1] == $ConLen[-1] ) { 
	my $val=0;
        for (my $a=0;$a<$ConLen[-1];$a++) {
	  $val*=256; #Shift 8 bits left
          for (my $b=(($a==0)?1:0);$b<8;$b++) { $val += $bits[(($a+$LenStart[-1]+1)*8+$b)]*(2**(7-$b)); } #Add these 8 bits
        }
        print "= $val\t";
      }

    } elsif ( $Tag == 3 ) { ################# Bit String type
      if ( $i != $LenStart[-1]+1 ) { 
        printf "%08b\t",ord($char);
      } elsif ( $i == $LenStart[-1]+1+$ConLen[-1] ) { #Last bit
	my $a=ord(substr($decoded,$LenStart[-1],1));
        for (my $b=0;$b<8;$b++) { print $bits[$i*8+$b] if ( (8-$b)>$a ); }
        print "\t";
      }

    } elsif ( $Tag == 4 ) { ################# Octet String type
      printf "0x%02X\t",ord($char);
      print "'".(($char =~ /[\040-\177]/ ) ? $char : "")."'\t";

    } elsif ( $Tag == 6 && $Class == 0) { ################# OID type
      printf "0x%02X\t",ord($char);
      if ( $i - $LenStart[-1] == $ConLen[-1] ) { 
	my @tmp=();
        my $tmp=0;
	for (my $a=0;$a < $ConLen[-1]; $a++) {
	  my $val=ord( substr $decoded,($LenStart[-1]+1+$a),1 );
          if ( $val > 127 ) {$tmp+=($val-128); $tmp*=128;}
          else {$tmp+=$val; push @tmp,$tmp; $tmp=0;}
        }
        $tmp=shift @tmp;
        my $a = int($tmp/40);
        my $b = $tmp-($a*40);
        $oid="$a.$b";
        foreach ( @tmp ) { $oid.=".$_"; }
        print &OIDS($oid)."\t";
      }
    } elsif ( $Tag == 19 || $Tag == 22 ) { ################# Printable/IA5 String type
      print "'$char'\t";
      if ( $i - $LenStart[-1] == $ConLen[-1] ) { print "\"".substr($decoded,$LenStart[-1]+1,$ConLen[-1])."\"\t" };

    } elsif ( $Tag == 23 ) { ################# UTC Time type
      printf "0x%02X\t",ord($char);
      if ( $i - $LenStart[-1] == $ConLen[-1] ) { 
        my $a=$LenStart[-1]+1;
        my $year=substr $decoded,$a,2;
        my $mth=substr $decoded,$a+2,2;
        my $day=substr $decoded,$a+4,2;
        my $hour=substr $decoded,$a+6,2;
        my $min=substr $decoded,$a+8,2;
        my $sec=substr $decoded,$a+10,2;
        print "$hour:$min:$sec $day/$mth/$year\t";
      }
    } else {                 ################# Unknown type
      printf "0x%02X\t",ord($char);
    }
  }

# Deal with constructions including VOMS
  if ( $inheader==-1 ) {
    if ($Constructed == 1) {
      $inheader=1;
    } else {
      $inheader=0;
    }
    if ($Constructed == 0 && $oid eq "1.3.6.1.4.1.8005.100.100.5") {
      $inheader=1;
      $oid="";
    }
  }


# Deal with end of content lengths
  if ( $i - $LenStart[-1] == $ConLen[-1] && $ConLen[-1] =~ /[0-9]/ && $LenStart[-1] =~ /[0-9]/ ) {
    $inheader=1;
  }

  while ( ( $i - $LenStart[-1] == $ConLen[-1] || $ConLen[-1] == 0 ) && scalar(@ConLen) > 0 ) {
    pop @ConLen;
    pop @LenStart;
  }
  print "\n";
}


sub OIDS {
  my $OID=shift;
  my @OID=split /\./,$OID;

  if ( $OID[0] == "1" ) {
    if ( $OID[1] == "2" ) {
      if ( $OID[2] == "840" ) {
        if ( $OID[3] == "113549" ) {
          if ( $OID[4] == "1" ) {
            if ( $OID[5] == "1" ) {
              if ( $OID[6] == "1" ) { return "rSAEncription"; }
              elsif ( $OID[6] == "2" ) { return "md2WithRSAEncription"; }
              elsif ( $OID[6] == "3" ) { return "md4WithRSAEncryption"; }
              elsif ( $OID[6] == "4" ) { return "md5WithRSAEncryption"; }
              elsif ( $OID[6] == "5" ) { return "sha1WithRSAEncryption"; }
              elsif ( $OID[6] == "6" ) { return "rsaOAEPEncryptionSET"; }
            }
            elsif ( $OID[5] == "9" ) {
              if ( $OID[6] == "1" ) { return "e-mailAddress"; }
              elsif ( $OID[6] == "2" ) { return "PKCS-9 unstructuredName"; }
              elsif ( $OID[6] == "3" ) { return "contentType"; }
              elsif ( $OID[6] == "4" ) { return "messageDigest"; }
              elsif ( $OID[6] == "5" ) { return "Signing Time"; }
              elsif ( $OID[6] == "7" ) { return "Challenge Password"; }
              elsif ( $OID[6] == "8" ) { return "PKCS-9 unstructuredAddress"; }
              elsif ( $OID[6] == "13" ) { return "Signing Description"; }
              elsif ( $OID[6] == "15" ) { return "S/Mime capabilities"; }
              elsif ( $OID[6] == "16" ) { return "S/MIME Object Identifier Registry"; }
              elsif ( $OID[6] == "20" ) { return "PKCS-9 Attribute : friendlyName"; }
              elsif ( $OID[6] == "22" ) { return "certTypes"; }
            }
          }
        }
      }
    }
    elsif ( $OID[1] == "3" ) {
      if ( $OID[2] == "6" ) {
        if ( $OID[3] == "1" ) {
          if ( $OID[4] == "4" ) {
            if ( $OID[5] == "1" ) {
              if ( $OID[6] == "8005" ) {
                if ( $OID[7] == "100" ) {
                  if ( $OID[8] == "100" ) {
                    if ( $OID[9] == "1" ) { return "vOMSvoms"; } #Obsolite
                    elsif ( $OID[9] == "2" ) { return "vOMSIncludeFile"; }
                    elsif ( $OID[9] == "3" ) { return "vOMSvO"; }
                    elsif ( $OID[9] == "4" ) { return "vOMSAttributes"; } #SEQ {OS{triple}.OS{triple}
                    elsif ( $OID[9] == "5" ) { return "vOMSAssertions"; } #SEQ of Attribute certificates
                    elsif ( $OID[9] == "6" ) { return "vOMSOrder"; } #Obsolite
                    elsif ( $OID[9] == "9" ) { return "vOMSTagContainer"; } 
                    elsif ( $OID[9] == "10" ) { return "vOMSACCertList"; } #SEQ x509certs
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  elsif ( $OID[0] == "2" ) {
    if ( $OID[1] == "5" ) {
      if ( $OID[2] == "4" ) {
        if ( $OID[3] == "0" ) { return "objectClass"; }
        elsif ( $OID[3] == "1" )  {return "aliasedEntryName";}
        elsif ( $OID[3] == "2" )  {return "knowldgeinformation";}
        elsif ( $OID[3] == "3" )  {return "commonName";}
        elsif ( $OID[3] == "4" )  {return "surname";}
        elsif ( $OID[3] == "5" )  {return "serialNumber";}
        elsif ( $OID[3] == "6" )  {return "countryName";}
        elsif ( $OID[3] == "7" )  {return "localityName";}
        elsif ( $OID[3] == "8" )  {return "stateOrProvinceName";}
        elsif ( $OID[3] == "9" )  {return "streetAddress";}
        elsif ( $OID[3] == "10" )  {return "organizationName";}
        elsif ( $OID[3] == "11" )  {return "organizationalUnitName";}
        elsif ( $OID[3] == "12" )  {return "title";}
        elsif ( $OID[3] == "13" )  {return "description";}
        elsif ( $OID[3] == "14" )  {return "searchGuide";}
        elsif ( $OID[3] == "15" )  {return "businessCategory";}
        elsif ( $OID[3] == "16" )  {return "postalAddress";}
        elsif ( $OID[3] == "17" )  {return "postalCode";}
        elsif ( $OID[3] == "18" )  {return "postOfficeBox";}
        elsif ( $OID[3] == "19" )  {return "physicalDeliveryOfficeName";}
        elsif ( $OID[3] == "20" )  {return "telephoneNumber";}
        elsif ( $OID[3] == "21" )  {return "telexNumber";}
        elsif ( $OID[3] == "22" )  {return "teletexTerminalIdentifier";}
        elsif ( $OID[3] == "23" )  {return "facsimileTelephoneNumber";}
        elsif ( $OID[3] == "24" )  {return "x121Address";}
        elsif ( $OID[3] == "25" )  {return "internationalISDNNumber";}
        elsif ( $OID[3] == "26" )  {return "registeredAddress";}
        elsif ( $OID[3] == "27" )  {return "destinationIndicator";}
        elsif ( $OID[3] == "28" )  {return "preferredDeliveryMethod";}
        elsif ( $OID[3] == "29" )  {return "presentationAddress";}
        elsif ( $OID[3] == "30" )  {return "supportedApplicationContext";}
        elsif ( $OID[3] == "31" )  {return "member";}
        elsif ( $OID[3] == "32" )  {return "owner";}
        elsif ( $OID[3] == "33" )  {return "roleOccupant";}
        elsif ( $OID[3] == "34" )  {return "seeAlso";}
        elsif ( $OID[3] == "35" )  {return "userPassword";}
        elsif ( $OID[3] == "36" )  {return "userCertificate";}
        elsif ( $OID[3] == "37" )  {return "cACertificate";}
        elsif ( $OID[3] == "38" )  {return "authorityRevocationList";}
        elsif ( $OID[3] == "39" )  {return "certificateRevocationList";}
        elsif ( $OID[3] == "40" )  {return "crossCertificatePair";}
        elsif ( $OID[3] == "41" )  {return "name";}
        elsif ( $OID[3] == "42" )  {return "givenName";}
        elsif ( $OID[3] == "43" )  {return "initials";}
        elsif ( $OID[3] == "44" )  {return "generationQualifier";}
        elsif ( $OID[3] == "45" )  {return "uniqueIdentifier";}
        elsif ( $OID[3] == "46" )  {return "dnQualifier";}
        elsif ( $OID[3] == "47" )  {return "enhancedSearchGuide";}
        elsif ( $OID[3] == "48" )  {return "protocolInformation";}
        elsif ( $OID[3] == "49" )  {return "distinguishedName";}
        elsif ( $OID[3] == "50" )  {return "uniqueMember";}
        elsif ( $OID[3] == "51" )  {return "houseIdentifier";}
        elsif ( $OID[3] == "52" )  {return "supportedAlgorithms";}
        elsif ( $OID[3] == "53" )  {return "deltaRevocationList";}
        elsif ( $OID[3] == "58" )  {return "attributeCertificate";}
        elsif ( $OID[3] == "65" )  {return "pseudonym";}
      }
      elsif ( $OID[2] == "29" ) {
        if ( $OID[3] == "1" ) { return "old Authority Key Identifier"; }
        elsif ( $OID[3] == "2" )  {return "old Primary Key Attributes";}
        elsif ( $OID[3] == "3" )  {return "Certificate Policies";}
        elsif ( $OID[3] == "4" )  {return "Primary Key Usage Restriction";}
        elsif ( $OID[3] == "14" )  {return "Subject Key Identifier";}
        elsif ( $OID[3] == "15" )  {return "Key Usage";}
        elsif ( $OID[3] == "16" )  {return "Private Key Usage Period";}
        elsif ( $OID[3] == "17" )  {return "Subject Alternative Name";}
        elsif ( $OID[3] == "18" )  {return "Issuer Alternative Name";}
        elsif ( $OID[3] == "19" )  {return "Basic Constraints";}
        elsif ( $OID[3] == "20" )  {return "CRL Number";}
        elsif ( $OID[3] == "21" )  {return "Reason code";}
        elsif ( $OID[3] == "23" )  {return "Hold Instruction Code";}
        elsif ( $OID[3] == "24" )  {return "Invalidity Date";}
        elsif ( $OID[3] == "27" )  {return "Delta CRL indicator";}
        elsif ( $OID[3] == "28" )  {return "Issuing Distribution Point";}
        elsif ( $OID[3] == "29" )  {return "Certificate Issuer";}
        elsif ( $OID[3] == "30" )  {return "Name Constraints";}
        elsif ( $OID[3] == "31" )  {return "CRL Distribution Points";}
        elsif ( $OID[3] == "32" )  {return "Certificate Policies";}
        elsif ( $OID[3] == "33" )  {return "Policy Mappings";}
        elsif ( $OID[3] == "35" )  {return "Authority Key Identifier";}
        elsif ( $OID[3] == "36" )  {return "Policy Constraints";}
        elsif ( $OID[3] == "37" )  {return "Extended key usage";}
        elsif ( $OID[3] == "46" )  {return "FreshestCRL";}
        elsif ( $OID[3] == "54" )  {return "X.509 version 3 certificate extension Inhibit Any-policy";}
        elsif ( $OID[3] == "56" )  {return "noRevAvail";}
      }
    }
    elsif ( $OID[1] == "16" ) {
      if ( $OID[2] == "840" ) {
        if ( $OID[3] == "1" ) {
          if ( $OID[4] == "113730" ) { # Netscape
            if ( $OID[5] == "1" ) { #Netscape certificate extension 
	      if ( $OID[6] == "1" ) { return "Netscape certificate type";}
	      elsif ( $OID[6] == "2" ) { return "Base URL";}
	      elsif ( $OID[6] == "3" ) { return "Revocation URL";}
	      elsif ( $OID[6] == "4" ) { return "CA Revocation URL";}
	      elsif ( $OID[6] == "7" ) { return "Renewal URL";}
	      elsif ( $OID[6] == "8" ) { return "Netscape CA policy URL";}
	      elsif ( $OID[6] == "12" ) { return "SSL server name";}
	      elsif ( $OID[6] == "13" ) { return "Netscape certificate comment";}
            }
            elsif ( $OID[5] == "2" ) { return "Netscape Data Type";}
            elsif ( $OID[5] == "3" ) { #Netscape LDAP 
	      if ( $OID[6] == "1" ) { #Netscape LDAP attribute types
                if ( $OID[7] == "5" ) { return "changeNumber";}
                elsif ( $OID[7] == "7" ) { return "changeType";}
                elsif ( $OID[7] == "8" ) { return "changes";}
                elsif ( $OID[7] == "12" ) { return "mailAccessDomain";}
                elsif ( $OID[7] == "14" ) { return "mailAccessDomain";}
                elsif ( $OID[7] == "15" ) { return "mailAutoReplyText";}
                elsif ( $OID[7] == "17" ) { return "mailForwardingAddress";}
                elsif ( $OID[7] == "35" ) { return "changeLog";}
                elsif ( $OID[7] == "36" ) { return "nsLicensedFor";}
                elsif ( $OID[7] == "40" ) { return "userSMIMECertificate";}
                elsif ( $OID[7] == "241" ) { return "DisplayName attribute";}
                elsif ( $OID[7] == "692" ) { return "inetUserStatus";}
              }
	      elsif ( $OID[6] == "2" ) { return"Netscape LDAP object classes";}
              elsif ( $OID[6] == "3" ) { return"Netscape LDAP matching rules";}
	      elsif ( $OID[6] == "4" ) { #Netscape LDAPv3 controls
                if ( $OID[7] == "2" ) { return "Manage DSA IT LDAPv3 control";}
                elsif ( $OID[7] == "3" ) { return "Persistent Search LDAPv3 control";}
                elsif ( $OID[7] == "4" ) { return "Netscape Password Expired LDAPv3 control";}
                elsif ( $OID[7] == "5" ) { return "Netscape Password Expiring LDAPv3 control";}
                elsif ( $OID[7] == "6" ) { return "Netscape NT Synchronization Client LDAPv3 control";}
                elsif ( $OID[7] == "7" ) { return "Entry Change Notification LDAPv3 control";}
                elsif ( $OID[7] == "8" ) { return "Transaction ID Request Control";}
                elsif ( $OID[7] == "9" ) { return "VLV Request LDAPv3 control";}
                elsif ( $OID[7] == "10" ) { return "VLV Response LDAPv3 control";}
                elsif ( $OID[7] == "11" ) { return "Transaction ID Response Control";}
                elsif ( $OID[7] == "12" ) { return "Proxied Authorization (version 1) control";}
                elsif ( $OID[7] == "13" ) { return "iPlanet Directory Server Replication Update Information Control";}
                elsif ( $OID[7] == "14" ) { return "iPlanet Directory Server \"search on specific backend\" control";}
                elsif ( $OID[7] == "15" ) { return "Authentication Response Control";}
                elsif ( $OID[7] == "16" ) { return "Real Attributes Only Request Control";}
                elsif ( $OID[7] == "17" ) { return "Real Attributes Only Request Control";}
                elsif ( $OID[7] == "18" ) { return "Proxied Authorization (version 2) Control";}
                elsif ( $OID[7] == "999" ) { return "iPlanet Replication Modrdn Extra Mods Control";}
              }
	      elsif ( $OID[6] == "5" ) { #Netscape LDAPv3 extended operations
                if ( $OID[7] == "1" ) { return "Transaction Request Extended Operation";}
                elsif ( $OID[7] == "2" ) { return "Transaction Response Extended Operation";}
                elsif ( $OID[7] == "3" ) { return "Transaction Response Extended Operation";}
                elsif ( $OID[7] == "4" ) { return "iPlanet Replication Response Extended Operation";}
                elsif ( $OID[7] == "5" ) { return "iPlanet End Replication Request Extended Operation";}
                elsif ( $OID[7] == "6" ) { return "iPlanet Replication Entry Request Extended Operation";}
                elsif ( $OID[7] == "7" ) { return "iPlanet Bulk Import Start Extended Operation";}
                elsif ( $OID[7] == "8" ) { return "iPlanet Bulk Import Finished Extended Operation";}
                elsif ( $OID[7] == "9" ) { return "iPlanet Digest Authentication Calculation Extended Operation";}
              }
	      elsif ( $OID[6] == "6" ) { #Netscape miscellaneous OIDs arc
                if ( $OID[7] == "1" ) { return "ISO/ITU-T jointly assigned OIDs";}
                elsif ( $OID[7] == "2" ) { return "iPlanet Total Update Replication Protocol Identifier";}
              }
            }
            elsif ( $OID[5] == "4" ) { #Netscape Policy 
	      if ( $OID[6] == "1" ) { return "Netscape Server Gated Crypto (nsSGC)";}
	    }
            elsif ( $OID[5] == "5" ) { return "Netscape Certificate Server"; }
            elsif ( $OID[5] == "6" ) { return "Netscape Algorithm "; }
            elsif ( $OID[5] == "7" ) { #Netscape Name Component 
	      if ( $OID[6] == "1" ) { return "Netscape Nickname";}
	      elsif ( $OID[6] == "2" ) { return "AOL Screenname";}
            }
	  }
        }
      }
    }
  }
  return $OID;
}

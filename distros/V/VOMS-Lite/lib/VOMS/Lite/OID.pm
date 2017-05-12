package VOMS::Lite::OID;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

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

1;

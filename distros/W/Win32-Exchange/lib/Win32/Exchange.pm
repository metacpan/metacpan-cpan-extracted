# Win32::Exchange
# Freely Distribute the code without modification.
#
# Creates and Modifies Exchange 5.5 and 2K Mailboxes
# (eventually it will do more, but for now, that's the scope)
#
# This is the culmination of 3 years of work in building Exchange Mailboxes, but now as a module.
# It uses Win32::OLE exclusively (and technically is just a wrapper for the underlying OLE calls).
# 
# This build is tested and works with ActivePerl build 633 (and Win32::OLE .1502)
# There is not currently a package that is tested on older (non-multi-threading versions of
# ActivePerl)... My guess is that it may work except for the SetPerms and SetOwner subs but,
# remember..  That's a guess.
# 
# Sorry... :(
#

package Win32::Exchange;
use strict;
use vars qw ($VERSION $Version $DEBUG);

use Win32::Exchange::Mailbox;
use Win32::Exchange::SMTP::Security;
use Win32::Exchange::Const;

use Win32::OLE qw (in);
Win32::OLE->Initialize(Win32::OLE::COINIT_OLEINITIALIZE);
Win32::OLE->Option('_Unique' => 1);

#@ISA = qw(Win32::OLE);

my $Version;
my $VERSION = $Version = "0.042";
my $DEBUG = 2;

sub new {
  my $server;
  my $ver = "";
  if (scalar(@_) == 1) {
    if ($_[0] eq "5.5" || $_[0] eq "6.0") {
      $ver = $_[0];
    } else {
      $server = $_[0];
    }
  } elsif (scalar(@_) == 2) {
    if ($_[0] eq "Win32::Exchange") {
      if ($_[1] eq "5.5" || $_[1] eq "6.0") {
        $ver = $_[1];
      } else {
        $server = $_[1];
      }

    } else {
      _ReportArgError("new",scalar(@_));
    }
  } else {
    _ReportArgError("new",scalar(@_));
    return 0;
  }

  my $class = "Win32::Exchange";
  my $ldap_provider = {};

  if ($ver eq "") {
    my %version;
    if (!Win32::Exchange::GetVersion($server,\%version)) {
      return undef;
    } else {
      $ver = $version{'ver'}
    }
  }
  if ($ver eq "5.5") {
    #Exchange 5.5
    if ($ldap_provider = Win32::OLE->new('ADsNamespaces')) {
      return bless $ldap_provider,$class;
    } else {
      _DebugComment("Failed creating ADsNamespaces object\n",1);
      return undef;
    }
  } elsif ($ver eq "6.0") {
    #Exchange 2000
    if ($ldap_provider = Win32::OLE->new('CDO.Person')) {
      return bless $ldap_provider,$class;
    } else {
      _DebugComment("Failed creating CDO.Person object\n",1);
      return undef;
    }
  } else {
    _DebugComment("Unable to verify version information for version: $ver\n",1);
    return undef;
  }
}

sub DESTROY {
  my $object = shift;
  bless $object,"Win32::OLE";
  return undef;
}

sub GetLDAPPath {
  my $ldap_provider;
  my $server_name;
  my $ldap_path;
  my $return_point;
  if (scalar(@_) == 3) {
    $server_name = $_[0];
    $ldap_path = "LDAP://$server_name";
    $return_point = 1;
  } elsif (scalar(@_) == 4) {
    $ldap_provider = $_[0];
    $server_name = $_[1];
    $return_point = 2;
  } else {
    _ReportArgError("GetLDAPPath",scalar(@_));
    return 0;
  }
  my $result;
  if (_AdodbExtendedSearch($server_name,"LDAP://$server_name","(&(objectClass=Computer)(rdn=$server_name))","rdn,distinguishedName",$result)) {
    _DebugComment("result = $result\n",2);
    if ($result =~ /cn=.*,cn=Servers,cn=Configuration,ou=(.*),o=(.*)/) {
      my $returned_ou = $1;
      my $returned_o = $2;
      $_[$return_point]=$returned_o;
      $_[($return_point+1)]=$returned_ou;
      _DebugComment("ou=$returned_ou\no=$returned_o\n",2);
      return 1;
    } else {
      _DebugComment("result = $result\n",2);
      _DebugComment("result from ADODB search failed to produce an acceptable match\n",1);
      return 0;
    }
  } else {
    _DebugComment("ADODB search failed\n",1);
    return 0;  
  }
}

sub GetVersion {
  my $server_name;
  my $error_num;
  my $error_name;
  if (scalar(@_) == 2) {
    $server_name = $_[0];
  } elsif (scalar(@_) == 3) {
    if ($_[0] eq "Win32::Exchange") {
      $server_name = $_[1];
    } else {
      _ReportArgError("GetVersion",scalar(@_));
      return 0;
    }
  } else {
    _ReportArgError("GetVersion",scalar(@_));
    return 0;
  }
  my $original_ole_warn_value = $Win32::OLE::Warn;
  $Win32::OLE::Warn = 0;
  my $serial_val;
  my $serial_version_check_obj = Win32::OLE->new('CDOEXM.ExchangeServer'); #substantiates the possible existance of e2k
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    if ($error_num eq "0x80040154" ||
        $error_num eq "0x800401f3") {
      #0x80040154 Class not registered
      #0x800401f3 Invalid class string
      _DebugComment("The Exchange 2000 client tools don't look to be installed on this machine\n",2);
      if (!_E55VersionInfo($server_name,$serial_val)) {
        _DebugComment("Error getting version information from Exchange 5.5\n",1);
        $Win32::OLE::Warn = $original_ole_warn_value;
        return 0;
      }
    } else {
      _DebugComment("error: $error_num - $error_name on $server_name encountered while trying to perform GetVersion\n",1);
      $Win32::OLE::Warn = $original_ole_warn_value;
      return 0;
    }
  } else {
    _DebugComment("found e2k tools, so we'll look and see what version of Exchange you have.\n",3);
    if (!_E2kVersionInfo($server_name,$serial_val)) {
      _DebugComment("Error getting version information from Exchange 2000 tools, let's try the Exch 5.5 way\n",3);
      if (!_E55VersionInfo($server_name,$serial_val)) {
        _DebugComment("Error getting version information trying the Exch 5.5 way\n",3);
        _DebugComment("Error getting version information\n",1);
        $Win32::OLE::Warn = $original_ole_warn_value;
        return 0;
      }
    }
  }
  $Win32::OLE::Warn = $original_ole_warn_value; 

  if ($serial_val =~ /Version (.*) \(Build (.{6})?(.*)\)/i) {
    my %return_struct;
    $return_struct{ver}= $1;
    $return_struct{build}= $2;
    $return_struct{sp}= $3;
    if ($return_struct{sp} =~ /service pack (.)/i) {
      $return_struct{sp} = $1;
    } else {
      $return_struct{sp}= "0";
    }
    if ($return_struct{sp} < 2 && $return_struct{ver} eq "6.0") {
      _DebugComment("It's possible that some of the E2K permissions functions will fail due to an incompatible E2K Service Pack level (please see the HTML docs for details)\n",2)
    }
    if (scalar(@_) == 2) {
      %{$_[1]} = %return_struct;
    } else {
      %{$_[2]} = %return_struct;
    }
    return 1;
  } else {
    return 0;
  }
}
 
sub _E55VersionInfo {
  my $server_name;
  my $error_num;
  my $error_name;
  if (scalar(@_) == 2) {
    $server_name = uc($_[0]);
  } else {
    _ReportArgError("_E55VersionInfo",scalar(@_));
    return 0;
  }
  my $serial_val;
  my $provider;
  my $org;
  my $ou;
  $provider = Win32::Exchange->new("5.5");
  if (!$provider) {
    _DebugComment("new provider create in GetVersion (E55) failed\n",1);
    return 0;
  }
  if ($provider->GetLDAPPath($server_name,$org,$ou)) {
    _DebugComment("returned -> o=$org,ou=$ou\n",3);
  } else {
    _DebugComment("Error Returning from GetLDAPPath in GetVersion (E55)\n",1);
    return 0;
  }
  bless $provider,"Win32::OLE";
  my $exch_server_obj = $provider->GetObject("","LDAP://$server_name/cn=$server_name,cn=Servers,cn=Configuration,ou=$ou,o=$org");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Failed getting the server object in Server container for version info (E55): $error_num,$error_name\n",1);
    return 0;
  }
  $exch_server_obj->GetInfoEx(['serialNumber'],0);
  $serial_val = $exch_server_obj->{"serialNumber"};
  if ($serial_val =~ /Version (.*) \(Build (.*): Service Pack (.*)\)/i) {
    $_[1] = $serial_val;
    return 1;
  } else {
    _DebugComment("GetVersion failed to produce acceptable results (E55)\n",1);
    return 0;
  }
}
 
sub _E2kVersionInfo {
  my $error_num;
  my $error_name;
  if (scalar(@_) != 2) {
    _ReportArgError("_E2kVersionInfo",scalar(@_));
  }
  my $server_name = $_[0];
  my $exchange_server = Win32::OLE->new("CDOEXM.ExchangeServer");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Failed creating object for version information (E2K) on $server_name -> $error_num ($error_name)\n",1);
      return 0;
  }
  $exchange_server->DataSource->Open($server_name);
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    if ($error_num eq "0x80072032") {
      #This error might be there if the server is on another domain...  not sure..  I'll need to research more.
      #It happenned on an E5.5 server anyway so I didn't need the E2K version strucure.
      _DebugComment("Failed opening object for version information (E2K) on $server_name -> $error_num ($error_name)\n",2);
    } else {
      _DebugComment("Failed opening object for version information (E2K) on $server_name -> $error_num ($error_name)\n",1);
    }
    return 0;
  }
 
  #example output:
  #Version 5.5 (Build 2653.23: Service Pack 4)
  #Version 6.0 (Build 6249.4: Service Pack 3)
  #Version 6.5 (Build 6944.4)
 
  if ($exchange_server->{ExchangeVersion} ne "") {
    if (ref($_[1]) eq "HASH") {
      my %verhash;
      $verhash{'ver'} = $exchange_server->{ExchangeVersion};
      $verhash{'dc'} = $exchange_server->{DirectoryServer};
      %{$_[1]} = %verhash;
    } else {
      $_[1] = $exchange_server->{ExchangeVersion};
    }
    return 1;
  } else {
    _DebugComment("Failed failed to produce valid version info for $server_name\n",1);
    return 0;
  }
}

sub _AdodbExtendedSearch {
  my $search_string;
  my $path;
  my $filter;
  my $columns;
  my $error_num;
  my $error_name;
  my $fuzzy;
  my $return_point;
  if (scalar(@_) > 4) {
    $search_string = $_[0];
    $path = $_[1];
    $filter = $_[2];
    $columns = $_[3];
    if (scalar(@_) == 5) {
      $return_point = 4;
    } elsif (scalar(@_) == 6) {
      $fuzzy = $_[4];
      $return_point = 5;
    }
  } else {
    _ReportArgError("_AdodbExtendedSearch (".scalar(@_));
    return 0;
  }
  my @cols = split (/,/,$columns);
  if (scalar(@cols) != 2) {
    _DebugComment("Only 2 columns can be sent to _AdodbExtendedSearch (total recieved = ".scalar(@cols).")\n",1);
  }
  my $option;
  if ($path =~ /^LDAP:\/\/RootDSE\/(.*)/i) {
    $option = $1;
    my $RootDSE = Win32::OLE->GetObject("LDAP://RootDSE");
    if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Failed creating object for _AdodbExtendedSearch on $search_string -> $error_num ($error_name)\n",1);
      return 0;
    }
    my $actual_ldap_path = $RootDSE->Get($option);
    if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Failed creating object for _AdodbExtendedSearch on $search_string -> $error_num ($error_name)\n",1);
      return 0;
    }
    $path = "LDAP://".$actual_ldap_path;
  }
  my $string = "<$path>;$filter;$columns;subtree";
  my $Com = Win32::OLE->new("ADODB.Command");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("path=$path\nfilter=$filter\ncolumns=$columns\n",2);
      _DebugComment("Failed creating ADODB.Command object for _AdodbExtendedSearch on $search_string -> $error_num ($error_name)\n",1);
      return 0;
  }
  my $Conn = Win32::OLE->new("ADODB.Connection");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("path=$path\nfilter=$filter\ncolumns=$columns\n",2);
      _DebugComment("Failed creating ADODB.Connection object for version information (E55) on $search_string -> $error_num ($error_name)\n",1);
      return 0;
  }
  $Conn->{'Provider'} = "ADsDSOObject";
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("path=$path\nfilter=$filter\ncolumns=$columns\n",2);
      _DebugComment("Failed executing ADODB.Command for version information (E55) on $search_string -> $error_num ($error_name)\n",1);
      return 0;
  }
  $Conn->{Open} = "Win32-Exchange a perl module";
  $Com->{ActiveConnection} = $Conn;
  $Com->{CommandText} = $string;
  $Com->{Properties}->{"Page Size"} = 99; #One less than the default of 100 for Exchange so we don't return an empty resultset if more than 100 results are found
  my $RS = $Com->Execute();
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("path=$path\nfilter=$filter\ncolumns=$columns\n",2);
      _DebugComment("Failed executing ADODB.Command for version information (E55) on $search_string -> $error_num ($error_name)\n",1);
      return 0;
  }
  my $not_found = 1;
  my $search_val = "";
  while ($search_val eq "") {
    if ($fuzzy != 0) {
      _DebugComment("fuzzy=$fuzzy\n",3);
      if ($RS->Fields($cols[($fuzzy - 1)])->value =~ /$search_string/i) {
        if (ref($RS->Fields($cols[($fuzzy - 1)])->value) eq "ARRAY") {
          _DebugComment("array - ".@{$RS->Fields($cols[1])->value}[0]."\n",3);
          $search_val = @{$RS->Fields($cols[1])->value}[0]; 
          @{$_[$return_point]} = @{$search_val};
          return 1;
        } else {
          _DebugComment("string - ".$RS->Fields($cols[1])->value."\n",3);
          $search_val = $RS->Fields($cols[1])->value; 
          $_[$return_point] = $search_val;
          return 1;
        }
      }
    } else {
      _DebugComment("found: $cols[0] -- ".($RS->Fields($cols[0])->value)[0]."\n  $cols[0] -- ".($RS->Fields($cols[1])->value)[0]."\n  -->$search_string\n",4);
      if (lc($search_string) eq lc($RS->Fields($cols[0])->value)) {
        if (ref($RS->Fields($cols[1])->value) eq "ARRAY") {
          _DebugComment("found (not fuzzy) (ARRAY)".$RS->Fields($cols[1])->value."\n",3);
          $search_val = @{$RS->Fields($cols[1])->value}[0]; 
          $_[$return_point] = $search_val;
          return 1;
        } else {
          _DebugComment("found (not fuzzy) (string)".$RS->Fields($cols[1])->value."\n",3);
          $search_val = $RS->Fields($cols[1])->value; 
          $_[$return_point] = $search_val;
          return 1;
        }
      }
    }
    _DebugComment($RS->Fields($cols[0])->value." - ".$RS->Fields($cols[1])->value."\n",3);
    if ($RS->EOF) {
      $search_val = "-1";
    }
    $RS->MoveNext;
  }
  if ($search_val eq "-1") {
    _DebugComment("Unable to match valid data for your search on $search_string\n",1);
    return 0;
  }
}

sub LocateMailboxStore {
  my $store_server;
  my $storage_group;
  my $mb_store;
  my $count = "no";
  if ($_[0] eq "Win32::Exchange") {
    if (scalar(@_) > 4) {
      if (scalar(@_) == 5) {
      } elsif (scalar(@_) == 6) {
        if (ref($_[5]) eq "ARRAY") {
          $count = "yes";
        } else {
          _DebugComment("the fifth argument passed to LocateMailboxStore must be an array (but is optional).\n",1);
          return 0;  
        }
      } else {
        _ReportArgError("LocateMailboxStore [E2K] (".scalar(@_));
       return 0;  
       }
    } else {
      _ReportArgError("LocateMailboxStore [E2K] (".scalar(@_));
      return 0;  
    }
  } else {
    if (scalar(@_) > 3) {
      if (scalar(@_) == 4) {
      } elsif (scalar(@_) == 5) {
        if (ref($_[4]) eq "ARRAY") {
          $count = "yes";
        } else {
          _DebugComment("the fifth argument passed to LocateMailboxStore must be an array (but is optional).\n",1);
          return 0;  
        }
      } else {
        _ReportArgError("LocateMailboxStore [E2K] (".scalar(@_));
       return 0;  
       }
    } else {
      _ReportArgError("LocateMailboxStore [E2K] (".scalar(@_));
      return 0;  
    }
  }
  
  my $ldap_path;
  my $mb_count;
  my %storage_groups;
  $store_server = $_[0];
  $storage_group = $_[1];
  $mb_store = $_[2];
  if (_EnumStorageGroups($store_server,\%storage_groups)) {
    if ($count eq "yes") {
      foreach my $sg (keys %storage_groups) {
        $mb_count += scalar(keys %{$storage_groups{$sg}}); 
      }
      push (@{$_[4]},scalar(keys %storage_groups)); 
      push (@{$_[4]},$mb_count); 
    }
    if (_TraverseStorageGroups(\%storage_groups,$store_server,$storage_group,$mb_store,$ldap_path)) {
      $_[3] = $ldap_path;
      return 1;
    } else {
      _DebugComment("Unable to locate valid mailbox store for mailbox creation.\n",1);
      return 0;          
    }
  } else {
    _DebugComment("Unable to locate valid storage group for mailbox creation.\n",1);
    return 0;          
  }
}

sub _EnumStorageGroups {
  my $server_name;
  my $error_num;
  my $error_name;
  if (scalar(@_) == 2) {
    $server_name = $_[0];
  } else {
    _ReportArgError("_EnumStorageGroups (".scalar(@_));
    return 0;
  }
  my $exchange_server = Win32::OLE->new("CDOEXM.ExchangeServer");

  $exchange_server->DataSource->Open($server_name);
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Failed opening ADODB ExchangeServer object for Storage Group enumeration on $server_name -> $error_num ($error_name)\n",1);
    return 0;
  }

  my @storegroups = Win32::OLE::in($exchange_server->StorageGroups);
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Failed enumerating Storage Groups on $server_name -> $error_num ($error_name)\n",1);
    return 0;
  }
  my %storage_groups;
  my $stor_group_obj = Win32::OLE->new("CDOEXM.StorageGroup");
  my $mbx_store_obj = Win32::OLE->new("CDOEXM.MailboxStoreDB");
  foreach my $storegroup (@storegroups) {
    $stor_group_obj->DataSource->Open($storegroup);
    _DebugComment("Stor Name = ".$stor_group_obj->{Name}."\n",3);
    foreach my $mbx_store (Win32::OLE::in($stor_group_obj->{MailboxStoreDBs})) {
      $mbx_store_obj->DataSource->Open($mbx_store);
      _DebugComment("  Mailbox Store = $mbx_store_obj->{Name}\n",3);
      $storage_groups{$stor_group_obj->{Name}}{$mbx_store_obj->{Name}}=$mbx_store;
    }
  }

  %{$_[1]} = %storage_groups;
  return 1;
}

sub _TraverseStorageGroups {
  if (scalar(@_) != 5) {
    _ReportArgError("_TraverseStorageGroups [E2K] (".scalar(@_));
    return 0;
  }
  if (ref($_[0]) ne "HASH") {
    _DebugComment("Storage group object is not a hash\n",1);
    return 0;
  }
  my %storage_groups = %{$_[0]};
  my $info_store_server = $_[1];
  my $storage_group = $_[2];
  my $mb_store = $_[3];
  my $ldap_path;
  if (scalar(keys %storage_groups) == 0) {
      _DebugComment("No Storage Groups were found\n",1);
      return 0;
  }
  my $sg;
  my $mb;
  foreach $sg (keys %storage_groups) {
    if (scalar(keys %storage_groups) == 1) {
      foreach $mb (keys %{$storage_groups{$sg}}) {
        if (scalar(keys %{$storage_groups{$sg}}) == 1 || $mb eq $mb_store && $mb_store ne "") {
          $_[4] = "LDAP://".$storage_groups{$sg}{$mb}; 
          return 1;
        } else {
          next;
        }
      }
      _DebugComment("Error locating proper storage group and mailbox db for mailbox creation (1SG)\n",1);
      return 0;
    } elsif ($sg eq $storage_group && $storage_group ne "") {
      foreach $mb (keys %{$storage_groups{$sg}}) {
        if (scalar(keys %{$storage_groups{$sg}}) == 1 || $mb eq $mb_store && $mb_store ne "") {
          $_[4] = "LDAP://".$storage_groups{$sg}{$mb}; 
          return 1;
        } else {
          next;
        }
      }
      _DebugComment("Error locating proper storage group and mailbox db for mailbox creation (2+SG)\n",1);
      return 0;
    }
  }
}

sub GetDistinguishedName {
  my $server_name;
  my $filter;
  my $filter_name;
  my $result;
  if (scalar(@_) == 3) {
    $server_name = $_[0];
    $filter = $_[1];  
  } else {
    _ReportArgError("GetDistinguishedName",scalar(@_));
  }
  my %filters;
  
  %filters = ('Home-MDB' => "(objectClass=MHS-Message-Store)",
              'Home-MTA' => "(objectClass=MTA)",
           );
  if ($filters{$filter} ne "") {
    $filter_name=$filters{$filter};
  } else {
    $filter_name = $filter;#If someone wants to actually send a correctly formatted objectClass  
  }
  _DebugComment("filter=$filter_name\n",2);
  _DebugComment("search=$server_name\n",2);
  if (_AdodbExtendedSearch($server_name,"LDAP://$server_name",$filter_name,"cn,distinguishedName",2,$result)) {
    $_[2] = $result;
    return 1;
  } else {
    return 0;
  }
}

sub _StripBackslashes {
  my $nt_pdc = $_[0];
  if ($nt_pdc =~ /^\\\\(.*)/) {
    $_[1] = $1;
    return 1;
  } else {
    $_[1] = $nt_pdc;
    return 1;
  }
}

sub FindCloseDC {
  # Requires Exchange 2000 SP2 or greater
  # Author: Andy Webb / Simpler-Webb
  # Version: 20020903.01
  # ------------------------------------------------------------------------
  #               Copyright (C) 2002 Simpler-Webb, Inc.
  # ------------------------------------------------------------------------
  # Terms of use: This script is provided AS IS without warranty of any kind,
  # either expressed or implied.
  #
  # This code may be modified from the original form for personal use without 
  # the permission of the original authors. 
  #
  #With modifications by Steven Manross for functionality requirements of this module

  my $host = $_[0];
  my $error_name;
  my $error_num;
  my $WMI = Win32::OLE->new('WbemScripting.SWbemLocator');
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error creating new WMI object (FindCloseDC)\n",1);
    return 0;
  } else {
    my $Service = $WMI->ConnectServer($host,"root\\microsoftexchangev2");
    if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Error connecting to the exchange WMI root node (FindCloseDC)\n",1);
      return 0;
    }
    my $listDCs = $Service->InstancesOf("Exchange_DSAccessDC");
    if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Error using InstancesOf in WMI object (FindCloseDC)\n",2);
      return 0;
    }
    my $dc = "";
    my $isup=0;
    foreach my $item (in($listDCs)) {
      if ($item->{'Type'} == 0) {
        #Configuration Domain Controller
        if ($item->{'DirectoryType'} == 0) {
          #Active Directory
          if ($item->{'IsUp'} == $item->{'IsInSync'} &&
              $item->{'IsInSync'} == $item->{'IsFast'} &&
              $item->{'IsFast'} == 1) {
            $dc = $item->{'Name'};
            _DebugComment("Found $dc, and it is: UP, FAST, and INSYNC\n",3);
            last;
          }
          if ($item->{'IsUp'} == $item->{'IsInSync'} &&
              $item->{'IsInSync'} == 1 &&
              ($dc eq "" || $isup == 1)) {
            $dc = $item->{'Name'};
            $isup=2;
            _DebugComment("Found $dc, and it is: UP, and INSYNC\n",4);
            #don't return its possible to still find something better 
          }
          if ($item->{'IsUp'} == 1 && $dc eq "") {
            $isup = 1;
            $dc = $item->{'Name'};
            _DebugComment("Found $dc, and it is: UP\n",4);
            #don't return its possible to still find something better 
          }
        }
      }
    }
    if ($dc ne "") {
      if (scalar(@_) == 2) {
        $_[1] = $dc;
        return 1;
      } else {
        return $dc;
      }
    } else {
      _DebugComment("WMI was unable to find a DC that was UP, sorry.\n",1);
      return 0;
    }
  }
}

sub IsMixedModeExchangeOrg {
  my $error_num;
  my $error_name;
  my $ldap_provider = Win32::OLE->new("ADsNamespaces");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error creating RootDSE object for Native/Mixed Mode determination\n",1);
    return 0;
  }
  my $rootdse = $ldap_provider->GetObject("","LDAP://RootDSE");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error creating RootDSE object for Native/Mixed Mode determination\n",1);
    return 0;
  }
  my $result;
  my $cnc = $rootdse->Get("configurationNamingContext");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error getting ConfigurationNamingContext property for Native/Mixed Mode determination\n",1);
    return 0;
  }
 
  if (!Win32::Exchange::_AdodbExtendedSearch("Microsoft Exchange","LDAP://$cnc","(objectCategory=CN=ms-Exch-Organization-Container,CN=Schema,CN=Configuration,DC=manross,DC=net)","cn,DistinguishedName",2,$result)) {
    _DebugComment("Error performing ADODB search for Native/Mixed Mode determination\n",1);
    return 0;
  }
  my $org = $ldap_provider->GetObject("","LDAP://$result");
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error performing GetObject for Native/Mixed Mode determination\n",1);
    return 0;
  }
  $_[0] = $org->{"msExchMixedMode"};
  return 1;
}

sub ErrorCheck {
  my $last_error_expected = $_[0];
  my $error_num;
  my $error_name;
  my $last_ole_error = Win32::OLE->LastError();
  $error_num = sprintf "0x%lx",Win32::OLE->LastError();
  if ($error_num eq "0x0") {
    $error_num = "0x00000000"
  }
  my @error_list = split(/\"/,$last_ole_error,3);
  $error_name = $error_list[1];
  if (lc($error_num) ne lc($last_error_expected)) {
    $_[1] = $error_num;
    $_[2] = $error_name;
    return 0;
  } else {
    return 1;
  }
}

sub _ReportArgError {
  _DebugComment("incorrect number of options passed to $_[0] ($_[1])\n",0);
  return 1;
}

sub _DebugComment {
  if (scalar(@_) == 2) {
    print "$_[0]" if ($DEBUG > ($_[1] - 1));
  } elsif (scalar(@_) == 3) {
    #usually called from another routine (eg.. Win32::Exchange::SMTP::Security or an external script)
    print "$_[0]" if ($_[2] > ($_[1] - 1));
  } else {
    print "DebugComment Error!!!!\n";
  }
  return 1;
}

1;
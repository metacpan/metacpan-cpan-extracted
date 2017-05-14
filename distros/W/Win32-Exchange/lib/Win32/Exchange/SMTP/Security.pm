#requires Exchange 2000 post-SP3 hotfix as described in article:
#      http://support.microsoft.com/default.aspx?scid=kb;en-us;810913
#  on the client you want to retrieve the info from
#  as well as the Exchange 2000 client tools

package Win32::Exchange::SMTP::Security;

use strict;
use vars qw ($VERSION $Version $DEBUG);

use Win32::OLE;
Win32::OLE->Initialize(Win32::OLE::COINIT_OLEINITIALIZE);
Win32::OLE->Option('_Unique' => 1);

my $Version;
my $VERSION = $Version = "0.003";
my $DEBUG = 1;
my $LAST_LOADED_LIST;
my $LIST_LOADED;

sub new {
  my $error_num;
  my $error_name;
  my $IpSec = Win32::OLE->new("ExIpSec.ExIpSecurity");
  $LIST_LOADED = 0;
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error creating new object (did you install client tools, SP3 and the hotfix?)\n".
          "  as discussed here:\n".
          '    http://support.microsoft.com/default.aspx?scid=kb;en-us;810913'."\n".
          "error: $error_num\n",1
        );
   return 0;
  } else {
    return bless $IpSec ,"Win32::Exchange::SMTP::Security";
  }
}

sub DESTROY {
  my $object = shift;
  bless $object,"Win32::OLE";
  return undef;
}

sub Bind {
  my $error_num;
  my $error_name;
  my $IpSec;
  my $exch_server;
  my $dom_controller;
  my $instance;
  my $rtn;
  if (scalar(@_) > 2) {
    $IpSec = $_[0];
    $exch_server = $_[1];
    $instance = $_[2];#usually 1
    if (scalar(@_) == 3) {
      if (!Win32::Exchange::FindCloseDC($exch_server,$dom_controller)) {
        _DebugComment("FindCloseDC failed to produce an acceptable DC\nerror: $error_num\n",1);
        return 0;
      }
    } else {
      if (scalar(@_) == 4) {
        $dom_controller = $_[3];
      } else {
        Win32::Exchange::_ReportArgError("Bind (E2K)",scalar(@_));
        return 0;
      }
    }
  } else {
    Win32::Exchange::_ReportArgError("Bind (E2K)",scalar(@_));
    return 0;
  }
  $LIST_LOADED = 0;
  bless $IpSec, "Win32::OLE";
  $IpSec->BindToSmtpVsi($exch_server, $instance, $dom_controller);
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error binding to new object\nerror: $error_num\n",1);
    bless $IpSec ,"Win32::Exchange::SMTP::Security";
    $IpSec->Release();
    $rtn = 0;
  } else {
    bless $IpSec ,"Win32::Exchange::SMTP::Security";
    $rtn = 1;
  }
  return $rtn;
}

sub GetIpSecurityList {
  my $error_num;
  my $error_name;
  my $IpSec;
  my $rtn;
  my %data;
  if (scalar(@_) > 0) {
    $IpSec = $_[0];
    if (scalar(@_) == 2) {
      if (ref($_[1]) ne "HASH") {
        Win32::Exchange::_ReportArgError("GetIpSecurityList (E2K ) - parameter 2 is not a HASH reference",scalar(@_));
        return 0;
      }
    } elsif (scalar(@_) == 1) {
    } else {
      Win32::Exchange::_ReportArgError("GetIpSecurityList (E2K)",scalar(@_));
      return 0;
    }
  } else {
    Win32::Exchange::_ReportArgError("GetIpSecurityList (E2K)",scalar(@_));
    return 0;
  }

  bless $IpSec, "Win32::OLE";
  if (($LIST_LOADED == 0) || ($LIST_LOADED == 1 && $LAST_LOADED_LIST eq "GetIpRelayList")) {
    $LAST_LOADED_LIST="GetIpSecurityList";
    $LIST_LOADED = 1;
    $IpSec->GetIpSecurityList();
    if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Error collecting IpSecurity information\nerror: $error_num\n",1);
      bless $IpSec ,"Win32::Exchange::SMTP::Security";
      $IpSec->Release();
      return 0;
    }
  } else {
    _DebugComment("Bypassing Security List Load (2nd time)\nerror: $error_num\n",4);
  }
  bless $IpSec ,"Win32::Exchange::SMTP::Security";
  if ($IpSec->RetrieveList(\%data)) {
    $rtn = 1;
  } else {

    _DebugComment("Error collecting list information.\n".
                                   "Although you're successfully connected to the SecurityList\n".
                                   "error: $error_num\n",1);
    $rtn = 0;
  }
  if (scalar(@_) == 2) {
    %{$_[1]} = %data;
    return $rtn;
  } else {
    return %data;
  }
}

sub GetIpRelayList {
  my $error_num;
  my $error_name;
  my $IpSec;
  my $rtn;
  my %data;
  if (scalar(@_) > 0) {
    $IpSec = $_[0];
    if (scalar(@_) == 2) {
      if (ref($_[1]) ne "HASH") {
        Win32::Exchange::_ReportArgError("GetIpRelayList (E2K ) - parameter 2 is not a HASH reference",scalar(@_));
        return 0;
      }
    } elsif (scalar(@_) == 1) {
    } else {
      Win32::Exchange::_ReportArgError("GetIpRelayList (E2K)",scalar(@_));
      return 0;
    }
  } else {
    Win32::Exchange::_ReportArgError("GetIpRelayList (E2K)",scalar(@_));
    return 0;
  }

  bless $IpSec, "Win32::OLE";
  if (($LIST_LOADED == 0) || ($LIST_LOADED == 1 && $LAST_LOADED_LIST eq "GetIpSecurityList")) {
    $LAST_LOADED_LIST="GetIpRelayList";
    $LIST_LOADED = 1;
    $IpSec->GetRelayIpList();
    if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Error collecting IPRelay information\nerror: $error_num\n",1);
      bless $IpSec ,"Win32::Exchange::SMTP::Security";
      $IpSec->Release();
      return 0;
    }
  } else {
    _DebugComment("Bypassing Relay List Load (2nd time)\nerror: $error_num\n",4);
  }
  bless $IpSec ,"Win32::Exchange::SMTP::Security";
  if ($IpSec->RetrieveList(\%data)) {
    $rtn = 1;
  } else {

      _DebugComment("Error collecting list information.\n".
                                     "Although you're successfully connected to the RelayList\n".
                                     "error: $error_num\n",1);
    $rtn = 0;
  }
  if (scalar(@_) == 2) {
    %{$_[1]} = %data;
    return $rtn;
  } else {
    return %data;
  }
}

sub RetrieveList {
  my $error_num;
  my $error_name;
  my $IpSec;
  my %data;
  if (scalar(@_) > 0) {
    $IpSec = $_[0];
  } else {
    if (scalar(@_) > 2) {
      Win32::Exchange::_ReportArgError("RetrieveList (E2K)",scalar(@_));
      return 0;
    }
  }

  bless $IpSec, "Win32::OLE";
  if ($IpSec->{GrantByDefault} == 1) {
    $data{'defaultaction'}='grant';
    if ($IpSec->{IPDeny} == 0) {
      $data{'iplist'} = "empty";
      $data{'iptotal'} = 0;
    } else {
      $data{'iplist'} = $IpSec->{IPDeny};
      $data{'iptotal'} = scalar(@{$IpSec->{IPDeny}});
    }
    if ($IpSec->{DomainDeny} == 0) {
      $data{'domainlist'} = "empty";
      $data{'domaintotal'} = 0;
    } else {
      $data{'domainlist'} = $IpSec->{DomainDeny};
      $data{'domaintotal'} = scalar(@{$IpSec->{DomainDeny}});
    }
  } else {
    $data{'defaultaction'}='deny';
    if ($IpSec->{IPGrant} == 0) {
      $data{'iplist'} = "empty";
      $data{'iptotal'} = 0;
    } else {
      $data{'iplist'} = $IpSec->{IPGrant};
      $data{'iptotal'} = scalar(@{$IpSec->{IPGrant}});
    }
    if ($IpSec->{DomainGrant} == 0) {
      $data{'domainlist'} = "empty";
      $data{'domaintotal'} = 0;
    } else {
      $data{'domainlist'} = $IpSec->{DomainGrant};
      $data{'domaintotal'} = scalar(@{$IpSec->{DomainGrant}});
    }
  }
  bless $IpSec ,"Win32::Exchange::SMTP::Security";
  if (scalar(@_) == 2) {
    %{$_[1]} = %data;
    return 1;
  } else {
    return %data;
  }
}

sub IpListManip {
  my $error_num;
  my $error_name;
  my $IpSec;
  my $action;
  my @list;
  my $rtn;
  if (scalar(@_) == 3) {
    $IpSec = $_[0];
    $action = $_[1];
    @list = @{$_[2]};
  } else {
    Win32::Exchange::_ReportArgError("IpListManip (E2K)",scalar(@_));
    return 0;
  }

  if (!$IpSec->_ListManip(\@list,$action,'IP')) {
    _DebugComment("Error performing ListManip for IP object\nerror: $error_num\n",1);
    $rtn = 0;
  } else {
    $rtn = 1;
  }
  bless $IpSec, "Win32::Exchange::SMTP::Security";
  return $rtn;
}

sub DomainListManip {
  my $error_num;
  my $error_name;
  my $IpSec;
  my $action;
  my @list;
  my $rtn;
  if (scalar(@_) == 3) {
    $IpSec = $_[0];
    $action = $_[1];
    @list = @{$_[2]};
  } else {
    Win32::Exchange::_ReportArgError("DomainListManip (E2K)",scalar(@_));
    return 0;
  }

  if (!$IpSec->_ListManip(\@list,$action,'Domain')) {
    _DebugComment("Error performing ListManip for Domain object\nerror: $error_num\n",1);
    $rtn = 0;
  } else {
    $rtn = 1;
  }
  bless $IpSec, "Win32::Exchange::SMTP::Security";
  return $rtn;
}

sub _ListManip {
  my $error_num;
  my $error_name;
  my $IpSec;
  my @list;
  my $action;
  my $type;
  my @exlist;
  my $rtn;
  if (scalar(@_) == 4) {
    $IpSec = $_[0];
    @list = @{$_[1]};
    $action = $_[2];
    $type = $_[3];
  } else {
    Win32::Exchange::_ReportArgError("_ListManip (E2K)",scalar(@_));
    return 0;
  }
  
  bless $IpSec, "Win32::OLE";
  my $typelist;
  my $typelist2;
  my $list_name;
  if ($IpSec->{GrantByDefault} == 1) {
    $typelist = $type.'Deny';
    $list_name = 'Deny';
  } else {
    $typelist = $type.'Grant';
    $list_name = 'Grant';
  }
  if ($action ne "overwrite" && $action ne "reset") {
    if ($IpSec->{$typelist} == 0) {
      if ($action eq "delete") {
        _DebugComment("Error deleting from the list.  There are no entries in the active list\n",1);
        bless $IpSec, "Win32::Exchange::SMTP::Security";
        return 0;
      }
    } else {
      @exlist = $IpSec->{$typelist};
      if ($action eq "add") {
        foreach my $item (@{$exlist[0]}) {
          push (@list,$item);
        }
      }
      if ($action eq "delete") {
        my $found = 0;
        my @new_list;
        foreach my $old_item (@{$exlist[0]}) {
          $found = 0;
          foreach my $item (@list) {
            if ($old_item eq $item) {
              $found = 1;
              last;
            }
          }
          if ($found != 1) {
            push (@new_list,$old_item);
          }
        }
        @list = @new_list
      }
    }
  }
  if ($action eq "reset") {  
    $typelist2='IP'.$list_name;
    $IpSec->{$typelist2} = [];#empty array
    $typelist2='Domain'.$list_name;
    $IpSec->{$typelist2} = [];#empty array
  } else {
    $IpSec->{$typelist} = \@list;
  }
  
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error setting $typelist\nerror: $error_num\n",1);
    $rtn = 0;
  } else {
     $IpSec->WriteList();
     $LIST_LOADED = 0;
     if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
       _DebugComment("Error performing WriteList\nerror: $error_num\n",1);
       $rtn = 0;
     } else {
       $rtn = 1;
     }
   }
   bless $IpSec, "Win32::Exchange::SMTP::Security";
   $IpSec->$LAST_LOADED_LIST(); #reload the list because the WriteList seems to reset the object
   $LIST_LOADED = 1;
 
   return $rtn;
}

sub SetDefaultAction {
  my $error_num;
  my $error_name;
  my $IpSec;
  my $action;
  if (scalar(@_) == 2) {
    $IpSec = $_[0];
    $action = lc($_[1]);
  } else {
    Win32::Exchange::_ReportArgError("SetDefaultAction (E2K)",scalar(@_));
    return 0;
  }
  bless $IpSec, "Win32::OLE";
  my %actions = ('grant' => 1,
                 'deny'  => 0
                );

  if ($actions{$action}) {
    $IpSec->{GrantByDefault}=$actions{$action};
  } else {
    _DebugComment("the parameter sent to SetDefaultAction needs to be either \"grant\" or \'deny\"\nerror: $error_num\n",1);
  }
  my $rtn;
  if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
    _DebugComment("Error setting GrantByDefault to $action\nerror: $error_num\n",1);
    $rtn = 0;
   } else {
    $IpSec->WriteList();
    $LIST_LOADED = 0;
    if (!ErrorCheck("0x00000000",$error_num,$error_name)) {
      _DebugComment("Error performing WriteList\nerror: $error_num\n",1);
      $rtn = 0;
    } else {
      $rtn = 1;
    }
  }
  bless $IpSec, "Win32::Exchange::SMTP::Security";
  $IpSec->$LAST_LOADED_LIST(); #reload the list because the WriteList seems to reset the object
  $LIST_LOADED = 1;
  return $rtn;
}

sub Release {
  my $IpSec = $_[0];
  bless $IpSec, "Win32::OLE";
  $IpSec->ReleaseBinding();#let go of the binding, you're done now
  bless $IpSec, "Win32::Exchange::SMTP::Security";
  return 1;
}

sub _ReportArgError {
  my $rtn = Win32::Exchange::_ReportArgError($_[0],$_[1]);
  return $rtn;
}

sub _DebugComment {
  my $rtn = Win32::Exchange::_DebugComment($_[0],$_[1],$DEBUG);
  return $rtn;
}

sub ErrorCheck {
  my $rtn = Win32::Exchange::ErrorCheck($_[0],$_[1],$_[2]);
  return $rtn;
}

1;

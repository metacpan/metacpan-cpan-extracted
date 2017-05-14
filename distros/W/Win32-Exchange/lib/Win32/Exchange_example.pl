use Win32::Exchange;
$domain = Win32::DomainName();
$info_store_server="YOUREXCHANGESERVERNAMEHERE";
$mta_server=$info_store_server; # this could be different, but for testing, we'll set them the same

#  start E2K only
$storage_group = ""; # you'd need to define this if you had more than 1 storage group on 1 server.
$mailbox_store = ""; # you'd need to define this if you had more than 1 mailbox store on 1 or more storage groups.
#  end E2K only

# runtime variables

$mailbox_alias_name='bgates'; # username
$givenName = "Bill"; # firstname
$sn = "Gates"; # lastname
$mailbox_full_name="$givenName $mailbox_alias_name $sn";
$distribution_list="Users"; # group / DL the user will be added to.
$email_domain = "microsoft.com"; # remote part of the final email address
$trustee_group = "Domain Admins"; # the group that has permission to log into this mailbox as well as the recipient

if (!Win32::Exchange::GetVersion($info_store_server,\%ver) ) {
  print "$rtn - Error returning into main from GetVersion\n";
  exit 0;
}

print "version      = $ver{ver}\n";
print "build        = $ver{build}\n";
print "service pack = $ver{sp}\n";
if (!($provider = Win32::Exchange::Mailbox->new($info_store_server))) {
  print "$rtn - Error returning into main from new ($Win32::Exchange::VERSION)\n";
  exit 0;
}

my @PermsUsers;
#in E2K, by default the SELF account has access to the mailbox (the self account is
#  the user account that is attached to the mailbox).
#
#So, only push the user in the case of an E55 mailbox.
push (@PermsUsers,"$domain\\$trustee_group"); #Group that needs perms to the mailbox...

if ($ver{ver} eq "5.5") {
  push (@PermsUsers,"$domain\\$mailbox_alias_name");
  e55(); # Exchange 5.5
} elsif ($ver{ver} =~ /^6\../) {
  e60(); # E2K03 is the same as E2K.
}

sub e55 {
  if ($mailbox = $provider->GetMailbox($mailbox_alias_name)) {
    print "Mailbox already existed\n";
    if ($mailbox->SetOwner("$domain\\$mailbox_alias_name")) {
      print "SetOwner in GetMailbox worked!\n";
    }
    if ($mailbox->SetPerms(\@PermsUsers)) {
      print "Successfully set perms in GetMailbox\n";  
    } else {
      print "Error setting perms from GetMailbox\n";  
      exit 0;
    }
  } else {
    $mailbox = $provider->CreateMailbox($mailbox_alias_name);
    if (!$mailbox) {
      print "error creating mailbox\n";
      exit 0;
    }
    print "We created a mailbox!\n";
    if ($mailbox->SetOwner("$domain\\$mailbox_alias_name")) {
      print "SetOwner worked\n";  
    } else {
      print "SetOwner failed\n";  
    }
    if ($mailbox->GetOwner($nt_user,0x2)) {
      print "GetOwner worked: owner = $nt_user\n";  
    } else {
      print "GetOwner failed\n";  
    }

    $mailbox->GetPerms(\@array);
    
    foreach my $acl (@array) {
      print "   trustee - $acl->{Trustee}\n";  
      print "accessmask - $acl->{AccessMask}\n";  
      print "   acetype - $acl->{AceType}\n";  
      print "  aceflags - $acl->{AceFlags}\n";  
      print "     flags - $acl->{Flags}\n";  
      print "   objtype - $acl->{ObjectType}\n";  
      print "inhobjtype - $acl->{InheritedObjectType}\n";  
    }

    if ($mailbox->SetPerms(\@PermsUsers)) {
      print "Successfully set perms\n";  
    } else {
      print "Error setting perms\n";  
      exit 0;
    }
  }
  
  #$Exchange_Info{'Deliv-Cont-Length'}='6000'; 
  #$Exchange_Info{'Submission-Cont-Length'}='6000'; 
  $Exchange_Info{'givenName'}=$givenName;
  $Exchange_Info{'sn'}=$sn;
  $Exchange_Info{'cn'}=$mailbox_full_name;
  $Exchange_Info{'mail'}="$mailbox_alias_name\@$email_domain";
  $Exchange_Info{'rfc822Mailbox'}="$mailbox_alias_name\@$email_domain"; 
  #You can add any attributes to this hash that you can set via exchange for a mailbox

  #$rfax="RFAX:$Exchange_Info{'cn'}\@"; #this can set the Rightfax SMTP name for Exchange-enabled Rightfax mail delivery
  #push (@$Other_MBX,$rfax);

  $smtp="smtp:another_name_to_send_to\@$email_domain"; 
  push (@$Other_MBX,$smtp);
  #be careful with 'otherMailbox'es..  You are deleting any addresses that may exist already
  #if you set them via 'otherMailbox' and don't get them first (you are now forewarned).
  $Exchange_Info{'otherMailbox'}=$Other_MBX;

  if (!Win32::Exchange::GetDistinguishedName($mta_server,"Home-MTA",$Exchange_Info{"Home-MTA"})) {
    print "Failed getting distinguished name for Home-MTA on $info_store_server\n";
    exit 0;
  }
  if (!Win32::Exchange::GetDistinguishedName($info_store_server,"Home-MDB",$Exchange_Info{"Home-MDB"})) {
    print "Failed getting distinguished name for Home-MDB on $info_store_server\n";
    exit 0;
  }

  if ($mailbox->SetAttributes(\%Exchange_Info)) {
    print "SetAttributes worked\n";  
  } else {
    print "SetAttributes failed\n";  
  }

  my @new_dl_members;
  push (@new_dl_members,$mailbox_alias_name);
  $provider->AddDLMembers($distribution_list,\@new_dl_members); 

}

sub e60 {

  if (Win32::Exchange::LocateMailboxStore($info_store_server,$storage_group,$mailbox_store,$store_name,\@counts)) {
    print "storage group = $storage_group\n";
    print "mailbox store = $mailbox_store\n";
    print "located store distinguished name= $store_name\n";
    print "$info_store_server\n";
    print "  Total:\n";
    print "    storage groups = $counts[0]\n";
    print "    mailbox stores = $counts[1]\n";
  }
  if ($mailbox = $provider->GetMailbox($mailbox_alias_name)) {
    print "Got Mailbox successfully\n";
  } else {
    print "Mailbox did not exist\n";
    if ($mailbox = $provider->CreateMailbox($mailbox_alias_name
                                           )
       ) {
      print "Mailbox create succeeded.\n";
    } else {
      print "Mailbox creation failed.\n";
      exit 0;
    }
    
  }
  #be careful with proxy addresses..  You are deleting any addresses that may exist already
  #if you set them via ProxyAddresses (you are now forewarned).
  push (@$proxies,'SMTP:'.$mailbox_alias_name.'@'.$email_domain);
  push (@$proxies,'SMTP:secondary@'.$email_domain);
  push (@$proxies,'SMTP:primary@'.$email_domain);
  push (@$proxies,'SMTP:tertiary@'.$email_domain);

  $Attributes{"IMailRecipient"}{ProxyAddresses} = $proxies;
  
  #  $Attributes{"ExchangeInterfaceName"}{Property} = value; #with this method you should be able to set any value
  #                                                           imaginable.....  Here's a few to start with

  $Attributes{"IMailRecipient"}{IncomingLimit} = 6000;
  $Attributes{"IMailRecipient"}{OutgoingLimit} = 6000;
  $Attributes{"IMailboxStore"}{EnableStoreDefaults} = 0;
  $Attributes{"IMailboxStore"}{StoreQuota} = 100; #at 100KB starts getting warnings
  $Attributes{"IMailboxStore"}{OverQuotaLimit} = 120; #at 120KB can't send...  I THINK...
  $Attributes{"IMailboxStore"}{HardLimit} = 130; #at 130KB, can't do anything...  I THINK...
  if (!$mailbox->SetAttributes(\%Attributes)) {
    print "Error setting 2K Attributes\n";
    exit 0;

  } else {
    print "Set Attributes correctly\n";
  }

  my @PermUsers;
  push (@PermUsers,"$domain\\$mailbox_alias_name");
  push (@PermUsers,"$domain\\$trustee_group"); #Group that needs perms to the mailbox...

  if (!$mailbox->SetPerms(\@PermUsers)) {
    print "Error setting 2K Perms\n";
    exit 0;
  } else {
    print "Set 2K Perms correctly\n";
  }
  my @new_dl_members;
  push (@new_dl_members,$mailbox_alias_name);
  if ($provider->AddDLMembers($distribution_list,\@new_dl_members)) {
    print "Add successful to DL\n";
  } else {
    print "Error adding distlist member\n";
    exit 0;
  }
  exit 1;
        
}

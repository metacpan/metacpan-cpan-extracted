# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use VMS::Mail;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{
$mailfile = new VMS::Mail();
print "ok 2\n";

$ahref = $mailfile->mailfile_begin({},[MAIL_DIRECTORY]);
if (defined($ahref)) {
  print "ok 3\n";
  printf("  result directory is '%s'\n",$ahref->{MAIL_DIRECTORY});
} else {
 print "NOT ok 3 ($!)";
}

$ahref = $mailfile->open({},[WASTEBASKET]);
$ahref || print "NOT ";
print("ok 4\n");
if (defined($ahref)) {
  printf("  result mbname is '%s'\n",$ahref->{WASTEBASKET});
} else {
  printf("  error text: $!");
}

$rs = sub {
  my ($lstRef,$fldrname) = @_;
  defined($fldrname) && push @$lstRef,$fldrname;
  return(1);
};

$ahref = $mailfile->info_file({ FOLDER_ROUTINE => $rs,
                                USER_DATA => $rfFlist=[]},
               [WASTEBASKET,RESULTSPEC,
                DELETED_BYTES]);
$ahref || print "NOT ";
printf("ok 5: Folder list is (%s)\n",join(",",@$rfFlist));
if (defined($ahref)) {
  printf("  result mbname     is '%s'\n",$ahref->{WASTEBASKET});
  printf("  result resultspec is '%s'\n",$ahref->{RESULTSPEC});
  printf("  result deleted bytes '%d'\n",$ahref->{DELETED_BYTES});
} else {
  printf("  error text: $!\n");
}

$ahref = $mailfile->close({FULL_CLOSE},
                          [TOTAL_RECLAIM,DATA_RECLAIM,DATA_SCAN,
                           INDEX_RECLAIM,MESSAGES_DELETED]);
if (defined($ahref)) {
  print("ok 6a");
  printf("  Total reclaim was '%d'\n",$ahref->{TOTAL_RECLAIM});
  printf("  index reclaim was '%d'\n",$ahref->{INDEX_RECLAIM});
  printf("  data reclaim  was '%d'\n",$ahref->{DATA_RECLAIM});
  printf("  data scan     was '%d'\n",$ahref->{DATA_SCAN});
  printf("  messages deleted  '%d'\n",$ahref->{MESSAGES_DELETED});
} else {
  print "NOT ok 6a ($!)\n";
}

$ahref = $mailfile->end({},[]);
$ahref || print "NOT ";
print("ok 6b\n");

$ahref = $mailfile->mailfile_begin({},[MAIL_DIRECTORY]);
if (defined($ahref)) {
  print "ok 7\n";
  printf("  result directory is '%s'\n",$ahref->{MAIL_DIRECTORY});
} else {
  print "NOT ok 7 ($!)\n";
}


$ahref = $mailfile->open({},[WASTEBASKET]);
$ahref || print "NOT ";
print("ok 8a\n");
if (defined($ahref)) {
  printf("  result mbname is '%s'\n",$ahref->{WASTEBASKET});
} else {
  printf("  error text: $!\n");
}


$message = new VMS::Mail();
$ahref = $message->message_begin({FILE_CTX=>$mailfile},
                                 [SELECTED]);
###FLAGS=>[REPLIED,MARKED]},
if (defined($ahref)) {
  printf("ok 8b - %d selected\n",$ahref->{SELECTED});
} else {
  print "NOT ok 8b ($!)";
}

$ahref = $message->select({FOLDER=>MAIL},
                                 [SELECTED]);
if (defined($ahref)) {
  printf("ok 9 - %d selected\n",$nsel = $ahref->{SELECTED});
} else {
  print "NOT ok 9 ($!)\n";
}

for ($lookat=0;$lookat<$nsel;$lookat++) {
  $ahref = $message->info({NEXT=>1},[CURRENT_ID,FROM,BINARY_DATE,SUBJECT,
                                     RETURN_FLAGS]);
  if (defined($ahref)) {
    printf("  (%s) %d %s %s %s\n",
          join(",",@{$ahref->{RETURN_FLAGS}}),
          $ahref->{CURRENT_ID},
          $ahref->{FROM},
          $ahref->{BINARY_DATE},
          $ahref->{SUBJECT});

    }
  else {
    print("Oops... it exploded... '$!'\n"); }

}



}

print "ok 10\n";	#Destroyed & deallocated the context ok


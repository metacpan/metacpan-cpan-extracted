# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-Mirror.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 144;
# use Test::More "no_plan";
BEGIN { use_ok('Tk::Mirror') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#-------------------------------------------------
 use_ok('Tk');
#-------------------------------------------------
 my $mw = eval { MainWindow->new(); };
 warn($@) if($@);
#-------------------------------------------------
 SKIP:
 {
 skip("no tests without a valid screen\n", 142) 
 	unless(ref($mw) && $mw->isa('MainWindow'));
#-------------------------------------------------
 $mw->title('Mirror Directories');
 $mw->geometry('+5+5');
 can_ok($mw, 'Mirror');
 ok(my $mirror = $mw->Mirror(
 	-localdir		=> 'TestA',
 	-remotedir	=> '/authors/id/K/KN/KNORR/Remote/TestA',
 	-user		=> 'anonymous',
 	-ftpserver	=> 'www.cpan.org',
 	-pass		=> 'create-soft@tiscali.de',
	-exclusions	=> ['CHECKSUMS'],
 	-overwrite	=> 'older'
 	));
#-------------------------------------------------
# Net::MirrorDir Methods
 isa_ok($mirror->{upload}, 'Net::MirrorDir');
 isa_ok($mirror->{download}, 'Net::MirrorDir');
 for(qw/
 	_Init
 	Connect
 	IsConnection
 	Quit
 	ReadLocalDir
 	ReadRemoteDir
 	LocalNotInRemote
 	RemoteNotInLocal
 	AUTOLOAD
 	DESTROY
 	/)
 	{
 	can_ok($mirror->{upload}, $_);
 	can_ok($mirror->{download}, $_);
 	}
#-------------------------------------------------
# Net::UploadMirror methods
 isa_ok($mirror->{upload}, 'Net::UploadMirror');
 can_ok($mirror->{upload}, $_)
 	for(qw/
 		_Init
 		Upload
 		CheckIfModified
 		UpdateLastModified
 		StoreFiles
 		MakeDirs
 		DeleteFiles
 		RemoveDirs
 		CleanUp
 		RtoL
 		LtoR
 		/);
#-------------------------------------------------
# Net::DownloadMirror methods
 isa_ok($mirror->{download}, 'Net::DownloadMirror');
 can_ok($mirror->{download}, $_)
 	for(qw/
 		_Init
 		Download
 		CheckIfModified
 		UpdateLastModified
 		StoreFiles
 		MakeDirs
 		DeleteFiles
 		RemoveDirs
 		CleanUp
 		LtoR
 		RtoL
 		/);
#-------------------------------------------------
# Tk::Mirror methods
 isa_ok($mirror, 'Tk::Frame');
 isa_ok($mirror, 'Tk::Mirror');
 can_ok($mirror, $_)
 	for(qw/
 		new		GetChilds
 		Populate		CompareDirectories
 		Label		Download
 		BrowseEntry	Upload
 		Entry		StoreParams
 		Dialog		SetParams
 		Scrolled		UpdateAccess
 		Button		InsertLocalTree
 		Advertise	InsertRemoteTree
 		Delegates	InsertProperties
 		grid		InsertRemoteModifiedTimes
 		Subwidget	InsertLocalModifiedTimes
 				InsertStoredValues
 				InsertPaths	
 				DeletePaths
 				DeleteProperties
				DESTROY	
 		/);
#-------------------------------------------------
 ok($mirror->grid());
 ok(my $rh_childs = $mirror->GetChilds());
 my $sub_widget;
 for(keys(%{$rh_childs}))
 	{
	ok($sub_widget = $mirror->Subwidget($_));
 	can_ok($sub_widget, "configure"); 
 	$sub_widget->configure(
 		-font	=> "{Times New Roman} 14 {bold}",
 		);
 	}
 for(qw/
 	TreeLocalDir
 	TreeRemoteDir
 	/)
 	{
 	ok($sub_widget = $mirror->Subwidget($_));
 	can_ok($sub_widget, "configure");
 	$sub_widget->configure(
 		-background	=> "#FFFFFF",
 		-width		=> 40,
 		-height		=> 20,
 		);
 	}
 for(qw/
 	bEntryUser
 	EntryPass
 	bEntryFtpServer
 	bEntryLocalDir
 	bEntryRemoteDir
 	/)
 	{
 	ok($sub_widget = $mirror->Subwidget($_));
 	can_ok($sub_widget, "configure");
 	$sub_widget->configure(
 		-background	=> "#FFFFFF",
 		);
 	}
#-------------------------------------------------
 skip("no tests with www.cpan.org\n", 9) unless($mirror->{download}->Connect());
 	ok($mirror->CompareDirectories());
	ok($mirror->Download());
 	ok(-f $_) for(
 		'TestA/TestB/TestC/Dir1/test1.txt',
 		'TestA/TestB/TestC/Dir2/test2.txt',
 		'TestA/TestB/TestC/Dir2/test2.subset',
 		'TestA/TestB/TestC/Dir3/test3.txt',
 		'TestA/TestB/TestC/Dir4/test4.txt',
 		'TestA/TestB/TestC/Dir4/test4.exclusions',
 		'TestA/TestB/TestC/Dir5/test5.txt'
 		);
# can only be tested with a valid FTP-Access
	# ok($mirror->Upload());
#-------------------------------------------------
 $mw->destroy();
 }
#-------------------------------------------------



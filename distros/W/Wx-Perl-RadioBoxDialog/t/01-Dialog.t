use 5.12.0;
use warnings FATAL => 'all';

use Wx qw( wxID_ANY wxNOT_FOUND );

use Test::More;
use Test::Exception;
use Wx::Perl::RadioBoxDialog;

{ 
	no strict 'refs';
	map { &{"main::$_"} }
	grep { defined &{"main::$_"} && /^test/ }
	keys %{'main::'};
}

sub mySleep {
	return if not $ENV{PERL_TEST_SLEEP};
	sleep $ENV{PERL_TEST_SLEEP};
}


sub newDialog {
	return Wx::Perl::RadioBoxDialog->new(
		undef,
		"Testmessage\nLong",
		'Testcaption',
		[ qw( a b c d e ) ],
	);
}

sub testNew {
	
	my $dlg = newDialog();
	isa_ok( $dlg, 'Wx::Perl::RadioBoxDialog' );
	$dlg->Show;
	ok( $dlg->IsShown );
	mySleep();
	$dlg->Destroy;
	
	# TODO: more possible new's..
}

sub testGetSelection {
	my $dlg = newDialog();
	ok( 0 == $dlg->GetSelection );	
	$dlg->Show();
	ok( 0 == $dlg->GetSelection );
	$dlg->SetSelection( 4 );
	ok( 4 == $dlg->GetSelection );
	$dlg->Destroy;		
}

sub testSetSelection {
	my $dlg = newDialog();
	$dlg->SetSelection( 3 );
	ok( 3 == $dlg->GetSelection );
	$dlg->Show;
	ok( 3 == $dlg->GetSelection );
	$dlg->SetSelection( 0 );
	ok( 0 == $dlg->GetSelection );
	$dlg->Destroy;
}

sub testGetStringSelection {
	my $dlg = newDialog();
	is( 'a', $dlg->GetStringSelection );	
	$dlg->Show();
	is( 'a', $dlg->GetStringSelection );
	$dlg->SetSelection( 4 );
	is( 'e', $dlg->GetStringSelection );
	$dlg->Destroy;		
}

sub testSetStringSelection {
	my $dlg = newDialog();
	$dlg->SetSelection( 3 );
	ok( 3 == $dlg->GetSelection );
	$dlg->Show;
	ok( 3 == $dlg->GetSelection );
	$dlg->SetSelection( 0 );
	ok( 0 == $dlg->GetSelection );
	$dlg->Destroy;
}

done_testing();

1;

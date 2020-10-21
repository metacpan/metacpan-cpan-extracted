#!perl

use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';
use Util::Medley::File;
use Util::Medley::Spawn;
use English;

###################################################

use vars qw();

###################################################

use_ok('Util::Medley::PkgManager::YUM');

my $file = Util::Medley::File->new;

my $yum = Util::Medley::PkgManager::YUM->new;
ok($yum);

SKIP: {
	my $yumPath = $file->which('yum');
	skip "can't find yum exe" if !$yumPath;

	doRepoList($yum);
	doList($yum);
}

SKIP: {
	my $repoqueryPath = $file->which('repoquery');
	skip "can't find repoquery exe" if !$repoqueryPath;

	doRepoList($yum);
}

done_testing;

###################################################

sub doList {
	my $yum = shift;

	my $repoList = $yum->repoList;

	foreach my $repo (@$repoList) {
		my $list = doListByRepo( $yum, $repo );
		if ($list and @$list > 0) {
		  last;  # don't need to test all repos	
		}
	}
}

sub userCanSudoNoPasswd {

	if ( $UID == 0 ) {
		return 1;
	}

	my $spawn = Util::Medley::Spawn->new;
	my @cmd   = ( "sudo", "-n", "true" );

	my ( $stdout, $stderr, $exit ) =
	  $spawn->capture( cmd => \@cmd, wantArrayRef => 1 );

	if ( !$exit ) {
		return 1;
	}

	return 0;
}

sub doListByRepo {
	my $yum  = shift;
	my $repo = shift;

    my $aref;
	if ( $UID == 0 ) {

		my %a;
		$a{installed} = 1;
		$a{repoId}    = $repo->{repoId};

		eval {
			$aref = $yum->list(%a);
			isa_ok( $aref, 'ARRAY' );
		};
		ok( !$@ );
	}
	else {

	  SKIP: {
			skip "user can't sudo without password" if !userCanSudoNoPasswd();

			my %a;
			$a{installed} = 1;
			$a{repoId}    = $repo->{repoId};
			$a{useSudo}   = 1;

			eval {
				$aref = $yum->list(%a);
				isa_ok( $aref, 'ARRAY' );
			};
			ok( !$@ );
		}
	}
	
	return $aref;
}

sub doRepoList {
	my ($yum) = @_;

	my $aref = $yum->repoList( enabled => 1, disabled => 1 );
	isa_ok( $aref, 'ARRAY' );

	foreach my $repo (@$aref) {
		isa_ok( $repo, 'HASH' );
		ok( $repo->{repoId} );
		ok( $repo->{repoStatus} );
	}
}


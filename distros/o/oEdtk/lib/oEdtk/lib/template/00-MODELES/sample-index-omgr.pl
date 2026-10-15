#!/usr/bin/perl
use oEdtk::Main;
use oEUser::Lib;
use oEdtk::Tracking;
use oEdtk::RecordParser;
use oEdtk::OmgrIdxDoc;
use oEUser::Descriptor::E1;
use oEUser::Descriptor::E2;
use oEUser::Descriptor::E3;
use oEUser::Descriptor::ENTETE;
use oEUser::Descriptor::F4;
use oEUser::Descriptor::L1;
use oEUser::Descriptor::OC;
use oEUser::Descriptor::T8;
use strict;
use warnings;

my ( %hRECORDS, $VALS, $DOC, $TRK, %hVARS_DOC );

sub main() {
	if ( $#ARGV == -1 ) { oe_app_usage(); }

	user_corp_file_prefixe( $ARGV[0], '_' );
	my $user = user_get_aneto_user( $ARGV[0] ) || 'none';

	# TRACKING INITIALIZATION
	$TRK = oEdtk::Tracking->new(
		$ARGV[1],
		user   => $user,
		entity => oe_corporation_set(),
		keys   => [ 'NUMADH', 'SECTION' ]
	);
	oe_new_job();

	# RECORD MAPPING
	map_records();

	# DOCUMENT-SPECIFIC INITIALIZATION
	initDoc();
	$DOC = oEdtk::OmgrIdxDoc->new();
	warn "INFO: header " . $DOC->{header} . "\n";

	# PARSER PROCESS INITIALIZATION (BINDS THE KEYS TO THE RECORDS)
	my $p = oEdtk::RecordParser->new(
		\*IN,
		'ENTETE' => $hRECORDS{ENTETE},
		'E1'     => $hRECORDS{E1},
		'E2'     => $hRECORDS{E2}
	);
	my ( $id, $lastid );
	while ( ( $id, $VALS ) = $p->next() ) {
		if ( $id eq 'E1' ) {
			process_E1();

		}
		elsif ( $id eq 'E2' ) {
			process_E2();
		}

		print OUT $DOC;
		$DOC->reset();
		$lastid = $id;
	}

	# PURGE BEFORE EXIT
	print OUT $DOC;
}

sub map_records() {
	$hRECORDS{ENTETE} = oEUser::Descriptor::ENTETE->get();
	$hRECORDS{ENTETE}->bind_all()
		;    # bind the data fields reusing the label defined in the descriptor
	$hRECORDS{E1} = oEUser::Descriptor::E1->get();

	# $hRECORDS{E1}->debug();	# request the display of the loaded record structure
	$hRECORDS{E1}->bind_all();    # bind the data fields reusing the label defined in the descriptor
	$hRECORDS{E2} = oEUser::Descriptor::E2->get();
	$hRECORDS{E2}->bind_all();    # bind the data fields reusing the label defined in the descriptor
	$hRECORDS{E3} = oEUser::Descriptor::E3->get();
	$hRECORDS{E3}->bind_all();
	$hRECORDS{T8} = oEUser::Descriptor::T8->get();
	$hRECORDS{T8}->bind_all();
	$hRECORDS{F4} = oEUser::Descriptor::F4->get();
	$hRECORDS{F4}->bind_all();
	$hRECORDS{OC} = oEUser::Descriptor::OC->get();
	$hRECORDS{OC}->bind_all();
	$hRECORDS{L1} = oEUser::Descriptor::L1->get();
	$hRECORDS{L1}->bind_all();

	return 1;
}

sub initDoc() {

# by putting all document variables in a hash, I have fewer variables and reinitialize everything at once...
	undef %hVARS_DOC;

	return 1;
}

sub process_E1 () {

}

sub process_E2 () {

}

main();
1;

#!/usr/bin/perl

use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config    qw(config_read);
use oEdtk::DBAdmin   qw(db_connect);
use oEdtk::Outmngr   qw(omgr_check_acquit omgr_track_folds omgr_track_report);
use oEdtk::Messenger qw(oe_send_mail);

if ( @ARGV > 1 or $ARGV[0] =~ /-h/i ) {
	die "Usage: $0 [history]\n\n\thistory : number of history days, default is 10 days \n";
}

my $cfg = config_read( 'EDTK_DB', 'EDTK_STATS', 'MAIL' );
my $dbh = db_connect( $cfg, 'EDTK_DBI_STATS', { AutoCommit => 1, RaiseError => 1 } );

my $rows = omgr_check_acquit( $dbh, $ARGV[0] );
$rows = omgr_track_folds( $dbh, $ARGV[0] );
my $fmt  = shift(@$rows);
my $head = shift(@$rows);

if ( @$rows == 0 ) {
	warn "INFO: no acquittement\n";
	exit 1;
}

my %hMail;
foreach my $row (@$rows) {
	$hMail{ @$row[$#$row] } .= sprintf( $$fmt . "\n", @$row );
}

foreach my $mail ( keys %hMail ) {
	my $mailfile = $cfg->{'EDTK_MAIL_ACQ'};
	open( my $fh, '<', $mailfile ) or die "Cannot open \"$mailfile\": $!\n";
	my @body = <$fh>;
	close($fh);

	push( @body, "\n\n\n" );
	push( @body, sprintf( $$fmt, @$head ), "\n" );
	push( @body, $hMail{$mail},            "\n" );

	my ( $sec, $min, $hour, $day, $month, $year ) = localtime();
	my $date = sprintf( "%02d/%02d/%d",   $day,  $month + 1, $year + 1900 );
	my $time = sprintf( "%02d:%02d:%02d", $hour, $min,       $sec );

	my $subject = $cfg->{'EDTK_TYPE_ENV'};
	$subject .= " - ";
	$subject .= $cfg->{'EDTK_MAIL_SUBJ'};
	$subject =~ s/%date/$date/;
	$subject =~ s/%time/$time/;

	oe_send_mail( $cfg->{$mail}, $subject, @body );
}

$rows = omgr_track_report($dbh);
$fmt  = shift(@$rows);
$head = shift(@$rows);
if ( @$rows == 0 ) {
	warn "INFO: nothing to report\n";
	exit 1;
}

my %hMail2;
foreach my $row (@$rows) {
	$hMail2{ @$row[6] } .= sprintf( $$fmt . "\n", @$row );
}

foreach my $mail ( keys %hMail2 ) {
	my $mailfile = $cfg->{'EDTK_MAIL_RPT'};
	open( my $fh, '<', $mailfile ) or die "Cannot open \"$mailfile\": $!\n";
	my @body = <$fh>;
	close($fh);

	push( @body, "\n\n\n" );
	push( @body, sprintf( $$fmt, @$head ), "\n" );
	push( @body, $hMail2{$mail},           "\n" );

	my ( $sec, $min, $hour, $day, $month, $year ) = localtime();
	my $date = sprintf( "%02d/%02d/%d",   $day,  $month + 1, $year + 1900 );
	my $time = sprintf( "%02d:%02d:%02d", $hour, $min,       $sec );

	my $subject = $cfg->{'EDTK_TYPE_ENV'};
	$subject .= " - ";
	$subject .= $cfg->{'EDTK_MAIL_SUBJ'};
	$subject =~ s/%date/$date/;
	$subject =~ s/%time/$time/;

	oe_send_mail( $cfg->{"EDTK_MAIL_$mail"}, $subject, @body );
}

1;

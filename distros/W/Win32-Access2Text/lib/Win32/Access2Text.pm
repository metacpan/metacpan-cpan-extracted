package Win32::Access2Text;

use warnings;
use strict;
use DBI;

our $VERSION = '0.03';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &AccTabSaveToText );
}

sub AccTabSaveToText($$$$) {

	my ($connectionString, $fileMdb, $tabMdb, $fileTxt) = (shift, shift, shift, shift);

	my $connect   = DBI->connect("dbi:ADO:Data Source=".$fileMdb.$connectionString, "");
	my $selectAll = $connect->selectall_arrayref("SELECT * FROM [$tabMdb]");

	open(my $fhTxt, ">", $fileTxt) or die $!;

	foreach my $row ( @{$selectAll} ) {
		print $fhTxt join("\t", map {defined $_?$_:''} @{$row})."\n";
	} # foreach

	close($fhTxt) or die $!;

	$fileTxt;

} # AccTabSaveToText

1;
__END__

=pod

=head1 NAME

Access2Text - a module for save Accesstable as Textfile

=head1 SYNOPSIS

  use warnings;
  use strict;
  use Access2Text qw( AccTabSaveToText );

  AccTabSaveToText("ourConnectionString", "C:\\DB.mdb", "Table", "C:\\Textfile.txt");

  Example for Connection String: ";Provider=Microsoft.ACE.OLEDB.12.0;Password=\"\""

=head1 ABSTRACT

Test

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut

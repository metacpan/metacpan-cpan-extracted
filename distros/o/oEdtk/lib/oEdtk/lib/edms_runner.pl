#!/usr/bin/perl
use strict;
use warnings;
use File::Temp    qw(tempdir);
use oEdtk::Config qw(config_read);
use Archive::Zip  qw(:ERROR_CODES);

if ( @ARGV != 2 or $ARGV[0] =~ /-h/i ) {
	die
"Usage: $0 NOM_APP DATA_FILE\n\n For GED data recovery (runs the composition and GED preparation)\n";
}

my @files;
my $app  = $ARGV[0];
my $file = $ARGV[1];
warn "INFO: processing $app requested for $file\n";
my $cfg     = config_read('COMPO');
my $workdir = tempdir( 'edtkXXXXXXX', DIR => $cfg->{'EDTK_DIR_APPTMP'} );
chmod( 0777, $workdir );
chdir($workdir);
warn "INFO: workdir = $workdir\n";

# IS THE DATA FILE COMPRESSED ?
if ( $file =~ /\.zip$/i ) {
	my $zip = Archive::Zip->new($file);
	@files = $zip->members();
	$zip->extractTree();

}
elsif ( $file =~ /\.gz$/i || $file =~ /\.z$/i ) {
	$files[0] = $file;
	$files[0] =~ s/(\.z)$//i;
	$files[0] =~ s/(\.gz)$//i;
	my $uncompress = system("gunzip -c $file > $files[0]");
	die "ERROR: Could not extract data ($uncompress)\n" if $uncompress != 0;

}
else {
	$files[0] = $file;
}

# PREPARATION OF THE PAGE LAYOUT PROCESSING
# CONFIGURATION (CGI GED TO BE REWORKED TO SIMPLIFY AND MAKE MORE EXPLICIT)
my $perl    = $cfg->{'EDTK_BIN_PERL'} . '/perl';
my $script  = $cfg->{'EDTK_DIR_APP'} . "/$app.pl";
my @options = ();

# my @options 	= ('cgi');
# push (@options, 'cgiged');

# WARNING: the document must also be configured in the parameter database
$ENV{'EDTK_OPTIONS'} = join( ',', @options );

foreach my $filename (@files) {

	# START THE PAGE LAYOUT PROCESSING WITH SENDING TO THE GED
	warn "INFO: processing $filename\n";
	my $rv = system("$perl $script $filename $filename --edms > $app.perl.log 2>&1");
	die "ERROR: Could not extract data ($rv)\n" if $rv != 0;
	unlink($filename);
}
warn "INFO: done, docs prepared for GED\n";

# DELETE THE INTERMEDIATE PDFs FROM THE WORKING DIRECTORY
# unlink glob "*.pdf";

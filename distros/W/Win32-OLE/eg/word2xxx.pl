# Convert MS Word files to other formats using the builtin file converters
#
# Ideas: 
# - Use PrintToFile to support PostScript etc. too
# - Ask before overwriting output file
# - Disable execution of AutoOpen macros: $Word->WordBasic->DisableAutoMacros?
#
use strict;
use Win32::OLE qw(in);

my $Word = Win32::OLE->new('Word.Application', 'Quit')
  or die "Couldn't run Word";

my $OutputFormat = shift;
my ($SaveFormat,$FormatName);
foreach my $Conv (in $Word->FileConverters) {
    next unless $Conv->{CanSave};
    my $ClassName = $Conv->{ClassName};

    if (@ARGV == 0) {
	# Print list of converter names if run without arguments
	printf("%4d %s %s %s\n", $Conv->{SaveFormat}, $ClassName,
	       '.' x (26 - length($ClassName)), $Conv->{FormatName});
    }
    elsif ($ClassName =~ /^$OutputFormat/oi) {
	$SaveFormat = $Conv->{SaveFormat};
	$FormatName = $Conv->{FormatName};
	last;
    }
}

exit unless @ARGV;

unless (defined $SaveFormat) {
    print "No fileconverter for \"$OutputFormat\" found!\n";
    print "Run word2xxx without arguments to get a list of converter names.\n";
    exit;
}

shift;
my ($InFile, $OutFile) = @ARGV;
$InFile  = Win32::GetCwd() . "/$InFile"  if $InFile  !~ /^(\w:)?[\/\\]/;
$OutFile = Win32::GetCwd() . "/$OutFile" if $OutFile !~ /^(\w:)?[\/\\]/;

unless (-f $InFile) {
    print "Inputfile $InFile does not exist!\n";
    exit;
}

printf("Convert 'Word' format to '%s' format:\nInput:  %s\nOutput: %s\n", 
       $FormatName, $InFile, $OutFile);

my $Doc = $Word->Documents->Open($InFile);
$Doc->SaveAs({FileName => $OutFile, FileFormat => $SaveFormat});
$Doc->Close;

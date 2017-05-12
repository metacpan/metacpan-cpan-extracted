package Real::Encode;

#use Win32::Process;
#use Win32::Registry qw(HKEY_LOCAL_MACHINE);
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Cwd 'chdir';
use Carp;

$VERSION = '0.05';

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw(Encode Merge Dump Cut Set_File new);

%EXPORT_TAGS = (all => [@EXPORT_OK]);
			 
sub Version {
return $VERSION;
}

#-------------------------------------#

sub new { 
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

#-------------------------------------#

sub initialize {
    my $self = shift;
    my $setDir="c:\\Real\\Encoder\\";
    $setDir = shift if @_; # in case not default install
    $$self{rootDir}=$setDir;
    $$self{error}=0;
}

#-------------------------------------#

sub Set_File {
my ($self) = shift;
my ($file) = @_;
$self->{out} = $file;
}

#-------------------------------------#

sub DESTROY {};

#-------------------------------------#

sub Encode {
my ($self) = shift;
if ($_[1] !~ /.r\w$/) { croak "Incorrect number/order of args for Encode()";}
my ($in1) = shift; my ($out) = shift;
my ($opt,$line,$uc);
my (@opts) = params(@_);
foreach $line (@opts) { # Get our options into one nice line
	$line =~ s/^-(\w)//; $uc = uc($1); # grab option letter and uc it
	$line =~ s/^/-$uc/; # put it back. Do this since global uc'ing will mess
	$line =~ s/-/\//;   # up /T, /U and /C
	$opt .= $line." ";
}
my @files;
push(@files,$in1);
my $exist = files_exist(@files);

my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it

if ($exist == 1) {
	chdir("$self->{'rootDir'}");	
# Did person put in full path?
	if ($in1 =~ /\w\:\\/ && $out =~ /\w\:\\/) {
		$self->{out}="$out";
		system("rvbatch.exe rvencode.exe /I $in1 /O $out $opt");
	}elsif ($in1 =~ /\w:\\/ && $out !~ /\w\:\\/) {
		$self->{out}="$dir\\$out";
		system("rvbatch.exe rvencode.exe /I $in1 /O $dir\\$out $opt");
	}elsif ($in1 !~ /\w\:\\/ && $out =~ /\w\:\\/) {
		$self->{out}="$out";
		system("rvbatch.exe rvencode.exe /I $dir\\$in1 /O $out $opt");
	}elsif ($in1 !~ /\w\:\\/ && $out !~ /\w\:\\/) {
		system("rvbatch.exe rvencode.exe /I $dir\\$in1 /O $dir\\$out $opt");
		$self->{out}="$dir\\$out";

	}
} else { $self->{out} = "No Output File"; }

# Check if new file exists, if not, report that error occured
# Need to find a better way to do this, since file may already exist
if (-e "$self->{out}" && $exist != 0) {
		print "\nEncoding complete ($self->{out})\n";
	}else{
		print "\nEncoding Failed. Please chech your files and options\n";
	}
# Make sure we get back to where we started
chdir("$dir");
}# End Encode

#-------------------------------------#


sub Merge {
my ($f,$Pdir,$out,$in,$outD,$foo);
my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it
my @params = params(@_);
foreach $f (@params) {
	if ($f =~ /^-d\s/) {$Pdir = $f; $Pdir =~ s/^-d\s+//; next;}
	if ($f =~ /^-o\s/) { $out = $f; $out =~ s/^-o\s+//; next;}
	if ($f =~ /^-i\s/) { $in = $f; $in =~ s/^-i\s+//; next;}
	if ($f =~ /^-D\s/) { $outD = $f; $outD =~ s/^-D\s+//; next;}
	
}
if (!defined($out) || !defined($in)) {
	croak "Incorrect args for Merge";
}
# Make sure program dir and output dir are set
if (!defined($Pdir)){$Pdir = "c:\\Real\\Encoder\\";} elsif ($Pdir !~ /\\$/) { $Pdir =~ s/$/\\/;}
if (!defined($outD)){$outD = "c:\\Real\\Encoder\\";} elsif ($outD !~ /\\$/) { $outD =~ s/$/\\/;}
$in =~ s/\s//;
$in =~ s/,/ /g; # get rid of commas
chdir("$Pdir");

$foo = `rmmerge $in $outD\\$out`;
print $foo;
chdir("$dir");
}


#-------------------------------------#


sub MergeD {
# No command line options supported yet. Only merging of files.
my ($self) = shift;
my ($in1,$in2,$out) = @_;
my @files;
push(@files,$in1);
push(@files,$in2);
my ($ext1,$ext2,$ext3);
$self->{mergeOk} = 1; 

my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it

# Make sure file extensions are ok
if ($in1 !~ /.(rm|ra)/g) {
		print "$in1 is an invalid file format";# $self->{mergeOk} = 0;
	}elsif ($in2 !~ /\.(rm|ra)/) {
		print "$in2 is an invalid file format";# $self->{mergeOk} = 0;
	}elsif ($out !~ /\.(rm|ra)/) {
		print "$out has an invalid file extension";# $self->{mergeOk} = 0;
}

if ($self->{mergeOk} == 1) {
	$self->{mergeOk} = files_exist(@files);
}

	chdir("$self->{'rootDir'}");	
# Did person put in full path?
	if ($in1 =~ /\w\:\\/ && $in2 =~ /\w\:\\/ && $out =~ /\w\:\\/) {
		$self->{mergerOut}="$out";
		system("rmmerge $in1 $in2 $out");

	}elsif ($in1 =~ /\w:\\/ && $in2 =~ /\w\:\\/ && $out !~ /\w\:\\/) {
		$self->{mergerOut}="$dir\\$out";
		system("rmmerge $in1 $in2 $dir\\$out");

	}elsif ($in1 !~ /\w\:\\/ && $in2 !~ /\w\:\\/ && $out =~ /\w\:\\/) {
		$self->{mergerOut}="$out";
		system("rmmerge $dir\\$in1 $dir\\$in2 $out");

	}elsif ($in1 !~ /\w\:\\/ && $in2 =~ /\w\:\\/ && $out !~ /\w\:\\/) {
		system("rmmerge $dir\\$in1 $in2 $dir\\$out");
		$self->{mergerOut}="$dir\\$out";

	}elsif ($in1 =~ /\w\:\\/ && $in2 !~ /\w\:\\/ && $out =~ /\w\:\\/) {
		system("rmmerge $in1 $dir\\$in2 $out");
		$self->{mergerOut}="$out";

	}elsif ($in1 !~ /\w\:\\/ && $in2 =~ /\w\:\\/ && $out =~ /\w\:\\/) {
		system("rmmerge $dir\\$in1 $in2 $out");
		$self->{mergerOut}="$out";

	}elsif ($in1 =~ /\w\:\\/ && $in2 !~ /\w\:\\/ && $out !~ /\w\:\\/) {
		system("rmmerge $in1 $dir\\$in2 $dir\\$out");
		$self->{mergerOut}="$dir\\$out";

	}elsif ($in1 !~ /\w\:\\/ && $in2 !~ /\w\:\\/ && $out !~ /\w\:\\/) {
		system("rmmerge $dir\\$in1 $dir\\$in2 $dir\\$out");
		$self->{mergerOut}="$dir\\$out";

	}
print " with merge.\n";
chdir("$dir");

} #end Merge

#-------------------------------------#

sub Edit_Text {
my ($self) = shift;
my ($out) = shift;
if ($out !~ /\.r\w$/) { croak "Invalid output file for Edit_Text";}
my $in = $self->{out};
my (@params) = params(@_);
my ($p,$str,$tittle,$auth,$copy,$comm,$foo);
my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it

foreach $p (@params) {
	if ($p =~ /^-t\s/) { $tittle = $p; $tittle =~ s/\s+(.*)$/ \"$1\"/g; next;}
	if ($p =~ /^-a\s/) { $auth = $p; $auth =~ s/\s+(.*)$/ \"$1\"/g; next;}
	if ($p =~ /^-c\s/) { $copy = $p; $copy =~ s/\s+(.*)$/ \"$1\"/g; next;}
	if ($p =~ /^-C\s/) { $comm = $p; $comm =~ s/\s+(.*)$/ \"$1\"/g; next;}
}
if (!defined($tittle)) {$tittle = "";}
if (!defined($auth)) {$auth = "";}
if (!defined($copy)) {$copy = "";}
if (!defined($comm)) {$comm = "";}
$str = "$tittle $auth $copy $comm";

chdir("$self->{rootDir}");
$foo = `rmedit -i $in -o $out $str`;
if ($foo eq "") {
	print "Text_Edit complete\n";
}else{
	croak $foo;
}
$self->{out} = $out;
chdir("$dir");
} # end Edit_Text

#-------------------------------------#

sub Edit_Flags {
my ($self) = shift;
my ($out) = shift;
if ($out !~ /\.r\w$/) { croak "Invalid output file for Edit_Flags";}
my $in = $self->{out};
my (@params) = params(@_);
my ($p,$str,$r,$b,$pram,$foo,$bar,$baz);
my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it

foreach $p (@params) {
	if ($p =~ /^-r\s/) { if ($p=~/(on|off)/i) {$baz=uc($1); $p=~s/$baz/$baz/i;} $r=$p; next;}
	if ($p =~ /^-b\s/) { if ($p=~/(on|off)/i) {$baz=uc($1); $p=~s/$baz/$baz/i;} $b=$p; next;}
	if ($p =~ /^-p\s/) { if ($p=~/(on|off)/i) {$baz=uc($1); $p=~s/$baz/$baz/i;} $pram=$p; next;}
}
if (!defined($r)) {$r = "";}
if (!defined($b)) {$b = "";}
if (!defined($pram)) {$pram = "";}

$str = "$r $b $pram";
chdir("$self->{rootDir}");
$foo = `rmedit -i $in -o $out $str`;
if ($foo eq "") {
	print "Edit_Flags complete\n";
}else{
	croak "Invalid parameters";
}

$self->{out} = $out;
chdir("$dir");
} # end Edit_Flags

#-------------------------------------#

sub Edit_Stream {
my ($self) = shift;
my ($out) = shift;
if ($out !~ /\.r\w$/) { croak "Invalid output file for Edit_Stream";}
my $in = $self->{out};
my (@params) = params(@_);
my ($p,$str,$S,$m,$s,$foo);
my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it

foreach $p (@params) {
	if ($p =~ /^-s\s/) { $s=$p; $s =~ s/\s+(.*)$/ \"$1\"/g; next;}
	if ($p =~ /^-m\s/) { $m=$p; $m =~ s/\s+(.*)$/ \"$1\"/g; next;}
	if ($p =~ /^-S\s/) { $S=$p; next;}
}
if (!defined($s)) {$s = "";}
if (!defined($m)) {$m = "";}
if (!defined($S) || $S !~ /(0|1)/) {croak "Need to identify a stream to edit";}

$str = "$S $m $s";
chdir("$self->{rootDir}");
$foo = `rmedit -i $in -o $out $str`;

if ($foo eq "") {
	print "Edit_Stream complete\n";
}else{
	croak "Invalid parameters";
}

$self->{out} = $out;
chdir("$dir");
} # end Edit_Stream


#-------------------------------------#

sub Edit_Dump {
my ($self) = shift;
my $out = $self->{out};
my ($foo);
my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it

chdir("$self->{rootDir}");
$foo = `rmedit -i $out`;
print $foo;

chdir("$dir");
}

#-------------------------------------#

sub Dump {
my ($self) = shift;
my ($out) = shift;
my ($line);
my $dir = Cwd::getcwd();
$dir =~ s/\//\\/g; #Make sure Windows likes it

chdir("$self->{rootDir}");
if ($out =~ /\w\:\\/) {
	system("rmdump.exe -i $self->{out} -o $out");
}else{
	system("rmdump.exe -i $self->{out} -o $dir\\$out");
}
# Let's replace carriage returns with newlines
open(FILE,"$out");
my @lines=<FILE>;
close FILE;
open(FILE,">$out");
foreach $line (@lines) {
	$line =~ s/\r/\n/g;
	print FILE $line;
}
close FILE;
print "Dump of $self->{out} complete and sent to $out.\n";
chdir("$dir");
} # end Dump

#-------------------------------------#

sub Cut {
my ($self) = shift;
my @params = params(@_);
my ($str); my ($d);
my $dir = Cwd::getcwd();

$dir =~ s/\//\\/g; #Make sure Windows likes it
chdir("$self->{rootDir}");
foreach $d (@params) {
	$str .= " " . $d;
}

my $too = `rmcut $str`;
if ($too ne "") { #error?
	print $too . "\n";
}
chdir("$dir");
exit;

} # end Cut


#-------------------------------------#

sub params {
my (@vals,$value,$name,$foo);
my ($a,$b);
my @array;
my %hash = @_;

foreach $a (sort keys %hash) {
	$b = $a;
	if (substr($a,0,1) ne '-') { $b=~s/^/-/;}
		if ($hash{$a} !~ /(^\s+|^$)/) {
			push(@array,"$b $hash{$a}");
		}
		
}
return @array;
	   
} # end params

#-------------------------------------#

sub files_exist {
my (@files) = @_;
# Do input files exist?
my $dir = Cwd::getcwd();
my ($file);
$dir =~ s/\//\\/g; #Make sure Windows likes it
my ($exist)=1;
# Check that input file exists before continuing

foreach $file (@files) {
	if ($file =~ /\w\:\\/) {
		if (!(-e "$file")) {
			print "$file does not exist\n"; $exist = 0;
		}
	}else {
		if (!(-e "$dir\\$file")) {
			print "$file does not exist\n"; $exist = 0;
		}
	}
}

return $exist;

} #end files_exist

1;

__END__

=head1 NAME

Real::Encode - Perl interaction with Progressive Networks ReadEncoder(tm).

=head1 SYNOPSIS



	
	# use it
	use Real::Encode;
	or
	use Real::Encode qw(Merge Set_File); # to use all methods and functions

	# create the objects
	$foo = new Real::Encode;
	$bar = new Real::Encode("path-to-Real-dir");

	# Define current outfile (explained later)
	$bar->Set_File("path-to-file");

	# Encode a file
	$foo->Encode(INFILE, OUTFILE, [Params]);
		
	# Merge 2 files
	Merge([Params]);
	
	# Edit text info within file
	$foo->Edit_Text(OUTFILE, [Params]);

	# Edit flag info within file
	$foo->Edit_Flags(OUTFILE, [Params]);

	# Edit stream info within file
	$foo->Edit_Stream(OUTFILE, [Params]);

	# Dump editing info (don't need to edit before using this)
	$foo->Edit_Dump;

	# Dump of file
	$foo->Dump(OUTFILE);

	# Cut segment from file
	$foo->Cut([Params]);


=head1 DESCRIPTION

This module allows for interaction with the RealEncoder, and thus the manipulation
of RealMedia files, and encoding to RealMedia format.

=head1 Installation

	Unzip distribution file.
	run install.bat


=head1 FUNCTIONS

=head2 NOTE:
Make sure you write your paths as x:\\dir\\dir\\etc.. (with the double slashes) so that
the \ is escaped.

=over 5

=item $foo = new Win32::Real::Encode[(path-to-dir)];

	'path-to-dir' is the path to the directory on you machine which contains 
	the encoding executables. You do not need to set this if you used the default
	install and they are in c:\Real\Encoder\ (the default install).

=item $foo->Set_File("path-to-file");

	This would be used on either of 2 cases.
		1) You are not starting off by encoding a file (object). or
		2) You wish to reset the current OUTFILE path during your script.

	Every time you do something with your object, it stores what the last outfile was, which
	is uses as your most current file. When you encode, it sets this to begin with, but when
	you do not start by encoding, you will want to set it, so other fucntions, like the Edit_* 
	functions, know what file to use. If you wish to print out your current outfile, you can 
	do so by:
	print $foo->{out};

=item $foo->Encode(INFILE,OUTFILE,[Params]);

	This takes a multimedia file, with the proper format (.wav, .avi, etc..) and encodes it
	into a RealMedia file (.rm). INFILE will be your multimedia file, and OUTFILE will be the 
	name you wish your encoded file to have. OUTFILE must have the proper extention (.rm, .ra).
	The parameters are the same that you would use for encoding from the command line. Options
	are given as such:
	
	$foo->Encode("foobar.wav",
		     "foobar-out.rm",
		     "-A" => "dnet 1",
	             "-F"  => "optimal",
	             "-B" => 40,
	             "-T" => "My Super Duper Title",
	             "-U" => "Kevin",
	             "-C" => "1998 Foobar Productions",
		    );

	A list of options and what the mean is below:

=head2 Encode Options

NOTE: This is taken from Progressive Networks help. To get a copy of this, type
	rvbatch rvencode.exe /?
      in your Encoder directory.
Options: ( defaults in parenthesis )

=over 1

	/I	infile		- Input File
	/O	outfile or dir	- Output File Name or Directory	( infile.rm or dir\YYYYMMDDHHMMSS.rm )
	/L			- Use Live Input		( ignores /I )
	/S	"server[:port]/file" - Server Name, Port and File	( port defaults to 7070 )
	/W	password	- Server Password
	/D	hhh:mm:ss	- Maximum Encoding Duration	( continuous )
	/A	audio codec tag	- Audio Codec			( sipr 1 )
	/V	video codec num	- Video Codec			( 0 )
	/F	framerate	- Frame Rate 0-15 or optimal	( optimal )
				(Note: Optimal available for RealVideo (Standard) only)
	/B	Kbps		- Total Kbps for clip 1 - 500	( 100 )
	/N	index		- Encoding Speed range 1 to 5	( 1 )
			  where 1 = Normal, 5 = fastest
			  Fastest will decrease quality
	/M	index		- Optimal Framerate Bias	( 2 )
				1 = Sharpest Image
				2 = Normal
				3 = Smoothest Motion
			  1 will lower frame rate, 
			  3 will lower quality
	/T	title		- Clip Title
	/U	author		- Clip Author
	/C	copyright	- Clip Copyright
	/K	boolean		- Enable Mobile Play 0-1	( 0 )
	/R	boolean		- Enable Selective Record 0-1	( 0 )
	/X	boolean		- Enable Audio Encoding 0-1	( 1 )
	/Y	boolean		- Enable Video Encoding 0-1	( 1 )
	/Z	l,t,w,h		- Set Cropping Values : Left,Top,Width,Height (0,0,0,0)
	/?	Display this help information

Audio Codecs:

	sipr 0	  6500 bps	6.5 Kbps Voice
	sipr 1	  8500 bps	8.5 Kbps Voice
	sipr 2	  5000 bps	5 Kbps Voice
	sipr 3	 16000 bps	16 Kbps Voice - Wideband
	dnet 0	 16000 bps	16 Kbps Music - Low Response
	dnet 1	 16000 bps	16 Kbps Music - Medium Response
	dnet 2	 16000 bps	16 Kbps Music - High Response
	dnet 3	 20000 bps	20 Kbps Music Stereo
	dnet 4	 40000 bps	40 Kbps Music Mono
	dnet 5	 40000 bps	40 Kbps Music Stereo
	dnet 6	 80000 bps	80 Kbps Music Mono
	dnet 7	 80000 bps	80 Kbps Music Stereo
	dnet 8	  8000 bps	8 Kbps Music
	dnet 9	 12000 bps	12 Kbps Music
	dnet 10	 32000 bps	32 Kbps Music Mono
	dnet 11	 32000 bps	32 Kbps Music Stereo
	28_8 0	 15200 bps	15.2 Kbps Voice

Video Codecs:

	0	RealVideo (Standard)
	1	RealVideo (Fractal)

RVEncode.log is written to the current working directory. (i.e., the dir with the executable)

=back 

=item Merge([Params]);

	This will merge two files together. To merge files, you want to merge a RealVideo file
	with a RealAudio file. This method is called as:

	  Merge("-d" => "c:\\foo",
		"-i" => "d:\\gsperl\\dev\\real\\drums.rm, d:\\gsperl\\dev\\real\\tada.rm",
		"-o" => "foo-out.rm",
		"-D" => "d:\\gsperl\\dev\\real\\",
	   );

	-d => Program directory. This is the path to where your executables are. If omitted
	      c:\Real\Encoder\ is used.
	
	-i => Your two files to merge.

	-o => The output file.

	-D => The output directory.

	You can merge together two objects as such:
		Merge->("-d" => "c:\\foo",
			"-i" => "$foo->{out}, $bar->{out}",
			"-o" => "foo-out.rm",
			"-D" => "d:\\gsperl\\dev\\real\\",
		);


=item $foo->Edit_Text(OUTFILE,[Params]);

	This function allows you to edit the author, title, copyright and comment on a file.
	
	$foo->Edit_Text("c:\\foo\\baz-out.rm", #OUTFILE location
		"-t" => "New funky Title",
		"-a" => "New Author",
		"-c" => "New copyright info",
		"-C" => "New Comment",
	);




=item $foo->Edit_Flags(OUTFILE,[Params]);

	This function allows you to edit certain flags on the file. The flags are perfect play mode,
	mobile playback mode, and selective record mode. 

	$foo->Edit_Flags("d:\\foo\\baz2-out.rm",
		"-r" => "on",
		"-b" => "off",
		"-p" => "on",
	);
	
	-r => set/clear selective record (ON|OFF)

	-b => set/clear mobile playback mode (ON|OFF)

	-p => set/clear perfect play mode (ON|OFF)

=item $foo->Edit_Stream(OUTFILE, [Params]);

	This function allows your to edit stream information on a file.

	$foo->Edit_Stream("d:\\foo\\baz3-out.rm",
		"-s" => "New Streamy Name",
		"-m" => "audio/x-pn-realaudio",
		"-S" => "0",
	);

	-s => New stream name

	-m => New mime type for stream

	-S => Which stream (0|1)

=head2 NOTE:

	When you wish to edit the text, flags and stream on a file, the output from each
	(your OUTFILE) will be saved in $foo->{out} and your final edited file will be the
	OUTFILE for the last edit function you call.

=item $foo->Edit_Dump;

	This will print out the current text, flag and stream info for $foo.

=item $foo->Dump(OUTFILE);

	This will give you a complete dump of $foo. OUTFILE should (could) be a text file.

=item $foo->Cut([Params]);

	This function will cut out a segment of a file as specified in the parameters.

	$foo->Cut("-i" => "foo.rm",
		"-o" => "outt.rm",
		"-S" => "1",
		"-s" => "1.0"
	);

	-i => INput file

	-o => Output file

	-S => Stream (0|1)

	-s => Start time in Days:Hours:Minutes:Seconds.Milliseconds ... This will default to
		the begining of the file.

	-e => End time in Days:Hours:Minutes:Seconds.Milliseconds ... defaults to the end of
		the start+input length

=back

=head1 Version

	0.04Beta

=head1 Knows Issues

=over 5

=item 1
	It is possible that some errors are not yet handled in the best way, if you find any
	please let me know.


=head1 REVISION HISTORY

v. 0.4 (9/14/98) - Original Release to CPAN

v. 0.5 (9/30/98) - No real technical changes. Just some cleaning from 0.4


=head1 AUTHOR INFORMATION

Copyright 1998, Kevin Meltzer.  All rights reserved.  It may
be used and modified freely, but I do request that this copyright
notice remain attached to the file.  You may modify this module as you
wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports and comments to:
kmeltz@cris.com

The author makes no warranties, promises, or gaurentees of this software. As with all
software, use at your own risk.

=head2 Copyright Info

This module is Copyright 1998, Kevin Meltzer. All rights reserved. Any documentation from
Progrssive Networks and and trademard of Progressive Networks Real products are copyright
by Progressive Networks (http://www.real.com). They had no part in the creation of this version
of this module.


=cut
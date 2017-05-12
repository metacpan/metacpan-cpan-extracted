package Tivoli::Logging;

# RHase
# www.Muc-Net.de
# sys.m.TEC GmbH
# www.sysmtec.de

our(@ISA, @EXPORT, $VERSION, $Fileparse_fstype, $Fileparse_igncase);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($G_LOGDO @G_FHs LogOpenNew LogOpenAppend LogInfo LogWarn LogFail LogFat LogsClose);

$VERSION = '0.02';


################################################################################################

=pod

=head1 NAME

	Tivoli::Logging - Perl Extension for Tivoli

=head1 SYNOPSIS

	use Tivoli::Logging;


=head1 VERSION

	v0.02

=head1 License

	Copyright (c) 2001 Robert Hase.
	All rights reserved.
	This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 DESCRIPTION

=over

	This Package will handle about everything you may need for Logging.
	If anything has been left out, please contact me at
	tivoli.rhase@muc-net.de
	so it can be added.
	
	Prints formated Logging-Informations to STDOUT and if wanted to one or more Files.
	Supports an unlimited Numbers of open Files (dynamical Filehandlers) and
	prints the Type of the STDOUT-Information in Color (requires ANSI).

	Should be the first loaded Tivoli-Package.

=back

=head2 DETAILS

=over

	If Parameter L<File-Handler> = STDOUT the Logging-Message will only be sended to Standard-Out

=item * Types of Logging and Colors

	ROUTINE		TYPE		FOREGROUND/BACKGROUND
	-----------------------------------------------------
	LogInfo		(Info)		black/green
	LogWarn		(Warning)	black/yellow
	LogFail		(Failed)	black/red
	LogFat		(Fatal)		white/black

=item * Loggings to STDOUT

	Prints Logging-Informations in the following Format:
	TYPE dd.mm.yyyy hh:mm:ss MSG

=item * SAMPLE

	&LogInfo(STDOUT, "This is an Information-Message only to Standard-Out");

=item * OUTPUT

	INFO 23.07.2001 This is an Information-Message only to Standard-Out

=item * Logging to Files

	Prints Logging-Informations in the following Format:
	yyyy-mm-dd hh:mm:ss TYPE MSG

=item * SAMPLE

	&LogInfo($G_LOGFILE1, "This is an Information-Message to Standard-Out AND Logfile $G_LOGFILE1");

=item * OUTPUT

        STDOUT: INFO 23.07.2001 13:27:42 This is an Information-Message to Standard-Out AND Logfile $G_LOGFILE1
	FILE  : 2001-07-23 13:27:42 INFO This is an Information-Message to Standard-Out AND Logfile $G_LOGFILE1

=back

=head2 Routines

=over

	Details to the Logging-Functionality

=back

=head3 LogOpenNew

=over

=item * CALL

	$FileHandle = &LogOpenNew(<PATH/FILENAME>);

=item * DESCRIPTION

	- opens a new Log-File
	- prints L<INFO-Message> to Display and L<$FileHandle>
	- returns the File-Handler

=back

=head3 LogOpenAppend

=over

=item * CALL

        $FileHandle = &LogOpenAppend(<PATH/FILENAME>);

=item * DESCRIPTION

	- opens PATH/FILENAME for Append
        - prints L<INFO-Message> to Display and $FileHandle
        - returns the File-Handler

=back

=head3 LogInfo

=over

=item * CALL

	&LogInfo($FileHandle, <MSG>);

=item * DESCRIPTION

	- prints INFO-Message to Display
	- prints INFO-Message to $FileHandle if $FileHandle not 0 

=back

=head3 LogWarn

=over

=item * CALL

	&LogWarn($FileHandle, <MSG>);

=item * DESCRIPTION

        - prints WARN-Message to Display
        - prints WARN-Message to $FileHandle if $FileHandle not 0

=back

=head3 LogFail

=over

=item * CALL

        &LogFail($FileHandle, <MSG>);

=item * DESCRIPTION

        - prints FAILED-Message to Display
        - prints FAILED-Message to $FileHandle if $FileHandle not 0

=back

=head3 LogFat

=over

=item * CALL

	&LogFat($FileHandle, <MSG>);

=item * DESCRIPTION

        - prints FATAL-Message to Display
        - prints FATAL-Message to $FileHandle if $FileHandle not 0

=back

=head3 LogClose

=over

=item * CALL

	&LogsClose;

=item * DESCRIPTION

	- prints INFO-Message to Display
        - prints INFO-Message to EVERY $FileHandle if exist
	- close EVERY open (Logging-) File-Handler

=back

=head2 Plattforms and Requirements

=over

	Supported Plattforms and Requirements

=item * Plattforms

	tested on:

	- w32-ix86 (W9x, NT4, Windows 2000)
	- aix4-r1 (AIX 4.3)
	- Linux (Kernel 2.2.x)

=back

=item * Requirements

	requires Perl v5 or higher

=back

=head2 HISTORY

	VERSION		DATE		AUTHOR		WORK
	----------------------------------------------------
	0.01		2001-07-18	RHase		created
	0.02		2001-07-23	RHase		POD-Doku added

=head1 AUTHOR

	Robert Hase
	ID	: RHASE
	eMail	: Tivoli.RHase@Muc-Net.de
	Web	: http://www.Muc-Net.de

=head1 SEE ALSO

	CPAN
	http://www.perl.com

=cut


###############################################################################################


sub LogOpenNew
{
	my($p_logfile) = $_[0];
	my($l_random);
	chomp($l_date = `date +"%d.%m.%Y %H:%M"`);
	chomp($l_datefile = `date +"%Y-%m-%d %H:%M:%S"`);
	$l_random = 42;
	$l_random += int(rand($$*$l_random/2*5)) + $$;
	$l_random += int(rand($$*$l_random/2*5)) + $$;
	if(open($l_random, ">$p_logfile") == 0)
	{
		print "\e[30;41mFAILURE\e[0m $l_date Function LogOpenNew $p_logfile $!\n";
		return(0);
	}
	print "\e[30;42m INFO  \e[0m $l_date Function LogOpenNew $p_logfile open\n";
        print $l_random "$l_datefile INFO Function LogOpenNew $p_logfile (FH $l_random) open\n";
	push(@G_FHs, $l_random);
	return($l_random);
}

sub LogOpenAppend
{
        my($p_logfile) = $_[0];
        my($l_random, $l_date);
	chomp($l_date = `date +"%d.%m.%Y %H:%M"`);
	chomp($l_datefile = `date +"%Y-%m-%d %H:%M:%S"`);
        $l_random = 42;
        $l_random += int(rand($$*$l_random/2*5)) + $$;
        $l_random += int(rand($$*$l_random/2*5)) + $$;
        if(open($l_random, ">>$p_logfile") == 0)
        {
        	print "\e[30;41mFAILURE\e[0m $l_date Function LogOpenAppend $p_logfile $!\n";
 	       	return(0);
        }
	print "\e[30;42m INFO  \e[0m $l_date Function LogOpenAppend $p_logfile open\n";
	print $l_random "$l_datefile INFO Function LogOpenAppend $p_logfile (FH $l_random) open\n";
	push(@G_FHs, $l_random);
        return($l_random);
}

sub LogInfo
{
	# \e[30;42m # BLACK/GREEN

	my($p_fh) = $_[0];
	my($p_msg) = $_[1];
	my($l_date);
	chomp($l_date = `date +"%d.%m.%Y %H:%M"`);
	chomp($l_datefile = `date +"%Y-%m-%d %H:%M:%S"`);
	print "\e[30;42m INFO  \e[0m $l_date $p_msg\n";
	if($p_fh !~ /STDOUT/) {print $p_fh "$l_datefile INFO $p_msg\n";}
}

sub LogWarn
{
	# \e[30;43m # BLACK/YELLOW
        my($p_fh) = $_[0];
        my($p_msg) = $_[1];
        my($l_date);
        chomp($l_date = `date +"%d.%m.%Y %H:%M"`);
	chomp($l_datefile = `date +"%Y-%m-%d %H:%M:%S"`);
        print "\e[30;43mWARNING\e[0m $l_date $p_msg\n";
        if($p_fh !~ /STDOUT/) {print $p_fh "$l_datefile WARNING $p_msg\n";}
}

sub LogFail
{
	# \e[30;41mFAILURE # BLACK/RED
        my($p_fh) = $_[0];
        my($p_msg) = $_[1];
        my($l_date);
        chomp($l_date = `date +"%d.%m.%Y %H:%M"`);
	chomp($l_datefile = `date +"%Y-%m-%d %H:%M:%S"`);
        print "\e[30;41mFAILURE\e[0m $l_date $p_msg\n";
        if($p_fh !~ /STDOUT/) {print $p_fh "$l_datefile FAILURE $p_msg\n";}
}

sub LogFat
{
	# \e[37;40mFATAL # WHITE/BLACK
        my($p_fh) = $_[0];
        my($p_msg) = $_[1];
        my($l_date);
        chomp($l_date = `date +"%d.%m.%Y %H:%M"`);
	chomp($l_datefile = `date +"%Y-%m-%d %H:%M:%S"`);
        print "\e[37;40m FATAL \e[0m $l_date $p_msg\n";
        if($p_fh !~ /STDOUT/) {print $p_fh "$l_datefile FATAL $p_msg\n";}
}

sub LogsClose
{
	foreach (@G_FHs)
	{
		&LogInfo($_, "$_ closing");
		if(close($_) == 0) {&LogFail($_, "Can't close $_ : $!");}
	}
}

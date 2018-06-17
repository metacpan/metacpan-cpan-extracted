#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    02/06/2017                                                             #
#    Revised: 05/24/2017                                                             #
#    UMLS Similarity Word2Vec Package Utility Module                                 #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                Utility functions for the Word2vec::Interface package.              #
#                                                                                    #
######################################################################################


package Word2vec::Util;

use strict;
use warnings;

# Standard CPAN Module(s)
use Cwd;


use vars qw($VERSION);

$VERSION = '0.02';


######################################################################################
#    Constructor
######################################################################################

BEGIN
{
    # CONSTRUCTOR : DO SOMETHING HERE
}


######################################################################################
#    Deconstructor
######################################################################################

END
{
    # DECONSTRUCTOR : DO SOMETHING HERE
}


######################################################################################
#    new Class Operator
######################################################################################

sub new
{
    my $class = shift;
    my $self = {
        # Private Member Variables
        _debugLog               => shift,               # Boolean (Binary): 0 = False, 1 = True
        _writeLog               => shift,               # Boolean (Binary): 0 = False, 1 = True
    };

    # Set Variable Default If Not Defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );

    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:utf8', 'UtilLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log file
    }
    else
    {
        $self->{ _fileHandle } = undef;
    }

    bless $self, $class;

    $self->WriteLog( "New - Debug On" );

    return $self;
}


######################################################################################
#    DESTROY
######################################################################################

sub DESTROY
{
    my ( $self ) = @_;

    # Close FileHandle
    close( $self->{ _fileHandle } ) if( $self->{ _fileHandle } );
}


######################################################################################
#    Module Functions
######################################################################################

sub IsFileOrDirectory
{
    my ( $self, $path ) = @_;

    # Check(s)
    return "unknown" if !defined( $path );
    return "unknown" if !( -e $path );

    return "file"    if ( -f $path );
    return "dir"     if ( -d $path );
}

sub IsWordOrCUITerm
{
    my ( $self, $term ) = @_;
    
    # Check(s)
    $self->WriteLog( "IsFileWordOrCUIFile - Error: String Term Not Defined" ) if !defined( $term );
    return undef if !defined( $term );
    
    $self->WriteLog( "IsFileWordOrCUIFile - Error: String Term Eq Empty String" ) if ( $term eq "" );
    return undef if ( $term eq "" );
    
    # Perform Check
    $term = lc( $term );
    my @terms = split( 'c', $term );
    
    # Return Word Term If There Are Not Two Elements After Splitting
    return "word" if( @terms != 2 );
    
    # If $term Is CUI, Then First Element Should Be Empty String
    return "word" if ( $terms[0] ne "" );
    
    # Remove Numbers From Second Element
    $terms[1] =~ s/[0-9]//g;
    
    # If $term Is CUI, Then After Removing All Number From Second Element An Empty String Is All That Is Left
    return "word" if ( $terms[1] ne "" );
    
    return "cui";
}

sub GetFilesInDirectory
{
    my ( $self, $directoryPath, $fileTagStr ) = @_;
    
    # Check(s)
    $self->WriteLog( "GetFilesInDirectory - Error: Directory Path Not Defined" ) if !defined( $directoryPath );
    $self->WriteLog( "GetFilesInDirectory - Error: File Tag String Not Defined" ) if !defined( $fileTagStr );
    $self->WriteLog( "GetFilesInDirectory - Error: Directory Path Is Empty / Empty String" ) if defined( $directoryPath ) && $directoryPath eq "";
    $self->WriteLog( "GetFilesInDirectory - Error: File Tag String Is Empty / Empty String" ) if defined( $fileTagStr ) && $fileTagStr eq "";
    $self->WriteLog( "GetFilesInDirectory - Error: Directory Path Does Not Exist" ) if !( -e "$directoryPath" );
    return undef if !defined( $directoryPath ) || !defined( $fileTagStr );
    return undef if defined( $directoryPath ) && $directoryPath eq "";
    return undef if defined( $fileTagStr ) && $fileTagStr eq "";
    return undef if !( -e "$directoryPath" );
    
    
    # Open Directory
    my $result = 0;
    my $listOfFilesStr = "";
    
    opendir( my $directoryHandle, "$directoryPath" ) or $result = -1;
    $self->WriteLog( "GetFilesInDirectory - Directory Opened Successfully" ) if $result == 0;
    $self->WriteLog( "GetFilesInDirectory - Error: Directory Could Not Be Opened" ) if $result == -1;
    return undef if $result == -1;
    
    for my $file ( readdir( $directoryHandle ) )
    {
        $listOfFilesStr .= "$file " if ( index( $file, "$fileTagStr" ) != -1 );
    }

    closedir( $directoryHandle );
    undef( $directoryHandle );
    
    $self->WriteLog( "GetFilesInDirectory - Found Files: $listOfFilesStr" ) if $listOfFilesStr ne "";
    
    return $listOfFilesStr;
}

sub GetOSType
{
    my ( $self ) = @_;
    return $^O;
}

######################################################################################
#    Accessor Functions
######################################################################################

sub GetDebugLog
{
    my ( $self ) = @_;
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    return $self->{ _debugLog };
}

sub GetWriteLog
{
    my ( $self ) = @_;
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    return $self->{ _writeLog };
}

sub GetFileHandle
{
    my ( $self ) = @_;
    $self->{ _fileHandle } = undef if !defined ( $self->{ _fileHandle } );
    return $self->{ _fileHandle };
}


######################################################################################
#    Debug Functions
######################################################################################

sub GetTime
{
    my ( $self ) = @_;
    my( $sec, $min, $hour ) = localtime();

    if( $hour < 10 )
    {
        $hour = "0$hour";
    }

    if( $min < 10 )
    {
        $min = "0$min";
    }

    if( $sec < 10 )
    {
        $sec = "0$sec";
    }

    return "$hour:$min:$sec";
}

sub GetDate
{
    my ( $self ) = @_;
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();

    $mon += 1;
    $year += 1900;

    return "$mon/$mday/$year";
}

sub WriteLog
{
    my ( $self ) = shift;
    my $string = shift;
    my $printNewLine = shift;

    return if !defined ( $string );
    $printNewLine = 1 if !defined ( $printNewLine );


    if( $self->GetDebugLog() )
    {
        if( ref ( $self ) ne "Word2vec::Util" )
        {
            print( GetDate() . " " . GetTime() . " - Util: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - Util::$string";
        print "\n" if( $printNewLine != 0 );
    }

    if( $self->GetWriteLog() )
    {
        if( ref ( $self ) ne "Word2vec::Util" )
        {
            print( GetDate() . " " . GetTime() . " - Util: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        my $fileHandle = $self->GetFileHandle();

        if( defined( $fileHandle ) )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - Util::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Util - Word2vec-Interface Utility Module.

=head1 SYNOPSIS

 use Word2vec::Util;

 my $util = Word2vec::Util->new();

 my $result = $util->IsFileOrDirectory( "../samples/stoplist" );

 print( "Path Type Is A File\n" ) if $result eq "file";
 print( "Path Type Is A Directory\n" ) if $result eq "dir";
 print( "Path Type Is Unknown\n" ) if $result eq "unknown";

 undef( $util );

=head1 DESCRIPTION

Word2vec::Util is a module of utility functions for the Word2vec::Interface package.

=head2 Main Functions

=head3 new

Description:

 Returns a new "Word2vec::Util" module object.

 Note: Specifying no parameters implies default options.

 Default Parameters:
    debugLog                    = 0
    writeLog                    = 0

Input:

 $debugLog                    -> Instructs module to print debug statements to the console. (1 = True / 0 = False)
 $writeLog                    -> Instructs module to print debug statements to a log file. (1 = True / 0 = False)

Output:

 Word2vec::Util object.

Example:

 use Word2vec::Util;
 
 my $util = Word2vec::Util->new();
 
 undef( $util );

=head3 DESTROY

Description:

 Removes Word2vec::Util object from memory.

Input:

 None

Output:

 None

Example:

 See above example for "new" function.

 Note: Destroy function is also automatically called during global destruction when exiting the program.

=head3 IsFileOrDirectory

Description:

 Given a path, returns a string specifying whether this path represents a file or directory.

Input:

 $path   -> String representing path to check

Output:

 $string -> Returns "file", "dir" or "unknown".

Example:

 use Word2vec::Util;

 my $util = Word2vec::Util->new();

 my $result = $util->IsFileOrDirectory( "../samples/stoplist" );

 print( "Path Type Is A File\n" ) if $result eq "file";
 print( "Path Type Is A Directory\n" ) if $result eq "dir";
 print( "Path Type Is Unknown\n" ) if $result eq "unknown";

 undef( $util );

=head3 IsWordOrCUITerm

Description:

 Checks whether the passed string argument is word or CUI term.

Input:

 $string   -> Word or CUI string term

Output:

 $string -> Returns "cui", "word" or undef

Example:

 use Word2vec::Util;

 my $util = Word2vec::Util->new();

 my $result = $util->IsWordOrCUITerm( "Cookie" );

 print( "Passed String Argument Term Type: \"$result\"\n" ) if defined( $result );
 print( "Cannot Determine String Argument Term Type\n" )    if !defined( $result );
 
 my $result = $util->IsWordOrCUITerm( "C08132016" );
 
 print( "Passed String Argument Term Type: \"$result\"\n" ) if defined( $result );
 print( "Cannot Determine String Argument Term Type\n" )    if !defined( $result );

 undef( $util );

=head3 GetFilesInDirectory

Description:

 Given a path and file tag string, returns a string of files consisting of the file tag string in the specified path.

Input:

 $path    -> String representing path
 $fileTag -> String consisting of file tag to fetch.

Output:

 $string  -> Returns string of file names consisting of $fileTag.

Example:

 use Word2vec::Util;

 my $util = Word2vec::Util->new();

 # Looks in specified path for files including ".sval" in their file name.
 my $result = $util->GetFilesInDirectory( "../samples/", ".sval" );

 print( "Found File Name(s): $result\n" ) if defined( $result );

 undef( $util );

=head3 GetOSType

Description:

 Returns (string) operating system type.

Input:

 None

Output:

 $string -> Operating System String

Example:

 use Word2vec::Util;

 my $util = Word2vec::Util->new();

 my $result = $util->GetOSType();

 print( "Current OS Type: $result\n" ) if defined( $result );

 undef( $util );

=head2 Accessor Functions

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Util object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Util;

 my $util = Word2vec::Util->new()
 my $debugLog = $util->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;


 undef( $util );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Util object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Util;

 my $util = Word2vec::Util->new();
 my $writeLog = $util->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $util );

=head2 Debug Functions

=head3 WriteLog

Description:

 Prints passed string parameter to the console, log file or both depending on user options.

 Note: printNewLine parameter prints a new line character following the string if the parameter
 is undefined and does not if parameter is 0.

Input:

 $string -> String to print to the console/log file.
 $value  -> 0 = Do not print newline character after string, all else prints new line character including 'undef'.

Output:

 None

Example:

 use Word2vec::Util:

 my $util = Word2vec::Util->new();
 $util->WriteLog( "Hello World" );

 undef( $util );

=head1 Author

 Clint Cuffy, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2016

 Bridget T McInnes, Virginia Commonwealth University
 btmcinnes at vcu dot edu

 Clint Cuffy, Virginia Commonwealth University
 cuffyca at vcu dot edu

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/PHtml.pm,v $
#            $Revision: 1.7 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: 
#
#          Description: 
#
#           Directions:
#
#           Depends on: 
#
#       Copyright (C) 1996-2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://www.gnu.org/copyleft/gpl.html
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#############################################################################
#
#
#       REVISION HISTORY:
#
#       $Log: PHtml.pm,v $
#       Revision 1.7  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.5  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.4  2002/01/23 19:16:48  bhenry
#       Improved handling of passed parms
#
#       Revision 1.3  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.2  2002/01/18 19:24:50  bhenry
#       Warning Fixes
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::PHtml;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use FileHandle;

our %PHTML_CACHE;
our $VERBOSE = $ENV{VERBOSE};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    my ($fileName,$docRoot) = @_;

    &log("Setting up new PHtml object for '$fileName'") if ($VERBOSE);

    $self->{fileName} = $fileName;

    $self;
}


#-------------------------------------------------------------------------------
# Function:     findObj
# Description:  Check the passed value to see if it's a reference to a PHtml object.
#               If not, then it must be a filename, so lookup it's object in the
#               global cache, or create one for it.
# Input Parms:
# Output Parms: 
#-------------------------------------------------------------------------------
sub findObj
{
    my ($obj) = @_;
    my $sQuote = '"';
    my $dQuote = "'";

    # If $obj is not a reference, then it must be a filename    
    if (ref($obj) ne 'PHtml')
    {
        # If so, try to look it up in the global cache
        my $fileName = $obj;

        &log("Searching for PHtml object for '$fileName'") if ($VERBOSE > 1);

        # Strip off any double or single quotes
        $fileName =~ s/[$sQuote$dQuote]//g;

        # Try to lookup the fileName to see if there's an existing object.
        $obj = $PHTML_CACHE{$fileName};

        # Otherwise, just allocate a new object for it.        
        if (! defined $obj)
        {
            $obj = new VBTK::PHtml ($fileName);
            $PHTML_CACHE{$fileName} = $obj;
        }
    }

    ($obj);
}

#-------------------------------------------------------------------------------
# Function:     generateHtml
# Description:  Read in file, parse out perl, and produce HTML.  Note that all 
#               variables in this subroutine start with '_' so as not to conflict
#               with variables in the parsedContent which are eval'd in the scope
#               of this subroutine.  The base directory must be passed in so that
#               we know where to find files referenced in '#include' statements 
#               in the phmtl.
# Input Parms:  Target or object, Base directory of web server
# Output Parms: HTML
#-------------------------------------------------------------------------------
sub generateHtml
{
    my $_obj = shift;
    my $_baseDir = shift;

    # These variables will be accessible from within the PHtml
    my ($_parms,$_conn,$_req) = @_;

    my ($_html,$evalText);

    # Just in case a filename was passed, run it through the finder
    $_obj = &findObj($_obj);            

    &log("Generating PHtml code") if ($VERBOSE > 1);
    $_obj->parseFile($_baseDir);

    # Protect local variables from the eval, but pass along a copy of $_baseDir
    $evalText = "my(\$_baseDir,\$_obj,\$_html,\$evalText);\n\n";

    # Make sure the last thing mentioned in the code is the html accumulator,
    # so that it returns back the html to us.
    $evalText .= $_obj->{parsedContent} . "\n(\$_html);\n";

    # Turn off uninitialized variable warnings temporarily because it's just too
    # annoying to troubleshoot and it's a very minor thing.
    # no warnings 'uninitialized';

    # Now execute the PHtml, unless we're in debug mode    
    if(! defined $_parms->{debugPHtml})
    {
        &log("Executing PHtml code") if ($VERBOSE > 1);
        $_html = eval($evalText);
    }

    # Turn warnings back on.
    # use warnings 'uninitialized';

    # Dump out the code if we had an error, or if we're in debug mode.
    if (($@)||(defined $_parms->{debugPHtml}))
    {
        my $msg = (! $_parms->{debugPHtml}) ? "Error Parsing PHtml - $@" : 
            "Debug mode specified, dumping code";
        &log($msg);
        my $count = 1;
        my $code;

        # Number the lines
        foreach my $row (split(/\n/,$evalText))
        {
            $code .= sprintf("%04d: %s\n",$count++,$row);
        }

        # Convert < and > to html characters.
        $code =~ s/</\&lt\;/g;
        $code =~ s/>/\&gt\;/g;
        return "<HTML><H3>$@</H3><PRE>$code</PRE></HTML>";
    }

    &log("Generated PHtml:\n$_html\n") if ($VERBOSE > 3);
    &log("Generated PHtml") if ($VERBOSE == 3);

    ($_html);            
}

#-------------------------------------------------------------------------------
# Function:     parseFile
# Description:  Read in file and parse out perl and html
# Input Parms:
# Output Parms: Structure containing perl and html
#-------------------------------------------------------------------------------
sub parseFile
{
    my $obj = shift;
    my $baseDir = shift;

    $obj->loadFile() || return 0;

    my $fileContent = $obj->{fileContent};
    my $directory = $obj->{directory};

    my @masterAccum;
    my $mode='html';
    my $LF='"\n"';
    my $pound="#";
    my ($accum,$modeSwitchFlg,$fileName,$childObj,$rcstag,$includeFileName);

    # Escape out any RCS tags so they won't be interpreted
    foreach $rcstag ('source:','revision:','date:')
    {
        grep(s/[^\\]\$($rcstag.*)\$/\\\$$1\\\$/i,@{$fileContent});
    }

    # Step through each line from the file   
    foreach (@{$fileContent})
    {
        $modeSwitchFlg = 0;

        # Watch for #include statements and if found, recurse into the named file
        if(/<!--${pound}include\s+virtual\s*=\s*["'"]?([^"'"\s]+)["'"]?\s*-->/)
        {
            $includeFileName = $1;

            # If include filename is relative, then look in the current objects
            # directory for it.  If it's absolute, then build the path from the
            # base directory.
            if($includeFileName =~ /^\//)
            {
                $includeFileName = $baseDir . $includeFileName;
            }
            else
            {
                $includeFileName = "$directory/$includeFileName";
            }

            &log("Including file '$includeFileName'") if ($VERBOSE > 2);
            $childObj=&findObj($includeFileName);

            $accum .= $`;
            $accum =~ s/\s+$//;
            push(@masterAccum, "\$_html .= qq($accum);\n") if ($accum ne '');
            $accum = '';
            $modeSwitchFlg = 1;

            if($childObj->parseFile($baseDir))
            {
                push(@masterAccum, "\$_html .= \"\\n\";\n");
                push(@masterAccum, $childObj->{parsedContent});
                push(@masterAccum, "\$_html .= \"\\n\";\n");
            }
            else
            {
                push(@masterAccum,
                    "\$_html .= qq(\n<!-- Error, can't find $fileName -->);\n");
            }
        }

        # If we find a perl marker, then switch to perl mode    
        if(/<!--${pound}perl\s?/)
        {
            $accum .= $`;
            $accum =~ s/\s+$//;
            $accum =~ s/\@/\\\@/;
            push(@masterAccum, "\$_html .= qq($accum);\n") if ($accum ne '');
            $mode = 'perl';
            $accum = '';
            $modeSwitchFlg = 1;
        }

        # If we're in perl mode and find an end-of-comment marker, then switch
        # back.
        if(($mode eq 'perl')&&(/-->/))
        {
            $accum .= $`;
            $accum =~ s/<!--${pound}perl //;
            push(@masterAccum, $accum) unless ($accum =~ /^\s*$/);
            $mode = 'html';
            $accum = '';
            $modeSwitchFlg = 1;
        }

        $accum .= ($modeSwitchFlg) ? $' : $_ ;
    }

    # Chop off whitespace on the end of the line and escape out special characters
    $accum =~ s/\s+$//;
    $accum =~ s/([@])/\\$1/;

    # Add whatever's left onto the end of the line
    push(@masterAccum, "\$_html .= qq($accum);\n") unless ($accum =~ /^\s*$/);

    # Now join it all together and store it in the object
    $obj->{parsedContent} = join("\n",@masterAccum);

    (1);
}

#-------------------------------------------------------------------------------
# Function:     loadFile
# Description:  Read in specified file, using a cached copy if nothing has changed
# Input Parms:
# Output Parms: Return value
#-------------------------------------------------------------------------------
sub loadFile
{
    my $obj = shift;
    my $fsize = $obj->{fsize};
    my $mtime = $obj->{mtime};
    my $fileName = $obj->{fileName};

    # Check the size and mtime of the file to see if it has changed.
    &log("Checking size and mtime of '$fileName'") if ($VERBOSE > 2);
    my ($inode,$curFsize,$curMtime) = (stat($fileName))[1,7,9];

    # See if the file really exists.
    if(! defined $inode)
    {
        &error("Invalid file request '$fileName'");
        return 0;
    }

    # If the file exists and the size and mtime haven't changed, then just return
    return 1 if((defined $fsize)&&(defined $mtime)&&
                ($fsize == $curFsize)&&($mtime == $curMtime));

    # Otherwise, open the file, read it in, and store it's contents.
    my $fh = new FileHandle;

    &log("Reading file '$fileName'") if ($VERBOSE);    
    unless($fh->open("$fileName"))
    {
        &error("Cannot open file '$fileName'");
        return 0;
    }

    my @fileContent = <$fh>;

    $fh->close;

    # Store the directory where this file resides.
    if($fileName =~ /^(\S+)\/([^\/\s]+)$/)
    {
        &log("Directory is $1") if ($VERBOSE > 2);
        $obj->{directory} = $1;
    }

    $obj->{fileContent} = \@fileContent;
    $obj->{fsize} = $curFsize;
    $obj->{mtime} = $curMtime;

    (1);
}

#-------------------------------------------------------------------------------
# Function:     dumpParsedContent
# Description:  Dump out the contents of the parsed file
# Input Parms:  
# Output Parms: Return value
#-------------------------------------------------------------------------------
sub dumpParsedContent
{
    my $obj = shift;

    my $parsedContent = $obj->{parsedContent};

    print STDOUT "$parsedContent";

    (0);
}

1;
__END__

=head1 NAME

VBTK::PHtml - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to handle .phtml
files used in the web interface.  Do not try to access this package
directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK::PHttpd|VBTK::PHttpd>

=back

=head1 AUTHOR

Brent Henry, vbtoolkit@yahoo.com

=head1 COPYRIGHT

Copyright (C) 1996-2002 Brent Henry

This program is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public
License as published by the Free Software Foundation available at:
http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut


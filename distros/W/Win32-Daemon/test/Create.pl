#//////////////////////////////////////////////////////////////////////////////
#//
#//  Create.pl
#//  Win32::Daemon Perl extension test script
#//
#//  Copyright (c) 1998-2008 Dave Roth
#//  Courtesy of Roth Consulting
#//  http://www.roth.net/
#//
#//  This file may be copied or modified only under the terms of either 
#//  the Artistic License or the GNU General Public License, which may 
#//  be found in the Perl 5.0 source kit.
#//
#//  2008.03.24  :Date
#//  20080324    :Version
#//////////////////////////////////////////////////////////////////////////////

# Demonstration of a script that registers a Perl script as 
# a Win32 Serice.

use Win32::Daemon; 

my $Script = shift @ARGV || "Callback.pl";
my $ServiceName = shift @ARGV || "PerlTest";

%Hash = (
    name    =>  $ServiceName,
    display =>  'Perl: Test of Win32::Daemon ($ServiceName)',
    path    =>  "\"$^X\" \"" . Win32::GetLongPathName( scalar Win32::GetFullPathName( ".\\$Script" ) ) . "\"",
    user    =>  '',
    password =>  '',
);

if( Win32::Daemon::CreateService( \%Hash ) )
{
    print "Successfully added.\n";
}
else
{
    print "Failed to add service: " . GetError() . "\n";
}



print "finished.\n";

sub DumpError
{
    print GetError(), "\n";
}

sub GetError
{
    return( Win32::FormatMessage( Win32::Daemon::GetLastError() ) );
}

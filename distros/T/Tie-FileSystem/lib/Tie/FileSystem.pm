#-----------------------------------------------------------------------
# Copyright 2003-2007 Vadim V. Kouevda,
#                     "KAITS, Inc."                All rights reserved.
#-----------------------------------------------------------------------
# $Id: FileSystem.pm,v 2.15 2007/03/21 00:11:01 vadim Exp $
#-----------------------------------------------------------------------
# Authors:    Vadim V. Kouevda   initdotd@gmail.com
#-----------------------------------------------------------------------
# Description: This is an interface to the file system as easy as to the
#         hash. You just need to declare:
#         my $contents = $dir{'etc'}{'passwd'}
#         ... and /etc/passwd will be read into the variable $contents.
#-----------------------------------------------------------------------

package         Tie::FileSystem;

use             vars qw($VERSION @ISA @EXPORT);
use             strict;                 # Makes life miserable
use             Exporter;               # Inheritance
use             Tie::Hash;              # That's what we do :-)
use             Data::Dumper;           # Great debug tool
use             Symbol;                 # Handler generator
use             Fcntl ':mode';          # Better tests "-f" & "-d"

use             Tie::FileSystem::System;# Subroutines for system files

#-----------------------------------------------------------------------

$VERSION        = sprintf("%d.%d", q$Revision: 2.15 $ =~ /(\d+)\.(\d+)/);
@ISA            = qw(Tie::FileSystem::System Tie::Hash Exporter);
@EXPORT         = qw();                 # Everything's private

#-----------------------------------------------------------------------
# Tunable variables
#-----------------------------------------------------------------------

my $symbol;                             # Randomized DIR handler

#-----------------------------------------------------------------------
# Define file handlers
#-----------------------------------------------------------------------

my %file_type = (
    'default' => sub {
        #---------------------------------------------------------------
        # By default we just read the file into a string
        #---------------------------------------------------------------
        my ($file, $dbg, $size_limit) = @_;
        if ( ! open(FILE, "$file") ) {
             $dbg && debug($dbg, "Failed to open file '$file'");
             return(undef);
        }
        my $buffer;                 # AUX buffer for file reading
        my $buf_size = 10485760;    # Do not read more than 10MB
        if ( $size_limit ) { $buf_size = $size_limit; }
        if ($dbg >= 6 ) { debug(6, ['size_limit'], [$size_limit]); }
        if ($dbg >= 6 ) { debug(6, ['buf_size'], [$buf_size]); }
        my $bytes = read(FILE, $buffer, $buf_size);
        if ( $bytes == $buf_size ) {
            $dbg && debug($dbg, "Buffer limit '$buf_size' reached");
            return(undef);
        }
        close(FILE);
        return($buffer);
    },
    '/etc/passwd$' => \&passwd,
);

#=======================================================================
# Auxiliary "system level" subroutines
#=======================================================================

my @level = ( 'SILENT',     # No output at all, ERRORs are suppressed
              'ERROR',      # ERRORs are printed to STDERR
              'WARNING',    # WARNINGs are printed to STDERR
              'INFO',       # Information messages
              'D:IN/OUT',   # Important variables
              'D:LOGIC',    # Logical desicions
              'D:VARS',     # Variables
            );

#-----------------------------------------------------------------------
# Debug output
#-----------------------------------------------------------------------

sub debug {
    my $dbg = shift(@_);
    #-------------------------------------------------------------------
    print STDERR "", (caller(1))[3], " [", $level[$dbg], "] ";
    #-------------------------------------------------------------------
    $Data::Dumper::Terse = 1;
    if ( scalar(@_) == 1 ) { print $_[0]; shift(@_); }
    if ( scalar(@_) <= 0 ) { print "\n"; return; }
    if ( scalar(@_) >  2 ) { print "INCORRECT debug USAGE\n"; return; }
    foreach my $idx ( 0 .. scalar(@{$_[0]})-1 ) {
        print STDERR $_[0][$idx], " = ", Dumper($_[1][$idx]);
    }
    return;
}

#-----------------------------------------------------------------------
# Better determination of the file type
#-----------------------------------------------------------------------

sub filetype {
    my ($filename) = @_;
    my @stat = stat($filename);
    if ( S_ISDIR($stat[2]) ) { return('DIR'); }
    if ( S_ISREG($stat[2]) ) { return('FILE'); }
    return(undef);
}

#=======================================================================
# Supported functions, required for tied hash implementation.
#=======================================================================

sub TIEHASH {
    my ( $class, %args ) = @_;
    #-------------------------------------------------------------------
    if ( ! defined($args{'dbg'}) ) { $args{'dbg'} = 0; }
    if ($args{'dbg'} >= 4 ) { debug(4, ['ARGS'], [\%args]); }
    #-------------------------------------------------------------------
    # Verify arguments
    #-------------------------------------------------------------------
    if ( ! defined($args{'dir'}) ) {
        $args{'dbg'} && debug(1, "Directory name is required");
        return(undef);
    }
    if ( filetype($args{'dir'}) ne "DIR"  ) {
        $args{'dbg'} && debug(1, "$args{'dir'} is not a directory");
        return(undef);
    }
    #-------------------------------------------------------------------
    if ($args{'dbg'} >= 4 ) { debug(4, "OUT"); }
    return ( bless ( [ \%args,  # [0] Hash of options
                       undef,   # [1] List of elements (quick access)
                       undef,   # [2] Index of current element
                       undef ], # [3] Reference to a hashed contents
                 ref($class) || $class
             )
           );
    #-------------------------------------------------------------------
}

#=======================================================================

sub FIRSTKEY {
    my ( $this ) = @_;
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN"); }
    #-------------------------------------------------------------------
    # Get on demand contents
    #-------------------------------------------------------------------
    if ( ! $this->[1] ) { dir_contents($this); }
    if ( ! $this->[1] ) {
        $this->[0]{'dbg'} && debug(1, "contents is not defined");
        return(undef);
    }
    #-------------------------------------------------------------------
    if ( ! defined($this->[2]) ) { $this->[2] = 0; }
    my $idx = $this->[2]++; # Advance iterator to the next element
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    return($this->[1][$idx]);
    #-------------------------------------------------------------------
}

#-----------------------------------------------------------------------

sub NEXTKEY {
    my ( $this, $last ) = @_;
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN"); }
    #-------------------------------------------------------------------
    # Extract current index and forward by one the stored counter.
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} ) {
        print STDERR (caller(0))[3], " [DEBUG] in\n";
    }
    #-------------------------------------------------------------------
    my $idx = $this->[2]++;
    #-------------------------------------------------------------------
    # Return next.
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    if ( scalar @{$this->[1]} > $idx ) {
        return($this->[1][$idx]);
    } else {
        return(undef);
    }
    #-------------------------------------------------------------------
}

#-----------------------------------------------------------------------

sub EXISTS {
    my ( $this, $key ) = @_;
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, ['KEY'], [$key]); }
    #-------------------------------------------------------------------
    # Fetch contents on demand!
    #-------------------------------------------------------------------
    if ( ! $this->[1] ) { dir_contents($this); }
    if ( ! $this->[1] ) {
        if ( $this->[0]{'dbg'} >= 4 )
            { debug(4, "does not exist"); }
        if ( $this->[0]{'dbg'} >= 5 )
            { debug(5, ['contents'], [$this->[1]]); }
        return(0);
    }
    my $exists = grep { /^$key$/ } @{$this->[1]};
    #-------------------------------------------------------------------
    if ( $exists ) {
        if ( $this->[0]{'dbg'} >= 3 ) { debug(3, "exists: '$key'"); }
    } else {
        if ( $this->[0]{'dbg'} >= 3 ) { debug(3, "not found: '$key'"); }
    }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    return($exists);
    #-------------------------------------------------------------------
}

#-----------------------------------------------------------------------

sub FETCH {
    my ( $this, $key ) = @_;
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, ['KEY'], [$key]); }
    #-------------------------------------------------------------------
    # Does it exist?
    #-------------------------------------------------------------------
    if ( ! EXISTS( $this, $key ) ) {
        if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
        return(undef);
    }
    if ( $this->[0]{'dbg'} >= 3 ) {
        debug(3, "get contents for '$key' (" .
                 ref($this->[3]{$key}) . ")");
    }
    #-------------------------------------------------------------------
    if ( ! defined($this->[3]{$key}) ) { return(undef); }   # Unknown
    #-------------------------------------------------------------------
    # Is it directory of a file?
    #-------------------------------------------------------------------
    (my $entry = "$this->[0]{'dir'}/$key") =~ s{/+}{/}g;
    if ( ref($this->[3]{$key}) eq 'HASH' ) {    # Directory
        if ( $this->[0]{'dbg'} >= 5 ) { debug(5, "This is a dir"); }
        if ( $this->[0]{'dbg'} >= 6 )
            { debug(6, ['KEY', 'ENTRY'], [$key, $entry]); }
        tie %{$this->[3]{$key}}, "Tie::FileSystem",
            ( 'dbg' => $this->[0]{'dbg'},
              'buf_size' => $this->[0]{'buf_size'},
              'dir' => $entry);
    } else {                                    # File
        if ( $this->[0]{'dbg'} >= 5 ) {debug(5, "This is a file");}
        $this->[3]{$key} = file_contents( $this,
                                          $entry,
                                          $this->[0]{'buf_size'} );
    }
    return($this->[3]{$key});
    #-------------------------------------------------------------------
}

#=======================================================================
# Not supported functions, required for tied hash implementation.
#=======================================================================

sub DESTROY {
    my ( $this ) = @_;
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN: nothing to do"); }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    #-------------------------------------------------------------------
}

#-----------------------------------------------------------------------

sub STORE {
    my ( $this, $key, $value ) = @_;
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN: not supported"); }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    #-------------------------------------------------------------------
}

#-----------------------------------------------------------------------

sub DELETE {
    my ( $this, $key ) = @_;
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN: not supported"); }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    #-------------------------------------------------------------------
}

#-----------------------------------------------------------------------

sub CLEAR {
    my ( $this ) = @_;
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN: not supported"); }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    #-------------------------------------------------------------------
}

#=======================================================================
# Not required for tied hash implementation.
# These functions are required for this particular implementation.
#=======================================================================

sub KEYS {
    my ( $this ) = @_;
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN"); }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    #-------------------------------------------------------------------
    return(@{$this->[1]});
}

#-----------------------------------------------------------------------
# Just return the version of the class implementation
#-----------------------------------------------------------------------

sub version {
    my ( $this ) = @_;
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "IN"); }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
    #-------------------------------------------------------------------
    return($VERSION);
}

#-----------------------------------------------------------------------
# Fetch directory contents
#-----------------------------------------------------------------------

sub dir_contents {
    my ( $this ) = @_;
    if ( $this->[0]{'dbg'} >= 4 )
        { debug(4, ['DIR'], [$this->[0]{'dir'}]); }
    #-------------------------------------------------------------------
    # Read in contents of the directory through randomized handler
    #-------------------------------------------------------------------
    $symbol = gensym();
    if ( ! opendir ( $symbol, $this->[0]{'dir'} ) ) {
        if ( $this->[0]{'dbg'} )
            { debug(1, "Failed to open dir $this->[0]{'dir'}"); }
        return(undef);
    }
    my @entries = sort grep { ! /^\.+$/ } readdir ( $symbol );
    #-------------------------------------------------------------------
    # Determine what every entry is
    #-------------------------------------------------------------------
    my %contents;
    foreach my $entry ( @entries ) {
        (my $element = "$this->[0]{'dir'}/$entry") =~ s{/+}{/}g;
        my @stat = stat($element);
        my $mode = undef;
        if ( S_ISDIR($stat[2]) ) { $mode = "DIR"; }
        if ( S_ISREG($stat[2]) ) { $mode = "FILE"; }
        if ( $mode eq "DIR" ) {
            $contents{$entry} = {};     # HASH   - directory
        } elsif ( $mode eq "FILE" ) {
            $contents{$entry} = '';     # SCALAR - file contents
        } else {
            $contents{$entry} = undef;  # UNDEF  - hmm...
        }
    }
    closedir($symbol);
    #-------------------------------------------------------------------
    # Store data in the object
    #-------------------------------------------------------------------
    $this->[1] = \@entries;     # Store list of entries
    $this->[2] = 0;             # What is the number of current element
    $this->[3] = \%contents;    # Hashed contents
    #-------------------------------------------------------------------
    if ( $this->[0]{'dbg'} >= 6 )
        { debug(6, ['ENTRIES'], [\@entries]); }
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, "OUT"); }
}

#-----------------------------------------------------------------------
# Fetch file contents
#-----------------------------------------------------------------------

sub file_contents {
    my ( $this, $file, $buf_size ) = @_;
    if ( $this->[0]{'dbg'} >= 4 ) { debug(4, ['FILE'], [$file]); }
    #-------------------------------------------------------------------
    # Our implementation is general, so we will call different
    # subroutines on different files. $type is a switcher for handlers
    #-------------------------------------------------------------------
    my $type = undef;
    foreach my $re ( keys %file_type ) {
        next unless ( $file =~ m{$re} );
        $type = $re; last;
    }
    if ( ! defined($type) ) { $type = 'default'; }
    if ( $this->[0]{'dbg'} >= 6 ) {debug(6, ['buf_size'], [$buf_size]);}
    my $contents = &{$file_type{$type}}( $file,
                                         $this->[0]{'dbg'},
                                         $buf_size );
    return($contents);
    #-------------------------------------------------------------------
}


#-----------------------------------------------------------------------
# Plain Old Documentation
#-----------------------------------------------------------------------

=head1 NAME

Tie::FileSystem - Access file system via a Perl hash

=head1 SYNOPSIS

  use Tie::FileSystem;
  use Data::Dumper;

  my %data;
  tie %data, "Tie::FileSystem", ( 'dir' => "/" );
  print Dumper($data{'etc'}{'passwd'});

=head1 DESCRIPTION

Tie::FileSystem represents file system as a Perl hash. Each hash key
corresponds to name of a directory or a file. For example, for a file
"/etc/passwd" it will be $data{'etc'}{'passwd'}. Contents of the file
"/etc/passwd" becomes a value corresponding to the
$data{'etc'}{'passwd'}.

Standard handling procedure for directories is to store a listing of
files in the directory as keys. Standard procedure for files is to store
a contents of the file in the scalar value.

For certain files with known structure it is possible to define
subroutines for special handling. "Tie::FileSystem::System" defines
subroutines for handling system files and, for starters, has 'passwd'
handling subroutine. "/etc/passwd" can be represented asa hash with
following structure: $data{'etc'}{'passwd'}{$username}{$field}.

=head2 Options

  tie %data, "Tie::FileSystem",
    ( 'dbg' => 0, 'buf_size' => 10, 'dir' => "/" );
  
  'dbg' - level of debug output
    0 - 'SILENT', default # No output at all, ERRORs are suppressed
    1 - 'ERROR'           # ERRORs are printed to STDERR
    2 - 'WARNING'         # WARNINGs are printed to STDERR
    3 - 'INFO'            # Information messages
    4 - 'D:IN/OUT'        # Important variables
    5 - 'D:LOGIC'         # Logical desicions
    6 - 'D:VARS'          # Variables

  'buf_size' - buffer limit for file reading

  'dir' - directory to tie to

=head2 Public Methods

None.

=head1 PLATFORMS

Debian 3.1, Perl, v5.8.8.

Windows XP, ActiveState Perl, v5.8.8.

=head1 CAVEATS

The module is read only and does not permit overwrite or delete
files.

Under Windows '/' corresponds to 'C:'.

If you try to tie hash %data to '/' and then print Dumper(%data),
module will traverse the entire file system on demand!

=head1 BUGS

None known.

=head1 AUTHOR

Vadim V. Kouevda, initdotd@gmail.com

=head1 LICENSE and COPYRIGHT

Copyright (c) 2003-2007, Vadim V. Kouevda, "KAITS, Inc."

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

These terms are your choice of any of (1) the Perl Artistic Licence, or
(2) version 2 of the GNU General Public License as published by the
Free Software Foundation, or (3) any later version of the GNU General
Public License.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this library program; it should be in the file COPYING. If not,
write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111 USA

For licensing inquiries, contact the author at initdotd@gmail.com

=head1 WARRANTY

Module comes with ABSOLUTELY NO WARRANTY. For details, see the license.

=head1 AVAILABILITY

The latest version can be obtained from CPAN

=head1 SEE ALSO

Tie::FileSystem::System(3), Tie::File(3)

=cut

#-----------------------------------------------------------------------
# $Id: FileSystem.pm,v 2.15 2007/03/21 00:11:01 vadim Exp $
#-----------------------------------------------------------------------
# $Log: FileSystem.pm,v $
# Revision 2.15  2007/03/21 00:11:01  vadim
# Cleaning POD from KA::Tie::Dir references
#
# Revision 2.13  2007/03/20 21:45:19  vadim
# Fixed small insignificant bug with debuging in NEXTKEY
#
# Revision 2.12  2007/03/20 21:20:50  vadim
# Upon suggestion of Steven Schubiger (schubiger@gmail.com) added indents
# to displaying code in POD.
#
# Revision 2.11  2007/03/20 21:17:08  vadim
# Convert to Tie:FileSystem name space
#-----------------------------------------------------------------------
1;

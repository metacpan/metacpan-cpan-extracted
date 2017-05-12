
#
#   UNIX/VMS Filename "special character" and upper/lower case mapping
#   as used by Multinet and UCX NFS
#
#   Version:    0.021
#   Author:     C. Lane     lane@duphy4.physics.drexel.edu
#   Revised:    4 Jan 2001
#

=head1 NAME

VMS::FileUtils::SafeName -- convert special chars and case of filenames

=head1 Synopsis

use VMS::FileUtils::SafeName qw(:all) ;

$vmsusablename = safename('unix:..name &tc',$do_all_dots);
$unixname      = unsafename($vmsusablename);
$path          = safepath('x.y/version:1.2.3',$do_all_dots_filename);
$unixpath      = unsafepath($safepathoutput);
$archivename   = safe_archive('HTML-Parser-1.07.tar.gz');

=head1 DESCRIPTION

This package provides conversion between Unix filenames and VMS filenames
where the Unix filenames may have characters that are illegal under VMS.

Spaces, punctuation, control characters, etc. get mapped to a sequence of
the form '$6C'.  Also the case of the original unix filename is preserved
using '$' to shift from lower to uppercase:

    Unix filename       safename output
    -------------       ---------------
    abc.DEF.ghi     ->  $ABC.$DEF$5NGHI
                        ^    ^   ^^^ extra periods get converted
                        +----+-------change case

The conversion may be reversed with unsafename

The conversion provided here is the same as is contained in the
Multinet and UCX NFS software.

Routines:

=head2  safename

Converts upper/lower case, punctuation etc. to chars valid for VMS filename.
The first '.' in the filename is left intact (unless the second parameter
to vmsify_name is true, in which case all .s are converted).

Lowercase is taken as the default for input filenames.

=head2 unsafename

Converts filenames produced by safename back to their original form.

=head2 safepath

Converts path elements into VMS-safe form.  The trailing element
(if the path doesn't end in a '/') can optionally have all periods
converted, or (default) all but the first period converted. Path
elements that correspond to directory names have all periods converted

=head2 unsafepath

Reverses the conversion done by safepath

=head2 safe_archive

Converts filename of the type typically used for CPAN archives into
a VMS-compatible format:

    HTML-Parser-1.07.tar.gz  ->   HTML-Parser-1_07.tar-gz


=head1 REVISION

This document was last revised on 10 Mar 1998, for Perl 5.004.59

=cut

package VMS::FileUtils::SafeName;
require 5.002;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
use Exporter();


$VERSION = '0.02';
@ISA = qw( Exporter );
@EXPORT_OK = qw(safename unsafename safepath unsafepath safe_archive);
%EXPORT_TAGS =  (
    all  => [qw(safename unsafename safepath unsafepath safe_archive)]
);


sub safename ($;$) {
    my (@fn) = split(//,$_[0]);
    my ($doalldots) = $_[1];
    my ($out) = '';
    my ($shift) = 0;
    my ($dots) = defined($doalldots) && $doalldots;

    foreach (@fn) {
        if (/[a-z]/) {
            $out .= ($shift==0 ? uc($_) : '$'.uc($_)) ;
            $shift = 0;
        } elsif (/[A-Z]/) {
            $out .= ($shift==1 ? uc($_) : '$'.uc($_)) ;
            $shift = 1;
        } elsif (/[0-9\-_]/) {
            $out .= $_;
        } elsif ($_ eq '$') {
            $out .= '$$';
        } elsif ($_ eq '.') {
            $out .= $dots ? '$5N': '.';
            $dots++;
        } elsif (ord($_) == 0) {
            $out .= '$6A';
        } elsif ($_ eq ' ') {
            $out .= '$7A';
        } elsif (ord($_) == 0x40) {
            $out .= '$8A';
        } elsif (ord($_) == 0x60) {
            $out .= '$9A';
        } elsif (ord($_) <= 0x1A) {
            $out .= '$4'.chr(ord($_)-0x01+ord('A'));
        } elsif (ord($_) <= 0x1F) {
            $out .= '$6'.chr(ord($_)-0x1B+ord('B'));
        } elsif (ord($_) <= 0x3A) {
            $out .= '$5'.chr(ord($_)-0x21+ord('A'));
        } elsif (ord($_) <= 0x3F) {
            $out .= '$7'.chr(ord($_)-0x3B+ord('B'));
        } elsif (ord($_) <= 0x5E) {
            $out .= '$8'.chr(ord($_)-0x5B+ord('B'));
        } elsif (ord($_) <= 0x7F) {
            $out .= '$9'.chr(ord($_)-0x7B+ord('B'));
        } else {
            $out .= sprintf('$%03.3o',ord($_));
        }
    }
    return($out);
}


sub unsafename ($) {
    my ($in) = uc($_[0]);
    my ($shift, $i, $mod, $out);

    $mod =1 ;
    while ($mod) {
        $mod = 0;
        if ($in =~ /\$([0-7]{3,3})/) {
            $in = $`.chr(oct($1)).$';
            $mod = 1;
        } elsif ($in =~ /\$([4-9])([A-Z])/) {
            $i = ord($2) - ord('A');
            if ($1 == 4) {
                $in = $`.chr($i+0x01).$';
            } elsif ($1 == 5) {
                $in = $`.chr($i+0x21).$';
            } elsif ($1 == 6) {
                $in = $`.($i ? chr($i+0x1A) : chr(0)).$';
            } elsif ($1 == 7) {
                $in = $`.($i ? chr($i+0x3A) : ' ').$';
            } elsif ($1 == 8) {
                $in = $`.($i ? chr($i+0x5A) : chr(0x40)).$';
            } elsif ($1 == 9) {
                $in = $`.($i ? chr($i+0x7A) : chr(0x60)).$';
            }
            $mod = 1;
        }
    }

    $mod = 1;
    $shift = 0;
    $in = lc($in);
    $out = '';
    while ($mod) {
        $mod = 0;
        if ($in =~ /\$([A-Z\$])/i) {
            if ($1 eq '$') {
                $out .= $`.'$';
                $in  = $';
                $mod = 1;
            } else {
                $shift = !$shift;
                $out .= $`.($shift? uc($1) : lc($1));
                $in = $shift ? uc($') : lc($');
                $mod = 1;
            }
        }
    }
    return ($out.$in);
}

sub safepath ($;$) {
    my ($path, $dolast) = @_;
    my (@e) = split('/',$path);
    my ($j, $isadir);

    if (!defined($dolast)) {$dolast = 0;}
    $isadir = ($path =~ /\/$/);
    $dolast ^= $isadir;

    for ($j = 0; $j < $#e ; $j++) {
        $e[$j] = safename($e[$j],1);
    }
    $e[$#e] = safename($e[$#e],$dolast);
    $path = join('/',@e).($isadir ? '/' : '');
    return $path;
}

sub unsafepath ($) {
    return unsafename($_[0]);
}


sub safe_archive ($) {
    my $name = shift;
    my $suff = '';
    if ($name =~ /\.([\w\-\$]+)\.(gz|Z|zip|gzip)\Z/i) {
        $suff = $1.'-'.$2;
        $name = $`;
    } elsif ($name =~ /\.([\w\-\$]+)\Z/i) {
        $suff = $1;
        $name = $`;
    }
    $name =~ s#\.$##;
    $name =~ s#\.#_#g;
    $name .= '.'.$suff;
    return $name;
}



1;



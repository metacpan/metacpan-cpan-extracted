#!perl -w

# Script to create the Win32::GUI::Constants
# definitions
#
# Creates constants.src, used as input to perfect.exe
# Creates constants.h, defining all the values for sub-optimal
#   sets of system header files
# Creates t\70_values.def testing all values
# Creates phash.inc, the hash source code
# 
# (c) Robert May 2005, 2006
#
# $Id: Constants.PL,v 1.10 2008/02/08 18:47:17 robertemay Exp $

use strict;
use warnings;

use File::Basename;
use File::Path;

my $type = 1; # 1 = constants.src; 2 = constants.h; 3 = t\70_values.def;
              # 4 = phash.inc;

# MakeMaker provides the output filename as the first argument on the
# command line, we need to ensure the directory exists before opening
# the file:
if ( @ARGV > 0 ) {
	my $file = $ARGV[0];
	my $path = dirname($file);
	unless (-d $path) {
		mkpath($path, 1) or die qq(Failed to create '$path': $!);
	}
	open(my $fh, '>', $file) or die qq(Failed to open '$file': $!);
	select $fh;
	$type = 1 if $file =~ /\.src$/;
	$type = 2 if $file =~ /\.h$/;
	$type = 3 if $file =~ /\.def$/;
	$type = 4 if $file =~ /\.inc$/;
}

my %C;

while(<DATA>) {
	s/#.*$//;     		# remove comments
	next if /^\s*$/;	# ignore blank lines
    #chomp;
    s/\r?\n$//;         # throw away line endings - chomp on cygwin only removes '\n'
                        # done this way in case dos2unix didn't get run on this file
	my ($c, $v) = split;
	$v = oct($v) if $v =~ /^0/;
	$v = int $v;

	# check key length, as perfect.exe has MAXKEYLEN
	# defined in perfect.h.  Currently set at 32:
	die <<ERMSG if length($c) >= 31;
Key $c is longer than the current maximum key length (31)
supported by perfect.exe.  Please update this file
and the MAXKEYLEN definition in hash/perfect.h,
and re-start the build process.

ERMSG

	# check for duplicates:
	die qq(Constant "$c" redefined) if exists $C{$c};
	$C{$c} = $v;
}
close(DATA);

########################################################
# Write the perfect.exe input file, one keyword per line
if($type == 1) {
    print "$_\n" for (keys(%C));
}

########################################################
# Write the constants.h file
elsif ($type == 2) {
    printf <<PRE, scalar gmtime();
/* constants.h written by Constants.PL
 * at %s.
 * Changes here will be lost, edit
 * Constants.PL instead
 *
 * Provides all constant values so that
 * build completes even with deficient
 * system header files
 */

PRE
    print <<DEFINE for (sort keys(%C));
#ifndef $_
#define $_ $C{$_}
#endif

DEFINE
}

########################################################
# Write the test file, to test each constant
elsif ($type == 3) {
    printf <<PRE, scalar gmtime, scalar keys(%C);
# 70_values.def written by Constants.PL
# at %s.
# Changes here will be lost, edit
# Constants.PL instead
# 
# Provides tests for each constant defined,
# comparing the value returned by the module
# to the value found in Constants.PL

plan tests => %d;

use Win32::GUI::Constants;
    
PRE
    print <<TEST for (sort keys(%C));
is(Win32::GUI::Constants::constant('$_'), $C{$_}, '$_ has correct value');
TEST
}

########################################################
# Write the hash definition file phash.inc
elsif ($type == 4) {

    # parse .def file:
    my ($define, $tab, $hash, $constants) = parse_def();

    # Write out the header
    printf <<PRE, scalar gmtime;
/* phash.inc written by Constants.PL
 * at %s.
 * Changes here will be lost, edit
 * Constants.PL instead
 *
 * Provides the hash definition and
 * lookup functions required by
 * the Win32::GUI::Constants XS code.
 */

PRE

    # Write out the defines section
    print <<DEFINE;
/* some useful defines */
DEFINE
    print join("\n", @{$define}), "\n";
    print "\n";

    # Write out the lookup table used by the hash function
    print <<TAB;
/* phash calculation table */
static const USHORT tab[] = {
TAB
    print "$_\n" for (@{$tab});
    print "};\n\n";

    # Create and write the strings table
    print <<STRINGTABLE1;
/* constant names string table */
struct stringpool_t {
STRINGTABLE1

    print '  CHAR str'.$_.'[sizeof("'.$constants->[$_].'")];'."\n" for (0 .. (@{$constants}-1));
    print <<STRINGTABLE2;
};

/* initialise string table */
static const struct stringpool_t stringpool_contents = {
STRINGTABLE2

    print "  \"$_\",\n" for (@{$constants});
    print <<STRINGTABLE3;
};
#define stringpool ((const LPSTR) &stringpool_contents)

STRINGTABLE3

    # Create the constant to value lookup table
    print <<WORDLIST;
/* constants lookup table structures */
struct const_entry {
    USHORT offset;  /* offset into the string table */
    USHORT flags;   /* flags: F_IV or F_UV */
    LONG   value;   /* constants value */
};
typedef struct const_entry const_entry;

/* falags values */
#define F_IV 0     /* treat value as signed */
#define F_UV 1     /* treat value as unsigned */

/* constants lookup table */
static const const_entry const_table[] = {
WORDLIST

    for (0 .. @{$constants}-1) {
        my $c = $constants->[$_];
        my $v = $C{$c};
        my $flags = ($v < 2**31 ? "F_IV" : "F_UV");
        my $e = ($v < 2**31 ? "L" : "UL");

        print "  {(USHORT)(INT_PTR)&((struct stringpool_t *)0)->str$_, $flags, (LONG)$v$e},\n";
    }
    print "};\n\n";

    # Write out the 'lookup' function
    print <<'LOOKUP';
/* lookup function from hash\lookupa.c */
#define mix(a,b,c) \
{ \
  a -= b; a -= c; a ^= (c>>13); \
  b -= c; b -= a; b ^= (a<<8); \
  c -= a; c -= b; c ^= (b>>13); \
  a -= b; a -= c; a ^= (c>>12);  \
  b -= c; b -= a; b ^= (a<<16); \
  c -= a; c -= b; c ^= (b>>5); \
  a -= b; a -= c; a ^= (c>>3);  \
  b -= c; b -= a; b ^= (a<<10); \
  c -= a; c -= b; c ^= (b>>15); \
}

static ULONG lookup(LPSTR k, ULONG length, ULONG level)
{
  ULONG a,b,c,len;

  /* Set up the internal state */
  len = length;
  a = b = 0x9e3779b9;  /* the golden ratio; an arbitrary value */
  c = level;           /* the previous hash value */

  /*---------------------------------------- handle most of the key */
  while (len >= 12) {
    a += (k[0] +((ULONG)k[1]<<8) +((ULONG)k[2]<<16) +((ULONG)k[3]<<24));
    b += (k[4] +((ULONG)k[5]<<8) +((ULONG)k[6]<<16) +((ULONG)k[7]<<24));
    c += (k[8] +((ULONG)k[9]<<8) +((ULONG)k[10]<<16)+((ULONG)k[11]<<24));
    mix(a,b,c);
    k += 12; len -= 12;
  }

  /*------------------------------------- handle the last 11 bytes */
  c += length;
  switch(len) {            /* all the case statements fall through */
    case 11: c+=((ULONG)k[10]<<24);
    case 10: c+=((ULONG)k[9]<<16);
    case 9 : c+=((ULONG)k[8]<<8);
      /* the first byte of c is reserved for the length */
    case 8 : b+=((ULONG)k[7]<<24);
    case 7 : b+=((ULONG)k[6]<<16);
    case 6 : b+=((ULONG)k[5]<<8);
    case 5 : b+=k[4];
    case 4 : a+=((ULONG)k[3]<<24);
    case 3 : a+=((ULONG)k[2]<<16);
    case 2 : a+=((ULONG)k[1]<<8);
    case 1 : a+=k[0];
     /* case 0: nothing left to add */
  }
  mix(a,b,c);
  /*-------------------------------------------- report the result */
  return c;
}

LOOKUP

    # Write out the 'phash' function
    print <<HASH;
/* the hash function */
static ULONG phash(LPSTR key, STRLEN len)
{
  ULONG val = lookup(key, len, PHASHSALT);
HASH
    print "$_\n" for (@{$hash});
    print <<HASHEND;
}
HASHEND
}

# Unknown output type
else {
    die "Unknown output type: $type";
}

exit(0);

# Parse phash.def and return:
# - reference to array of defines to be included in phash.inc
# - reference to array of hash table values
# - reference to array of lines for the hash function
# - reference to array of constant names in hash key order
sub parse_def
{
    my (@defines, @tab, @hash, @constants);
    my $file = "phash.def";

    open my $fh, "<", $file or die "Failed to open $file: $!";

    my $type;
    while (my $line = <$fh>) {
	next if $line =~/^\s*$/; # discard empty lines
	$type = $1 if ($line =~ /^# \(@\)(\w+)/);
	next if $line =~ /^#/;   # discard comments
        chomp $line;

	if ($type eq 'DEFINE') {
            push @defines, "#define $line";
        }
        elsif ($type eq 'TAB') {
            push @tab, "  $line";
        }
        elsif ($type eq 'HASH') {
            next if $line =~ /lookup/;
	    if ($line =~ s/^\s*rsl\s*=\s*/return/) {
                push @hash, "  $line";
	    }
            else {
	        die "unexpected contents at line $. in file $file";
	    }
        }
        elsif ($type eq 'CONSTANTS') {
            push @constants, $line;
        }
        else {
            die "Unknown type $type at line $. while parsing $file";
        }
    }

    return \@defines, \@tab, \@hash, \@constants;
}

# Constansts are after the __DATA__ symbol.
# Comments start with # and continue to end of line.
# Blank lines are ignored.
# Constant values can only be numeric
# Constant values can be decimal, octal (start with 0), hex (start with 0x)
# or binary (start with 0b).
# Constants are listed in approximate alphabetical order, but there are
# some exceptions to keep related constants togeher.
# If a constant is included here twice, this script will die with an error.

__DATA__
# Background Modes
TRANSPARENT                    1           
OPAQUE                         2           

# Animation Control Messages
ACM_OPEN                1124  # (WM_USER+100)
ACM_PLAY                1125  # (WM_USER+101)
ACM_STOP                1126  # (WM_USER+102)

# Animation Control Notifications
ACN_START               1
ACN_STOP                2

# Animation control styles
ACS_CENTER              0x0001
ACS_TRANSPARENT         0x0002
ACS_AUTOPLAY            0x0004
ACS_TIMER               0x0008

# AnimateWindow constants
AW_HOR_POSITIVE             0x00000001
AW_HOR_NEGATIVE             0x00000002
AW_VER_POSITIVE             0x00000004
AW_VER_NEGATIVE             0x00000008
AW_CENTER                   0x00000010
AW_HIDE                     0x00010000
AW_ACTIVATE                 0x00020000
AW_SLIDE                    0x00040000
AW_BLEND                    0x00080000

# 3D border styles and flags
BDR_RAISEDOUTER                0x0001      
BDR_SUNKENOUTER                0x0002      
BDR_RAISEDINNER                0x0004      
BDR_SUNKENINNER                0x0008      
BDR_OUTER                      0x0003      # (BDR_RAISEDOUTER | BDR_SUNKENOUTER)
BDR_INNER                      0x000C      # (BDR_RAISEDINNER | BDR_SUNKENINNER)
BDR_RAISED                     0x0005      # (BDR_RAISEDOUTER | BDR_RAISEDINNER)
BDR_SUNKEN                     0x000A      # (BDR_SUNKENOUTER | BDR_SUNKENINNER)
EDGE_RAISED                    0x0005      # (BDR_RAISEDOUTER | BDR_RAISEDINNER)
EDGE_SUNKEN                    0x000A      # (BDR_SUNKENOUTER | BDR_SUNKENINNER)
EDGE_ETCHED                    0x0006      # (BDR_SUNKENOUTER | BDR_RAISEDINNER)
EDGE_BUMP                      0x0009      # (BDR_RAISEDOUTER | BDR_SUNKENINNER)
BF_LEFT                        0x0001      
BF_TOP                         0x0002      
BF_RIGHT                       0x0004      
BF_BOTTOM                      0x0008      
BF_TOPLEFT                     0x0003      # (BF_TOP | BF_LEFT)
BF_TOPRIGHT                    0x0006      # (BF_TOP | BF_RIGHT)
BF_BOTTOMLEFT                  0x0009      # (BF_BOTTOM | BF_LEFT)
BF_BOTTOMRIGHT                 0x000C      # (BF_BOTTOM | BF_RIGHT)
BF_RECT                        0x000F      # (BF_LEFT | BF_TOP | BF_RIGHT | BF_BOTTOM)
BF_DIAGONAL                    0x0010      
BF_DIAGONAL_ENDTOPRIGHT        0x0016      # (BF_DIAGONAL | BF_TOP | BF_RIGHT)
BF_DIAGONAL_ENDTOPLEFT         0x0013      # (BF_DIAGONAL | BF_TOP | BF_LEFT)
BF_DIAGONAL_ENDBOTTOMLEFT      0x0019      # (BF_DIAGONAL | BF_BOTTOM | BF_LEFT)
BF_DIAGONAL_ENDBOTTOMRIGHT     0x001C      # (BF_DIAGONAL | BF_BOTTOM | BF_RIGHT)
BF_MIDDLE                      0x0800      
BF_SOFT                        0x1000      
BF_ADJUST                      0x2000      
BF_FLAT                        0x4000      
BF_MONO                        0x8000      

# Button Messages
BM_GETCHECK        0x00F0
BM_SETCHECK        0x00F1
BM_GETSTATE        0x00F2
BM_SETSTATE        0x00F3
BM_SETSTYLE        0x00F4
BM_CLICK           0x00F5
BM_GETIMAGE        0x00F6
BM_SETIMAGE        0x00F7
BCM_FIRST          0x1600
BCM_GETIDEALSIZE   0x1601 # (BCM_FIRST + 0x0001)
BCM_SETIMAGELIST   0x1602 # (BCM_FIRST + 0x0002)
BCM_GETIMAGELIST   0x1603 # (BCM_FIRST + 0x0003)
BCM_SETTEXTMARGIN  0x1604 # (BCM_FIRST + 0x0004)
BCM_GETTEXTMARGIN  0x1605 # (BCM_FIRST + 0x0005)

# Button Notifications
BN_CLICKED          0
BN_PAINT            1
BN_HILITE           2
BN_UNHILITE         3
BN_DISABLE          4
BN_DOUBLECLICKED    5
BN_PUSHED           2 # BN_HILITE
BN_UNPUSHED         3 # BN_UNHILITE
BN_DBLCLK           5 # BN_DOUBLECLICKED
BN_SETFOCUS         6
BN_KILLFOCUS        7

# Button Styles:
BS_PUSHBUTTON                  0x00000000  
BS_DEFPUSHBUTTON               0x00000001  
BS_CHECKBOX                    0x00000002  
BS_AUTOCHECKBOX                0x00000003  
BS_RADIOBUTTON                 0x00000004  
BS_3STATE                      0x00000005  
BS_AUTO3STATE                  0x00000006  
BS_GROUPBOX                    0x00000007  
BS_USERBUTTON                  0x00000008  
BS_AUTORADIOBUTTON             0x00000009  
BS_PUSHBOX                     0x0000000A  
BS_OWNERDRAW                   0x0000000B  
BS_TYPEMASK                    0x0000000F  
BS_LEFTTEXT                    0x00000020  
BS_TEXT                        0x00000000  
BS_ICON                        0x00000040  
BS_BITMAP                      0x00000080  
BS_LEFT                        0x00000100  
BS_RIGHT                       0x00000200  
BS_CENTER                      0x00000300  
BS_TOP                         0x00000400  
BS_BOTTOM                      0x00000800  
BS_VCENTER                     0x00000C00  
BS_PUSHLIKE                    0x00001000  
BS_MULTILINE                   0x00002000  
BS_NOTIFY                      0x00004000  
BS_FLAT                        0x00008000  
BS_RIGHTBUTTON                 0x00000020  

# Toolbar and toolbar button styles
BTNS_BUTTON                    0x0000      # TBSTYLE_BUTTON
BTNS_SEP                       0x0001      # TBSTYLE_SEP
BTNS_CHECK                     0x0002      # TBSTYLE_CHECK
BTNS_GROUP                     0x0004      # TBSTYLE_GROUP
BTNS_CHECKGROUP                0x0006      # TBSTYLE_CHECKGROUP
BTNS_DROPDOWN                  0x0008      # TBSTYLE_DROPDOWN
BTNS_AUTOSIZE                  0x0010      # TBSTYLE_AUTOSIZE
BTNS_NOPREFIX                  0x0020      # TBSTYLE_NOPREFIX
BTNS_SHOWTEXT                  0x0040      
BTNS_WHOLEDROPDOWN             0x0080      

# Combo Box return values
CB_OKAY             0
CB_ERR              -1
CB_ERRSPACE         -2

# Combo Box Messages
CB_GETEDITSEL               0x0140
CB_LIMITTEXT                0x0141
CB_SETEDITSEL               0x0142
CB_ADDSTRING                0x0143
CB_DELETESTRING             0x0144
CB_DIR                      0x0145
CB_GETCOUNT                 0x0146
CB_GETCURSEL                0x0147
CB_GETLBTEXT                0x0148
CB_GETLBTEXTLEN             0x0149
CB_INSERTSTRING             0x014A
CB_RESETCONTENT             0x014B
CB_FINDSTRING               0x014C
CB_SELECTSTRING             0x014D
CB_SETCURSEL                0x014E
CB_SHOWDROPDOWN             0x014F
CB_GETITEMDATA              0x0150
CB_SETITEMDATA              0x0151
CB_GETDROPPEDCONTROLRECT    0x0152
CB_SETITEMHEIGHT            0x0153
CB_GETITEMHEIGHT            0x0154
CB_SETEXTENDEDUI            0x0155
CB_GETEXTENDEDUI            0x0156
CB_GETDROPPEDSTATE          0x0157
CB_FINDSTRINGEXACT          0x0158
CB_SETLOCALE                0x0159
CB_GETLOCALE                0x015A
CB_GETTOPINDEX              0x015b
CB_SETTOPINDEX              0x015c
CB_GETHORIZONTALEXTENT      0x015d
CB_SETHORIZONTALEXTENT      0x015e
CB_GETDROPPEDWIDTH          0x015f
CB_SETDROPPEDWIDTH          0x0160
CB_INITSTORAGE              0x0161
CB_MULTIPLEADDSTRING        0x0163
CB_GETCOMBOBOXINFO          0x0164

# Combo Box notifications
CBN_ERRSPACE        -1
CBN_SELCHANGE       1
CBN_DBLCLK          2
CBN_SETFOCUS        3
CBN_KILLFOCUS       4
CBN_EDITCHANGE      5
CBN_EDITUPDATE      6
CBN_DROPDOWN        7
CBN_CLOSEUP         8
CBN_SELENDOK        9
CBN_SELENDCANCEL    10

# Combo Box styles
CBS_SIMPLE            0x0001
CBS_DROPDOWN          0x0002
CBS_DROPDOWNLIST      0x0003
CBS_OWNERDRAWFIXED    0x0010
CBS_OWNERDRAWVARIABLE 0x0020
CBS_AUTOHSCROLL       0x0040
CBS_OEMCONVERT        0x0080
CBS_SORT              0x0100
CBS_HASSTRINGS        0x0200
CBS_NOINTEGRALHEIGHT  0x0400
CBS_DISABLENOSCROLL   0x0800
CBS_UPPERCASE         0x2000
CBS_LOWERCASE         0x4000

# Extended Combo box styles
CBES_EX_NOEDITIMAGE          0x00000001
CBES_EX_NOEDITIMAGEINDENT    0x00000002
CBES_EX_PATHWORDBREAKPROC    0x00000004
CBES_EX_NOSIZELIMIT          0x00000008
CBES_EX_CASESENSITIVE        0x00000010

# Custome Draw Draw States
CDDS_PREPAINT                  0x00000001
CDDS_POSTPAINT                 0x00000002
CDDS_PREERASE                  0x00000003
CDDS_POSTERASE                 0x00000004
CDDS_ITEM                      0x00010000
CDDS_ITEMPREPAINT              0x00010001 # (CDDS_ITEM | CDDS_PREPAINT)
CDDS_ITEMPOSTPAINT             0x00010002 # (CDDS_ITEM | CDDS_POSTPAINT)
CDDS_ITEMPREERASE              0x00010003 # (CDDS_ITEM | CDDS_PREERASE)
CDDS_ITEMPOSTERASE             0x00010004 # (CDDS_ITEM | CDDS_POSTERASE)
CDDS_SUBITEM                   0x00020000

# Custom Draw Return Flags
CDRF_DODEFAULT                 0x00000000
CDRF_NEWFONT                   0x00000002
CDRF_SKIPDEFAULT               0x00000004
CDRF_NOTIFYPOSTPAINT           0x00000010
CDRF_NOTIFYITEMDRAW            0x00000020
CDRF_NOTIFYSUBITEMDRAW         0x00000020
CDRF_NOTIFYPOSTERASE           0x00000040

# Predefined Clipboard Formats
CF_TEXT                        1           
CF_BITMAP                      2           
CF_METAFILEPICT                3           
CF_SYLK                        4           
CF_DIF                         5           
CF_TIFF                        6           
CF_OEMTEXT                     7           
CF_DIB                         8           
CF_PALETTE                     9           
CF_PENDATA                     10          
CF_RIFF                        11          
CF_WAVE                        12          
CF_UNICODETEXT                 13          
CF_ENHMETAFILE                 14          
CF_HDROP                       15          
CF_LOCALE                      16          
CF_DIBV5                       17          
CF_MAX                         18          
CF_OWNERDISPLAY                0x0080      
CF_DSPTEXT                     0x0081      
CF_DSPBITMAP                   0x0082      
CF_DSPMETAFILEPICT             0x0083      
CF_DSPENHMETAFILE              0x008E      
CF_PRIVATEFIRST                0x0200      
CF_PRIVATELAST                 0x02FF      

# COLOR types
CLR_NONE                       0xFFFFFFFF  
CLR_DEFAULT                    0xFF000000  
CLR_INVALID                    0xFFFFFFFF  
CLR_HILIGHT                    0xFF000000  # CLR_DEFAULT

# CreateWindow constants
CW_USEDEFAULT                  0x80000000  
HWND_DESKTOP                   0           

# ChildWindowFromPoint flags
CWP_ALL                        0x0000      
CWP_SKIPINVISIBLE              0x0001      
CWP_SKIPDISABLED               0x0002      
CWP_SKIPTRANSPARENT            0x0004      

# System colors
COLOR_SCROLLBAR                0           
COLOR_BACKGROUND               1           
COLOR_ACTIVECAPTION            2           
COLOR_INACTIVECAPTION          3           
COLOR_MENU                     4           
COLOR_WINDOW                   5           
COLOR_WINDOWFRAME              6           
COLOR_MENUTEXT                 7           
COLOR_WINDOWTEXT               8           
COLOR_CAPTIONTEXT              9           
COLOR_ACTIVEBORDER             10          
COLOR_INACTIVEBORDER           11          
COLOR_APPWORKSPACE             12          
COLOR_HIGHLIGHT                13          
COLOR_HIGHLIGHTTEXT            14          
COLOR_BTNFACE                  15          
COLOR_BTNSHADOW                16          
COLOR_GRAYTEXT                 17          
COLOR_BTNTEXT                  18          
COLOR_INACTIVECAPTIONTEXT      19          
COLOR_BTNHIGHLIGHT             20          
COLOR_3DDKSHADOW               21          
COLOR_3DLIGHT                  22          
COLOR_INFOTEXT                 23          
COLOR_INFOBK                   24          
COLOR_HOTLIGHT                 26          
COLOR_GRADIENTACTIVECAPTION    27          
COLOR_GRADIENTINACTIVECAPTION  28          
COLOR_MENUHILIGHT              29          
COLOR_MENUBAR                  30          
COLOR_DESKTOP                  1           # COLOR_BACKGROUND
COLOR_3DFACE                   15          # COLOR_BTNFACE
COLOR_3DSHADOW                 16          # COLOR_BTNSHADOW
COLOR_3DHIGHLIGHT              20          # COLOR_BTNHIGHLIGHT
COLOR_3DHILIGHT                20          # COLOR_BTNHIGHLIGHT
COLOR_BTNHILIGHT               20          # COLOR_BTNHIGHLIGHT

# Code Page Default Values.
CP_ACP                         0           
CP_OEMCP                       1           
CP_MACCP                       2           
CP_THREAD_ACP                  3           
CP_SYMBOL                      42          
CP_UTF7                        65000       
CP_UTF8                        65001       

# Class styles
CS_VREDRAW                     0x0001      
CS_HREDRAW                     0x0002      
CS_DBLCLKS                     0x0008      
CS_OWNDC                       0x0020      
CS_CLASSDC                     0x0040      
CS_PARENTDC                    0x0080      
CS_NOCLOSE                     0x0200      
CS_SAVEBITS                    0x0800      
CS_BYTEALIGNCLIENT             0x1000      
CS_BYTEALIGNWINDOW             0x2000      
CS_GLOBALCLASS                 0x4000      
CS_IME                         0x00010000  
CS_DROPSHADOW                  0x00020000  

# GetViewFlags
CDB2GVF_SHOWALLFILES           0x00000001  
CSIDL_DESKTOP                  0x0000      
CSIDL_INTERNET                 0x0001      
CSIDL_PROGRAMS                 0x0002      
CSIDL_CONTROLS                 0x0003      
CSIDL_PRINTERS                 0x0004      
CSIDL_PERSONAL                 0x0005      
CSIDL_FAVORITES                0x0006      
CSIDL_STARTUP                  0x0007      
CSIDL_RECENT                   0x0008      
CSIDL_SENDTO                   0x0009      
CSIDL_BITBUCKET                0x000a      
CSIDL_STARTMENU                0x000b      
CSIDL_MYDOCUMENTS              0x000c      
CSIDL_MYMUSIC                  0x000d      
CSIDL_MYVIDEO                  0x000e      
CSIDL_DESKTOPDIRECTORY         0x0010      
CSIDL_DRIVES                   0x0011      
CSIDL_NETWORK                  0x0012      
CSIDL_NETHOOD                  0x0013      
CSIDL_FONTS                    0x0014      
CSIDL_TEMPLATES                0x0015      
CSIDL_COMMON_STARTMENU         0x0016      
CSIDL_COMMON_PROGRAMS          0x0017      
CSIDL_COMMON_STARTUP           0x0018      
CSIDL_COMMON_DESKTOPDIRECTORY  0x0019      
CSIDL_APPDATA                  0x001a      
CSIDL_PRINTHOOD                0x001b      
CSIDL_LOCAL_APPDATA            0x001c      
CSIDL_ALTSTARTUP               0x001d      
CSIDL_COMMON_ALTSTARTUP        0x001e      
CSIDL_COMMON_FAVORITES         0x001f      
CSIDL_INTERNET_CACHE           0x0020      
CSIDL_COOKIES                  0x0021      
CSIDL_HISTORY                  0x0022      
CSIDL_COMMON_APPDATA           0x0023      
CSIDL_WINDOWS                  0x0024      
CSIDL_SYSTEM                   0x0025      
CSIDL_PROGRAM_FILES            0x0026      
CSIDL_MYPICTURES               0x0027      
CSIDL_PROFILE                  0x0028      
CSIDL_SYSTEMX86                0x0029      
CSIDL_PROGRAM_FILESX86         0x002a      
CSIDL_PROGRAM_FILES_COMMON     0x002b      
CSIDL_PROGRAM_FILES_COMMONX86  0x002c      
CSIDL_COMMON_TEMPLATES         0x002d      
CSIDL_COMMON_DOCUMENTS         0x002e      
CSIDL_COMMON_ADMINTOOLS        0x002f      
CSIDL_ADMINTOOLS               0x0030      
CSIDL_CONNECTIONS              0x0031      
CSIDL_COMMON_MUSIC             0x0035      
CSIDL_COMMON_PICTURES          0x0036      
CSIDL_COMMON_VIDEO             0x0037      
CSIDL_RESOURCES                0x0038      
CSIDL_RESOURCES_LOCALIZED      0x0039      
CSIDL_COMMON_OEM_LINKS         0x003a      
CSIDL_CDBURN_AREA              0x003b      
CSIDL_COMPUTERSNEARME          0x003d      
CSIDL_FLAG_CREATE              0x8000      
CSIDL_FLAG_DONT_VERIFY         0x4000      
CSIDL_FLAG_NO_ALIAS            0x1000      
CSIDL_FLAG_PER_USER_INIT       0x0800      
CSIDL_FLAG_MASK                0xFF00      

# flags for DrawFrameControl
DFC_CAPTION                    1           
DFC_MENU                       2           
DFC_SCROLL                     3           
DFC_BUTTON                     4           
DFC_POPUPMENU                  5           
DFCS_CAPTIONCLOSE              0x0000      
DFCS_CAPTIONMIN                0x0001      
DFCS_CAPTIONMAX                0x0002      
DFCS_CAPTIONRESTORE            0x0003      
DFCS_CAPTIONHELP               0x0004      
DFCS_MENUARROW                 0x0000      
DFCS_MENUCHECK                 0x0001      
DFCS_MENUBULLET                0x0002      
DFCS_MENUARROWRIGHT            0x0004      
DFCS_SCROLLUP                  0x0000      
DFCS_SCROLLDOWN                0x0001      
DFCS_SCROLLLEFT                0x0002      
DFCS_SCROLLRIGHT               0x0003      
DFCS_SCROLLCOMBOBOX            0x0005      
DFCS_SCROLLSIZEGRIP            0x0008      
DFCS_SCROLLSIZEGRIPRIGHT       0x0010      
DFCS_BUTTONCHECK               0x0000      
DFCS_BUTTONRADIOIMAGE          0x0001      
DFCS_BUTTONRADIOMASK           0x0002      
DFCS_BUTTONRADIO               0x0004      
DFCS_BUTTON3STATE              0x0008      
DFCS_BUTTONPUSH                0x0010      
DFCS_INACTIVE                  0x0100      
DFCS_PUSHED                    0x0200      
DFCS_CHECKED                   0x0400      
DFCS_TRANSPARENT               0x0800      
DFCS_HOT                       0x1000      
DFCS_ADJUSTRECT                0x2000      
DFCS_FLAT                      0x4000      
DFCS_MONO                      0x8000      

# WM_GETDLGCODE message return values
DLGC_WANTARROWS                1
DLGC_WANTTAB                   2
DLGC_WANTALLKEYS               4
DLGC_WANTMESSAGE               4
DLGC_HASSETSEL                 8
DLGC_DEFPUSHBUTTON             16
DLGC_UNDEFPUSHBUTTON           32
DLGC_RADIOBUTTON               64
DLGC_WANTCHARS                 128
DLGC_STATIC                    256
DLGC_BUTTON                    0x2000

# Dialog styles
DS_ABSALIGN                    0x01        
DS_SYSMODAL                    0x02        
DS_LOCALEDIT                   0x20        
DS_SETFONT                     0x40        
DS_MODALFRAME                  0x80        
DS_NOIDLEMSG                   0x100       
DS_SETFOREGROUND               0x200       
DS_3DLOOK                      0x0004      
DS_FIXEDSYS                    0x0008      
DS_NOFAILCREATE                0x0010      
DS_CONTROL                     0x0400      
DS_CENTER                      0x0800      
DS_CENTERMOUSE                 0x1000      
DS_CONTEXTHELP                 0x2000      
DS_SHELLFONT                   0x0048      # (DS_SETFONT | DS_FIXEDSYS)

# DrawText() Format Flags
DT_TOP                         0x00000000  
DT_LEFT                        0x00000000  
DT_CENTER                      0x00000001  
DT_RIGHT                       0x00000002  
DT_VCENTER                     0x00000004  
DT_BOTTOM                      0x00000008  
DT_WORDBREAK                   0x00000010  
DT_SINGLELINE                  0x00000020  
DT_EXPANDTABS                  0x00000040  
DT_TABSTOP                     0x00000080  
DT_NOCLIP                      0x00000100  
DT_EXTERNALLEADING             0x00000200  
DT_CALCRECT                    0x00000400  
DT_NOPREFIX                    0x00000800  
DT_INTERNAL                    0x00001000  
DT_EDITCONTROL                 0x00002000  
DT_PATH_ELLIPSIS               0x00004000  
DT_END_ELLIPSIS                0x00008000  
DT_MODIFYSTRING                0x00010000  
DT_RTLREADING                  0x00020000  
DT_WORD_ELLIPSIS               0x00040000  
DT_NOFULLWIDTHCHARBREAK        0x00080000  
DT_HIDEPREFIX                  0x00100000  
DT_PREFIXONLY                  0x00200000  

# Date/Time picker styles
DTS_UPDOWN                     0x0001      
DTS_SHOWNONE                   0x0002      
DTS_SHORTDATEFORMAT            0x0000      
DTS_LONGDATEFORMAT             0x0004      
DTS_SHORTDATECENTURYFORMAT     0x000C      
DTS_TIMEFORMAT                 0x0009      
DTS_APPCANPARSE                0x0010      
DTS_RIGHTALIGN                 0x0020      

# Edit Control Messages
EM_GETSEL                      0x00B0
EM_SETSEL                      0x00B1
EM_GETRECT                     0x00B2
EM_SETRECT                     0x00B3
EM_SETRECTNP                   0x00B4
EM_SCROLL                      0x00B5
EM_LINESCROLL                  0x00B6
EM_SCROLLCARET                 0x00B7
EM_GETMODIFY                   0x00B8
EM_SETMODIFY                   0x00B9
EM_GETLINECOUNT                0x00BA
EM_LINEINDEX                   0x00BB
EM_SETHANDLE                   0x00BC
EM_GETHANDLE                   0x00BD
EM_GETTHUMB                    0x00BE
EM_LINELENGTH                  0x00C1
EM_REPLACESEL                  0x00C2
EM_GETLINE                     0x00C4
EM_LIMITTEXT                   0x00C5
EM_CANUNDO                     0x00C6
EM_UNDO                        0x00C7
EM_FMTLINES                    0x00C8
EM_LINEFROMCHAR                0x00C9
EM_SETTABSTOPS                 0x00CB
EM_SETPASSWORDCHAR             0x00CC
EM_EMPTYUNDOBUFFER             0x00CD
EM_GETFIRSTVISIBLELINE         0x00CE
EM_SETREADONLY                 0x00CF
EM_SETWORDBREAKPROC            0x00D0
EM_GETWORDBREAKPROC            0x00D1
EM_GETPASSWORDCHAR             0x00D2
EM_SETMARGINS                  0x00D3
EM_GETMARGINS                  0x00D4
EM_SETLIMITTEXT                0x00C5 # EM_LIMITTEXT
EM_GETLIMITTEXT                0x00D5
EM_POSFROMCHAR                 0x00D6
EM_CHARFROMPOS          0x00D7
EM_SETIMESTATUS         0x00D8
EM_GETIMESTATUS         0x00D9

# (Rich)Edit control notification codes
EN_MSGFILTER         0x0700
EN_REQUESTRESIZE     0x0701
EN_SELCHANGE         0x0702
EN_DROPFILES         0x0703
EN_PROTECTED         0x0704
EN_CORRECTTEXT       0x0705
EN_STOPNOUNDO        0x0706
EN_IMECHANGE         0x0707
EN_SAVECLIPBOARD     0x0708
EN_OLEOPFAILED       0x0709
EN_OBJECTPOSITIONS   0x070a
EN_LINK              0x070b
EN_DRAGDROPDONE      0x070c
EN_PARAGRAPHEXPANDED 0x070d
EN_PAGECHANGE        0x070e
EN_LOWFIRTF          0x070f
EN_ALIGNLTR          0x0710
EN_ALIGNRTL          0x0711
EN_SETFOCUS          0x0100
EN_KILLFOCUS         0x0200
EN_CHANGE            0x0300
EN_UPDATE            0x0400
EN_ERRSPACE          0x0500
EN_MAXTEXT           0x0501
EN_HSCROLL           0x0601
EN_VSCROLL           0x0602
EN_ALIGN_LTR_EC      0x0700
EN_ALIGN_RTL_EC      0x0701

# Richedit Event notification masks 
ENM_NONE                       0x00000000  
ENM_CHANGE                     0x00000001  
ENM_UPDATE                     0x00000002  
ENM_SCROLL                     0x00000004  
ENM_SCROLLEVENTS               0x00000008  
ENM_DRAGDROPDONE               0x00000010  
ENM_PARAGRAPHEXPANDED          0x00000020  
ENM_PAGECHANGE                 0x00000040  
ENM_KEYEVENTS                  0x00010000  
ENM_MOUSEEVENTS                0x00020000  
ENM_REQUESTRESIZE              0x00040000  
ENM_SELCHANGE                  0x00080000  
ENM_DROPFILES                  0x00100000  
ENM_PROTECTED                  0x00200000  
ENM_CORRECTTEXT                0x00400000  
ENM_IMECHANGE                  0x00800000  
ENM_LANGCHANGE                 0x01000000  
ENM_OBJECTPOSITIONS            0x02000000  
ENM_LINK                       0x04000000  
ENM_LOWFIRTF                   0x08000000  

# Edit control styles
ES_LEFT                        0x0000      
ES_CENTER                      0x0001      
ES_RIGHT                       0x0002      
ES_MULTILINE                   0x0004      
ES_UPPERCASE                   0x0008      
ES_LOWERCASE                   0x0010      
ES_PASSWORD                    0x0020      
ES_AUTOVSCROLL                 0x0040      
ES_AUTOHSCROLL                 0x0080      
ES_NOHIDESEL                   0x0100      
ES_OEMCONVERT                  0x0400      
ES_READONLY                    0x0800      
ES_WANTRETURN                  0x1000      
ES_NUMBER                      0x2000      

# ExtFloodFill style flags
FLOODFILLBORDER                0           
FLOODFILLSURFACE               1           

# GetAncestor() constants (The "real" ancestor window)
GA_PARENT                      1           
GA_ROOT                        2           
GA_ROOTOWNER                   3           

# Class field offsets for GetClassLong()
GCL_MENUNAME                   -8          
GCL_HBRBACKGROUND              -10         
GCL_HCURSOR                    -12         
GCL_HICON                      -14         
GCL_HMODULE                    -16         
GCL_CBWNDEXTRA                 -18         
GCL_CBCLSEXTRA                 -20         
GCL_WNDPROC                    -24         
GCL_STYLE                      -26         
GCW_ATOM                       -32         
GCLP_HICONSM                   -34         

# Flags for the GETEXTEX data structure 
GT_DEFAULT		       0
GT_USECRLF	               1
GT_SELECTION                   2
GT_RAWTEXT                     4
GT_NOHIDDENTEXT                8

# GetWindow() constants
GW_HWNDFIRST                   0           
GW_HWNDLAST                    1           
GW_HWNDNEXT                    2           
GW_HWNDPREV                    3           
GW_OWNER                       4           
GW_CHILD                       5           
GW_ENABLEDPOPUP                6           

# Window field offsets for GetWindowLong()
GWL_WNDPROC                    -4          
GWL_HINSTANCE                  -6          
GWL_HWNDPARENT                 -8          
GWL_STYLE                      -16         
GWL_EXSTYLE                    -20         
GWL_USERDATA                   -21         
GWL_ID                         -12         

# Header control styles
HDS_HORZ                0x0000
HDS_BUTTONS             0x0002
HDS_HOTTRACK            0x0004
HDS_HIDDEN              0x0008
HDS_DRAGDROP            0x0040
HDS_FULLDRAG            0x0080
HDS_FILTERBAR           0x0100
HDS_FLAT                0x0200

# HISNT values
HINST_COMMCTRL                 -1          

# WM_NCHITTEST and MOUSEHOOKSTRUCT Mouse Position Codes
HTERROR                        -2          
HTTRANSPARENT                  -1          
HTNOWHERE                      0           
HTCLIENT                       1           
HTCAPTION                      2           
HTSYSMENU                      3           
HTGROWBOX                      4           
HTSIZE                         4           # HTGROWBOX
HTMENU                         5           
HTHSCROLL                      6           
HTVSCROLL                      7           
HTMINBUTTON                    8           
HTMAXBUTTON                    9           
HTLEFT                         10          
HTRIGHT                        11          
HTTOP                          12          
HTTOPLEFT                      13          
HTTOPRIGHT                     14          
HTBOTTOM                       15          
HTBOTTOMLEFT                   16          
HTBOTTOMRIGHT                  17          
HTBORDER                       18          
HTREDUCE                       8           # HTMINBUTTON
HTZOOM                         9           # HTMAXBUTTON
HTSIZEFIRST                    10          # HTLEFT
HTSIZELAST                     17          # HTBOTTOMRIGHT
HTOBJECT                       19          
HTCLOSE                        20          
HTHELP                         21          

# Toolbar special image indices
I_IMAGECALLBACK                -1
I_IMAGENONE                    -2

# WM_SETICON / WM_GETICON Type Codes
ICON_SMALL                     0           
ICON_BIG                       1           
ICON_SMALL2                    2           

# Image List constants
ILC_MASK                       0x00000001  
ILC_COLOR                      0x00000000  
ILC_COLORDDB                   0x000000FE  
ILC_COLOR4                     0x00000004  
ILC_COLOR8                     0x00000008  
ILC_COLOR16                    0x00000010  
ILC_COLOR24                    0x00000018  
ILC_COLOR32                    0x00000020  
ILC_PALETTE                    0x00000800  
ILC_MIRROR                     0x00002000  
ILC_PERITEMMIRROR              0x00008000  
ILD_NORMAL                     0x00000000  
ILD_TRANSPARENT                0x00000001  
ILD_MASK                       0x00000010  
ILD_IMAGE                      0x00000020  
ILD_ROP                        0x00000040  
ILD_BLEND25                    0x00000002  
ILD_BLEND50                    0x00000004  
ILD_OVERLAYMASK                0x00000F00  
ILD_PRESERVEALPHA              0x00001000  
ILD_SCALE                      0x00002000  
ILD_DPISCALE                   0x00004000  
ILD_SELECTED                   0x00000004  # ILD_BLEND50
ILD_FOCUS                      0x00000002  # ILD_BLEND25
ILD_BLEND                      0x00000004  # ILD_BLEND50
ILS_NORMAL                     0x00000000  
ILS_GLOW                       0x00000001  
ILS_SHADOW                     0x00000002  
ILS_SATURATE                   0x00000004  
ILS_ALPHA                      0x00000008  

# Image types for LoadImage/LoadResource
IMAGE_BITMAP                   0           
IMAGE_ICON                     1           
IMAGE_CURSOR                   2           
IMAGE_ENHMETAFILE              3           

# Dialog Box Command Ids
IDOK                           1           
IDCANCEL                       2           
IDABORT                        3           
IDRETRY                        4           
IDIGNORE                       5           
IDYES                          6           
IDNO                           7           
IDCLOSE                        8           
IDHELP                         9           
IDTRYAGAIN                     10          
IDCONTINUE                     11          
IDTIMEOUT                      32000       

# ID for bitmaps (Toolbars)
IDB_STD_SMALL_COLOR            0           
IDB_STD_LARGE_COLOR            1           
IDB_VIEW_SMALL_COLOR           4           
IDB_VIEW_LARGE_COLOR           5           
IDB_HIST_SMALL_COLOR           8           
IDB_HIST_LARGE_COLOR           9           

# Standard Cursor IDs
IDC_ARROW                      32512       
IDC_IBEAM                      32513       
IDC_WAIT                       32514       
IDC_CROSS                      32515       
IDC_UPARROW                    32516       
IDC_SIZENWSE                   32642       
IDC_SIZENESW                   32643       
IDC_SIZEWE                     32644       
IDC_SIZENS                     32645       
IDC_SIZEALL                    32646       
IDC_NO                         32648       
IDC_HAND                       32649       
IDC_APPSTARTING                32650       
IDC_HELP                       32651       

# Standard Icon IDs
IDI_APPLICATION                32512       
IDI_HAND                       32513       
IDI_QUESTION                   32514       
IDI_EXCLAMATION                32515       
IDI_ASTERISK                   32516       
IDI_WINLOGO                    32517       
IDI_WARNING                    32515       # IDI_EXCLAMATION
IDI_ERROR                      32513       # IDI_HAND
IDI_INFORMATION                32516       # IDI_ASTERISK

# Win32::GUI Icon
IDI_DEFAULTICON                102

# Win32::GUI Cursors
IDC_HSPLIT                     103
IDC_VSPLIT                     104

# OEM Cursor IDs
OCR_NORMAL          32512
OCR_IBEAM           32513
OCR_WAIT            32514
OCR_CROSS           32515
OCR_UP              32516
OCR_SIZENWSE        32642
OCR_SIZENESW        32643
OCR_SIZEWE          32644
OCR_SIZENS          32645
OCR_SIZEALL         32646
OCR_NO              32648
OCR_HAND            32649
OCR_APPSTARTING     32650

# OEM Bitmap IDs
OBM_CLOSE           32754
OBM_UPARROW         32753
OBM_DNARROW         32752
OBM_RGARROW         32751
OBM_LFARROW         32750
OBM_REDUCE          32749
OBM_ZOOM            32748
OBM_RESTORE         32747
OBM_REDUCED         32746
OBM_ZOOMD           32745
OBM_RESTORED        32744
OBM_UPARROWD        32743
OBM_DNARROWD        32742
OBM_RGARROWD        32741
OBM_LFARROWD        32740
OBM_MNARROW         32739
OBM_COMBO           32738
OBM_UPARROWI        32737
OBM_DNARROWI        32736
OBM_RGARROWI        32735
OBM_LFARROWI        32734
OBM_SIZE            32766
OBM_BTSIZE          32761
OBM_CHECK           32760
OBM_CHECKBOXES      32759
OBM_BTNCORNERS      32758

# OEM Icon IDs
OIC_SAMPLE          32512
OIC_HAND            32513
OIC_QUES            32514
OIC_BANG            32515
OIC_NOTE            32516
OIC_WINLOGO         32517
OIC_WARNING         32515   # OIC_BANG
OIC_ERROR           32513   # OIC_HAND
OIC_INFORMATION     32516   # OIC_NOTE

# Owner Draw Types
ODT_MENU        1
ODT_LISTBOX     2
ODT_COMBOBOX    3
ODT_BUTTON      4
ODT_STATIC      5
ODT_HEADER      100
ODT_TAB         101
ODT_LISTVIEW    102

# Owner Draw Actions
ODA_DRAWENTIRE  0x0001
ODA_SELECT      0x0002
ODA_FOCUS       0x0004

# Owner Draw States
ODS_SELECTED    0x0001
ODS_GRAYED      0x0002
ODS_DISABLED    0x0004
ODS_CHECKED     0x0008
ODS_FOCUS       0x0010
ODS_DEFAULT         0x0020
ODS_COMBOBOXEDIT    0x1000
ODS_HOTLIGHT        0x0040
ODS_INACTIVE        0x0080
ODS_NOACCEL         0x0100
ODS_NOFOCUSRECT     0x0200

# Listbox return values
LB_OKAY             0
LB_ERR              -1
LB_ERRSPACE         -2

# Listbox messages
LB_ADDSTRING            0x0180
LB_INSERTSTRING         0x0181
LB_DELETESTRING         0x0182
LB_SELITEMRANGEEX       0x0183
LB_RESETCONTENT         0x0184
LB_SETSEL               0x0185
LB_SETCURSEL            0x0186
LB_GETSEL               0x0187
LB_GETCURSEL            0x0188
LB_GETTEXT              0x0189
LB_GETTEXTLEN           0x018A
LB_GETCOUNT             0x018B
LB_SELECTSTRING         0x018C
LB_DIR                  0x018D
LB_GETTOPINDEX          0x018E
LB_FINDSTRING           0x018F
LB_GETSELCOUNT          0x0190
LB_GETSELITEMS          0x0191
LB_SETTABSTOPS          0x0192
LB_GETHORIZONTALEXTENT  0x0193
LB_SETHORIZONTALEXTENT  0x0194
LB_SETCOLUMNWIDTH       0x0195
LB_ADDFILE              0x0196
LB_SETTOPINDEX          0x0197
LB_GETITEMRECT          0x0198
LB_GETITEMDATA          0x0199
LB_SETITEMDATA          0x019A
LB_SELITEMRANGE         0x019B
LB_SETANCHORINDEX       0x019C
LB_GETANCHORINDEX       0x019D
LB_SETCARETINDEX        0x019E
LB_GETCARETINDEX        0x019F
LB_SETITEMHEIGHT        0x01A0
LB_GETITEMHEIGHT        0x01A1
LB_FINDSTRINGEXACT      0x01A2
LB_SETLOCALE            0x01A5
LB_GETLOCALE            0x01A6
LB_SETCOUNT             0x01A7
LB_INITSTORAGE          0x01A8
LB_ITEMFROMPOINT        0x01A9
LB_MULTIPLEADDSTRING    0x01B1
LB_GETLISTBOXINFO       0x01B2

# Listbox notifications
LBN_ERRSPACE        -2
LBN_SELCHANGE       1
LBN_DBLCLK          2
LBN_SELCANCEL       3
LBN_SETFOCUS        4
LBN_KILLFOCUS       5

# Listbox styles
LBS_NOTIFY            0x0001
LBS_SORT              0x0002
LBS_NOREDRAW          0x0004
LBS_MULTIPLESEL       0x0008
LBS_OWNERDRAWFIXED    0x0010
LBS_OWNERDRAWVARIABLE 0x0020
LBS_HASSTRINGS        0x0040
LBS_USETABSTOPS       0x0080
LBS_NOINTEGRALHEIGHT  0x0100
LBS_MULTICOLUMN       0x0200
LBS_WANTKEYBOARDINPUT 0x0400
LBS_EXTENDEDSEL       0x0800
LBS_DISABLENOSCROLL   0x1000
LBS_NODATA            0x2000
LBS_NOSEL             0x4000
LBS_COMBOBOX          0x8000
LBS_STANDARD          0x00300003  # (LBS_NOTIFY | LBS_SORT | WS_VSCROLL | WS _BORDER)

# Listview styles
LVS_ICON                0x0000
LVS_REPORT              0x0001
LVS_SMALLICON           0x0002
LVS_LIST                0x0003
LVS_TYPEMASK            0x0003
LVS_SINGLESEL           0x0004
LVS_SHOWSELALWAYS       0x0008
LVS_SORTASCENDING       0x0010
LVS_SORTDESCENDING      0x0020
LVS_SHAREIMAGELISTS     0x0040
LVS_NOLABELWRAP         0x0080
LVS_AUTOARRANGE         0x0100
LVS_EDITLABELS          0x0200
LVS_OWNERDATA           0x1000
LVS_NOSCROLL            0x2000
LVS_TYPESTYLEMASK       0xfc00
LVS_ALIGNTOP            0x0000
LVS_ALIGNLEFT           0x0800
LVS_ALIGNMASK           0x0c00
LVS_OWNERDRAWFIXED      0x0400
LVS_NOCOLUMNHEADER      0x4000
LVS_NOSORTHEADER        0x8000

# Listview extended styles
LVS_EX_GRIDLINES        0x00000001
LVS_EX_SUBITEMIMAGES    0x00000002
LVS_EX_CHECKBOXES       0x00000004
LVS_EX_TRACKSELECT      0x00000008
LVS_EX_HEADERDRAGDROP   0x00000010
LVS_EX_FULLROWSELECT    0x00000020
LVS_EX_ONECLICKACTIVATE 0x00000040
LVS_EX_TWOCLICKACTIVATE 0x00000080
LVS_EX_FLATSB           0x00000100
LVS_EX_REGIONAL         0x00000200
LVS_EX_INFOTIP          0x00000400
LVS_EX_UNDERLINEHOT     0x00000800
LVS_EX_UNDERLINECOLD    0x00001000
LVS_EX_MULTIWORKAREAS   0x00002000
LVS_EX_LABELTIP         0x00004000
LVS_EX_BORDERSELECT     0x00008000
LVS_EX_DOUBLEBUFFER     0x00010000
LVS_EX_HIDELABELS       0x00020000
LVS_EX_SINGLEROW        0x00040000
LVS_EX_SNAPTOGRID       0x00080000
LVS_EX_SIMPLESELECT     0x00100000

# Listview Item States
LVIS_FOCUSED            0x0001
LVIS_SELECTED           0x0002
LVIS_CUT                0x0004
LVIS_DROPHILITED        0x0008
LVIS_GLOW               0x0010
LVIS_ACTIVATING         0x0020
LVIS_OVERLAYMASK        0x0F00
LVIS_STATEIMAGEMASK     0xF000

# Listview ??
LVSIL_NORMAL            0
LVSIL_SMALL             1
LVSIL_STATE             2

# Listview ??
LVIR_BOUNDS             0
LVIR_ICON               1
LVIR_LABEL              2
LVIR_SELECTBOUNDS       3

# LoadResource() constants
LR_DEFAULTCOLOR                0x0000      
LR_MONOCHROME                  0x0001      
LR_COLOR                       0x0002      
LR_COPYRETURNORG               0x0004      
LR_COPYDELETEORG               0x0008      
LR_LOADFROMFILE                0x0010      
LR_LOADTRANSPARENT             0x0020      
LR_DEFAULTSIZE                 0x0040      
LR_VGACOLOR                    0x0080      
LR_LOADMAP3DCOLORS             0x1000      
LR_CREATEDIBSECTION            0x2000      
LR_COPYFROMRESOURCE            0x4000      
LR_SHARED                      0x8000      

# WM_MOUSEACTIVATE Return Codes
MA_ACTIVATE                    1           
MA_ACTIVATEANDEAT              2           
MA_NOACTIVATE                  3           
MA_NOACTIVATEANDEAT            4           

# MessageBox() flags
MB_OK                          0x00000000  
MB_OKCANCEL                    0x00000001  
MB_ABORTRETRYIGNORE            0x00000002  
MB_YESNOCANCEL                 0x00000003  
MB_YESNO                       0x00000004  
MB_RETRYCANCEL                 0x00000005  
MB_CANCELTRYCONTINUE           0x00000006  
MB_ICONHAND                    0x00000010  
MB_ICONQUESTION                0x00000020  
MB_ICONEXCLAMATION             0x00000030  
MB_ICONASTERISK                0x00000040  
MB_USERICON                    0x00000080  
MB_ICONWARNING                 0x00000030  # MB_ICONEXCLAMATION
MB_ICONERROR                   0x00000010  # MB_ICONHAND
MB_ICONINFORMATION             0x00000040  # MB_ICONASTERISK
MB_ICONSTOP                    0x00000010  # MB_ICONHAND
MB_DEFBUTTON1                  0x00000000  
MB_DEFBUTTON2                  0x00000100  
MB_DEFBUTTON3                  0x00000200  
MB_DEFBUTTON4                  0x00000300  
MB_APPLMODAL                   0x00000000  
MB_SYSTEMMODAL                 0x00001000  
MB_TASKMODAL                   0x00002000  
MB_HELP                        0x00004000  
MB_NOFOCUS                     0x00008000  
MB_SETFOREGROUND               0x00010000  
MB_DEFAULT_DESKTOP_ONLY        0x00020000  
MB_TOPMOST                     0x00040000  
MB_RIGHT                       0x00080000  
MB_RTLREADING                  0x00100000  
MB_SERVICE_NOTIFICATION        0x00200000  
MB_SERVICE_NOTIFICATION_NT3X   0x00040000  
MB_TYPEMASK                    0x0000000F  
MB_ICONMASK                    0x000000F0  
MB_DEFMASK                     0x00000F00  
MB_MODEMASK                    0x00003000  
MB_MISCMASK                    0x0000C000  

#MonthCal control states
MCS_DAYSTATE        0x0001
MCS_MULTISELECT     0x0002
MCS_WEEKNUMBERS     0x0004
MCS_NOTODAYCIRCLE   0x0008
MCS_NOTODAY         0x0010

# MonthCal Control - portions of the control
MCSC_BACKGROUND                0           
MCSC_TEXT                      1           
MCSC_TITLEBK                   2           
MCSC_TITLETEXT                 3           
MCSC_MONTHBK                   4           
MCSC_TRAILINGTEXT              5           

# Flags for Add/Check/Enable MenuItem
MF_CHANGE                      0x00000080  
MF_APPEND                      0x00000100  
MF_DELETE                      0x00000200  
MF_REMOVE                      0x00001000  
MF_BYCOMMAND                   0x00000000  
MF_BYPOSITION                  0x00000400  
MF_SEPARATOR                   0x00000800  
MF_ENABLED                     0x00000000  
MF_GRAYED                      0x00000001  
MF_DISABLED                    0x00000002  
MF_UNCHECKED                   0x00000000  
MF_CHECKED                     0x00000008  
MF_USECHECKBITMAPS             0x00000200  
MF_STRING                      0x00000000  
MF_BITMAP                      0x00000004  
MF_OWNERDRAW                   0x00000100  
MF_POPUP                       0x00000010  
MF_MENUBARBREAK                0x00000020  
MF_MENUBREAK                   0x00000040  
MF_UNHILITE                    0x00000000  
MF_HILITE                      0x00000080  
MF_DEFAULT                     0x00001000  
MF_SYSMENU                     0x00002000  
MF_HELP                        0x00004000  
MF_RIGHTJUSTIFY                0x00004000  
MF_MOUSESELECT                 0x00008000  

# Key State Masks for Mouse Messages
MK_LBUTTON                     0x0001      
MK_RBUTTON                     0x0002      
MK_SHIFT                       0x0004      
MK_CONTROL                     0x0008      
MK_MBUTTON                     0x0010      
MK_XBUTTON1                    0x0020      
MK_XBUTTON2                    0x0040      

# Notify Message codes
NM_OUTOFMEMORY                 -1
NM_CLICK                       -2
NM_DBLCLK                      -3
NM_RETURN                      -4
NM_RCLICK                      -5
NM_RDBLCLK                     -6
NM_SETFOCUS                    -7
NM_KILLFOCUS                   -8
NM_CUSTOMDRAW                  -12
NM_HOVER                       -13
NM_NCHITTEST                   -14
NM_KEYDOWN                     -15
NM_RELEASEDCAPTURE             -16
NM_SETCURSOR                   -17
NM_CHAR                        -18
NM_TOOLTIPSCREATED             -19
NM_LDOWN                       -20
NM_RDOWN                       -21
NM_THEMECHANGED                -22

# Object Definitions for EnumObjects()
OBJ_PEN                        1           
OBJ_BRUSH                      2           
OBJ_DC                         3           
OBJ_METADC                     4           
OBJ_PAL                        5           
OBJ_FONT                       6           
OBJ_BITMAP                     7           
OBJ_REGION                     8           
OBJ_METAFILE                   9           
OBJ_MEMDC                      10          
OBJ_EXTPEN                     11          
OBJ_ENHMETADC                  12          
OBJ_ENHMETAFILE                13          
OBJ_COLORSPACE                 14          

# Binary raster ops
R2_BLACK                       1           
R2_NOTMERGEPEN                 2           
R2_MASKNOTPEN                  3           
R2_NOTCOPYPEN                  4           
R2_MASKPENNOT                  5           
R2_NOT                         6           
R2_XORPEN                      7           
R2_NOTMASKPEN                  8           
R2_MASKPEN                     9           
R2_NOTXORPEN                   10          
R2_NOP                         11          
R2_MERGENOTPEN                 12          
R2_COPYPEN                     13          
R2_MERGEPENNOT                 14          
R2_MERGEPEN                    15          
R2_WHITE                       16          

# Ternary raster operations
SRCCOPY                        0x00CC0020  
SRCPAINT                       0x00EE0086  
SRCAND                         0x008800C6  
SRCINVERT                      0x00660046  
SRCERASE                       0x00440328  
NOTSRCCOPY                     0x00330008  
NOTSRCERASE                    0x001100A6  
MERGECOPY                      0x00C000CA  
MERGEPAINT                     0x00BB0226  
PATCOPY                        0x00F00021  
PATPAINT                       0x00FB0A09  
PATINVERT                      0x005A0049  
DSTINVERT                      0x00550009  
BLACKNESS                      0x00000042  
WHITENESS                      0x00FF0062  
NOMIRRORBITMAP                 0x80000000  
CAPTUREBLT                     0x40000000  

# ReBar Band styles
RBBS_BREAK                     0x00000001  
RBBS_FIXEDSIZE                 0x00000002  
RBBS_CHILDEDGE                 0x00000004  
RBBS_HIDDEN                    0x00000008  
RBBS_NOVERT                    0x00000010  
RBBS_FIXEDBMP                  0x00000020  
RBBS_VARIABLEHEIGHT            0x00000040  
RBBS_GRIPPERALWAYS             0x00000080  
RBBS_NOGRIPPER                 0x00000100  
RBBS_USECHEVRON                0x00000200  
RBBS_HIDETITLE                 0x00000400  
RBBS_TOPALIGN                  0x00000800  

# RedrawWindow() flags
RDW_INVALIDATE                 0x0001      
RDW_INTERNALPAINT              0x0002      
RDW_ERASE                      0x0004      
RDW_VALIDATE                   0x0008      
RDW_NOINTERNALPAINT            0x0010      
RDW_NOERASE                    0x0020      
RDW_NOCHILDREN                 0x0040      
RDW_ALLCHILDREN                0x0080      
RDW_UPDATENOW                  0x0100      
RDW_ERASENOW                   0x0200      
RDW_FRAME                      0x0400      
RDW_NOFRAME                    0x0800      

# Region Flags
ERROR                          0           
NULLREGION                     1           
SIMPLEREGION                   2           
COMPLEXREGION                  3           
RGN_ERROR                      0           # ERROR

# CombineRgn() Styles
RGN_AND                        1           
RGN_OR                         2           
RGN_XOR                        3           
RGN_DIFF                       4           
RGN_COPY                       5           
RGN_MIN                        1           # RGN_AND
RGN_MAX                        5           # RGN_COPY

# Scroll Bar Commands
SB_LINEUP                      0           
SB_LINELEFT                    0           
SB_LINEDOWN                    1           
SB_LINERIGHT                   1           
SB_PAGEUP                      2           
SB_PAGELEFT                    2           
SB_PAGEDOWN                    3           
SB_PAGERIGHT                   3           
SB_THUMBPOSITION               4           
SB_THUMBTRACK                  5           
SB_TOP                         6           
SB_LEFT                        6           
SB_BOTTOM                      7           
SB_RIGHT                       7           
SB_ENDSCROLL                   8           

# scroll Bar Constants
SB_HORZ                        0           
SB_VERT                        1           
SB_CTL                         2           
SB_BOTH                        3           

# Scroll bar messages
SBM_SETPOS                  0x00E0
SBM_GETPOS                  0x00E1
SBM_SETRANGE                0x00E2
SBM_SETRANGEREDRAW          0x00E6
SBM_GETRANGE                0x00E3
SBM_ENABLE_ARROWS           0x00E4
SBM_SETSCROLLINFO           0x00E9
SBM_GETSCROLLINFO           0x00EA
SBM_GETSCROLLBARINFO        0x00EB

# Scroll Bar styles
SBS_HORZ                    0x0000
SBS_VERT                    0x0001
SBS_TOPALIGN                0x0002
SBS_LEFTALIGN               0x0002
SBS_BOTTOMALIGN             0x0004
SBS_RIGHTALIGN              0x0004
SBS_SIZEBOXTOPLEFTALIGN     0x0002
SBS_SIZEBOXBOTTOMRIGHTALIGN 0x0004
SBS_SIZEBOX                 0x0008
SBS_SIZEGRIP                0x0010

# Status Bar styles 
SBT_OWNERDRAW                  0x1000      
SBT_NOBORDERS                  0x0100      
SBT_POPOUT                     0x0200      
SBT_RTLREADING                 0x0400      
SBT_NOTABPARSING               0x0800      

# System Menu Command Values
SC_SIZE                        0xF000      
SC_MOVE                        0xF010      
SC_MINIMIZE                    0xF020      
SC_MAXIMIZE                    0xF030      
SC_NEXTWINDOW                  0xF040      
SC_PREVWINDOW                  0xF050      
SC_CLOSE                       0xF060      
SC_VSCROLL                     0xF070      
SC_HSCROLL                     0xF080      
SC_MOUSEMENU                   0xF090      
SC_KEYMENU                     0xF100      
SC_ARRANGE                     0xF110      
SC_RESTORE                     0xF120      
SC_TASKLIST                    0xF130      
SC_SCREENSAVE                  0xF140      
SC_HOTKEY                      0xF150      
SC_DEFAULT                     0xF160      
SC_MONITORPOWER                0xF170      
SC_CONTEXTHELP                 0xF180      
SC_SEPARATOR                   0xF00F      
SC_ICON                        0xF020      # SC_MINIMIZE
SC_ZOOM                        0xF030      # SC_MAXIMIZE

# Richedit Stream formats Flags
SF_TEXT                        0x0001      
SF_RTF                         0x0002      
SF_RTFNOOBJS                   0x0003      
SF_TEXTIZED                    0x0004      
SF_UNICODE                     0x0010      
SF_USECODEPAGE                 0x0020      
SF_NCRFORNONASCII              0x40        
SFF_WRITEXTRAPAR               0x80        
SFF_SELECTION                  0x8000      
SFF_PLAINRTF                   0x4000      
SFF_PERSISTVIEWSCALE           0x2000      
SFF_KEEPDOCINFO                0x1000      
SFF_PWD                        0x0800      
SF_RTFVAL                      0x0700      

# WM_SIZE message wParam values
SIZE_RESTORED                  0           
SIZE_MINIMIZED                 1           
SIZE_MAXIMIZED                 2           
SIZE_MAXSHOW                   3           
SIZE_MAXHIDE                   4           

# GetSystemMetrics() codes
SM_CXSCREEN                    0           
SM_CYSCREEN                    1           
SM_CXVSCROLL                   2           
SM_CYHSCROLL                   3           
SM_CYCAPTION                   4           
SM_CXBORDER                    5           
SM_CYBORDER                    6           
SM_CXDLGFRAME                  7           
SM_CYDLGFRAME                  8           
SM_CYVTHUMB                    9           
SM_CXHTHUMB                    10          
SM_CXICON                      11          
SM_CYICON                      12          
SM_CXCURSOR                    13          
SM_CYCURSOR                    14          
SM_CYMENU                      15          
SM_CXFULLSCREEN                16          
SM_CYFULLSCREEN                17          
SM_CYKANJIWINDOW               18          
SM_MOUSEPRESENT                19          
SM_CYVSCROLL                   20          
SM_CXHSCROLL                   21          
SM_DEBUG                       22          
SM_SWAPBUTTON                  23          
SM_RESERVED1                   24          
SM_RESERVED2                   25          
SM_RESERVED3                   26          
SM_RESERVED4                   27          
SM_CXMIN                       28          
SM_CYMIN                       29          
SM_CXSIZE                      30          
SM_CYSIZE                      31          
SM_CXFRAME                     32          
SM_CYFRAME                     33          
SM_CXMINTRACK                  34          
SM_CYMINTRACK                  35          
SM_CXDOUBLECLK                 36          
SM_CYDOUBLECLK                 37          
SM_CXICONSPACING               38          
SM_CYICONSPACING               39          
SM_MENUDROPALIGNMENT           40          
SM_PENWINDOWS                  41          
SM_DBCSENABLED                 42          
SM_CMOUSEBUTTONS               43          
SM_CXFIXEDFRAME                7           #  SM_CXDLGFRAME
SM_CYFIXEDFRAME                8           #  SM_CYDLGFRAME
SM_CXSIZEFRAME                 32          #  SM_CXFRAME
SM_CYSIZEFRAME                 33          #  SM_CYFRAME
SM_SECURE                      44          
SM_CXEDGE                      45          
SM_CYEDGE                      46          
SM_CXMINSPACING                47          
SM_CYMINSPACING                48          
SM_CXSMICON                    49          
SM_CYSMICON                    50          
SM_CYSMCAPTION                 51          
SM_CXSMSIZE                    52          
SM_CYSMSIZE                    53          
SM_CXMENUSIZE                  54          
SM_CYMENUSIZE                  55          
SM_ARRANGE                     56          
SM_CXMINIMIZED                 57          
SM_CYMINIMIZED                 58          
SM_CXMAXTRACK                  59          
SM_CYMAXTRACK                  60          
SM_CXMAXIMIZED                 61          
SM_CYMAXIMIZED                 62          
SM_NETWORK                     63          
SM_CLEANBOOT                   67          
SM_CXDRAG                      68          
SM_CYDRAG                      69          
SM_SHOWSOUNDS                  70          
SM_CXMENUCHECK                 71          
SM_CYMENUCHECK                 72          
SM_SLOWMACHINE                 73          
SM_MIDEASTENABLED              74          
SM_MOUSEWHEELPRESENT           75          
SM_XVIRTUALSCREEN              76          
SM_YVIRTUALSCREEN              77          
SM_CXVIRTUALSCREEN             78          
SM_CYVIRTUALSCREEN             79          
SM_CMONITORS                   80          
SM_SAMEDISPLAYFORMAT           81          
SM_IMMENABLED                  82          
SM_CXFOCUSBORDER               83          
SM_CYFOCUSBORDER               84          
SM_TABLETPC                    86          
SM_MEDIACENTER                 87          
SM_STARTER                     88          
SM_SERVERR2                    89          
SM_CMETRICS                    90          
SM_REMOTESESSION               0x1000      
SM_SHUTTINGDOWN                0x2000      
SM_REMOTECONTROL               0x2001      
SM_CARETBLINKINGENABLED        0x2002      

# SendMessageTimeout values
SMTO_NORMAL                    0x0000      
SMTO_BLOCK                     0x0001      
SMTO_ABORTIFHUNG               0x0002      
SMTO_NOTIMEOUTIFNOTHUNG        0x0008      

# Stock Logical Objects
WHITE_BRUSH                    0           
LTGRAY_BRUSH                   1           
GRAY_BRUSH                     2           
DKGRAY_BRUSH                   3           
BLACK_BRUSH                    4           
NULL_BRUSH                     5           
HOLLOW_BRUSH                   5           # NULL_BRUSH
WHITE_PEN                      6           
BLACK_PEN                      7           
NULL_PEN                       8           
OEM_FIXED_FONT                 10          
ANSI_FIXED_FONT                11          
ANSI_VAR_FONT                  12          
SYSTEM_FONT                    13          
DEVICE_DEFAULT_FONT            14          
DEFAULT_PALETTE                15          
SYSTEM_FIXED_FONT              16          
DEFAULT_GUI_FONT               17          
DC_BRUSH                       18          
DC_PEN                         19          

# Brush Styles
BS_SOLID                       0           
BS_NULL                        1           
BS_HOLLOW                      1           # BS_NULL
BS_HATCHED                     2           
BS_PATTERN                     3           
BS_INDEXED                     4           
BS_DIBPATTERN                  5           
BS_DIBPATTERNPT                6           
BS_PATTERN8X8                  7           
BS_DIBPATTERN8X8               8           
BS_MONOPATTERN                 9           

# Hatch Styles
HS_HORIZONTAL                  0           
HS_VERTICAL                    1           
HS_FDIAGONAL                   2           
HS_BDIAGONAL                   3           
HS_CROSS                       4           
HS_DIAGCROSS                   5           

# ProgressBar messages
PBM_SETRANGE            1025 #(WM_USER+1)
PBM_SETPOS              1026 #(WM_USER+2)
PBM_DELTAPOS            1027 #(WM_USER+3)
PBM_SETSTEP             1028 #(WM_USER+4)
PBM_STEPIT              1029 #(WM_USER+5)
PBM_SETRANGE32          1030 #(WM_USER+6)
PBM_GETRANGE            1031 #(WM_USER+7)
PBM_GETPOS              1032 #(WM_USER+8)
PBM_SETBARCOLOR         1033 #(WM_USER+9)
PBM_SETBKCOLOR          0x2001 #CCM_SETBKCOLOR (CCM_FIRST+1)
PBM_SETMARQUEE          1035 #(WM_USER+10)

# ProgressBar styles
PBS_SMOOTH              0x01
PBS_VERTICAL            0x04
PBS_MARQUEE             0x08

# Pen Styles
PS_SOLID                       0           
PS_DASH                        1           
PS_DOT                         2           
PS_DASHDOT                     3           
PS_DASHDOTDOT                  4           
PS_NULL                        5           
PS_INSIDEFRAME                 6           
PS_USERSTYLE                   7           
PS_ALTERNATE                   8           
PS_STYLE_MASK                  0x0000000F  
PS_ENDCAP_ROUND                0x00000000  
PS_ENDCAP_SQUARE               0x00000100  
PS_ENDCAP_FLAT                 0x00000200  
PS_ENDCAP_MASK                 0x00000F00  
PS_JOIN_ROUND                  0x00000000  
PS_JOIN_BEVEL                  0x00001000  
PS_JOIN_MITER                  0x00002000  
PS_JOIN_MASK                   0x0000F000  
PS_COSMETIC                    0x00000000  
PS_GEOMETRIC                   0x00010000  
PS_TYPE_MASK                   0x000F0000  

# StretchBlt() Modes
BLACKONWHITE                   1           
WHITEONBLACK                   2           
COLORONCOLOR                   3           
HALFTONE                       4           
STRETCH_ANDSCANS               1           # BLACKONWHITE
STRETCH_ORSCANS                2           # WHITEONBLACK
STRETCH_DELETESCANS            3           # COLORONCOLOR
STRETCH_HALFTONE               4           # HALFTONE

# ShellExecute() and ShellExecuteEx() error codes
SE_ERR_FNF                     2           
SE_ERR_PNF                     3           
SE_ERR_ACCESSDENIED            5           
SE_ERR_OOM                     8           
SE_ERR_DLLNOTFOUND             32          
SE_ERR_SHARE                   26          
SE_ERR_ASSOCINCOMPLETE         27          
SE_ERR_DDETIMEOUT              28          
SE_ERR_DDEFAIL                 29          
SE_ERR_DDEBUSY                 30          
SE_ERR_NOASSOC                 31          

# Static Control Messages
STM_SETICON         0x0170
STM_GETICON         0x0171
STM_SETIMAGE        0x0172
STM_GETIMAGE        0x0173
STM_MSGMAX          0x0174

# Static Control Notifications
STN_CLICKED         0
STN_DBLCLK          1
STN_ENABLE          2
STN_DISABLE         3

# ShowWindow() commands
SW_HIDE                        0           
SW_SHOWNORMAL                  1           
SW_NORMAL                      1           
SW_SHOWMINIMIZED               2           
SW_SHOWMAXIMIZED               3           
SW_MAXIMIZE                    3           
SW_SHOWNOACTIVATE              4           
SW_SHOW                        5           
SW_MINIMIZE                    6           
SW_SHOWMINNOACTIVE             7           
SW_SHOWNA                      8           
SW_RESTORE                     9           
SW_SHOWDEFAULT                 10          
SW_FORCEMINIMIZE               11          

# SetWindowPos() Flags
SWP_NOSIZE                     0x0001      
SWP_NOMOVE                     0x0002      
SWP_NOZORDER                   0x0004      
SWP_NOREDRAW                   0x0008      
SWP_NOACTIVATE                 0x0010      
SWP_FRAMECHANGED               0x0020      
SWP_SHOWWINDOW                 0x0040      
SWP_HIDEWINDOW                 0x0080      
SWP_NOCOPYBITS                 0x0100      
SWP_NOOWNERZORDER              0x0200      
SWP_NOSENDCHANGING             0x0400      
SWP_DRAWFRAME                  0x0020      # SWP_FRAMECHANGED
SWP_NOREPOSITION               0x0200      # SWP_NOOWNERZORDER
SWP_DEFERERASE                 0x2000      
SWP_ASYNCWINDOWPOS             0x4000      
HWND_TOP                       0           
HWND_BOTTOM                    1           
HWND_TOPMOST                   -1          
HWND_NOTOPMOST                 -2          

# Text Align constants (use with SetTextAlign)
TA_NOUPDATECP     0
TA_UPDATECP       1
TA_LEFT           0
TA_RIGHT          2
TA_CENTER         6
TA_TOP            0
TA_BOTTOM         8
TA_BASELINE      24
TA_RTLREADING   256
TA_MASK         287 # (TA_BASELINE+TA_CENTER+TA_UPDATECP+TA_RTLREADING)
VTA_BASELINE     24 # TA_BASELINE
VTA_LEFT          8 # TA_BOTTOM
VTA_RIGHT         0 # TA_TOP
VTA_CENTER        6 # TA_CENTER
VTA_BOTTOM        2 # TA_RIGHT
VTA_TOP           0 # TA_LEFT

# Toolbar button states
TBSTATE_CHECKED                0x01        
TBSTATE_PRESSED                0x02        
TBSTATE_ENABLED                0x04        
TBSTATE_HIDDEN                 0x08        
TBSTATE_INDETERMINATE          0x10        
TBSTATE_WRAP                   0x20        
TBSTATE_ELLIPSES               0x40        
TBSTATE_MARKED                 0x80        

# Toolbar styles
TBSTYLE_BUTTON                 0x0000      
TBSTYLE_SEP                    0x0001      
TBSTYLE_CHECK                  0x0002      
TBSTYLE_GROUP                  0x0004      
TBSTYLE_CHECKGROUP             0x0006      # (TBSTYLE_GROUP | TBSTYLE_CHECK)
TBSTYLE_DROPDOWN               0x0008      
TBSTYLE_AUTOSIZE               0x0010      
TBSTYLE_NOPREFIX               0x0020      
TBSTYLE_TOOLTIPS               0x0100      
TBSTYLE_WRAPABLE               0x0200      
TBSTYLE_ALTDRAG                0x0400      
TBSTYLE_FLAT                   0x0800      
TBSTYLE_LIST                   0x1000      
TBSTYLE_CUSTOMERASE            0x2000      
TBSTYLE_REGISTERDROP           0x4000      
TBSTYLE_TRANSPARENT            0x8000      

# Toolbar extended styles
TBSTYLE_EX_DRAWDDARROWS        0x00000001  
TBSTYLE_EX_MIXEDBUTTONS        0x00000008  
TBSTYLE_EX_HIDECLIPPEDBUTTONS  0x00000010  
TBSTYLE_EX_DOUBLEBUFFER        0x00000080  

# Track bar tip side
TBTS_TOP                       0           
TBTS_LEFT                      1           
TBTS_BOTTOM                    2           
TBTS_RIGHT                     3           

# Flags for TrackMouseEvent()
TME_HOVER                      0x00000001  
TME_LEAVE                      0x00000002  
TME_NONCLIENT                  0x00000010  
TME_QUERY                      0x40000000  
TME_CANCEL                     0x80000000  
HOVER_DEFAULT                  0xFFFFFFFF  

# Flags for TrackPopupMenu
TPM_LEFTBUTTON                 0x0000      
TPM_RIGHTBUTTON                0x0002      
TPM_LEFTALIGN                  0x0000      
TPM_CENTERALIGN                0x0004      
TPM_RIGHTALIGN                 0x0008      
TPM_TOPALIGN                   0x0000      
TPM_VCENTERALIGN               0x0010      
TPM_BOTTOMALIGN                0x0020      
TPM_HORIZONTAL                 0x0000      
TPM_VERTICAL                   0x0040      
TPM_NONOTIFY                   0x0080      
TPM_RETURNCMD                  0x0100      
TPM_RECURSE                    0x0001      
TPM_HORPOSANIMATION            0x0400      
TPM_HORNEGANIMATION            0x0800      
TPM_VERPOSANIMATION            0x1000      
TPM_VERNEGANIMATION            0x2000      
TPM_NOANIMATION                0x4000      
TPM_LAYOUTRTL                  0x8000      

# Tool tip Delay Time flags
TTDT_AUTOMATIC                 0           
TTDT_RESHOW                    1           
TTDT_AUTOPOP                   2           
TTDT_INITIAL                   3           

# Tool tip flags
TTF_IDISHWND                   1
TTF_CENTERTIP                  2
TTF_RTLREADING                 4
TTF_SUBCLASS                   16
TTF_TRACK                      0x0020
TTF_ABSOLUTE                   0x0080
TTF_TRANSPARENT                0x0100
TTF_PARSELINKS                 0x1000
TTF_DI_SETITEM                 0x8000

# Tool tip messages
TTM_ACTIVATE           1025   #(WM_USER+1)
TTM_SETDELAYTIME       1027   #(WM_USER+3)
TTM_ADDTOOL            1028   #(WM_USER+4)
TTM_DELTOOL            1029   #(WM_USER+5)
TTM_NEWTOOLRECT        1030   #(WM_USER+6)
TTM_RELAYEVENT         1031   #(WM_USER+7)
TTM_GETTOOLINFO        1032   #(WM_USER+8)
TTM_SETTOOLINFO        1033   #(WM_USER+9)
TTM_HITTEST            1034   #(WM_USER+10)
TTM_GETTEXT            1035   #(WM_USER+11)
TTM_UPDATETIPTEXT      1036   #(WM_USER+12)
TTM_GETTOOLCOUNT       1037   #(WM_USER+13)
TTM_ENUMTOOLS          1038   #(WM_USER+14)
TTM_GETCURRENTTOOL     1039   #(WM_USER+15)
TTM_WINDOWFROMPOINT    1040   #(WM_USER+16)
TTM_TRACKACTIVATE      1041   #(WM_USER+17)  
TTM_TRACKPOSITION      1042   #(WM_USER+18)  
TTM_SETTIPBKCOLOR      1043   #(WM_USER+19)
TTM_SETTIPTEXTCOLOR    1044   #(WM_USER+20)
TTM_GETDELAYTIME       1045   #(WM_USER+21)
TTM_GETTIPBKCOLOR      1046   #(WM_USER+22)
TTM_GETTIPTEXTCOLOR    1047   #(WM_USER+23)
TTM_SETMAXTIPWIDTH     1048   #(WM_USER+24)
TTM_GETMAXTIPWIDTH     1049   #(WM_USER+25)
TTM_SETMARGIN          1050   #(WM_USER+26)  
TTM_GETMARGIN          1051   #(WM_USER+27)  
TTM_POP	               1052   #(WM_USER+28)
TTM_UPDATE             1053   #(WM_USER+29)
TTM_GETBUBBLESIZE      1054   #(WM_USER+30)
TTM_ADJUSTRECT         1055   #(WM_USER+31)
TTM_SETTITLE           1056   #(WM_USER+32)

# Tool tip notification messages
TTN_GETDISPINFO        -520   #(TTN_FIRST - 0)
TTN_NEEDTEXT           -520   #TTN_GETDISPINFOA
TTN_SHOW               -521   #(TTN_FIRST-1)
TTN_POP                -522   #(TTN_FIRST-2)

# Treeview Get Next types
TVGN_ROOT                      0x0000      
TVGN_NEXT                      0x0001      
TVGN_PREVIOUS                  0x0002      
TVGN_PARENT                    0x0003      
TVGN_CHILD                     0x0004      
TVGN_FIRSTVISIBLE              0x0005      
TVGN_NEXTVISIBLE               0x0006      
TVGN_PREVIOUSVISIBLE           0x0007      
TVGN_DROPHILITE                0x0008      
TVGN_CARET                     0x0009      
TVGN_LASTVISIBLE               0x000A      

# Treeview hit test regions
TVHT_NOWHERE            0x0001
TVHT_ONITEMICON         0x0002
TVHT_ONITEMLABEL        0x0004
TVHT_ONITEM             0x0046  # (TVHT_ONITEMICON | TVHT_ONITEMLABEL | TVHT_ONITEMSTATEICON)
TVHT_ONITEMINDENT       0x0008
TVHT_ONITEMBUTTON       0x0010
TVHT_ONITEMRIGHT        0x0020
TVHT_ONITEMSTATEICON    0x0040
TVHT_ABOVE              0x0100
TVHT_BELOW              0x0200
TVHT_TORIGHT            0x0400
TVHT_TOLEFT             0x0800

# Virtual Keys
VK_LBUTTON                     0x01        
VK_RBUTTON                     0x02        
VK_CANCEL                      0x03        
VK_MBUTTON                     0x04        
VK_XBUTTON1                    0x05        
VK_XBUTTON2                    0x06        
VK_BACK                        0x08        
VK_TAB                         0x09        
VK_CLEAR                       0x0C        
VK_RETURN                      0x0D        
VK_SHIFT                       0x10        
VK_CONTROL                     0x11        
VK_MENU                        0x12        
VK_PAUSE                       0x13        
VK_CAPITAL                     0x14        
VK_KANA                        0x15        
VK_HANGEUL                     0x15        
VK_HANGUL                      0x15        
VK_JUNJA                       0x17        
VK_FINAL                       0x18        
VK_HANJA                       0x19        
VK_KANJI                       0x19        
VK_ESCAPE                      0x1B        
VK_CONVERT                     0x1C        
VK_NONCONVERT                  0x1D        
VK_ACCEPT                      0x1E        
VK_MODECHANGE                  0x1F        
VK_SPACE                       0x20        
VK_PRIOR                       0x21        
VK_NEXT                        0x22        
VK_END                         0x23        
VK_HOME                        0x24        
VK_LEFT                        0x25        
VK_UP                          0x26        
VK_RIGHT                       0x27        
VK_DOWN                        0x28        
VK_SELECT                      0x29        
VK_PRINT                       0x2A        
VK_EXECUTE                     0x2B        
VK_SNAPSHOT                    0x2C        
VK_INSERT                      0x2D        
VK_DELETE                      0x2E        
VK_HELP                        0x2F        
VK_0                           0x30        
VK_1                           0x31        
VK_2                           0x32        
VK_3                           0x33        
VK_4                           0x34        
VK_5                           0x35        
VK_6                           0x36        
VK_7                           0x37        
VK_8                           0x38        
VK_9                           0x39        
VK_A                           0x41        
VK_B                           0x42        
VK_C                           0x43        
VK_D                           0x44        
VK_E                           0x45        
VK_F                           0x46        
VK_G                           0x47        
VK_H                           0x48        
VK_I                           0x49        
VK_J                           0x4A        
VK_K                           0x4B        
VK_L                           0x4C        
VK_M                           0x4D        
VK_N                           0x4E        
VK_O                           0x4F        
VK_P                           0x50        
VK_Q                           0x51        
VK_R                           0x52        
VK_S                           0x53        
VK_T                           0x54        
VK_U                           0x55        
VK_V                           0x56        
VK_W                           0x57        
VK_X                           0x58        
VK_Y                           0x59        
VK_Z                           0x5A        
VK_LWIN                        0x5B        
VK_RWIN                        0x5C        
VK_APPS                        0x5D        
VK_SLEEP                       0x5F        
VK_NUMPAD0                     0x60        
VK_NUMPAD1                     0x61        
VK_NUMPAD2                     0x62        
VK_NUMPAD3                     0x63        
VK_NUMPAD4                     0x64        
VK_NUMPAD5                     0x65        
VK_NUMPAD6                     0x66        
VK_NUMPAD7                     0x67        
VK_NUMPAD8                     0x68        
VK_NUMPAD9                     0x69        
VK_MULTIPLY                    0x6A        
VK_ADD                         0x6B        
VK_SEPARATOR                   0x6C        
VK_SUBTRACT                    0x6D        
VK_DECIMAL                     0x6E        
VK_DIVIDE                      0x6F        
VK_F1                          0x70        
VK_F2                          0x71        
VK_F3                          0x72        
VK_F4                          0x73        
VK_F5                          0x74        
VK_F6                          0x75        
VK_F7                          0x76        
VK_F8                          0x77        
VK_F9                          0x78        
VK_F10                         0x79        
VK_F11                         0x7A        
VK_F12                         0x7B        
VK_F13                         0x7C        
VK_F14                         0x7D        
VK_F15                         0x7E        
VK_F16                         0x7F        
VK_F17                         0x80        
VK_F18                         0x81        
VK_F19                         0x82        
VK_F20                         0x83        
VK_F21                         0x84        
VK_F22                         0x85        
VK_F23                         0x86        
VK_F24                         0x87        
VK_NUMLOCK                     0x90        
VK_SCROLL                      0x91        
VK_OEM_NEC_EQUAL               0x92        
VK_OEM_FJ_JISHO                0x92        
VK_OEM_FJ_MASSHOU              0x93        
VK_OEM_FJ_TOUROKU              0x94        
VK_OEM_FJ_LOYA                 0x95        
VK_OEM_FJ_ROYA                 0x96        
VK_LSHIFT                      0xA0        
VK_RSHIFT                      0xA1        
VK_LCONTROL                    0xA2        
VK_RCONTROL                    0xA3        
VK_LMENU                       0xA4        
VK_RMENU                       0xA5        
VK_BROWSER_BACK                0xA6        
VK_BROWSER_FORWARD             0xA7        
VK_BROWSER_REFRESH             0xA8        
VK_BROWSER_STOP                0xA9        
VK_BROWSER_SEARCH              0xAA        
VK_BROWSER_FAVORITES           0xAB        
VK_BROWSER_HOME                0xAC        
VK_VOLUME_MUTE                 0xAD        
VK_VOLUME_DOWN                 0xAE        
VK_VOLUME_UP                   0xAF        
VK_MEDIA_NEXT_TRACK            0xB0        
VK_MEDIA_PREV_TRACK            0xB1        
VK_MEDIA_STOP                  0xB2        
VK_MEDIA_PLAY_PAUSE            0xB3        
VK_LAUNCH_MAIL                 0xB4        
VK_LAUNCH_MEDIA_SELECT         0xB5        
VK_LAUNCH_APP1                 0xB6        
VK_LAUNCH_APP2                 0xB7        
VK_OEM_1                       0xBA        
VK_OEM_PLUS                    0xBB        
VK_OEM_COMMA                   0xBC        
VK_OEM_MINUS                   0xBD        
VK_OEM_PERIOD                  0xBE        
VK_OEM_2                       0xBF        
VK_OEM_3                       0xC0        
VK_OEM_4                       0xDB        
VK_OEM_5                       0xDC        
VK_OEM_6                       0xDD        
VK_OEM_7                       0xDE        
VK_OEM_8                       0xDF        
VK_OEM_AX                      0xE1        
VK_OEM_102                     0xE2        
VK_ICO_HELP                    0xE3        
VK_ICO_00                      0xE4        
VK_PROCESSKEY                  0xE5        
VK_ICO_CLEAR                   0xE6        
VK_PACKET                      0xE7        
VK_OEM_RESET                   0xE9        
VK_OEM_JUMP                    0xEA        
VK_OEM_PA1                     0xEB        
VK_OEM_PA2                     0xEC        
VK_OEM_PA3                     0xED        
VK_OEM_WSCTRL                  0xEE        
VK_OEM_CUSEL                   0xEF        
VK_OEM_ATTN                    0xF0        
VK_OEM_FINISH                  0xF1        
VK_OEM_COPY                    0xF2        
VK_OEM_AUTO                    0xF3        
VK_OEM_ENLW                    0xF4        
VK_OEM_BACKTAB                 0xF5        
VK_ATTN                        0xF6        
VK_CRSEL                       0xF7        
VK_EXSEL                       0xF8        
VK_EREOF                       0xF9        
VK_PLAY                        0xFA        
VK_ZOOM                        0xFB        
VK_NONAME                      0xFC        
VK_PA1                         0xFD        
VK_OEM_CLEAR                   0xFE        

# WM_ACTIVATE state values
WA_INACTIVE                    0           
WA_ACTIVE                      1           
WA_CLICKACTIVE                 2           

# Windows Messages
WM_NULL                        0x0000      
WM_CREATE                      0x0001      
WM_DESTROY                     0x0002      
WM_MOVE                        0x0003      
WM_SIZE                        0x0005      
WM_ACTIVATE                    0x0006      
WM_SETFOCUS                    0x0007      
WM_KILLFOCUS                   0x0008      
WM_ENABLE                      0x000A      
WM_SETREDRAW                   0x000B      
WM_SETTEXT                     0x000C      
WM_GETTEXT                     0x000D      
WM_GETTEXTLENGTH               0x000E      
WM_PAINT                       0x000F      
WM_CLOSE                       0x0010      
WM_QUERYENDSESSION             0x0011      
WM_QUERYOPEN                   0x0013      
WM_ENDSESSION                  0x0016      
WM_QUIT                        0x0012      
WM_ERASEBKGND                  0x0014      
WM_SYSCOLORCHANGE              0x0015      
WM_SHOWWINDOW                  0x0018      
WM_WININICHANGE                0x001A      
WM_SETTINGCHANGE               0x001A      # WM_WININICHANGE
WM_DEVMODECHANGE               0x001B      
WM_ACTIVATEAPP                 0x001C      
WM_FONTCHANGE                  0x001D      
WM_TIMECHANGE                  0x001E      
WM_CANCELMODE                  0x001F      
WM_SETCURSOR                   0x0020      
WM_MOUSEACTIVATE               0x0021      
WM_CHILDACTIVATE               0x0022      
WM_QUEUESYNC                   0x0023      
WM_GETMINMAXINFO               0x0024      
WM_PAINTICON                   0x0026      
WM_ICONERASEBKGND              0x0027      
WM_NEXTDLGCTL                  0x0028      
WM_SPOOLERSTATUS               0x002A      
WM_DRAWITEM                    0x002B      
WM_MEASUREITEM                 0x002C      
WM_DELETEITEM                  0x002D      
WM_VKEYTOITEM                  0x002E      
WM_CHARTOITEM                  0x002F      
WM_SETFONT                     0x0030      
WM_GETFONT                     0x0031      
WM_SETHOTKEY                   0x0032      
WM_GETHOTKEY                   0x0033      
WM_QUERYDRAGICON               0x0037      
WM_COMPAREITEM                 0x0039      
WM_GETOBJECT                   0x003D      
WM_COMPACTING                  0x0041      
WM_COMMNOTIFY                  0x0044      
WM_WINDOWPOSCHANGING           0x0046      
WM_WINDOWPOSCHANGED            0x0047      
WM_POWER                       0x0048      
WM_COPYDATA                    0x004A      
WM_CANCELJOURNAL               0x004B      
WM_NOTIFY                      0x004E      
WM_INPUTLANGCHANGEREQUEST      0x0050      
WM_INPUTLANGCHANGE             0x0051      
WM_TCARD                       0x0052      
WM_HELP                        0x0053      
WM_USERCHANGED                 0x0054      
WM_NOTIFYFORMAT                0x0055      
WM_CONTEXTMENU                 0x007B      
WM_STYLECHANGING               0x007C      
WM_STYLECHANGED                0x007D      
WM_DISPLAYCHANGE               0x007E      
WM_GETICON                     0x007F      
WM_SETICON                     0x0080      
WM_NCCREATE                    0x0081      
WM_NCDESTROY                   0x0082      
WM_NCCALCSIZE                  0x0083      
WM_NCHITTEST                   0x0084      
WM_NCPAINT                     0x0085      
WM_NCACTIVATE                  0x0086      
WM_GETDLGCODE                  0x0087      
WM_SYNCPAINT                   0x0088      
WM_NCMOUSEMOVE                 0x00A0      
WM_NCLBUTTONDOWN               0x00A1      
WM_NCLBUTTONUP                 0x00A2      
WM_NCLBUTTONDBLCLK             0x00A3      
WM_NCRBUTTONDOWN               0x00A4      
WM_NCRBUTTONUP                 0x00A5      
WM_NCRBUTTONDBLCLK             0x00A6      
WM_NCMBUTTONDOWN               0x00A7      
WM_NCMBUTTONUP                 0x00A8      
WM_NCMBUTTONDBLCLK             0x00A9      
WM_NCXBUTTONDOWN               0x00AB      
WM_NCXBUTTONUP                 0x00AC      
WM_NCXBUTTONDBLCLK             0x00AD      
WM_INPUT                       0x00FF      
WM_KEYFIRST                    0x0100      
WM_KEYDOWN                     0x0100      
WM_KEYUP                       0x0101      
WM_CHAR                        0x0102      
WM_DEADCHAR                    0x0103      
WM_SYSKEYDOWN                  0x0104      
WM_SYSKEYUP                    0x0105      
WM_SYSCHAR                     0x0106      
WM_SYSDEADCHAR                 0x0107      
WM_UNICHAR                     0x0109      
WM_KEYLAST                     0x0109      
WM_IME_STARTCOMPOSITION        0x010D      
WM_IME_ENDCOMPOSITION          0x010E      
WM_IME_COMPOSITION             0x010F      
WM_IME_KEYLAST                 0x010F      
WM_INITDIALOG                  0x0110      
WM_COMMAND                     0x0111      
WM_SYSCOMMAND                  0x0112      
WM_TIMER                       0x0113      
WM_HSCROLL                     0x0114      
WM_VSCROLL                     0x0115      
WM_INITMENU                    0x0116      
WM_INITMENUPOPUP               0x0117      
WM_MENUSELECT                  0x011F      
WM_MENUCHAR                    0x0120      
WM_ENTERIDLE                   0x0121      
WM_MENURBUTTONUP               0x0122      
WM_MENUDRAG                    0x0123      
WM_MENUGETOBJECT               0x0124      
WM_UNINITMENUPOPUP             0x0125      
WM_MENUCOMMAND                 0x0126      
WM_CHANGEUISTATE               0x0127      
WM_UPDATEUISTATE               0x0128      
WM_QUERYUISTATE                0x0129      
WM_CTLCOLORMSGBOX              0x0132      
WM_CTLCOLOREDIT                0x0133      
WM_CTLCOLORLISTBOX             0x0134      
WM_CTLCOLORBTN                 0x0135      
WM_CTLCOLORDLG                 0x0136      
WM_CTLCOLORSCROLLBAR           0x0137      
WM_CTLCOLORSTATIC              0x0138      
WM_MOUSEFIRST                  0x0200      
WM_MOUSEMOVE                   0x0200      
WM_LBUTTONDOWN                 0x0201      
WM_LBUTTONUP                   0x0202      
WM_LBUTTONDBLCLK               0x0203      
WM_RBUTTONDOWN                 0x0204      
WM_RBUTTONUP                   0x0205      
WM_RBUTTONDBLCLK               0x0206      
WM_MBUTTONDOWN                 0x0207      
WM_MBUTTONUP                   0x0208      
WM_MBUTTONDBLCLK               0x0209      
WM_MOUSEWHEEL                  0x020A      
WM_XBUTTONDOWN                 0x020B      
WM_XBUTTONUP                   0x020C      
WM_XBUTTONDBLCLK               0x020D      
WM_MOUSELAST                   0x020D      
WM_PARENTNOTIFY                0x0210      
WM_ENTERMENULOOP               0x0211      
WM_EXITMENULOOP                0x0212      
WM_NEXTMENU                    0x0213      
WM_SIZING                      0x0214      
WM_CAPTURECHANGED              0x0215      
WM_MOVING                      0x0216      
WM_POWERBROADCAST              0x0218      
WM_DEVICECHANGE                0x0219      
WM_MDICREATE                   0x0220      
WM_MDIDESTROY                  0x0221      
WM_MDIACTIVATE                 0x0222      
WM_MDIRESTORE                  0x0223      
WM_MDINEXT                     0x0224      
WM_MDIMAXIMIZE                 0x0225      
WM_MDITILE                     0x0226      
WM_MDICASCADE                  0x0227      
WM_MDIICONARRANGE              0x0228      
WM_MDIGETACTIVE                0x0229      
WM_MDISETMENU                  0x0230      
WM_ENTERSIZEMOVE               0x0231      
WM_EXITSIZEMOVE                0x0232      
WM_DROPFILES                   0x0233      
WM_MDIREFRESHMENU              0x0234      
WM_IME_SETCONTEXT              0x0281      
WM_IME_NOTIFY                  0x0282      
WM_IME_CONTROL                 0x0283      
WM_IME_COMPOSITIONFULL         0x0284      
WM_IME_SELECT                  0x0285      
WM_IME_CHAR                    0x0286      
WM_IME_REQUEST                 0x0288      
WM_IME_KEYDOWN                 0x0290      
WM_IME_KEYUP                   0x0291      
WM_MOUSEHOVER                  0x02A1      
WM_MOUSELEAVE                  0x02A3      
WM_NCMOUSEHOVER                0x02A0      
WM_NCMOUSELEAVE                0x02A2      
WM_WTSSESSION_CHANGE           0x02B1      
WM_TABLET_FIRST                0x02c0      
WM_TABLET_LAST                 0x02df      
WM_CUT                         0x0300      
WM_COPY                        0x0301      
WM_PASTE                       0x0302      
WM_CLEAR                       0x0303      
WM_UNDO                        0x0304      
WM_RENDERFORMAT                0x0305      
WM_RENDERALLFORMATS            0x0306      
WM_DESTROYCLIPBOARD            0x0307      
WM_DRAWCLIPBOARD               0x0308      
WM_PAINTCLIPBOARD              0x0309      
WM_VSCROLLCLIPBOARD            0x030A      
WM_SIZECLIPBOARD               0x030B      
WM_ASKCBFORMATNAME             0x030C      
WM_CHANGECBCHAIN               0x030D      
WM_HSCROLLCLIPBOARD            0x030E      
WM_QUERYNEWPALETTE             0x030F      
WM_PALETTEISCHANGING           0x0310      
WM_PALETTECHANGED              0x0311      
WM_HOTKEY                      0x0312      
WM_PRINT                       0x0317      
WM_PRINTCLIENT                 0x0318      
WM_APPCOMMAND                  0x0319      
WM_THEMECHANGED                0x031A      
WM_HANDHELDFIRST               0x0358      
WM_HANDHELDLAST                0x035F      
WM_AFXFIRST                    0x0360      
WM_AFXLAST                     0x037F      
WM_PENWINFIRST                 0x0380      
WM_PENWINLAST                  0x038F      
WM_APP                         0x8000      
WM_USER                        0x0400      

# Window styles
WS_OVERLAPPED                  0x00000000  
WS_POPUP                       0x80000000  
WS_CHILD                       0x40000000  
WS_MINIMIZE                    0x20000000  
WS_VISIBLE                     0x10000000  
WS_DISABLED                    0x08000000  
WS_CLIPSIBLINGS                0x04000000  
WS_CLIPCHILDREN                0x02000000  
WS_MAXIMIZE                    0x01000000  
WS_CAPTION                     0x00C00000  # (WS_BORDER | WS_DLGFRAME)
WS_BORDER                      0x00800000  
WS_DLGFRAME                    0x00400000  
WS_VSCROLL                     0x00200000  
WS_HSCROLL                     0x00100000  
WS_SYSMENU                     0x00080000  
WS_THICKFRAME                  0x00040000  
WS_GROUP                       0x00020000  
WS_TABSTOP                     0x00010000  
WS_MINIMIZEBOX                 0x00020000  
WS_MAXIMIZEBOX                 0x00010000  
WS_TILED                       0x00000000  # WS_OVERLAPPED
WS_ICONIC                      0x20000000  # WS_MINIMIZE
WS_SIZEBOX                     0x00040000  # WS_THICKFRAME
WS_TILEDWINDOW                 0x00CF0000  # WS_OVERLAPPEDWINDOW

# Combined Window styles
WS_OVERLAPPEDWINDOW            0x00CF0000  # (WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX)
WS_POPUPWINDOW                 0x80880000  # (WS_POPUP|WS_BORDER|WS_SYSMENU)
WS_CHILDWINDOW                 0x40000000  # WS_CHILD

# Extended Window Styles
WS_EX_DLGMODALFRAME            0x00000001  
WS_EX_NOPARENTNOTIFY           0x00000004  
WS_EX_TOPMOST                  0x00000008  
WS_EX_ACCEPTFILES              0x00000010  
WS_EX_TRANSPARENT              0x00000020  
WS_EX_MDICHILD                 0x00000040  
WS_EX_TOOLWINDOW               0x00000080  
WS_EX_WINDOWEDGE               0x00000100  
WS_EX_CLIENTEDGE               0x00000200  
WS_EX_CONTEXTHELP              0x00000400  
WS_EX_RIGHT                    0x00001000  
WS_EX_LEFT                     0x00000000  
WS_EX_RTLREADING               0x00002000  
WS_EX_LTRREADING               0x00000000  
WS_EX_LEFTSCROLLBAR            0x00004000  
WS_EX_RIGHTSCROLLBAR           0x00000000  
WS_EX_CONTROLPARENT            0x00010000  
WS_EX_STATICEDGE               0x00020000  
WS_EX_APPWINDOW                0x00040000  
WS_EX_OVERLAPPEDWINDOW         0x00000300  # (WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE)
WS_EX_PALETTEWINDOW            0x00000188  # (WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST)
WS_EX_LAYERED                  0x00080000  
WS_EX_NOINHERITLAYOUT          0x00100000  
WS_EX_LAYOUTRTL                0x00400000  
WS_EX_COMPOSITED               0x02000000  
WS_EX_NOACTIVATE               0x08000000  


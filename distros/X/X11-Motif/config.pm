
# --------------------------------------------------------------------------------
# STEP 1:  Which modules do you want to build?
# --------------------------------------------------------------------------------
#
# NOTE: You must have working copies of the following software before
#       building the related modules.  The libraries are *not* distributed
#       with this package.  On some platforms, e.g. Linux, Motif is not a
#       standard option.  You may have to purchase it separately.  I have
#       reports that LessTif, the Motif freeware clone, works, but some
#       functionality is not yet implemented.

$want_motif = 1;	# build the Motif module?  1 = yes, 0 = no
$want_xbae = 0;		# build the Xbae (Motif) widgets?  1 = yes, 0 = no
$want_athena = 0;	# build the Athena module?  1 = yes, 0 = no
$want_xpm = 1;		# build the X Pixmap module?  1 = yes, 0 = no
$want_xrt = 0;		# build the XRT (Motif) widgets?  1 = yes, 0 = no


# --------------------------------------------------------------------------------
# STEP 2:  How does your compiler work?
# --------------------------------------------------------------------------------

# How do you ask the compiler to search for include files somewhere?
sub I_flag { "-I$_[0]" }				# generic

# How do you ask the linker to search for libraries somewhere?
sub L_flag { "-L$_[0] -R$_[0]" }			# Solaris 2.5
#sub L_flag { "-L$_[0]" }				# IRIX 6.4
#sub L_flag { "-L$_[0]" }				# Red Hat Linux 4.2


# --------------------------------------------------------------------------------
# STEP 3:  Where is X installed?
# --------------------------------------------------------------------------------

# The directory that holds the X libraries (look for libX11.a)
$x_lib_dir = "/usr/openwin/lib";			# Solaris 2.5
#$x_lib_dir = "";					# IRIX 6.4
#$x_lib_dir = "/usr/X11R6/lib";				# Red Hat Linux 4.2

# The directory that holds the X includes (look for X11/Intrinsic.h)
$x_inc_dir = "/usr/openwin/include";			# Solaris 2.5
#$x_inc_dir = "";					# IRIX 6.4
#$x_inc_dir = "/usr/X11R6/include";			# Red Hat Linux 4.2

# The X libraries needed on your platform:
$x_libs = "-lXext -lX11 -lgen -lsocket -lnsl";		# Solaris 2.5
#$x_libs = "-lX11";					# IRIX 6.4
#$x_libs = "-lXext -lX11";				# Red Hat Linux 4.2

# The X toolkit libraries needed on your platform:
$x_toolkit_libs = "-lXt -lXmu";				# generic
#$x_toolkit_libs = "-lXt";				# IRIX 6.4


# --------------------------------------------------------------------------------
# STEP 4:  Does your version of X have any quirks or special features?
# --------------------------------------------------------------------------------

#$has_fast_quarks = 1;					# IRIX 6.4


# --------------------------------------------------------------------------------
# STEP 5:  Where is Motif installed?
# --------------------------------------------------------------------------------
#
# NOTE: You only need to do this if you've set $want_motif = 1.

# The directory that holds the Motif libraries (look for libXm.a)
$motif_lib_dir = "/usr/dt/lib"; 			# Solaris 2.5
#$motif_lib_dir = "";					# IRIX 6.4
#$motif_lib_dir = "";					# Red Hat Linux 4.2

# The directory that holds the Motif includes (look for Xm/Xm.h)
$motif_inc_dir = "/usr/dt/include";			# Solaris 2.5
#$motif_inc_dir = "";					# IRIX 6.4
#$motif_inc_dir = "";					# Red Hat Linux 4.2

# The Motif libraries needed on your platform:
$motif_libs = "-lXm";					# generic


# --------------------------------------------------------------------------------
# STEP 6:  Where is Athena installed?
# --------------------------------------------------------------------------------
#
# NOTE: You only need to do this if you've set $want_athena = 1.

$athena_lib_dir = "/usr/openwin/lib";
$athena_inc_dir = "/usr/openwin/include";
$athena_libs = "-lXaw";


# --------------------------------------------------------------------------------
# STEP 7:  Where is X Pixmap installed?
# --------------------------------------------------------------------------------
#
# NOTE: You only need to do this if you've set $want_xpm = 1.

$xpm_lib_dir = "/ford/thishost/unix/div/ap/base/X11/lib";
$xpm_inc_dir = "/ford/thishost/unix/div/ap/base/X11/include";
$xpm_libs = "-lXpm";


# --------------------------------------------------------------------------------
# STEP 8:  Where is Xbae installed?
# --------------------------------------------------------------------------------
#
# NOTE: You only need to do this if you've set $want_xbae = 1

$xbae_lib_dir = "/ford/thishost/unix/div/ap/base/X11/lib";
$xbae_inc_dir = "/ford/thishost/unix/div/ap/base/X11/include";
$xbae_libs = "-lXbae";


# --------------------------------------------------------------------------------
# STEP 9:  Where is XRT installed?
# --------------------------------------------------------------------------------
#
# NOTE: You only need to do this if you've set $want_xrt = 1

$xrt_dir = $ENV{'XRTHOME'};
$xrt_lib_dir = "$xrt_dir/lib";
$xrt_inc_dir = "$xrt_dir/include";


# --------------------------------------------------------------------------------
# STEP 10:  What XRT components do you want?
# --------------------------------------------------------------------------------
#
# NOTE: You only need to do this if you've set $want_xrt = 1

$want_xrt_table = 0;
$want_xrt_graph = 1;
$want_xrt_3d = 0;
$want_xrt_gear = 1;
$want_xrt_field = 0;


# --------------------------------------------------------------------------------
# STEP 11:  Select additional compiler and/or linker flags.
# --------------------------------------------------------------------------------
#
# NOTE: You only need to do this if your standard Perl configuration
#       is not able to compile the modules.  The most common problem
#       occurs when the number of symbols exceeds the default limit.
#       You may have to change from -fpic to -fPIC for example.

@extra_MakeMaker_flags = ( 'CCCDLFLAGS' => '-fPIC' );	# gcc


# --------------------------------------------------------------------------------
# STEP 12:  Do you want a statically linked 'xperl' executable?
# --------------------------------------------------------------------------------
#
# Sometimes you want a perl interpreter with all the X11 modules built-in.
# You can still use this interpreter with your other dynamically loaded
# modules, so it's really just a performance tweak on most systems.
#
# If you're building the XRT module, you'll get a statically linked perl
# interpreter regardless of this setting because the XRT licensing system
# requires it.
#
# The default is to build dynamic modules so that you can use them with
# the regular perl executable.

$want_static_perl = 0;					# 0 = no, 1 = yes

# --------------------------------------------------------------------------------
# You shouldn't need to change anything more.
# --------------------------------------------------------------------------------

if ($want_xrt) {
    $want_static_perl = 1;
}

%emitted_L_flags = ();

sub do_L_flag {
    my($dir) = @_;
    if ($dir !~ /^\s*$/) {
	if (!exists $emitted_L_flags{$dir}) {
	    ++$emitted_L_flags{$dir};
	    return L_flag($dir);
	}
    }
    "";
}

%emitted_I_flags = ();

sub do_I_flag {
    my($dir) = @_;
    if ($dir !~ /^\s*$/) {
	if (!exists $emitted_I_flags{$dir}) {
	    ++$emitted_I_flags{$dir};
	    return I_flag($dir);
	}
    }
    "";
}

@saved_extra_MakeMaker_flags = @extra_MakeMaker_flags;

sub do_reset_flags {
    %emitted_L_flags = ();
    %emitted_I_flags = ();
    @extra_MakeMaker_flags = @saved_extra_MakeMaker_flags;
}

1;

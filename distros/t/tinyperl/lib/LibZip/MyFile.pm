######################
# SIMPLE FILES::Spec #
######################

package LibZip::File::Spec ;
#use strict qw( vars subs ) ;

my %module = (MacOS   => 'Mac',
	      MSWin32 => 'Win32',
	      os2     => 'OS2',
	      VMS     => 'VMS',
	      epoc    => 'Unix',
	      NetWare => 'Win32', # Yes, File::Spec::Win32 works on NetWare.
	      dos     => 'OS2',   # Yes, File::Spec::OS2 works on DJGPP.
	      cygwin  => 'Unix');


my $module = $module{$^O} || 'Unix';

sub splitpath { &{"splitpath_$module"}(@_); } ;
sub catpath { &{"catpath_$module"}(@_); } ;


sub splitpath_Unix {
    my ($self,$path, $nofile) = @_;

    my ($volume,$directory,$file) = ('','','');

    if ( $nofile ) {
        $directory = $path;
    }
    else {
        $path =~ m|^ ( (?: .* / (?: \.\.?\Z(?!\n) )? )? ) ([^/]*) |xs;
        $directory = $1;
        $file      = $2;
    }

    return ($volume,$directory,$file);
}

sub catpath_Unix {
    my ($self,$volume,$directory,$file) = @_;

    if ( $directory ne ''                && 
         $file ne ''                     && 
         substr( $directory, -1 ) ne '/' && 
         substr( $file, 0, 1 ) ne '/' 
    ) {
        $directory .= "/$file" ;
    }
    else {
        $directory .= $file ;
    }

    return $directory ;
}

sub splitpath_Win32 {
    my ($self,$path, $nofile) = @_;
    my ($volume,$directory,$file) = ('','','');
    if ( $nofile ) {
        $path =~ 
            m{^( (?:[a-zA-Z]:|(?:\\\\|//)[^\\/]+[\\/][^\\/]+)? ) 
                 (.*)
             }xs;
        $volume    = $1;
        $directory = $2;
    }
    else {
        $path =~ 
            m{^ ( (?: [a-zA-Z]: |
                      (?:\\\\|//)[^\\/]+[\\/][^\\/]+
                  )?
                )
                ( (?:.*[\\\\/](?:\.\.?\Z(?!\n))?)? )
                (.*)
             }xs;
        $volume    = $1;
        $directory = $2;
        $file      = $3;
    }

    return ($volume,$directory,$file);
}

sub catpath_Win32 {
    my ($self,$volume,$directory,$file) = @_;

    # If it's UNC, make sure the glue separator is there, reusing
    # whatever separator is first in the $volume
    $volume .= $1
        if ( $volume =~ m@^([\\/])[\\/][^\\/]+[\\/][^\\/]+\Z(?!\n)@s &&
             $directory =~ m@^[^\\/]@s
           ) ;

    $volume .= $directory ;

    # If the volume is not just A:, make sure the glue separator is 
    # there, reusing whatever separator is first in the $volume if possible.
    if ( $volume !~ m@^[a-zA-Z]:\Z(?!\n)@s &&
         $volume =~ m@[^\\/]\Z(?!\n)@      &&
         $file   =~ m@[^\\/]@
       ) {
        $volume =~ m@([\\/])@ ;
        my $sep = $1 ? $1 : '\\' ;
        $volume .= $sep ;
    }

    $volume .= $file ;

    return $volume ;
}

sub splitpath_Mac {
    my ($self,$path, $nofile) = @_;
    my ($volume,$directory,$file);

    if ( $nofile ) {
        ( $volume, $directory ) = $path =~ m|^((?:[^:]+:)?)(.*)|s;
    }
    else {
        $path =~
            m|^( (?: [^:]+: )? )
               ( (?: .*: )? )
               ( .* )
             |xs;
        $volume    = $1;
        $directory = $2;
        $file      = $3;
    }

    $volume = '' unless defined($volume);
	$directory = ":$directory" if ( $volume && $directory ); # take care of "HD::dir"
    if ($directory) {
        # Make sure non-empty directories begin and end in ':'
        $directory .= ':' unless (substr($directory,-1) eq ':');
        $directory = ":$directory" unless (substr($directory,0,1) eq ':');
    } else {
	$directory = '';
    }
    $file = '' unless defined($file);

    return ($volume,$directory,$file);
}

sub catpath_Mac {
    my ($self,$volume,$directory,$file) = @_;

    if ( (! $volume) && (! $directory) ) {
	$file =~ s/^:// if $file;
	return $file ;
    }

    my $path = $volume; # may be ''
    $path .= ':' unless (substr($path, -1) eq ':'); # ensure trailing ':'

    if ($directory) {
	$directory =~ s/^://; # remove leading ':' if any
	$path .= $directory;
	$path .= ':' unless (substr($path, -1) eq ':'); # ensure trailing ':'
    }

    if ($file) {
	$file =~ s/^://; # remove leading ':' if any
	$path .= $file;
    }

    return $path;
}

sub splitpath_OS2 {
    my ($self,$path, $nofile) = @_;
    my ($volume,$directory,$file) = ('','','');
    if ( $nofile ) {
        $path =~ 
            m{^( (?:[a-zA-Z]:|(?:\\\\|//)[^\\/]+[\\/][^\\/]+)? ) 
                 (.*)
             }xs;
        $volume    = $1;
        $directory = $2;
    }
    else {
        $path =~ 
            m{^ ( (?: [a-zA-Z]: |
                      (?:\\\\|//)[^\\/]+[\\/][^\\/]+
                  )?
                )
                ( (?:.*[\\\\/](?:\.\.?\Z(?!\n))?)? )
                (.*)
             }xs;
        $volume    = $1;
        $directory = $2;
        $file      = $3;
    }

    return ($volume,$directory,$file);
}

sub catpath_OS2 {
    my ($self,$volume,$directory,$file) = @_;

    # If it's UNC, make sure the glue separator is there, reusing
    # whatever separator is first in the $volume
    $volume .= $1
        if ( $volume =~ m@^([\\/])[\\/][^\\/]+[\\/][^\\/]+\Z(?!\n)@s &&
             $directory =~ m@^[^\\/]@s
           ) ;

    $volume .= $directory ;

    # If the volume is not just A:, make sure the glue separator is 
    # there, reusing whatever separator is first in the $volume if possible.
    if ( $volume !~ m@^[a-zA-Z]:\Z(?!\n)@s &&
         $volume =~ m@[^\\/]\Z(?!\n)@      &&
         $file   =~ m@[^\\/]@
       ) {
        $volume =~ m@([\\/])@ ;
        my $sep = $1 ? $1 : '/' ;
        $volume .= $sep ;
    }

    $volume .= $file ;

    return $volume ;
}

sub splitpath_VMS {
    my($self,$path) = @_;
    my($dev,$dir,$file) = ('','','');

    vmsify($path) =~ /(.+:)?([\[<].*[\]>])?(.*)/s;
    return ($1 || '',$2 || '',$3);
}

sub catpath_VMS {
    my($self,$dev,$dir,$file) = @_;
    if ($dev =~ m|^/+([^/]+)|) { $dev = "$1:"; }
    else { $dev .= ':' unless $dev eq '' or $dev =~ /:\Z(?!\n)/; }
    if (length($dev) or length($dir)) {
      $dir = "[$dir]" unless $dir =~ /[\[<\/]/;
      $dir = vmspath($dir);
    }
    "$dev$dir$file";
}

##########################
# LIBZIP::FILE::BASENAME #
##########################

package LibZip::File::Basename ;

my(@ISA, $VERSION, $Fileparse_fstype, $Fileparse_igncase);

$VERSION = "2.71";

sub fileparse {
  my($fullname,@suffices) = @_;
  my($fstype,$igncase) = ($Fileparse_fstype, $Fileparse_igncase);
  my($dirpath,$tail,$suffix,$basename);
  my($taint) = substr($fullname,0,0);  # Is $fullname tainted?

  if ($fstype =~ /^VMS/i) {
    if ($fullname =~ m#/#) { $fstype = '' }  # We're doing Unix emulation
    else {
      ($dirpath,$basename) = ($fullname =~ /^(.*[:>\]])?(.*)/s);
      $dirpath ||= '';  # should always be defined
    }
  }
  if ($fstype =~ /^MS(DOS|Win32)|epoc/i) {
    ($dirpath,$basename) = ($fullname =~ /^((?:.*[:\\\/])?)(.*)/s);
    $dirpath .= '.\\' unless $dirpath =~ /[\\\/]\z/;
  }
  elsif ($fstype =~ /^os2/i) {
    ($dirpath,$basename) = ($fullname =~ m#^((?:.*[:\\/])?)(.*)#s);
    $dirpath = './' unless $dirpath;	# Can't be 0
    $dirpath .= '/' unless $dirpath =~ m#[\\/]\z#;
  }
  elsif ($fstype =~ /^MacOS/si) {
    ($dirpath,$basename) = ($fullname =~ /^(.*:)?(.*)/s);
    $dirpath = ':' unless $dirpath;
  }
  elsif ($fstype =~ /^AmigaOS/i) {
    ($dirpath,$basename) = ($fullname =~ /(.*[:\/])?(.*)/s);
    $dirpath = './' unless $dirpath;
  }
  elsif ($fstype !~ /^VMS/i) {  # default to Unix
    ($dirpath,$basename) = ($fullname =~ m#^(.*/)?(.*)#s);
    if ($^O eq 'VMS' and $fullname =~ m:^(/[^/]+/000000(/|$))(.*):) {
      # dev:[000000] is top of VMS tree, similar to Unix '/'
      # so strip it off and treat the rest as "normal"
      my $devspec  = $1;
      my $remainder = $3;
      ($dirpath,$basename) = ($remainder =~ m#^(.*/)?(.*)#s);
      $dirpath ||= '';  # should always be defined
      $dirpath = $devspec.$dirpath;
    }
    $dirpath = './' unless $dirpath;
  }

  if (@suffices) {
    $tail = '';
    foreach $suffix (@suffices) {
      my $pat = ($igncase ? '(?i)' : '') . "($suffix)\$";
      if ($basename =~ s/$pat//s) {
        $taint .= substr($suffix,0,0);
        $tail = $1 . $tail;
      }
    }
  }

  $tail .= $taint if defined $tail; # avoid warning if $tail == undef
  wantarray ? ($basename .= $taint, $dirpath .= $taint, $tail)
            : ($basename .= $taint);
}

sub dirname {
    my($basename,$dirname) = fileparse($_[0]);
    my($fstype) = $Fileparse_fstype;

    if ($fstype =~ /VMS/i) { 
        if ($_[0] =~ m#/#) { $fstype = '' }
        else { return $dirname || $ENV{DEFAULT} }
    }
    if ($fstype =~ /MacOS/i) {
	if( !length($basename) && $dirname !~ /^[^:]+:\z/) {
	    $dirname =~ s/([^:]):\z/$1/s;
	    ($basename,$dirname) = fileparse $dirname;
	}
	$dirname .= ":" unless $dirname =~ /:\z/;
    }
    elsif ($fstype =~ /MS(DOS|Win32)|os2/i) { 
        $dirname =~ s/([^:])[\\\/]*\z/$1/;
        unless( length($basename) ) {
	    ($basename,$dirname) = fileparse $dirname;
	    $dirname =~ s/([^:])[\\\/]*\z/$1/;
	}
    }
    elsif ($fstype =~ /AmigaOS/i) {
        if ( $dirname =~ /:\z/) { return $dirname }
        chop $dirname;
        $dirname =~ s#[^:/]+\z## unless length($basename);
    }
    else {
        $dirname =~ s:(.)/*\z:$1:s;
        unless( length($basename) ) {
	    local($LibZip::File::Basename::Fileparse_fstype) = $fstype;
	    ($basename,$dirname) = fileparse $dirname;
	    $dirname =~ s:(.)/*\z:$1:s;
	}
    }

    $dirname;
}

sub fileparse_set_fstype {
  my @old = ($Fileparse_fstype, $Fileparse_igncase);
  if (@_) {
    $Fileparse_fstype = $_[0];
    $Fileparse_igncase = ($_[0] =~ /^(?:MacOS|VMS|AmigaOS|os2|RISCOS|MSWin32|MSDOS)/i);
  }
  wantarray ? @old : $old[0];
}

fileparse_set_fstype $^O;

####################
# LIBZIPFILE::PATH #
####################

package LibZip::File::Path ;

my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

sub mkpath {
    my($paths, $verbose, $mode) = @_;
    # $paths   -- either a path string or ref to list of paths
    # $verbose -- optional print "mkdir $path" for each directory created
    # $mode    -- optional permissions, defaults to 0777
    local($")=$Is_MacOS ? ":" : "/";
    $mode = 0777 unless defined($mode);
    $paths = [$paths] unless ref $paths;
    my(@created,$path);
    foreach $path (@$paths) {
	$path .= '/' if $^O eq 'os2' and $path =~ /^\w:\z/s; # feature of CRT 
	# Logic wants Unix paths, so go with the flow.
	next if -d $path;
	my $parent = LibZip::File::Basename::dirname($path);
	unless (-d $parent or $path eq $parent) {
	    push(@created,mkpath($parent, $verbose, $mode));
 	}
	print "mkdir $path\n" if $verbose;
	unless (mkdir($path,$mode)) {
	    my $e = $!;
	    # allow for another process to have created it meanwhile
	    #croak "mkdir $path: $e" unless -d $path;
	}
	push(@created, $path);
    }
    @created;
}

sub carp { print @_ }

sub rmtree {
    my($roots, $verbose, $safe) = @_;
    my(@files);
    my($count) = 0;
    $verbose ||= 0;
    $safe ||= 0;

    if ( defined($roots) && length($roots) ) {
      $roots = [$roots] unless ref $roots;
    }
    else {
      carp "No root path(s) specified\n";
      return 0;
    }

    my($root);
    foreach $root (@{$roots}) {
    	if ($Is_MacOS) {
	    $root = ":$root" if $root !~ /:/;
	    $root =~ s#([^:])\z#$1:#;
	} else {
	    $root =~ s#/\z##;
	}
	(undef, undef, my $rp) = lstat $root or next;
	$rp &= 07777;	# don't forget setuid, setgid, sticky bits
	if ( -d _ ) {
	    # notabene: 0777 is for making readable in the first place,
	    # it's also intended to change it to writable in case we have
	    # to recurse in which case we are better than rm -rf for 
	    # subtrees with strange permissions
	    chmod(0777, ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
	      or carp "Can't make directory $root read+writeable: $!"
		unless $safe;

	    if (opendir my $d, $root) {
		#no strict 'refs';
		if (!defined ${"\cTAINT"} or ${"\cTAINT"}) {
		    # Blindly untaint dir names
		    @files = map { /^(.*)$/s ; $1 } readdir $d;
		} else {
		    @files = readdir $d;
		}
		closedir $d;
	    }
	    else {
	        carp "Can't read $root: $!";
		@files = ();
	    }

	    # Deleting large numbers of files from VMS Files-11 filesystems
	    # is faster if done in reverse ASCIIbetical order 
	    @files = reverse @files if $Is_VMS;
	    ($root = VMS::Filespec::unixify($root)) =~ s#\.dir\z## if $Is_VMS;
	    if ($Is_MacOS) {
		@files = map("$root$_", @files);
	    } else {
		@files = map("$root/$_", grep $_!~/^\.{1,2}\z/s,@files);
	    }
	    $count += rmtree(\@files,$verbose,$safe);
	    if ($safe &&
		($Is_VMS ? !&VMS::Filespec::candelete($root) : !-w $root)) {
		print "skipped $root\n" if $verbose;
		next;
	    }
	    chmod 0777, $root
	      or carp "Can't make directory $root writeable: $!"
		if $force_writeable;
	    print "rmdir $root\n" if $verbose;
	    if (rmdir $root) {
		++$count;
	    }
	    else {
		carp "Can't remove directory $root: $!";
		chmod($rp, ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
		    or carp("and can't restore permissions to "
		            . sprintf("0%o",$rp) . "\n");
	    }
	}
	else { 
	    if ($safe &&
		($Is_VMS ? !&VMS::Filespec::candelete($root)
		         : !(-l $root || -w $root)))
	    {
		print "skipped $root\n" if $verbose;
		next;
	    }
	    chmod 0666, $root
	      or carp "Can't make file $root writeable: $!"
		if $force_writeable;
	    print "unlink $root\n" if $verbose;
	    # delete all versions under VMS
	    for (;;) {
		unless (unlink $root) {
		    carp "Can't unlink file $root: $!";
		    if ($force_writeable) {
			chmod $rp, $root
			    or carp("and can't restore permissions to "
			            . sprintf("0%o",$rp) . "\n");
		    }
		    last;
		}
		++$count;
		last unless $Is_VMS && lstat $root;
	    }
	}
    }

    $count;
}


#    my ( $volumeName, $dirName, $fileName ) = LibZip::File::Spec->splitpath('./LibZipData.pm');
#    print "$volumeName, $dirName, $fileName\n" ;
#    
#    $dirName = LibZip::File::Spec->catpath( $volumeName, $dirName, '' );
#    print "$dirName\n" ;
#    
#    my $d = LibZip::File::Basename::dirname('./asdasd/fl.txt') ;
#    print "$d\n" ;

#######
# END #
#######

1;



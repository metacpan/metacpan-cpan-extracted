package LiveGeez::File;


BEGIN
{
	use strict;
	use vars qw($VERSION $DIRMASK @itoa64 @gFile $RC_OK $RC_NOT_MODIFIED);

	$VERSION = '0.20';

	require 5.000;

	# use LiveGeez::Config;
	use LiveGeez::HTML;

	require LiveGeez::URI;
	require LiveGeez::CacheAsSERA;

	# if ( $PROCESSURLS ) {
	#	use LWP::Simple;
	# }
	#
	# Uncomment these next 3 if using getURL command
	#
	# use LWP::UserAgent;
	# use HTTP::Request;
	# use HTTP::Response;
	# use File::Path 'mkpath';
	require File::Path;
	require Apache::File;
	require Compress::Zlib;
	require LWP::Simple;
	require POSIX;

	$DIRMASK = "0755";

	@itoa64 = split ( //, "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" );
#
#  @gFile is a global array that holds the content of our file.  It is 
#         global since the number of subroutines that use it is high
#         enough that we should get a memory and performance enhancement
#         by not passing it around.
#
$#gFile = 100;	# preset to one hundred lines, most articles should be
		# smaller than this.

	$RC_OK           = LWP::Simple::RC_OK();
	$RC_NOT_MODIFIED = LWP::Simple::RC_NOT_MODIFIED();
}




sub new
{
my $class   = shift;
my $self    = {};


	my $blessing = bless $self, $class;

	$self->_init_sysOut ( @_ );

	$self->OpenFile;

	$blessing;

}


sub _init_sysOut
{
my ( $self, $request ) = @_;


	#
	# this isn't a good test, check the Content-Type type.
	#
	# $request->DieCgi ( "Unrecognized file type, does not appear to be HTML<br>$request->{file}" )
	# 	if ( $request->{file} !~ /\.x\w{3,}$/i && $request->{file} !~ /\/$/ );


	$self->{request}     =   $request;

	$self->{fileSysOut}  =   $request->{sysOut}->{sysName};

	$self->{fileSysOut} .= ".$request->{sysOut}->{xfer}"
				 if ( $request->{sysOut}->{xfer} ne "notv" );

	$self->{fileSysOut} .= ".7-bit"
				 if ( $request->{sysOut}->{'7-bit'} eq "true" );

	$self->{fileSysOut} .= ".$request->{sysOut}->{options}"
				 if ( $request->{sysOut}->{options} );

	$self->{fileSysOut} .= ".$request->{WebFont}" if ( $request->{WebFont} );

	$self->{fileSysOut} .= ".$request->{sysOut}->{lang}" unless ( $request->{file} =~ /\.$request->{sysOut}->{lang}\./ );

	$self->{fileSysOut} .= ".NoFrames"
				 if ( $request->{frames} eq "no" );

	$self->{fileSysOut} .= ".FirstTime"
				 if ( $request->{FirstTime} );

	$self->{scriptRoot} = ( $self->{request}->{uri}->scheme ) 
	                      ? $self->{request}->{config}->{uris}->{zuri} 
	                      : $self->{request}->{config}->{uris}->{zpath}
	                    ;
	$self->{isCGI}       =   0;

	$self->{refsUpdated} =   0;

	$self->{baseUpdated} =   0;
1;
}


sub myRand
{
	my $rand = rand;
	$rand =~ s/0\.(\d{2})\d+/$1/;
	$rand %= 64;

        $itoa64[$rand];
}


#------------------------------------------------------------------------------#
#
# "OpenFile"
#
#   is here to do the dirty work of opening either a local or remote file and
#   copying the contents into the "gFile" array.  If the file is cached and
#   the file has not been modified the routine returns.  Otherwise document
#   data is copied into the htmlData hash field.  OpenFile has no return value.
#
#------------------------------------------------------------------------------#
sub OpenFile
{
my $self = shift;
my ( $sourceFile, $fileStream, $fileIsURL );


	#
	# check if file is a URL, if not strip off leading "/" if any.
	#
	$self->{isRemote} = ( $self->{request}->{uri}->scheme ) ? 1 : 0;


	#
	# if we do not permit remote processing then bail at this point.
	# ...or we could redirect to Zobel server that does allow remote
	# processing...
	#
	$self->{request}->DieCgi ( "Sorry!  Zobel at $scriptURL is for local use only!\n" )
		if ( $self->{isRemote} && !$self->{request}->{config}->{processurls} );


	#
	# check if cached.
	#
	$sourceFile = ( $self->{isRemote} ) ? $self->CheckCacheURL : $self->CheckCacheFile;

	$self->{request}->DieCgiWithEMail ( "The requested file '$self->{request}->{file}' was not found.", "$self->{request}->{file} not found" )
		unless ( $sourceFile );

	#
	# if cached delete or return
	#
	return if ( $self->{isCached} );



	1;

}


sub Display
{
my $self = shift;


	#
	# If cached, display and return.
	#
	if ( $self->{isCached} ) {
		$self->DisplayFromCache;
	}
	elsif ( $self->{useSource} ) {
		$self->DisplayFromSource;
	}
	else {

		#
		# Translate buffer.
		#
		FileBuffer ( $self );


		#
		# finally, display and cache the results.
		#
		if ( $self->{isCGI} ) {
			$self->DisplayFileDontCache;
			unlink ( $self->{uris}->{source} );
			unlink ( $self->{uris}->{tmpFile} );
		}
		elsif ( $self->{dontCache} ) {  # probably a date="today"
			$self->DisplayFileDontCache;
		}
		else {
			$self->DisplayFileAndCache;
		}


		delete ( $self->{htmlData} );
	}
}


sub DisplayFromSource
{
my $self = shift;


	my $sourceFile = $self->{uris}->{source};

	#
	# if no modification, then redirect to source URL, if not cached
	#


	my $fileStream 
	= ( ( $self->{isZipped} && $self->{request}->{'x-gzip'} ) || !$self->{isZipped} )
	  ? $sourceFile
	  : "gzip -d --stdout $sourceFile |"
	;

	open (SOURCEFILE, "$fileStream") || $self->{request}->DieCgi
	     ( "!: Could Not Open File: $sourceFile!\n" );

	$self->{request}->HeaderPrint;

	if ( !$self->{isZipped} && $self->{request}->{'x-gzip'} ) {
		local $/;
		$self->{request}->print ( Compress::Zlib::memGzip( <SOURCEFILE> ) );
	}
	else {
		$self->{request}->print ( <SOURCEFILE> );
	}

	close ( SOURCEFILE );

	1;
}


#------------------------------------------------------------------------------#
#
# "DisplayFileAndCache"
# 
#	Does just as the name implies.  The "cacheFileIn" string must be set
#	before the method is called.  The "htmlData" is written into a tee pipe
#	to simultaneously display the output and write to a file (cacheFileIn
#	that is).  The cached file is finally gzipped unless it is a frame
#	element that we want users to cache on their side (in which case we
#	require frame elements to be stored in a "Frames" subdirectory).
#
#------------------------------------------------------------------------------#
sub DisplayFileAndCacheX
{
my $self = shift;
my $cacheFile = $self->{uris}->{cachein};


	$self->{request}->HeaderPrint;

	if ( $self->{request}->{apache} ) {
		if ( $self->{request}->{'x-gzip'} ) {
			local $/;
			$self->{request}->{apache}->print ( Compress::Zlib::memGzip( $self->{htmlData} ) );
		}
		else {
			$self->{request}->{apache}->print ( $self->{htmlData} );
		}
		open (CACHEFILE, ">$cacheFile") 
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	else {
		open (CACHEFILE, "| tee $cacheFile") 
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}

	print CACHEFILE $self->{htmlData};

	close (CACHEFILE);

	system ( 'gzip', '-f', $cacheFile ) if ( $cacheFile !~ /\/Frames/ );

	1;
}
sub DisplayFileAndCache
{
my $self = shift;
my $cacheFile = $self->{uris}->{cachein};


	$self->{request}->HeaderPrint;

	if ( $self->{request}->{'x-gzip'} ) {
		local $/;
		$self->{request}->print ( Compress::Zlib::memGzip( $self->{htmlData} ) );
		open (CACHEFILE, ">$cacheFile") 
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	else {
		if ( $self->{request}->{apache} ) {
			$self->{request}->{apache}->print ( $self->{htmlData} );
			open (CACHEFILE, ">$cacheFile") 
				|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
		}
		else {
			open (CACHEFILE, "| tee $cacheFile") 
			|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
		}
	}

	print CACHEFILE $self->{htmlData};

	close (CACHEFILE);

	system ( 'gzip', '-f', $cacheFile ) if ( $cacheFile !~ /\/Frames/ );

	1;
}


sub DisplayFileDontCache
{
my $self = shift;


	$self->{request}->HeaderPrint;
	
	if ( $self->{request}->{'x-gzip'} ) {
		local $/;
		$self->{request}->print ( Compress::Zlib::memGzip( $self->{htmlData} ) );
	}
	else {
		$self->{request}->print ( $self->{htmlData} );
	}

	1;
}


#------------------------------------------------------------------------------#
#
# "getURL"
#
#	is just here now occassional debugging purposes.  It is not an essential
#	part of solving the task at hand since we have elected to use the Request
#	"mirror" function which does nearly the same thing but with better error
#	handling.
#
#------------------------------------------------------------------------------#
sub getURL
{
my $self = shift;
my ( $url, $cacheDate ) = @_;
my $responseCode;


	my $ua = new LWP::UserAgent;
	$ua->agent ("Ge'ezilla/0.1");
	my $request = new HTTP::Request ('GET', $url);
	$request->header ('If-Modified-Since' => $cacheDate) if ( $cacheDate );
	my $response = $ua->request ($request);

	if ( ($responseCode = $response->code) != 304 && !$response->is_success ) {
		print $response->error_as_HTML;
		exit (0);
	}

	@gFile = $response->content if ( $responseCode != 304 );
	$self->{htmlData} = join ( "", @gFile );

	undef ($ua);
	undef ($response);
	undef ($request);

	return ( $responseCode == 304 ) ? 1 : 0;

}


#------------------------------------------------------------------------------#
#
# "CheckCacheFile"
#
#	Checks to see if a cached version of a file in a request output system
#	is available.  If so isCached and cacheFileOut are set.  If the "no-cache"
#	pragma is set cacheFileOut will be deleted.  isZipped is set for compressed
#	cached files.  cacheFileIn is set as a pre-zipped storage name for zipped
#	files for uncached files.  sourceFile always points to the file to be
#	opened, cached or uncached.  MakeCacheDir is called to create an appropriate
#	subdirectory to store files in cache.  The sourceFile is returned.
#
#	Note: Cached file dates are _not_ compared to the source file dates simply
#	to save the time involved for the operations required.  This does not
#	present a problem for the way files are updated at the ENH and Tobia where
#	cached version are cleaned out when new source versions are installed.
#
#------------------------------------------------------------------------------#
sub CheckCacheFile
{
my $self = shift;
my ( $dir, $file, $diskFile, $cacheDir, $cacheFileIn, $cacheFileOut, $sourceFile, $ext );

	$self->{doc_root} = ( $self->{request}->{config}->{set_local_base} )
	? $self->{request}->{config}->{set_local_base} . "/"
	: 0
	;
	

	$diskFile = $self->{request}->{uri}->path;

	$file = $self->{request}->{uri}->file;

	unless ( $file ) {
		# we were passed a directory reference
		# so for caching purposes we'll use "index.html"
		if ( -e ("$self->{request}->{config}->{uris}->{webroot}/$diskFile/index.sera.html") ) {
			$diskFile .= "/index.sera.html";
		}
		elsif ( -e ("$self->{request}->{config}->{uris}->{webroot}/$diskFile/index.html") ) {
			$diskFile .= "/index.html";
		} elsif ( -e ("$self->{request}->{config}->{uris}->{webroot}/$diskFile/index.htm") ) {
			$diskFile .= "/index.htm";
		}
		$file = "index.html";
	}
	else {
		$diskFile =~ s|^/||;
	}

	#
	#  Look for a language specific index if we are dealing with an index
	#
	if ( $diskFile =~ /index\..*?\.htm(l)?$/o
	     && $diskFile !~ /\.$request->{sysOut}->{lang}\./ ) {
		my $langIndex = $diskFile;
		$langIndex =~ s/index/index.$self->{request}->{sysOut}->{lang}/;
		$diskFile = $langIndex
		if ( -e ("$self->{request}->{config}->{uris}->{webroot}/$langIndex") );
	}

	#
	#  Alas the sourceFile that we are working with
	#
	$sourceFile = "$self->{request}->{config}->{uris}->{webroot}/$diskFile";

	unless ( (-e $sourceFile) ) {
		if ( (-e "$sourceFile.gz") ) {
			$self->{isZipped} = "true";
			$sourceFile .= ".gz";
		}
		else {
			return;
		}
	}

	#
	#  Alas the sourceFile that we are working with
	#
	if ( $self->{request}->{sysIn}->{sysName} eq $self->{request}->{sysOut}->{sysName} ) {
		$self->{useSource} = 1;
		return ( $self->{uris}->{source} = $sourceFile );
	}


	$file = $self->{request}->{uri}->file_base || "index";  # no ext
	$dir  = $self->{request}->{uri}->dir_clean;
	$ext  = $self->{ext} = $self->{request}->{uri}->ext || "html";

	$file   =~ s/\.sera$//i;

	$cacheDir     = "$self->{request}->{config}->{uris}->{cachelocal}";
	$cacheDir    .= "/$dir" if ( $dir );
	$cacheFileIn  = "$cacheDir/$file.$self->{fileSysOut}.$ext";
	$cacheFileOut =  ( $diskFile !~ /\/Frames/ )
	              ? "$cacheDir/$file.$self->{fileSysOut}.$ext.gz"
	              :  $cacheFileIn
	              ;

	$self->{uris}->{cachein} = $cacheFileIn;

	unlink ( $cacheFileOut ) if ( $self->{request}->{'no-cache'} );

	if ( (-e $cacheFileOut) ) {
		#
		#  Check Date Here
		#
		if ( $self->{request}->{config}->{checkfiledates}
		     && ( (stat ( $cacheFileOut ))[9] < (stat ( $sourceFile ))[9] ) )
	 	{
			#
			#  if old delete and get New
			#
			unlink <$cacheDir/$file*.gz>;

			#
			#  is sourceFile in SERA?
			#
		#	$sourceFile = LiveGeez::CacheAsSERA::HTML ( $self, $sourceFile )
		#		unless ( $self->{request}->{sysIn}->{sysName} eq "sera" );
			$sourceFile = ( $self->{request}->{sysIn}->{sysName} eq "sera" )
			              ? LiveGeez::CacheAsSERA::Local ( $self, $sourceFile )
			              : LiveGeez::CacheAsSERA::Remote ( $self, $sourceFile )
			                unless ( $self->{request}->{cache_check_override} )
			            ;
		}
		else {
			$sourceFile = $cacheFileOut;
			$self->{isCached} = "true";
			$self->{isZipped} = "true" if ( $cacheFileOut ne $cacheFileIn );
		}
		$self->{uris}->{cacheout} = $cacheFileOut;
	}
	else {
		MakeCacheDir ($cacheDir, $FileCacheDir);
		#
		#  is sourceFile in SERA?
		#
		# $sourceFile = LiveGeez::CacheAsSERA::HTML ( $self, $sourceFile )
		# 	unless ( $self->{request}->{sysIn}->{sysName} eq "sera" );
		$sourceFile = ( $self->{request}->{sysIn}->{sysName} eq "sera" )
		              ? LiveGeez::CacheAsSERA::Local ( $self, $sourceFile )
		              : LiveGeez::CacheAsSERA::Remote ( $self, $sourceFile )
		                unless ( $self->{request}->{cache_check_override} )
		            ;
		$self->{request}->{sysIn} = $LiveGeez::CacheAsSERA::s;
	}

	$self->{uris}->{source} = $sourceFile;

}


#------------------------------------------------------------------------------#
#
# "CheckCacheURL"
# 
#	is the analog of CheckCacheFile with the ability to open a URL and update
#	local cached copies when out of date.
#
#------------------------------------------------------------------------------#
sub CheckCacheURL
{
my $self = shift;
my ( $dir, $file, $cacheDir, $cacheFileIn, $cacheFileOut, $ext );

# use LWP::Simple;  # presumably this load only once and only if we reach here


	$file = $self->{request}->{uri}->file_clean || "index.html";
	$dir  = $self->{request}->{uri}->dir_clean;
	$ext  = $self->{ext} = $self->{request}->{uri}->ext || "html";

	$self->{uri_authority} = $self->{request}->{uri}->scheme_authority;
	$self->{doc_root}      = $self->{request}->{uri}->doc_root . "/";

	$cacheDir   = "$self->{request}->{config}->{uris}->{cacheremote}/".$self->{request}->{uri}->host.$dir;
	$sourceFile = "$cacheDir/$file";


	$file = $self->{request}->{uri}->file_base || "index";  # no terminal ext

	$file   =~ s/\.sera$//i;

	$cacheFileIn  = "$cacheDir/$file.$self->{fileSysOut}.$ext";
	$cacheFileOut = $cacheFileIn.".gz";

	$self->{uris}->{cachein} = $cacheFileIn;

	unlink <$cacheDir/$file*>
		if ( $self->{request}->{'no-cache'} );
	printf STDERR "Clear Cache Error [$!]\n" if ( $! );

	#
	# If the file is cached we will compare the file date against the
	# version on the server
	#
	if (-e $sourceFile) {
		# my ($mtime) = (stat($cacheFileOut))[9];
		# my ($cacheDate) = HTTP::Date::time2str($mtime);

		my $rc = LWP::Simple::mirror ($self->{request}->{file}, $sourceFile);
		if ( $rc == $RC_OK ) {
			# Clear cache
			my $output = unlink <$cacheDir/$file*gz>;
			
			# We start anew...
			#
			# Don't gzip sourceFiles from URLs,since it complicates the
			# use of "mirror" (we would have to ungzip the file).  We
			# like "mirror" for now because it does error checking, we
			# might write our own version later...
			#
			# system ( 'gzip', $sourceFile );

			#
			#  is sourceFile in SERA?
			#
			# $sourceFile = LiveGeez::CacheAsSERA::HTML ( $self, $sourceFile );
				# unless ( $self->{request}->{sysIn} && ($self->{request}->{sysIn}->{sysName} eq "sera") );

			# return ( $self->{uris}->{source} = $sourceFile );
		}
		# elsif ( $rc != $RC_NOT_MODIFIED ) {
		# 	return;
		# }
		# continue and use present version

		# Use present cache file, we assume a 304
		if ( -e $cacheFileOut ) {
			$self->{isZipped} = $self->{isCached} = "true";
			$self->{uris}->{cacheout} = $sourceFile = $cacheFileOut;
		}
		else {
			$sourceFile = LiveGeez::CacheAsSERA::Remote ( $self, $sourceFile );
		}
	
	}
	else {
		# use POSIX qw(strftime);

		my $tempFile = "$self->{request}->{config}->{uris}->{cacheremote}/tmp."
		             . POSIX::strftime ( '%m%d%H%M%S', localtime(time) )
		             . "."
		             # . myRand
			     . rand
		             ;
		if ( LWP::Simple::mirror ($self->{request}->{file}, $tempFile) == $RC_OK ) {
			if ( $self->{request}->{uri}->iscgi ) {
				$self->{isCGI} = 1;
				$self->{uris}->{tmpFile} = $sourceFile = $tempFile;
			}
			else {
				MakeCacheDir ($cacheDir, $URLCacheDir);
				rename ( $tempFile, $sourceFile );
			}
			#
			#  is sourceFile in SERA?
			#
			$sourceFile = LiveGeez::CacheAsSERA::Remote ( $self, $sourceFile );
				# unless ( $self->{request}->{sysIn} && ($self->{request}->{sysIn}->{sysName} eq "sera") ); 
		}
		else {
			return;
		}
	}

	$self->{uris}->{source} = $sourceFile;

}


#------------------------------------------------------------------------------#
#
# "MakeCacheDir"
# 
#	Does just as the name implies.  The "$cacheDir" path is received as the 
#	sole argument.  MakeCacheDir will create the subdirectories in the cacheDir
#	path as needed.  This is a naive apporoach to caching but we can live
#	with it for now...
#
#------------------------------------------------------------------------------#
sub MakeCacheDir
{
# my ($cacheDir, $refDir) = @_;  # always starts with "/";

	File::Path::mkpath $_[0], 0, 0755 unless -d $_[0];

	return;
	unless ( (-e $cacheDir) ) {
		$cacheDir    =~ s/^$self->{request}->{config}->{uris}->{webroot}//;
		$cacheDir    =~ s|^/||;

		my $fullPath = $self->{request}->{config}->{uris}->{webroot};
		my (@dirs) = split ( /\//, $cacheDir );

		foreach my $dir ( @dirs ) {
			$fullPath .= "/$dir";
			if ( !(-e $fullPath) ) {
				warn ( "Failed to make '$fullPath' [$cacheDir]: $!" ) unless ( mkdir ($fullPath, 0755) );
			}
		}
	}

}


#------------------------------------------------------------------------------#
#
# "DisplayFromCache"
# 
#	Does just as the name implies.  The "cacheFileOut" string must be set
#	before the method is called.  The file is printed to STDOUT.  Generally
#   cached files are gzipped, DisplayFromCache will gunzip as needed.
#
#------------------------------------------------------------------------------#
sub DisplayFromCache
{
my $self = shift;
my $cacheFile = $self->{uris}->{cacheout};


	my $fileStream 
	= ( ( $self->{isZipped} && $self->{request}->{'x-gzip'} ) || !$self->{isZipped} )
	  ? $cacheFile
	  : "gzip -d --stdout $cacheFile |"
	;

	open ( FILE, "$fileStream" ) || $self->{request}->DieCgi
		 ( "!: Could Not Open Cached File: $cacheFile!\n" );

	$self->{request}->HeaderPrint;

	$self->{request}->print ( <FILE> );

	close (FILE);

}


#------------------------------------------------------------------------------#
#
# "DisplayFromCache"
# 
#	Does just as the name implies.  The "cacheFileOut" string must be set
#	before the method is called.  The file is printed to STDOUT.  Generally
#   cached files are gzipped, DisplayFromCache will gunzip as needed.
#
#------------------------------------------------------------------------------#
sub DisplayFromCacheX
{
my $self = shift;
my $cacheFile = $self->{uris}->{cacheout};


	$self->{request}->HeaderPrint;

	# print STDERR "ZIP[1]: $self->{request}->{'x-gzip'}\n";

	if ( $self->{request}->{apache} ) {
		$self->{request}->HeaderPrint;
		if ( $self->{request}->{'x-gzip'} ) {
			my $fh = Apache::File->new( $cacheFile );
			# print STDERR "Printing Zipped: $cacheFile\n";
			# local $/;
			# print Compress::Zlib::memGzip( <$fh> );
			$self->{request}->{apache}->send_fd($fh);
		}
		else {
			my $fileStream 
			= ( ( $self->{isZipped} && $self->{request}->{'x-gzip'}) || !$self->{isZipped} )
			  ? "$cacheFile"
			  : "gzip -d --stdout $cacheFile |"
			;
			my $fh = Apache::File->new( $fileStream );
			$self->{request}->{apache}->send_fd($fh);
		}
	}
	else {
		my $fileStream 
		= ( ( $self->{isZipped} && $self->{request}->{'x-gzip'}) || !$self->{isZipped} )
		  ? $cacheFile
		  : "gzip -d --stdout $cacheFile |"
		;

		open ( FILE, "$fileStream" ) || $self->{request}->DieCgi
			 ( "!: Could Not Open Cached File: $cacheFile!\n" );


		$self->{request}->HeaderPrint;

		$self->{request}->print ( <FILE> );

		close (FILE);
	}

}


#------------------------------------------------------------------------------#
#
# "ReadFromCache"
# 
#	Does just as the name implies.  The "cacheFileOut" string must be set
#	before the method is called.  Generally cached files are gzipped,
#   ReadFromCache will gunzip as needed.
#
#------------------------------------------------------------------------------#
sub ReadFromCache
{
my $self = shift;
my $cacheFile = $self->{uris}->{cacheout};
my $fileStream;


	$fileStream = ($self->{isZipped}) ? "gzip -d --stdout $cacheFile |" : "$cacheFile";

	open (FILE, "$fileStream") || $self->{request}->DieCgi
	     ( "!: Could Not Open Cached File: $cacheFile!\n" );
	# @gFile = <FILE>;
	# $self->{htmlData} = join ( "", @gFile );
	local $/ = undef;
	$self->{htmlData} = <FILE>;
	close (FILE);

}


sub SaveToCache
{
my $self = shift;
my $cacheFile = $self->{uris}->{cachein};


	if ( $self->{request}->{apache} ) {
		$self->{request}->{apache}->print ( $self->{htmlData} );
		open (CACHEFILE, ">$cacheFile") 
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	else {
		open (CACHEFILE, "| tee $cacheFile")
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	print CACHEFILE $self->{htmlData};
	close (CACHEFILE);

	system ( 'gzip', '-f', $cacheFile ) if ( $cacheFile !~ /\/Frames/ );

}


sub show
{
my $self = shift;


	foreach $key (keys %$self) {
		if ( ref $self->{$key} ) {
			$self->{$key}->show;
		}
		else {
			$self->{request}->print ( "  $key = $self->{$key}\n" );
		}
	}

}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::File - File Openning and Caching for LiveGe'ez

=head1 SYNOPSIS

 use LiveGeez::Request;
 use LiveGeez::File;

 main:
 {

 	my $r = LiveGeez::Request->new;

	my $f = LiveGeez::File->new ( $r );

	$f->Display;

	exit (0);

 }

=head1 DESCRIPTION

File.pm instantiates an object for processing an Ethiopic text or HTML
document.  The constructor requires a LiveGeez::Request object as an
argument.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut

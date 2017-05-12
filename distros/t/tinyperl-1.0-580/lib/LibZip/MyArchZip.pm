##########################################
# SIMPLE ARCHIVE::ZIP INDEPENDENT MODULE #
##########################################

package LibZip::MyArchZip ;
#use vars qw($CHUNKSIZE) ;

#use Compress::Zlib();
use LibZip::MyZlib ;
use LibZip::MyFile ;
#use File::Spec;
#use File::Path;

#########
# BEGIN #
#########

sub BEGIN {
  $CHUNKSIZE = 1024*32 ; ## Memory to use!
}

#############
# CONSTANTS #
#############

sub END_CENTDIR_LENGTH { 18 }
sub END_CENTDIR_SIGN { 0x06054b50 }
sub END_CENTDIR_SIGN_STR { pack( "V", END_CENTDIR_SIGN ) }

sub END_CENTDIR_FORMAT { "v4 V2 v" } ;

sub SIGNATURE_FORMAT {"V"}
sub SIGNATURE_LENGTH { 4 }

sub CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE { 0x02014b50 }

sub LOCAL_FILE_HEADER_SIGNATURE { 0x04034b50 }
sub LOCAL_FILE_HEADER_FORMAT { "v3 V4 v2" }
sub LOCAL_FILE_HEADER_LENGTH { 26 }

sub CENTRAL_DIRECTORY_FILE_HEADER_LENGTH { 42 }
sub CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE { 0x02014b50 }
sub CENTRAL_DIRECTORY_FILE_HEADER_FORMAT    { "C2 v3 V4 v5 V2" }

sub COMPRESSION_STORED   { 0 }    # file is stored (no compression)
sub COMPRESSION_DEFLATED { 8 }    # file is Deflated

sub COMPRESSION_LEVEL_NONE             { 0 }
sub COMPRESSION_LEVEL_DEFAULT          { -1 }
sub COMPRESSION_LEVEL_FASTEST          { 1 }
sub COMPRESSION_LEVEL_BEST_COMPRESSION { 9 }

sub GPBF_ENCRYPTED_MASK { 1 << 0 }

#######
# NEW #
#######

sub new {
  my $class = shift ;
  my $self = bless( {
    'diskNumber'                            => 0,
    'diskNumberWithStartOfCentralDirectory' => 0,
    'numberOfCentralDirectoriesOnThisDisk'  => 0,   # shld be # of members
    'numberOfCentralDirectories'            => 0,   # shld be # of members
    'centralDirectorySize' => 0,    # must re-compute on write
    'centralDirectoryOffsetWRTStartingDiskNumber' => 0,  # must re-compute
    'writeEOCDOffset'             => 0,
    'writeCentralDirectoryOffset' => 0,
    'eocdOffset'                  => 0,
    'fileName'                    => ''
    },
    $class
  );
  
  $self->{'members'} = [];

  if (@_) { $self->read(@_) ;}
  
  return $self;
}

########
# READ #
########

sub read {
  my $self = shift;
  my $fileName = shift;
  
  return _error('No filename given') unless $fileName ;

  my $ZIPFL ;
  open ($ZIPFL,$fileName) ; binmode($ZIPFL) ;

  $self->{'fileName'} = $fileName ;
  $self->{'fh'} = $ZIPFL ;
  
  if (! $self->_find_end_centdir($ZIPFL) ) { return( undef ) ;}
  
  my $eocdPosition = tell($ZIPFL) ;

  if (! $self->_read_end_centdir($ZIPFL) ) { return( undef ) ;}
  
  seek( $ZIPFL , $eocdPosition - $self->{'centralDirectorySize'} , 0 ) || return _error("Can't seek $fileName");
  
  $self->{'eocdOffset'} = $eocdPosition - $self->{'centralDirectorySize'} - $self->{'centralDirectoryOffsetWRTStartingDiskNumber'} ;
  
  for (;;) {
    my $newMember = LibZip::MyArchZip::Member->_newFromZipFile( $ZIPFL , $fileName ) ;
    my ( $status, $signature ) = $self->_readSignature( $ZIPFL , $fileName ) ;
    
    return $status if !$status ;
    
    last if $signature == END_CENTDIR_SIGN ;
    
    if (! $newMember->_readCentralDirectoryFileHeader() ) { return( undef ) ;}

    $newMember->endRead();
    
    $newMember->{'localHeaderRelativeOffset'} += $self->{'eocdOffset'} ;
    
    push ( @{ $self->{'members'} }, $newMember );
  }

  return( 1 ) ;
}

#################
# EXTRACTMEMBER #
#################

sub extractMember {
  my $self   = shift;
  my $member = shift;

  $member = $self->memberNamed($member) unless ref($member);
  return _error('member not found') unless $member;
  
  my $name = shift;    # local FS name if given
  if (! defined($name)) { return _error('No save name past to extract!') ;}

  my ( $volumeName, $dirName, $fileName ) = LibZip::File::Spec->splitpath($name);
  $dirName = LibZip::File::Spec->catpath( $volumeName, $dirName, '' );

  LibZip::File::Path::mkpath($dirName) if ( !-d $dirName );
  return _ioError("can't create dir $dirName") if ( !-d $dirName );
  return $member->extractToFileNamed( $name, @_ );
}

###############
# EXTRACTTREE #
###############

sub extractTree {
  my $self = shift ();
  my $root = shift () || '';	# Zip format
  my $dest = shift || '.';	# Zip format
  my $volume = shift;			# optional
  my $pattern = qr{^\Q$root};
  my @members = $self->membersMatching($pattern);
  my $slash   = qr{/};

  foreach my $member (@members) {
    my $fileName = $member->{'fileName'} ;    # in Unix format
    $fileName =~ s{$pattern}{$dest};       # in Unix format
  		                                       # convert to platform format:
  
    my $status = $member->extractToFileNamed($fileName);
    return $status if $status != 0;
  }
  return 0;
}

###################
# MEMBERSMATCHING #
###################

sub membersMatching {
  my ( $self, $pattern ) = @_ ;
  return grep { $_->{'fileName'} =~ /$pattern/ } $self->members();
}



###########
# MEMBERS #
###########

sub members { @{ shift->{'members'} } ;}

###############
# MEMBERNAMES #
###############

sub memberNames {
  my $self = shift;
  return map { $_->{'fileName'} } $self->members() ;
}

###############
# MEMBERNAMED #
###############

sub memberNamed {
  my ( $self, $fileName ) = @_;
  foreach my $member ( $self->members() ) { return $member if $member->{'fileName'} eq $fileName ;}
  return undef;
}

##################
# _READSIGNATURE #
##################

sub _readSignature {
  my $self     = shift;
  my $fh       = shift;
  my $fileName = shift;
  my $signatureData;
  
  my $bytesRead = read( $fh , $signatureData , SIGNATURE_LENGTH );
  
  if ( $bytesRead != SIGNATURE_LENGTH ) { return _error("reading header signature") ;}
  
  my $signature = unpack( SIGNATURE_FORMAT, $signatureData );

  my $status = 1;
  
  if ( $signature != CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE && 
       $signature != LOCAL_FILE_HEADER_SIGNATURE &&
       $signature != END_CENTDIR_SIGN ) {

       my $errmsg = sprintf( "bad signature: 0x%08x", $signature );
       if (-f $self->{'fh'} ) {  $errmsg .= sprintf( " at offset %d", tell($fh) - SIGNATURE_LENGTH ) ;}
    
       $status = _error("$errmsg in file $fileName");
  }
  
  return ( $status, $signature );
}

#####################
# _READ_END_CENTDIR #
#####################

sub _read_end_centdir {
  my $self = shift;
  my $fh   = shift;
  
  seek( $fh , SIGNATURE_LENGTH, 1 ) || return _error("Can't seek past EOCD signature") ;
  
  my $header ;
  my $bytesRead = read( $fh , $header, END_CENTDIR_LENGTH );
  if ( $bytesRead != END_CENTDIR_LENGTH ) { return _error("reading end of central directory $bytesRead") ;}

  my $zipfileCommentLength;
  
  ( $self->{'diskNumber'},
    $self->{'diskNumberWithStartOfCentralDirectory'},
    $self->{'numberOfCentralDirectoriesOnThisDisk'},
    $self->{'numberOfCentralDirectories'},
    $self->{'centralDirectorySize'},
    $self->{'centralDirectoryOffsetWRTStartingDiskNumber'},
    $zipfileCommentLength ) = unpack( END_CENTDIR_FORMAT , $header );

  return( 1 ) ;
}
  
#####################
# _FIND_END_CENTDIR #
#####################

sub _find_end_centdir {
  my $self = shift;
  my $fh   = shift;
  
  seek($fh, 0, 2) ;
  
  my $fileLength = tell($fh) ;
  
  if ($fileLength < END_CENTDIR_LENGTH+4) { _error("file is too short!") ;}
  
  my $seekOffset = 0;
  my $pos = -1;
  my $data ;
  
  for (;;) {
    $seekOffset += 512;
    $seekOffset = $fileLength if ( $seekOffset > $fileLength ) ;
    
    seek($fh, -$seekOffset , 2) || return _error("seek failed") ;
    
    my $bytesRead = read($fh, $data , $seekOffset) ;

    if ( $bytesRead != $seekOffset ) { return _error("read failed") ;}
    
    $pos = rindex( $data, END_CENTDIR_SIGN_STR ) ;
    
    if ( $pos >= 0 || $seekOffset == $fileLength || $seekOffset >= $CHUNKSIZE ) { last ;}
  }
  
  if ( $pos >= 0 ) {
    seek($fh, $pos-$seekOffset , 1) || return _error("seeking to EOCD") ;
    return( 1 ) ;
  }
  else { return _error("can't find EOCD signature") ;}
}

##########  
# _ERROR #
##########

sub _error { print STDERR "ERROR: $_[0]\n" ; return( undef ) ;}



################################################################################
# LIBZIP::MYARCHZIP::MEMBER
################################################################################

package LibZip::MyArchZip::Member ;

#use Compress::Zlib ();
use LibZip::MyZlib ;
use LibZip::MyFile ;
#use File::Path;
#use File::Basename;

sub _error { LibZip::MyArchZip::_error(@_) ;}

sub Z_OK {0}
sub Z_STREAM_END {1}
sub MAX_WBITS {15}

#########
# BEGIN #
#########

sub BEGIN {

  my @CONST = qw(
  CENTRAL_DIRECTORY_FILE_HEADER_FORMAT
  CENTRAL_DIRECTORY_FILE_HEADER_LENGTH
  CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE
  CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE
  COMPRESSION_DEFLATED
  COMPRESSION_LEVEL_BEST_COMPRESSION
  COMPRESSION_LEVEL_DEFAULT
  COMPRESSION_LEVEL_FASTEST
  COMPRESSION_LEVEL_NONE
  COMPRESSION_STORED
  END_CENTDIR_FORMAT
  END_CENTDIR_LENGTH
  END_CENTDIR_SIGN
  END_CENTDIR_SIGN_STR
  GPBF_ENCRYPTED_MASK
  LOCAL_FILE_HEADER_FORMAT
  LOCAL_FILE_HEADER_LENGTH
  LOCAL_FILE_HEADER_SIGNATURE
  SIGNATURE_FORMAT
  SIGNATURE_LENGTH
  ) ;

  foreach my $CONST_i ( @CONST ) {
    eval(qq` sub $CONST_i { &LibZip::MyArchZip::$CONST_i } `);
  }

}

###################
# _NEWFROMZIPFILE #
###################

sub _newFromZipFile {
  my $class            = shift;
  my $fh               = shift;
  my $externalFileName = shift;
  
  my $self  = {
    'lastModFileDateTime'      => 0,
    'fileAttributeFormat'      => FA_UNIX,
    'versionMadeBy'            => 20,
    'versionNeededToExtract'   => 20,
    'bitFlag'                  => 0,
    'compressionMethod'        => COMPRESSION_STORED,
    'desiredCompressionMethod' => COMPRESSION_STORED,
    'desiredCompressionLevel'  => COMPRESSION_LEVEL_NONE,
    'internalFileAttributes'   => 0,
    'externalFileAttributes'   => 0,                        # set later
    'fileName'                 => '',
    'cdExtraField'             => '',
    'localExtraField'          => '',
    'fileComment'              => '',
    'crc32'                    => 0,
    'compressedSize'           => 0,
    'uncompressedSize'         => 0,
    'diskNumberStart'           => 0,
    'localHeaderRelativeOffset' => 0,
    'dataOffset' => 0,    # localHeaderRelativeOffset + header length
    @_
  };
  bless( $self, $class );
  $self->{'externalFileName'} = $externalFileName;
  $self->{'fh'}               = $fh;
  return $self ;
}

###################################
# _READCENTRALDIRECTORYFILEHEADER #
###################################

sub _readCentralDirectoryFileHeader {
  my $self = shift;
  my $fh = $self->{'fh'} ;

  my $header ;
  my $bytesRead = read($fh , $header, CENTRAL_DIRECTORY_FILE_HEADER_LENGTH );
  
  if ( $bytesRead != CENTRAL_DIRECTORY_FILE_HEADER_LENGTH ) { return _error("reading central dir header") ;}
  
  my ( $fileNameLength, $extraFieldLength, $fileCommentLength ) ;
  
  ( $self->{'versionMadeBy'},          $self->{'fileAttributeFormat'},
    $self->{'versionNeededToExtract'}, $self->{'bitFlag'},
    $self->{'compressionMethod'},      $self->{'lastModFileDateTime'},
    $self->{'crc32'},                  $self->{'compressedSize'},
    $self->{'uncompressedSize'},       $fileNameLength,
    $extraFieldLength,                 $fileCommentLength,
    $self->{'diskNumberStart'},        $self->{'internalFileAttributes'},
    $self->{'externalFileAttributes'}, $self->{'localHeaderRelativeOffset'} ) = unpack( CENTRAL_DIRECTORY_FILE_HEADER_FORMAT, $header );

  if ($fileNameLength) {
    $bytesRead = read( $fh , $self->{'fileName'}, $fileNameLength );
    if ( $bytesRead != $fileNameLength ) { _error("reading central dir filename") ;}
  }
  
  if ($extraFieldLength) {
    $bytesRead = read($fh , $self->{'cdExtraField'}, $extraFieldLength );
    if ( $bytesRead != $extraFieldLength ) { return _error("reading central dir extra field") ;}
  }

  if ($fileCommentLength) {
    $bytesRead = read($fh , $self->{'fileComment'}, $fileCommentLength );
    if ( $bytesRead != $fileCommentLength ) { return _error("reading central dir file comment") ;}
  }

  $self->desiredCompressionMethod( $self->{'compressionMethod'} );

  return 1 ;
}

############################
# DESIREDCOMPRESSIONMETHOD #
############################

sub desiredCompressionMethod {
  my $self                        = shift;
  my $newDesiredCompressionMethod = shift;
  my $oldDesiredCompressionMethod = $self->{'desiredCompressionMethod'};

  if ( defined($newDesiredCompressionMethod) ) {
    $self->{'desiredCompressionMethod'} = $newDesiredCompressionMethod;

    if ( $newDesiredCompressionMethod == COMPRESSION_STORED ) {
      $self->{'desiredCompressionLevel'} = 0;
    }
    elsif ( $oldDesiredCompressionMethod == COMPRESSION_STORED ) {
      $self->{'desiredCompressionLevel'} = COMPRESSION_LEVEL_DEFAULT;
    }
  }

  return $oldDesiredCompressionMethod;
}

###########
# ENDREAD #
###########

sub endRead {
  my $self = shift;
  $self->{'fh'} = undef;
  delete $self->{'inflater'};
  delete $self->{'deflater'};
  $self->{'dataEnded'}         = 1;
  $self->{'readDataRemaining'} = 0;
  return 0 ;
}

###############################
# _BECOMEDIRECTORYIFNECESSARY #
###############################

sub _becomeDirectoryIfNecessary { 1 }

###############
# ISDIRECTORY #
###############

sub isDirectory {
  my $self = shift;
  return ( substr( $self->{'fileName'} , -1) eq '/' and $self->{'uncompressedSize'} == 0 );
}

######################
# EXTRACTTOFILENAMED #
######################

sub extractToFileNamed {
  my $self = shift;
  my $name = shift;    # local FS name
  return _error("encryption unsupported") if $self->isEncrypted();
  
  LibZip::File::Path::mkpath( LibZip::File::Basename::dirname($name) );    # croaks on error
  
  my $fh ;
  open ($fh,">$name") ; binmode($fh) ;
  my $retval = $self->extractToFileHandle($fh) ;
  close($fh) ;
  
  utime( $self->{'lastModTime'}, $self->{'lastModTime'}, $name );
  
  return $retval;
}

#######################
# EXTRACTTOFILEHANDLE #
#######################

sub extractToFileHandle {
  my $self = shift;
  return _error("encryption unsupported") if $self->isEncrypted();
  my $fh = shift;
  binmode($fh) ;
  
  my $oldCompression = $self->desiredCompressionMethod(COMPRESSION_STORED);

  $self->{'fh'} = undef ;

  my $status = $self->rewindData2(@_);
  
  $status = $self->_writeData($fh) if $status == 0 ;

  $self->desiredCompressionMethod($oldCompression);
  $self->endRead();

  return $status;
}

##############
# REWINDDATA #
##############

sub rewindData {
  my $self = shift;
  my $status;

  $self->{'chunkHandler'} = $self->can('_noChunk');

  # Work around WinZip bug with 0-length DEFLATED files
  $self->desiredCompressionMethod(COMPRESSION_STORED) if $self->{'uncompressedSize'} == 0 ;

  # assume that we're going to read the whole file, and compute the CRC anew.
  
  $self->{'crc32'} = 0 if ( $self->{'compressionMethod'} == COMPRESSION_STORED );

  # These are the only combinations of methods we deal with right now.
  if ($self->{'compressionMethod'} == COMPRESSION_STORED && $self->desiredCompressionMethod() == COMPRESSION_DEFLATED ) {
    
    ( $self->{'deflater'}, $status ) = Compress::Zlib::deflateInit(
    '-Level' => $self->desiredCompressionLevel(),
    '-WindowBits' => -MAX_WBITS(),
    @_
    );

    return _error( 'deflateInit error!' ) unless $status == 0 ;
    $self->{'chunkHandler'} = $self->can('_deflateChunk');
    
  }
  elsif ( $self->{'compressionMethod'} == COMPRESSION_DEFLATED && $self->desiredCompressionMethod() == COMPRESSION_STORED ) {
    ( $self->{'inflater'}, $status ) = Compress::Zlib::inflateInit(
    '-WindowBits' => -MAX_WBITS(),
    @_
    );

    return _error( 'inflateInit error!' ) unless $status == 0 ;
    $self->{'chunkHandler'} = $self->can('_inflateChunk');
  }

  elsif ( $self->{'compressionMethod'} == $self->desiredCompressionMethod() ) { $self->{'chunkHandler'} = $self->can('_copyChunk') ;}

  else {
    return _error(
    sprintf( "Unsupported compression combination: read %d, write %d", $self->{'compressionMethod'}, $self->desiredCompressionMethod() )
    );
  }

  $self->{'readDataRemaining'} = ( $self->{'compressionMethod'} == COMPRESSION_STORED ) ? $self->{'uncompressedSize'} : $self->{'compressedSize'} ;
  $self->{'dataEnded'}  = 0;
  $self->{'readOffset'} = 0;

  return 0 ;
}

###############
# REWINDDATA2 #
###############

sub rewindData2 {
  my $self = shift;

  my $status = $self->rewindData(@_);
  return $status unless $status == 0;

  return 4 unless $self->fh() ;

  # Seek to local file header.
  # The only reason that I'm doing this this way is that the extraField
  # length seems to be different between the CD header and the LF header.
  seek( $self->{'fh'} , $self->{'localHeaderRelativeOffset'} + SIGNATURE_LENGTH , 0 ) or return _error("seeking to local header");
  
  
  # skip local file header
  $status = $self->_skipLocalFileHeader();
  return $status unless $status == 0 ;
  
  # Seek to beginning of file data
  seek($self->{'fh'} , $self->{'dataOffset'} , 0 ) || return _error("seeking to beginning of file data") ;

  return 0 ;
}

########################
# _SKIPLOCALFILEHEADER #
########################

sub _skipLocalFileHeader {
  my $self = shift;
  my $header;
  my $bytesRead = read($self->{'fh'} , $header, LOCAL_FILE_HEADER_LENGTH );
  if ( $bytesRead != LOCAL_FILE_HEADER_LENGTH ) { return _error("reading local file header") ;}

  my $fileNameLength;
  my $extraFieldLength;

  ( undef,    # $self->{'versionNeededToExtract'},
    undef,    # $self->{'bitFlag'},
    undef,    # $self->{'compressionMethod'},
    undef,    # $self->{'lastModFileDateTime'},
    undef,    # $crc32,
    undef,    # $compressedSize,
    undef,    # $uncompressedSize,
    $fileNameLength,
    $extraFieldLength )
    = unpack( LOCAL_FILE_HEADER_FORMAT, $header );

  if ($fileNameLength) {
    seek($self->{'fh'} , $fileNameLength, 1 ) || return _error("skipping local file name") ;
  }

  if ($extraFieldLength) {
    $bytesRead = read( $self->{'fh'} , $self->{'localExtraField'}, $extraFieldLength );
    if ( $bytesRead != $extraFieldLength ) { return _error("reading local extra field") ;}
  }

  $self->{'dataOffset'} = tell($self->{'fh'}) ;

  return 0 ;
}

##############
# _WRITEDATA #
##############

sub _writeData {
  my $self    = shift;
  my $writeFh = shift;

  return 0 if ( $self->{'uncompressedSize'} == 0 ) ;

  my $status;
  my $chunkSize = $LibZip::MyArchZip::CHUNKSIZE ;

  while ( $self->{'readDataRemaining'} > 0 ) {
    my $outRef;
    ( $outRef, $status ) = $self->readChunk($chunkSize);
    return $status if ( $status != 0 and $status != 1 );

    if ( length($$outRef) > 0 ) {
      print $writeFh $$outRef || return _ioError("write error during copy");
    }

    last if $status == 1 ;
  }

  $self->{'compressedSize'} = $self->{'writeOffset'} ;
  return 0 ;
}

#############
# READCHUNK #
#############

sub readChunk {
	my ( $self, $chunkSize ) = @_;

	if ( $self->readIsDone() ) {
		$self->endRead();
		my $dummy = '';
		return ( \$dummy, 1 );
	}

	$chunkSize = $LibZip::MyArchZip::CHUNKSIZE if not defined($chunkSize);
	$chunkSize = $self->{'readDataRemaining'} if $chunkSize > $self->{'readDataRemaining'} ;

	my $buffer ;
	my $outputRef;
	my ( $bytesRead, $status ) = $self->_readRawChunk( \$buffer, $chunkSize );
	return ( \$buffer, $status ) unless $status == 0 ;

	$self->{'readDataRemaining'} -= $bytesRead;
	$self->{'readOffset'} += $bytesRead;

	if ( $self->{'compressionMethod'} == COMPRESSION_STORED ) {
		$self->{'crc32'} = $self->computeCRC32( $buffer, $self->{'crc32'} );
	}

	( $outputRef, $status ) = &{ $self->{'chunkHandler'} } ( $self, \$buffer );
	$self->{'writeOffset'} += length($$outputRef);

	$self->endRead() if $self->readIsDone() ;

	return ( $outputRef, $status );
}

#################
# _READRAWCHUNK #
#################

sub _readRawChunk {
  my ( $self, $dataRef, $chunkSize ) = @_;
  return ( 0, 0 ) unless $chunkSize;

  my $fh = $self->fh ;
  my $bytesRead = read( $fh , $$dataRef, $chunkSize ) || return ( 0, _error("reading data") );
  
  return ( $bytesRead, 0 );
}

######
# FH #
######

sub fh {
  my $self = shift;
  $self->fh_open() if ! $self->{'fh'} ;
  return $self->{'fh'};
}

###########
# FH_OPEN #
###########

sub fh_open {
  my $self = shift ;  
  my $fh ;
  open ($fh,  $self->{'externalFileName'} ) ;
  binmode($fh);
  $self->{'fh'} = $fh ;
  return( $fh ) ;
}

##############
# READISDONE #
##############

sub readIsDone {
  my $self = shift;
  return ( $self->{'dataEnded'} or !$self->{'readDataRemaining'} );
}

#################
# _DEFLATECHUNK #
#################

sub _deflateChunk {
	my ( $self, $buffer ) = @_;
	my ( $out,  $status ) = $self->{'deflater'}->deflate($buffer);

	if ( $self->{'readDataRemaining'} == 0 )
	{
		my $extraOutput;
		( $extraOutput, $status ) = $self->{'deflater'}->flush();
		$out .= $extraOutput;
		$self->endRead();
		return ( \$out, 1 );
	}
	elsif ( $status == Z_OK ) {
		return ( \$out, 0 );
	}
	else
	{
		$self->endRead();
		my $retval = _error( 'deflate error', $status );
		my $dummy = '';
		return ( \$dummy, $retval );
	}
}

#################
# _INFLATECHUNK #
#################

sub _inflateChunk {
  my ( $self, $buffer ) = @_;
  my ( $out,  $status ) = $self->{'inflater'}->inflate($buffer);
 
  my $retval;
  $self->endRead() unless $status == Z_OK;
  if ( $status == Z_OK || $status == Z_STREAM_END ) {
    $retval = ( $status == Z_STREAM_END ) ? 1 : 0 ;
    return ( \$out, $retval );
  }
  else {
    $retval = _error( 'inflate error', $status );
    my $dummy = '';
    return ( \$dummy, $retval );
  }
}

sub _copyChunk {
  my ( $self, $dataRef ) = @_;
  return ( $dataRef, 0 );
}

sub computeCRC32 {
  my $data = shift;
  $data = shift if ref($data);    # allow calling as an obj method
  my $crc = shift;
  return Compress::Zlib::crc32( $data, $crc );
}


###############
# ISENCRYPTED #
###############

sub isEncrypted { shift->{'bitFlag'} & GPBF_ENCRYPTED_MASK ;}

#######
# END #
#######

1;



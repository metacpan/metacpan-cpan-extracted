#############################################################################
## Name:        LibZip.pm
## Purpose:     Use lib.zip files as Perl librarys directorys.
## Author:      Graciliano M. P.
## Modified by:
## Created:     21/10/2002
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip ;

use LibZip::MyArchZip ;
my ($LIBZIP,$LIBTMP,@LIBBASES,%LIBTREE,$ZIP,%DEP,$FILETMP,%FILETMP,@DIRTMP,@DATAPACK,@INC_ORG,@LYB) ;

$DEBUG = 0 ;

unshift(@INC , \&INC ) ;

##########
# IMPORT #
##########

sub import {
  my ($class , @args) = @_ ;

  if (-s $args[0]) { $LIBZIP = $args[0] ;}
  
  &LoadLibZip($LIBZIP) ;
}

#######
# INC #
#######

sub INC {
  my ( $ref , $pack ) = @_ ;

  my $pack_fl = find_file_zip($pack) ;
  
  if ($pack_fl eq '') { return( undef ) ;}

  check_pack_dep($pack_fl) ;
  
#  $INC{$pack} = "$LIBZIP#:/$pack_fl" ;
  
  $INC{$pack} = "$LIBTMP/$pack_fl" ;
  
  return( get_file_zip_handle( $pack_fl ) ) ;
}

##############
# LOADLIBZIP #
##############

sub LoadLibZip {
  my ( $libzip ) = @_ ;

  if (!-s $libzip) { croak("Can't find or load LibZip: $libzip") ;}

  $ZIP = LibZip::MyArchZip->new();
  $ZIP->read($libzip);

  %LIBTREE = map { $_ => 1 } ($ZIP->memberNames()) ;
  
  foreach my $libtree_i ( keys %LIBTREE ) {
    if ($libtree_i =~ /^\/*(?:lib|site\/lib)\/*$/i) {
      my $memb = $ZIP->memberNamed($libtree_i) ;
      if ( $memb->isDirectory ) { push(@LIBBASES , $libtree_i) ;}
    }
  }
  
  push(@LIBBASES , "") ;
  
  foreach my $LIBBASES_i ( @LIBBASES ) { unshift(@INC , "$LIBTMP/$LIBBASES_i") ;}
  
  my $libzipdir ;
  
  foreach my $LIBBASES_i ( @LIBBASES ) {
    my $dir = zip_path($LIBBASES_i,'LibZip') ;
    if ($LIBTREE{$dir}) { $libzipdir = $dir ;}
  }
  
  my $LibZipInfo_pm ;
  
  if ($libzipdir eq '') { $LibZipInfo_pm = 'LibZipInfo.pm' ;}
  else { $LibZipInfo_pm = zip_path($libzipdir,'Info.pm') ;}
  
  if ($LIBTREE{$LibZipInfo_pm}) {
    my $pack = pm2pack($LibZipInfo_pm) ;
    eval("require $pack ;") ;
  }
  else { eval("require LibZip::Info ;") ;}
  
}

#############
# FIND_FILE #
#############

sub find_file {
  my ( $pack , @LIB ) = @_ ;
  my $pack_fl ;
  
  foreach my $LIB_i ( @INC , @LIB ) {
    if ( ref($LIB_i) ) { next ;}
    my $fl = "$LIB_i/$pack" ;
    if (-e $fl) { $pack_fl = $fl ;}
  }

  return( $pack_fl ) ;
}

#################
# FIND_FILE_ZIP #
#################

sub find_file_zip {
  my ( $pack ) = @_ ;
  
  foreach my $LIB_i ( @LIBBASES ) {
    my $fl = zip_path($LIB_i,$pack) ;
    if ( $LIBTREE{$fl} ) { return( $fl ) ;}
  }

  return( undef ) ;
}

#######################
# GET_FILE_ZIP_HANDLE #
#######################

sub get_file_zip_handle {
  my ( $file ) = @_ ;

#  my $filename = $FILETMP ;
  
  my $filename = "$LIBTMP/$file" ;
  
  my $memb = $ZIP->memberNamed($file) ;
  my $size = $memb->{'uncompressedSize'} ;

  if ($size > 0 && -s $filename != $size) {
    $ZIP->extractMember($file,$filename) ;
    print "ZIP>> $file\n" if $DEBUG ;
  }
  
#   my ($has_DATA) = has_data_block($file,$filename) ;
#   
#   if ($has_DATA) {
#     print "DATA>>> $filename\n" ;
#     $filename = new_tempfile($LIBTMP) ;
#     rename($FILETMP,$filename) ;
#   }

  $PMFILE = $filename ;

  my $fh ;
  open ($fh,$filename) ; binmode($fh) ;

  return( $fh ) ;
}

##################
# HAS_DATA_BLOCK #
##################

sub has_data_block {
  my ( $file , $filename ) = @_ ;
  
  if ( %LibZip::Info::DATA ) {
    my $pack = pm2pack($file) ;
    if ( defined $LibZip::Info::DATA{$pack} ) {
      push(@DATAPACK , $LibZip::Info::DATA{$pack} , $pack) ;
      return(1 , $LibZip::Info::DATA{$pack}) ;
    }
    else { return( undef ) ;}
  }

  my ($fh,$has_DATA,$datapack) ;

  open ($fh,$filename) ;
  while (my $line = <$fh>) {
    if ($line =~ /package\s+([\w+:]+)/s) { $datapack = $1 ;}
    if ($line =~ /^__DATA__\s+$/s) { $has_DATA = 1 ; push(@DATAPACK , $datapack) ;}
  }
  close ($fh) ;
  
  return($has_DATA,$datapack) ;
}

###########
# PM2PACK #
###########

sub pm2pack {
  my ( $pack ) = @_ ;
  $pack =~ s/^.*?\/lib\///i ;
  $pack =~ s/[\\\/]/::/gs ;
  $pack =~ s/\.pm$//i ;
  return( $pack ) ;
}

############
# ZIP_PATH #
############

sub zip_path {
  my ( $dir ) = @_ ;
  $dir .= '/' if ($dir ne '' && $dir !~ /\/$/) ;
  $dir .= $_[1] ;
  return( $dir ) ;
}

################
# NEW_TEMPFILE #
################

sub new_tempfile {
  my ( $lib ) = @_ ;
  
  my $rand ;
  while(length($rand) < 4) { $rand .= $LYB[rand(@LYB)] ;}
  
  my $file = "$lib/pm-$$-$rand.tmp" ;
  
  if (-e $file) { $file = &new_tempfile($_[0],1) ;}
  
  if (! $_[1]) { $FILETMP{$file} = 0 ;}
  
  return( $file ) ;
}

###############
# NEW_TEMPDIR #
###############

sub new_tempdir {
  my ( $lib ) = @_ ;

  my $rand ;
  while(length($rand) < 4) { $rand .= $LYB[rand(@LYB)] ;}
  
  my $file = "$lib/libzip-$$-$rand-tmp" ;
  
  if (-e $file) { $file = &new_tempdir($_[0],1) ;}
  
  if (! $_[1]) {
    mkdir($file,0775) ;
    push(@DIRTMP , $file) ;
  }
  
  return( $file ) ;
}

##################
# CHECK_PACK_DEP #
##################

sub check_pack_dep {
  my ( $pack ) = @_ ;

  $pack =~ s/\/*\.pm$/\//i ;
  
  if ( $DEP{$pack} || (!$LIBTREE{$pack} && !$LIBTREE{$_[0]}) ) { return ;}
  $DEP{$pack} = 1 ;
  
  foreach my $path ( keys %LIBTREE ) {
    if ( $path !~ /\/$/ ) {
      if ( $path =~ /^\Q$pack\E[^\/]+$/ && $path !~ /\.pm$/i) {
        my $extract = "$LIBTMP/$path" ;
        my $memb = $ZIP->memberNamed($path) ;
        my $size = $memb->{'uncompressedSize'} ;
        
        if ($size > 0 && -s $extract != $size) {
          $ZIP->extractMember($path,$extract) ;
          print "DEP>> $path\n" if $DEBUG ;
        }
      }
    }
  }
  
  if ($pack =~ /^(?:lib|site\/lib)\/([^\/]+.*)$/ && !$_[1] ) {
    my $pack_path = $1 ;
    
    foreach my $LIBBASES_i ( @LIBBASES ) {
      my $auto = zip_path($LIBBASES_i,"auto/$pack_path") ;
      if ( $LIBTREE{$auto} ) { check_pack_dep("$auto.pm",1) ;}
    }
  }
  
  if ( %LibZip::Info::DEPENDENCES ) {
    my $package = pm2pack($_[0]) ;
    foreach my $Key ( keys %LibZip::Info::DEPENDENCES ) {
      if ( $Key =~ /^$package$/i ) {
        my @dep ;
        if (ref($LibZip::Info::DEPENDENCES{$Key}) eq 'ARRAY' ) { @dep = @{$LibZip::Info::DEPENDENCES{$Key}} ;}
        else { @dep = $LibZip::Info::DEPENDENCES{$Key} ;}
        foreach my $dep_i ( @dep ) {
          my $path = find_file_zip($dep_i) ;
          my $extract = "$LIBTMP/$path" ;
          if ($path =~ /\/$/) {
            $ZIP->extractTree($path,$extract) ;
            print "%DEP>> $path >> $extract\n" if $DEBUG ;
          }
          else {
            my $memb = $ZIP->memberNamed($path) ;
            my $size = $memb->{'uncompressedSize'} ;
            if ($size > 0 && -s $extract != $size) {
              $ZIP->extractMember($path,$extract) ;
              print "%DEP>> $path >> $extract\n" if $DEBUG ;
            }
          }
          
        }
      }
    }
  }

  return( undef ) ;
}

################
# CHK_DEAD_TMP #
################

sub chk_dead_tmp {
  opendir (LIBTMPDIR, $LIBTMP) ;
  
  my ($has_files,@dirs) ;

  while (my $filename = readdir LIBTMPDIR) {
    if ($filename ne "\." && $filename ne "\.\.") {
      my $file = "$LIBTMP/$filename" ;
      if (-d $file) { push(@dirs , $file) ;}
      else {
        my ($pid) = ( $filename =~ /^pm-(-?[\d]+)-/i );
        if ($_[0] ne '') {
          if ($pid == $_[0]) { unlink ($file) ;}
          else { $has_files = 1 ;}
        }
        elsif (! kill(0,$pid)) { unlink ($file) ;}
        else { $has_files = 1 ;}
      }
    }
  }
  
  if (! $has_files) {
    foreach my $dirs_i ( @dirs ) { LibZip::File::Path::rmtree($dirs_i,0) ;}
  }
  
  closedir(LIBTMPDIR) ;
}

#########
# BEGIN #
#########

sub BEGIN {
  if (-d './lib') { splice(@INC,-1,0,'./lib') ;}
  
  @INC_ORG = @INC ;
  
  @LYB = qw(0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) ;

  $INC{'XSLoader.pm'} = 'internal';
  $INC{'DynaLoader.pm'} = 'internal';
  
  #require File::Path ;
  eval(q` sub LibZip::File::Path::carp {1} ;`); ## Prevent alerts!
  
  my @find_lib = @INC_ORG ;
  
  foreach my $find_lib_i ( @find_lib ) { $find_lib_i =~ s/[\\\/]+[^\\\/]+[\\\/]*$// ;}
  
  $LIBZIP = find_file('lib.zip',@find_lib,'.') ;
  
  my $libtmp ;
  
  foreach my $find_lib_i ( @find_lib ) {
    if ($find_lib_i =~ /[\\\/]site$/i) {
      my $tmp_lib = "$find_lib_i/libzip-tmp" ;
      if (! -d $tmp_lib) { mkdir($tmp_lib,0775) ;}
      if (-d $tmp_lib && -r $tmp_lib && -w $tmp_lib) { $libtmp = $tmp_lib ; next ;}
    }
  }
  
  if ($libtmp eq '') {
    foreach my $find_lib_i ( @INC_ORG ) {
      if ($find_lib_i =~ /[\\\/]lib$/i) {
        my $tmp_lib = "$find_lib_i/libzip-tmp" ;
        if (! -d $tmp_lib) { mkdir($tmp_lib,0775) ;}
        if (-d $tmp_lib && -r $tmp_lib && -w $tmp_lib) { $libtmp = $tmp_lib ; next ;}
      }
    }
  }

  if ($libtmp eq '') { $libtmp = new_tempdir('.') ;}
  
  $LIBTMP = $libtmp ;
  
  &chk_dead_tmp($$) ;
  
  $FILETMP = "$LIBTMP/pm-$$-zip.tmp" ;
  
  open (FILETMP,">$FILETMP") ;
  
  #delete $INC{'XSLoader.pm'} ;
  #delete $INC{'DynaLoader.pm'} ;
}

#######
# END #
#######

sub END {

  foreach my $DATAPACK_i ( @DATAPACK ) {
    eval(qq`close($DATAPACK_i\::DATA);`);
  }
  
  close(FILETMP) ;  
  
  foreach my $FILETMP_i ( keys %FILETMP , $FILETMP ) { unlink ($FILETMP_i) ;}

  &chk_dead_tmp ;

  opendir (LIBTMPDIR, $LIBTMP);

  while (my $filename = readdir LIBTMPDIR) {
    if ($filename ne "\." && $filename ne "\.\.") {
      my $file = "$LIBTMP/$filename" ;
#      if (-d $file) { File::Path::rmtree($file,0) ;}
    }
  }
  
  closedir(LIBTMPDIR) ;

  foreach my $DIRTMP_i ( @DIRTMP ) { rmdir($DIRTMP_i) ;}

}

#######
# END #
#######

1;



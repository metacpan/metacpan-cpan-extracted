#############################################################################
## Name:        http.pm
## Purpose:     lib::http
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-02-04
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package lib::http ;

  use strict qw(vars) ;
  
  use vars qw($VERSION @ISA $DEBUG %STATUS) ;
  
  $VERSION = '0.01' ;

###########
# REQUIRE #
###########

  use Socket ;

########
# VARS #
########

  my $AGENT = "lib::http/$VERSION Perl/$] ($^O)" ;
  
  my @MONTHS_DAYS = ('',31,28,31,30,31,30,31,31,30,31,30,31) ;
  
  my ( $ACCEPT_GZIP , $ENABLE_GZIP , @IDX_FIND , $FIND_IDX , %LIBS_IDX  , @TMPDIRS ) ;
  my ( $TMPDIR , $TMPFILE , @INC_LIB , %INC_LIB , %URLS , %LIB_TREE ) ;
  
  use constant URI_TIMEOUT => 60 ;
  use constant USER_AGENT => "perl-lib-httpd/$VERSION libwww-perl/$LWP::VERSION Perl/$] ($^O)" ;
  
  my @STATIC_TMPDIR = qw(libhttp lib/libhttp-tmp) ;
  
  my $LIB_VER = $] ;
  $LIB_VER =~ s/(\d+)\.(\d\d\d)(\d\d\d)/$1 .'.'. ($2*1) .'.'. ($3*1)/ge ;
  
  my @LIB_VERSIONED = (
  'lib','site/lib', ## win32
  'perl5','site_perl','perl5/site_perl','perl5/vendor_perl' , ## linux
  ) ;
  
  {
    my @copy = @LIB_VERSIONED ;
    foreach my $LIB_VERSIONED_i ( @copy ) {
      push(@LIB_VERSIONED , "$LIB_VERSIONED_i/$LIB_VER") ;
    }
  }
  
  my %MONTHS_EG = (
  'jan' => 1 ,
  'feb' => 2 ,
  'mar' => 3 ,
  'apr' => 4 ,
  'may' => 5 ,
  'jun' => 6 ,
  'jul' => 7 ,
  'aug' => 8 ,
  'sep' => 9 ,
  'oct' => 10 ,
  'nov' => 11 ,
  'dec' => 12
  );

##########
# IMPORT #
##########

sub import {
  my $class = shift ;
  
  if ( @_ == 1 ) {
    if ( $_[0] eq 'unlink_tmpfile' ) {
      unlink_tmpfile(1) ;
      return ;
    }
    elsif ( $_[0] =~ /debug/i ) {
      $DEBUG = 1 ;
      return ;
    }
  }

  
  my ( @bases ) = @_ ;
  
  start() if @bases ;
  
  my %idx ;
  
  foreach my $bases_i ( @bases ) {
    my $uri = $bases_i ;
    $uri =~ s/\/*$/\// ;
    
    if ( !$INC_LIB{$uri}++ ) {
      push(@INC_LIB , $uri) ;
      push(@IDX_FIND , $uri) ;
                
      foreach my $LIB_VERSIONED_i ( @LIB_VERSIONED ) {
        my $uri_ver = "$uri$LIB_VERSIONED_i" ;
        $uri_ver =~ s/\/*$/\//gs ;
        if ( scalar get_head($uri_ver) && !$INC_LIB{$uri_ver}++ ) {
          push(@INC_LIB , $uri_ver) ;
          push(@IDX_FIND , $uri_ver) ;
        }
      }
    }
  }

}

#########
# START #
#########

sub start {
  if ( !$TMPDIR ) {
    foreach my $STATIC_TMPDIR_i ( @STATIC_TMPDIR ) {
      if ( -d $STATIC_TMPDIR_i ) {
        $TMPDIR = $STATIC_TMPDIR_i ;
        last ;
      }
    }
    
    if ( !$TMPDIR ) {
      my $tmp = tmpdir() ;
      if ( $tmp && -d $tmp ) {
        my @lyb = (a..z,0..9) ;
        my $rand ;
        $rand .= $lyb[ rand(@lyb) ] while length($rand) < 6 ;
        $tmp .= '/' if $tmp !~ /[\\\/]$/ ;
        $tmp .= "libhttp-$rand-tmp" ;
        mkpath($tmp) ;
        if ( -d $tmp ) {
          $TMPDIR = $tmp ;
          push(@TMPDIRS , $TMPDIR) ;
        }
      }
    }
    
    $TMPFILE = "$TMPDIR/libhttp.tmp" ;
  }
  
  my ($hash_hook , $has_lib) ;
  foreach my $INC_i ( @INC ) {
    $hash_hook = 1 if $INC_i == \&hook ;
    $has_lib = 1 if $INC_i eq $TMPDIR ;
  }
  
  push(@INC , \&hook) if !$hash_hook ;
  push(@INC , $TMPDIR) if !$has_lib ;
  
  $SIG{INT} = \&end if !$SIG{INT} ;
  
  return 1 ;
}

###############
# ENABLE_GZIP #
###############

sub enable_gzip {
  return if $ENABLE_GZIP ;
  $ENABLE_GZIP = 2 ;
  
  eval('use Compress::Zlib ;') ;
  
  if ( !$@ && defined &Compress::Zlib::memGunzip ) {
    $ACCEPT_GZIP = 1 ;
    print ">> *** GZIP ON ***\n" if $DEBUG ;
  }
  
  $ENABLE_GZIP = 1 ;
}

############
# FIND_IDX #
############

sub find_idx {
  return if $FIND_IDX ;
  $FIND_IDX = 1 ;

  my %idx ;

  foreach my $IDX_FIND_i ( @IDX_FIND ) {
    my $fl_idx = "${IDX_FIND_i}libhttp.idx" ;
    
    my $fl_idx_local = $fl_idx ;
    $fl_idx_local =~ s/^http:\/\///si ;
    $fl_idx_local =~ s/\./_/gs ;
    $fl_idx_local =~ s/\W/-/gs ;
    $fl_idx_local =~ s/_idx$/.idx/gi ;
    
    $fl_idx_local = "$TMPDIR/$fl_idx_local" ;
    
    my ($idx , $idx_time) ;
    
    my ($fl_size , $mdf_time) = (stat($fl_idx_local))[7,9] ;
    if ( $fl_size ) {
      my ( $code , $modf , $length ) = get_head($fl_idx) ;
      
      if ( $code == 200 && $fl_size == $length && $mdf_time >= $modf ) {
        $idx_time = $mdf_time ;
        open (IDX,$fl_idx_local) ; binmode(IDX) ;
        1 while( read(IDX, $idx , 1024*4 , length($idx) ) ) ;
        close(IDX) ;
      }
    }
    
    if ( !$idx ) {
      my $modf ;
      ( $idx , undef , $modf ) = get_url("$fl_idx.gz" , undef , 1) if $ENABLE_GZIP ;
      ( $idx , undef , $modf ) = get_url($fl_idx      , undef , 1) if !$idx ;

      if ( $idx ) {
        $idx_time = $modf ;
        open (IDX,">$fl_idx_local") ; binmode(IDX) ;
        print IDX $idx ;
        close (IDX) ;
        utime($modf , $modf , $fl_idx_local) ;
      }
    }
    
    $idx{$IDX_FIND_i} = [$idx , $idx_time] if $idx ;
  }
  
  foreach my $Key (sort keys %idx ) {
    $LIBS_IDX{lib}{$Key} = $idx{$Key}[1] ;
    
    my (@files) = split( /(?:"\r\n?|\n)+/s , $idx{$Key}[0] ) ;
    
    foreach my $files_i ( @files ) {
      my ($file , $size) = split(/\s+=\s+/s , $files_i) ;
      $size =~ s/\s+//gs ;
      $LIBS_IDX{"$Key$file"} = $size ;
      $LIBS_IDX{libs}{"$Key$file"} = [$Key , $file] ;
      my ($dir) = ( $file =~ /(.*?)[^\\\/]+$/ ) ;
      $LIBS_IDX{dirs}{"$Key$dir"} = 1 ;
      $LIBS_IDX{path}{$dir}{$Key} = 1 ;
    }
  }
  
  ##print "*** IDX ON!\n" ; <STDIN> ;
    
}

########
# HOOK #
########

sub hook {
  my $code = shift ;
  my $module = shift ;

  unlink_tmpfile() ;
  
##  enable_gzip() ;
##  find_idx() if $ENABLE_GZIP != 2 ;

  find_idx() ;
  enable_gzip() ;
  
  foreach my $INC_LIB_i ( @INC_LIB ) {
    my $uri = $INC_LIB_i . $module ; #URI->new_abs($module , $INC_LIB_i)->canonical ;
    check_module_dep($uri , $module) ;
    my $fl = get_file($uri , $module) ;
    return $fl if ref $fl ;
    last if $fl ;
  }
  
  ## Return undef since tmpdir is at @INC:
  return undef ;
}

####################
# CHECK_MODULE_DEP #
####################

sub check_module_dep {
  my ( $url , $module ) = @_ ;
  
  my $pack = $module ;
  $pack =~ s/[\\\/]/::/gs ;
  $pack =~ s/\.(?:pm|pl|al)$//si ;
  $pack =~ s/::/\//gs ;
  $pack =~ s/[\\\/]*$/\//s ;
  
  my @dep ;
  
  foreach my $INC_LIB_i ( @INC_LIB ) {
    push(@dep , [$INC_LIB_i , $pack]) ;
    push(@dep , [$INC_LIB_i , "auto/$pack"]) ;
  }

  foreach my $dep_i ( @dep ) {
    get_tree(@$dep_i) ;
  }
}

############
# GET_TREE #
############

sub get_tree {
  my ( $inc_base , $dir ) = @_ ;
  
  #print "DEP> $inc_base $dir\n" ;
  
  my @files ;
  
  if ( %LIBS_IDX && $LIBS_IDX{dirs}{"$inc_base$dir"} ) {
    foreach my $Key ( sort keys %LIBS_IDX ) {
      next if !$LIBS_IDX{$Key} || $Key =~ /\.gz$/ || $Key !~ /^\Q$inc_base$dir\E/ ;
      if ( $inc_base =~ /^\Q$LIBS_IDX{libs}{$Key}[0]\E/ && $Key =~ /^\Q$inc_base\E(.*)/ ) {
        push(@files , $1) ;
      }
    }
  }
  
  if ( !@files ) {
    my $has_lib_idx ;
    foreach my $Key ( keys %{ $LIBS_IDX{lib} } ) {
      $has_lib_idx = 1 if $inc_base =~ /^\Q$Key\E/i ;
    }
    @files = get_dir("$inc_base$dir" , $dir) if !$has_lib_idx ;
  }
  
  foreach my $files_i ( @files ) {
    ##print "FL> $inc_base > $files_i\n" ;
    if ( $files_i =~ /\/$/ ) {
      get_tree($inc_base , $files_i) ;
    }
    else {
      get_file("$inc_base$files_i" , $files_i) if $files_i !~ /\.pm$/ ;
    }
  }
  
}

#####################
# GET_DIR_RECURSIVE #
#####################

sub get_dir_recursive {
  my ( $inc_base , $dir ) = @_ ;
  
  my @files = get_dir("$inc_base$dir" , $dir) ;
  
  my @tree ;
  
  foreach my $files_i ( @files ) {
    if ( $files_i =~ /\/$/ ) {
      push(@tree , get_dir_recursive($inc_base , $files_i) ) ;
    }
    else {
      push(@tree , $files_i) ;
    }
  }
  
  return @tree ;
}

###########
# GET_DIR #
###########

sub get_dir {
  my ( $url_base , $pack_base ) = @_ ;
  
  my $dir = get_url($url_base , undef , 1) ;
    
  return if !$dir ;
  
  my @files = parse_dir($dir) ;
  
  foreach my $files_i ( @files ) {
    $files_i = "$pack_base$files_i" ;
  }

  return @files ;
}

#############
# PARSE_DIR #
#############

sub parse_dir {
  my ( $dir ) = @_ ;
  
  my (@links) = ( $dir =~ /<a\s+[^>]*?href=['"]([^'"]+)['"]>.*?<\/a>/gsi );
  
  my @files ;
  foreach my $links_i ( @links ) {
    next if $links_i !~ /(?:\w|\/)$/ || $links_i =~ /^(?:mailto:|\?|\/)/ ;
    push(@files , $links_i) ;
  }
  
  return @files ;
}

#################
# GET_MODULE_FH #
#################

sub get_module_fh {
  my ( $uri , $module ) = @_ ;
  
  my $new_file ;
  
  $new_file = get_file($uri , $module) || return ;
  
  open (my $fh , $new_file) ; binmode($fh) ;
  return $fh ;
}

############
# GET_FILE #
############

sub get_file {
  my ( $uri , $module ) = @_ ;
  
  return if (time - $URLS{$uri}{t}) < URI_TIMEOUT && $URLS{$uri}{status} == 404 ;
  
  my $new_file = $TMPDIR =~ /[\\\/]$/ ? "$TMPDIR$module" : "$TMPDIR/$module" ;
  my $file_dir = $new_file ;
  $file_dir =~ s/[^\\\/]+$//gs ;
  mkpath($file_dir) ;

  if ( -s $new_file && $LIBS_IDX{$uri} ) {
    my ($fl_size , $mdf_time) = (stat($new_file))[7,9] ;
    my $idx_time ;
    foreach my $Key ( sort keys %{ $LIBS_IDX{lib} } ) {
      $idx_time = $LIBS_IDX{lib}{$Key} if $uri =~ /^\Q$Key\E/i ;
    }

    return $new_file if $LIBS_IDX{$uri} == $fl_size && $idx_time ;
    
    my ( $code , $modf , $length ) = get_head($uri) ;
    
    return $new_file if $code == 200 && $fl_size == $length && $mdf_time >= $modf ;
    return if $code != 200 ;
  }
  
  my ($data , $code , $fl_time) ;

  if ( $ACCEPT_GZIP && $uri !~ /(?:\.gz|\/)$/i ) {
    my $uri_gz = "$uri.gz" ; 
    if ( %LIBS_IDX && $LIBS_IDX{$uri_gz} ) {
      ($data , $code , $fl_time) = get_url($uri_gz) ;
      $data = '' if $code != 200 ;
    }
  }

  if ( $data eq '' && %LIBS_IDX ) {
    my $has_lib_idx ;
    foreach my $Key ( keys %{ $LIBS_IDX{lib} } ) {
      $has_lib_idx = 1 if $uri =~ /^\Q$Key\E/i ;
    }
    return if $has_lib_idx && !$LIBS_IDX{$uri} ;
  }

  unlink($new_file) ;

  ($data , $code , $fl_time) = get_url($uri) if $data eq '' ;

  $URLS{$uri}{t} = time ;
  if ( $data eq '' || $code != 200 ) {
    $URLS{$uri}{status} = 404 ;
    return ;
  }
  else {
    $URLS{$uri}{status} = 200 ;
  }
  
  if ( is_file_hidden(undef , $data) ) {
    $data =~ s/(?:\r\n?|\n)__END__(?:\r\n?|\n).*?$//s ;
    $data =~ s/(?:\r\n?|\n)__DATA__(?:\r\n?|\n).*?$//s ;
  
    open (my $fh,">$TMPFILE") ; binmode($fh) ;
    print $fh $data ;
    print $fh "\n\n use lib::http 'unlink_tmpfile' ;\n\n" ;
    close ($fh) ;
    
    open (TMPFILE,$TMPFILE) ; binmode(TMPFILE) ;
    return \*TMPFILE ;
  }
  
  open (my $fh,">$new_file") ; binmode($fh) ;
  print $fh $data ;
  close ($fh) ;
  
  utime($fl_time , $fl_time , $new_file) ;

  return if !-s $new_file ;
  
  return $new_file ;
}

############
# GET_HEAD #
############

sub get_head {
  return if %LIBS_IDX && $LIBS_IDX{lib}{$LIBS_IDX{libs}{$_[0]}[0]} && !$LIBS_IDX{$_[0]} ;
  return get_url($_[0],1,1) ;
}

###########
# GET_URL #
###########

sub get_url {
  my ( $url , $head , $force ) = @_ ;
  
  unlink_tmpfile() ;
  
  return if !$force && (time - $URLS{$url}{t}) < URI_TIMEOUT && ($URLS{$url}{status} == 404 || $url =~ /\/$/) ;
  
  #print ">> $url\n" if !$head ;

  my ( $host , $port , $path ) = ( $url =~ m,^http://([^/:]+)(?::(\d+))?(/\S*)?$, ) ;
  if ($host !~ /\w/s) { return ;}
  
  if ($port eq '' || $port == 0 || $port !~ /^[\d]+$/) { $port = 80 ;}
  if ($path eq '') { $path = '/' ;}
  
  my $socket ;
  
  for(1..3) {
    $socket = new_socket($host , $port) ;
    last if $socket ;
  }

  my $proto = $head ? 'HEAD' : 'GET' ;

  my $netloc = $host ;
  $netloc .= ":$port" if $port != 80 ;

  print $socket join("\015\012",
  "$proto $path HTTP/1.0" ,
  "Host: $netloc" ,
  ($ACCEPT_GZIP ? 'Accept-Encoding: gzip' : () ) ,
  "User-Agent: $AGENT" ,
  'Connection: close' ,
  '',''
  ) ;
  
  my $buffer ;
  while( read($socket, $buffer , 1024*4 , length($buffer) ) ) {
    #$buffer =~ s/\r\n?/\n/gs ;
    #print "$buffer\n" ;
  } ;
  
  close($socket) ;
  
  #print "$buffer\n" ;
  
  my ($headers , $content) = split(/(?:\015\012|\r\n){2}/ , $buffer , 2) ;

  ++$STATUS{loads} ;
  $STATUS{bandwidth} += length($buffer) ;
  
  if ( $DEBUG ) {
    print ">> $url\n" ;
    print ">> LOADS> $STATUS{loads}\n" ;
    print ">> BANDWIDTH> ". ( int($STATUS{bandwidth}/1024) ) ."Kb\n" ;
  }
  
  $buffer = undef ;
  
  #print "$headers\n" ;
    
  my ($code) = ( $headers =~ /HTTP[^\s]*[\s]+([\d]+)[\s]+[\w]+?/gsi ) ;
  my ($type) = ( $headers =~ /Content-Type\:?[\s]+([^\n\r]*)[\n\r]?/gsi ) ;
  my ($length) = ( $headers =~ /Content-Length\:?[\s]+([^\n\r]*)[\n\r]?/gsi ) ;
  my ($modf) = ( $headers =~ /Last-Modified\:?[\s]+([^\n\r]*)[\n\r]?/gsi ) ;
  
  if ($modf =~ /,\s+\d+[\s-]+\w+[\s-]+\d+\s+\d+[:-]\d+[:-]\d+/i) {
    my ($day,$mon,$year,$hour,$min,$sec) = ($modf =~ /,\s+(\d+)[\s-]+(\w+)+[\s-]+(\d+)\s+(\d+)[:-](\d+)[:-](\d+)/i ) ;
    $mon = $MONTHS_EG{lc($mon)} if $mon !~ /^\d+$/ ;
    $modf = timelocal($year,$mon,$day,$hour,$min,$sec) ;
  } else { $modf = '' ;}
  
  if ( $ACCEPT_GZIP && ($headers =~ /Content-Encoding:\s*gzip/si || $path =~ /\.gz$/i) ) {
    $content = Compress::Zlib::memGunzip($content) ;
  }
  
  $URLS{$url}{t} = time ;
  $URLS{$url}{status} = $code ;
  
  $content = '' if $code != 200 ;
  
  return ( ($head ? () : $content) , $code , $modf , $length , $type ) if wantarray ;

  return if $code != 200 ;
  
  return $code if $head ;
  return $content ;
}

##############
# NEW_SOCKET #
##############

sub new_socket {
  my ( $host , $port ) = @_ ;

  my $iaddr = inet_aton($host) || return ;
  my $paddr = sockaddr_in($port, $iaddr) || return ;
  my $proto = getprotobyname('tcp') || return ;
  
  socket(SOCK, PF_INET, SOCK_STREAM, $proto) || return ;
  
  connect(SOCK, $paddr) || return ;
  
  my $sel = select(SOCK) ; $|=1 ; select($sel) ;

  return \*SOCK ;
}

#############
# TIMELOCAL #
#############

sub timelocal {
  my ( $year,$mon,$day,$hour,$min,$sec ) = @_ ; 

  my $year_0 = (gmtime(1))[5] + 1900 ;
  
  my ($now_sec,$now_min,$now_hour,$now_mday,$now_mon,$now_year) = gmtime( time ) ;

  if (!$year || $year eq '*' || $year < $year_0) { $year = $now_year ;}

  my $year_bisexto = 0 ;
  if ( is_leap_year($year) ) { $year_bisexto = 1 ;}

  if (!$mon || $mon eq '*') { $mon = $now_mon }
  elsif ($mon < 1 || $mon > 12 ) { return }

  elsif (!$day || $day eq '*') { $day = $now_mday }
  elsif ($day < 1 || $day > 31 ) { return }
  elsif ($mon == 2 && $day > 28) {
    $day = 28 if !check_date($year,$mon,$day) ;
  }
  elsif ($day > check_date($mon) ) { return }

  if    ($hour eq '') { $hour = 0 }
  elsif ($hour eq '*') { $hour = $now_hour }
  elsif ($hour == 24) { $hour = 0 }
  elsif ($hour < 0 || $hour > 24 ) { return }
  
  if    ($min eq '') { $min = 0 }
  elsif ($min eq '*') { $min = $now_min }
  elsif ($min == 60) { $min = 59 }
  elsif ($min < 0 || $min > 60 ) { return }
  
  if    ($sec eq '') { $sec = 0 }
  elsif ($sec eq '*') { $sec = $now_sec }
  elsif ($sec == 60) { $sec = 59 }
  elsif ($sec < 0 || $sec > 60 ) { return }

  my $timelocal ;

  my $time_day = 60*60*24 ;
  my $time_year = $time_day * 365 ;
      
  for my $y ($year_0..($year-1)) {
    $timelocal += $time_year ;
    if ( is_leap_year($y) ) { $timelocal += $time_day ;}
  }
  
  for my $m (1..($mon-1)) {
    my $month_days = &check_date($m) ;
    $timelocal += $month_days * $time_day ;
  }

  if ($year_bisexto == 1 && $mon > 2) { $timelocal += $time_day ;}
    
  $timelocal += $time_day * ($day-1) ;
  
  $timelocal += 60*60 * $hour ;
  $timelocal += 60 * $min ;
  $timelocal += $sec ;
    
  return $timelocal ;
}

################
# IS_LEAP_YEAR #
################

sub is_leap_year { 
  my ( $year ) = @_ ;

  if    ($year == 0) { return 1 ;}
  elsif (($year % 4000) == 0) { return 0 ;}
  elsif (($year % 400) == 0) { return 1 ;}
  elsif (($year % 100) == 0) { return 0 ;}
  elsif (($year % 4) == 0) { return 1 ;}
  return 0 ;
}

##############
# CHECK_DATE #
##############

sub check_date { 
  shift if $_[0] !~ /^\d+$/ ;

  my ( $year , $month , $day ) ;
  
  if ($#_ == 2) { ( $year , $month , $day ) = @_ ;}
  if ($#_ == 1) { ( $month , $day ) = @_ ;}
  if ($#_ == 0) { ( $month ) = @_ ;}
  
  if ($#_ > 0) {
    if ($year eq '')  { $year = 1970 }
    if ($month eq '') { $month = 1 }
    if ($day eq '')   { $day = 1 }
    
    my @months_days = @MONTHS_DAYS ;
    
    if ( is_leap_year($year) ) { $months_days[2] = 29 ;}
    
    if ($day <= $months_days[$month]) { return 1 ;}
    else { return ;}
  }
  elsif ($#_ == 0) {
    if ($month eq '') { return ; }
    return $MONTHS_DAYS[$month] ;
  }
  
  return undef ;
}

##################
# IS_FILE_HIDDEN #
##################

sub is_file_hidden {
  my $file = shift ;
  
  my $data_ref = \$_[0] ;
  
  if ( -e $file ) {
    my $buffer ;
    open (FLH,$file) ;
    1 while( read(FLH, $buffer , 1024*8 , length($buffer) ) ) ;
    close (FLH) ;
    $data_ref = \$buffer ;
  }
  
  if ( $$data_ref =~ /(?:^|\r\n?|\n)[ \t]*#[ \t#]*lib:*http[ \t]*=>[ \t]*hidden_?file\s/si ) {
    return 1 ;
  }

  return ;
}

##################
# UNLINK_TMPFILE #
##################

sub unlink_tmpfile {
  close TMPFILE ;
  
  if ( $_[0] ) {
    open (TMPFILE,">$TMPFILE") ;
    print TMPFILE "\n" ;
    close (TMPFILE) ;
  }
  
  unlink $TMPFILE ;
  ##print "UNLINK TMPFILE: $TMPFILE [". $INC{'BotCore.pm'} ."]\n" ;
  ##<STDIN>
}

##########
# TMPDIR #
##########

sub tmpdir {

  my @dir_list = (
   @ENV{qw(TMPDIR TEMP TMP)},
   qw(
    C:/temp
    C:/tmp
    SYS:/temp
    SYS:/tmp
    /tmp
    /
   ),
  ) ;
  
  my $tmpdir ;
  foreach my $dir_list_i ( @dir_list ) {
    next if !$dir_list_i ;
    if ( -d $dir_list_i && -w $dir_list_i && -r $dir_list_i ) {
      $tmpdir = $dir_list_i ;
      last ;
    }
  }
  
  if ( !$tmpdir && -w '.' ) {
    my @lyb = (a..z,0..9) ;
    my $rand ;
    $rand .= $lyb[ rand(@lyb) ] while length($rand) < 6 ;
    my $dir = "./$rand-tmp" ;
    mkdir($dir , 0777) ;
    $tmpdir = $dir if -d $dir && -w $dir ;
  }
  
  return $tmpdir ;
}

##########
# MKPATH #
##########

sub mkpath {
  my ( $path ) = @_ ;
  
  my @path = split(/[\\\/]/ , $path) ;
  
  my $path ;
  
  if ( $path[0] =~ /^\w+:$/ ) {
    $path .= shift(@path) . '/' ;
  }
  
  foreach my $path_i ( @path ) {
    $path .= $path_i . '/' ;
    next if -e $path ;
    mkdir($path , 0777) ;
  }
  
  return 1 ;
}

##########
# RMTREE #
##########

sub rmtree {
  my ( $path ) = @_ ;
  
  my @subdirs = scandir($path) ;
  
  my $main = $subdirs[0] ;
  
  foreach my $subdirs_i ( reverse @subdirs ) {
    opendir (my $DH, $subdirs_i);

    while (my $filename = readdir $DH) {
      if ($filename ne '.' && $filename ne '..') {
        my $file = "$subdirs_i/$filename" ;
        next if -d $file ;
        unlink($file) ;
      }
    }
    
    closedir ($DH) ;

    rmdir($subdirs_i) ;
  }

  return 1 ;
}

#######
# END #
#######

sub end {
  unlink_tmpfile(1) ;
  
  foreach my $TMPDIRS_i ( @TMPDIRS ) {
    print ">> UNLINK> $TMPDIRS_i\n" if $DEBUG ;
    rmtree($TMPDIRS_i) ;
  }

  exit ;
}

sub END { &end ;}

#######
# END #
#######

1;

__END__

=head1 NAME

lib::http - Uses a Perl libray diretory over the internet using the HTTP protocol.

=head1 DESCRIPTION

This module enables the use of a Perl libray diretory over the internet using
the HTTP protocol.

Also you can use libhttp-perl, that is a L<TinyPerl> (I<http://tinyperl.sf.net>)
modified, that doesn't have any library, only the basics to load I<lib::http>,
than the rest of the library you load over the internet. By default a library
at I<http://tinyperl.sf.net/libhttp/> is used, so you can have a full Perl working
without install a full Perl.

=head1 USAGE

You can use this module from your code:

  #!/usr/bin/perl

  use lib::http 'http://tinyperl.sf.net/libhttp/perl-lib-5.8.6-Win32' ;
  
  ## Loading XML::Smart over the internet! ;-P
  use XML::Smart ;
  
  my $xml = XML::Smart->new() ;
  ...
  
or from a modified Perl, I<libhttp-perl>, that is distributed with the sources
of this module and should be at I<./libhttp-perl>:

  $> libhttp-perl anyscript.pl

To define what libraries URI I<libhttp-perl> will use define them in the file
libhttp.conf that should be in the same path of the binary of I<libhttp-perl>.
Here's an example:

  http://192.168.100.196/gmpassos/perl-5.8.6-win32-lib/
  http://192.168.100.196/gmpassos/my-modules/

=head1 Setting Up the Library in the Web Server

I<lib::http> works with any simple HTTP Server. To setup a library in the web server
just copy all the library files of an installed Perl to a directory that can be
accessed from the Web Server. Also you can link /usr/loca/lib/perl5/ to a directory
that the Web Server can show.

B<To make the usage of the remote library faster you can use the I<libhttp> script
that will scan the library, create an index file and create compressed versions
of the files. So, with the index you will make less calls to the server and the
compressed files will save bandwidth.>

Preparing the library:

  $> libhttp /www/path/to/perl-lib-os-xxx/

Cleanning the files added in the prepare stage (undo the command above):

  $> libhttp /www/path/to/perl-lib-os-xxx/ clean

=head1 Caching Library Files

By default I<lib::http> will save the loaded files from the internet in a cache
directory that will work as a normal Perl library.

The location of the cache directory will be a temporary directory in the default
temporary directory of the system. If a I<./libhttp> directory exists in the current
path it will be used as a static path that can be reused after many executions. By
default the temporary directory will be cleanned after each execution.

=head1 Hidding Files

To hide files from the cache, in other words, to not store fisically a file, you can
use a I<"macro"> that will force to load the file only in the memory, so, you can
have restricted modules loaded from the internet without store them in the local
host:

  package TopSecret ;
  
  ## lib::http => hidden_file
  
  $var = 123 ;
  
  1;
  
So, if I<"lib:http => hidden_file"> is found as a commnet in your file, the file
will be loaded directly from the memory.

=head1 SEE ALSO

=over 4

=item TinyPerl (L<http://tinyperl.sf.net>).

=back

L<LibZip>.

=head1 AUTHOR

Graciliano M. P. <gmpassos@cpan.org>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#
# $Id$
#
# Unicode::Map 0.112
#
# Documentation at end of file.
#
# Copyright (C) 1998, 1999, 2000 Martin Schwartz. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Contact: Martin Schwartz <martin@nacho.de>
#

package Unicode::Map;
use strict;
use vars qw($VERSION $WARNINGS @ISA $DEBUG);
use Carp;

$VERSION='0.112';   # Michael Changes it to 0.112

require DynaLoader; @ISA=qw(DynaLoader);
bootstrap Unicode::Map $VERSION;

sub NOISE   () { 1 }

sub MAGIC   () { 0xB827 } # magic word

sub M_END   () { 0 }      # end
                          
sub M_INF   () { 1 }      # infinite subsequent entries (default)
sub M_BYTE  () { 2 }      # 1..255 subsequent entries 
                 
sub M_VER   () { 4 }      # (Internal) file format revision.
            
sub M_AKV   () { 6 }      # key1, val1, key2, val2, ... (default)
sub M_AKAV  () { 7 }      # key1, key2, ..., val1, val2, ...
sub M_PKV   () { 8 }      # partial key value mappings
            
sub M_CKn   () { 10 }     # compress keys not
sub M_CK    () { 11 }     # compress keys (default)
            
sub M_CVn   () { 13 }     # compress values not
sub M_CV    () { 14 }     # compress values (default)

##
## The next entries are for info, only. They are stored as unicode strings.
##

sub I_NAME  () { 20 }     # Character Set Name
sub I_ALIAS () { 21 }     # Character Set alias name (several entries allowed)
sub I_VER   () { 22 }     # Mapfile revision
sub I_AUTH  () { 23 }     # Mapfile authRess
sub I_INFO  () { 24 }     # Some userEss definable string

sub WARN_DEFAULT ()       { 0x0000 };
sub WARN_DEPRECATION ()   { 0x1000 };
sub WARN_COMPATIBILITY () { 0x2000 };

##
## --- Init ---------------------------------------------------------------
##

my $MAP_Pathname = 'Unicode/Map';
my $MAP_Path     = $INC{"Unicode/Map.pm"}; $MAP_Path=~s/\.pm//;
die "Can't find base directory of Unicode::Map!" unless $MAP_Path;

my @order = (
   { 1=>"C", 2=>"n", 3=>"N", 4=>"N" },  # standard ("Network order")
   { 1=>"C", 2=>"v", 3=>"V", 4=>"V" },   # reverse  ("Vax order")
);

my %registry = ();
my %mappings = ();
my $registry_loaded = 0;

$WARNINGS = WARN_DEFAULT;
_init_registry();

##
## --- public conversion methods ------------------------------------------
##

# For compatibility with Unicode::Map8
sub to8 { goto &from_unicode }

sub from_unicode {
   my $S = shift;
   if ( $#_==0 ) {
      $S -> _to ("TO_CUS", $S->_csid(), @_);
   } else {
      _deprecated ( );
      _incompatible ( );
      $S -> _to ("TO_CUS", @_);
   }
}

sub new {
#
# $ref||undef = Unicode::Map->new("ISO-8859-1")
#
   # Note: usage like below is deprecated. It is not compatible with
   # Unicode::Map8. Support will vanish soon! martin [2000-Jun-19]
   #
   # I<$Map> = new Unicode::Map;
   # 
   # I<$utf16> = I<$Map> -> to_unicode ("ISO-8859-1", "Hello world!");
   #   => $_16bit == "\0H\0e\0l\0l\0o\0 \0w\0o\0r\0l\0d\0!"
   # 
   # I<$locale> = I<$Map> -> from_unicode ("ISO-8859-7", I<$_16bit>);
   #   => $_8bit == "Hello world!"
   my ($proto, $parH) = @_;
   my $S = bless ({}, ref($proto) || $proto);
   $S -> _noise ( NOISE );
   return unless $S -> _load_registry ( );
   if (!$parH) {
      _deprecated ( );
   } else {
      my $csid;
      if (!ref($parH)) {
         # Compatible to Unicode::Map8  
         $csid = $parH;
      } else {
         _deprecated ( );
         _incompatible ( );
         if ( $parH->{"STARTUP"} ) {
            $S -> Startup ( $parH->{"STARTUP"} );
         }
         $csid = $parH -> { "ID" };
      }
      if ( $csid ) {
         return 0 unless $S -> _csid ( $S->_real_id($csid) )
      }
   }
   $S;
}

# Deprecated!
sub noise { 
    _deprecated ( );
    _incompatible ( );
    # Defines the verbosity of messages to user sent via I<$Startup>. Can be no
    # messages at all (n=0), some information (n=1) or some more information
    # (n=3). Default is n=1.
    # I<$Map> -> noise (I<$n>)
    _noise ( @_ );
}
sub _noise { shift->_member("P_NOISE", @_) }

#
# Unicode::Map.xs -> reverse_unicode 
#
# Usage is deprecated! Use Unicode::String::byteswap instead!
#
# I<$string> = I<$Map> -> reverse_unicode (I<$string>)
#
# One Unicode character, precise one utf16 character, consists of two
# bytes. Therefore it is important, in which order these bytes are stored.
# As far as I could figure out, Unicode characters are assumed to be in
# "Network order" (0x1234 => 0x12, 0x34). Alas, many PC Windows documents
# store Unicode characters internally in "Vax order" (0x1234 => 0x34, 0x12).
# With this method you can convert "Vax mode" -> "Network mode" and vice versa.
# 
# reverse_unicode changes the original variable if in a void context. If
# in scalar or list context returns a new created string.
# 
sub reverse_unicode {
    _deprecated ( "see: Unicode::String::byteswap" );
    _incompatible ( );
    &_reverse_unicode;
}

# For compatibility with Unicode::Map8
sub to16 { goto &to_unicode }

sub to_unicode {
   my $S = shift;
   if ( $#_==0 ) {
      $S -> _to ("TO_UNI", $S->_csid(), @_);
   } else {
      _deprecated ( );
      _incompatible ( );
      $S -> _to ("TO_UNI", @_);
   }
}

## 
## --- public maintainance methods ----------------------------------------
##

sub alias { 
   _incompatible ( );
   @{$registry{$_[1]} -> {"ALIAS"}};
}

sub dest {
   _deprecated ( "'dest' is now 'mapping'" );
   goto &mapping;
}

sub mapping {
   _incompatible ( );
   return shift -> _mapping ( shift() );
}

sub id {
   _incompatible ( );
   shift->_real_id(shift());
}

sub ids { 
   _incompatible ( );
   (sort {$a cmp $b} grep {!/^GENERIC$/i} keys %registry);
}

sub info  { 
   _incompatible ( );
   $registry{$_[1]} -> {"INFO"};
}

sub read_text_mapping {
   _incompatible ( );
   my ($S, $csid, $textpath, $style) = @_;
   return 0 if !($csid = $S->id($csid));
   $S->_msg("reading") if $S->_noise>0;
   $S->_read_text_mapping($csid, $textpath, $style);
}

sub src { 
   _incompatible ( );
   $registry{$_[1]} -> {"SRC"};
}

sub srcURL {
   _incompatible ( );
   $registry{$_[1]} -> {"SRCURL"};
}

sub style { 
   _incompatible ( );
   $registry{$_[1]} -> {"STYLE"};
}

sub write_binary_mapping {
   _incompatible ( );
   my ($S, $csid, $binpath) = @_;
   return 0 unless ( $csid = $S->id($csid) ); 
   $binpath = $S->_mapping($csid) if !$binpath; 
   return 0 unless $binpath;
   $S->_msg("writing") if $S->_noise>0;
   $S->_write_IMap_to_binary($csid, $binpath);
}

##
## --- Application program interface --------------------------------------
##

sub Startup { 
   _deprecated ( "module Startup shouldn't be used any longer" );
   shift->_member("STARTUP", @_);
}

##
## --- private methods ----------------------------------------------------
##

sub _member    { my $S=shift; my $n=shift if @_; $S->{$n}=shift if @_; $S->{$n}}

sub _csid      { shift->_member("P_CSID", @_) }
sub _error     { my $S=shift; $S->Startup ? $S->Startup->error(@_) : 0 }
sub _msg       { my $S=shift; $S->Startup ? $S->Startup->msg(@_) : 0 }
sub _msg_fin   { my $S=shift; $S->Startup ? $S->Startup->msg_finish(@_) : 0 }
sub _IMap      { shift->_member("I", @_) }

sub _mapping   { $registry{$_[1]} -> {"MAP"} }

sub _dump {
   my $S = shift;
   print "Dumping Mapping $S:\n";
   if ($S->Startup) {
      print "   - Startup object: ".$S->Startup."\n";
   } else {
      print "   - no Startup object\n";
   } 
   if (%registry) {
      print "   - Mapping: " . (keys %registry) . " entries defined.\n";
   } else {
      print "   - No mappings!\n";
   }
   if ($S->_IMap) {
      print "   - IMap:\n";
      my ($k,$v); while(($k,$v)=each %{$S->_IMap}) {
         printf "      %10s => %s\n", $k, $v;
      }
   }
   if (%mappings) {
      print "   - Mappings:\n";
      my ($k,$v); while(($k,$v)=each %mappings) {
         printf "      %10s => %s\n", $k, $v;
      }
   }
1}

sub _real_id {
   my ($S, $csid) = @_;
   if (!%registry) {
      return $S->_error("No mapping definitions!\n");
   }
   return $csid if defined $registry{$csid};
   my $id=""; 
   my (@tmp, $k, $v);
   while (($k,$v) = each %registry) {
      next if !$k || !$v;
      if ($csid =~ /^$k$/i) {
         $id=$k; last;
      } else {
         for (@{$v->{"ALIAS"}}) {
            if (/^$csid$/i) {
               $id=$k; last;
            }
         }
      }
   }
   while (($k, $v) = each %registry) {}
   return $S->_error("Character Set $csid not defined!") if !$id;
   $id;
}

sub _to {
#
# 1||0      = $S -> _to ("TO_UNI"||"TO_CUS", $csid, $src||$srcR, $destR, $o, $l)
# $text||"" = $S -> _to ("TO_UNI"||"TO_CUS", $csid, $src||$srcR, "",     $o, $l)
#
   my ($S, $to, $csid, $srcR, $destR, $o, $l) = @_;
   return 0 if !($csid = $S->_real_id($csid));
   return 0 if !$S->_load_TMap($csid);

   my ($cs1, $n1, $cs2, $n2, $tmp) = (0, 0, 0, 0, "");
   my (@M, @C);

   my $destbuf = ""; 
   my $srcbuf  = ref($srcR) ? $$srcR : $srcR;

   my $C = $mappings{$csid}->{$to};

   if ($S->_noise>2) {
      $S->_msg("mapping ".(($to=~/^to_unicode$/i) ? "to Unicode" : "to $csid"));
   }
   my ($csa,$na,$csb,$nb);
   my @n = sort { 
      # Sort the partial mappings according to their left side's total
      # length, descending order.
      ($csa, $na) = split/,/,$a;
      ($csb, $nb) = split/,/,$b;
      $csb*$nb <=> $csa*$na
   } keys %$C;
   if ($#n==0) {
      ($cs1, $n1, $cs2, $n2) = split /,/,$n[0];
      $destbuf = $S->_map_hash($srcbuf, 
         $C->{$n[0]}, 
         $n1*$cs1,
         $o||undef, $l||undef
      );
   } else {
      $destbuf = $S->_map_hashlist($srcbuf, 
         [map $C->{$_}, @n],
         [map {($cs1,$n1)=split/,/; int($cs1*$n1)} @n],
         $o, $l
      );
   }
   if ($destR) {
      $$destR=$destbuf; 1;
   } else {
      $destbuf;
   }
}

sub _init_registry {
   %registry = ();
   $registry_loaded = 0;
   _add_registry_entry("GENERIC", "GENERIC", "GENERIC");
1}

sub _unload_registry { 
   _init_registry;
}

##
## --- Binary to TMap -----------------------------------------------------
##

#  TMap structure:
#  
#  %T = (
#     $CSID => {
#        TO_CUS  => {
#           "$cs_a1,$n_a1,$cs_a2,$n_a2" => {
#              "str_a1_1" => "str_a2_1", ... , 
#              "str_a1_n" => "str_a2_n",
#           }, ... ,
#           "$cs_x1,$n_x1,$cs_x2,$n_x2" => {
#              "str_x1_1" => "str_x2_1", ... , 
#              "str_x1_n" => "str_x2_n",
#           }
#        }
#        TO_UNI => {
#           "$cs_a2,$n_a2,$cs_a1,$n_a1" => {
#              "str_a2_1" => "str_a1_1", ... ,
#              "str_a2_n" => "str_a1_n",
#           }, ... ,
#           "$csx2,$nx2,$csx1,$nx1" => {
#              "str_x2_1" => "str_x1_1", ... ,
#              "str_x2_n" => "str_x1_n",
#           }
#        }
#     }
#  );

sub _load_TMap {
   my ($S, $csid) = @_;
   return 1 if $mappings{$csid};
   return 0 if !$S->_read_binary_to_TMap($csid);
1}

sub _read_binary_to_TMap {
   my ($S, $csid) = @_;
   my %U = (); 
   my %C = ();
   my $buf = "";

   #
   # read file
   #
   my $file = $S->_mapping($csid);
   return $S->_error ("Cannot find mapping file for id \"$csid\"!")
      unless -f $file
   ;
   return $S->_error ("Cannot open binary mapping \"$file\"!") 
      if !open(MAP1, $file)
   ;
   binmode MAP1;
   my $size = read MAP1, $buf, -s $file;
   close MAP1;
   return $S->_error ("Error while reading mapping \"$file\"!")
      if ($size != -s $file)
   ;

   if ($size>0x1000) {
      $S->_msg("loading mapfile \"$csid\"") if $S->_noise>0;
   } else {
      $S->_msg("loading mapfile \"$csid\"") if $S->_noise>2;
   }

   return $S->_error ("Error in binary map file!\n")
      if !$S->_read_binary_mapping($buf, 0, \%U, \%C)
   ;

   if ($size>0x1000) {
      $S->_msg("loaded") if $S->_noise>0;
   } else {
      $S->_msg("loaded") if $S->_noise>2;
   }

   $mappings{$csid} = {
      TO_CUS  => \%C,
      TO_UNI => \%U
   };
   # $S->_dump_TMap ($mappings{$csid});
1}

sub _dump_TMap {
   my ($S, $TMap) = @_;
   print "\nDumping TMap $TMap\n";
   my ($pat1, $pat2, $up1, $up2);
   foreach (keys %$TMap) {
      my $subTMap = $TMap->{$_};
      print "SubTMap $_:\n";
      my @n = sort {(split/,/,$b)[0] <=> (split/,/,$a)[0]} keys %$subTMap;
      for (@n) {
         my ($cs1, $n1, $cs2, $n2) = split /,/;
         print "   Submapping $cs1 bytes ($n1 times) => "
            ."$cs2 bytes ($n2 times):\n"
         ;
         my $s="";
         $pat1 = ("%0".($cs1*2)."x ") x $n1;
         $pat2 = ("%0".($cs2*2)."x ") x $n2;
         $up1 = ($order[0]->{$cs1}).$n1;
         $up2 = ($order[0]->{$cs2}).$n2;
         my $subsubTMap = $subTMap->{$_};
         for (sort keys %$subsubTMap) {
           printf "      $pat1 => $pat2\n",
              unpack($up1, $_),
              unpack($up2, $subsubTMap->{$_})
           ;
         }
      }
   }
   print "Dumping done.\n\n";
}

##
## --- Text (Unicode, Keld) to IMap ---------------------------------------
##

sub _read_text_mapping {
   my ($S, $id, $path, $style) = @_;
   $S->_IMap({}) if !defined $S->_IMap;
   return $S->_error("Bad charset id") if (!$id || !$registry{$id});
   if ($style =~ /^keld$/i) {
      $S->_read_text_keld_to_IMap($id, $path);
   } elsif ($style =~ /^reverse$/i) {
      $S->_read_text_unicode_to_IMap($id, $path, 2, 1);
   } elsif (!$style || $style=~/^unicode$/i) {
      $S->_read_text_unicode_to_IMap($id, $path, 1, 2);
   } else {
      my ($vendor, $unicode) = ($style =~ /^\s*(\d+)\s+(\d+)/);
      if ($vendor && $unicode) {
         $S->_read_text_unicode_to_IMap($id, $path, $vendor, $unicode);
      } else {
         return $S->_error("Unknown style '$style'");
      }
   }
}

sub _read_text_keld_to_IMap {
   my ($S, $csid, $path) = @_;
   my %U = (); 
   my ($k, $v);
   my $com = ""; my $esc = "";
   return 0 unless my @file = $S -> readTextFile ( $path );
   while ( @file ) {
      $_ = shift ( @file );
      s/$com.*// if $com;
      s/^\s+//; s/\s+$//; next if !$_; 
      last if /^CHARMAP/i;
      ($k, $v) = split /\s+/,$_,2;
      if ($k =~ /<comment_char>/i) { $com = $v; next }
      if ($k =~ /<escape_char>/i)  { $esc = $v; next }
   }
   my (@l, $f, $t);
   my $escx = $esc."x";
   while ( @file ) {
      $_ = shift ( @file );
      s/$com.*// if $com;
      next if ! /$escx([^\s]+)\s+<U([^>]+)/;
      $U{length($1)*4}->{hex($1)} = hex($2);
   }
   # $S->_dump_IMap(\%U);
   $S->_IMap->{$csid} = \%U;
1}

sub readTextFile {
    my ( $S, $filePath ) = @_;
    local $/;
    return $S->_error ( "No text file specified!" ) unless $filePath;
    return $S->_error ( "Can't find text file \"$filePath\"!" )
        unless -f $filePath
    ;
    return $S->_error ( "Cannot open text file \"$filePath\"!" )
        unless open ( FILE, $filePath )
    ;
    undef $/; my $file = <FILE>;
    close FILE or warn ( "Oops: can't close file '$filePath'! ($!)" );
    return map "$_\n", split /\r\n|\r|\n/, $file;
}

sub _read_text_unicode_to_IMap {
#
# Converts map files like created by Unicode Inc. to IMap
#
   no strict;
   my ($S, $csid, $file, $row_vendor, $row_unicode) = @_;
   my %U = (); 

   return 0 unless my @file = $S -> readTextFile ( $file );

   my (@l, $f, $t);
   my $hex = '(?:0x)?([^\s]+)\s+';
   my $hexgap = '(?:0x)?[^\s]+\s+';
   my ($min, $max) = ($row_vendor, $row_unicode);
   ($min, $max) = ($row_unicode, $row_vendor) if $row_unicode<$row_vendor;
   my $gap1 = $hexgap x ($min - 1);
   my $gap2 = $hexgap x ($max - $min - 1);
   if ($row_vendor > $row_unicode) {
      $row_unicode=1; $row_vendor=2;
   } else {
      $row_unicode=2; $row_vendor=1;
   }

   # Info fields in comments: (at this release still unused)
   my $Name = "";
   my $Unicode_version = "";
   my $Table_version = "";
   my $Date = "";
   my $Authresses = "";

   my $comment_info = 1; my $comment_authress=0;
   while( @file ) {
      $_ = shift ( @file );
      if ($comment_info && !/#/) {
         $comment_info = 0;
      }
      if ($comment_info) {
         if ($comment_authress && (/^#\s*$/ || /^#[^:]:/)) {
            $comment_authress = 0;
         }
         if (/#\s*name\S*:\s*(.*$)/i) {
            $Name = $1;
         }
         if (/#\s*unicode\s*version\S*:\s*(.*$)/i) {
            $Unicode_version = $1;
         }
         if (/#\s*table\s*version\S*:\s*(.*$)/i) {
            $Table_version = $1;
         }
         if (/#\s*date\S*:\s*(.*$)/i) {
            $Date = $1;
         }
         if ($comment_authress) {
            $Authresses .= ", $1" if /^#\s*(.+$)/;
         } elsif (/#\s*Author\S*:\s*(.*$)/i) {
            $Authresses = $1; $comment_authress=1;
         }
      }
      s/#.*$//; 
      next if !$_;
      next if ! /^$gap1$hex$gap2$hex/i;
      ($f, $t) = ($$row_vendor, $$row_unicode);
      $f =~ s/0x//ig;
      $t =~ s/0x//ig;
      if ( index($f,"+")>=0 ) {
         # The left side contains one or more "+". Handling this way:
         # The key becomes an 8 bit string.
         $f =~ s/\s*\+\s*//g;
         my $fs = pack ( "H*", $f );
         if (index($t, "+")<0) {
            my $list = "8,".length($fs);
            $U { $list } -> { $fs } = hex ( $t );
         } else {
            @l = map hex($_), split /\+/, $t;
            my $list = "8,".length($fs).",".($#l+1);
            $U { $list } -> { $fs } = [@l];
         }
      } else {
         if (index($t, "+")<0) {
            $U{length($f)*4}->{hex($f)} = hex($t);
         } else {
            @l = map hex($_), split /\+/, $t;
            $U{(length($f)*4).",1,".($#l+1)}->{hex($f)} = [@l];
         }
      }
   }
   # $S->_dump_IMap(\%U);
   $S->_IMap->{$csid} = \%U;
1}

sub _dump_IMap {
#
# Dump IMap
#
   my ($S, $U) = @_;
   print "\nDumping IMap entry.\n";
   my ($U1, @list);
   for (keys %{$U}) {
      my $size = $_ / 4;
      $U1 = $U->{$_};
      for (sort {$a <=> $b} keys %{$U1}) {
         printf (("      %0$size"."x => "), $_);
         if (ref($U1->{$_})) {
            @list = @{$U1->{$_}};
            printf "(".("%04x " x ($#list+1)).")\n", @list;
         } else {
            printf "%04x\n", $U1->{$_};
         }
      }
   }
1}

##
## --- IMap to binary -----------------------------------------------------
##

sub _write_IMap_to_binary {
   my ($S, $csid, $path) = @_;
   return $S->_error("Integer Map \"$csid\" not loaded!\n")
      if !(my $IMap = $S->_IMap->{$csid})
   ;
   return $S->_error("Cannot open output table \"$path\"!")
      if !open (MAP4, ">$path"); 
   ;
   binmode MAP4;
   my $str = "";
   $str .= _map_binary_begin();
   $str .= _map_binary_stream(I_NAME, $S->_to_unicode($csid));
   $str .= _map_binary_mode(M_BYTE);
   $str .= _map_binary_mode(M_PKV);
   my ($from, $from_n, $to_n);
   for (keys %{$IMap}) {
      ($from, $from_n, $to_n) = split /\s*,\s*/;
      my $subMapping = $S->_map_binary_submapping (
         $IMap->{$_}, $from, $from_n||1, 16, $to_n||1
      );
      return 0 unless $subMapping;
      $str .= $subMapping;
   }
   $str .= _map_binary_mode(M_END);
   print MAP4 "$str";
   close (MAP4);
1}

sub _to_unicode {
   my ($S, $txt) = @_;
   $S -> to_unicode ($ENV{LC_CTYPE}, \$txt);
}

sub _map_binary_begin {
   pack($order[0]->{2}, MAGIC);
}

sub _map_binary_end {
   pack("C", M_END);
}

sub _map_binary_submapping {
   my ($S, $mapH, $size1, $n1, $size2, $n2) = @_;
   return $S->_error ("No IMap specified!") if (!$mapH || !%$mapH);

   if ($n2*$size2>0xffff) {
      return $S->_error ("Bad n character mapping! Too many chars!");
   }

   my $bs1S = $order[0]->{int(($size1+7)/8)};
   my $bs2S = $order[0]->{int(($size2+7)/8)}.$n2;
   return $S->_error ("'From' characters have zero size!") if !$bs1S;

   my $str = "";
   my $sig = pack ("C4", ($size1, $n1, $size2, $n2));
   
   my @key;
   if ( $n1==1 ) {
      @key = sort {$a <=> $b} keys %$mapH;
   } else {
      @key = sort keys %$mapH;
   }
   my @val = map $mapH->{$_}, @key;
   my $max = $#key;

   if ($n1>1) {
      $str .= _map_binary_mode(M_AKV);
      $str .= _map_binary_mode(M_BYTE);
      $str .= $sig;
      my $n = 0;
      while ( @key ) {
         if ( $n==0 ) {
            $n = $#key + 1;
            if ( $n>255 ) {
               $n = 255;
            }
            $str .= pack ( "C", $n );
         }
         $str .= shift ( @key );
         my $val = shift ( @val );
         if ( $n2==1 ) {
            $str .= pack ( $bs2S, $val );
         } else {
            $str .= pack ( $bs2S, @$val );
         }
         $n--;
      }
   } else {
      my ($kkey, $kbegin, $kend, $kn, $vkey, $vbegin, $vend, $vn);
      if ($n2==1) {
         $str .= _map_binary_mode(M_PKV);
         $str .= $sig;
         $kkey = _list_to_intervals(\@key, 0, $#key);
         while (@$kkey) {
            $kbegin = shift(@$kkey);
            $kend   = shift(@$kkey);
            #print "kbegin=$kbegin kend=$kend klen=".($kend-$kbegin+1)."\n";
            $str .= pack("C", $kend-$kbegin+1);
            $str .= pack($bs1S, $key[$kbegin]);
            $vkey = _list_to_intervals(\@val, $kbegin, $kend);
            while (@$vkey) {
               $vbegin = shift (@$vkey);
               $vend   = shift (@$vkey);
               $str .= pack("C", $vend-$vbegin+1);
               $str .= pack($bs2S, $val[$vbegin]);
            }
         }
      } else {
         $str .= _map_binary_mode(M_CVn);
         $str .= $sig;
         $kkey = _list_to_intervals(\@key, 0, $#key);
         while (@$kkey) {
            $kbegin = shift(@$kkey);
            $kend   = shift(@$kkey);
            $str .= pack("C", $kend-$kbegin+1);
            $str .= pack($bs1S, $key[$kbegin]);
            for ($kbegin..$kend) {
               $str .= pack($bs2S, @{$val[$_]});
            }
         }
      }
   }
   $str .= _map_binary_mode(M_END);
   $str;
}

sub _map_binary_mode {
   my ($mode) = @_;
   return "\0".pack("C", $mode)."\0";
}

sub _map_binary_stream {
   my ($mode, $str) = @_;
   if (length($str) > 255) {
      $str = substr($str, 0, 255);
   }
   my $len = length($str);
   return "\0".pack("C2", $mode, $len).$str;
}

##
## --- registry file -------------------------------------------------------
##

#
# Registry entries:
#    ALIAS  => [a list of equivalent charset ids]
#    INFO   => some occult information about this charset
#    MAP    => the path to the binary mapfile of this charset
#    SRC    => the path to the textual mapfile of this charset
#    SRCURL => an URL where to get the textual mapfile of this charset
#    STYLE  => describes what type of textual mapfile this is
#
# Registry example:
# registry = (
#    "ISO-8859-3" => {
#       "ALIAS"  => ["ISO-IR-109","ISO_8859-3:1988","LATIN3","L3"],
#       "INFO"   => "",
#       "MAP"    => "/usr/lib/perl5/.../Unicode/Map/ISO/8859-3.map",
#       "SRC"    => "/usr/local/Unicode/ISO8859/8859-3.TXT",
#       "SRCURL" => "ftp://ftp.unicode.org/MAPPINGS/ISO8859/8859-3.TXT",
#       "STYLE"  => "",
#    }
# )
#

sub _load_registry {
   #
   # The REGISTRY loaded once and reused later. Runtime modifications of
   # REGISTRY will remain unnoticed!
   #
   return 1 if $registry_loaded;
   my ($S) = @_;
   $S->_msg("loading unicode registry") if $S->_noise>2;
   my $path = $S -> _get_path ( "REGISTRY" );
   return 0 unless my @file = $S -> readTextFile ( $path );

   my %var = ();
   my ($k, $v);

   while ( @file ) {
      $_ = shift ( @file );
      # Skip everything until DEFINE marker...
      s/#.*//; s/^\s+//; s/\s+$//; next if !$_; 
      last if /^DEFINE:/i;
   }
   while ( @file ) {
      $_ = shift ( @file );
      s/#.*//; s/^\s+//; s/\s+$//; next if !$_; 
      last if /^DATA:/i;
      ($k, $v) = split /\s*[= ]\s*/,$_,2;
      $k=~s/^\$//; $v=~s/^"(.*)"$/$1/;
      if ( defined $ENV{$k} ) {
         # User environment overrides file settings.
         $v = $ENV { $k };
      } else {
         if ($v!~s/^'(.*)'$/$1/) {
            my @check;
            # parse environment
            @check=(); while ($v=~/\$(\w+|\$)/g) { push (@check, $1) }
            for (@check) {
               if ( defined $ENV{$_} ) {
                   # User environment has ranges before registry and magics.
                   $v =~ s/\$$_/$ENV{$_}/g
               } elsif ( $_ eq '$' ) {
                   # Magic value $$
                   $v =~ s/\$\$/$MAP_Path/;
               } elsif ( defined $var{$_} ) {
                   # Apply registry variables
                   $v =~ s/\$$_/$var{$_}/g
               } else {
                   # Error, undefined value!  
                   warn ("Error in file REGISTRY: Variable '$_' not defined!");
                   return 0;
               }
            }
            # parse home tilde
            if (($v eq '~') || ($v=~/^~\//)) { 
               $v =~ s/^~/_getHomeDir()/e;
            }
         }
      }
      $var{$k} = $v;
   }
   my ($name, $map, $src, $srcURL, $style, @alias, $info);
   my %arg_s = (
      "name"=>\$name, "map"=>\$map, "src"=>\$src, "srcurl"=>\$srcURL,
      "style"=>\$style, "info"=>\$info
   );
   my %arg_a = ("alias"=>\@alias);
   $name=""; $map=""; $src=""; $srcURL=""; $style=""; @alias=(); $info="";
   while ( @file ) {
      $_ = shift ( @file );
      s/#.*//; s/^\s+//; s/\s+$//;
      if (!$_) {
         $S->_add_registry_entry (
            $name, $src, $map, $srcURL, $style, \@alias, $info
         ) if $name;
         $name=""; $map=""; $src=""; $srcURL=""; $style=""; @alias=();
         $info=""; next;
      }
      ($k, $v) = split /\s*[: ]\s*/,$_,2;
      for (keys %var) {
         $v =~ s/\$$_/$var{$_}/g;
      }
      $k = lc($k);
      if ($arg_s{$k}) {
         ${$arg_s{$k}} = $v;
      } elsif ($arg_a{$k}) {
         push (@{$arg_a{$k}}, $v);
      }
   }
   $S->_msg_fin("done") if $S->_noise>2;
   $registry_loaded=1;
1}

sub _getHomeDir {
    $ENV{HOME}
    || eval ( '(getpwuid($<))[7]' ) # for systems not supporting getpwuid
    || "/";
}

sub _add_registry_entry {
   my ($S, $name, $src, $map, $srcURL, $style, $aliasL, $info) = @_;
   $registry{$name} = {
      "ALIAS"   => $aliasL ? [@$aliasL] : [],
      "MAP"   => $map     || "",
      "INFO"   => $info    || "",
      "SRC"   => $src     || "",
      "SRCURL"  => $srcURL  || "",
      "STYLE"   => $style   || "",
   };
}

sub _dump_registry {
   my ($k, $v);
   print "\nDumping registry definition:\n";
   while (($k, $v) = each %registry) {
      print "Name: $k\n";
      printf "   src:     %s\n", $v->{"SRC"};
      printf "   srcURL:  %s\n", $v->{"SRC"};
      printf "   style:   %s\n", $v->{"STYLE"};
      printf "   map:     %s\n", $v->{"MAP"};
      printf "   info:    %s\n", $v->{"INFO"};
      print  "   alias: " . join (", ", @{$v->{"ALIAS"}}) . "\n";
      print  "\n";
   }
   print "done.\n";
}

##
## --- misc ---------------------------------------------------------------
##

sub _get_path {
   my ($S, $path) = @_;
   return $S->_error("Cannot find mapfile base directory!") if !$MAP_Path;
   $path =~ s/^\/+//;
   return "$MAP_Path/$path";
}

sub _list_to_intervals {
   my ($listR, $start, $end) = @_;
   my @split = ();
   my ($begin, $i, $partend);
   $i=$start;
   while ($i<=$end) {
      $begin = $i;
      $partend = $begin+254;
      while (
         ($i<$end) && 
         ($i<$partend) &&
         ($listR->[$i+1]==($listR->[$i]+1))
      ) { 
         $i++ 
      }
      push (@split, ($begin, $i));
      $i++;
   }
   \@split;
}

sub _deprecated {
    my ( $msg ) = @_;
    if ( $WARNINGS & WARN_DEPRECATION ) {
        my $s = "Deprecated usage!";
        $s .= " ($msg)" if $msg;
        carp ( $s );
    }
1}

sub _incompatible {
    my ( $msg ) = @_;
    if ( $WARNINGS & WARN_COMPATIBILITY ) {
        my $s = "Incompatible usage!";
        $s .= " ($msg)" if $msg;
        carp ( $s );
    }
1}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

Unicode::Map V0.112 - maps charsets from and to utf16 unicode 

=head1 SYNOPSIS

=over 4

use Unicode::Map();

I<$Map> = new Unicode::Map("ISO-8859-1");

I<$utf16> = I<$Map> -> to_unicode ("Hello world!");
  => $utf16 == "\0H\0e\0l\0l\0o\0 \0w\0o\0r\0l\0d\0!"

I<$locale> = I<$Map> -> from_unicode (I<$utf16>);
  => $locale == "Hello world!"

=back

A more detailed description below.

2do: short note about perl's Unicode perspectives.

=head1 DESCRIPTION

This module converts strings from and to 2-byte Unicode UCS2 format. 
All mappings happen via 2 byte UTF16 encodings, not via 1 byte UTF8
encoding. To transform these use Unicode::String.

For historical reasons this module coexists with Unicode::Map8.
Please use Unicode::Map8 unless you need to care for two byte character
sets, e.g. chinese GB2312. Anyway, if you stick to the basic 
functionality (see documentation) you can use both modules equivalently.

Practically this module will disappear from earth sooner or later as 
Unicode mapping support needs somehow to get into perl's core. If you 
like to work on this field please don't hesitate contacting Gisle Aas!

This module can't deal directly with utf8. Use Unicode::String to convert
utf8 to utf16 and vice versa.

Character mapping is according to the data of binary mapfiles in Unicode::Map 
hierarchy. Binary mapfiles can also be created with this module, enabling you
to install own specific character sets. Refer to mkmapfile or file REGISTRY in the Unicode::Map hierarchy.


=head1 CONVERSION METHODS

Probably these are the only methods you will need from this module. Their
usage is compatible with Unicode::Map8.

=over 4

=item new

I<$Map> = new Unicode::Map("GB2312-80")

Returns a new Map object for GB2312-80 encoding.

=item from_unicode

I<$dest> = I<$Map> -> from_unicode (I<$src>)

Creates a string in locale charset representation from utf16 encoded
string I<$src>.

=item to_unicode

I<$dest>   = I<$Map> -> to_unicode (I<$src>)

Creates a string in utf16 representation from I<$src>.

=item to8

Alias for I<from_unicode>. For compatibility with Unicode::Map8

=item to16

Alias for I<to_unicode>. For compatibility with Unicode::Map8

=back

=head1 WARNINGS

=over 4

You can demand Unicode::Map to issue warnings at deprecated or incompatible 
usage with the constants WARN_DEFAULT, WARN_DEPRECATION or WARN_COMPATIBILITY.
The latter both can be ored together.

=item No special warnings:

$Unicode::Map::WARNINGS = Unicode::Map::WARN_DEFAULT

=item Warnings for deprecated usage:

$Unicode::Map::WARNINGS = Unicode::Map::WARN_DEPRECATION

=item Warnings for incompatible usage:

$Unicode::Map::WARNINGS = Unicode::Map::WARN_COMPATIBILITY

=back

=head1 MAINTAINANCE METHODS

I<Note:> These methods are solely for the maintainance of Unicode::Map.
Using any of these methods will lead to programs incompatible with
Unicode::Map8.

=over 4

=item alias

I<@list> = I<$Map> -> alias (I<$csid>)

Returns a list of alias names of character set I<$csid>.

=item mapping

I<$path> = I<$Map> -> mapping (I<$csid>)

Returns the absolute path of binary character mapping for character set 
I<$csid> according to REGISTRY file of Unicode::Map.

=item id

I<$real_id>||C<""> = I<$Map> -> id (I<$test_id>)

Returns a valid character set identifier I<$real_id>, if I<$test_id> is
a valid character set name or alias name according to REGISTRY file of 
Unicode::Map.

=item ids

I<@ids> = I<$Map> -> ids()

Returns a list of all character set names defined in REGISTRY file.

=item read_text_mapping

C<1>||C<0> = I<$Map> -> read_text_mapping (I<$csid>, I<$path>, I<$style>)

Read a text mapping of style I<$style> named I<$csid> from filename I<$path>.
The mapping then can be saved to a file with method: write_binary_mapping.
<$style> can be:

 style          description

 "unicode"    A text mapping as of ftp://ftp.unicode.org/MAPPINGS/
 ""           Same as "unicode"
 "reverse"    Similar to unicode, but both columns are switched
 "keld"       A text mapping as of ftp://dkuug.dk/i18n/charmaps/

=item src

I<$path> = I<$Map> -> src (I<$csid>)

Returns the path of textual character mapping for character set I<$csid> 
according to REGISTRY file of Unicode::Map.

=item style

I<$path> = I<$Map> -> style (I<$csid>)

Returns the style of textual character mapping for character set I<$csid> 
according to REGISTRY file of Unicode::Map.

=item write_binary_mapping

C<1>||C<0> = I<$Map> -> write_binary_mapping (I<$csid>, I<$path>)

Stores a mapping that has been loaded via method read_text_mapping in
file I<$path>.

=back

=head1 DEPRECATED METHODS

Some functionality is no longer promoted.

=over 4

=item noise

Deprecated! Don't use any longer.

=item reverse_unicode

Deprecated! Use Unicode::String::byteswap instead.

=back

=head1 BINARY MAPPINGS

Structure of binary Mapfiles

Unicode character mapping tables have sequences of sequential key and
sequential value codes. This property is used to crunch the maps easily. 
n (0<n<256) sequential characters are represented as a bytecount n and
the first character code key_start. For these subsequences the according 
value sequences are crunched together, also. The value 0 is used to start
an extended information block (that is just partially implemented, though).

One could think of two ways to make a binary mapfile. First method would 
be first to write a list of all key codes, and then to write a list of all 
value codes. Second method, used here, appends to all partial key code lists
the according crunched value code lists. This makes value codes a little bit
closer to key codes. 

B<Note: the file format is still in a very liquid state. Neither rely on
that it will stay as this, nor that the description is bugless, nor that
all features are implemented.>

STRUCTURE:

=over 4

=item <main>:

   offset  structure     value

   0x00    word          0x27b8   (magic)
   0x02    @(<extended> || <submapping>)

The mapfile ends with extended mode <end> in main stream.

=item <submapping>:

   0x00    byte != 0     charsize1 (bits)
   0x01    byte          n1 number of chars for one entry
   0x02    byte          charsize2 (bits)
   0x03    byte          n2 number of chars for one entry
   0x04    @(<extended> || <key_seq> || <key_val_seq)

   bs1=int((charsize1+7)/8), bs2=int((charsize2+7)/8)

One submapping ends when <mapend> entry occurs.

=item <key_val_seq>:

   0x00    size=0|1|2|4  n, number of sequential characters 
   size    bs1           key1
   +bs1    bs2           value1
   +bs2    bs1           key2
   +bs1    bs2           value2
   ...

key_val_seq ends, if either file ends (n = infinite mode) or n pairs are
read.

=item <key_seq>:

   0x00    byte          n, number of sequential characters 
   0x01    bs1           key_start, first character of sequence
   1+bs1   @(<extended> || <val_seq>)

A key sequence starts with a byte count telling how long the sequence
is. It is followed by the key start code. After this comes a list of 
value sequences. The list of value sequences ends, if sum(m) equals n.

=item <val_seq>:

   0x00    byte          m, number of sequential characters
   0x01    bs2           val_start, first character of sequence

=item <extended>:

   0x00    byte          0
   0x01    byte          ftype
   0x02    byte          fsize, size of following structure
   0x03    fsize bytes   something

For future extensions or private use one can insert here 1..255 byte long 
streams. ftype can have values 30..255, values 0..29 are reserved. Modi
are not fully defined now and could change. They will be explained later.

=back

=head1 TO BE DONE

=over 4

=item - 

Something clever, when a character has no translation.

=item - 

Direct charset -> charset mapping.

=item - 

Better performance.

=item - 

Support for mappings according to RFC 1345.

=back

=head1 SEE ALSO

=over 4

=item -

File C<REGISTRY> and binary mappings in directory C<Unicode/Map> of your
perl library path 

=item -

recode(1), map(1), mkmapfile(1), Unicode::Map(3), Unicode::Map8(3),
Unicode::String(3), Unicode::CharName(3), mirrorMappings(1)

=item -

RFC 1345

=item -

Mappings at Unicode consortium ftp://ftp.unicode.org/MAPPINGS/

=item -

Registrated Internet character sets ftp://dkuug.dk/i18n/charmaps/

=item -

2do: more references

=back

=head1 AUTHOR

Martin Schwartz E<lt>F<martin@nacho.de>E<gt>

=cut


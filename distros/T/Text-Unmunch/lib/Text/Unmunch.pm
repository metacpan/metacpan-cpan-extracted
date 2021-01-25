# Copyrights 2020 by [Eleonora <eleonora46@gmx.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
package Text::Unmunch;

our $VERSION = 0.2;

use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );

sub new{
    my ($class,$args) = @_;
    my $self = bless { aff => $args->{aff},
                       wf => $args->{wf}, 
                       sfx => $args->{sfx},
                       pfx => $args->{pfx},
                       debug    => $args->{debug},
                       debug_class => 0,
                     }, $class;

}

sub check_args{
   my $self = shift;
   
   if (not defined $self->{aff} or not defined $self->{wf}){
     die "affix file and word file must be defined\n";
   }
    if(   not -e $self->{aff} or not -e $self->{wf}){
     die "either $self->{aff} or $self->{wf} does not exist\n";
   }
   if(not defined $self->{debug}){
      $self->{debug} = '';
   }
   if($self->{debug} ne ""){
      $self->{debug_class} = substr($self->{debug}, 3);
   }
   if(not defined $self->{sfx}){
      $self->{sfx} = '';
   } elsif(length($self->{sfx}) > 1){
     $self->{sfx} = substr( $self->{sfx}, 1);
   }
   if(not defined $self->{pfx}){
      $self->{pfx} = '';
   } elsif(length($self->{pfx}) > 1){
     $self->{pfx} = substr( $self->{pfx}, 1);
   }
 
   if($self->{sfx} ne '' and $self->{sfx} eq 's'){
     $self->{sfx} = 1;
   }
   if($self->{pfx} ne '' and $self->{pfx} eq 'p'){
     $self->{pfx} = 1;
   }
   if(($self->{sfx} eq '') and ($self->{pfx} eq '')){
     $self->{pfx} = 1;
     $self->{sfx} = 1;
   }
   if($self->{debug_class} >= 2){
     print "r_s:$self->{sfx} r_p:$self->{pfx} deb:$self->{debug} af:$self->{aff} wf:$self->{wf}\n";
   }
      
}

# get aff file
sub get_aff{
   my $self = shift;
   return $self->{aff};
}

# set aff file
sub set_aff{
   my ($self,$new_aff) = @_;
   $self->{aff} = $new_aff;
}

# get wf
sub get_wf{
   my $self = shift;
   return $self->{wf};
}

# set wf
sub set_wf{
   my ($self,$new_wf) = @_;
   $self->{wf} = $new_wf;
}
# get sfx
sub get_sfx{
   my $self = shift;
   return $self->{sfx};   
}
# set sfx
sub set_sfx{
   my ($self,$new_sfx) = @_;
   $self->{sfx} = $new_sfx;
}
# get pfx
sub get_pfx{
   my $self = shift;
   return $self->{pfx};   
}
# set pfx
sub set_pfx{
   my ($self,$new_pfx) = @_;
   $self->{pfx} = $new_pfx;
}
# get debug
sub get_debug{
   my $self = shift;
   return $self->{debug};   
}
# set debug
sub set_debug{
   my ($self,$new_debug) = @_;
   $self->{debug} = $new_debug;
}
# return formatted string of the product
sub to_string{
   my $self = shift;
   
   return "aff: $self->{aff}\nwf: $self->{wf}\nsfx: $self->{sfx}\npfx: $self->{pfx}\ndebug: $self->{debug}\ndebug_class: $self->{debug_class}\n";
}

sub get_endings{
   my $self = shift;
   my ($sfxptr, $hashptr);
   my (@sfx_arr, @pfx_arr);
   
   check_args($self);

   ($sfxptr,$hashptr) = read_in_sfx($self->{aff}, $self->{debug_class});
   
 
   open(FH, '<', $self->{wf}) or die $!;

while(<FH>){
  my @warr = split(/\//, $_);
  my $szo = $warr[0];
  my $flags = $warr[1]; 
  my @flarr = split(//, $flags);
   if($self->{debug_class} >= 3){
     print "szo:$szo flags:$flags\n";
   }
  foreach(@flarr){
    # get sfx index
     my $idx = $hashptr->{$_};
    if(defined($idx)){
      if($self->{debug_class} >= 2){
      print "tag = $_ idx:$idx\n";
      }
      my $count = $sfxptr->[$idx]{'count'};
      my $type  = $sfxptr->[$idx]{'type'};
      my $comb  = $sfxptr->[$idx]{'comb'};
    #   print "idx:$idx cnt=$count\n";
      for (my $i=0; $i < $count; $i++){
        my ($strip, $addtoword, $cond);
        $strip     = $sfxptr->[$idx]{'elements'}->[$i]{'strip'};
        $addtoword = $sfxptr->[$idx]{'elements'}->[$i]{'add_to_word'};
        $cond      = $sfxptr->[$idx]{'elements'}->[$i]{'condition'};
         if($self->{debug_class} >=3){
         print "idx:$idx cnt=$count strip:$strip atw:$addtoword cond:$cond->[0]\n";
         }
         if(met_cond($szo, $cond, $type,$self->{debug_class})){
             my $ujszo;
             if($type eq 's'){
               $ujszo = strip_add_sfx($szo, $strip, $addtoword);
               push(@sfx_arr,$ujszo );
             } elsif($type  eq 'p'){
                if($comb eq 'y' or $comb eq 'Y'){
                  push( @pfx_arr, $addtoword);
                } else{
                  $ujszo = strip_add_pfx($szo, $strip, $addtoword);
                }
             }
             if($self->{sfx} and defined($ujszo)){print "$ujszo\n";}
         } 
      }
    }
  }  # flarr
  if($self->{pfx}){
   if($self->{pfx}){
    foreach(@pfx_arr){
      my $pfx = $_;
      foreach(@sfx_arr){
        my $ujszo = $pfx.$_;
        if(defined($ujszo)){print "$ujszo\n";}
      }
    }
   }
  } # r_prefix
  @sfx_arr = ();
  @pfx_arr = ();

    
}

close(FH);
   
   
}


sub read_in_sfx{
   my($affixfile, $debug) = @_;
   
 my $new = 1;
 my (@sfx);
 my ($idx);
 $idx = 0;
 my $counter = 0;
 #my $debug = 2;
 my %shash;
 
open(FH, '<', $affixfile) or die $!;

 while(<FH>){
   if(index($_, "SFX ") == 0 or index($_, "PFX ") == 0){
     if($debug >=4){
       print $_;
     }
     if($new){
         my @fields = split( /\s{1,}/, $_);
         my @newarr;
        # print Dumper (\@fields);
         $sfx[$idx]{'count'}    = $fields[3];
         $sfx[$idx]{'id'}       = $fields[1];
         $sfx[$idx]{'comb'}     = $fields[2];
         $shash{$fields[1]} = $idx;
         if($fields[0] eq 'SFX'){
           $sfx[$idx]{'type'}     = 's';
         } else{
           $sfx[$idx]{'type'}     = 'p';
          }
         $sfx[$idx]{'elements'} = \@newarr;
         $new = 0;
      } else{
        my @fields = split( /\s{1,}/, $_);
        my $r = $sfx[$idx]{'elements'};
        my @newarr = @$r;
        $newarr[$counter]{'strip'}         = $fields[2];
        #
        # strip /.. from prefix
        #
        my @tmparr = split(/\//, $fields[3]);
        $newarr[$counter]{'add_to_word'}   = $tmparr[0];
        $newarr[$counter]{'condition'}     = read_cond($fields[4], $debug);
        $sfx[$idx]{'elements'} = \@newarr;
         ++ $counter;
        if($counter eq $sfx[$idx]{'count'}){
            $new = 1;
            $counter = 0;
            ++$idx;
         }
         
     }
   }
 }

 close(FH);

 return (\@sfx, \%shash);
}


sub read_cond{
   my($condition, $debug) = @_; 
   
   my @carr;
   
   my $in_loop = 0;
   my @condarr = split(//, $condition);
   my ($tcarr);
   foreach (@condarr){
      if ($_  eq '['){
         if(!$in_loop){
           $in_loop = 1;
          } else {
            print "error1 in condition $condition\n";
          }
      } 
      elsif($_ eq ']'){
        if($in_loop) {
          push(@carr, $tcarr);
          $in_loop = 0;
          $tcarr = '';
        }else {
            print "error2 in condition $condition\n";
        }
      }else {
        if($in_loop){
          $tcarr .= $_;
        }else{
           push(@carr, $_);
        }
      }
         
   }
   if($debug >=4){
      my $condarrsize =  @carr;
      my  $i;
      print "carr: $condarrsize\n";
      for ($i = 0; $i < $condarrsize; $i++){
        print "$i $carr[$i]\n";
      }
   }
   return \@carr;
   
}

sub met_cond{
   my($szo, $condref, $type, $debug) = @_; 
   
   my @carr = @$condref;
   my $condarrsize =  @carr;
   if($debug >=5){
     print "condarrsize:$condarrsize\n";
   }
   
   if($carr[0] eq '.' and $condarrsize == 1 ){
     return 1;
   }elsif ($type eq 's'){
   my $lszo = length($szo);
   my $szoidx = $lszo - 1;
   my $i;
   for($i = $condarrsize -1; $i >=0; $i--){
     my $tobechecked = substr($szo, $szoidx, 1);
     if($debug >= 4){
        print "tbc:$tobechecked szdx:$szoidx ci:$carr[$i]\n";
     }
     if(length($carr[$i]) == 1){
        if ( $carr[$i] ne $tobechecked  and $carr[$i] ne '.'){
           if($debug >= 3){
             print "no match1\n";
           }
           return 0;
        }
    } else{
      my $j ;
      my $matched = 0;
      my $clen = length($carr[$i]);
      if(substr($carr[$i],0,1) eq '^'){ # inverted check
         for($j = 1; $j < $clen; $j++){
           if(substr($carr[$i],$j,1) eq $tobechecked){
             if($debug >= 3){
               print "no match2\n";
             }
             return 0;
           }
         }
         $matched = 1;
        } else{ # at least one matches
         for($j = 1; $j < $clen; $j++){
           if(substr($carr[$i],$j,1) eq  $tobechecked){
             $matched = 1;
             last;
           }
         }
        }
        if($matched eq 0){
           if($debug >= 3){
            print "no match3 i= $i szi: $szoidx tbc:$tobechecked\n";
           }
            return 0;
        }
     }
     --$szoidx;
    }          
      
   } elsif($type eq 'p'){
   my $szoidx = 0;
   my $i;
   for($i = 0; $i <= $condarrsize -1; $i++){
     my $tobechecked = substr($szo, $szoidx, 1);
     if($debug >= 4){
        print "tbc:$tobechecked szdx:$szoidx ci:$carr[$i]\n";
     }
     if(length($carr[$i]) == 1){
        if ( $carr[$i] ne $tobechecked ){
           if($debug >= 3){
             print "no match1\n";
           }
           return 0;
        }
    } else{
      my $j ;
      my $matched = 0;
      my $clen = length($carr[$i]);
      if(substr($carr[$i],0,1) eq '^'){ # inverted check
         for($j = 1; $j < $clen; $j++){
           if(substr($carr[$i],$j,1) eq $tobechecked){
             if($debug >= 3){
               print "no match2\n";
             }
             return 0;
           }
         }
         $matched = 1;
        } else{ # at least one matches
         for($j = 1; $j < $clen; $j++){
           if(substr($carr[$i],$j,1) eq  $tobechecked){
             $matched = 1;
             last;
           }
         }
        }
        if($matched eq 0){
           if($debug >= 3){
            print "no match3 i= $i szi: $szoidx tbc:$tobechecked\n";
           }
            return 0;
        }
     }
     ++$szoidx;
    }          
      
   }
  return 1;  
   
}
sub strip_add_sfx{
  my($szo, $strip, $atw) = @_;
  if($strip ne '0'){ 
    $szo =  substr($szo, 0, (length($szo)-length($strip)));
  }
  return $szo.$atw;

}
sub strip_add_pfx{
  my($szo, $strip, $atw) = @_;
  if($strip ne '0'){ 
    $szo =  substr($szo, 0, (length($szo)-length($strip)));
  }
  return $atw.$szo;

}

1;

__END__


=encoding utf8
 
=head1 NAME

Text::Unmunch - find all endings of a word for hunspell 


=head1 SYNOPSIS

  use Text::Unmunch;
 
  my $unmunch = Text::Unmunch->new{
                       aff => "en_US.aff",
                       wf => "iren.dic", 
                       sfx => "-s",
                       pfx => "-p",
                       debug    => "-d=2"
                     });
  $unmunch->get_endings();

=head1 DESCRIPTION

Lists all endings of a word, that hunspell will generate.
The listed words here will be accepted as good words by hunspell.
The arguments for Text::Unmunch are:

=over 4

=item B<aff file>, this must be an UTF-8 coded affix file. You can use recode for this, like this: cat hu_HU.aff | recode l2..u8 > output.aff or: cat en_US.aff | recode l1..u8 >output.aff


=item B<word file>, this is also an utf-8 coded file, containing the words to be checked, with all flags, as it appears in the .dic file for hunspell.

=over 12

=item  Example word file: 

=begin man

 civility/IMS 
 bestseller/MS

=end man

=back

=item B<sfx>, if it exists, its form is -s. It means, that you wish to see the suffixes in the result (not only the prefix results)

=item B<pfx>, if it exists, its form is -p. It means, that you wish to see the prefixes in the result (not only the suffix results)

If both sfx and pfx are missing, both will be displayed.

=item B<debug>, if exists, its form is -d=n, where n is a number between 0 and 9. The higher the value, the more debug lines will be displayed.


=back

Only the aff file and the word file are required parameters.

=head1 METHODS

=head2 Constructor

=over 4

=item my obj = Text::Unmunch-E<gt>B<new>( ARGS)

=back

=head2 Method

=over 4

=item $obj-E<gt>B<get_endings>()

This function reads the aff and the word file, finds the possible word endings for the words in the word file, and prints the result onto the screen.

=back

=head1 DETAILS


=head2 BUGS

Text::Unmunch does not handle two level affixing. If a result word has switches, these will not automatically be searched and shown. If you are interested, what they do, you must edit a word file for that and let you show in a second step, what hunspell generates.
Two level affixing is included as far as I know, only in the Hungarian affix file.

=head1 SEE ALSO

This module is useful, when you work with hunspell, and want an easy way to find, what endings do switches generate. There are some programs in the hunspell distribution to find the endings, unfortunately none of them works properly. Therefore this program.

=head1 External references

=over 4

=item Hunspell source code: 
 https://sourceforge.net/projects/hunspell/files/Hunspell/1.3.3/hunspell-1.3.3.tar.gz/download?use_mirror=kumisystems

=item Hunspell issues: 
 https://github.com/hunspell/hunspell/issues
 
=item Magyarispell issues: 
 https://github.com/laszlonemeth/magyarispell/

=back
 
=head1 AUTHORS

Developer: Eleonora, email E<lt>eleonora46@gmx.netE<gt>

=head1 LICENSE

Copyrights 2020 Eleonora, email E<lt>eleonora46@gmx.netE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See F<http://www.perl.com/perl/misc/Artistic.html>

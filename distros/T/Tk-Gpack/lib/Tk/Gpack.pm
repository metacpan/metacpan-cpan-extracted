package Tk::Gpack ; 

use Exporter                ; 
use Tk::Widget              ; 
our @ISA = qw(Exporter Tk::Widget) ;
our @EXPORT = qw(gpack xpack spack tpack gplace xplace splace tplace ggrid xgrid sgrid tgrid gunderline _packinate _gridinate _placinate) ;
our $VERSION = '0.7' 	    ;
 
package Tk ;  # Gleefully pollute the root namespace. 
Exporter::import qw(Tk::Gpack gpack xpack spack tpack gplace xplace splace tplace ggrid xgrid sgrid tgrid gunderline _packinate _gridinate _placinate); 

package Tk::Gpack ; 

sub gpack { # Group Pack   
###########
	my @tp = @_    ; # To pack 
	my $count = 0  ; 
	foreach (@tp) {
		if ($count % 2) { # If odd 
			$tp[$count - 1]->pack(_packinate($tp[$count])) ;
		}
		$count++ ;
	}
}

sub tpack { # Target Pack, group pack in a target   
###########
	my $self = shift ; 
	my @tp = @_      ; # To pack 
	my $count = 0    ; 
	foreach (@tp) {
		if ($count % 2) { # If odd 
			$tp[$count - 1]->pack(_packinate($tp[$count]), -in => $self) ;
		}
		$count++ ;
	}
}

sub xpack { # Expand Pack
###########
	my $self = shift   ; 
	my $string = shift ; 
	my @options = @_   ; 
	push @options,  _packinate($string) ; 
	$self->pack(@options) ; 
} 

sub spack { # self pack, assume the object has a data configspec called -geometry
#############
	my $self = shift ;
	my @options = @_ ;  
	my $string = $self->cget('-geometry') ;
	$self->xpack($string, @options)       ; 
}

sub ggrid { # Group Grid
###########
	my @tg = @_    ; # To grid 
	my $count = 0  ; 
	foreach (@tg) {
		if ($count % 2) { # If odd 
			$tg[$count - 1]->grid(_gridinate($tg[$count])) ;
		}
		$count++ ;
	}
}

sub tgrid { # Group Grid
###########
	my $self = shift ; 
	my @tg = @_      ; # To grid 
	my $count = 0    ; 
	foreach (@tg) {
		if ($count % 2) { # If odd 
			$tg[$count - 1]->grid(_gridinate($tg[$count]), -in => $self) ;
		}
		$count++ ;
	}
}

sub xgrid { # Expand Grid
###########
	my $self = shift   ; 
	my $string = shift ; 
	my @options = @_   ; 
	push @options,  _gridinate($string) ; 
	$self->grid(@options) ; 
}

sub sgrid { # self pack, assume the object has a data configspec called -geometry
#############
	my $self = shift ;
	my @options = @_ ;  
	my $string = $self->cget('-geometry') ;
	$self->xgrid($string, @options)       ; 
}

sub gunderline { # Group underline
#################
	my @tu = @_ ; # too underline 
	my $count = 0  ; 
	foreach (@tu) {
		if ($count % 2) { # If odd 
			$tu[$count - 1]->configure("-underline" => $tu[$count]) ;
		}
		$count++ ;
	}
}

sub gplace { # Group place
###########
        my @tp = @_    ; # To place
        my $count = 0  ;
        foreach (@tp) {
                if ($count % 2) { # If odd
                        $tp[$count - 1]->place(_placinate($tp[$count])) ;
                }
                $count++ ;
        }
}

sub tplace { # Target Place
###########
        my $self = shift ;
        my @tp = @_      ; # To place
        my $count = 0    ;
        foreach (@tp) {
                if ($count % 2) { # If odd
                        $tp[$count - 1]->place(_placinate($tp[$count]), -in => $self) ;
                }
                $count++ ;
        }
}

sub xplace { # Expand place
###########
        my $self = shift   ;
        my $string = shift ;
        my @options = @_   ;
        push @options,  _placinate($string) ;
        $self->place(@options) ;
}

sub splace { # self place
#############
        my $self = shift ;
        my @options = @_ ;
        my $string = $self->cget('-geometry') ;
        $self->xplace($string, @options)       ;
}

sub _placinate {
################
	# -padx and -pady are now ony effective to a single character. 
	my $stringin = shift ; 
	my @stringout        ; 
	my $foo = 0          ; 
	################### Switches
	my $a = "-anchor"      ; 
	my $h = "-height"      ; 
	my $w = "-width"       ; 
	my $x = "-x"           ; 
	my $y = "-y"           ; 
	########################
	my @chars = reverse(split(//, $stringin)) ; # Read backwards 
	my @buf = () 		       	          ; 
	foreach(@chars) {
		if ($_ =~ /[0-9]/) {
			unshift @buf, $_ ; 
			next 		 ; 
		} else {
			if ($_ =~ /w/ && scalar(@buf)) { # a -width 
				my $n = join "", @buf ; 
				@buf = ()             ; 
				push @stringout, ($w => $n) ;  
				next 		      ; 
			} elsif ($_ =~ /h/ && scalar(@buf)) { # -height 
				my $n = join "", @buf ; 
				@buf = ()             ; 
				push @stringout, ($h => $n) ;  
				next 		      ; 
			} elsif ($_ =~ /x/ && scalar(@buf)) { # -x 
				my $n = join "", @buf ; 
				@buf = ()             ; 
				push @stringout, ($x => $n) ;  
				next 		      ; 
			} elsif ($_ =~ /y/ && scalar(@buf)) { # -y 
				my $n = join "", @buf ; 
				@buf = ()             ; 
				push @stringout, ($y => $n) ;  
				next 		      ; 
			} elsif ($_ =~ /a/ && scalar(@buf)) { # -anchor 
				my $n = join "", @buf ; 
				@buf = ()             ; 
				push @stringout, ($a => $n) ;  
				next 		      ; 
			} else {
				unshift @buf, $_ ; # Should only be characters preceding an "a"
			}
		}
	}
	warn @stringout if $foo ;  
	return @stringout       ; 
}


sub _packinate {
###############
	# -padx and -pady are now ony effective to a single character. 
	# 
	my $string = shift ;
	#  warn $string ;
	my $foo = 0     ;
	#################### Switches 
	my $x1 = "-expand" ; 
	my $s1 = "-side"   ; 
	my $a = "-anchor"  ; 
	my $f = "-fill"    ;
	my $X = "-padx"    ;
	my $Y = "-pady"	 ; 
	#################### Values
	my $c = "center"   ; 
	my $l = "left" 	 ; 
	my $r = "right"    ; 
	my $t = "top"      ;
	my $n = "n"   ; 
	my $s2 = "s"  ; 
	my $e = "e"	  ; 
	my $w = "w"	  ; 
	my $y = "y"   ; 
	my $x2 = "x"  ; 
	my $b1 = "both"    ;
	my $b2 = "bottom"  ;   
	my @chars = split(//,$string) ;
	#################### 
	my $last ;
	my $count = 0     ;  
	foreach (@chars) { # single characters.
		if (s/a/$a/) { } 
		elsif (s/f/$f/) { } 
		elsif (s/X/$X/) { } 
		elsif (s/Y/$Y/) { } 
		elsif (s/c/$c/) { } 
		elsif (s/l/$l/) { } 
		elsif (s/r/$r/) { } 
		elsif (s/t/$t/) { } 
		elsif (s/n/$n/) { } 
		elsif (s/e/$e/) { } 
		elsif (s/w/$w/) { } 
		elsif (s/y/$y/) { $foo = 1 ; } 
		elsif ($_ =~ /x/) {if ($last =~ /$f/) {$_ = $x2 ; } else {$_ = $x1 ; } }
		elsif ($_ =~ /s/) {if ($last =~ /$a/) { $_ = $s2 ; } else {$_ = $s1 ; } }  
		elsif ($_ =~ /b/) {if ($last =~ /$s1/) { $_ = $b2 ; } else {$_ = $b1 ; } }
		##########
		$chars[$count] = $_ ; 
		$last = $_ ;
		$count++ ;    
	} 
	# 
	$count = 0  ;
	my @vals ; 
	foreach (@chars) {
		if ($count % 2) { # If odd 
			push @vals, ($chars[$count - 1] => $chars[$count]) ;
		}
		$count++ ; 
	}
	warn @vals if $foo ;  
	return @vals ; 
}

sub _gridinate {
###############
	# Untested
	my $string = shift   ;
	my $row = $string    ; 
	my $col = $string    ;
	my $sticky = $string ;  
	my @vals ; 

	$row =~ s/.*r([0-9]+).*/$1/ ;  # Keep the numbers that previously followed "r"
	$col =~ s/.*c([0-9]+).*/$1/ ;  #
	$sticky =~ s/([cr][0-9]+)//g  ;# delete all other possible pairs 
	if ($sticky =~ /s/) { 
		$sticky =~ s/s(...)/$1/ ; # allow for sw se etc. 
		$sticky =~ s/^s//       ;  
		push @vals, ("-sticky" => $sticky) ;  
	} 
	unshift @vals, ("-row" => $row)    ;
	unshift @vals, ("-column" => $col) ;
	# warn "$row $col $sticky"           ;   
	return @vals ; 	 
}

1 ;

################## END OF CODE #####################################

=head1 NAME 

Tk::Gpack - Abbreviated geometry arguments for pack, grid and place geometry managers.

=head1 DESCRIPTION

This module exports four functions for each of the different geometry mananers into the Tk namespace.
These functions provide a variety of styles for controlling the indevidual geometry of one, 
or bulk groups of widgets.  Each geometry manager has a series of single letter abbreviations 
allowing a significant reduction in code, while remaining fairly intuitive. 

=head1 SYNOPSIS 

	use Tk::Gpack ; 

gpack, ggrid, and gplace are group packers, they recieve an even numbered list of alternating widgets and abbreviations. 

	gpack($one, 'slan' $two, 'sran' $three, 'slanx1fb')     ; # group pack
	ggrid($one, 'r25c10', $two, 'c9r15', $three, 'c1r1se' ) ; # group grid
	gplace($one, 'w40h40x120y120anw', $two, 'x40y40ase', $three, 'aww20h20x25y140') ; # group placer 

tpack, tgrid, and tplace are target packers, and use exactly the same format except they take a preceding target widget, (typically a frame) which will be automatically be used in conjunction with the -in => argument. 

	tpack($FRAME1, $one, 'slan' $two, 'sran' $three, 'slanx1fb')        ; # target pack
	tgrid($TOPLEVEL1, $one, 'r25c10', $two, 'c9r15', $three, 'c1r1se' ) ; # target grid
	tplace($MW, $one, 'w40h40x120y120anw', $two, 'x40y40ase', $three, 'aww20h20x25y140') ; # target placer 

xpack xgrid and xplace are expand packers, and used inline as a direct replacement to pack grid and place. The first string passed is the abbreviation string, while anything remaining will be parsed as the standard verbose options. 

	$one->xpack('slan', -in => $FRAME1)      ; # expand pack  
	$two->xgrid('r4c4sw', -in => $TOPLEVEL2) ; # expand grid
	$three->xplace('x20y20aw', -in => $MW)   ; # expand place 

spack sgrid and splace are self packers, they assume that an abbreviation is embedded in the widget as an option called '-geometry'. You must be using derived widgets for this to work, and have defined a configspec '-geometry'. The self packers perform the same as xpack in that they permit additional verbose option pairs to be passed which will be appended to the expansion of the embedded abbreviation. If you are using a default widget geometry as shown below, you can still override it by simply using xpack in place of spack. (spack won't take the abbreviation as an argument) This is particularly handly for templated code. To use spack splace and sgrid do the following: 

	package DerivedButton ; 
	...
	sub Populate {
	$self->ConfigSpecs(-geometry => ['PASSIVE',     'data',       'Data',       'slan']) ; # <------ Abbreviation
	}
	#!/usr/bin/perl -w 
	use Tk ; 
	... 
	my $DButton = $mw->DerivedButton()->spack(-in => $foo) ; 

Obviously this last example is not complete. Once you've built a derived widget it should make sense though. 

=head1 DETAILS

The abbreviations are fairly intuitive. All supported options are represented by a single character. For the pack geometry manager all passed values are also single characters. For grid and place passed values may be multiple characters. Numeric arguments for grid and place are variable length integers for example. There are a few redundant characters, but they work as expected.  

NOT ALL OPTIONS TRANSLATE, in this version. (And probably for quite a few versions to come) But the most used ones do. Please review the following translation lists to see How things are supported at this time. 

=head1 SUPPORTED TRANSLATIONS

	# OPTIONS pack() 
	################### 
	x = '-expand'  
	s = '-side'    
	a = '-anchor'  
	f = '-fill'   
	X = '-padx'  
	Y = '-pady' 

	# VALUES pack() 
	#################### 
	c = 'center'   
	l = 'left'      
	r = 'right'     
	t = 'top'      
	n = 'n'         
	s = 's'       
	e = 'e'	      
	w = 'w'	       
	y = 'y'        
	x = 'x'        
	b = 'both'    
	b = 'bottom'    

	# OPTIONS grid() 
	#################### 
	r = '-row'   
	c = '-column'
	s = '-sticky'

	# VALUES grid() 
	#################### 
	n = 'n'
	s = 's'
	e = 'e'
	w = 'w'

        # OPTIONS place()
        ####################
	w = '-width' 
	h = '-height' 
	x = '-x' 
	y = '-y' 
	a = '-anchor' 

	# VALUES place() 
	#################### 
	n = 'n' 
	ne = 'ne' 
	nw = 'nw' 
	s = 's'
	se = 'se' 
	sw = 'sw' 
	e = 'e' 
	w = 'w'

=head1 INSTALLATION 

To install this module type the following:

	perl Makefile.PL
	make
	make install

=head1 DEPENDENCIES

	use Tk ; # (duh) 

Not all options currently supported. I've been using this for a while now, and it 
seems to work OK. 

=head1 TODO

Add more supported options. Tighten up some of the code. 

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2005 IT Operators (http://www.itoperators.com) 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


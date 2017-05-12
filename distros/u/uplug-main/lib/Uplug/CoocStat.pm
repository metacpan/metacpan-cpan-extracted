#-*-perl-*-
#
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#----------------------------------------------------------------------------
#
# 


package Uplug::CoocStat;

use strict;

use vars qw(@ISA);
@ISA;

sub new{

    my $class=shift;
    my ($m)=@_;

    if ($m=~/dice/i){return Uplug::CoocStat::Dice->new();}
    if ($m=~/jaccard/i){return Uplug::CoocStat::Jaccard->new();}
    if ($m=~/t-?score/i){return Uplug::CoocStat::tscore->new();}
    if ($m=~/(ll|log\s*like)/i){return Uplug::CoocStat::LL->new();}
    if ($m=~/(pmi|pointwise)/i){return Uplug::CoocStat::PMI->new();}
    if ($m=~/(tmi|mutual)/i){return Uplug::CoocStat::I->new();}
    if ($m=~/(association|mi)/i){return Uplug::CoocStat::MI->new();}
    if ($m=~/(cubic|mi3)/i){return Uplug::CoocStat::MI3->new();}
    if ($m=~/phi/i){return Uplug::CoocStat::Phi->new();}
    if ($m=~/chi/i){return Uplug::CoocStat::Chi2->new();}
    if ($m=~/kulczinsky/i){return Uplug::CoocStat::Kulczinsky->new();}
    if ($m=~/ochiai/i){return Uplug::CoocStat::Ochiai->new();}
    if ($m=~/yule/i){return Uplug::CoocStat::Yule->new();}
    if ($m=~/connoughy/i){return Uplug::CoocStat::McConnoughy->new();}
    if ($m=~/(simple|matching)/i){return Uplug::CoocStat::Simple->new();}
    return undef;
}


#------------------------------------------------------------------
#
# frequencies:
#             |  word 1   not word1 |
#--------------------------------------------
#      word 2 |   n11       n10     |  n1x
#  not word 2 |   n01       n00     |  n0x
#--------------------------------------------
#             |   nx1       nx0     |  nxx
#
#

package Uplug::CoocStat::Measure;

sub new{
    my $class=shift;
    my ($measure)=@_;
    my $s={};
    return bless $s,$class;
}

sub setValues{
    my $s=shift;
    my ($joint,$left,$right,$total)=@_;
    ($s->{n11},$s->{n1x},$s->{nx1},$s->{nxx})=@_;
}

sub checkValues{
    my $s=shift;
    if (not $s->{n1x}){
	$s->{ERROR}='Left marginal should not be zero!';
	return 0;
    }
    if (not $s->{nx1}){
	$s->{ERROR}='Right marginal should not be zero!';
	return 0;
    }
    if (not $s->{nxx}){
	$s->{ERROR}='Total frequency should not be zero!';
	return 0;
    }
    if ($s->{n11}>$s->{n1x}){
	$s->{ERROR}='Joint frequency should not be greater than left marginal!';
	return 0;
    }
    if ($s->{n11}>$s->{nx1}){
	$s->{ERROR}='Joint frequency should not be greater than right marginal!';
	return 0;
    }
    if ($s->{n1x}>$s->{nxx}){
	$s->{ERROR}='Left marginal should not be greater than the total frequency!';
	return 0;
    }
    if ($s->{nx1}>$s->{nxx}){
	$s->{ERROR}='Right marginal should not be greater than the total frequency!';
	return 0;
    }
    return 1;
}

sub compute{
    my $s=shift;
    $s->setValues(@_);
    if (not $s->checkValues()){
	print STDERR "# Uplug::CoocStat: ",$s->{ERROR},"\n";
	return undef;
    }
    return 1;
}













#-----------------------------------------
# Dice Coefficient
#
#      Dice = 2*P(x,y) / (P(x)+P(y))
#           = 2*joint / (left+right)


package Uplug::CoocStat::Dice;

use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Measure );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return 2*$s->{n11}/($s->{n1x}+$s->{nx1});
    }
    return undef;
}

#-----------------------------------------
# Jaccard Coefficient
#


package Uplug::CoocStat::Jaccard;

use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Measure );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return $s->{n11}/($s->{n1x}+$s->{nx1}-$s->{n11});
    }
    return undef;
}


#-----------------------------------------
# point-wise mututal information (PMI)
#
#      PMI = log( P(x,y) / (P(x)p(y)) )


package Uplug::CoocStat::PMI;

use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Measure );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	my $score=
	    (($s->{n11}/$s->{n1x})/$s->{nx1})*$s->{nxx};
	if ($score<=0){
	    print STDERR "Attempt to take log of 0 or negative value.";
	    return undef;
	}
	return log($score)/log(2);
    }
    return undef;
}


#-----------------------------------------
# t-score 
#
#      t-score = (P(x,y)-P(x)P(y)) / sqrt( 1/K * P(x,y) )


package Uplug::CoocStat::tscore;

use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Measure );


sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return sqrt($s->{n11})-($s->{n1x}*$s->{nx1})/
	    (sqrt($s->{n11})*($s->{nxx}));
    }
    return undef;
}

sub compute_old{
    my $s=shift;
    if ($s->SUPER::compute(@_)){

	my $Pxy=$s->{n11}/$s->{nxx};
	my $Px=$s->{nx1}/$s->{nxx};
	my $Py=$s->{n1x}/$s->{nxx};

	return ($Pxy-($Px*$Py))/sqrt($Pxy/$s->{nxx});
    }
    return undef;
}


#-----------------------------------------
# the PHI coefficient
#

package Uplug::CoocStat::Phi;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Measure );


sub setValues{
    my $s=shift;
    $s->SUPER::setValues(@_);

    $s->{n11}=$s->{n11};
    $s->{n10}=$s->{n1x}-$s->{n11};
    $s->{n01}=$s->{nx1}-$s->{n11};
    $s->{n00}=$s->{nxx}-$s->{n11}-$s->{n10}-$s->{n01};
    $s->{n0x}=$s->{nxx}-$s->{n1x};
    $s->{nx0}=$s->{nxx}-$s->{nx1};
}

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return ((($s->{n11}*$s->{n00})-($s->{n10}*$s->{n01}))**2)/
	    ($s->{n1x}*$s->{nx1}*$s->{n0x}*$s->{nx0});
    }
    return undef;
}



#-----------------------------------------
# the log-likelihood (ll)
#

package Uplug::CoocStat::LL;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );


sub checkValues{
    my $s=shift;
    if (not $s->SUPER::checkValues(@_)){return 0;}
    if (not $s->{n10}){
	$s->{ERROR}='n10 should not be zero!';
	return 0;
    }
    if (not $s->{n01}){
	$s->{ERROR}='n01 should not be zero!';
	return 0;
    }
    if (not $s->{n00}){
	$s->{ERROR}='n00 should not be zero!';
	return 0;
    }
    return 1;
}


sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	my $ll=
	    $s->{n11}*log($s->{n11})+
	    $s->{n10}*log($s->{n10})+
	    $s->{n01}*log($s->{n01})+
	    $s->{n00}*log($s->{n00})
	    -($s->{n1x}*log($s->{n1x}))
	    -($s->{nx1}*log($s->{nx1}))
	    -($s->{nx0}*log($s->{nx0}))
	    -($s->{n0x}*log($s->{n0x}))
	    +($s->{nxx}*log($s->{n11}+$s->{nxx}));
	return $ll;

#	my $ll=
#	    $s->{n11}*log($s->{n11})+
#	    $s->{n10}*log($s->{n10})+
#	    $s->{n01}*log($s->{n01})+
#	    $s->{n00}*log($s->{n00})
#	    -($s->{n11}+$s->{n10})*log($s->{n11}+$s->{n10})
#	    -($s->{n11}+$s->{n01})*log($s->{n11}+$s->{n01})
#	    -($s->{n10}+$s->{n00})*log($s->{n10}+$s->{n00})
#	    -($s->{n01}+$s->{n00})*log($s->{n01}+$s->{n00})
#	    +($s->{n11}+$s->{n10}+$s->{n01}+$s->{n00})*
#	    log($s->{n11}+$s->{n10}+$s->{n01}+$s->{n00});
#	return $ll;
    }
    return undef;
}


#-----------------------------------------
# Cubic Association Ratio (MI3)
#

package Uplug::CoocStat::MI3;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return log(($s->{n11}**3)/
		   (($s->{n11}+$s->{n10})*
		    ($s->{n11}+$s->{n01})))/log(2);
    }
}


#-----------------------------------------
# Association Ratio (MI)
#

package Uplug::CoocStat::MI;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return log(($s->{n11})/
		   (($s->{n11}+$s->{n10})*
		    ($s->{n11}+$s->{n01})))/log(2);
    }
}


#-----------------------------------------
# Kulczinsky Coefficient
#

package Uplug::CoocStat::Kulczinsky;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return ($s->{n11}/2)*
	    (1/($s->{n11}+$s->{n10})+1/($s->{n11}+$s->{n01}));
    }
}



#-----------------------------------------
# Ochiai Coefficient
#

package Uplug::CoocStat::Ochiai;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return ($s->{n11})/
	    (sqrt(($s->{n11}+$s->{n10})*($s->{n11}+$s->{n01})));
    }
}



#-----------------------------------------
# Yule Coefficient
#

package Uplug::CoocStat::Yule;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return ($s->{n11}*$s->{n00}-$s->{n10}*$s->{n01})/
	    (($s->{n11}*$s->{n00})+($s->{n10}*$s->{n01}));
    }

}


#-----------------------------------------
# McConnoughy Coefficient
#

package Uplug::CoocStat::McConnoughy;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return ($s->{n11}**2-$s->{n10}*$s->{n01})/
	    (($s->{n11}+$s->{n10})*($s->{n11}+$s->{n01}));
    }
}


#-----------------------------------------
# Simple Matchink Coefficient
#

package Uplug::CoocStat::Simple;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){
	return ($s->{n11}+$s->{n10})/
	    ($s->{n11}+$s->{n10}+$s->{n01}+$s->{n00});
    }
}


#-----------------------------------------
# Chi2
#
# taken from nsp (Ted Pedersen)
#

package Uplug::CoocStat::Chi2;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::Phi );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){

	my $m11 = $s->{n1x} * $s->{nx1} / $s->{nxx};
	my $m12 = $s->{n1x} * $s->{nx0} / $s->{nxx};
	my $m21 = $s->{n0x} * $s->{nx1} / $s->{nxx};
	my $m22 = $s->{n0x} * $s->{nx0} / $s->{nxx};

	my $Xsquare = 0;
	if ($m11 == 0 || $m12 == 0 || $m21 == 0 || $m22 == 0){return undef;}

	$Xsquare += ( ( $s->{n11} - $m11 ) ** 2 ) / $m11;
	$Xsquare += ( ( $s->{n10} - $m12 ) ** 2 ) / $m12;
	$Xsquare += ( ( $s->{n01} - $m21 ) ** 2 ) / $m21;
	$Xsquare += ( ( $s->{n00} - $m22 ) ** 2 ) / $m22;

	return $Xsquare;
    }
}


#-----------------------------------------
# mututal information
#
# taken from nsp (Ted Pedersen)
#

package Uplug::CoocStat::I;
use vars qw(@ISA); @ISA = qw( Uplug::CoocStat::LL );

sub compute{
    my $s=shift;
    if ($s->SUPER::compute(@_)){

	my $m11 = $s->{n1x} * $s->{nx1} / $s->{nxx};
	my $m12 = $s->{n1x} * $s->{nx0} / $s->{nxx};
	my $m21 = $s->{n0x} * $s->{nx1} / $s->{nxx};
	my $m22 = $s->{n0x} * $s->{nx0} / $s->{nxx};

	my $tmi=0;
	$tmi += $s->{n11}/$s->{nxx} * log ( $s->{n11} / $m11 ) / log 2;
	$tmi += $s->{n10}/$s->{nxx} * log ( $s->{n10} / $m12 ) / log 2;
	$tmi += $s->{n01}/$s->{nxx} * log ( $s->{n01} / $m21 ) / log 2;
	$tmi += $s->{n00}/$s->{nxx} * log ( $s->{n00} / $m22 ) / log 2;
	return $tmi;
    }
    return undef;
}


1;

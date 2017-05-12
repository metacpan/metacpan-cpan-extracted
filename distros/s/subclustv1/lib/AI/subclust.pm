package AI::subclust;

use vars qw/$VERSION/;
use strict;
$VERSION = '1.0'; 


my %attributes = (  ##Attributes
	-data   	  => undef,
	-bounds		  => undef,
	-ra		  => 0.5,
	-rb		  => 0.6,
	-acceptLimit   	  => 0.5,  ## fifty porcent of max potencial value 
	-vervose   	  => 0, 
);

sub new{
my ($proto,%variables) = @_;	  
	my $class= ref($proto) || $proto;
	my $self = {
		_permited => \%attributes,
		%attributes,
	};
	bless ($self, $class);
	die "Lost subclust Parameters" if (!exists $variables{-data});
	foreach(keys(%variables)){$self->{$_}=$variables{$_};}
return $self;
}

sub calculate(){
	my $self = shift;
	my $K = scalar(@{$self->{-data}});    ##retrive rows 
	my $N = scalar(@{$self->{-data}[0]}); ##retrive columns
	my (@minX,@maxX);
	if(scalar($self->{-bounds}) == 0){
	#no data scaling range values are specified, use the actual minimum and
	#maximum values of the data for scaling the data into a unit hyperbox
		@minX = min($self,$N,$K);
		@maxX = max($self,$N,$K);
	}else{
		@minX = @{$self->{-bounds}[0]};
		@maxX = @{$self->{-bounds}[1]};
	}
	my (@Dk,@CLUS);
	for my $k (0..$K-1){
		
		for my $j (0..$K-1){
			my $dist=0;
			for my $x (0..$N-1){	 
				$dist += ($self->{-data}[$k][$x]-$self->{-data}[$j][$x])**2;
			}
			$Dk[$k] += exp(- sqrt($dist)/($self->{-ra}/2)**2);	
		}
							
	}
		print join("\n",@Dk)."\n" if $self->{-vervose};
	##First Loop;
	
	my ($Dkmax,$KCl,@Dkp) = _ClusterCalc($self,$N,$K,@Dk);
	push(@CLUS,$KCl);
	my $Potenciallimit = $Dkmax * $self->{-acceptLimit};
		print "Limit: ".$Potenciallimit. "\n" if $self->{-vervose};
		#print join("\n",@Dkp)."\n" if $self->{-vervose};
		print "Potencial: ".$Dkmax." Data:<".$KCl.">\n" if $self->{-vervose};
	my $endflag = 1;
	my @Dkin = @Dkp;
	while($endflag){ 	
		my ($Dkmaxp,$KClp,@Dkp) = _ClusterCalc($self,$N,$K,@Dkin);
		last if $Dkmaxp == 0;
		
		print "Potencial: ".$Dkmaxp." Data:<".$KClp.">\n" if $self->{-vervose};	
		$endflag = 0 if $Dkmaxp < $Potenciallimit;
		if($endflag == 1){
			push(@CLUS,$KClp);
			@Dkin = @Dkp;			
		}
	}
	#Compute the sigma values for the clusters
	my @sigmas;
	for my $x (0..$N-1){
		$sigmas[$x] = ($self->{-ra} * ($maxX[$x] - $minX[$x])) / sqrt(8.0);
	}
	return(\@CLUS,\@sigmas); 
}

sub _ClusterCalc{
	my ($self,$N,$K,@Dk)= @_;
	
	my $Dkmax = 0;
	my $KCl; ##position of the cluster
	for my $k (0..$K-1){
			if($Dkmax < $Dk[$k]){
				$Dkmax= $Dk[$k];
				$KCl = $k;
			}
	}		
	my @Dkp; 
	for my $k (0..$K-1){
		my $dist=0;	
		for my $x (0..$N-1){
			$dist += ($self->{-data}[$k][$x]-$self->{-data}[$KCl][$x])**2;
		}	 
		$Dkp[$k]= $Dk[$k] - $Dkmax*exp(- sqrt($dist)/($self->{-rb}/2)**2);	
	}
	return ($Dkmax,$KCl,@Dkp);
}

sub min{
	my ($self,$N,$K)= @_;
	my @min = @{$self->{-data}[0]};
	for my $x (0..$N-1){
		for my $k (0..$K-1){
			if($min[$x] > $self->{-data}[$k][$x]){
				$min[$x] = $self->{-data}[$k][$x];			
			}
		}
	}
	return (@min);
}
sub max{
	my ($self,$N,$K)= @_;
	my @max = @{$self->{-data}[0]};
	for my $x (0..$N-1){
		for my $k (0..$K-1){
			if($max[$x] < $self->{-data}[$k][$x]){
				$max[$x] = $self->{-data}[$k][$x];			
			}
		}
	}
	return (@max);
}
1;

__END__	

=pod

=head1 NAME

AI::subclust - A module to implement substractive clustering algorithm.

=head1 SYNOPSYS

    use AI::subclust;

    my @Data  = [[qw/0.3 0.5/],[qw/0.3 0.6/],[qw/0.6 0.8/],[qw/0.02 0.6/]];
    my @bound = [[qw/0 0/],[qw/1 1/]];
    
    my $subC = new AI::subclust(-data=>@Data,-bounds=>@bound);

    my ($CLU,$S) = $subC->calculate();

=head1 DESCRIPTION

This module implements a substractive clustering algorithm. 

=head1 PUBLIC METHODS

The module has the following public methods:

=over *

=item new()

This is the constructor. It have to be defined only -data paramater obligatorily any other has an default value.

$subC = new subclust(	-data => @Data,
		     -bounds => @bounds,
		     -ra => 0.5,
		     -rb => 0.6,
		     -acceptLimit => 0.5,  
		     -vervose => 0, 
		    );

=over 6

=item -data

Input data array.

=item -bounds

Scale array. It is a 2xN dimension array.
Use default valueas @max and @min arrays calculated from @Data

=item -ra  

Radio of the hypercube selected for each cluster.
Use default value as 0.5

=item -rb    

Radio of rejection for each cluster.        
Use default value as  0.6

=item -acceptLimit  

Minimal value of Potencial required to be center of cluster.  
Use default value as 0.5  

=item -vervose 

Vevose mode. 1 activated or 0 desactivated.      
Use default value as 0

=back

=item calculate()

This method is used to calculate substractive algorithm. Just 
call method in this way

($CLU,$S) = $subC->calculate();

Method retrieve two array references, following with above example:
$CLU represent an cluster position array reference
$S   represent sigma value array reference of each variable (Matlab style).

=back

=head1 AUTHOR 

Copyright 2004, Jorge Courett. All rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please send me any comments to: courett@softhome.net

=cut
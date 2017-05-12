package Combine::GraphAlgorithm;

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self =  {};
    $self->{NumberNodes}=0;
    $self->{Nodes} = {}; # a hash with all nodes
      #each node will have 2 lists (possibly empty): inlinks and outlinks
      #  and possibly a topic score associated: score
    bless ($self , $class);
    return $self;
}

sub addLink {
    my ($self,$fromnode, $tonode, $weight) = @_;
#    if ($fromnode == $tonode) { warn "No selflinking!"; return; }
#    if (!defined($self->{Nodes}->{$fromnode})) {
    if (! defined($weight)) { $weight = 1.0; }
#fails if link $from -> $to already added!!!
    push(@{$self->{Nodes}->{$fromnode}->{outlinks}}, $tonode);
    push(@{$self->{Nodes}->{$tonode}->{inlinks}}, $fromnode);
    ${$self->{Nodes}->{$fromnode}->{relevance}}{$tonode} += $weight;
}

sub setScore {
    my ($self,$node,$score) = @_;
    $self->{Nodes}->{$node}->{score} = $score;
}

sub nodes {
    my ($self) = @_;
    return keys(%{$self->{Nodes}});
}

sub outDegree {
    my ($self,$node) = @_;
    my @n = @{$self->{Nodes}->{$node}->{outlinks}};
    return $#n+1;
}

sub inDegree {
    my ($self,$node) = @_;
    my @n = @{$self->{Nodes}->{$node}->{inlinks}};
    return $#n+1;
}

sub hasScore {
    my ($self,$node) = @_;
    return defined($self->{Nodes}->{$node}->{score});
}

sub getScore {
    my ($self,$node) = @_;
    if ( defined($self->{Nodes}->{$node}->{score}) ) {
	return $self->{Nodes}->{$node}->{score};
    } else {return 0; }
}

sub deleteNode {
    my ($self,$node) = @_;
    delete($self->{Nodes}->{$node}->{outlinks});
    my @l = $self->linkedToBy($node);
    foreach my $n (@l) {
      #walk through list of nodes that link to me and remove my node
	my @links = $self->linksTo($n);
	@{$self->{Nodes}->{$n}->{outlinks}} = ();
	foreach my $l (@links) {
	    if ($l != $node) { push(@{$self->{Nodes}->{$n}->{outlinks}},$l); }
	}
    }
    delete($self->{Nodes}->{$node}->{inlinks});
    delete($self->{Nodes}->{$node}->{score});
    delete($self->{Nodes}->{$node}->{relevance});
    delete($self->{Nodes}->{$node});
}

sub linksTo {
    my ($self,$node) = @_;
    return @{$self->{Nodes}->{$node}->{outlinks}};
}

sub linkedToBy {
    my ($self,$node) = @_;
    return @{$self->{Nodes}->{$node}->{inlinks}};
}

sub addBackLinks {
    my ($self) = @_;
    my @pages = $self->nodes();
    foreach my $i (@pages) {
	my @backlinks = $self->linkedToBy($i);
	my @links = $self->linksTo($i);
	my %li = ();
	foreach my $l (@links) { $li{$l}=1; } #To detect duplicates
	foreach my $l (@backlinks) {
	    #$l is a backlink for $i
	    #use score divided by total no of backlinks as weight
            #what if link already exists?
	    if (!defined($li{$l})) {
		push(@{$self->{Nodes}->{$i}->{outlinks}}, $l);
	    }
	    ${$self->{Nodes}->{$i}->{relevance}}{$l} += $self->getScore($l)/($#backlinks+1);
	}
    }
}

sub PageRank {
    my ($self,$rmDang, $Bias) = @_;
    # Parameters
    # $rmDang (boolean) remove dangling pages NOT USED
    # $Bias (boolean) use bias vector when calculating PageRank
    # $d1 is an Graph object that contains bias vector as attribute
    #     to the vertices. May be modified by this subroutine!

    # Using algorithm (1) The Power method from "Deeper Inside PageRank"

    my @pages;
    my $n;
    my $i;

    my %Ri; #The pageRank vector (x(k?)T)
    my %Ri1;#The pageRank vector (x(k?)T)
    my %Ei; #Topical (personalization) vector (vT in alg)
    my $d = 0.85; #The alpha param

    @pages = $self->nodes();
    my $npages = $#pages + 1;
    print "Got $npages nodes\n";
    ########

    if ( $Bias ) {
        #Init Ei with autoclass scores
        #  maintain sum(Ei) == 1
	print "Initializing bias vector\n";
	my $totscore=0;
	foreach $i (@pages) {
	    $totscore += $self->getScore($i); 
	}
	$normconst = 1.0/$totscore;
	print "Using $normconst as normalization factor; Tot=$totscore\n";
	my $riNorm=0.0;
	foreach $i (@pages) {
	    $Ei{$i}=0.0;
	    $Ri{$i}=0.0;
	    if ( $self->hasScore($i) ) {
		$Ei{$i} = $self->getScore($i) * $normconst;
#		$Ri{$i}=1.0/$npages; #Uniform starting PageRank vector
		$Ri{$i}=$Ei{$i}; # Topic-score starting PageRank vector
	    } else { print "WARN node $i has no score\n"; }
	}
	my $eisum; foreach $i (@pages) { $eisum +=    $Ei{$i}; }
	print "EiSUM = $eisum\n";
	my $risum; foreach $i (@pages) { $risum +=    $Ri{$i}; }
	print "RiSUM = $risum\n";
    } else {
	#Uniform normalization (so that sum(Ei) = 1)
	foreach $i (@pages) { $Ri{$i}=1.0/$npages; $Ei{$i}= 1.0/$npages;}
    }

#Normalize relevance weights
    foreach $i (@pages) {
	# $i links to $l
	my $nlinks=$self->outDegree($i);
	if ($nlinks==0) {
	    next;
	}
	my @links = $self->linksTo($i); #Sparse P matrix
	my $sum=0.0;
	foreach my $l (@links) {
	    $sum += ${$self->{Nodes}->{$i}->{relevance}}{$l};
        }
#    print "Node $i: SUM=$sum\n";
        foreach my $l (@links) {
	    ${$self->{Nodes}->{$i}->{relevance}}{$l} = ${$self->{Nodes}->{$i}->{relevance}}{$l} / $sum;
            $r = ${$self->{Nodes}->{$i}->{relevance}}{$l};
#            print "  link to $l relevance=$r\n";
        }
    }

    my $loops=0;
    my $lenDelta = 1.0;
    my $Ri1sum;
    while ( ($lenDelta > 0.0000001) ) {
	$loops++;
	my $dangContr=0.0; # the term x(k-1)T*a
	foreach $i (@pages) {
	    # $i links to $l
	    my $nlinks=$self->outDegree($i);
	    if ($nlinks==0) {
		$dangContr += $Ri{$i};
		next;
	    }
	    my @links = $self->linksTo($i); #Sparse P matrix
#	    $mcontr = $Ri{$i}/($nlinks); #Uniform probability for all links
	    foreach my $l (@links) {
		#nonuniform jump probability
		my $mcontr = $Ri{$i} * (${$self->{Nodes}->{$i}->{relevance}}{$l});
		$Ri1{$l} += $mcontr; # x(k-1)T*P
#print "  Adding $mcontr to node $l making sum=$Ri1{$l}\n";
	    }
	}

	$Ri1sum=0.0;
	$lenDelta=0.0;
	foreach $i (@pages) {
	    my $tmp = $Ri{$i}; #Old PageRank
	    $Ri{$i} = $d * $Ri1{$i} + ($d * $dangContr + (1.0-$d))*$Ei{$i};
	    $Ri1sum += $Ri{$i};
	    $lenDelta = ($Ri{$i} - $tmp) * ($Ri{$i} - $tmp); #Euclidian length
	    $Ri1{$i}=0.0;
	}
	$lenDelta = sqrt($lenDelta);
#	print "Difference lenDelta=$lenDelta; Ri1sum=$Ri1sum\n";
    } #end while
    print "LOOPS: $loops; Convergence lenDelta=$lenDelta; Ri1sum=$Ri1sum\n";
    return %Ri;
}
#################
sub PageRankBL {
    my ($self,$rmDang, $Bias) = @_;
    # Parameters
    # $rmDang (boolean) remove dangling pages NOT USED
    # $Bias (boolean) use bias vector when calculating PageRank
    # $d1 is an Graph object that contains bias vector as attribute
    #     to the vertices. May be modified by this subroutine!

    # Using algorithm (1) The Power method from "Deeper Inside PageRank"
    # But doing calculations on backlinks only

    my @pages;
    my $n;
    my $i;

    my %Ri; #The pageRank vector (x(k?)T)
    my %Ri1;#The pageRank vector (x(k?)T)
    my %Ei; #Topical (personalization) vector (vT in alg)
    my $d = 0.85; #The alpha param

    @pages = $self->nodes();
    my $npages = $#pages + 1;
    print "Got $npages nodes\n";
    ########

    if ( $Bias ) {
        #Init Ei with autoclass scores
        #  maintain sum(Ei) == 1
	print "Initializing bias vector\n";
	my $totscore=0;
	foreach $i (@pages) {
	    $totscore += $self->getScore($i); 
	}
	$normconst = 1.0/$totscore;
	print "Using $normconst as normalization factor; Tot=$totscore\n";
	my $riNorm=0.0;
	foreach $i (@pages) {
	    $Ei{$i}=0.0;
	    $Ri{$i}=0.0;
	    if ( $self->hasScore($i) ) {
		$Ei{$i} = $self->getScore($i) * $normconst;
#		$Ri{$i}=1.0/$npages; #Uniform starting PageRank vector
		$Ri{$i}=$Ei{$i}; # Topic-score starting PageRank vector
	    } else { print "WARN node $i has no score\n"; }
	}
	my $eisum; foreach $i (@pages) { $eisum +=    $Ei{$i}; }
	print "EiSUM = $eisum\n";
	my $risum; foreach $i (@pages) { $risum +=    $Ri{$i}; }
	print "RiSUM = $risum\n";
    } else {
	#Uniform normalization (so that sum(Ei) = 1)
	foreach $i (@pages) { $Ri{$i}=1.0/$npages; $Ei{$i}= 1.0/$npages;}
    }

#Normalize relevance weights
    foreach $i (@pages) {
	# $i links to $l
	my $nlinks=$self->outDegree($i);
	if ($nlinks==0) {
	    next;
	}
###	my @links = $self->linksTo($i); #Sparse P matrix
	my @links = $self->linkedToBy($i); #Sparse P matrix
	my $sum=0.0;
	foreach my $l (@links) {
	    $sum += ${$self->{Nodes}->{$l}->{relevance}}{$i};
        }
#    print "Node $i: SUM=$sum\n";
        foreach my $l (@links) {
	    ${$self->{Nodes}->{$l}->{relevance}}{$i} = ${$self->{Nodes}->{$l}->{relevance}}{$i} / $sum;
            $r = ${$self->{Nodes}->{$l}->{relevance}}{$i};
#            print "  link to $l relevance=$r\n";
        }
    }

    my $loops=0;
    my $lenDelta = 1.0;
    my $Ri1sum;
    while ( ($lenDelta > 0.0000001) ) {
	$loops++;
	my $dangContr=0.0; # the term x(k-1)T*a
	foreach $i (@pages) {
	    # $i links to $l
###	    my $nlinks=$self->outDegree($i);
	    my $nlinks=$self->inDegree($i);
	    if ($nlinks==0) {
		$dangContr += $Ri{$i};
		next;
	    }
###	    my @links = $self->linksTo($i); #Sparse P matrix
	    my @links = $self->linkedToBy($i); #Sparse P matrix
#	    $mcontr = $Ri{$i}/($nlinks); #Uniform probability for all links
	    foreach my $l (@links) {
		#nonuniform jump probability
		my $mcontr = $Ri{$i} * (${$self->{Nodes}->{$l}->{relevance}}{$i});
		$Ri1{$i} += $mcontr; # x(k-1)T*P
#print "  Adding $mcontr to node $l making sum=$Ri1{$l}\n";
	    }
	}

	$Ri1sum=0.0;
	$lenDelta=0.0;
	foreach $i (@pages) {
	    my $tmp = $Ri{$i}; #Old PageRank
	    $Ri{$i} = $d * $Ri1{$i} + ($d * $dangContr + (1.0-$d))*$Ei{$i};
	    $Ri1sum += $Ri{$i};
	    $lenDelta = ($Ri{$i} - $tmp) * ($Ri{$i} - $tmp); #Euclidian length
	    $Ri1{$i}=0.0;
	}
	$lenDelta = sqrt($lenDelta);
#	print "Difference lenDelta=$lenDelta; Ri1sum=$Ri1sum\n";
    } #end while
    print "LOOPS: $loops; Convergence lenDelta=$lenDelta; Ri1sum=$Ri1sum\n";
    return %Ri;
}
#################

sub printProbMatrix {
    my ($self)=@_;
    my %P;
    foreach my $i ($self->nodes()) {
	foreach my $j ($self->nodes()) {
	    $P{$i}{$j}=0;
	}
    }
    foreach my $i ($self->nodes()) {
	foreach my $j (@{$self->{Nodes}->{$i}->{outlinks}}) {
#	    $P{$i}{$j}=1;
	    $P{$i}{$j}=${$self->{Nodes}->{$i}->{relevance}}{$j};
	}
    }
    print "P: ";
    foreach my $i ($self->nodes()) { print "$i "; }
    print "\n";
    foreach my $i ($self->nodes()) {
	print "$i: ";
	foreach my $j ($self->nodes()) {
	    my $p=$P{$i}{$j};
	    print "$p ";
	}
	print "\n";
    }
}

sub HITS {
    my ($Graph) = @_;

    my $k=5;
    my %x;
    my %y;
    my @pages = $Graph->vertices;
    #Evt initialize to rscore?
    foreach $p (@pages) { $x{$p}=1; $y{$p}=1; }
    my %yp;

    foreach $i (0..$k) {
    #I operation
        print "    #I operation\n";
	my %xp;
	foreach $p (@pages) {
	    $w=0;
	    @q = $Graph->predecessors($p);
	    foreach $q (@q) { $xp{$p} += $y{$q}; }
##	    foreach $q (0..$n) {
##		if ( $links{$q,$p} ) { $w += $y[$q]; }
##	    }
##	    $xp[$p]=$w;
##

	}
	#O operation
            print "    #O operation\n";
	my %yp;
	foreach $p (@pages) {
	    @q = $Graph->successors($p);
	    foreach $q (@q) { $yp{$p} += $xp{$q}; }
##	$w=0;
##	foreach $q (0..$n) {
##	    if ( $links{$p,$q} ) { $w += $xp[$q]; }
##	}
##	$yp[$p]=$w;

	}
	%x = Normalize(%xp);
	%y = Normalize(%yp);
#	&PrProgress($i);
    }
    my %HITS;
    foreach $i (keys(%x)) {
	$HITS{$i}{AUTH}=$x{$i};
	$HITS{$i}{HUB}=$y{$i};
	delete($y{$i});
    }
    foreach $i (keys(%y)) {
	$HITS{$i}{HUB}=$y{$i};
    }
    return %HITS;
}

sub Normalize {
    my (%arr) = @_;
    my $sum = 0.0;
    foreach my $v (keys(%arr)) { $sum += $arr{$v}*$arr{$v}; }
    my $nv = sqrt($sum);
#    print "Norm: NV=$nv; #=$#_\n";
    my %xn;
    foreach my $v (keys(%arr)) {
	$xn{$v} = $arr{$v}/$nv;
    }
    return %xn;
}
##################

sub PrProgress {
    ($it) = @_;
    my %TMx;
    my %TMy;
    print "Status iteration $it\n";
    foreach my $ii (0..$n) {
	if ($x[$ii]>0.001) {$TMx{$ii}=$x[$ii];}
	if ($y[$ii]>0.001) {$TMy{$ii}=$y[$ii];}
    }
    my $ant=0;
    foreach $ii (sort {$TMx{$b} <=> $TMx{$a};} keys(%TMx)) {
	print "X($ant): $TMx{$ii} $ii $urls[$ii]\n";
	last if ($ant++>10);
    }
    $ant=0;
    foreach $ii (sort {$TMy{$b} <=> $TMy{$a};} keys(%TMy)) {
	print "Y($ant): $TMy{$ii} $ii $urls[$ii]\n";
	last if ($ant++>10);
    }
}


############
1;

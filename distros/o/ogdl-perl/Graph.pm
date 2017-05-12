# Graph.pm
# This class implements a nested named list.
# author 'Rolf Veen'
# license zlib
# date 20030609
# Modified by Hui Zhou <zhouhui@wam.umd.edu>

package OGDL::Graph;

use strict;
use warnings;


use OGDL::Path;

sub new {
   my ($class,$name)=@_;
   my $rec = {
      parent=>undef,
      name => $name,
      list => [ () ]
   };
#   print "New Graph node: [$name]\n";
   return bless $rec,$class;
}

#$g->addGraph($name); append node with name=$name
sub addGraph {
   my ($self,$name) = @_;
   my $n=OGDL::Graph->new($name);
   $self->addNode($n);
   return $n;
}
#$g->addNode($sub); append node to the end 
sub addNode {
   my ($self,$node) = @_;
   my $list = $self->{list};
   my $len = @$list;
   $node->{parent}=$self;
   $self->{list}[$len] = $node;
#   print "Adding node: [",$node->{name},"]\n";
}

sub merge{
   my ($self,$node)=@_;
   my $list1=$self->{"list"};
   my $list2=$node->{"list"};
   if(!$list2){return;}
   push @$list1, @$list2;
}

sub unlink{
   my $node=shift;
   my $parent=$node->{"parent"};
   $node->{"parent"}=undef;
   my $j=0;
   my $l=$$parent{"list"};
   while($j<=$#$l){
      if($$l[$j]==$node){
	splice @$l,$j,1;
	return;
      }
      $j++;
   }
}

sub getname{
    my $node=get(@_);
    if(!$node){return undef;}
    return $$node{"name"};
}

sub childrencount{
    my  $g=shift;
    my $list=$$g{"list"};
    return scalar @$list;
}

sub getChildren{
    my  $g=shift;
    my $list=$$g{"list"};
    return @$list;
}

sub isempty{
    my $g=shift;
    my $l=$$g{"list"};
    return (! scalar(@$l));
}
 
sub clear{
    my $g=shift;
    my $l=$$g{"list"};
    foreach(@$l){
	$_->{"parent"}=undef;
    }
    $$g{"list"}=[ () ];
}

#Not sure how  to deal with the order
#sub diff{
#    my ($g1,$g2)=@_;
#    my ($pg1,$pg2);
#}

sub listmatch{
    my ($g,$list,$rnum,@path)=@_;
    my $inum=-1; #match all index
    my $namepat;
    my $pat=shift @path;
    if($pat=~/(.*)(\[(\d*)\])/){
	if($3 eq ""){$inum=-1;}
	else{$inum=$3;}
	if($1 eq ""){$namepat="^*\$";}
	else{$namepat="^$1\$";}
    }
    else{
	$inum=-1;
	$namepat="^$pat\$";
    }
    $namepat=~s/\*/\.\*/g;
    $namepat=~s/\?/\./g;
    $inum++;
	
#    print "listmatch ",$$g{"name"},"=~$namepat\n";
    if($$g{"name"}=~/$namepat/){
	$$rnum=$$rnum+1;
#	print "Match: ",$$rnum,", $inum, (",$#path,")\n";
        if($inum>0 && $$rnum!=$inum){ #index doesn't match
	    return undef;
	}
	if($#path==-1){
#	    print "Matched\n";
	    {push @$list,$g;return 1;} #matches finally
	}
	my $n=0;
	my $l=$g->{list};
	foreach(@$l){
	    $_->listmatch($list,\$n,@path);
	}
    }
}

sub glist{
    my @list;
    my ($g,$pathstr)=@_;
    my @path=splitPath($pathstr);
    if($#path<0){push @list,$g;return @list;}
    unshift @path,"*";
    my $n=0;
#   my $j=0; foreach(@path){print "$j:[$_],";$j++;}print "\n";
    listmatch($g,\@list,\$n,@path);
    return @list;
}

sub removematch{
    my ($g,$list,@path)=@_;
    my $inum=-1; #match all index
    my $namepat;
    my $pat=shift @path;
    if($pat=~/(.*)(\[(\d*)\])/){
	if($3 eq ""){$inum=-1;}
	else{$inum=$3;}
	if($1 eq ""){$namepat="^*\$";}
	else{$namepat="^$1\$";}
    }
    else{
	$inum=-1;
	$namepat="^$pat\$";
    }
    $namepat=~s/\*/\.\*/g;
    $namepat=~s/\?/\./g;
    if($inum>=0){$inum++;}
	
    my $j=0;
    my $num=0;
    my $l=$g->{"list"};
    my $n=$$l[$j];
    while($n){
#        print "removematch ",$$n{"name"},"=~/$namepat/\n";
	if($$n{"name"}=~/$namepat/){
	    $num++;
#	    print "Match :$num, $inum\n";
	    if($inum>=0 && $num!=$inum){ #index doesn't match
		$j++;
	    }
	    else{
   {my $j=0; foreach(@path){print "$j:[$_],";$j++;}print "\n";}
		if($#path==-1){
		    push @$list,$n;
		    splice(@$l,$j,1);
		    if($inum>=0){ last; }
		    else{
			$num++;
		    }
		}
		else{
		    removematch($n,$list,@path);
		    if($inum>=0){last;}
		    $j++;
		}
	    }
	}
	else{
	    $j++;
	}
	$n=$$l[$j];
    }
}

sub gremove{
    my ($g,$pathstr)=@_;
    my @path=splitPath($pathstr);
    if($#path<0){unshift @path,"*";}
    my @list;
    if($#path<0){return $g;}
    removematch($g,\@list,@path);
    return @list;
}

sub gmove{
    my ($g,$from,$to)=@_;
    my @frompath=splitPath($from);
    my @topath=splitPath($to);
    my @remove=gremove($from);
    foreach (@remove){
	addmatch($g,$_,@topath);
    }
}

sub addmatch{
    my ($g,$node,@path)=@_;
    if($#path<0){
	if($node){
	    $g->clear;
	    $g->addNode($node)
	};
	return;
    }
    my $inum=-1; #match all index
    my $uniq=1;
    my $namepat;
    my $pat=shift @path;
    if($pat=~/(.*)(\[(\d*)\])/){
	if($3 eq ""){ $uniq=0;$inum=-1;}
	else{$inum=$3;}
	if($1 eq ""){$namepat="*";}
	else{$namepat="$1";}
    }
    else{
	$namepat="$pat";
    }
    if($namepat=~/[*?]/){
	$namepat=~s/\*/\.\*/g;
	$namepat=~s/\?/\./g;
	$uniq=0;
    }
    if($inum>=0){$inum++;}
	
    my $j=0;
    my $num=0;
    my $n=$g->{list}[$j];
    my $exist=0;
    while($n){
#        print "addmatch ",$$n{"name"},"=~/^$namepat\$/\n";
	if($$n{"name"}=~/^$namepat$/){
	    $num++;
#	    print "Match: $num, $inum\n";
	    if($inum<0 || $num==$inum){ # match
		$exist=1;
		addmatch($n,$node,@path);
	    }
	}
	$j++;
	$n=$g->{list}[$j];
    }
    if(!$exist && $uniq){
#        print "Add $namepat?\n";
        $j=$num;
	if($inum<0){$inum=1;}
	while($j<$inum){
	    $n=OGDL::Graph->new($namepat);
	    $g->addNode($n);
	    $j++;
#	    print "Added node [$namepat]\n";
	}
	addmatch($n,$node,@path);
    }
}

sub gadd{
    my ($g,$pathstr,$str)=@_;
    my @path=splitPath($pathstr);
#    my $j=0;foreach(@path){print "$j:[$_],";$j++;}print "\n";
    my $node=undef;
    if($str){
	$node=OGDL::Graph->new($str);
    }
    addmatch($g,$node,@path);
}

# g->add(path, string)
# doesn't work with numeric indices
sub add
{
    my ($g,$path,$string)=@_;
    my $n=$g->get($path);
    return $n->addGraph($string);
}

#$g->getNode($index); return subnode by index
sub getNode {
   my $self = shift;
   return $self->{list}[$_[0]];
}

sub getNodeByName {
   my $self = shift;
   my $name = shift;
  
   my $list = $self->{list};
   my $i=0;
   
   for (@$list) {  
       if ($_->{name} eq $name)
           { return $i; }
       $i++; 
   }
   return -1;
}

# look for the nth ocurrence of a name

sub getNodeByNameN {
   my $self = shift;
   my $name = shift;
   my $n = shift;

   my $list = $self->{list};
   my $i=0;
   
   for (@$list) {  
       if ($_->{name} eq $name) {
           if ($n-- == 0)
               { return $i; }
       }
       $i++; 
   }
   return -1;
}

# make a new Graph with all nodes with given name.

sub newGraphByName {
   my $self = shift;
   my $name = shift;
   my $list = $self->{list};
   my $i=0;
   my $g = OGDL::Graph->new($name);
   my $list2;
   
   for (@$list) {  
       if ($_->{name} eq $name) {
           $list2=$_->{list};
           for (@$list2) {
               $g->addNode($_);
           }
       }
       $i++; 
   }   
   return $g;
}

sub get
{
    my $self = shift;
    my @path = OGDL::Path::path2list(shift);
    my $node = $self;
    my $i=0;
    my $prev;   # to distinguish between x[n] and x.[n] and hold the
                # previous node
    
    for (@path) {       
        if ( !$_ && $_ ne '0') { last; }     # Whose bug is this ?
        
        if ($_ eq ".") { $prev=""; next; }

        # [n]?
	if(/\[(\d*)\]/){
#        if ( substr($_,0,1) eq '[') {
#            $i = 0 + substr($_,1,100);     # get the numeric index
            if($1 eq ""){$i=0;}
	    else{$i=$1;}
            
            # if prev & i>0 then we must look for ith ocurrence
            # of prev
            
            # if prev & i==0 then we group all nodes with the same name
            # as $node->{name} in a new Graph and continue from there.
            
            if ( $prev ) {
                if ( $i > 0 ) {
                    $i = $prev->getNodeByNameN($node->{name},$i);
                    $node = $prev->getNode($i);
                    $prev = 0;
                    next;
                }
                elsif ( $i == 0 ) {                
                    $node = $prev->newGraphByName($node->{name});
                    $prev = 0;
                    next;
                }
                else { $i = -1; }
            }
        }
        else {
            $i = $node->getNodeByName($_);
        }
        
        if ($i == -1) { return undef; }
        $prev = $node;
        $node = $node->getNode($i);
    }                  
 
    return $node;
}

sub getGraph
{
    return get(@_);
}

sub getScalar
{
    my $node = get(@_);
    if ($node) {
        $node = $node->{list}[0];
        if ($node) 
            { return $node->{name}; }
    }
    return undef;
}


#_print_str($name,$indent,$pending,$blockquote,$noquote,*FILE)
sub _print_str 
{
    my ($s,$n,$pending,$blockquote,$noquote,$sameline,$output)=@_;
    #$pending = $_[2]; #Whether continuing at previous line or starting at begining of new line
    #$blockquote=$_[3]; #Whether use \ quote or " quote
    # see what type of string it is: word, quoted or block
    if ($s =~ /[ \n\r]/) {#block
	if($blockquote && $pending){
	    print $output " \\\n";
	    my $c;
	    my $pend=1;
	    print $output ' ' x $n; $pend = 0;
	    for (my $i=0;$i<length($s);$i++){
	        $c = substr($s,$i,1) ;
#		if(!defined $c) {last;}
		if ( $pend == 1 ) { print $output ' ' x $n; $pend = 0;}
		if ($c eq "\n") {
		    $pend = 1;
		}
		print $output $c;
	    }
	    if($pend){$pending = 0;}
	    else{$pending=1;}
	}
	else{ #use double quote block
	    if($pending){
		if($sameline){print $output ' ';}
		else{
		    print $output "\n";
		    print $output ' ' x $n;
		}
	    }
	    my $c;
	    my $i=0;
	    my $pend=0;
	    if(!$noquote){ print $output '"';$n++;} #Opening quote 
	    for (my $i=0;$i<length($s);$i++){
	        $c = substr($s,$i,1);
		if ( $pend == 1 ) { print $output ' ' x $n; $pend = 0;}
		if ($c eq "\n") {
		    $pend = 1;
		}
		elsif($c eq '"' && !$noquote) { print $output "\\"; } #Quote the quote
		print $output $c;
	    }
	    if(!$noquote){print $output '"'; }#Closing quote
	    $pending = 1;
	}
    }
    else {
        if ($pending == 1) { 
	    if($sameline){
		print $output ' ';
	    }
	    else{
		print $output "\n" ;
		print $output ' ' x $n;
	    }
	}
	else{
		print $output ' ' x $n;
	}
	print $output $s;
        $pending = 1;
    }
    return $pending;
}

#assuming it always start at $indentlevel==0
sub _print {
   use integer;
   my ($self,$output,$indentlevel,$indentwidth,$pending,$single,$singlequote,$noblockquote,$depth, $group)=@_;
   my $list = $self->{list};
   my @l = @$list;

   my $indent=$indentwidth*$indentlevel;
   my $blockquote=0;
   my $noquote=0;
   my $sameline=0;
   if($group==0){$sameline=1;}
   if (!$noblockquote && $single && $#l<0){$blockquote=1;}
   if (!$singlequote && $indentlevel==0 && $single && ($#l<0 ||$depth ==0)){$noquote=1;}#single node output
   $pending = _print_str($self->{name}, $indent, $pending,$blockquote,$noquote,$sameline,$output);
   if($#l==0){ 
	$single=1;
    }
    else{
	$single=0;
    }
   $indentlevel++;
   
   #negative $depth is equivalent to infinity depth
   $depth--;
   if($depth==0 || $#l<0){return $pending;}
   if($group>0){$group--;}
   if($group==0){$sameline=1;}
   if($sameline){
       if($#l>0){print $output " (";}
   }
   my $j=$#l;
   {
       foreach  my $g(@l){
	   $pending=$g->_print($output,$indentlevel,$indentwidth,$pending,$single,$singlequote,$noblockquote,$depth,$group);
	   if($sameline && $j>0){
	       print $output ",";
	       $j--;
	    }
       }
       if($sameline){
	   if($#l>0){print $output " )";}
       }
   }
   return $pending;
}

# arguments: A hash with keys: depth, indentwidth, filehandle, singlequote, printroot, noblockquote
sub print{
   my ($g,%params) = @_;
   my $list = $g->{list};
   my @l = @$list;
   my $singleblock=0;
   my $indentwidth=4;
   my $quote=0;
   my $depth=0;#infinity
   my $pending=0;
   my $noblockquote=0;
   my $output=*STDOUT;
   my $group=-1; #put all nodes after $group depth in one line
   if($params{"indentwidth"}){$indentwidth=$params{"indentwidth"};}
   if($params{"singlequote"}){$quote=$params{"singlequote"};}
   if($params{"filehandle"}){$output=$params{"filehandle"};}
   if($params{"depth"}){$depth=$params{"depth"};}
   if(exists $params{"group"}){$group=$params{"group"};}
   if($params{"noblockquote"}){$noblockquote=$params{"noblockquote"};}
   if(defined $params{printroot} and $params{"printroot"} eq "0"){
	$g=$list->[0];
	foreach my $g2(@$list){
	   my $indent=0;
	   $pending = $g2->_print($output,$indent,$indentwidth,0,1,$quote,$noblockquote,$depth,$group);
	   if ($pending) { print $output  "\n"; }
	}
    }
    else{
       my $indent=0;
       $pending = $g->_print($output,$indent,$indentwidth,0,1,$quote,$noblockquote,$depth,$group);
       if ($pending) { print $output  "\n"; }
    }
}

sub printnodes{
    my ($g,%params)=@_;
    my $list=$g->{list};
    foreach(@$list){
	$_->print(%params);
    }
}

sub dump{
    my ($g,$file,%params)=@_;
    $params{"quote"}=1;
    open my $fh, ">$file" or return 0;
    my $l=$g->{"list"};
    foreach(@$l){
	$_->print(%params,"filehandle"=>$fh);
    }
}


###############Path##############
sub splitPath{
    my $path=shift;
    my @paths;
    if(!defined $path || $path eq "" || $path eq "."){return @paths;}
    my $n=length($path);
    my $j=0;
    my $c;
    my $s="";
    while($j<$n){
	my $c=substr($path,$j,1);$j++;
	if($c eq '.' ){
	    push @paths,$s;
	    $s="";
	}
	elsif($c eq '\\'){
	    if($j==$n){$s=$s.$c;} 
	    else{
		$c=substr($path,$j,1);$j++;
		if($c eq '.'){$s=$s.$c;}
		else{$s=$s."\\$c";}
	    }
	}
	else{
	    $s=$s.$c;
	}
    }
    push @paths,$s;
    return @paths;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

OGDL::Graph - a class for manipulating a OGDL graph object

=head1 SYNOPSIS

  use OGDL::Graph;
  $g=OGDL::Graph->new("rootname");
  $g1=$g->addGraph("node1");
  $g2=$g->addGraph("node2");
  $g11=$g1->addGraph("subnode1");
  $g2->addNode($g11)

  #the following prints:
  #node1
  #    subnode1
  #node2
  #    subnode1
  $g->print;

  $q=$g->get("node1");
  #the following prints:
  #subnode1
  $q->print;

  $s=$g->getname("node1.[0]"); #$s eq "subnode1"
  
  @c=$g->getChildren; #@c now is ($g1, $g2)

  ## Editing the graph with paths
  $g->clear  # unlinks all the children nodes
  $g->gadd("node1.subnode1");
  $g->gadd("node2","subnode1"); #Recreates the above graph
  @nodes=$g->glist("*.subnode1"); #@nodes contains the two subnodes
  $g->remove("*2.*"); 
  $g->print;

  #it prints
  #node1
  #    subnode1
  #node2

=head1 DESCRIPTION

OGDL is a human editable alternative to XML. It embeds information
in the form of graphs, where the nodes are strings and the arcs or 
edges are spaces or indentations. This class facilitates the 
manipulation of ogdl graph.

=head1 METHOD

$g=OGDL::Graph->new($rootname)
    This method creates an empty graph with root node name $rootname.

$child=$g->addGraph($name)
    This method adds a subnode with name $name to $g as its last
    children node. It returns the new subnode that is added.

$node=$g->get($path)
    This method returns the node specified by $path. For the OGDL PATH
    specification, see: http://ogdl.sourceforge.net.

$str=$g->getname($path)
    This method returns the name of the node matches $path.

$n=$g->childrencount
    It returns the number of children nodes of $g.
    
@nodes=$g->getChildren
    It returns all the children nodes of $g as an array.

$node->unlink
    unlinks $node from the graph

$g->glist($path)
    Returns a list of nodes that matches $path

$g->gremove($path)
    Unlinks the nodes specified by $path from the graph

$g->gadd($path)
    Adds nodes to the graph that qualified by $path

$g->print(%print_options)
    It prints $g into a text stream. It accepts following options:
	"indentwidth" sets the indent width for each level, defaut
    is 4;
	"singlequote" sets whether to put quote around the text if 
    the output only contains a single node, default is not to put 
    quote;
	"filehandle" sets the filehandle the output goes to. The 
    default goes to STDOUT;
    	"depth" sets how many level of subnodes to print. The default
    is -1, which prints all subnodes.
    	"group"=>n prints all nodes below level n into one line. 
    The default prints each node in a single line.
	"noblockquote"=>1 prints all nodes that require quoting 
    with doulble quotes. The default prints it in a '\' block.

=head1 SEE ALSO

  OGDL::Parser, http://ogdl.sourceforge.net/

=cut

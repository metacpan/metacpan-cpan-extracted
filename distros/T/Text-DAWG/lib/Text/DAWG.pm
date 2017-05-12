package Text::DAWG;

use strict;
use warnings;

BEGIN {
    our $VERSION="0.001";
}

use Carp
    qw(croak);

use constant {
    BADNODE	=> 0,
    STARTNODE	=> 1,
};

=head1 NAME

Text::DAWG - directed acyclic word graphs

=head1 SYNOPSIS

 use Text::DAWG;

 my $dawg=Text::DAWG::->new([qw(one two three)]);

 print "one\n"  if $dawg->match("one");   # prints something

 print "four\n" if $dawg->match("four");  # prints nothing

=head1 DESCRIPTION

Text::DAWG implements implements string set recognition by way of
directed acyclic word graphs.

=head1 CONSTRUCTORS

=over

=item my $dawg=Text::DAWG::->new(\@words);

Creates a new DAWG matching the strings in an array.

=item my $dawg=Text::DAWG::->load(\*FILEHANDLE);

Creates a new DAWG from a compact representation stored in a file,
or dies if anything goes wrong.  The filehandle must be opened for reading
and binmoded before the call.

=back

=head1 METHODS

=over

=item $dawg->match($string);

Returns a true value if the DAWG contains the string.

=item $dawg->store(\*FILEHANDLE);

Stores a compact representation of the DAWG in a file.
The filehandle must be opened for writing and binmoded before the call.

=back

=head1 PEDAGOGIC METHODS

=over

=item $dawg->write_dot(\*FILEHANDLE);

=item $dawg->write_dot(\*FILEHANDLE,\%options);

Outputs a dot language representation of the DAWG
(see L<http://www.graphviz.org/>).
The filehandle must be opened for writing before the call.
If the DAWG contains any non-ASCII characters, you must set an appropriate
encoding as well.

You can pass a reference to a hash of options for tweaking the output.
The following keys are recognised:

=over

=item "" (the empty string)

The value must be a hash reference specifying global attributes
for the generated digraph.

=item "graph"

The value must be a hash reference specifying default attributes
for subgraphs.

=item "edge"

The value must be a hash reference specifying default attributes
for edges.

=item "node"

The value must be a hash reference specifying default attributes
for nodes.  Defaults to C<{ shape =E<gt> 'circle' }>.

=item "start"

The value must be a hash reference specifying attributes
for the start node.

=item "match"

The value must be a hash reference specifying attributes
for a matching node.  Defaults to C<{ shape =E<gt> 'doublecircle' }>.

=item "startmatch"

The value must be a hash reference specifying attributes
for a matching start node.  Defaults to the combination of the
C<start> and C<match> options, with C<match> given priority.

=item "chars"

The value must be a hash reference with single characters for keys
and hash references for values.  It specifies attributes for
edges representing the given characters.  The default has an entry
for the space character containng C<{ label =E<gt> 'SP' }>,
since an edge label consisting of a single space is hard to notice.

=item "id"

An id for the digraph itself.

=item "readable"

If true, certain optimisations that reduce both the size
and the readability of the output are not performed.

=back

Node ids are positive integers, with the start node always 1.

Edges have a default label equal to the character it represents.
You can override this with the C<chars> option.

=item my $dawg=Text::DAWG::->new(\@words,\*FILEHANDLE);

=item my $dawg=Text::DAWG::->new(\@words,\*FILEHANDLE,\%options);

You can pass extra arguments to the constructor to output a dot language
representation of the trie that is the un-optimised version of the DAWG.
Groups of trie nodes that correspond to the same DAWG node will be clustered.

=back

=head1 TIME AND SPACE

A Text::DAWG is always slower than a built-in Perl hash.

A Text::DAWG containing a set of strings with many common prefixes
and suffixes (e.g. a dictionary of English words) may use less memory
than a built-in Perl hash.  However, the unoptimised trie and
the optimisation process itself uses many times as much memory
as the final result.  Loading a stored DAWG from a file uses very
little extra memory.

=head1 AUTHOR

Bo Lindbergh E<lt>blgl@stacken.kth.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011, Bo Lindbergh

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.9 or, at
your option, any later version of Perl 5 you may have available.

=cut

sub new
{
    my($class,$strings,$fh,$options)=@_;
    my($work,$self);

    $work={
	strings	=> $strings,
    };
    bless($work,$class);
    $work->_init_charmap();
    $work->_build_trie();
    $work->_init_groups();
    $work->_split_groups();
    $work->_sort_groups();
    if ($fh) {
	$work->_sort_nodes();
	$work->write_dot($fh,$options);
    }
    $self={};
    bless($self,$class);
    $self->_final_charmap($work);
    $self->_build_dawg($work);
    $self;
}

sub _init_charmap
{
    my($self)=@_;
    my($strings,$charix,%histo,@chars);

    foreach my $string (@{$self->{strings}}) {
	foreach my $char (split(//,$string)) {
	    $histo{$char}++;
	}
    }
    @chars=sort {
	$histo{$b}<=>$histo{$a};
    } keys(%histo);
    $charix=1;
    for my $charmap ($self->{charmap}) {
	$charmap="";
	foreach my $char (@chars) {
	    vec($charmap,ord($char),32)=$charix;
	    $charix++;
	}
    }
}

sub _build_trie
{
    my($self)=@_;

    for my $match ($self->{match}) {
	for my $charmap ($self->{charmap}) {
	    my(@nodes,@depths);

	    $match="";
	    $nodes[BADNODE]="";
	    $nodes[STARTNODE]="";
	    $depths[BADNODE]=-1;
	    $depths[STARTNODE]=0;
	    foreach my $string (@{$self->{strings}}) {
		my($nodeix,$depth);

		$nodeix=STARTNODE;
		$depth=0;
		foreach my $charix (map(vec($charmap,ord($_),32)-1,
					split(//,$string))) {
		    my($nextix);

		    $depth++;
		    $nextix=vec($nodes[$nodeix],$charix,32);
		    if (!$nextix) {
			$nextix=@nodes;
			$nodes[$nextix]="";
			$depths[$nextix]=$depth;
			vec($nodes[$nodeix],$charix,32)=$nextix;
		    }
		    $nodeix=$nextix;
		}
		vec($match,$nodeix,1)=1;
	    }
	    $self->{nodes}=\@nodes;
	    $self->{depths}=\@depths;
	}
    }
}

sub _init_groups
{
    my($self)=@_;

    for my $match ($self->{match}) {
	my($nodes,@match,@nomatch,@groups);

	$nodes=$self->{nodes};
	@groups=(
	    [BADNODE],
	);
	foreach my $nodeix (STARTNODE .. $#{$nodes}) {
	    if (vec($match,$nodeix,1)) {
		push(@match,$nodeix);
	    } else {
		push(@nomatch,$nodeix)
	    }
	}
	if (@match) {
	    push(@groups,\@match);
	}
	if (@nomatch) {
	    push(@groups,\@nomatch);
	}
	$self->{groups}=\@groups;
    }
}

sub _split_groups
{
    my($self)=@_;
    my($nodes,$groups,@groupmap);

    $nodes=$self->{nodes};
    $groups=$self->{groups};
    for (;;) {
	my(@groups);

	foreach my $groupix (0 .. $#{$groups}) {
	    foreach my $nodeix (@{$groups->[$groupix]}) {
		$groupmap[$nodeix]=$groupix;
	    }
	}
	foreach my $group (@{$groups}) {
	    if (@{$group}>1) {
		my(%newgroups);

		foreach my $nodeix (@{$group}) {
		    my($key);

		    $key=pack("N*",
			      @groupmap[unpack("N*",$nodes->[$nodeix])]);
		    push(@{$newgroups{$key}},$nodeix);
		}
		push(@groups,values(%newgroups));
	    } else {
		push(@groups,$group);
	    }
	}
	last if @groups==@{$groups};
	$groups=\@groups;
    }
    $self->{groups}=$groups;
}

sub _sort_groups
{
    my($self)=@_;
    my($nodes,$depths,$groups);

    $nodes=$self->{nodes};
    $depths=$self->{depths};
    $groups=$self->{groups};
    foreach my $group (@{$groups}) {
	my($maxdepth,$maxnode);

	$maxdepth=-2;
	$maxnode=-1;
	foreach my $nodeix (@{$group}) {
	    my($depth);

	    $depth=$depths->[$nodeix];
	    if ($depth>$maxdepth) {
		$maxdepth=$depth;
		$maxnode=$nodeix;
	    }
	}
	$group=[$maxdepth,$maxnode,$group];
    }
    @{$groups}=sort {
	$a->[0]<=>$b->[0] || $a->[1]<=>$b->[1];
    } @{$groups};
}

sub _sort_nodes
{
    my($self)=@_;
    my($groups,$nodes);
    my(@nodemap,@nodes,$newix,$oldmatch);

    $groups=$self->{groups};
    $nodes=$self->{nodes};
    $newix=0;
    foreach my $group (@{$self->{groups}}) {
	foreach my $nodeix (@{$group->[2]}) {
	    $nodemap[$nodeix]=$newix++;
	}
    }
    for my $oldmatch (delete $self->{match}) {
	for my $match ($self->{match}) {
	    $match="\x00";
	    foreach my $nodeix (0..$#nodemap) {
		$nodes[$nodemap[$nodeix]]=
		    pack("N*",@nodemap[unpack("N*",$nodes->[$nodeix])]);
		if (vec($oldmatch,$nodeix,1)) {
		    vec($match,$nodemap[$nodeix],1)=1;
		}
	    }
	}
    }
    $self->{nodes}=\@nodes;
    foreach my $group (@{$groups}) {
	$group->[1]=$nodemap[$group->[1]];
	@{$group->[2]}=@nodemap[@{$group->[2]}];
    }
}

sub _final_charmap
{
    my($self,$work)=@_;
    my($nodes,$groups,@histo,@reorder,@remap);

    $nodes=$work->{nodes};
    $groups=$work->{groups};
    foreach my $group (@{$groups}) {
	for my $node ($nodes->[$group->[1]]) {
	    foreach my $charix (0 .. length($node)/4-1) {
		if (vec($node,$charix,32)) {
		    $histo[$charix]++;
		}
	    }
	}
    }
    @reorder=sort {
	$histo[$b]<=>$histo[$a];
    } (0 .. $#histo);
    foreach my $charix (0 .. $#reorder) {
	$remap[$reorder[$charix]]=$charix;
    }
    for my $triemap ($work->{charmap}) {
	for my $dawgmap ($self->{charmap}) {
	    $dawgmap="";
	    foreach my $ord (0 .. length($triemap)/4-1) {
		my($charix);

		$charix=vec($triemap,$ord,32);
		next unless $charix;
		vec($dawgmap,$ord,32)=$remap[$charix-1]+1;
	    }
	}
    }
    $work->{remap}=\@remap;
}

sub _build_dawg
{
    my($self,$work)=@_;

    for my $triematch ($work->{match}) {
	for my $dawgmatch ($self->{match}) {
	    my($trienodes,$groups,$remap,@groupmap,@dawgnodes);

	    $dawgmatch="\x00";
	    $trienodes=$work->{nodes};
	    $groups=$work->{groups};
	    $remap=$work->{remap};
	    foreach my $dawgix (0 .. $#{$groups}) {
		foreach my $trieix (@{$groups->[$dawgix]->[2]}) {
		    $groupmap[$trieix]=$dawgix;
		}
	    }
	    foreach my $dawgix (0 .. $#{$groups}) {
		my($trieix);

		$trieix=$groups->[$dawgix]->[1];
		for my $trienode ($trienodes->[$trieix]) {
		    for my $dawgnode ($dawgnodes[$dawgix]) {
			$dawgnode="";
			foreach my $charix (0 .. length($trienode)/4-1) {
			    my($nextix);

			    $nextix=vec($trienode,$charix,32);
			    if ($nextix) {
				vec($dawgnode,$remap->[$charix],32)=
				    $groupmap[$nextix];
			    }
			}
		    }
		}
		if (vec($triematch,$trieix,1)) {
		    vec($dawgmatch,$dawgix,1)=1;
		}
	    }
	    $self->{nodes}=\@dawgnodes;
	}
    }
}

sub match
{
    my $self=shift(@_);
    my($nodes,$nodeix);

    $nodes=$self->{nodes};
    for my $charmap ($self->{charmap}) {
	$nodeix=STARTNODE;
	foreach my $char (split(//,$_[0])) {
	    $nodeix=vec($nodes->[$nodeix],vec($charmap,ord($char),32)-1,32);
	}
    }
    return vec($self->{match},$nodeix,1);
}

sub store
{
    my($self,$fh)=@_;
    my($nodes);
    my(@unmap,@nodes,$sizes,$map);

    $nodes=$self->{nodes};
    for my $charmap ($self->{charmap}) {
	foreach my $ord (0 .. length($charmap)/4-1) {
	    my($charix);

	    $charix=vec($charmap,$ord,32);
	    if ($charix) {
		$unmap[$charix-1]=$ord;
	    }
	}
    }
    $map=pack("w*",@unmap);
    @nodes=map(pack("w*",unpack("N*",$_)),
	       @{$nodes}[STARTNODE .. $#{$nodes}]);
    $sizes=pack("w*",map(length($_),@nodes));
    print $fh "dAWg",pack("N",1);
    print $fh pack("N",length($map));
    print $fh pack("N",length($sizes));
    print $fh $map if length($map);
    print $fh $sizes;
    print $fh $self->{match};
    foreach my $node (@nodes) {
	print $fh $node if length($node);
    }
}

sub load
{
    my($class,$fh)=@_;
    my($self,@nodes,$nodecnt,$width);
    my($got,$mapsize,$sizessize,@sizes,$matchsize);
    my($used,$reachable);

    $self={
	charmap	=> "",
	nodes	=> \@nodes,
	match	=> "",
    };
    bless($self,$class);
    {
	my($head,$magic,$version);

	$got=read($fh,$head,16);
	defined($got)
	    or croak $!;
	$got==16
	    or croak "Unexpected EOF";
	($magic,$version,$mapsize,$sizessize)=unpack("A4NNN",$head);
	$magic eq "dAWg"
	    or croak "Bad stored data";
	$version==1
	    or croak "Unknown stored data version";
	$sizessize>=1
	    or croak "Bad stored data";
    }
    if ($mapsize>0) {
	my($packed,@unmap);

	$got=read($fh,$packed,$mapsize);
	defined($got)
	    or croak $!;
	$got==$mapsize
	    or croak "Unexpected EOF";
	@unmap=unpack("w*",$packed);
	$width=@unmap;
	for my $charmap ($self->{charmap}) {
	    foreach my $charix (0 .. $#unmap) {
		my($ord);

		$ord=$unmap[$charix];
		if (vec($charmap,$ord,32)) {
		    croak "Bad stored data";
		}
		vec($charmap,$ord,32)=$charix+1;
	    }
	}
    } else {
	$width=0;
    }
    {
	my($packed);

	$got=read($fh,$packed,$sizessize);
	defined($got)
	    or croak $!;
	$got==$sizessize
	    or croak "Unexpected EOF";
	@sizes=unpack("w*",$packed);
	$nodecnt=@sizes;
	unshift(@sizes,0);
    }

    $matchsize=int(($nodecnt+8)/8);
    $got=read($fh,$self->{match},$matchsize);
    defined($got)
	or croak $!;
    $got==$matchsize
	or croak "Unexpected EOF";

    $used="";
    $reachable="";
    vec($reachable,BADNODE,1)=1;
    $nodes[BADNODE]="";
    vec($reachable,STARTNODE,1)=1;
    foreach my $nodeix (STARTNODE .. $nodecnt) {
	for my $node ($nodes[$nodeix]) {
	    my($nodesize);

	    $nodesize=$sizes[$nodeix];
	    if ($nodesize>0) {
		my($packed,$nodewidth);

		$got=read($fh,$packed,$nodesize);
		defined($got)
		    or croak $!;
		$got==$nodesize
		    or croak "Unexpected EOF";
		$node=pack("N*",unpack("w*",$packed));
		$nodewidth=length($node)/4;
		$nodewidth<=$width
		    or croak "Bad stored data";
		vec($node,$nodewidth-1,32)
		    or croak "Bad stored data";
		foreach my $charix (0 .. $nodewidth-1) {
		    my($nextix);

		    $nextix=vec($node,$charix,32);
		    next unless $nextix;
		    if ($nextix>$nodecnt || $nextix<=$nodeix) {
			croak "Bad stored data";
		    }
		    vec($used,$charix,1)=1;
		    vec($reachable,$nextix,1)=1;
		}
	    } else {
		$nodecnt==1 || vec($self->{match},$nodeix,1)
		    or croak "Bad stored data";
		$node="";
	    }
	}
    }
    $used =~ /\A\xFF*/;
    foreach my $charix ($+[0]*8 .. $width-1) {
	vec($used,$charix,1)
	    or croak "Bad stored data";
    }
    $reachable =~ /\A\xFF*/;
    foreach my $nodeix ($+[0]*8 .. $nodecnt) {
	vec($reachable,$nodeix,1)
	    or croak "Bad stored data";
    }

    $self;
}

my $dot_id_re=
    qr/^(?:[A-Za-z_][0-9A-Za-z_]*|-?(?:[0-9]+(?:\.[0-9]*)|\.[0-9]+))$/;

sub _dot_id
{
    my($id)=@_;

    if ($id =~ $dot_id_re) {
	$id;
    } else {
	$id =~ s/\"/\\\"/g;
	qq{"$id"};
    }
}

sub _dot_attrs
{
    my($attrs)=@_;
    my(@attrs);

    foreach my $name (sort(keys(%{$attrs}))) {
	push(@attrs,_dot_id($name)."="._dot_id($attrs->{$name}));
    }
    join(", ",@attrs);
}

my %default_options=(
    "" => {
    },
    graph => {
    },
    edge => {
    },
    node => {
	shape	=> "circle",
    },
    match => {
	shape	=> "doublecircle",
    },
    start => {
    },
    chars => {
	" " => {
	    label => "SP",
	},
    },
);

sub _dot_break
{
    my($fh)=@_;

    for my $text ($_[1]) {
	my($pos,$len);

	$pos=0;
	$len=length($text);
	while ($len>64) {
	    my($break);

	    $break=rindex($text," ",$pos+64);
	    print $fh "\t",substr($text,$pos,$break-$pos),"\n";
	    $pos=$break+1;
	    $len=length($text)-$pos;
	}
	print $fh "\t",substr($text,$pos),";\n";
    }
}

sub write_dot
{
    my($self,$fh,$options)=@_;
    my($nodes);
    my(@charunmap,@order);

    $nodes=$self->{nodes};
    for my $charmap ($self->{charmap}) {
	foreach my $ord (0 .. length($charmap)/4-1) {
	    my($charix);

	    $charix=vec($charmap,$ord,32);
	    next unless $charix;
	    $charunmap[$charix-1]=chr($ord);
	}
    }
    @order=sort {
	$charunmap[$a] cmp $charunmap[$b];
    } (0 .. $#charunmap);

    $options||={};
    while (my($key,$value)=each(%default_options)) {
	$options->{$key}||=$value;
    }
    $options->{startmatch}||={
	%{$options->{start}},
	%{$options->{match}},
    };

    {
	my($id,$nullattrs);

	$id=$options->{id};
	print $fh "digraph";
	if (defined($id)) {
	    print $fh " ",_dot_id($id);
	}
	print $fh " {\n";
	$nullattrs=_dot_attrs($options->{""});
	if ($nullattrs ne "") {
	    print $fh "    $nullattrs;\n";
	}
    }

    foreach my $class (qw(graph node edge)) {
	my($classattrs);

	$classattrs=_dot_attrs($options->{$class});
	if ($classattrs ne "") {
	    print $fh "    $class [$classattrs];\n";
	}
    }

    if ($options->{readable}) {
	for my $match ($self->{match}) {
	    foreach my $nodeix (STARTNODE .. $#{$nodes}) {
		my($attrs);

		if (vec($match,$nodeix,1)) {
		    if ($nodeix==STARTNODE) {
			$attrs=_dot_attrs($options->{startmatch});
		    } else {
			$attrs=_dot_attrs($options->{match});
		    }
		} else {
		    if ($nodeix==STARTNODE) {
			$attrs=_dot_attrs($options->{start});
		    } else {
			$attrs="";
		    }
		}
		if ($attrs ne "") {
		    print $fh "    $nodeix [$attrs];\n";
		}
		for my $node ($nodes->[$nodeix]) {
		    foreach my $charix (@order) {
			my($nextix,%attrs,$char);

			$nextix=vec($node,$charix,32);
			next unless $nextix;
			$char=$charunmap[$charix];
			$attrs=_dot_attrs({
			    label => $char,
			    %{$options->{chars}->{$char} || {}},
			});
			print $fh "    $nodeix\->$nextix [$attrs];\n";
		    }
		}
	    }
	}
    } else {
	for my $match ($self->{match}) {
	    my($startattrs,$matchattrs,@matchids);

	    if (vec($match,STARTNODE,1)) {
		$startattrs=_dot_attrs($options->{startmatch});
	    } else {
		$startattrs=_dot_attrs($options->{start});
	    }
	    $matchattrs=_dot_attrs($options->{match});
	    if ($startattrs ne "") {
		if ($startattrs eq $matchattrs) {
		    push(@matchids,STARTNODE);
		} else  {
		    print $fh "    ".STARTNODE." [$startattrs];\n";
		}
	    }
	    if ($matchattrs ne "") {
		foreach my $nodeix (STARTNODE+1 .. $#{$nodes}) {
		    if (vec($match,$nodeix,1)) {
			push(@matchids,$nodeix);
		    }
		}
		if (@matchids>=26/(length($matchattrs)+8)+1) {
		    print $fh "    subgraph {\n";
		    print $fh "\tnode [$matchattrs];\n";
		    _dot_break($fh,join(" ",@matchids));
		    print $fh "    }\n";
		} else {
		    foreach my $nodeix (@matchids) {
			print $fh "    $nodeix [$matchattrs];\n";
		    }
		}
	    }
	}
	{
	    my(@charedges);

	    foreach my $nodeix (STARTNODE .. $#{$nodes}) {
		for my $node ($nodes->[$nodeix]) {
		    foreach my $charix (@order) {
			my($nextix,%attrs,$char);

			$nextix=vec($node,$charix,32);
			next unless $nextix;
			push(@{$charedges[$charix]},[$nodeix,$nextix]);
		    }
		}
	    }
	    foreach my $charix (@order) {
		my($char,$attrs,$edges);

		$char=$charunmap[$charix];
		$attrs=_dot_attrs({
		    label => $char,
		    %{$options->{chars}->{$char} || {}},
		});
		$edges=$charedges[$charix];
		if (@{$edges}>=26/(length($attrs)+8)+1) {
		    print $fh "    subgraph {\n";
		    print $fh "\tedge [$attrs];\n";
		    _dot_break(
			$fh,join(" ",map("$_->[0]\->$_->[1]",@{$edges})));
		    print $fh "    }\n";
		} else {
		    foreach my $edge (@{$edges}) {
			print $fh "    $edge->[0]\->$edge->[1] [$attrs];\n";
		    }
		}
	    }
	}
    }
    if (defined(my $groups=$self->{groups})) {
	foreach my $groupix (0 .. $#{$groups}) {
	    my($nodes);

	    $nodes=$groups->[$groupix]->[2];
	    if (@{$nodes}>=2) {
		print $fh "    subgraph cluster_$groupix {\n";
		_dot_break($fh,join(" ",@{$nodes}));
		print $fh "    }\n";
	    }
	}
    }
		
    print $fh "}\n";
}

1;


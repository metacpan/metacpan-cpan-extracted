package XML::STX::STXPath;

require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;
use XML::STX::Base;
use XML::STX::Functions;

@XML::STX::STXPath::ISA = qw(XML::STX::Base XML::STX::Functions);

# --------------------------------------------------

sub new {
    my $class = shift;
    my $stx = shift;
    my $self = bless { STX => $stx }, $class;
    return $self;
}

sub expr {
    my ($self, $nodes, $expr, $ns, $vars) = @_;

    $self->{ns} = $ns;
    $self->{vars} = $vars;
    my @expr = @$expr;
    $self->{tokens} = \@expr;

    # for debug & testing
    use Time::HiRes;
    my $t0 = Time::HiRes::time();

    my $result = $self->orExpr($nodes);
    
    # for debug & testing
    $self->{STX}->{_time_expr} += Time::HiRes::time() - $t0;
    
    if ($self->{tokens}->[0]) {
	# didn't manage to parse entire expression - throw an exception
 	$self->doError(2, 3, $expr, $self->{tokens}->[0]);
    }
    #print "EXP: ", _dbg_print('[expr]', $result);
    return $result;
}

sub match {
    my ($self, $node, $pattern, $p, $ns, $vars) = @_;

    $self->{ns} = $ns;
    $self->{vars} = $vars;
    my $result = [0, -1, '']; # true/false, priority

    # for debug & testing
    my $t0 = Time::HiRes::time();

    # an optimization for single location paths
    if ($#$pattern == 0) {

	my $res = $self->matchPath($node, $pattern->[0]);

	#print "EXP: match $res\n";
	my $pty = ref $p ? $p->[0] : $p;
	$result = [1, $pty, $pattern->[0]] if $res;

    } else {
	for (my $i = 0; $i <= $#$pattern; $i++) {
	    my $res = $self->matchPath($node, $pattern->[$i]);
	    #print "EXP: match $res\n";
	    my $pty = $p->[$i];
	    $result = [1, $pty, $pattern->[$i]] if $res and $pty > $result->[1];
	}
    }

    # for debug & testing
    $self->{STX}->{_time_match} += Time::HiRes::time() - $t0;

    #print "EXP: [match] $result->[0]\n";
    return $result;
}


# ==================================================
# General Expression

sub orExpr {
    my ($self, $nodes) = @_;
    #print "EXP: orExpr ", $self->{tokens}->[0], "\n";

    my $result = $self->andExpr($nodes);

    while ($self->{tokens}->[0] and
	   $self->{tokens}->[0] eq 'or') {
	shift @{$self->{tokens}};
	my $bool = $self->F_boolean($result);
	my $bool2 = $self->F_boolean($self->andExpr($nodes));

	my $val = $bool->[0] + $bool2->[0] > 0 ? 1 : 0;
	#print "EXP: orExpr: $bool->[0] or $bool2->[0] = $val\n";
	$result = [[$val, STX_BOOLEAN]];	
    }
    #print "EXP: ", _dbg_print('orExpr', $result);
    return $result;
}

sub andExpr {
    my ($self, $nodes) = @_;
    #print "EXP: andExpr ", $self->{tokens}->[0], "\n";

    my $result = $self->genComp($nodes);

    while ($self->{tokens}->[0] and
	   $self->{tokens}->[0] eq 'and') {
	shift @{$self->{tokens}};
	my $bool = $self->F_boolean($result);
	my $bool2 = $self->F_boolean($self->genComp($nodes));

	my $val = $bool->[0] * $bool2->[0];
	#print "EXP: andExpr: $bool->[0] and $bool2->[0] = $val\n";
	$result = [[$bool->[0] * $bool2->[0], STX_BOOLEAN]];	
    }
    #print "EXP: ", _dbg_print('andExpr', $result);
    return $result;
}

sub genComp {
    my ($self, $nodes) = @_;
    #print "EXP: genComp ", $self->{tokens}->[0], "\n";

    my $result = $self->addExpr($nodes);

    while ($self->{tokens}->[0] and
	   $self->{tokens}->[0] =~ /^(?:=|!=|<|<=|>|>=)$/) {
	my $compOp = shift @{$self->{tokens}};
	#print "EXP: genComp: $compOp\n";

	my $comp_res = $self->_compare($result, $self->addExpr($nodes), $compOp);
 	$result = [[$comp_res, STX_BOOLEAN]];
    }
    #print "EXP: ", _dbg_print('genComp', $result);
    return $result;
}

sub addExpr {
    my ($self, $nodes) = @_;
    #print "EXP: addExpr ", $self->{tokens}->[0], "\n";

    my $result = $self->multExpr($nodes);

    while ($self->{tokens}->[0] and
	   $self->{tokens}->[0] =~ /^(?:\+|-)$/) {
	my $addOp = shift @{$self->{tokens}};
	#print "EXP: addExpr: $addOp\n";

	my $num = $self->F_number($result);
	my $num2 = $self->F_number($self->multExpr($nodes));

	if ($addOp eq '+') {
	    $result = [[$num->[0] + $num2->[0], STX_NUMBER]];

	} else { # $addOp eq '-'
	    $result = [[$num->[0] - $num2->[0], STX_NUMBER]];
	}
	#print "EXP: addExpr: $num->[0] $addOp $num2->[0] = $result->[0]->[0]\n";
    }
    #print "EXP: ", _dbg_print('addExpr', $result);
    return $result;
}

sub multExpr {
    my ($self, $nodes) = @_;
    #print "EXP: multExpr ", $self->{tokens}->[0], "\n";

    my $result = $self->unaryExpr($nodes);

    while ($self->{tokens}->[0] and 
	   $self->{tokens}->[0] =~ /^(?:\*|div|mod)$/) {

	my $multOp = shift @{$self->{tokens}};
	#print "EXP: multExpr: $multOp\n";

	my $num = $self->F_number($result);
	my $num2 = $self->F_number($self->unaryExpr($nodes));

	if ($multOp eq '*') {
	    $result = [[$num->[0] * $num2->[0], STX_NUMBER]];
		
	} elsif ($multOp eq 'mod') {
	    $result = [[$num->[0] % $num2->[0], STX_NUMBER]];

	} else { # $multOp eq 'div'
	    $result = [[$num->[0] / $num2->[0], STX_NUMBER]];
	}
	#print "EXP: multExpr: $num->[0]$multOp$num2->[0] = $result->[0]->[0]\n";
    }
    #print "EXP: ", _dbg_print('multExpr', $result);
    return $result;
}

sub unaryExpr {
    my ($self, $nodes) = @_;
    #print "EXP: unaryExpr ", $self->{tokens}->[0], "\n";

    #my $unaryOp = ($self->{tokens}->[0] =~ /^(?:\+|-)$/)
    my $unaryOp = ($self->{tokens}->[0] eq '+' or $self->{tokens}->[0] eq '-')
      ? shift @{$self->{tokens}} : undef;

    my $result = $self->basicExpr($nodes);

    #print "EXP: ", _dbg_print('unaryExpr', $result);

    if ($unaryOp) {
	my $num = $self->F_number($result);
	$self->doError(11, 3, $result->[0]->[0]) if $num->[0] eq 'NaN';

	$num->[0] = -$num->[0] if $unaryOp eq '-';
	#print "EXP: unaryExpr converted to number -> $num->[0]\n";
	return [[$num->[0], STX_NUMBER]];

    } else {
	return $result;
    }
}

sub basicExpr {
    my ($self, $nodes) = @_;
    #print "EXP: basicExpr ", $self->{tokens}->[0], "\n";

    # literal or numeric literal
    if ($self->{tokens}->[0] 
	=~ /^(?:$LITERAL|$NUMBER_RE|$DOUBLE_RE)$/o) {
	return $self->literal($nodes);

    # current item
    } elsif ($self->{tokens}->[0] eq '.') {
    	return $self->currentItem($nodes);

    # parenthesized expression
    } elsif ($self->{tokens}->[0] eq '(') {
	return $self->parExpr($nodes);

    # data accessor
    } else {
	return $self->dataAccessor($nodes);
    }
}

sub currentItem {
    my ($self, $nodes) = @_;
    #print "EXP: currentItem ", $self->{tokens}->[0], "\n";

    shift @{$self->{tokens}};

    my @seq = map([$_,STX_NODE], @$nodes);
    return \@seq;
}

sub literal {
    my $self = shift;
    #print "EXP: literal ", $self->{tokens}->[0], "\n";

    my $lit = shift @{$self->{tokens}};

    if ($lit =~ /^($NUMBER_RE|$DOUBLE_RE)$/o) {
	return [[$1, STX_NUMBER]]

    } elsif ($lit =~ /^['](.*)[']$/ or $lit =~ /^["](.*)["]$/) {
	return [[$1, STX_STRING]];
    }
}

sub fcCall {
    my ($self, $nodes) = @_;
    #print "EXP: fcCall ", $self->{tokens}->[0], "\n";

    my $fce = substr(shift @{$self->{tokens}}, 
		     length(STX_FNS_URI) + 2);

    # parsing & expanding arguments
    $self->doError(13, 3, $fce, $self->{tokens}->[0]) 
      unless $self->{tokens}->[0] eq '(';
    shift @{$self->{tokens}};

    my @arg = ();
    while (defined $self->{tokens}->[0]) {
	my $arg = $self->{tokens}->[0];
	if ($arg eq ')') {
	    shift @{$self->{tokens}};
	    last;
	};
	#print "EXP: function argument: $arg\n";

	my $result = $self->orExpr($nodes);
	push @arg, $result;
	#print "EXP: ", _dbg_print('fcCall', $result);

	if ($self->{tokens}->[0] eq ',') {
	    shift @{$self->{tokens}};

	} elsif ($self->{tokens}->[0] eq ')') {
	    shift @{$self->{tokens}};
	    last;

	} else {
	    $self->doError(14, 3, $fce, $self->{tokens}->[0]) 	    
	}
    }

    if ($fce eq 'boolean') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return [$self->F_boolean($arg[0])];

    } elsif ($fce eq 'string') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return [$self->F_string($arg[0])];

    } elsif ($fce eq 'number') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return [$self->F_number($arg[0])];

    } elsif ($fce eq 'true') {
	$self->doError(15, 3, scalar @arg, $fce, 0) if @arg != 0;
	return [[1,STX_BOOLEAN]];

    } elsif ($fce eq 'false') {
	$self->doError(15, 3, scalar @arg, $fce, 0) if @arg != 0;
	return [[0,STX_BOOLEAN]];

    } elsif ($fce eq 'not') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_not($arg[0]);

    } elsif ($fce eq 'name') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	# current node is used when no argument found
	my $arg = $arg[0] ? $arg[0] 
	  : [[$self->{STX}->{Stack}->[-1],STX_NODE]];
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg > 1;
	return $self->F_name($arg);

    } elsif ($fce eq 'namespace-uri') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	# current node is used when no argument found
	my $arg = $arg[0] ? $arg[0] 
	  : [[$self->{STX}->{Stack}->[-1],STX_NODE]];
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg > 1;
	return $self->F_namespace_uri($arg);

    } elsif ($fce eq 'local-name') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	# current node is used when no argument found
	my $arg = $arg[0] ? $arg[0] 
	  : [[$self->{STX}->{Stack}->[-1],STX_NODE]];
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg > 1;
	return $self->F_local_name($arg);

    } elsif ($fce eq 'normalize-space') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg > 1;
	# string value of the current node is used when no argument found
	my $arg = $arg[0] ? $arg[0] 
	  : [$self->F_string([[$self->{STX}->{Stack}->[-1],STX_NODE]])];
	return $self->F_normalize_space($arg);

    } elsif ($fce eq 'position') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	$self->doError(15, 3, scalar @arg, $fce, 0) if @arg != 0;
	# returns 1 and warning for attributes
	if ($self->{STX}->{position} == 0) {
	    $self->doError(506, 1);
	    return [[1, STX_NUMBER]];
	};
	return [[$self->{STX}->{position}, STX_NUMBER]];

    } elsif ($fce eq 'has-child-nodes') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	$self->doError(15, 3, scalar @arg, $fce, 0) if @arg != 0;
	return [[$self->{STX}->{_child_nodes}, STX_BOOLEAN]];

    } elsif ($fce eq 'node-kind') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	# current node is used when no argument found
	my $arg = $arg[0] ? $arg[0] 
	  : [[$self->{STX}->{Stack}->[-1],STX_NODE]];
	$self->doError(15, 3, scalar @arg, $fce, 0) if @arg > 1;
	return $self->F_node_kind($arg);

    } elsif ($fce eq 'get-in-scope-prefixes') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_get_in_scope_prefixes(@arg);

    } elsif ($fce eq 'get-namespace-uri-for-prefix') {
	$self->doError(216, 3, "\'$fce()\'") unless $nodes;
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2;
	return $self->F_get_namespace_uri_for_prefix(@arg);

    } elsif ($fce eq 'starts-with') {
	$self->doError(18, 1, $arg[2]->[0]->[0], $fce) if @arg == 3;
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2 and @arg != 3;
	return $self->F_starts_with(@arg);

    } elsif ($fce eq 'ends-with') {
	$self->doError(18, 1, $arg[2]->[0]->[0], $fce) if @arg == 3;
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2 and @arg != 3;
	return $self->F_ends_with(@arg);

    } elsif ($fce eq 'contains') {
	$self->doError(18, 1, $arg[2]->[0]->[0], $fce) if @arg == 3;
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2 and @arg != 3;
	return $self->F_contains(@arg);

    } elsif ($fce eq 'substring') {
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg!=2 and @arg!=3;
	return $self->F_substring(@arg);

    } elsif ($fce eq 'substring-before') {
	$self->doError(18, 1, $arg[2]->[0]->[0], $fce) if @arg == 3;
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2 and @arg!=3;
	return $self->F_substring_before(@arg);

    } elsif ($fce eq 'substring-after') {
	$self->doError(18, 1, $arg[2]->[0]->[0], $fce) if @arg == 3;
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2 and @arg!=3;
	return $self->F_substring_after(@arg);

    } elsif ($fce eq 'string-length') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg > 1;
	# string value of the current node is used when no argument found
	my $arg = $arg[0] ? $arg[0] 
	  : [$self->F_string([[$self->{STX}->{Stack}->[-1],STX_NODE]])];
	return $self->F_string_length($arg);

    } elsif ($fce eq 'concat') {
	# any number of arguments is allowed
	return $self->F_concat(@arg);

    } elsif ($fce eq 'string-join') {
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2;
	return $self->F_string_join(@arg);

    } elsif ($fce eq 'translate') {
	$self->doError(15, 3, scalar @arg, $fce, 3) if @arg != 3;
	return $self->F_translate(@arg);

    } elsif ($fce eq 'floor') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_floor(@arg);

    } elsif ($fce eq 'round') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_floor([[$arg[0]->[0]->[0] + 0.5, STX_NUMBER]]);

    } elsif ($fce eq 'ceiling') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_ceiling(@arg);

    } elsif ($fce eq 'count') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return [[scalar @{$arg[0]}, STX_NUMBER]];
	
    } elsif ($fce eq 'sum') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_sum($arg[0]);

    } elsif ($fce eq 'avg') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_avg($arg[0]);

    } elsif ($fce eq 'min') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_min($arg[0]);

    } elsif ($fce eq 'max') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_max($arg[0]);

    } elsif ($fce eq 'empty') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_empty($arg[0]);

    } elsif ($fce eq 'exists') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_exists($arg[0]);

    } elsif ($fce eq 'item-at') {
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2;
	return $self->F_item_at(@arg);

    } elsif ($fce eq 'index-of') {
	$self->doError(18, 1, $arg[2]->[0]->[0], $fce) if @arg == 3;
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2 and @arg != 3;
	return $self->F_index_of(@arg);

    } elsif ($fce eq 'subsequence') {
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2 and @arg != 3;
	return $self->F_subsequence(@arg);

    } elsif ($fce eq 'insert-before') {
	$self->doError(15, 3, scalar @arg, $fce, 3) if @arg != 3;
	return $self->F_insert_before(@arg);

    } elsif ($fce eq 'remove') {
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2;
	return $self->F_remove(@arg);

    } elsif ($fce eq 'upper-case') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_upper_case($arg[0]);

    } elsif ($fce eq 'lower-case') {
	$self->doError(15, 3, scalar @arg, $fce, 1) if @arg != 1;
	return $self->F_lower_case($arg[0]);

    } elsif ($fce eq 'string-pad') {
	$self->doError(15, 3, scalar @arg, $fce, 2) if @arg != 2;
	return $self->F_string_pad(@arg);

    # ----------
    } else {
	$self->doError(12, 3, $fce);	
    }
}

sub parExpr {
    my ($self, $nodes) = @_;
    #print "EXP: parExpr ", $self->{tokens}->[0], "\n";

    shift @{$self->{tokens}};
    my $result = $self->{tokens}->[0] eq ')' ? [] : $self->orExpr($nodes);

    until ($self->{tokens}->[0] eq ')') {
	if ($self->{tokens}->[0] eq ',') {
	    shift @{$self->{tokens}};
	    #print "EXP: parExpr - next item\n";
	    #print "EXP: parExpr ", $self->{tokens}->[0], "\n";
	    my $next = $self->orExpr($nodes);
	    push @$result, @$next;

	} else {
	    $self->doError(3, 3, $self->{tokens}->[0]);	    
	}
    }

    shift @{$self->{tokens}};
    #print "EXP: ", _dbg_print('parExpr', $result);
    return $result;
}

sub dataAccessor {
    my ($self, $nodes) = @_;
    #print "EXP: dataAccessor ", $self->{tokens}->[0], "\n";

    my $result;

    if (unpack('A1', $self->{tokens}->[0]) eq '@') {
	$result = $self->attributeNameTest($nodes);

    } else { 
	# node accessor ----------
	if ($self->{tokens}->[0] =~ /^\$(.+)$/) {
	    $result = $self->variable($1);

	# function call
	} elsif (substr($self->{tokens}->[0],1,length(STX_FNS_URI)) 
		 eq STX_FNS_URI) {
	    $result = $self->fcCall($nodes);

        # pathAccessor
	} else { 
	    $result = $self->pathAccessor($nodes);	
	}

	if ($self->{tokens}->[0] and $self->{tokens}->[0] eq '/') {
	    shift @{$self->{tokens}};

	    if (unpack('A1', $self->{tokens}->[0]) eq '@') {
		# sequence is turned back to nodes
		my @nodes2 = map($_->[0], @$result);
		$result = $self->attributeNameTest(\@nodes2);

	    } else {
		$self->doError(6, 3, $self->{tokens}->[0]);
	    }
	}
    }
    #print "EXP: ", _dbg_print('dataAccessor', $result);
    return $result;
}

sub pathAccessor {
    my ($self, $nodes) = @_;
    #print "EXP: pathAccessor ", $self->{tokens}->[0], "\n";

    if ($self->{tokens}->[0] eq '/') {
	$nodes = [ $self->{STX}->{root} ];
	$self->{axis} = 1;
	shift @{$self->{tokens}};

	# '/' only shortcut
	return [[$self->{STX}->{root}, STX_NODE]]
	  if $self->{tokens}->[0] eq ')' or $self->{tokens}->[0] eq ',';

    } elsif ($self->{tokens}->[0] eq '//') {
	$nodes = [ $self->{STX}->{root} ];
	$self->{axis} = 2;
	shift @{$self->{tokens}};

    } else {
	$self->{axis} = 1;
    }

    my $result = $self->relAccessor($nodes);

    #print "EXP: ", _dbg_print('pathAccessor', $result);
    return $result;
}

sub relAccessor {
    my ($self, $nodes) = @_;
    #print "EXP: relAccessor ", $self->{tokens}->[0], "\n";

    # dynamic context required
    $self->doError(216, 3, "\'$self->{tokens}->[0]\'") unless $nodes;
    $nodes = $self->accessorStep($nodes);

    while ($self->{tokens}->[0] and
	   $self->{tokens}->[0] =~ /^(?:\/|\/\/)$/) {

	# attributes to be resolved elsewhere
	last if unpack('A', $self->{tokens}->[1]) eq '@';

	my $delimiter = shift @{$self->{tokens}};
	#print "EXP: relAccessor next: $delimiter $self->{tokens}->[0]\n";

	$self->{axis} = ($delimiter eq '/')  ? 1 : 2;

	$nodes = $self->accessorStep($nodes);
    }
    # nodes are turned to a sequence
    my @seq = map([$_,STX_NODE], @$nodes);

    #print "EXP: ", _dbg_print('relAccessor', \@seq);
    return \@seq;
}

sub accessorStep {
    my ($self, $nodes) = @_;
    #print "EXP: accessorStep ", $self->{tokens}->[0], "\n";

    # .. shortcut
    if ($self->{tokens}->[0] eq '..') {
	$self->doError(4, 3) unless ($self->{axis} == 1);
	shift @{$self->{tokens}};
	
	my $parents = [];
	foreach (@$nodes) {
	      push @$parents, $self->{STX}->{Stack}->[$_->{Index}-1]
		if $_->{Index} > 0;
	}
	return $parents;

    } elsif (index($self->{tokens}->[0], '()') > 0) {
	return $self->nodeKindTest($nodes);	

    } else {
	return $self->nodeNameTest($nodes);
    }
}

sub variable {
    my ($self, $name) = @_;
    #print "EXP: variable: $name\n";

    shift @{$self->{tokens}};

    # local variable
    if (my $ct = $self->{STX}->{_c_template}->[-1]) {
	my $vars = $ct->{vars};
	return $vars->[-1]->{$name}->[0] if $vars->[-1]->{$name};
    }

    # group variable
    my $var = $self->_get_group_variable($name);
    return $var if $var;

    $self->doError(16, 3, "\'$name\'");
}

sub nodeKindTest {
    my ($self, $nodes) = @_;
    #print "EXP: nodeKindTest ", $self->{tokens}->[0], "\n";

    my $res_nodes = [];
    #print "EXP: axis: $self->{axis}\n";

    # child axis
    if ($self->{axis} == 1) {
	foreach (@$nodes) {

	    # frame exists
	    if (@{$self->{STX}->{Stack}} > $_->{Index}+1) {
		my $node = $self->{STX}->{Stack}->[$_->{Index}+1];
		push @$res_nodes, $node if $self->kindTest($node) == 1;
	    }
	}

    # descendant axis	
    } elsif ($self->{axis} == 2) {
	foreach (@$nodes) {
	    # scan all descendants
	    for (my $i = $_->{Index}+1; $i < @{$self->{STX}->{Stack}}; $i++) {
		my $node = $self->{STX}->{Stack}->[$i];
		push @$res_nodes, $node if $self->kindTest($node) == 1;
	    }
	}
    }
    shift @{$self->{tokens}};
    return $res_nodes;
}

sub nodeNameTest {
    my ($self, $nodes) = @_;
    #$self->{tokens}->[0] || ($self->{tokens}->[0] = '');
    #print "EXP: nodeNameTest ", $self->{tokens}->[0], "\n";

    my $res_nodes = [];

    # child axis
    if ($self->{axis} == 1) {
	foreach (@$nodes) {

	    # frame exists
	    if (@{$self->{STX}->{Stack}} > $_->{Index}+1) {
		my $node = $self->{STX}->{Stack}->[$_->{Index}+1];
		my $res = $self->_node_match($node);
		push @$res_nodes, $res if $res != -1;
	    }
	}

    # descendant axis	
    } elsif ($self->{axis} == 2) {
	foreach (@$nodes) {
	    # scan all descendants
	    for (my $i = $_->{Index}+1; $i < @{$self->{STX}->{Stack}}; $i++) {
		my $node = $self->{STX}->{Stack}->[$i];
		my $res = $self->_node_match($node);
		push @$res_nodes, $res if $res != -1;
	    }
	}
    }
    shift @{$self->{tokens}};
    return $res_nodes;
}

sub attributeNameTest {
    my ($self, $nodes) = @_;
    #print "EXP: attributeNameTest ", $self->{tokens}->[0], "\n";

    my $res_nodes = [];

    foreach (@{$nodes}) {
	my $res = $self->_attribute_match($_->{Index});
	push @$res_nodes, @$res;
    }
    shift @{$self->{tokens}};
    #print "EXP: attributeNameTest ",join(':',map($_->{Name},@$res_nodes)),"\n";

    # nodes are turned to a sequence
    my @seq = map([$_,STX_NODE], @$res_nodes);
    return \@seq;
}

sub namespaces {
    my ($self, $node) = @_;
    #print "EXP: namespaces ", $self->{tokens}->[0], "\n";

    my $ns_nodes = [];
    my $pref = $self->{tokens}->[0];

    if ($node->{Type} == 1) {
	my @prefs = $pref eq '*' ? $self->{STX}->{ns}->get_prefixes 
	  : ($self->{tokens}->[0]);

	foreach (@prefs) {
	    my $p = $_ eq '' ? '#default' : $_;
	    my $uri = $self->{STX}->{ns}->get_uri($p);
	    my $node = {Type => 8, 
			Index => scalar @{$self->{STX}->{Stack}} + 1,
			Name => $p,
			Value => $uri,
		       };
	    #print "EXP: NS node $p|$uri\n";
	    push @$ns_nodes, $node;
	}
    } else {
       	$self->doError(17, 3, $node->{Type});
    }

    return $ns_nodes;
}

# ==================================================
# Match Pattern

# pathPattern
sub matchPath {
    my ($self, $node, $path) = @_;
    my $i = $#$path;
    #print "EXP: matchPath $i\n";

    my $result = 1;

    while ($i >= 0 and $result) {
	my $step = $path->[$i];
	#print "EXP: matchPath->$i $step->{left}:$#{$step->{step}}\n";
	#print "EXP: matchPath->$i node $node->{Index}\n";

	# to handle '/' pattern
	if ($#{$step->{step}} == -1 && $step->{left} eq 'R') {
	    #print "EXP: '/' pattern, node: $node->{Type}\n";
	    if ($node->{Type} == STX_ROOT_NODE) {
		return 1;
	    } else {
		return 0;
	    }
	}

	$result = $self->matchStep($node, $step->{step});
	#print "EXP: matchPath->$i <$result>\n";
	return 0 unless $result;

	if ($step->{left} eq 'P') {
	    #print "EXP: matchPath->$i process parent\n";
	    $node = $self->{STX}->{Stack}->[$node->{Index}-1];

	} elsif ($step->{left} eq 'R') {
	    #print "EXP: matchPath->$i verify root\n";
	    return $node->{Index} == 1 ? $result : 0;

	} elsif ($step->{left} eq 'A') {
	    #print "EXP: matchPath->$i process ancestors\n";
	    my $a_result = 0;

	    foreach (my $j = $node->{Index} - 1; $j >= 0; $j--) {
		$node = $self->{STX}->{Stack}->[$j];
		my @apath = @$path;
		pop @apath;
		my $a_res = $self->matchPath($node, \@apath);
		$a_result = 1 if $a_res;
		#print "EXP: ancestor $j: $a_res->$a_result\n";
	    }
	    #print "EXP: matchPath <<$a_result>>\n";
	    return $a_result;
	}
	$i--;
    }
    #print "EXP: matchPath <<$result>>\n";
    return $result;
}

sub matchStep {
    my ($self, $node, $step) = @_;
    #print "EXP: matchStep $step->[0]\n";

    my @step = @$step;
    $self->{tokens} = \@step;

    my $result = $self->nodeTest($node);
    return 0 if $result == -1;

    my $tok = shift @{$self->{tokens}};

    if ($self->{tokens}->[0]) {

	if ($self->{tokens}->[0] eq '[') {

	    $tok = $self->_counter_key($tok);
	    $self->{STX}->{position} 
	      = $self->{STX}->{Counter}->[$#{$self->{STX}->{Stack}}]->{$tok};

	    my $predicate = $self->predExpr($node);
	    #print "EXP: predicate <$predicate->[0]>\n";
	    $self->{STX}->{position} = undef;
	    return $predicate->[0];

	} else {
	    $self->doError(7, 3, $self->{tokens}->[0]);
	}

    } else {return 1}
}

sub nodeTest {
    my ($self, $node) = @_;
    #print "EXP: nodeTest ", $self->{tokens}->[0], "\n";

    if (index($self->{tokens}->[0], '(') > 0 
	or $self->{tokens}->[0] eq 'processing-instruction') {
	return $self->kindTest($node);	

    } else {
	return $self->nameTest($node);
    }
}

sub nameTest {
    my ($self, $node) = @_;
    #print "EXP: nameTest ", $self->{tokens}->[0], "\n";

    return $self->_node_match($node);
}

sub kindTest {
    my ($self, $node) = @_;
    #print "EXP: kindTest ", $self->{tokens}->[0], ", $node->{Type}\n";
    my $test = $self->{tokens}->[0];

    if ($test eq 'node()') {
	return 1;

    } elsif ($test eq 'text()') {
	return 1 if $node->{Type} == 2 or $node->{Type} == 3;

    } elsif ($test eq 'cdata()') {
	return 1 if $node->{Type} == 3;

    } elsif ($test eq 'processing-instruction()') {
	return 1 if $node->{Type} == 4;

    } elsif ($test eq 'processing-instruction') {
	unless ($self->{tokens}->[1] eq '('
		and $self->{tokens}->[2] =~ /^(?:$LITERAL)$/o
		and $self->{tokens}->[3] eq ')') {

	    my $expr = $self->{tokens}->[0] . $self->{tokens}->[1] 
	      . $self->{tokens}->[2] . $self->{tokens}->[3];
	    $self->doError(5, 3, $expr);
	}
	
	my $target = substr($self->{tokens}->[2], 1, 
			    length($self->{tokens}->[2]) - 2);
	shift @{$self->{tokens}};
	shift @{$self->{tokens}};
	shift @{$self->{tokens}};
	$self->{tokens}->[0] = "processing-instruction:$target";

	return 1 if ($node->{Type} == 4 and $node->{Target} eq $target);

    } elsif ($test eq 'comment()') {
	return 1 if $node->{Type} == 5;

    } else {
	$self->doError(8, 3);
    }
    return -1;
}

sub predExpr {
    my ($self, $node) = @_;
    #print "EXP: predExpr ", $self->{tokens}->[0], "\n";

    shift @{$self->{tokens}};
    my $result = $self->orExpr([$node]);
    unless ($self->{tokens}->[0] eq ']') {
	$self->doError(9, 3, $self->{tokens}->[0]);
    }
    shift @{$self->{tokens}};
    #print "EXP: ", _dbg_print('predExpr', $result);

     if ($#$result == 0 and $result->[0]->[1] == STX_NUMBER) {
	 if ($self->{STX}->{position} == $result->[0]->[0]) {
	     return [1, STX_BOOLEAN];
	 } else {
	     return [0, STX_BOOLEAN];
	 }

     } else {
	 return $self->F_boolean($result);	 
     }
}

# utils ----------------------------------------

# if a stack frame matches a QName, the node is returned
sub _node_match {
    my ($self, $node) = @_;

    # element or attribute node
    if ($node->{Type} == 1 or $node->{Type} == 6) {

	my $nsuri = '';
	my $lname = (unpack('A1', $self->{tokens}->[0]) eq '@')
	  ? substr($self->{tokens}->[0],1) : $self->{tokens}->[0];

	if ($lname =~ /^\{([^|}]+)\}(.+)/) {
	    $nsuri = $1;
       	    $lname = $2;
	}

	#print "EXP: path {$nsuri}$lname\n";
	#print "EXP: node {$node->{NamespaceURI}}$node->{LocalName}\n";
	# element expanded name matches
	if (($lname eq '*') and not($nsuri)) {
	    #print "EXP: _node_match->*\n";
	    return $node;

	} elsif (($lname eq '*') and $nsuri) {
	    #print "EXP: _node_match->ns:*\n";
	    return $node if $nsuri eq $node->{NamespaceURI};

	} elsif (($lname ne '*') and not($nsuri)) {
	    #print "EXP: _node_match->lname\n";
	    return $node if $lname eq $node->{LocalName} 
	      and not($node->{NamespaceURI});

	} elsif (($lname ne '*') and ($nsuri eq '*')) {
	    #print "EXP: _node_match->*:lname\n";
	    return $node if $lname eq $node->{LocalName};

	} else {
	    #print "EXP: _node_match->ns:lname\n";
	    return $node if ($nsuri eq $node->{NamespaceURI}
	      and $lname eq $node->{LocalName});
	}
    }
    return -1;
}

# if an attribute matches QName, it's added to node-set
sub _attribute_match {
    my ($self, $findex) = @_;

    my $node = $self->{STX}->{Stack}->[$findex];
    my $attributes = [];
    # element node
    if ($node->{Type} == 1) {
	# attribute expanded name matches
	foreach (keys %{$node->{Attributes}}) {
	    #print "EXP: attribute: $_\n";
	    my $att = $self->_node_match($node->{Attributes}->{$_});
	    push @$attributes, $att if ref $att;
 	}
    }
    return $attributes;
}

# resolves sequence comparisons
sub _compare {
    my ($self, $o1, $o2, $op) = @_;

    if ($#$o1 == -1 or $#$o2 == -1) {
	return 0;

    } else {
	my $res = 0;
	foreach my $n1 (@$o1) {
	    foreach my $n2 (@$o2) {
		$res = 1 if $self->_item_compare($n1, $n2, $op);
	    }
	}
	return $res;
    }
}

# resolves item comparisons
sub _item_compare {
    my ($self, $o1, $o2, $op) = @_;

    if ($o1->[1] == STX_NODE) {

	if ($o2->[1] == STX_NODE) {
	    return _s_compare($self->F_string($o1),
			      $self->F_string($o2),
			      $op);
	    
	} elsif ($o2->[1] == STX_STRING) {
	    return _s_compare($self->F_string($o1),$o2,$op);

	} elsif ($o2->[1] == STX_NUMBER) {
	    return _n_compare($self->F_number($o1),$o2,$op);

	} elsif ($o2->[1] == STX_BOOLEAN) {
	    return _n_compare($self->F_boolean($o1),$o2,$op);
	}

    } elsif ($o1->[1] == STX_STRING) {

	if ($o2->[1] == STX_NODE) {
	    return _s_compare($o1,$self->F_string($o2),$op);

	} elsif ($o2->[1] == STX_STRING) {
	    if ($op eq '=' or $op eq '!=') {
		return _s_compare($o1,$o2,$op);
	    } else {
		return _n_compare($self->F_number($o1),
				  $self->F_number($o2),
				  $op);
	    }

	} elsif ($o2->[1] == STX_NUMBER) {
	    return _n_compare($self->F_number($o1), $o2, $op);

	} elsif ($o2->[1] == STX_BOOLEAN) {
	    if ($op eq '=' or $op eq '!=') {
		return _n_compare($self->F_boolean($o1), $o2, $op);
	    } else {
		return _n_compare($self->F_number($o1), 
				  $self->F_number($o2), $op);
	    }
	}

    } elsif ($o1->[1] == STX_NUMBER) {

	if ($o2->[1] == STX_NODE) {
	    return _n_compare($o1,$self->F_number($o2),$op);

	} elsif ($o2->[1] == STX_STRING) {
	    return _n_compare($o1, $self->F_number($o2), $op);

	} elsif ($o2->[1] == STX_NUMBER) {
	    return _n_compare($o1, $o2, $op);

	} elsif ($o2->[1] == STX_BOOLEAN) {
	    if ($op eq '=' or $op eq '!=') {
		return _n_compare($self->F_boolean($o1), $o2, $op);
	    } else {
		return _n_compare($o1, $self->F_number($o2), $op);
	    }
	}

    } elsif ($o1->[1] == STX_BOOLEAN) {

	if ($o2->[1] == STX_NODE) {
	    return _n_compare($o1, $self->F_boolean($o2), $op);

	} elsif ($o2->[1] == STX_STRING) {
	    if ($op eq '=' or $op eq '!=') {
		return _n_compare($o1, $self->F_boolean($o2), $op);
	    } else {
		return _n_compare($self->F_number($o1), 
				  $self->F_number($o2), $op);
	    }

	} elsif ($o2->[1] == STX_NUMBER) {
	    if ($op eq '=' or $op eq '!=') {
		return _n_compare($o1, $self->F_boolean($o2), $op);
	    } else {
		return _n_compare($self->F_number($o1), $o2, $op);
	    }

	} elsif ($o2->[1] == STX_BOOLEAN) {
	    if ($op eq '=' or $op eq '!=') {
		return _n_compare($o1, $o2, $op);
	    } else {
		return _n_compare($self->F_number($o1), 
				  $self->F_number($o2), $op);
	    }
	}
    }
}

sub _s_compare {
    my ($o1, $o2, $op) = @_;

    #print "EXP: s_compare $o1->[0] $op $o2->[0]\n";
    if ($op eq '=') {
	return 1 if $o1->[0] eq $o2->[0];

    } elsif ($op eq '!=') {
	return 1 if $o1->[0] ne $o2->[0];

    } elsif ($op eq '>') {
	return 1 if $o1->[0] gt $o2->[0];

    } elsif ($op eq '>=') {
	return 1 if $o1->[0] ge $o2->[0];

    } elsif ($op eq '<') {
	return 1 if $o1->[0] lt $o2->[0];

    } else { # <=
	return 1 if $o1->[0] le $o2->[0];
	
    }
    return 0;
}

sub _n_compare {
    my ($o1, $o2, $op) = @_;

    #print "EXP: n_compare $o1->[0] $op $o2->[0]\n";
    if ($op eq '=') {
	return 1 if $o1->[0] == $o2->[0];

    } elsif ($op eq '!=') {
	return 1 if $o1->[0] != $o2->[0];

    } elsif ($op eq '>') {
	return 1 if $o1->[0] > $o2->[0];

    } elsif ($op eq '>=') {
	return 1 if $o1->[0] >= $o2->[0];

    } elsif ($op eq '<') {
	return 1 if $o1->[0] < $o2->[0];

    } else { # <=
	return 1 if $o1->[0] <= $o2->[0];
    }
    return 0;
}

sub _get_group_variable {
    my ($self, $name) = @_;

    my $g = $self->{STX}->{c_group} ? $self->{STX}->{c_group} 
      : $self->{STX}->{Sheet}->{dGroup};

    return $g->{vars}->[-1]->{$name}->[0] if $g->{vars}->[-1]->{$name};

    while ($g->{group}) {
	$g = $g->{group};
	return $g->{vars}->[-1]->{$name}->[0] if $g->{vars}->[-1]->{$name};
    }
    return undef;
}

sub _dbg_print {
    my ($routine, $result) = @_;
    my @out = ("$routine:");

    foreach (@{$result}) {
	if (ref $_->[0]) {
	    push @out, ($_->[0]->{Name} 
			or $_->[0]->{Data} 
			or $_->[0]->{Value} 
			or $_->[0]->{Type});
	} else {
	    push @out, $_->[0];
	}
    }
    push @out, "\n";
    return join(' ', @out);
}

1;
__END__

=head1 XML::STX::STXPath

XML::STX::STXPath - STXPath evaluator

=head1 SYNOPSIS

no public API, used from XML::STX

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 CREDITS

This modules has been inspired by XML::XPath by Matt Sergeant.

=head1 SEE ALSO

XML::STX, perl(1).

=cut

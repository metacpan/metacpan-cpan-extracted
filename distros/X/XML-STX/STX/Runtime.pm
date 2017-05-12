package XML::STX::Runtime;

require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;
use XML::SAX::Base;
use XML::NamespaceSupport;
use XML::STX::Base;
use XML::STX::STXPath;
use XML::STX::Parser;
use Clone qw(clone);

@XML::STX::Runtime::ISA = qw(XML::SAX::Base XML::STX::Base);

# --------------------------------------------------

sub new {
    my $timeI = 0;
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $options = ($#_ == 0) ? shift : { @_ };

    my $self = bless $options, $class;
    # turn NS processing on by default
    $self->set_feature('http://xml.org/sax/features/namespaces', 1);

    $self->{SoS} = [];   # stack of stacks to keep stacks on process-document
    $self->{nodeID} = 0; # global counter to generate node IDs
    return $self;
}

# content ----------------------------------------

sub start_document {
    my $self = shift;
    #print "STX: start_document\n";

    my $frame = {Type => STX_ROOT_NODE, 
		 Index => 0, 
		 Name => '/',
		 ID => $self->{nodeID}++,
		};

    $self->_current_node([STXE_START_DOCUMENT, $frame]);
}

sub end_document {
    my $self = shift;
    #print "STX: end_document\n";

    $self->_current_node([STXE_END_DOCUMENT]);

    # lookahead clean-up
    $self->_current_node([0]);

    return scalar @{$self->{Stack}};
}

sub start_element {
    my $self = shift;
    my $el = shift;
    #print "STX: start_element: $el->{Name}\n";

    $el->{Type} = STX_ELEMENT_NODE;
    $el->{ID} = $self->{nodeID}++;

    $self->_current_node([STXE_START_ELEMENT, $el]);
}

sub end_element {
    my $self = shift;
    my $el = shift;
    #print "STX: end_element: $el->{Name}\n";

    $self->_current_node([STXE_END_ELEMENT]);
}

sub characters {
    my $self = shift;
    my $char = shift;
    #print "STX: characters: $char->{Data}\n";

    if ($self->{lookahead}->[0] == STXE_CHARACTERS) {
	$self->{lookahead}->[1]->{Data} .= $char->{Data};
	
    } else {
	$char->{Type} = $self->{CDATA} ? STX_CDATA_NODE : STX_TEXT_NODE;
	$char->{ID} = $self->{nodeID}++;

	$self->_current_node([STXE_CHARACTERS, $char]);
    }
}

sub processing_instruction {
    my $self = shift;
    my $pi = shift;
    #print "STX: pi: $pi->{Target}\n";

    $pi->{Type} = STX_PI_NODE;
    $pi->{ID} = $self->{nodeID}++;

    $self->_current_node([STXE_PI, $pi]);
}

sub ignorable_whitespace {
}

sub start_prefix_mapping {
    my ($self, $map) = @_;

    $self->_current_node([STXE_START_PREF, $map]);
}

sub end_prefix_mapping {
    my ($self, $map) = @_;

    $self->_current_node([STXE_END_PREF, $map]);
}

sub skipped_entity {
}

# lexical ----------------------------------------

sub start_cdata {
    my $self = shift;
    #print "STX: start_cdata\n";

    if ($self->_get_base_group()->{Options}->{'recognize-cdata'}) {
	$self->_current_node([STXE_START_CDATA]);
	$self->{CDATA} = 1; 
    }
}

sub end_cdata {
    my $self = shift;
    #print "STX: end_cdata\n";

    if ($self->_get_base_group()->{Options}->{'recognize-cdata'}) {
 	$self->_current_node([STXE_END_CDATA]);
  	$self->{CDATA} = 0;
    }
}

sub comment {
    my $self = shift;
    my $comment = shift;
    #print "STX: comment: $comment->{Data}\n";

    $comment->{Type} =  STX_COMMENT_NODE;
    $comment->{ID} = $self->{nodeID}++;

    $self->_current_node([STXE_COMMENT, $comment]);
}

sub start_dtd {
}

sub end_dtd {
}

sub start_entity {
}

sub end_entity {
}

# error ----------------------------------------

sub warning {
}

sub error {
}

sub fatal_error {
}

# SAX1 ----------------------------------------

sub xml_decl {
}

# internal ----------------------------------------

sub change_stream {
    my ($self, $event) = @_;
    #print "STX: change_stream: $event\n";

    $self->_current_node([$event]);
}

# --------------------------------------------------

sub _current_node {
    my ($self, $next) = @_;

    my $current;

    if ($next->[0] == STXE_START_BUFFER) {
	push @{$self->{_sla}}, $self->{lookahead};
	$self->{lookahead} = $next;
	return;

    } elsif ($next->[0] == STXE_END_BUFFER) {
	$current = $self->{lookahead};
	$self->{lookahead} = pop @{$self->{_sla}};

    } else {
	$current = $self->{lookahead};
	$self->{lookahead} = $next;
    }
    
    if ($current) {

	if ($current->[0] == STXE_START_DOCUMENT) {
	    $self->{root} = $current->[1];
	    $self->_start_document($current->[1]);

	} elsif ($current->[0] == STXE_END_DOCUMENT) {
	    $self->_end_document;

	} elsif ($current->[0] == STXE_START_ELEMENT) {
	    $self->_start_element($current->[1]);

	} elsif ($current->[0] == STXE_END_ELEMENT) {
	    $self->_end_element;

	} elsif ($current->[0] == STXE_CHARACTERS) {
	    $self->_characters($current->[1]);

	} elsif ($current->[0] == STXE_PI) {
	    $self->_processing_instruction($current->[1]);

	} elsif ($current->[0] == STXE_COMMENT) {
	    $self->_comment($current->[1]);

	} elsif ($current->[0] == STXE_START_PREF) {
	    $self->_start_prefix_mapping($current->[1]);

	} elsif ($current->[0] == STXE_END_PREF) {
	    $self->_end_prefix_mapping($current->[1]);

	}
    }
}

sub _start_document {
    my ($self, $root) = @_;
    #print "STX: > _start_document\n";

    $self->{Stack} = []; # ancestor stack
    $self->{Counter} = []; # position()
    $self->{byEnd} = {}; # stack for instructions after process-children
    $self->{byEndSib} = {}; # stack for instructions after process-siblings

    $self->{OutputStack} ||= []; # output stack
    $self->{LookUp} ||= [1]; # lookup for templates
    $self->{SP} ||= XML::STX::STXPath->new($self);

    $self->{ns} = XML::NamespaceSupport->new({ xmlns => 1 });
    $self->{ns_out} ||= XML::NamespaceSupport->new({ xmlns => 1 });

    $self->{_g_prefix} ||= 0;
    $self->{_stx_element} ||= [];
    $self->{_self} ||= 0;
    $self->{_handlers} ||= [];
    $self->{_c_template} ||= [];
    $self->{_params} ||= [];

    $self->{ns}->pushContext;

    # counter
    #$self->{Counter}->[0] = {};
    $self->_counter(0, '/root', '/node');

    $self->SUPER::start_document;

    #new
    push @{$self->{Stack}}, $root;
    push @{$self->{LookUp}}, 0;
    $self->_process;
}

sub _end_document {
    my $self = shift;
    #print "STX: > _end_document\n";

    my $node = $self->{Stack}->[0];

    # run 2nd part of template if any
    if (defined $self->{byEnd}->{0}) {

	while ($#{$self->{byEnd}->{0}} > -1) {
	    $self->_run_template(0, undef, 0, $node);
	    #shift @{$self->{exG}->{$node->{Index} + 1}};
	}
    }
    $self->{exG}->{1} = undef; #TBD: perhaps needless
    $self->{byEnd}->{0} = undef;

    pop @{$self->{Stack}};
    $self->{ns}->popContext;
    $self->SUPER::end_document;

    $self->doError(504, 3, $self->{OutputStack}->[-1]->{Name})
      if $#{$self->{OutputStack}} > -1 and $#{$self->{SoS}} == -1;    
}

sub _start_element {
    my ($self, $el) = @_;
    #print "STX: > _start_element: $el->{Name}\n"; xxx

    my $index = scalar @{$self->{Stack}};
    #$self->{Counter}->[$index] or $self->{Counter}->[$index] = {};

    $el->{Prefix} = '' unless defined $el->{Prefix};
    $self->_counter($index, '/node', '/star', "$el->{Prefix}:/star", 
		    "/star:$el->{LocalName}", "$el->{Prefix}:$el->{LocalName}");

    $el->{Index} = $index;
    $el->{Counter} = $self->{Counter}->[$index];

    # string value
    if ($self->{lookahead}->[0] == STXE_CHARACTERS) {
	$el->{Value} = $self->{lookahead}->[1]->{Data};
    } else {
	$el->{Value} = '';
    }

    # attributes
    foreach (keys %{$el->{Attributes}}) {
 	$el->{Attributes}->{$_}->{Type} = STX_ATTRIBUTE_NODE;
 	$el->{Attributes}->{$_}->{Index} = $index + 1;
	$el->{Attributes}->{$_}->{ID} => $self->{nodeID}++,
     }

    # NS context + declarations
    $self->{ns}->pushContext;
    foreach (keys %{$self->{_start_prefmap}}) {
	$self->{ns}->declare_prefix($_, $self->{_start_prefmap}->{$_});
    }
    $self->{_start_prefmap} = {};
    
    # in-scope NS
    $el->{inScopeNS} = {};
    foreach ($self->{ns}->get_prefixes()) {
	$el->{inScopeNS}->{$_} = $self->{ns}->get_uri($_);
    }
    if ($self->{ns}->get_uri('')) {
	$el->{inScopeNS}->{''} = $self->{ns}->get_uri('');
    }
 
    push @{$self->{Stack}}, $el;

    # process-siblings stuff ------------------------------ sss
    #print "-s->$el->{Name}:$index\n";
    if (defined $self->{byEndSib}->{$index}->[-1]) {
	my $while = $self->{byEndSib}->{$index}->[-1]->[3];
	my $until = $self->{byEndSib}->{$index}->[-1]->[4];

	my $r_wh = [1, 1];
	$r_wh = $self->{SP}->match($el, $while, [0], $el->{inScopeNS}, {})
	  if defined $while;
	    
	my $r_un = [0, 1];
	$r_un = $self->{SP}->match($el, $until, [0], $el->{inScopeNS}, {})
	  if defined $until;

	my $end = ($r_wh->[0] ? 0 : 1) + $r_un->[0];
	#print ">>$r_wh->[0]:$r_un->[0]:$end\n";

	if ($end) {
	    #print "STX: sibling doesn't match: running the 2nd part\n";
	    $self->_run_template(4, undef, $index, $el);
	    #shift @{$self->{exG}->{$index + 1}};
	    
	    pop @{$self->{_params}};
	}
    }

    push @{$self->{LookUp}}, 0;
    $self->_process;
}

sub _end_element {
    my $self = shift;

    my $node = $self->{Stack}->[-1];
    #print "STX: > _end_element $node->{Name} ($node->{Index})\n";

    # process-siblings stuff ------------------------------ zzz
    #print "-e->$node->{Name}:$node->{Index}\n";
    if (defined $self->{byEndSib}->{$node->{Index} + 1}->[-1]) {
	#print "STX: end of siblings: running the 2nd part\n";
	$self->_run_template(4, undef, $node->{Index} + 1, $node);
	#shift @{$self->{exG}->{$node->{Index} + 1}};
	shift @{$self->{byEndSib}->{$node->{Index} + 1}};
	pop @{$self->{_params}};
    }

    # process-children stuff ------------------------------
    if (defined $self->{byEnd}->{$node->{Index}}) {

	while ($#{$self->{byEnd}->{$node->{Index}}} > -1) {
	    $self->_run_template(0, undef, $node->{Index}, $node);
	    #shift @{$self->{exG}->{$node->{Index} + 1}};

	    pop @{$self->{_params}};
	}
    }
    $self->{exG}->{$node->{Index} + 1} = undef;
    $self->{byEnd}->{$node->{Index}} = undef;

    # cleaning counters ------------------------------
    my $index = scalar @{$self->{Stack}};
    $self->{Counter}->[$index] = {};

    pop @{$self->{LookUp}};
    pop @{$self->{Stack}};
    $self->{ns}->popContext;
}

sub _characters {
    my $self = shift;
    my $char = shift;
    #print "STX: > _characters: $char->{Data}\n";

    return if $self->_get_base_group()->{Options}->{'strip-space'}
      and $char->{Data} =~ /^\s*$/;

    my $index = scalar @{$self->{Stack}};
    #$self->{Counter}->[$index] or $self->{Counter}->[$index] = {};

    $self->_counter($index, '/node', '/text');
    $self->_counter($index, '/cdata') if $self->{CDATA};

    $char->{Index} = $index;
    $char->{Counter} = $self->{Counter}->[$index];

    push @{$self->{Stack}}, $char;
    push @{$self->{LookUp}}, 0;

    $self->_process;

    pop @{$self->{LookUp}};
    pop @{$self->{Stack}};
}

sub _processing_instruction {
    my $self = shift;
    my $pi = shift;
    #print "STX: > _pi: $pi->{Target}\n";

    my $index = scalar @{$self->{Stack}};
    $self->{Counter}->[$index] or $self->{Counter}->[$index] = {};

    $self->_counter($index, '/node', '/pi', "/pi:$pi->{Target}");

    $pi->{Index} = $index;
    $pi->{Counter} = $self->{Counter}->[$index];

    push @{$self->{Stack}}, $pi;
    push @{$self->{LookUp}}, 0;

    $self->_process;

    pop @{$self->{LookUp}};
    pop @{$self->{Stack}};
}

sub _comment {
    my $self = shift;
    my $comment = shift;
    #print "STX: > _comment: $comment->{Data}\n";

    my $index = scalar @{$self->{Stack}};
    #$self->{Counter}->[$index] or $self->{Counter}->[$index] = {};

    $self->_counter($index, '/node', '/comment');

    $comment->{Index} = $index;
    $comment->{Counter} = $self->{Counter}->[$index];

    push @{$self->{Stack}}, $comment;
    push @{$self->{LookUp}}, 0;

    $self->_process;

    pop @{$self->{LookUp}};
    pop @{$self->{Stack}};
}

sub _start_prefix_mapping {
    my ($self, $map) = @_;

    $self->{_start_prefmap}->{$map->{Prefix}} = $map->{NamespaceURI};
}

sub _end_prefix_mapping {
    my ($self, $map) = @_;

    $self->{_end_prefmap}->{$map->{Prefix}} = $map->{NamespaceURI};
}

# process ----------------------------------------

sub _process {
    my $self = shift;
    #print "STX: process> LookUp $self->{LookUp}->[-2]\n";

#     $self->_frameDBG;
#     $self->_counterDBG;
#     $self->_nsDBG;
#     $self->_grpDBG;

    # for debug & testing
    use Time::HiRes;
    my $t0 = Time::HiRes::time();

    if ($self->{LookUp}->[-2]) {

	# current node
	my $node = $self->{Stack}->[-1];

	# visible namespaces
 	my $ns = $node->{inScopeNS};

	# current group
	my $g;
	if ($#{$self->{Stack}} == 0 and $#{$self->{SoS}} == -1) {
	    # default group
	    $g = $self->{Sheet}->{dGroup};
	} else {
	    my $exG = $self->{exG}->{$node->{Index}}->[-1];
	    if ($exG) {
		# explicit group
		if ($self->{Sheet}->{named_groups}->{$exG}) {
		    $g = $self->{Sheet}->{named_groups}->{$exG};
		} else {
		    $self->doError(507, 2, $exG);
		    $g = $self->{Stack}->[-2]->{Group}->[-1];	    
		}
	    } else {
		# group of the recent matching template
		$g = $self->{Stack}->[-2] 
		  # the active stack
		  ? $self->{Stack}->[-2]->{Group}->[-1]
		    # accessing original stack moved by process-docuemnt
		    : $self->{SoS}->[-1]->[0]->[-1]->{Group}->[-1];
	    }
	}
	#print "STX: base group $g->{gid}\n";

	my $templates = $self->_match($ns, $node, $g);

	$self->{_child_nodes} = $self->_child_nodes;

	# run the best match template if any
	if ($templates->[0]) {
	    $node->{Group} = [$templates->[0]->{group}];

	    my $k = $templates->[0]->{_pos_key}->{step}->[0] 
	      ? $self->_counter_key($templates->[0]->{_pos_key}->{step}->[0])
		: '/root';

	    $self->_run_template(1, $templates, $ns, $node, 
				 $self->{Counter}->[$#{$self->{Stack}}]->{$k});

        # default rule is applied
	} else {
	    #print "STX: default rule\n";
	    $node->{Group} = [$g];

	    $self->_run_template(1, [$self->_get_def_template], $ns, $node);
	}

    } else {
	# even when there is no lookup a group must be recorded 
	# in order to determine options
	$self->{Stack}->[-1]->{Group} 
	  = [$self->{exG}->{$#{$self->{Stack}} + 1}->[-1] 
	     ? $self->{Sheet}->{named_groups}->
	     {$self->{exG}->{$#{$self->{Stack}}+1}->[-1]} 
	     : $self->{Stack}->[-2]->{Group}->[-1]];
    }

    # for debug & testing
    $self->{_time_process} += Time::HiRes::time() - $t0;
}

sub _process_attributes {
    my ($self, $node, $ns) = @_;
    #print "STX: processing attributes\n";
    
    # current group
    my $g;
    my $exG = $self->{exG}->{$node->{Index}}->[-1];
    if ($exG) {
	# explicit group
	if ($self->{Sheet}->{named_groups}->{$exG}) {
	    $g = $self->{Sheet}->{named_groups}->{$exG};
	} else {
	    $self->doError(507, 2, $exG);
	    $g = $node->{Group}->[-1];
	}
    } else {
	# group of the recent matching template
	$g = $node->{Group}->[-1];
    }
    #print "STX: base group $g->{gid}\n";

    foreach (keys %{$node->{Attributes}}) {
	my $templates = $self->_match($ns, $node->{Attributes}->{$_}, $g, 1);

	# run the best match template if any
	if ($templates->[0]) {

	    $node->{Attributes}->{$_}->{Group} = [$templates->[0]->{group}];

	    $self->{_pos} = undef;
	    push @{$self->{Stack}}, $node->{Attributes}->{$_};

	    $self->_run_template(1, $templates, $ns, 
				 $node->{Attributes}->{$_}, 0);

	    pop @{$self->{Stack}};
	    $node->{Attributes}->{$_}->{Group} = undef;
	    
        # default rule is applied
	} else {
	    #print "STX: default rule\n";
	    my $t = $self->_get_def_template;
	    $self->_run_template(1, [$t], $ns, $node);
	}
    }
}

sub _process_self {
    my ($self, $node, $ns, $env) = @_;
    #print "STX: processing self\n";

    # current group
    my $g;
    my $exG = $self->{exG}->{$node->{Index}}->[-1];
    if ($exG) {
	# explicit group
	if ($self->{Sheet}->{named_groups}->{$exG}) {
	    $g = $self->{Sheet}->{named_groups}->{$exG};
	} else {
	    $self->doError(507, 2, $exG);
	    $g = $node->{Group}->[-1];   
	}
    } else {
	# group of the recent matching template
	$g = $node->{Group}->[-1];
    }
    #print "STX: base group $g->{gid}\n";
    
    my $templates = $self->_match($ns, $node, $g);

    # excluded templates are excluded
    my $new_templates = [];
    foreach my $t (@$templates) {
	push @$new_templates, $t 
	  unless grep($t->{tid} == $_, @{$self->{_excluded_templates}});
    }

    # run the best match template if any
    if ($new_templates->[0]) {
	push @{$node->{Group}}, $templates->[0]->{group};

	my $k = $new_templates->[0]->{_pos_key}->{step}->[0] 
	  ? $self->_counter_key($new_templates->[0]->{_pos_key}->{step}->[0])
	    : '/root';
	my $pos = $self->{Counter}->[$#{$self->{Stack}}]->{$k};

	$self->_run_template(2, $new_templates, $env, $node);

    # default rule is applied
    } else {
	#print "STX: default rule\n";
	push @{$node->{Group}}, $g;
	my $t = $self->_get_def_template;
	$self->_run_template(1, [$t], $ns, $node);
    }
    pop @{$node->{Group}};
}

sub _call_procedure {
    my ($self, $name, $node, $env) = @_;
    #print "STX: call procedure: $name\n";

    # current group
    my $g;
    my $exG = $self->{exG}->{$node->{Index}}->[-1];
    if ($exG) {

	# explicit group
	if ($self->{Sheet}->{named_groups}->{$exG}) {
	    $g = $self->{Sheet}->{named_groups}->{$exG};
	} else {
	    $self->doError(507, 2, $exG);
	    $g = $node->{Group}->[-1];
	}
    } else {
	# group of the recent matching template
	$g = $node->{Group}->[-1];
    }
    #print "STX: base group $g->{gid}\n";
    
    # procedure
    my $p = $g->{pc1P}->{$name}
      || $g->{pc2P}->{$name} 
	|| $self->{Sheet}->{dGroup}->{pc3P}->{$name};

    $self->doError(508, 3, $name) unless $p;

    # run the template
    push @{$node->{Group}}, $p->{group};
    $self->_run_template(2, [$p], $env, $node);
    pop @{$node->{Group}}, $p->{group};
}

# matching ----------------------------------------

sub _match {
    my ($self, $ns, $node, $group, $att) = @_;

    my $templates = [];
    # there are different lists of templates for attributes and
    # all other nodes (in order to keep lists shorter)
    my $pc1 = $att ? 'pc1A' : 'pc1';
    my $pc2 = $att ? 'pc2A' : 'pc2';
    my $pc3 = $att ? 'pc3A' : 'pc3';

    if ($group->{$pc1}->[0]) {
	push @$templates, 
	  @{$self->_match_pc($node, $ns, $pc1, $group)};
    }
    return $templates if $templates->[0] and not($self->{_self});

    if ($group->{$pc2}->[0]) {
	push @$templates, 
	  @{$self->_match_pc($node, $ns, $pc2, $group)};
    }
    return $templates if $templates->[0] and not($self->{_self});

    if ($self->{Sheet}->{dGroup}->{$pc3}->[0]) {
	push @$templates, 
	  @{$self->_match_pc($node, $ns, $pc3, $self->{Sheet}->{dGroup})};
    }

    #print "STX: >winner $templates->[0]->{tid}\n" if $templates->[0];
    return $templates;
}

# match templates from a specified precedence category
sub _match_pc {
    my ($self, $node, $ns, $pc, $group) = @_;
    my $templates = [];
    my $current_p = -1e20;

    foreach my $t (@{$group->{$pc}}) {
	#print "STX: match $pc -> template $t->{tid}\n";
	#print "STX: self:$self->{_self} complex:$group->{_complex_priority}\n";

	next if grep($current_p >= $_, @{$t->{priority}})
	  and not($group->{_complex_priority} or $self->{_self});

	my $res = $self->{SP}->match($node, 
				     $t->{match},
				     $t->{priority},
				     $ns,
				     {}  # variables
				    );
	#print "STX: >matching $res->[0] | priority $res->[1]\n";

	if ($res->[0]) {

	    if (($group->{_complex_priority} or $self->{_self}) 
		and $current_p > $res->[1]) {
		push @$templates, $t;
	    } else {
		unshift @$templates, $t;
	    }
	    
	    $t->{_pos_key} = $res->[2]->[-1];
	    last unless $group->{_complex_priority} or $self->{_self};
	    $current_p = $res->[1] if $current_p < $res->[1];
	}
    }

    return $templates;
}

# run template ----------------------------------------

# run template instructions
sub _run_template {
    my ($self, $ctx, $templates, $i_ns, $c_node, $position) = @_;
    my $t;         # template to be run
    my $start = 0; # the first instruction to be processed
    my $env;       # environment (ns, condition stack, etc.)
    my $ns;        # namespaces

    # new template
    if ($ctx == 1) {
	$t = $templates->[0];
	$env = { condition => [1], 
		 position => $position, 
		 ns => $i_ns,
	       };
	$self->{position} = $position;
	$ns = $i_ns;

    # self & procedures OR internal loop (for-each-item/while)
    } elsif ($ctx == 2 or $ctx == 3) {
	$t = $templates->[0];
	$env = $i_ns;
	$self->{position} = $env->{position};
	$ns = $env->{ns};

    # 2nd part of template after stx:process-siblings
    } elsif ($ctx == 4) {
	my $byEnd = pop @{$self->{byEndSib}->{$i_ns}};
	$t = $byEnd->[0];
	$start = $byEnd->[1];
	$env = $byEnd->[2];
	$self->{position} = $env->{position};
	$ns = $env->{ns};

    # 2nd part of template after stx:process-children
    } else {
	my $byEnd = shift @{$self->{byEnd}->{$i_ns}};
	$t = $byEnd->[0];
	$start = $byEnd->[1];
	$env = $byEnd->[2];
	$self->{position} = $env->{position};
	$ns = $env->{ns};
    }

    # new variables on recursion
    if ($t->{'new-scope'} and ($ctx == 1 or $ctx == 2)) {
	push @{$t->{group}->{vars}}, {};

	foreach (keys %{$t->{group}->{vars}->[-2]}) {

	    $t->{group}->{vars}->[-1]->{$_} 
	      = clone($t->{group}->{vars}->[-2]->{$_});

 	    $t->{group}->{vars}->[-1]->{$_}->[0] 
	      = clone($t->{group}->{vars}->[-1]->{$_}->[1])
 		unless $t->{group}->{vars}->[-1]->{$_}->[2];
	}
    }
    # new local variables
    push @{$t->{vars}}, {} if $ctx == 1 or $ctx == 2;

    # new buffers on recursion
    if ($t->{'new-scope'} and ($ctx == 1 or $ctx == 2)) {
	push @{$t->{group}->{bufs}}, {};

	foreach (keys %{$t->{group}->{bufs}->[-2]}) {

	    $t->{group}->{bufs}->[-1]->{$_} 
	      = clone($t->{group}->{bufs}->[-2]->{$_});

 	    $t->{group}->{bufs}->[-1]->{$_}->[0]
 	      = clone($t->{group}->{bufs}->[-1]->{$_}->[1])
 		unless $t->{group}->{bufs}->[-1]->{$_}->[2];
	}
    }
    # new local buffers
    push @{$t->{bufs}}, {} if $ctx == 1 or $ctx == 2;

    #print "STX: running template $t->{tid}\n";
    
    my $out = {};       # out element buffer
    my $text = '';      # out text buffer
    my $children = 0;   # interrupted by process-children
    my $siblings = 0;   # interrupted by process-siblings
    my $skipped_if = 0; # number of nested skipped stx:if
    $env->{elsif}  = 0; # elsif (when) has already been evaluated

    push @{$self->{_c_template}}, $t;
    $self->{c_group} = $t->{group};

    # the main loop over instructions
    for (my $j = $start; $j < @{$t->{instructions}}; $j++) {

	my $i = $t->{instructions}->[$j];
	#print "STX: =>$j:$i->[0]\n";
	#print "STX: cond: $env->{condition}->[-1]\n";

	# resolving conditions
	unless ($env->{condition}->[-1]) {

	    if ($i->[0] == I_IF_START) {
		$skipped_if++;
		next;

	    } elsif ($i->[0] == I_IF_END or $i->[0] == I_ELSIF_END 
		     or $i->[0] == I_ELSE_END) {
		if ($skipped_if > 0) { 
		    $skipped_if--; 
		    next; 
		}

	    } else { 
		next;		
	    }
	}

	# I_LITERAL_START ----------------------------------------
	if ($i->[0] == I_LITERAL_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    $out = exists $i->[1]->{Attributes} ? clone($i->[1]) : $i->[1];

  	    foreach (keys %{$out->{Attributes}}) {
 		$out->{Attributes}->{$_}->{Value} 
 		  = $self->_expand($out->{Attributes}->{$_}->{Value}, $ns)
 		    if exists $out->{Attributes}->{$_}->{Value};  
 	    }

	# I_LITERAL_END ----------------------------------------
	} elsif ($i->[0] == I_LITERAL_END) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    $out = $self->_send_element_end($i->[1]);

	# I_ELEMENT_START ----------------------------------------
	} elsif ($i->[0] == I_ELEMENT_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    $out = $self->_resolve_element($i);

	    push @{$self->{_stx_element}}, $out;

	# I_ELEMENT_END ----------------------------------------
	} elsif ($i->[0] == I_ELEMENT_END) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    if ($i->[1]) {
		$out = $self->_resolve_element($i);

	    } else {
		$out = $self->{_stx_element}->[-1];
	    }
	    pop @{$self->{_stx_element}};
	    $out = $self->_send_element_end($out);

	# I_ATTRIBUTE_START ----------------------------------------
	} elsif ($i->[0] == I_ATTRIBUTE_START) {

	    my $at = $self->_resolve_element($i, 1); # aflag set
	    my $nsuri = $at->{NamespaceURI} ? $at->{NamespaceURI} : '';
	    $out->{Attributes}->{"{$nsuri}$at->{LocalName}"} = $at;

	    if ($i->[4]) {
		my $val = $self->_expand($i->[4], $ns);
		$val = $self->{SP}->F_normalize_space([[$val,STX_STRING]]);

		$out->{Attributes}->{"{$nsuri}$at->{LocalName}"}->{Value}
		  = $val->[0]->[0];

	    } else {
		$self->{_TTO} = $at; # text template object
		$self->{_text_cache} = '';
	    }

	# I_ATTRIBUTE_END ----------------------------------------
	} elsif ($i->[0] == I_ATTRIBUTE_END) {

	    if ($self->{_TTO}) {

		my $val = $self->{SP}->F_normalize_space([[$self->{_text_cache},
							   STX_STRING]]);
		my $nsuri = $self->{_TTO}->{NamespaceURI} 
		  ? $self->{_TTO}->{NamespaceURI} : '';
		$out->{Attributes}->{"{$nsuri}$self->{_TTO}->{LocalName}"}->{Value} 
		  = $val->[0]->[0];

		$self->{_TTO} = undef;
		$self->{_text_cache} = undef;
	    }

	# I_P_CHILDREN_START ----------------------------------------
	} elsif ($i->[0] == I_P_CHILDREN_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    my $exg = $i->[1] ? $i->[1] : undef;
	    $self->{exG}->{$c_node->{Index} + 1} = [$exg];
	    push @{$self->{_params}}, {};

	# I_P_CHILDREN_END ----------------------------------------
	} elsif ($i->[0] == I_P_CHILDREN_END) {
	    next unless $self->{_child_nodes};

	    my $fi = $c_node->{Index};
	    # pointer to the template, the number of the next
	    # instruction, and environment is put to 'byEnd' stack

	    $self->{byEnd}->{$fi} = [[$t, $j+1, $env]];
	    $self->{LookUp}->[-1] = 1;

	    $children = 1;
	    last;

	# I_P_SIBLINGS_START ----------------------------------------
	} elsif ($i->[0] == I_P_SIBLINGS_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    my $exg = $i->[1] ? $i->[1] : undef;
	    $self->{exG}->{$c_node->{Index}} = [$exg];
	    push @{$self->{_params}}, {};

	# I_P_SIBLINGS_END ---------------------------------------- xxx
	} elsif ($i->[0] == I_P_SIBLINGS_END) {

	    my $fi = $c_node->{Index};
	    # pointer to the template, the number of the next
	    # instruction, and environment is put to 'byEnd' stack

	    if (ref $self->{byEndSib}->{$fi}) {
		push @{$self->{byEndSib}->{$fi}}, 
		  [$t, $j+1, $env, $i->[1], $i->[2]];

	    } else {
		$self->{byEndSib}->{$fi} = [[$t, $j+1, $env, $i->[1], $i->[2]]];
	    }

	    $self->{LookUp}->[-1] = 1;
	    $siblings = 1;
	    last;

	# I_P_ATTRIBUTES_START ----------------------------------------
	} elsif ($i->[0] == I_P_ATTRIBUTES_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    my $exg = $i->[1] ? $i->[1] : undef;
	    push @{$self->{exG}->{$c_node->{Index}}}, $exg;
	    push @{$self->{_params}}, {};

	# I_P_ATTRIBUTES_END ----------------------------------------
	} elsif ($i->[0] == I_P_ATTRIBUTES_END) {
	    next unless $c_node->{Type} == STX_ELEMENT_NODE;

	    $self->_process_attributes($c_node, $ns);

	    pop @{$self->{exG}->{$c_node->{Index}}};
	    pop @{$self->{_params}};

	# I_P_SELF_START ----------------------------------------
	} elsif ($i->[0] == I_P_SELF_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    # explicit group
	    my $exg = $i->[1] ? $i->[1] : undef;
	    push @{$self->{exG}->{$c_node->{Index}}}, $exg;

	    #excluded templates
	    if (ref $self->{_excluded_templates}) {
		push @{$self->{_excluded_templates}}, $t->{tid};
	    } else {
		$self->{_excluded_templates} = [$t->{tid}];
	    }

	    push @{$self->{_params}}, {};

	# I_P_SELF_END ----------------------------------------
	} elsif ($i->[0] == I_P_SELF_END) {

	    $self->{_self} = 1;

	    $self->_process_self($c_node, $ns, $env);

	    # process-children has been called inside
 	    if ($self->{byEnd}->{$c_node->{Index}}) {
 		push @{$self->{byEnd}->{$c_node->{Index}}}, [$t, $j+1, $env];
 		$children = 1;
 		last;
 	    }

	    pop @{$self->{exG}->{$c_node->{Index}}};
	    pop @{$self->{_excluded_templates}};
	    pop @{$self->{_params}};
	    $self->{_self} = 0;

	# I_CALL_PROCEDURE_START ----------------------------------------
	} elsif ($i->[0] == I_CALL_PROCEDURE_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};
	    
	    # explicit group
	    my $exg = $i->[2] ? $i->[2] : undef;
	    push @{$self->{exG}->{$c_node->{Index}}}, $exg;

	    $self->{_procedure_name} = $i->[1];
	    push @{$self->{_params}}, {};

	# I_CALL_PROCEDURE_END ----------------------------------------
	} elsif ($i->[0] == I_CALL_PROCEDURE_END) {

	    $self->_call_procedure($self->{_procedure_name}, $c_node, $env);

	    # process-children has been called inside
 	    if ($self->{byEnd}->{$c_node->{Index}}) {
 		push @{$self->{byEnd}->{$c_node->{Index}}}, [$t, $j+1, $env];
 		$children = 1;
 		last;
 	    }

	    pop @{$self->{exG}->{$c_node->{Index}}};
	    pop @{$self->{_params}};

	# I_CHARACTERS ----------------------------------------
	} elsif ($i->[0] == I_CHARACTERS) {
	    $out = $self->_send_element_start($out) 
	      if (exists $out->{Name} and not($self->{_TTO}));

	    # stx:value-of
	    if (defined $i->[2]) {
		$self->_send_text(
			  $self->{SP}->F_string_join(
				     $self->_eval($i->[1],$ns),
				     [[$self->_expand($i->[2],$ns), STX_STRING]]
						    )->[0]->[0]
				 );
	    # stx:text
	    } else {
		$self->_send_text($self->_expand($i->[1], $ns));
	    }

	# I_COPY_START ----------------------------------------
	} elsif ($i->[0] == I_COPY_START) {

	    my $type = $c_node->{Type};

	    if ($type == STX_ELEMENT_NODE) {
		$out = $self->_send_element_start($out) if exists $out->{Name};

  		$out->{Name} = $c_node->{Name};
  		$out->{LocalName} = $c_node->{LocalName};
  		$out->{Prefix} = $c_node->{Prefix} 
  		  if exists $c_node->{Prefix};
  		$out->{NamespaceURI} = $c_node->{NamespaceURI}
  		  if exists $c_node->{NamespaceURI};

		$out->{Attributes} = {};
		my @att = split(' ', $i->[1]);

		foreach my $a (keys %{$c_node->{Attributes}}) {

		    if ($i->[1] eq '#all' 
			or grep($_ eq $c_node->{Attributes}->{$a}->{Name}, @att)) {

			$out->{Attributes}->{$a} = $c_node->{Attributes}->{$a};
		    }
		}

	    } elsif ($type == STX_TEXT_NODE) {
		$out = $self->_send_element_start($out) if exists $out->{Name};

		$self->_send_text($c_node->{Data});

	    } elsif ($type == STX_CDATA_NODE) {
		$out = $self->_send_element_start($out) if exists $out->{Name};

		$self->SUPER::start_cdata() unless $self->{_TTO};
		$self->_send_text($c_node->{Data});
		$self->SUPER::end_cdata() unless $self->{_TTO};

	    } elsif ($type == STX_PI_NODE) {
		$out = $self->_send_element_start($out) if exists $out->{Name};

		$self->SUPER::processing_instruction(
				{Target => $c_node->{Target}, 
				 Data => $c_node->{Data}});

	    } elsif ($type == STX_COMMENT_NODE) {
		$out = $self->_send_element_start($out) if exists $out->{Name};

		$self->SUPER::comment({Data => $c_node->{Data}});

	    } elsif ($type == STX_ATTRIBUTE_NODE) {
		#tbd !!!

	    }

	# I_COPY_END ----------------------------------------
	} elsif ($i->[0] == I_COPY_END) {

	    my $type = $c_node->{Type};
	    if ($type == STX_ELEMENT_NODE) {
		$out = $self->_send_element_start($out) if exists $out->{Name};

		$out = $self->_send_element_end($c_node);
	    }
	    # else: ignore </copy> for other types of nodes

	# I_CDATA_START ----------------------------------------
	} elsif ($i->[0] == I_CDATA_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    $self->SUPER::start_cdata();

	# I_CDATA_END ----------------------------------------
	} elsif ($i->[0] == I_CDATA_END) {

	    $self->SUPER::end_cdata();

	# I_COMMENT_START ----------------------------------------
	} elsif ($i->[0] == I_COMMENT_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    $self->{_TTO} = 'COM'; # comment
	    $self->{_text_cache} = '';

	# I_COMMENT_END ----------------------------------------
	} elsif ($i->[0] == I_COMMENT_END) {

	    $self->SUPER::comment({ Data => $self->{_text_cache} });

	    $self->{_TTO} = undef;
	    $self->{_text_cache} = undef;

	# I_PI_START ----------------------------------------
	} elsif ($i->[0] == I_PI_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    my $target = $self->_expand($i->[1], $ns);
	    $self->doError(502, 3, 'name', 
			   '<stx:processing-instruction>', 
			   'non-qualified name', $target)
	      unless $target =~ /^$NCName$/o;

	    $self->{_TTO} = $target; # PI target
	    $self->{_text_cache} = '';

	# I_PI_END ----------------------------------------
	} elsif ($i->[0] == I_PI_END) {

	    $self->SUPER::processing_instruction({
					Data => $self->{_text_cache},
					Target => $self->{_TTO},
					});

	    $self->{_TTO} = undef;
	    $self->{_text_cache} = undef;

	# I_VARIABLE_START ----------------------------------------
	} elsif ($i->[0] == I_VARIABLE_START) {

	    if ($i->[2] and $i->[3] == 0) {
		$t->{vars}->[-1]->{$i->[1]} = [$self->_eval($i->[2], $ns)];

	    } else {
		$self->{_TTO} = $i->[1]; # text template object
		$self->{_text_cache} = '';
	    }

	# I_VARIABLE_END ----------------------------------------
	} elsif ($i->[0] == I_VARIABLE_END) {

	    if ($self->{_TTO}) {

		$t->{vars}->[-1]->{$self->{_TTO}} 
		  = [$self->{SP}->F_normalize_space([[$self->{_text_cache},
						      STX_STRING]])];
		$self->{_TTO} = undef;
		$self->{_text_cache} = undef;
	    }

	# I_VARIABLE_SCOPE_END ----------------------------------------
	} elsif ($i->[0] == I_VARIABLE_SCOPE_END) {

	    $t->{vars}->[-1]->{$i->[1]} = undef;

	# I_PARAMETER_START ----------------------------------------
	} elsif ($i->[0] == I_PARAMETER_START) {

	    if ($self->{_params}->[-1]->{$i->[1]}) {
		$t->{vars}->[-1]->{$i->[1]} = [$self->{_params}->[-1]->{$i->[1]}];

	    } elsif ($i->[4]) {
		$self->doError(510, 3, $i->[1]);

	    } elsif ($i->[2] and $i->[3] == 0) {
		$t->{vars}->[-1]->{$i->[1]} = [$self->_eval($i->[2], $ns)];

	    } else {
		$self->{_TTO} = $i->[1]; # text template object
		$self->{_text_cache} = '';
	    }

	# I_ASSIGN_START ----------------------------------------
	} elsif ($i->[0] == I_ASSIGN_START) {

	    if ($i->[2]) {
		my $var = $self->_get_objects($i->[1]);
		$self->doError(505, 3, 'variable', $i->[1]) unless $var; 

		$var->{$i->[1]}->[0] = $self->_eval($i->[2], $ns);

	    } else {
		$self->{_TTO} = $i->[1]; # text template object
		$self->{_text_cache} = '';
	    }

	# I_ASSIGN_END ----------------------------------------
	} elsif ($i->[0] == I_ASSIGN_END) {

	    if ($self->{_TTO}) {

		my $var = $self->_get_objects($self->{_TTO});
		$self->doError(505, 3, 'variable', $self->{_TTO}) unless $var; 
		$var->{$self->{_TTO}} = 
		  [$self->{SP}->F_normalize_space([[$self->{_text_cache},
						    STX_STRING]])];
		
		$self->{_TTO} = undef;
		$self->{_text_cache} = undef;
	    }

	# I_WITH_PARAM_START ----------------------------------------
	} elsif ($i->[0] == I_WITH_PARAM_START) {

	    if ($i->[2] and $i->[3] == 0) {
		$self->{_params}->[-1]->{$i->[1]} = $self->_eval($i->[2], $ns);

	    } else {
		$self->{_TTO} = $i->[1]; # text template object
		$self->{_text_cache} = '';
	    }

	# I_WITH_PARAM_END ----------------------------------------
	} elsif ($i->[0] == I_WITH_PARAM_END) {

	    if ($self->{_TTO}) {

		$self->{_params}->[-1]->{$self->{_TTO}} 
		  = $self->{SP}->F_normalize_space([[$self->{_text_cache},
						      STX_STRING]]);

		$self->{_TTO} = undef;
		$self->{_text_cache} = undef;
	    }

	# I_BUFFER_START ----------------------------------------
	} elsif ($i->[0] == I_BUFFER_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    # new buffer
	    my $b = XML::STX::Buffer->new($i->[1]);
	    $t->{bufs}->[-1]->{$i->[1]} = $b;

 	    push @{$self->{_handlers}}, $self->{Handler};
 	    $self->{Handler} = $b;
	    $self->{Methods} = {}; # to empty methods cached by XML::SAX::Base
 	    $self->{Handler}->init($self); # to initialize buffer
 	    #print "STX: new handler:$self->{Handler}\n";

	# I_BUFFER_END ----------------------------------------
	} elsif ($i->[0] == I_BUFFER_END) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

 	    $self->{Handler} = pop @{$self->{_handlers}};
	    $self->{Methods} = {}; # to empty methods cached by XML::SAX::Base
 	    #print "STX: orig handler:$self->{Handler}\n";

	# I_BUFFER_SCOPE_END ----------------------------------------
	} elsif ($i->[0] == I_BUFFER_SCOPE_END) {

	    $t->{bufs}->[-1]->{$i->[1]} = undef;

 	# I_RES_BUFFER_START ----------------------------------------
 	} elsif ($i->[0] == I_RES_BUFFER_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

 	    my $buf = $self->_get_objects($i->[1], 1);
 	    $self->doError(505, 3, 'buffer', $i->[1]) unless $buf; 

 	    push @{$self->{_handlers}}, $self->{Handler};
 	    $self->{Handler} = $buf->{$i->[1]};
	    $self->{Methods} = {}; # to empty methods cached by XML::SAX::Base
 	    $self->{Handler}->init($self, $i->[2]); # to initialize buffer
 	    #print "STX: new handler:$self->{Handler}\n";

 	# I_RES_BUFFER_END ----------------------------------------
 	} elsif ($i->[0] == I_RES_BUFFER_END) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

 	    $self->{Handler} = pop @{$self->{_handlers}};
	    $self->{Methods} = {}; # to empty methods cached by XML::SAX::Base
 	    #print "STX: orig handler:$self->{Handler}\n";

	# I_P_BUFFER_START ----------------------------------------
	} elsif ($i->[0] == I_P_BUFFER_START) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    my $exg = $i->[2] ? $i->[2] : undef;
	    push @{$self->{exG}->{$c_node->{Index} + 1}}, $exg;

 	    $self->{_buffer} = $self->_get_objects($i->[1], 1)->{$i->[1]};
	    push @{$self->{_params}}, {};

 	# I_P_BUFFER_END ----------------------------------------
 	} elsif ($i->[0] == I_P_BUFFER_END) {

 	    $self->{LookUp}->[-1] = 1;

 	    $self->{_buffer}->process();

 	    $self->{_child_nodes} = $self->_child_nodes;
 	    pop @{$self->{LookUp}};
 	    pop @{$self->{exG}->{$c_node->{Index} + 1}};
	    pop @{$self->{_params}};

  	# I_RES_DOC_START ----------------------------------------
  	} elsif ($i->[0] == I_RES_DOC_START) {
 	    $out = $self->_send_element_start($out) if exists $out->{Name};

 	    my $href = $self->_expand($i->[1], $ns);
	    $self->doError(502, 3, 'href', '<stx:result-document>',
			   'URI reference', $href) 
	      unless $href =~ /^$URIREF$/o;

	    my $result = $self->{URIResolver}->resolve_result($href);	    

  	    push @{$self->{_handlers}}, $self->{Handler};
  	    $self->{Handler} = $result->{Handler};
 	    $self->{Methods} = {}; # to reset methods cached by XML::SAX::Base
  	    #print "STX: new handler:$self->{Handler}\n";

  	# I_RES_DOC_END ----------------------------------------
  	} elsif ($i->[0] == I_RES_DOC_END) {
 	    $out = $self->_send_element_start($out) if exists $out->{Name};

  	    $self->{Handler} = pop @{$self->{_handlers}};
 	    $self->{Methods} = {}; # to reset methods cached by XML::SAX::Base
  	    #print "STX: orig handler:$self->{Handler}\n";

 	# I_P_DOC_START ----------------------------------------
 	} elsif ($i->[0] == I_P_DOC_START) {
 	    $out = $self->_send_element_start($out) if exists $out->{Name};

 	    $self->{_href} = $self->_eval($i->[1], $ns);
 	    $self->{_exg} = $i->[2];
	    $self->{_base} = $i->[3];

 	    push @{$self->{_params}}, {};

  	# I_P_DOC_END ----------------------------------------
  	} elsif ($i->[0] == I_P_DOC_END) {

  	    $self->{LookUp}->[-1] = 1;

	    foreach (@{$self->{_href}}) {
		# resolving href
		my $base;
		if ($self->{_base}) {
		    $base = $self->_expand($self->{_base}, $ns);

		} else {
		    $base = ($_->[1] == STX_NODE) 
		      ? $self->{Source}->[-1]->{SystemId} 
			: $self->{Sheet}->{URI};
		}
		$self->doError(502, 3, 'base', '<stx:process-document>',
			       'URI reference|#input|#stylesheet', $base) 
		  unless $base =~ /^$URIREF$/o or $base eq '#stylesheet'
		    or $base eq '#input';

		my $uri = $self->{SP}->F_string([$_])->[0];
		
		my $source = $self->{URIResolver}->resolve($uri, $base);

		$source->{XMLReader}->{Handler} = $self;
		$source->{XMLReader}->{Source} = $source->{InputSource};

		push @{$self->{Source}}, $source;
		push @{$self->{SoS}}, 
		  [$self->{Stack}, $self->{Counter}, $self->{byEnd},
		   $self->{ns}, $self->{exG}];

		push @{$self->{exG}->{0}}, $self->{_exg};

		$self->change_stream(STXE_START_BUFFER);
		$source->{XMLReader}->parse();
		$self->change_stream(STXE_END_BUFFER);

		pop @{$self->{Source}};
		($self->{Stack},$self->{Counter},$self->{byEnd},$self->{ns}) 
		  = @{pop @{$self->{SoS}}};
	    }

  	    $self->{_child_nodes} = $self->_child_nodes;
  	    pop @{$self->{LookUp}};
 	    pop @{$self->{_params}};

	# I_IF_START ----------------------------------------
	} elsif ($i->[0] == I_IF_START) {

	    my $bool = $self->{SP}->F_boolean($self->_eval($i->[1], $ns));

	    if ($bool->[0]) {
		push @{$env->{condition}}, 1;			

	    } else {
		push @{$env->{condition}}, 0;			
	    }

	# I_IF_END ----------------------------------------
	} elsif ($i->[0] == I_IF_END) {

	    $env->{otherwise} = pop @{$env->{condition}} ? 0 : 1;

	# I_ELSIF_START ----------------------------------------
	} elsif ($i->[0] == I_ELSIF_START) {

	    my $bool = $env->{elsif}
	      ? [0] : $self->{SP}->F_boolean($self->_eval($i->[1], $ns));

	    if ($bool->[0]) {
		push @{$env->{condition}}, 1;
		$env->{elsif} = 1;

	    } else {
		push @{$env->{condition}}, 0;			
	    }
	    
	# I_ELSIF_END ----------------------------------------
	} elsif ($i->[0] == I_ELSIF_END) {

	    $env->{otherwise} = (pop @{$env->{condition}} or $env->{elsif}) 
	      ? 0 : 1;

	# I_ELSE_START ----------------------------------------
	} elsif ($i->[0] == I_ELSE_START) {

	    push @{$env->{condition}}, $env->{otherwise};			

	# I_ELSE_END ----------------------------------------
	} elsif ($i->[0] == I_ELSE_END) {

	    pop @{$env->{condition}};

  	# I_FOR_EACH_ITEM ----------------------------------------
  	} elsif ($i->[0] == I_FOR_EACH_ITEM) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    foreach my $item (@{$self->_eval($i->[2], $ns)}) {
		#print "STX: for-each-item: type $item->[1]\n";

 		# linking local variable and buffers
 		$i->[3]->{vars}->[0] = $t->{vars}->[-1];
 		$i->[3]->{bufs}->[0] = $t->{bufs}->[-1];
		$i->[3]->{vars}->[-1]->{$i->[1]} = [[$item]];
		# keeping existing variables and buffers
		my @eVars = keys %{$t->{vars}->[-1]};
		my @eBufs = keys %{$t->{bufs}->[-1]};

		$self->_run_template(3, [$i->[3]], $env, $c_node);

 		# removing added variablers and buffers
 		foreach my $var (keys %{$t->{vars}->[-1]}) {
 		    delete($t->{vars}->[-1]->{$var}) 
 		      unless grep($_ eq $var, @eVars);
 		}
 		foreach my $buf (keys %{$t->{bufs}->[-1]}) {
 		    delete($t->{bufs}->[-1]->{$buf}) 
 		      unless grep($_ eq $buf, @eBufs);
 		}
	    }

  	# I_WHILE ----------------------------------------
  	} elsif ($i->[0] == I_WHILE) {
	    $out = $self->_send_element_start($out) if exists $out->{Name};

	    my $bool = $self->{SP}->F_boolean($self->_eval($i->[1], $ns));

	    my $count = 0; # infinite loop protection;
	    while ($bool->[0] and $count < $self->{Options}->{LoopLimit}) {
		#print "STX: while: $bool->[0]\n";

 		# linking local variable and buffers
 		$i->[2]->{vars}->[0] = $t->{vars}->[-1];
 		$i->[2]->{bufs}->[0] = $t->{bufs}->[-1];
		# keeping existing variables and buffers
		my @eVars = keys %{$t->{vars}->[-1]};
		my @eBufs = keys %{$t->{bufs}->[-1]};

 		$self->_run_template(3, [$i->[2]], $env, $c_node);

 		# removing added variablers and buffers
 		foreach my $var (keys %{$t->{vars}->[-1]}) {
 		    delete($t->{vars}->[-1]->{$var}) 
 		      unless grep($_ eq $var, @eVars);
 		}
 		foreach my $buf (keys %{$t->{bufs}->[-1]}) {
 		    delete($t->{bufs}->[-1]->{$buf}) 
 		      unless grep($_ eq $buf, @eBufs);
 		}
		
		$bool = $self->{SP}->F_boolean($self->_eval($i->[1], $ns));
		$count++;
	    }

	}

    }

    # send element after the last instruction
    $out = $self->_send_element_start($out) if exists $out->{Name};

    if ($t->{'new-scope'} and not($children)) {
	pop @{$t->{group}->{vars}};
	pop @{$t->{group}->{bufs}};
    }
    pop @{$t->{vars}} unless $children;
    pop @{$t->{bufs}} unless $children;
    pop @{$self->{_c_template}};
}

# expands AVT to string
sub _expand {
    my ($self, $val, $ns) = @_;

    if (ref $val) {
	return $self->{SP}->F_string($self->_eval($val,$ns))->[0];

    } else {
	return $val;
    }
}

# evaluates expression to sequence
sub _eval {
    my ($self, $val, $ns) = @_;

    return $self->{SP}->expr([ $self->{Stack}->[-1] ], $val, $ns, {});
}

sub _send_element_start {
    my ($self, $out) = @_;

    $self->{ns_out}->pushContext; #??? tady

    $out->{Prefix} = '' unless $out->{Prefix};
    my $nsuri = $self->{ns_out}->get_uri($out->{Prefix});

    unless ($nsuri && $nsuri eq $out->{NamespaceURI}) {
	if ($out->{Prefix} or $out->{NamespaceURI}) {

	    $self->{ns_out}->declare_prefix($out->{Prefix}, $out->{NamespaceURI});
	    $self->SUPER::start_prefix_mapping({Prefix => $out->{Prefix},
					    NamespaceURI => $out->{NamespaceURI}});
	}
    }

    foreach (keys %{$out->{Attributes}}) {

	# removing declarations (these are passed with startPrefixMapping)
	if ($out->{Attributes}->{$_}->{NamespaceURI} eq XMLNS_URI
	   or $out->{Attributes}->{$_}->{Name} eq 'xmlns'
	    or $out->{Attributes}->{$_}->{Prefix} eq 'xmlns') {
	    
	    delete $out->{Attributes}->{$_};
	    next;
	}

	$out->{Attributes}->{$_}->{Prefix} = '' 
	  unless $out->{Attributes}->{$_}->{Prefix};
	my $nsuri = $self->{ns_out}->get_uri($out->{Attributes}->{$_}->{Prefix});

	unless ($nsuri && $nsuri eq $out->{Attributes}->{$_}->{NamespaceURI}) {
	    if ($out->{Attributes}->{$_}->{Prefix} 
		or $out->{Attributes}->{$_}->{NamespaceURI}) {

		$self->{ns_out}->declare_prefix(
			$out->{Attributes}->{$_}->{Prefix}, 
			$out->{Attributes}->{$_}->{NamespaceURI}
					   );
		$self->SUPER::start_prefix_mapping({
			Prefix => $out->{Attributes}->{$_}->{Prefix},
			NamespaceURI => $out->{Attributes}->{$_}->{NamespaceURI}
					       });
	    }
	}
    }

    $self->SUPER::start_element($out);
    push @{$self->{OutputStack}}, $out;

    return {};
}

sub _send_element_end {
    my ($self, $out) = @_;

    $self->SUPER::end_element($out);

    $self->{ns_out}->popContext;
    my $os =  pop @{$self->{OutputStack}};

    my $ns_out = defined $out->{NamespaceURI} ? $out->{NamespaceURI} : '';
    my $ns_os = defined $os->{NamespaceURI} ? $os->{NamespaceURI} : '';

    if (($ns_out ne $ns_os) or ($out->{LocalName} ne $os->{LocalName})) {
	
	$self->doError(503, 3, $os->{Name}, $out->{Name});
    }
    return {};
}

sub _send_text {
    my ($self, $text) = @_;

    if ($self->{_TTO}) {
	$self->{_text_cache} .= $text;

    } else {
	$self->SUPER::characters({ Data => $text });
    }
}

# returns either explicit or current group
sub _get_base_group {
    my $self = shift;

    return $self->{exG}->{$#{$self->{Stack}} + 1}->[-1] 
      ? $self->{Sheet}->{named_groups}->{$self->{exG}->{$#{$self->{Stack}}+1}->[-1]}
	: $self->{Stack}->[-1]->{Group}->[-1];
}

# util ----------------------------------------

sub _counter {
    my ($self, $index, @names) = @_;

    foreach (@names) {
	if (defined $self->{Counter}->[$index]->{$_}) {
	    $self->{Counter}->[$index]->{$_}++
	} else {
	    $self->{Counter}->[$index]->{$_} = 1;
	}
    }
}

sub _generate_prefix {
    my $self = shift;

    my $g_pref = "g$self->{_g_prefix}";
    $self->{_g_prefix}++;

    my @prefixes = $self->{ns_out}->get_prefixes;
    while (grep($_ eq $g_pref, @prefixes)) {
	$g_pref = "g$self->{_g_prefix}";
	$self->{_g_prefix}++;
    }
    return $g_pref;
}

sub _resolve_element {
    my ($self, $i, $aflag) = @_;

    my $out = {};
    my $qname = $self->_expand($i->[1]);
    my $lname = $qname;
    my $pref = undef;
    ($pref, $lname) = split(':', $qname, 2) if index($qname,':') > -1;

    if (defined $i->[2]) {
	my $ns_uri = $self->_expand($i->[2]);
	
	my $pre = $i->[3]->get_prefix($ns_uri);

	# prefix already declared
	if ($pre) {
	    $out->{Name} = "$pre:$lname";
	    $out->{NamespaceURI} = $ns_uri;
	    $out->{Prefix} = $pre;
	    $out->{LocalName} = $lname;

	# prefix not declared yet
	} else {
	    $pref = $self->_generate_prefix unless $pref; 
	    $out->{Name} = "$pref:$lname";
	    $out->{NamespaceURI} = $ns_uri;
	    $out->{Prefix} = $pref;
	    $out->{LocalName} = $lname;
	}
		
    # namespace not defined	
    } else {
	my @ns = $aflag ? $i->[3]->process_attribute_name($qname) 
	  : $i->[3]->process_element_name($qname);
	$self->doError(501, 3, $qname)
	  unless @ns;
	$out->{Name} = $qname;
	$out->{NamespaceURI} = $ns[0] if $ns[0];
	$out->{Prefix} = $ns[1] if $ns[1];
	$out->{LocalName} = $ns[2];
    }
    return $out;
}

sub _get_def_template {
    my $self = shift;

    my $type = $self->{Stack}->[-1]->{Type};
    my $mode = $self->{Stack}->[-1]->{Group}->[-1]->{Options}->{'pass-through'};
    #print "STX: default rule: mode->$mode, type->$type\n";
    my $t = {};
    $t->{tid} = 'default';

    my $i_cs  = [ I_COPY_START, '#all' ];
    my $i_pcs = [ I_P_CHILDREN_START, undef ];
    my $i_pce = [ I_P_CHILDREN_END ];
    my $i_ce  = [ I_COPY_END, '#all' ];

    my $ii_e = [];
    my $ii_p = [ $i_pcs, $i_pce ];
    my $ii_c = [ $i_cs, $i_ce ];
    my $ii_cpc = [ $i_cs, $i_pcs, $i_pce, $i_ce ];

    if ($type == STX_ELEMENT_NODE or $type == STX_ROOT_NODE) {
	if ($mode == 1) {
	    $t->{instructions} = $ii_cpc;
	    #print "STX: default rule: CPC\n";
	} else {
	    $t->{instructions} = $ii_p;
	    #print "STX: default rule: P\n";
	}

    } elsif ($type == STX_TEXT_NODE or $type == STX_CDATA_NODE) {
	if ($mode) {
	    $t->{instructions} = $ii_c;
	    #print "STX: default rule: C\n";
	} else {
	    $t->{instructions} = $ii_e;
	    #print "STX: default rule: E\n";
	}

    } else { # STX_COMMENT_NODE, STX_PI_NODE, STX_ATTRIBUTE_NODE
	if ($mode == 1) {
	    $t->{instructions} = $ii_c;
	    #print "STX: default rule: C\n";
	} else {
	    $t->{instructions} = $ii_e;
	    #print "STX: default rule: E\n";
	}
    }
    return $t;
}

# dynamic retrieval of either variable or buffer sss
sub _get_objects {
    my ($self, $name, $type) = @_;

    my $tp = $type ? 'bufs' : 'vars';
    my $ct = $self->{_c_template}->[-1];

    # local object
    return $ct->{$tp}->[-1] if $ct->{$tp}->[-1]->{$name};

    # current group
    my $g = $self->{c_group};
    return $g->{$tp}->[-1] if $g->{$tp}->[-1]->{$name};

    # descendant groups
    while ($g->{group}) {
	$g = $g->{group};
	return $g->{$tp}->[-1] if $g->{$tp}->[-1]->{$name};
    }
    return undef;
}

sub _child_nodes {
    my $self = shift;

    return 1 
      if $self->{Stack}->[-1]->{Type} == STX_ELEMENT_NODE 
      and $self->{lookahead}->[0] != STXE_END_ELEMENT;

    return 1 
      if $self->{Stack}->[-1]->{Type} == STX_ROOT_NODE 
      and $self->{lookahead}->[0] != STXE_END_DOCUMENT;

    return 0;
}

# debug ----------------------------------------

sub _frameDBG {
    my $self = shift;

    my $index = scalar @{$self->{Stack}} - 1;
    print "===[$self->{Source}->[-1]->{SystemId}]STACK:$index ";
    foreach (@{$self->{Stack}}) {
	if ($_->{Type} == STX_ELEMENT_NODE) {
	    print "/", $_->{Name};	    
	} elsif ($_->{Type} == STX_TEXT_NODE) {
	    my $norm = $_->{Data};
	    $norm =~ s/\s+/ /g;
	    print "/[text]$norm";	    
	} elsif ($_->{Type} == STX_CDATA_NODE) {
	    my $norm = $_->{Data};
	    $norm =~ s/\s+/ /g;
	    print "/[cdata]$norm";	    
	} elsif ($_->{Type} == STX_COMMENT_NODE) {
	    my $norm = $_->{Data};
	    $norm =~ s/\s+/ /g;
	    print "/[comment]$norm";	    
	} elsif ($_->{Type} == STX_PI_NODE) {
	    my $norm = $_->{Target};
	    $norm =~ s/\s+/ /g;
	    print "/[pi]$norm";	    
	} elsif ($_->{Type} == STX_ROOT_NODE) {
	    print "^";	    
	} else {
	    print "/unknown node: ", $_->{Type};	    
	}
    }
    print "\n";
}

sub _counterDBG {
    my $self = shift;

    my $index = scalar @{$self->{Stack}} - 1;
    print "COUNTER:$index";
     foreach (keys %{$self->{Counter}->[$index]}) {
	 my $cnt = $self->{Counter}->[$index]->{$_};
	 print " $_->$cnt";
     }
    print "\n";
}

sub _nsDBG {
    my $self = shift;

    my @prefixes = $self->{ns}->get_prefixes;
    print "PREFIXES: ", join("|",@prefixes), "\n";

#     foreach (@prefixes) {
# 	my $uri = $self->{ns}->get_uri($_);
# 	print " >$_:$uri\n";
#     }

    my @prefixes2 = $self->{ns_out}->get_prefixes;
    print "RESULT PREFIXES: ", join("|",@prefixes2), "\n";
}

sub _grpDBG {
    my $self = shift;

    print "exG: ";
    foreach my $frm (@{$self->{Stack}}) {
	print "/";
	foreach (@{$self->{exG}->{$frm->{Index}}}) {
	    print "{$_}";
	}
    }
    print "\n";
}

1;
__END__

=head1 NAME

XML::STX::Runtime - STX processor runtime engine

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX

=cut

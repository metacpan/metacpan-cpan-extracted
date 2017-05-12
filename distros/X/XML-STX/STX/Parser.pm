package XML::STX::Parser;

require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;
use XML::STX::Base;
use XML::STX::Stylesheet;
use XML::STX::Buffer;
use Clone qw(clone);

@XML::STX::Parser::ISA = qw(XML::STX::Base);

my $ATT_NUMBER = '\d+(\\.\d*)?|\\.\d+';
my $ATT_URIREF = '[a-z][\w\;\/\?\:\@\&\=\+\$\,\-\_\.\!\~\*\'\(\)\%]+';
my $ATT_STRING = '[\w][\w-]*';
my $ATT_NCNAME = '[A-Za-z_][\w\\.\\-]*';
my $ATT_QNAME  = "($ATT_NCNAME:)?$ATT_NCNAME";
my $ATT_QNAMES = "$ATT_QNAME( $ATT_QNAME)*";

# --------------------------------------------------

sub new {
    my $class = shift;
    my $options = ($#_ == 0) ? shift : { @_ };
    
    my $self = bless $options, $class;
    return $self;
}

# content ----------------------------------------

sub start_document {
    my $self = shift;

    $self->{e_stack} ||= [];
    $self->{g_stack} ||= [];
    $self->{c_template} ||= [];
    $self->{nsc} ||= XML::NamespaceSupport->new({ xmlns => 1 });
}

sub end_document {
    my $self = shift;

    # post-processing
    $self->_process_templates($self->{Sheet}->{dGroup})
      if $self->{Sheet}->{alias}->[0];

    return $self->{Sheet};
}

sub start_element {
    my $self = shift;
    my $el = shift;

    #print "COMP: $el->{Name}\n";
    $self->doError(201, 3) if $self->{end};

    $el->{vars} = [];
    $self->{nsc}->pushContext;

    my $a = exists $el->{Attributes} ? $el->{Attributes} : {};
    my $e_stack_top = $#{$self->{e_stack}} == -1 ? undef 
      : $self->{e_stack}->[-1];
    my $g_stack_top = $#{$self->{g_stack}} == -1 ? undef 
      : $self->{g_stack}->[-1];

    # STX instructions ==================================================
    if (defined $el->{NamespaceURI} and $el->{NamespaceURI} eq STX_NS_URI) {

	# <stx:transform> ----------------------------------------
	if ($el->{LocalName} eq 'transform') {

	    $el->{LocalName} = 'group' if $self->{include};

	    if ($self->_allowed($el->{LocalName})) {

		# included module
		if ($self->{include}) {
		    #print "COMP: >include\n";
		    $el->{LocalName} = 'transform';

		    my $g = XML::STX::Group->new($self->{Sheet}->{next_gid},
						 $g_stack_top);
		    #print "COMP: >new group $self->{Sheet}->{next_gid} $g\n";

		    # the group is linked from the previous group
		    $g_stack_top->{groups}->{$self->{Sheet}->{next_gid}} = $g;

		    push @{$self->{g_stack}}, $g;
		    $self->{Sheet}->{next_gid}++;

		# principal module
		} else {
		    $self->{Sheet} = XML::STX::Stylesheet->new();
		    push @{$self->{g_stack}}, $self->{Sheet}->{dGroup};
		    #print "COMP: >new stylesheet $self->{Sheet}\n";
		    #print "COMP: >default group $self->{Sheet}->{dGroup}->{gid}\n";

		    $self->doError(212, 3, '<stx:transform>', 'version')
		      unless exists $el->{Attributes}->{'{}version'};

		    $self->doError(214, 3, 'version', '<stx:transform>', '1.0')
		      unless $el->{Attributes}->{'{}version'}->{Value} eq STX_VERSION;
		}

		# options: stxpath-default-namespace
		if (exists $a->{'{}stxpath-default-namespace'}) {
		    if ($a->{'{}stxpath-default-namespace'}->{Value} 
			=~ /^$ATT_URIREF$/) {
			push @{$self->{Sheet}->{Options}->
				 {'stxpath-default-namespace'}}, 
				   $a->{'{}stxpath-default-namespace'}->{Value};
		    } else {
			$self->doError(217, 3, 'stxpath-default-namespace', 
				       $a->{'{}stxpath-default-namespace'}->{Value},
				       'uri-reference', );	  
		    }
		}

		# options: output-encoding
		unless ($self->{include}) {
		    if (exists $a->{'{}output-encoding'}) {
			if ($a->{'{}output-encoding'}->{Value} 
			    =~ /^$ATT_STRING$/) {
			    $self->{Sheet}->{Options}->{'output-encoding'}
			      = $a->{'{}output-encoding'}->{Value};
			} else {
			    $self->doError(217, 3, 'output-encoding', 
					   $a->{'{}output-encoding'}->{Value},
					   'string');	  
			}
		    }
		}
		
		# options: recognize-cdata
 		if (exists $a->{'{}recognize-cdata'}) {
 		    if ($a->{'{}recognize-cdata'}->{Value} eq 'no') {
 			$self->{g_stack}->[-1]->{Options}->{'recognize-cdata'} = 0
 		    } elsif ($a->{'{}recognize-cdata'}->{Value} ne 'yes') {
 			$self->doError(205, 3, 'recognize-data', 
 				       $a->{'{}recognize-cdata'}->{Value});
 		    }
 		}

		# options: pass-through
 		if (exists $a->{'{}pass-through'}) {
 		    if ($a->{'{}pass-through'}->{Value} eq 'all') {
 			$self->{g_stack}->[-1]->{Options}->{'pass-through'} = 1

 		    } elsif ($a->{'{}pass-through'}->{Value} eq 'text') {
 			$self->{g_stack}->[-1]->{Options}->{'pass-through'} = 2

 		    } elsif ($a->{'{}pass-through'}->{Value} ne 'none') {
 			$self->doError(206, 3, 
 				       $a->{'{}pass-through'}->{Value});
 		    }
 		}

		# options: strip-space
 		if (exists $a->{'{}strip-space'}) {
 		    if ($a->{'{}strip-space'}->{Value} eq 'yes') {
 			$self->{g_stack}->[-1]->{Options}->{'strip-space'} = 1
 		    } elsif ($a->{'{}strip-space'}->{Value} ne 'no') {
 			$self->doError(205, 3, 'strip-space',
 				       $a->{'{}strip-space'}->{Value});
 		    }
 		}

	    }

	# <stx:include> ----------------------------------------
	} elsif ($el->{LocalName} eq 'include') {

	    if ($self->_allowed($el->{LocalName})) {
		
		$self->doError(212, 3, '<stx:include>', 'href')
		  unless exists $a->{'{}href'};

		$self->doError(214,3,'href','<stx:include>', 'URI reference') 
		  unless $a->{'{}href'}->{Value} =~ /^$ATT_URIREF$/;

		my $source = $self->{URIResolver}->resolve($a->{'{}href'}->{Value},
							   $self->{URI});

		# nested compiler inherits properties from the current one
 		my $iP = XML::STX::Parser->new({include => 1});
 		$iP->{Sheet} = $self->{Sheet};
		$iP->{e_stack} = $self->{e_stack};
		$iP->{g_stack} = $self->{g_stack};
		$iP->{nsc} = $self->{nsc};
 		$iP->{DBG} = $self->{DBG};
 		$iP->{URIResolver} = $self->{URIResolver};
 		$iP->{ErrorListener} = $self->{ErrorListener};
 		$iP->{URI} = $self->{URI};

 		$source->{XMLReader}->{Handler} = $iP;
 		$source->{XMLReader}->parse_uri($source->{SystemId});
	    }

	# <stx:namespace-alias> ----------------------------------------
	} elsif ($el->{LocalName} eq 'namespace-alias') {

	    if ($self->_allowed($el->{LocalName})) {

		# --- stylesheet-prefix ---
		$self->doError(212, 3, '<stx:namespace-alias>', 'stylesheet-prefix')
		  unless exists $a->{'{}stylesheet-prefix'};

		$self->doError(214, 3, 'stylesheet-prefix',
			       '<stx:namespace-alias>', 'NCName')
		  unless $a->{'{}stylesheet-prefix'}->{Value} =~ /^$ATT_NCNAME$/
		    or $a->{'{}stylesheet-prefix'}->{Value} eq '#default';

		my $pre1 = $a->{'{}stylesheet-prefix'}->{Value} eq '#default' 
		  ? '' : $a->{'{}stylesheet-prefix'}->{Value};
		my $ns1 = $self->{nsc}->get_uri($pre1);
		#print "COMP: ns-alias> $pre1:$ns1\n";

		$self->doError(221, 3, $a->{'{}stylesheet-prefix'}->{Value}, 
			       'stx:namespace-alias') unless $ns1;

		# --- result-prefix ---
		$self->doError(212, 3, '<stx:namespace-alias>', 'result-prefix')
		  unless exists $a->{'{}result-prefix'};

		$self->doError(214, 3, 'result-prefix',
			       '<stx:namespace-alias>', 'NCName')
		  unless $a->{'{}result-prefix'}->{Value} =~ /^$ATT_NCNAME$/
		    or $a->{'{}result-prefix'}->{Value} eq '#default';

		my $pre2 = $a->{'{}result-prefix'}->{Value} eq '#default' 
		  ? '' : $a->{'{}result-prefix'}->{Value};
		my $ns2 = $self->{nsc}->get_uri($pre2);
		#print "COMP: ns-alias> $pre2:$ns2\n";

		$self->doError(221, 3, $a->{'{}result-prefix'}->{Value}, 
			       'stx:namespace-alias') unless $ns2;

		unshift @{$self->{Sheet}->{alias}}, [[$ns1, $pre1], [$ns2, $pre2]];
	    }

	# <stx:group> ----------------------------------------
	} elsif ($el->{LocalName} eq 'group') {

	    if ($self->_allowed($el->{LocalName})) {

		my $g = XML::STX::Group->new($self->{Sheet}->{next_gid},
					     $g_stack_top);
		#print "COMP: >new group $self->{Sheet}->{next_gid} $g\n";

		# the group is linked from the previous group
		$g_stack_top->{groups}->{$self->{Sheet}->{next_gid}} = $g;

		# the group inherits pc2 templates from all ancestors
		foreach (@{$self->{g_stack}}) {
		    push @{$g->{pc2}}, @{$_->{vGroup}};
		    push @{$g->{pc2A}}, @{$_->{vGroupA}};

		    foreach my $p (@{$_->{vGroupP}}) {
			$self->doError(220, 3, $p->{name}, 2)
			  if $g->{pc2P}->{$p->{name}};
			$g->{pc2P}->{$p->{name}} = $p;
		    }
		}

		if (exists $a->{'{}name'}) {
		    $self->doError(214,3,'name','<stx:group>', 'qname') 
		      unless $a->{'{}name'}->{Value} =~ /^$ATT_QNAME$/;
		    $g->{name} = $a->{'{}name'}->{Value};

		    $g->{name} = $self->_expand_qname($g->{name});

		    $self->doError(219, 3, 'group', $g->{name}) 
		      if exists $self->{Sheet}->{named_groups}->{$g->{name}};

		    $self->{Sheet}->{named_groups}->{$g->{name}} = $g;
		}

		# options: recognize-cdata
 		if (exists $a->{'{}recognize-cdata'}) {
 		    if ($a->{'{}recognize-cdata'}->{Value} eq 'no') {
 			$g->{Options}->{'recognize-cdata'} = 0

 		    } elsif ($a->{'{}recognize-cdata'}->{Value} eq 'yes') {
 			$g->{Options}->{'recognize-cdata'} = 1

 		    } elsif ($a->{'{}recognize-cdata'}->{Value} eq 'inherit') {
 			$g->{Options}->{'recognize-cdata'} 
			  = $g->{group}->{Options}->{'recognize-cdata'}

		    } else {
 			$self->doError(205, 3, 'recognize-data', 
 				       $a->{'{}recognize-cdata'}->{Value});
		    }
 		} else {
		    $g->{Options}->{'recognize-cdata'} 
		      = $g->{group}->{Options}->{'recognize-cdata'}
		}

 		# options: pass-through
  		if (exists $a->{'{}pass-through'}) {
  		    if ($a->{'{}pass-through'}->{Value} eq 'all') {
  			$g->{Options}->{'pass-through'} = 1

  		    } elsif ($a->{'{}pass-through'}->{Value} eq 'text') {
  			$g->{Options}->{'pass-through'} = 2

  		    } elsif ($a->{'{}pass-through'}->{Value} eq 'none') {
  			$g->{Options}->{'pass-through'} = 0

  		    } elsif ($a->{'{}pass-through'}->{Value} eq 'inherit') {
  			$g->{Options}->{'pass-through'} 
			  = $g->{group}->{Options}->{'pass-through'}

  		    } else {
  			$self->doError(206, 3, 
  				       $a->{'{}pass-through'}->{Value});
  		    }
  		} else {
		    $g->{Options}->{'pass-through'} 
		      = $g->{group}->{Options}->{'pass-through'}
		}

 		# options: strip-space
  		if (exists $a->{'{}strip-space'}) {
  		    if ($a->{'{}strip-space'}->{Value} eq 'yes') {
  			$g->{Options}->{'strip-space'} = 1

  		    } elsif ($a->{'{}strip-space'}->{Value} eq 'no') {
  			$g->{Options}->{'strip-space'} = 0

  		    } elsif ($a->{'{}strip-space'}->{Value} eq 'inherit') {
  			$g->{Options}->{'strip-space'} 
			  = $g->{group}->{Options}->{'strip-space'}

  		    } else {
  			$self->doError(205, 3, 'strip-space',
  				       $a->{'{}strip-space'}->{Value});
  		    }
  		} else {
		    $g->{Options}->{'strip-space'} 
		      = $g->{group}->{Options}->{'strip-space'}
		}

		push @{$self->{g_stack}}, $g;
		$self->{Sheet}->{next_gid}++;
	    }

	# <stx:template> ----------------------------------------
	} elsif ($el->{LocalName} eq'template') {

	    if ($self->_allowed($el->{LocalName})) {

		my $t = XML::STX::Template->new($self->{Sheet}->{next_tid},
						$g_stack_top);

		# --- match ---
		$self->doError(212, 3, '<stx:template>', 'match')
		  unless exists $a->{'{}match'};

		$t->{pattern} = $a->{'{}match'}->{Value};
		$t->{match} = $self->tokenize_match($a->{'{}match'}->{Value});

		if ($#{$t->{match}->[0]->[0]->{step}} > -1) {
		    foreach (@{$t->{match}}) {
			if ($_->[-1]->{step}->[0] =~ /^@/) {
			    $t->{_att} = 1;
			    $t->{_not_att} = 0;
			} elsif ($_->[-1]->{step}->[0] =~ /^node\(\)/) {
			    $t->{_att} = 1;
			    $t->{_not_att} = 1;
			} else {
			    $t->{_att} = 0;
			    $t->{_not_att} = 1;
			}
		    }
		} else { # '/' root
			$t->{_att} = 0;
			$t->{_not_att} = 1;
		}
		#print "COMP: att: $t->{_att}, not att: $t->{_not_att}\n";

		# --- priority ---
		if (exists $a->{'{}priority'}) {
		    $self->doError(214, 3, 'priority', 
				   '<stx:template>', 'number')
		      unless $a->{'{}priority'}->{Value} 
			=~ /^$ATT_NUMBER$/;
		    $t->{priority} = [$a->{'{}priority'}->{Value}];
		    $t->{eff_p} = $a->{'{}priority'}->{Value};
		}
		unless (exists $t->{priority}) {
		    $t->{priority}
		      = $self->match_priority($a->{'{}match'}->{Value});
			
		    if (defined $t->{priority}->[1]) {
			$t->{eff_p} = 10;
			$g_stack_top->{_complex_priority} = 1;
			
		    } else {
			$t->{eff_p} = $t->{priority}->[0];
		    }
		}

		# --- public ---
		$t->{public} = 0;
		# visible from the current group
		unshift @{$g_stack_top->{pc1}}, $t if $t->{_not_att};
		unshift @{$g_stack_top->{pc1A}}, $t if $t->{_att};

		if (exists $a->{'{}public'}) {

		    if ($a->{'{}public'}->{Value} eq 'yes') {
			$t->{public} = 1;

			if ($t->{_not_att}) {
			    # visible from the parent group
			    unshift @{$self->{g_stack}->[-2]->{pc1}}, $t 
			      if $#{$self->{g_stack}} > 0;
			}
			if ($t->{_att}) { # to match against attributes
			    # visible from the parent group
			    unshift @{$self->{g_stack}->[-2]->{pc1A}}, $t 
			      if $#{$self->{g_stack}} > 0;
			}
			
		    } elsif ($a->{'{}public'}->{Value} ne 'no') {
			$self->doError(205, 3, 'public', $a->{'{}public'}->{Value});
		    }
		} elsif ($e_stack_top->{LocalName} eq 'transform') {
		    $t->{public} = 1;

		    if ($t->{_not_att}) {
			    # visible from the parent group
			unshift @{$self->{g_stack}->[-2]->{pc1}}, $t 
			  if $#{$self->{g_stack}} > 0;
		    }
		    if ($t->{_att}) { # to match against attributes
			# visible from the parent group
			unshift @{$self->{g_stack}->[-2]->{pc1A}}, $t 
			  if $#{$self->{g_stack}} > 0;
		    }
		}

		# --- visibility ---
		$t->{visibility} = 1;
		if (exists $a->{'{}visibility'}) {
			
		    if ($a->{'{}visibility'}->{Value} eq 'group') {
			$t->{visibility} = 2;
			push @{$g_stack_top->{vGroup}}, $t if $t->{_not_att};
			push @{$g_stack_top->{vGroupA}}, $t if $t->{_att};

		    } elsif ($a->{'{}visibility'}->{Value} eq 'global') {
			$t->{visibility} = 3;

			if ($t->{_not_att}) {
			    push @{$g_stack_top->{vGroup}}, $t;
			    unshift @{$self->{Sheet}->{dGroup}->{pc3}}, $t;
			}
			if ($t->{_att}) { # to match against attributes
			    push @{$g_stack_top->{vGroupA}}, $t;
			    unshift @{$self->{Sheet}->{dGroup}->{pc3A}}, $t;
			}
			
		    } elsif ($a->{'{}visibility'}->{Value} ne 'local') {
			$self->doError(204, 3, $a->{'{}visibility'}->{Value});
		    }
		}
	
		# --- new-scope ---
		$t->{'new-scope'} = 0;
		if (exists $a->{'{}new-scope'}) {
		    if ($a->{'{}new-scope'}->{Value} eq 'yes') {
			$t->{'new-scope'} = 1
		    } elsif ($a->{'{}new-scope'}->{Value} ne 'no') {
			$self->doError(205, 3, 'new-scope',
				       $a->{'{}new-scope'}->{Value});
		    }
		}
		
		#print "COMP: >new template $self->{Sheet}->{next_tid} $t\n";
		#print "COMP: >matching $t->{match}\n";
		$g_stack_top->{templates}->{$self->{Sheet}->{next_tid}} = $t;

		push @{$self->{c_template}}, $t;
		$self->{Sheet}->{next_tid}++;
	    }

	# <stx:procedure> ----------------------------------------

	} elsif ($el->{LocalName} eq'procedure') {

	    if ($self->_allowed($el->{LocalName})) {

		my $p = XML::STX::Template->new($self->{Sheet}->{next_tid},
						$g_stack_top);

		# --- name ---
		$self->doError(212, 3, '<stx:procedure>', 'name')
		  unless exists $a->{'{}name'};

		$self->doError(214,3,'name','<stx:procedure>', 'qname') 
		  unless $a->{'{}name'}->{Value} =~ /^$ATT_QNAME$/;
		$p->{name} = $a->{'{}name'}->{Value};

		$p->{name} = $self->_expand_qname($p->{name});

		# --- public ---
		$p->{public} = 0;
		# visible from the current group
		$g_stack_top->{pc1P}->{$p->{name}} = $p;

		if (exists $a->{'{}public'}) {

		    if ($a->{'{}public'}->{Value} eq 'yes') {
			$p->{public} = 1;
			#push @{$g_stack_top->{vPublicP}}, $p;

			# visible from the parent group
			$self->{g_stack}->[-2]->{pc1P}->{$p->{name}} = $p 
			  if $#{$self->{g_stack}} > 0;
			
		    } elsif ($a->{'{}public'}->{Value} ne 'no') {
			$self->doError(205, 3, 'public', $a->{'{}public'}->{Value});
		    }

		} elsif ($e_stack_top->{LocalName} eq 'transform') {
		    $p->{public} = 1;
		    #push @{$g_stack_top->{vPublicP}}, $p;

		    # visible from the parent group
		    $self->{g_stack}->[-2]->{pc1P}->{$p->{name}} = $p 
		      if $#{$self->{g_stack}} > 0;
		}

		# --- visibility ---
		$p->{visibility} = 1;
		if (exists $a->{'{}visibility'}) {
			
		    if ($a->{'{}visibility'}->{Value} eq 'group') {
			$p->{visibility} = 2;
			push @{$g_stack_top->{vGroupP}}, $p;

		    } elsif ($a->{'{}visibility'}->{Value} eq 'global') {
			$p->{visibility} = 3;

			push @{$g_stack_top->{vGroupP}}, $p;
			$self->{Sheet}->{dGroup}->{pc3P}->{$p->{name}} = $p;
			
		    } elsif ($a->{'{}visibility'}->{Value} ne 'local') {
			$self->doError(204, 3, $a->{'{}visibility'}->{Value});
		    }
		}

		# --- new-scope ---
		if (exists $a->{'{}new-scope'}) {
		    if ($a->{'{}new-scope'}->{Value} eq 'yes') {
			$p->{'new-scope'} = 1
		    } elsif ($a->{'{}new-scope'}->{Value} ne 'no') {
			$self->doError(205, 3, 'new-scope',
				       $a->{'{}new-scope'}->{Value});
		    }
		}
		
		#print "COMP: >new procedure $self->{Sheet}->{next_tid} $p\n";
		#print "COMP: >name $p->{name}\n";
		$g_stack_top->{procedures}->{$self->{Sheet}->{next_tid}} = $p;

		push @{$self->{c_template}}, $p;
		$self->{Sheet}->{next_tid}++;
	    }

	# <stx:process-children> ----------------------------------------
	} elsif ($el->{LocalName} eq'process-children') {

	    if ($self->_allowed($el->{LocalName})) {

		my $group;
		if (exists $a->{'{}group'}) {
		    $self->doError(214,3,'group','<stx:process-children>',
				   'qname') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_QNAME$/;
		    $group = $a->{'{}group'}->{Value};

		    $group = $self->_expand_qname($group);
		}

		#TBD: filter attributes

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_P_CHILDREN_START, $group];
		#print "COMP: >PROCESS_CHILDREN_START\n";
	    }

	# <stx:process-siblings> ----------------------------------------
	} elsif ($el->{LocalName} eq'process-siblings') {

	    if ($self->_allowed($el->{LocalName})) {

		my $group;
		if (exists $a->{'{}group'}) {
		    $self->doError(214,3,'group','<stx:process-siblings>',
				   'qname') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_QNAME$/;
		    $group = $a->{'{}group'}->{Value};

		    $group = $self->_expand_qname($group);
		}

		# --- while ---
		$self->{_sib}->[0] = exists $a->{'{}while'}
		  ? $self->tokenize_match($a->{'{}while'}->{Value}) : undef;

		# --- until ---
		$self->{_sib}->[1] = exists $a->{'{}until'}
		  ? $self->tokenize_match($a->{'{}until'}->{Value}) : undef;

		#TBD: filter attributes

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_P_SIBLINGS_START, $group];
		#print "COMP: >PROCESS_SIBLINGS_START\n";
	    }

	# <stx:process-attributes> ----------------------------------------
	} elsif ($el->{LocalName} eq'process-attributes') {

	    if ($self->_allowed($el->{LocalName})) {

		my $group;
		if (exists $a->{'{}group'}) {
		    $self->doError(214,3,'group','<stx:process-attributes>',
				   'qname') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_QNAME$/;
		    $group = $a->{'{}group'}->{Value};

		    $group = $self->_expand_qname($group);
		}

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_P_ATTRIBUTES_START, $group];
		#print "COMP: >PROCESS ATTRIBUTES START\n";
	    }

	# <stx:process-self> ----------------------------------------
	} elsif ($el->{LocalName} eq'process-self') {

	    if ($self->_allowed($el->{LocalName})) {

		my $group;
		if (exists $a->{'{}group'}) {
		    $self->doError(214,3,'group','<stx:process-self>',
				   'qname') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_QNAME$/;
		    $group = $a->{'{}group'}->{Value};

		    $group = $self->_expand_qname($group);
		}

		$self->{c_template}->[-1]->{_self} = 1;

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_P_SELF_START, $group];
		#print "COMP: >PROCESS SELF START\n";
	    }

	# <stx:call-procedure> ----------------------------------------
	} elsif ($el->{LocalName} eq'call-procedure') {

	    if ($self->_allowed($el->{LocalName})) {

		# --- name ---
		$self->doError(212, 3, '<stx:call-procedure>', 'name')
		  unless exists $a->{'{}name'};
		$self->doError(214,3,'name','<stx:call-procedure>','qname') 
		      unless $a->{'{}name'}->{Value} =~ /^$ATT_QNAME$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		# --- group ---
		my $group;
		if (exists $a->{'{}group'}) {
		    $self->doError(214,3,'group','<stx:call-procedure>', 'qname') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_QNAME$/;
		    $group = $a->{'{}group'}->{Value};

		    $group = $self->_expand_qname($group);
		}

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_CALL_PROCEDURE_START, $name, $group];
		#print "COMP: >CALL PROCEDURE START\n";
	    }

	# <stx:if> ----------------------------------------
	} elsif ($el->{LocalName} eq 'if') {

	    if ($self->_allowed($el->{LocalName})) {

		$self->doError(212, 3, '<stx:if>', 'test')
		  unless exists $a->{'{}test'};

		my $expr = $self->tokenize($a->{'{}test'}->{Value});
		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_IF_START, $expr];
		#print "COMP: >IF\n";
	    }

	# <stx:else> ----------------------------------------
	} elsif ($el->{LocalName} eq 'else') {

	    if ($self->_allowed($el->{LocalName})) {

		my $last = $self->{c_template}->[-1]->{instructions}->[-1]->[0];
		$self->doError(218, 3, 'stx:else', 'stx:if', $last) 
		  if $last != I_IF_END;

		push @{$self->{c_template}->[-1]->{instructions}}, [I_ELSE_START];
		#print "COMP: >ELSE\n";
	    }

	# <stx:choose> ----------------------------------------
	} elsif ($el->{LocalName} eq 'choose') {

	    if ($self->_allowed($el->{LocalName})) {

		$self->doError(208, 3, 'stx:choose') if $self->{_choose};

		$self->{_choose} = 1;
		#print "COMP: >CHOOSE\n";
	    }

	# <stx:when> ----------------------------------------
	} elsif ($el->{LocalName} eq 'when') {

	    if ($self->_allowed($el->{LocalName})) {

		$self->doError(212, 3, '<stx:when>', 'test')
		  unless exists $a->{'{}test'};

		my $expr = $self->tokenize($a->{'{}test'}->{Value});
		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_ELSIF_START, $expr];
		#print "COMP: >WHEN\n";
	    }

	# <stx:otherwise> ----------------------------------------
	} elsif ($el->{LocalName} eq 'otherwise') {

	    if ($self->_allowed($el->{LocalName})) {

 		my $last = $self->{c_template}->[-1]->{instructions}->[-1]->[0];
 		$self->doError(218, 3, 'stx:otherwise', 'stx:when', $last)
		  if $last != I_ELSIF_END;

		push @{$self->{c_template}->[-1]->{instructions}}, [I_ELSE_START];
		#print "COMP: >OTHERWISE\n";
	    }

	# <stx:value-of> ----------------------------------------
	} elsif ($el->{LocalName} eq 'value-of') {

	    if ($self->_allowed($el->{LocalName})) {

		$self->doError(212, 3, '<stx:value-of>', 'select')
		  unless exists $a->{'{}select'};
		
		$self->doError(213, 3, 'select', '<stx:value-of>')
		  if $a->{'{}select'}->{Value} =~ /\{|\}/;

		my $expr = $self->tokenize($a->{'{}select'}->{Value});

		my $sep = exists $a->{'{}separator'} 
		  ? $self->_avt($a->{'{}separator'}->{Value}) : ' ';

		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_CHARACTERS, $expr, $sep];
		#print "COMP: >CHARACTER\n";
	    }

	# <stx:copy> ----------------------------------------
	} elsif ($el->{LocalName} eq 'copy') {

	    if ($self->_allowed($el->{LocalName})) {
		
		my $attributes = '#all'; # TBD: changed in the spec!!!
		if (exists $a->{'{}attributes'}) {
		    $self->doError(217, 3, 'attributes',
				   $a->{'{}attributes'}->{Value}, 
				   'list of qnames')
		      unless $a->{'{}attributes'}->{Value} 
			=~ /^($ATT_QNAMES|#none|#all)$/ 
			  or $a->{'{}attributes'}->{Value} eq '';

		$attributes = $a->{'{}attributes'}->{Value};
		}
		
		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_COPY_START, $attributes];
		#print "COMP: >COPY_START $attributes\n";
	    }

	# <stx:element> or <stx:start-element> -----------------
	} elsif ($el->{LocalName} eq 'element'
		or $el->{LocalName} eq 'start-element') {

	    if ($self->_allowed($el->{LocalName})) {

		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};

		my $qn = $self->_avt($a->{'{}name'}->{Value});

		my $ns = exists $a->{'{}namespace'}
		  ? $self->_avt($a->{'{}namespace'}->{Value}) : undef;

		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_ELEMENT_START, $qn, $ns, clone($self->{nsc})];
		#print "COMP: >ELEMENT_START\n";
	    }

	# <stx:end-element> ----------------------------------------
	} elsif ($el->{LocalName} eq'end-element') {

	    if ($self->_allowed($el->{LocalName})) {

		$self->doError(212, 3, '<stx:end-element>', 'name')
		  unless exists $el->{Attributes}->{'{}name'};

		my $qn = $self->_avt($a->{'{}name'}->{Value});

		my $ns = exists $a->{'{}namespace'}
		  ? $self->_avt($a->{'{}namespace'}->{Value}) : undef; 

		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_ELEMENT_END, $qn, $ns, clone($self->{nsc})];
		#print "COMP: >ELEMENT_END\n";
	    }

	# <stx:attribute> ----------------------------------------
	} elsif ($el->{LocalName} eq'attribute') {

	    if ($self->_allowed($el->{LocalName})) {
		
		my $ok;
		my $insts = $self->{c_template}->[-1]->{instructions};
		for (my $i = 0; $i < @$insts; $i++) {

		    last if $insts->[$#$insts - $i]->[0] == I_ATTRIBUTE_END
		      or $insts->[$#$insts - $i]->[0] == I_ELEMENT_START
			or $insts->[$#$insts - $i]->[0] == I_LITERAL_START
			  or $insts->[$#$insts - $i]->[0] == I_COPY_START;
		    # these instructions don't output anything
		    $self->doError(207, 3, $insts->[$#$insts - $i]->[0]) 
		      unless $insts->[$#$insts - $i]->[0] > 100;
		}

		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};

		my $qn = $self->_avt($a->{'{}name'}->{Value});

		my $ns = exists $a->{'{}namespace'}
		  ? $self->_avt($a->{'{}namespace'}->{Value}) : undef; 

		my $sel = exists $a->{'{}select'} ? 
		  $self->tokenize($a->{'{}select'}->{Value}) : undef;

		$self->{_attribute_select} = $sel;
		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_ATTRIBUTE_START, $qn, $ns, clone($self->{nsc}), $sel];
		#print "COMP: >ATTRIBUTE_START\n";
	    }

	# <stx:text> ----------------------------------------
	} elsif ($el->{LocalName} eq 'text') {

	    $self->_allowed($el->{LocalName});

	# <stx:cdata> ----------------------------------------
	} elsif ($el->{LocalName} eq 'cdata') {

	    if ($self->_allowed($el->{LocalName})) {

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_CDATA_START];
		#print "COMP: >CDATA_START\n";
	    }

	# <stx:comment> ----------------------------------------
	} elsif ($el->{LocalName} eq'comment') {

	    if ($self->_allowed($el->{LocalName})) {
		
		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_COMMENT_START];
		#print "COMP: >COMMENT_START\n";
	    }

	# <stx:processing-instruction> -----------------------------------
	} elsif ($el->{LocalName} eq'processing-instruction') {

	    if ($self->_allowed($el->{LocalName})) {

		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};

		my $target = $self->_avt($el->{Attributes}->{'{}name'}->{Value});

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_PI_START, $target];
		#print "COMP: >PI_START\n";
	    }

	# <stx:variable> ----------------------------------------
	} elsif ($el->{LocalName} eq 'variable') {

	    if ($self->_allowed($el->{LocalName})) {
		
		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};
		$self->doError(217, 3, 'name', 
			       $a->{'{}name'}->{Value}, 'qname')
		  unless $a->{'{}name'}->{Value} =~ /^($ATT_QNAME)$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		my $select;
		my $default_select;
		if (exists $a->{'{}select'}) {
		    $self->doError(213, 3, 'select', '<stx:variable>')
		      if $a->{'{}select'}->{Value} =~ /^\{|\}/;
		    $select = $self->tokenize($a->{'{}select'}->{Value});
		    $default_select = 0;
		} else {
		    $select = ['""']; # the empty string
		    $default_select = 1;
		}

		$self->{_variable_select} = $select;

		# local variable ------------------------------
		if ($self->{c_template}->[0]) {

		    # variable already declared
		    $self->doError(211, 3, 'Local variable', "\'$name\'") 
		      if exists $self->{c_template}->[-1]->{vars}->[0]->{$name};

		    push @{$e_stack_top->{vars}}, $name;
		    $self->{c_template}->[-1]->{vars}->[0]->{$name} = [];

		    push @{$self->{c_template}->[-1]->{instructions}}, 
		      [I_VARIABLE_START, $name, $select, $default_select];
		    #print "COMP: >VARIABLE_START\n";

		# group variable ------------------------------
		} else {

		    # variable already declared
		    $self->doError(211, 3, 'Group variable', "\'$name\'") 
		      if $g_stack_top->{vars}->[0]->{$name};

		    my $keep_value = 0; 
 		    if (exists $a->{'{}keep-value'}) {
 			if ($a->{'{}keep-value'}->{Value} eq 'yes') {
 			    $keep_value = 1
 			} elsif ($a->{'{}keep-value'}->{Value} ne 'no') {
 			    $self->doError(205, 3, 'keep-value',
 					   $a->{'{}keep-value'}->{Value});
 			}
 		    }

		    # actual value
		    $g_stack_top->{vars}->[0]->{$name}->[0]
		      = $self->_static_eval($select);
		    # init value
		    $g_stack_top->{vars}->[0]->{$name}->[1]
		      = clone($g_stack_top->{vars}->[0]->{$name}->[0]);
		    # keep value
		    $g_stack_top->{vars}->[0]->{$name}->[2]
		      = $keep_value;
 		    #print "COMP: >GROUP_VARIABLE\n";
		}
	    }

	# <stx:param> ----------------------------------------
	} elsif ($el->{LocalName} eq 'param') {

	    if ($self->_allowed($el->{LocalName})) {
		
		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};
		$self->doError(217, 3, 'name', 
			       $a->{'{}name'}->{Value}, 'qname')
		  unless $a->{'{}name'}->{Value} =~ /^($ATT_QNAME)$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		my $select;
		my $default_select;
		if (exists $a->{'{}select'}) {
		    $self->doError(213, 3, 'select', '<stx:param>')
		      if $a->{'{}select'}->{Value} =~ /^\{|\}/;
		    $select = $self->tokenize($a->{'{}select'}->{Value});
		    $default_select = 0;
		} else {
		    $select = ['""']; # the empty string
		    $default_select = 1;
		}

		my $req = 0; 
		if (exists $a->{'{}required'}) {
		    if ($a->{'{}required'}->{Value} eq 'yes') {
			$req = 1
		    } elsif ($a->{'{}required'}->{Value} ne 'no') {
			$self->doError(205, 3, 'required',
				       $a->{'{}required'}->{Value});
		    }
		}

		$self->{_variable_select} = $select;

		# local parameter ------------------------------
		if ($self->{c_template}->[0]) {

		    # parameter already declared
		    $self->doError(211, 3, 'Local parameter', "\'$name\'") 
		      if exists $self->{c_template}->[-1]->{vars}->[0]->{$name};

		    push @{$e_stack_top->{vars}}, $name;
		    $self->{c_template}->[-1]->{vars}->[0]->{$name} = [];

		    push @{$self->{c_template}->[-1]->{instructions}}, 
		      [I_PARAMETER_START, $name, $select, $default_select, $req];
		    #print "COMP: >PARAMETER_START\n";

		# stylesheet parameter ------------------------------
		} else {

		    # parameter already declared
		    $self->doError(211, 3, 'Stylesheet parameter', "\'$name\'") 
		      if $self->{Sheet}->{dGroup}->{vars}->[0]->{$name};

		    # actual value
		    $self->{Sheet}->{dGroup}->{vars}->[0]->{$name}->[0]
		      = $self->_static_eval($select);
		    # init value
		    $self->{Sheet}->{dGroup}->{vars}->[0]->{$name}->[1]
		      = clone($self->{Sheet}->{dGroup}->{vars}->[0]->{$name}->[0]);
		    # keep value
		    $self->{Sheet}->{dGroup}->{vars}->[0]->{$name}->[2] = 0;

		    # list of params
		    $self->{Sheet}->{dGroup}->{pars}->{$name} = $req;
 		    #print "COMP: >GROUP_VARIABLE - parameter\n";
		}

	    }

	# <stx:with-param> ----------------------------------------
	} elsif ($el->{LocalName} eq 'with-param') {

	    if ($self->_allowed($el->{LocalName})) {
		
		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};
		$self->doError(217, 3, 'name', 
			       $a->{'{}name'}->{Value}, 'qname')
		  unless $a->{'{}name'}->{Value} =~ /^($ATT_QNAME)$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		my $select;
		my $default_select;
		if (exists $a->{'{}select'}) {
		    $self->doError(213, 3, 'select', '<stx:with-param>')
		      if $a->{'{}select'}->{Value} =~ /^\{|\}/;
		    $select = $self->tokenize($a->{'{}select'}->{Value});
		    $default_select = 0;
		} else {
		    $select = ['""']; # the empty string
		    $default_select = 1;
		}
		
		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_WITH_PARAM_START, $name, $select, $default_select];
		#print "COMP: >WITH_PARAM\n";
	    }

	# <stx:assign> ----------------------------------------
	} elsif ($el->{LocalName} eq 'assign') {

	    if ($self->_allowed($el->{LocalName})) {
		
		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};
		$self->doError(217, 3, 'name', 
			       $a->{'{}name'}->{Value}, 'qname')
		  unless $a->{'{}name'}->{Value} =~ /^($ATT_QNAME)$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		my $select;
		if (exists $a->{'{}select'}) {
		    $self->doError(213, 3, 'select', '<stx:assign>')
		      if $a->{'{}select'}->{Value} =~ /\{|\}/;
		    $select = $self->tokenize($a->{'{}select'}->{Value});
		}

		$self->{_variable_select} = $select;

		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_ASSIGN_START, $name, $select];
		#print "COMP: >ASSIGN_START\n";
	    }


	# <stx:buffer> ----------------------------------------
	} elsif ($el->{LocalName} eq 'buffer') {

	    if ($self->_allowed($el->{LocalName})) {
		
		# --- name ---
		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};
		$self->doError(217, 3, 'name', 
			       $a->{'{}name'}->{Value}, 'qname')
		  unless $a->{'{}name'}->{Value} =~ /^($ATT_QNAME)$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		# local buffer ------------------------------
		if ($self->{c_template}->[0]) {

		    # buffer already declared
		    $self->doError(211, 3, 'Local buffer', "\'$name\'") 
		      if exists $self->{c_template}->[-1]->{bufs}->[0]->{$name};

		    push @{$e_stack_top->{bufs}}, $name;

		    push @{$self->{c_template}->[-1]->{instructions}}, 
		      [I_BUFFER_START, $name];
		    #print "COMP: >BUFFER_START\n";

		# group buffer ------------------------------
		} else {

		    # buffer already declared
		    $self->doError(211, 3, 'Group buffer', "\'$name\'") 
		      if $self->{c_group}->{bufs}->[0]->{$name};

		    # new buffer
		    my $b = XML::STX::Buffer->new($name);
		    $g_stack_top->{bufs}->[0]->{$name} = $b;

 		    #print "COMP: >GROUP_BUFFER\n";
		}
	    }

	# <stx:result-buffer> ----------------------------------------
	} elsif ($el->{LocalName} eq 'result-buffer') {

	    if ($self->_allowed($el->{LocalName})) {
		
		# --- name ---
		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};
		$self->doError(217, 3, 'name', 
			       $a->{'{}name'}->{Value}, 'qname')
		  unless $a->{'{}name'}->{Value} =~ /^($ATT_QNAME)$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		my $clear = 0;
		if (exists $a->{'{}clear'}) {
		    if ($a->{'{}clear'}->{Value} eq 'yes') {
			$clear = 1;
		    } elsif ($a->{'{}clear'}->{Value} ne 'no') {
			$self->doError(205, 3, 'clear', $a->{'{}clear'}->{Value});
		    }
		}

		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_RES_BUFFER_START, $name, $clear];
		#print "COMP: >RESULT_BUFFER_START\n";
	    }

	# <stx:process-buffer> ----------------------------------------
	} elsif ($el->{LocalName} eq'process-buffer') {

	    if ($self->_allowed($el->{LocalName})) {

		# --- name ---
		$self->doError(212, 3, "<stx:$el->{LocalName}>", 'name')
		  unless exists $el->{Attributes}->{'{}name'};
		$self->doError(217, 3, 'name', 
			       $a->{'{}name'}->{Value}, 'qname')
		  unless $a->{'{}name'}->{Value} =~ /^($ATT_QNAME)$/;

		my $name = $a->{'{}name'}->{Value};
		$name = $self->_expand_qname($name);

		# --- group ---
		my $group;
		if (exists $a->{'{}group'}) {
		    $self->doError(214,3,'group','<stx:process-buffer>',
				   'qname') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_QNAME$/;

		    $group = $self->_expand_qname($a->{'{}group'}->{Value});
		}

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_P_BUFFER_START, $name, $group];
		#print "COMP: >PROCESS BUFFER START\n";
	    }

	# <stx:result-document> ----------------------------------------
	} elsif ($el->{LocalName} eq 'result-document') {

	    if ($self->_allowed($el->{LocalName})) {
		
		# --- href ---
		$self->doError(212, 3, '<stx:result-document>', 'href')
		  unless exists $a->{'{}href'};

		my $href = $self->tokenize($a->{'{}href'}->{Value});

		# --- encoding ---
		my $encoding;
		if (exists $a->{'{}encoding'}) {
		    $self->doError(214,3,'encoding','<stx:result-document>',
				   'string') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_STRING$/;

		    $encoding = $a->{'{}encoding'}->{Value};
		}
		
		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_RES_DOC_START, $href, $encoding];
		#print "COMP: >RESULT_DOCUMENT_START\n";
	    }

	# <stx:process-document> ----------------------------------------
	} elsif ($el->{LocalName} eq'process-document') {

	    if ($self->_allowed($el->{LocalName})) {

		# --- href ---
		$self->doError(212, 3, '<stx:process-document>', 'href')
		  unless exists $a->{'{}href'};

		my $href = $self->tokenize($a->{'{}href'}->{Value});

		# --- group ---
		my $group;
		if (exists $a->{'{}group'}) {
		    $self->doError(214,3,'group','<stx:process-document>',
				   'qname') 
		      unless $a->{'{}group'}->{Value} =~ /^$ATT_QNAME$/;

		    $group = $self->_expand_qname($a->{'{}group'}->{Value});
		}

		# --- base ---
		my $base = exists $a->{'{}base'} 
		  ? $self->_avt($a->{'{}base'}->{Value}) : undef;
		
		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_P_DOC_START, $href, $group, $base];
		#print "COMP: >PROCESS_DOCUMENT_START\n";
	    }

	# <stx:for-each-item> ----------------------------------------
	} elsif ($el->{LocalName} eq'for-each-item') {

	    if ($self->_allowed($el->{LocalName})) {

		# --- name ---
		$self->doError(212, 3, '<stx:for-each-item>', 'name')
		  unless exists $a->{'{}name'};

		$self->doError(214,3,'name','<stx:for-each-item>','qname') 
		  unless $a->{'{}name'}->{Value} =~ /^$ATT_QNAME$/;

		my $name = $self->_expand_qname($a->{'{}name'}->{Value});

		# --- select ---
		$self->doError(212, 3, '<stx:for-each-item>', 'select')
		  unless exists $a->{'{}select'};

		$self->doError(213, 3, 'select', '<stx:for-each-item>')
		  if $a->{'{}select'}->{Value} =~ /\{|\}/;

		my $expr = $self->tokenize($a->{'{}select'}->{Value});

		# --- content is template ---
		my $t = XML::STX::Template->new($self->{Sheet}->{next_tid},
						$g_stack_top);

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_FOR_EACH_ITEM, $name, $expr, $t];
		#print "COMP: >FOR_EACH_ITEM\n";

		push @{$self->{c_template}}, $t;
		$self->{Sheet}->{next_tid}++;
	    }

	# <stx:while> ----------------------------------------
	} elsif ($el->{LocalName} eq'while') {

	    if ($self->_allowed($el->{LocalName})) {

		# --- test ---
		$self->doError(212, 3, '<stx:while>', 'test')
		  unless exists $a->{'{}test'};

		$self->doError(213, 3, 'test', '<stx:while>')
		  if $a->{'{}test'}->{Value} =~ /\{|\}/;

		my $expr = $self->tokenize($a->{'{}test'}->{Value});

		unless (grep(index($_,'$') == 0, @$expr)) {
		    $self->doError(222, 1, $a->{'{}test'}->{Value});
		    $self->{Sheet}->{Options}->{LoopLimit} = 1;
		}

		# --- content is template ---
		my $t = XML::STX::Template->new($self->{Sheet}->{next_tid},
						$g_stack_top);

		push @{$self->{c_template}->[-1]->{instructions}}, 
		  [I_WHILE, $expr, $t];
		#print "COMP: >WHILE\n";

		push @{$self->{c_template}}, $t;
		$self->{Sheet}->{next_tid}++;
	    }

	} else {
	    $self->doError(209, 3, "<stx:$el->{LocalName}>")
	}

    # literals ==================================================
    } else {

	if ($self->_allowed('_literal')) {

	    if (exists $el->{Attributes}) {
		foreach my $ns (keys %{$el->{Attributes}}) {

		    # tokenize AVT in attributes
		    $el->{Attributes}->{$ns}->{Value} 
		      = $self->_avt($el->{Attributes}->{$ns}->{Value});
		}
	    }
		
	    my $i = [I_LITERAL_START, $el];
	    push @{$self->{c_template}->[-1]->{instructions}}, $i;
	    #print "COMP: >LITERAL_START $el->{Name}\n";

	} else { #???
	    $self->doError(210, 3, $el->{Name}) 
	      unless $el->{NamespaceURI};
	}
    }

    push @{$self->{e_stack}}, $el;
}

sub end_element {
    my $self = shift;
    my $el = shift;

    #print "COMP: \/$el->{Name}\n";

    # STX instructions ==================================================
    if (defined $el->{NamespaceURI} and $el->{NamespaceURI} eq STX_NS_URI) {

	# <stx:transform> ----------------------------------------
	if ($el->{LocalName} eq 'transform') {

	    if ($self->{include}) {
		#$self->_dump_g_stack;
		my $g = pop @{$self->{g_stack}};
		$self->_sort_templates($g->{pc1});
		$self->_sort_templates($g->{pc1A});
		$self->_sort_templates($g->{pc2});
		$self->_sort_templates($g->{pc2A});

	    } else {
		# nothing else is allowed
		$self->_sort_templates($self->{Sheet}->{dGroup}->{pc1});
		$self->_sort_templates($self->{Sheet}->{dGroup}->{pc1A});
		$self->_sort_templates($self->{Sheet}->{dGroup}->{pc2});
		$self->_sort_templates($self->{Sheet}->{dGroup}->{pc2A});
		$self->_sort_templates($self->{Sheet}->{dGroup}->{pc3});
		$self->_sort_templates($self->{Sheet}->{dGroup}->{pc3A});
		$self->{end} = 1;
	    }

	# <stx:process-children> ----------------------------------------
	} elsif ($el->{LocalName} eq 'process-children') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_P_CHILDREN_END];
	    #print "COMP: >PROCESS CHILDREN END /$el->{Name}\n";

	# <stx:process-siblings> ----------------------------------------
	} elsif ($el->{LocalName} eq 'process-siblings') {

	    push @{$self->{c_template}->[-1]->{instructions}}, 
	      [I_P_SIBLINGS_END, $self->{_sib}->[0], $self->{_sib}->[1]];
	    #print "COMP: >PROCESS SIBLINGS END /$el->{Name}\n";

	# <stx:process-self> ----------------------------------------
	} elsif ($el->{LocalName} eq 'process-self') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_P_SELF_END];
	    #print "COMP: >PROCESS SELF END /$el->{Name}\n";

	# <stx:process-attributes> ----------------------------------------
	} elsif ($el->{LocalName} eq 'process-attributes') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_P_ATTRIBUTES_END];
	    #print "COMP: >PROCESS ATTRIBUTES END /$el->{Name}\n";

	# <stx:process-buffer> ----------------------------------------
	} elsif ($el->{LocalName} eq 'process-buffer') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_P_BUFFER_END];
	    #print "COMP: >PROCESS BUFFER END /$el->{Name}\n";

	# <stx:process-document> ----------------------------------------
	} elsif ($el->{LocalName} eq 'process-document') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_P_DOC_END];
	    #print "COMP: >PROCESS DOCUMENT END /$el->{Name}\n";

	# <stx:call-procedure> ----------------------------------------
	} elsif ($el->{LocalName} eq 'call-procedure') {

	    push @{$self->{c_template}->[-1]->{instructions}}, 
	      [I_CALL_PROCEDURE_END];
	    #print "COMP: >CALL PROCEDURE END /$el->{Name}\n";

	# <stx:variable> ----------------------------------------
	} elsif ($el->{LocalName} =~ /^(variable|param)$/) {

	    # local variable
	    if ($self->{c_template}->[0]) {
		
		push @{$self->{c_template}->[-1]->{instructions}}, [I_VARIABLE_END];
		#print "COMP: >VARIABLE END\n";
	    } else {
		# tbd
	    }
	    
	# <stx:assign> ----------------------------------------
	} elsif ($el->{LocalName} eq 'assign') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_ASSIGN_END];
	    #print "COMP: >ASSIGN_END\n";

	# <stx:with-param> ----------------------------------------
	} elsif ($el->{LocalName} eq 'with-param') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_WITH_PARAM_END];
	    #print "COMP: >WITH_PARAM_END\n";

	# <stx:group> ----------------------------------------
	} elsif ($el->{LocalName} eq 'group') {
	    #$self->_dump_g_stack;
	    my $g = pop @{$self->{g_stack}};
	    $self->_sort_templates($g->{pc1});
	    $self->_sort_templates($g->{pc1A});
	    $self->_sort_templates($g->{pc2});
	    $self->_sort_templates($g->{pc2A});

	# <stx:template> ----------------------------------------
	} elsif ($el->{LocalName} eq 'template') {
	    pop @{$self->{c_template}};

	# <stx:procedure> ----------------------------------------
	} elsif ($el->{LocalName} eq 'procedure') {
	    pop @{$self->{c_template}};

	# <stx:copy> ----------------------------------------
	} elsif ($el->{LocalName} eq 'copy') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_COPY_END];
	    #print "COMP: >COPY_END\n";

	# <stx:element> ----------------------------------------
	} elsif ($el->{LocalName} eq 'element') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_ELEMENT_END];
	    #print "COMP: >ELEMENT_END /$el->{Name}\n";

	# <stx:attribute> ----------------------------------------
	} elsif ($el->{LocalName} eq 'attribute') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_ATTRIBUTE_END];
	    #print "COMP: >ATTRIBUTE_END\n";

        # <stx:cdata> ----------------------------------------
	} elsif ($el->{LocalName} eq 'cdata') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_CDATA_END];
	    #print "COMP: >CDATA_END\n";

        # <stx:comment> ----------------------------------------
	} elsif ($el->{LocalName} eq 'comment') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_COMMENT_END];
	    #print "COMP: >COMMENT_END\n";

        # <stx:processing-instruction> -----------------------------------
	} elsif ($el->{LocalName} eq 'processing-instruction') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_PI_END];
	    #print "COMP: >PI_END\n";

	# <stx:if> ----------------------------------------
	} elsif ($el->{LocalName} eq 'if') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_IF_END];
	    #print "COMP: >IF_END\n";

	# <stx:else> ----------------------------------------
	} elsif ($el->{LocalName} eq 'else') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_ELSE_END];
	    #print "COMP: >ELSE_END\n";

	# <stx:choose> ----------------------------------------
	} elsif ($el->{LocalName} eq 'choose') {

	    $self->{_choose} = undef;
	    #print "COMP: >CHOOSE_END\n";

	# <stx:when> ----------------------------------------
	} elsif ($el->{LocalName} eq 'when') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_ELSIF_END];
	    #print "COMP: >WHEN_END\n";

	# <stx:otherwise> ----------------------------------------
	} elsif ($el->{LocalName} eq 'otherwise') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_ELSE_END];
	    #print "COMP: >OTHERWISE_END\n";

	# <stx:buffer> ----------------------------------------
	} elsif ($el->{LocalName} eq 'buffer') {

	    # local buffer
	    if ($self->{c_template}->[0]) {
		push @{$self->{c_template}->[-1]->{instructions}}, [I_BUFFER_END];
		#print "COMP: >BUFFER_END\n";

	    } else {
		# kontrola pres lookahead
	    }

	# <stx:result-buffer> ----------------------------------------
	} elsif ($el->{LocalName} eq 'result-buffer') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_RES_BUFFER_END];
	    #print "COMP: >RESULT_BUFFER_END\n";

	# <stx:result-document> ----------------------------------------
	} elsif ($el->{LocalName} eq 'result-document') {

	    push @{$self->{c_template}->[-1]->{instructions}}, [I_RES_DOC_END];
	    #print "COMP: >RESULT_DOCUMENT_END\n";

	# <stx:for-each-item> ----------------------------------------
	} elsif ($el->{LocalName} eq 'for-each-item') {
	    pop @{$self->{c_template}};

	# <stx:while> ----------------------------------------
	} elsif ($el->{LocalName} eq 'while') {
	    pop @{$self->{c_template}};

	}

	# end tags for empty elements can be ignored, their emptiness is 
	# checked elsewhere

    # literals
    } else {
	
	push @{$self->{c_template}->[-1]->{instructions}}, [I_LITERAL_END, $el];
	#print "COMP: >LITERAL_END /$el->{Name}\n";
    }

    my $e = pop @{$self->{e_stack}};

    # end of local variable visibility
    if ($self->{c_template}->[0]) {
	foreach (@{$e->{vars}}) {
	    push @{$self->{c_template}->[-1]->{instructions}}, 
	      [I_VARIABLE_SCOPE_END, $_];
	    #print "COMP: >VARIABLE_SCOPE_END $_\n";
	}
    }
    # end of local buffer visibility
    if ($self->{c_template}->[0]) {
	foreach (@{$e->{bufs}}) {
	    push @{$self->{c_template}->[-1]->{instructions}}, 
	      [I_BUFFER_SCOPE_END, $_];
	    #print "COMP: >BUFFER_SCOPE_END $_\n";
	}
    }

    $self->{nsc}->popContext;
}

sub characters {
    my $self = shift;
    my $char = shift;

    # whitespace only
    if ($char->{Data} =~ /^\s*$/) {
	my $parent = $self->{e_stack}->[-1];
	if ($parent->{NamespaceURI} eq STX_NS_URI
	   and $parent->{LocalName} =~ /^(text|cdata)$/) {

	    if ($self->_allowed('_text')) {
		push @{$self->{c_template}->[-1]->{instructions}},
		  [I_CHARACTERS, $char->{Data}];
		#print "COMP: >CHARACTERS - $char->{Data}\n";
	    }
	}

    # not whitespace only
    } else {
	if ($self->_allowed('_text')) {
	    push @{$self->{c_template}->[-1]->{instructions}},
	      [I_CHARACTERS, $char->{Data}];
	    #print "COMP: >CHARACTERS - $char->{Data}\n";
	}	
    }
}

sub processing_instruction {
    my $self = shift;
    my $pi = shift;
}

sub ignorable_whitespace {
}

sub start_prefix_mapping {
    my ($self, $ns) = @_;

    $self->{nsc}->declare_prefix($ns->{Prefix}, $ns->{NamespaceURI});
}

sub end_prefix_mapping {
    my ($self, $ns) = @_;

    $self->{nsc}->undeclare_prefix($ns->{Prefix});
}

sub skipped_entity {
}

# lexical ----------------------------------------

sub start_cdata {
    my $self = shift;
}

sub end_cdata {
    my $self = shift;
}

sub comment {
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

# static evaluation ----------------------------------------

sub _static_eval {
    my ($self, $val) = @_;

    my $spath = XML::STX::STXPath->new();
    my $seq = $spath->expr(undef, $val);

    return $seq;
}

# tokenize ----------------------------------------

sub tokenize_match {
    my ($self, $pattern) = @_;
    my $tokens = [];

    foreach my $path (split('\|',$pattern)) {

	my $steps = [];

	$path =~ s/^\/\///g;
	$path =~ s/^\//&R/g;
	$path =~ s/\/\//&&&A/g;
	$path =~ s/\//&&&P/g;
	$path = '&N' . $path unless substr($path,0,2) eq '&R';

	foreach (split('&&', $path)) {
	    my $left = substr($_,1,1);
	    my $step = $self->tokenize(substr($_,2));
	    push @$steps, { left => $left, step => $step};
	}
	push @$tokens, $steps;
    }
    return $tokens;
}

sub match_priority {
    my ($self, $pattern) = @_;
    my $priority = [];

    foreach my $path (split('\|',$pattern)) {

	my @steps = split('/|//',$path);
	my $last = $steps[-1];
	my $p = 0.5;

	if ($#steps == 0) {

	    if ($last =~ /^$QName$/) {
		$p = 0;
		
	    } elsif ($last =~ /^processing-instruction\(?:$LITERAL\)$/) {
		$p = 0;

	    } elsif ($last =~ /^cdata\(\)$/) {
		$p = 0;
		
	    } elsif ($last =~ /^(?:$NCWild)$/) {
		$p = -0.25;
		
	    } elsif ($last =~ /^(?:$QNWild)$/) {
		$p = -0.25;
		
	    } elsif ($last =~ /^$NODE_TYPE$/) {
		$p = -0.5;
	    }
	}
	#print "TOK: last step: $last, more steps: $#steps, priority: $p\n";
	push @$priority, $p;
    }
    return $priority;
}

sub tokenize {
    my ($self, $path) = @_;
    study $path;

    my @tokens = ();
    #print "TOK: tokenizing: $path\n";
    
    while($path =~ m/\G
        \s*                                   # ignore all whitespace
        (   $LITERAL|                         # literal
            $DOUBLE_RE|                       # double numbers
            $NUMBER_RE|                       # digits
            \.\.|                             # parent
            \.|                               # current node
            $NODE_TYPE|                       # node type
            processing-instruction|           # pi, to allow pi(target)  
            \$$QName|                         # variable reference
            $QName\(|                         # function
            $NCWild|$QName|$QNWild|           # QName
            \@($NCWild|$QName|$QNWild)|       # attribute
            \!=|<=|\-|>=|\/\/|and|or|mod|div| # multi-char seps
            [,\+=\|<>\/\(\[\]\)]|             # single char seps
            (?<!(\@|\(|\[))\*|                # multiply operator rules
            $                                 # end of query
        )
        \s* # ignore all whitespace
        /gcxso) {

        my ($token) = ($1);

        if (length($token)) {
            #print "TOK: token: $token\n";

	    # resolving QNames ####################
	    if ($token =~ /^$QName\($/o) {
		$token = $self->_expand_prefixedFce($token);

		$token = substr($token, 0, length($token) - 1);
		push @tokens, $token, '(';

	    } elsif ($token =~ /^$NCName$/o 
		     && $token !~ /^(?:and|or|mod|div)$/) {

 		if ($self->{Sheet}->{Options}->
		    {'stxpath-default-namespace'}->[-1]) {
 		    $token = '{' . $self->{Sheet}->{Options}->
		      {'stxpath-default-namespace'}->[-1]
 			. '}' . $token;
		}
		push @tokens, $token;

	    } elsif ($token =~ /^([\@\$])?($QName)$/o) {
		$token = $1 . $self->_expand_prefixedQN($2);
		push @tokens, $token;

	    } elsif ($token =~ /^(\@)?($NCName):\*$/o) {
		$token = $1 . $self->_expand_prefixedQN("$2:lname");
		$token =~ s/lname$/*/;
		push @tokens, $token;

	    } elsif ($token =~ /^(\@)?\*:($NCName|\*)$/o) {
		$token = $1 . "{*}$2";
		push @tokens, $token;

	    } else {
		push @tokens, $token;
	    }
            #print "TOK: exp. token: $token\n";
        }
    }

    if (pos($path) < length($path)) {
        my $marker = ("." x (pos($path)-1));
        $path = substr($path, 0, pos($path) + 8) . "...";
        $path =~ s/\n/ /g;
        $path =~ s/\t/ /g;
	$self->doError(1, 3, $path, $marker);
    }

    return \@tokens;
}

# structure ----------------------------------------

my $s_group = ['variable','buffer','template','procedure','include','group'];

my $s_top_level = [@$s_group, 'param', 'namespace-alias'];

my $s_text_constr = ['text','cdata','value-of','if','else','choose','_text'];

my $s_content_constr = [@$s_text_constr ,'call-procedure', 'copy',
			'process-attributes', 'process-self', 'element',
			'start-element', 'end-element', 'comment',
			'processing-instruction', 'variable', 'param', 
			'assign', 'buffer', 'result-buffer', 'process-buffer',
			'result-document', 'process-document', 'for-each-item',
			'while', '_literal', 'attribute'];

my $s_template = [@$s_content_constr, 'process-children', 'process-siblings'];

my $sch = {
	   transform => $s_top_level,
	   group => $s_group,
	   template => $s_template,
	   procedure => $s_template,
	   'process-children' => ['with-param'],
	   'process-attributes' => ['with-param'],
	   'process-self' => ['with-param'],
	   'process-siblings' => ['with-param'],
	   'process-document' => ['with-param'],
	   'process-buffer' => ['with-param'],
	   'call-procedure' => ['with-param'],
	   'with-param' => $s_text_constr,
	   param => $s_text_constr,
	   copy => $s_template,
	   element => $s_template,
	   attribute => $s_text_constr,
	   'processing-instruction' => $s_text_constr,
	   comment => $s_text_constr,
	   'if' => $s_template,
	   'else' => $s_template,
	   choose => ['when','otherwise'],
	   when => $s_template,
	   otherwise => $s_template,
	   'for-each-item' => $s_template,
	   while => $s_template,
	   variable => $s_text_constr,
	   assign => $s_text_constr,
	   text => ['_text'],
	   cdata => ['_text'],
	   buffer => $s_template,
	   'result-buffer' => $s_template,
	   'result-document' => $s_template,
	   _literal => $s_template,
	  };

sub _allowed {
    my ($self, $lname) = @_;

    if ($#{$self->{e_stack}} == -1) {

	$self->doError(202, 3, $lname) 
	  unless $lname eq 'transform';

    } else {
	my $parent = $self->{e_stack}->[-1];

	my $s_key = (defined $parent->{NamespaceURI} 
	  and $parent->{NamespaceURI} eq STX_NS_URI)
	  ? $parent->{LocalName} : '_literal';

	$self->doError(215, 3, $lname, $parent->{Name})
	  unless grep($_ eq $lname ,@{$sch->{$s_key}});
    }
    return 1;
}

# utils ----------------------------------------

sub _avt {
    my ($self, $val) = @_;

    if ($val =~ /^\{([^\}\{]*)\}$/) {
	return $self->tokenize($1);

    } elsif ($val =~ /^.*\{([^\}\{]*)\}.*$/) {
	$val =~ s/^(.*)$/concat('$1')/;
	$val =~ s/\{/',/g;
	$val =~ s/\}/,'/g;
	$val =~ s/'',|,''//g;
	return $self->tokenize($val);

    } else {
	return $val;	
    }
}

sub _sort_templates {
    my ($self, $t) = @_;
    my $sorted = 1;

    while ($sorted) {
	$sorted = 0;
	for (my $i=0; $i < $#$t; $i++) {
	    if ($t->[$i+1]->{eff_p} > $t->[$i]->{eff_p}) {
		my $tmp = $t->[$i];
		$t->[$i] = $t->[$i+1];
		$t->[$i+1] = $tmp;
		$sorted = 1;
	    }
	}
    }
}

sub _expand_qname {
    my ($self, $qname) = @_;

    my @n = $self->{nsc}->process_element_name($qname);
    return $n[0] ? "{$n[0]}$n[2]" : $qname;
}

# default NS is ignored
sub _expand_prefixedQN {
    my ($self, $qname) = @_;

    my @n = $self->{nsc}->process_attribute_name($qname);
    return $n[0] ? "{$n[0]}$n[2]" : $qname;
}

# default function NS is used
sub _expand_prefixedFce {
    my ($self, $qname) = @_;

    my @n = $self->{nsc}->process_attribute_name($qname);
    return $n[0] ? "{$n[0]}$n[2]" : '{' . STX_FNS_URI . "}$n[2]";
}

sub _process_templates {
    my ($self, $g) = @_;

    foreach my $t (keys %{$g->{templates}}) {

	# namespace-alias
	foreach my $i (@{$g->{templates}->{$t}->{instructions}}) {
	    if ($i->[0] == I_LITERAL_START or $i->[0] == I_LITERAL_END) {

		foreach (@{$self->{Sheet}->{alias}}) {
		    if ($i->[1]->{NamespaceURI} eq $_->[0]->[0]) {
			$i->[1]->{NamespaceURI} = $_->[1]->[0];
			$i->[1]->{Prefix} = $_->[1]->[1];
			$i->[1]->{Name} = $i->[1]->{Prefix} 
			  ? "$i->[1]->{Prefix}:$i->[1]->{LocalName}" 
			    : $i->[1]->{LocalName};
			last;
		    }
		}

		if (exists $i->[1]->{Attributes}) {
		    foreach my $ns (keys %{$i->[1]->{Attributes}}) {

			foreach (@{$self->{Sheet}->{alias}}) {
			    if ($i->[1]->{Attributes}->{$ns}->{NamespaceURI} 
				eq $_->[0]->[0]) {
				my $key = "{$_->[1]->[0]}" 
				  . $i->[1]->{Attributes}->{$ns}->{LocalName};

				$i->[1]->{Attributes}->{$key} 
				  = $i->[1]->{Attributes}->{$ns};
				delete $i->[1]->{Attributes}->{$ns};

				$i->[1]->{Attributes}->{$key}->{NamespaceURI} 
				  = $_->[1]->[0];
				$i->[1]->{Attributes}->{$key}->{Prefix} 
				  = $_->[1]->[1];
				$i->[1]->{Attributes}->{$key}->{Name} 
				  = $i->[1]->{Attributes}->{$key}->{Prefix} 
				    ? "$i->[1]->{Attributes}->{$key}->{Prefix}:"
				      . $i->[1]->{Attributes}->{$key}->{LocalName}
					: $i->[1]->{Attributes}->{$key}->{LocalName};
				last;
			    }
			}
		    }
		}
	    }
	}
    }

    foreach (keys %{$g->{groups}}) {
	$self->_process_templates($g->{groups}->{$_})
    }
}

# debug ----------------------------------------

sub _dump_g_stack {
    my $self = shift;

    print "G-stack:", 
      join('|',map("$_->{gid}",@{$self->{g_stack}})), "\n";
}

1;
__END__

=head1 NAME

XML::STX::Parser - XML::STX stylesheet parser

=head1 SYNOPSIS

no public API, used from XML::STX

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX, perl(1).

no public API


=cut

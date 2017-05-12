package XML::Parser::Lite::Tree::XPath::Token;

use strict;
use XML::Parser::Lite::Tree::XPath::Result;
use XML::Parser::Lite::Tree::XPath::Axis;
use Data::Dumper;

sub new {
	my $class = shift;
 	my $self = bless {}, $class;
	return $self;
}

sub match {
	my ($self, $type, $content) = @_;

	return 0 unless $self->{type} eq $type;

	return 0 if (defined($content) && ($self->{content} ne $content));

	return 1;
}

sub is_expression {
	my ($self) = @_;

	return 1 if $self->{type} eq 'Number';
	return 1 if $self->{type} eq 'Literal';
	return 0 if $self->{type} eq 'Operator';

	warn "Not sure if $self->{type} is an expression";

	return 0;
}

sub dump {
	my ($self) = @_;

	my $ret = $self->{type};
	$ret .= ':absolute' if $self->{absolute};
	$ret .= ':'.$self->{content} if defined $self->{content};
	$ret .= '::'.$self->{axis} if defined $self->{axis};

	return $ret;
}

sub ret {
	my ($self, $a, $b) = @_;
	return XML::Parser::Lite::Tree::XPath::Result->new($a, $b);
}

sub eval {
	my ($self, $context) = @_;

	return $context if $context->is_error;
	$self->{context} = $context;

	if ($self->{type} eq 'LocationPath'){

		# a LocationPath should just be a list of Steps, so eval them in order

		my $ret;

		if ($self->{absolute}){
			$ret = $self->{root};
		}else{
			$ret = $context->get_nodeset;
			return $ret if $ret->is_error;
		}


		for my $step(@{$self->{tokens}}){

			unless ($step->match('Step')){
				return $self->ret('Error', "Found a non-Step token ('$step->{type}') in a LocationPath");
			}

			$ret = $step->eval($ret);

			return $ret if $ret->is_error;

			$ret->normalize();
		}

		return $ret;

	}elsif ($self->{type} eq 'Step'){

		# for a step, loop through it's children

		# my $axis = defined($self->{axis}) ? $self->{axis} : 'child';
		# my $ret = $self->filter_axis($axis, $context);

		my $ret = XML::Parser::Lite::Tree::XPath::Axis::instance->filter($self, $context);

		for my $step(@{$self->{tokens}}){

			unless ($step->match('AxisSpecifier') || $step->match('NameTest') || $step->match('Predicate') || $step->match('NodeTypeTest')){

				return $self->ret('Error', "Found an unexpected token ('$step->{type}') in a Step");
			}

			$ret = $step->eval($ret);

			return $ret if $ret->is_error;
		}

		return $ret;


	}elsif ($self->{type} eq 'NameTest'){

		return $context if $self->{content} eq '*';

		if ($self->{content} =~ m!\:\*$!){
			return $self->ret('Error', "Can't do NCName:* NameTests");
		}

		if ($context->{type} eq 'nodeset'){
			my $out = $self->ret('nodeset', []);

			for my $tag(@{$context->{value}}){

				if (($tag->{'type'} eq 'element') && ($tag->{'name'} eq $self->{content})){
					push @{$out->{value}}, $tag;
				}

				if (($tag->{'type'} eq 'attribute') && ($tag->{'name'} eq $self->{content})){
					push @{$out->{value}}, $tag;
				}
			}

			return $out;
		}

		return $self->ret('Error', "filter by name $self->{content} on context $context->{type}");


	}elsif ($self->{type} eq 'NodeTypeTest'){

		if ($self->{content} eq 'node'){
			if ($context->{type} eq 'nodeset'){
				return $context;
			}else{
				return $self->ret('Error', "can't filter node() on a non-nodeset value.");
			}
		}

		return $self->ret('Error', "NodeTypeTest with an unknown filter ($self->{content})");


	}elsif ($self->{type} eq 'Predicate'){

		my $expr = $self->{tokens}->[0];

		my $out = $self->ret('nodeset', []);
		my $i = 1;
		my $c = scalar @{$context->{value}};

		for my $child(@{$context->{value}}){

			$child->{proximity_position} = $i;
			$child->{context_size} = $c;
			$i++;

			my $ret = $expr->eval($self->ret('node', $child));

			if ($ret->{type} eq 'boolean'){

				if ($ret->{value}){
					push @{$out->{value}}, $child;
				}

			}elsif ($ret->{type} eq 'number'){

				if ($ret->{value} == $child->{proximity_position}){
					push @{$out->{value}}, $child;
				}

			}elsif ($ret->{type} eq 'nodeset'){

				if (scalar @{$ret->{value}}){
					push @{$out->{value}}, $child;
				}

			}elsif ($ret->{type} eq 'Error'){

				return $ret;

			}else{
				return $self->ret('Error', "unexpected predicate result type ($ret->{type})");
			}

			delete $child->{proximity_position};
			delete $child->{context_size};
		}

		return $out;

	}elsif ($self->{type} eq 'Number'){

		return $self->ret('number', $self->{content});

	}elsif ($self->{type} eq 'FunctionCall'){

		my $handler = $self->get_function_handler($self->{content});

		if ((!defined $handler) || (!defined $handler->[0])){
			return $self->ret('Error', "No handler for function call '$self->{content}'");
		}


		#
		# evaluate each of the supplied args first
		#

		my @in_args;
		for my $source (@{$self->{tokens}}){
			my $out = $source->eval($context);
			return $out if $out->is_error;
			push @in_args, $out;
		}


		#
		# now check them against the function signature
		#

		my $func = $handler->[0];
		my $sig = $handler->[1];
		my @sig = split /,/, $sig;
		my @out_args;

		my $position = 0;

		for my $sig(@sig){

			my $repeat = 0;
			my $optional = 0;

			if ($sig =~ m/\+$/){ $repeat = 1; }
			if ($sig =~ m/\?$/){ $optional = 1; }
			$sig =~ s/[?+]$//;

			#
			# repeating args are somewhat tricky
			#

			if ($repeat){

				my $count = 0;

				while (1){
					$count++;

					unless (defined $in_args[$position]){
						if ($count == 1){
							return $self->ret('Error', "Argument $position to function $self->{content} is required (type $sig)");
						}
						last;
					}

					my $value = $self->coerce($in_args[$position], $sig);
					$position++;
					if (defined $value){
						return $value if $value->is_error;
						push @out_args, $value;

					}else{
						if ($count == 1){
							return $self->ret('Error', "Can't coerce argument $position to a $sig in function $self->{content}");
						}
						last;
					}
				}

			}else{

				unless (defined $in_args[$position]){
					if ($optional){
						next;
					}else{
						return $self->ret('Error', "Argument $position to function $self->{content} is required (type $sig)");
					}
				}

				my $value = $self->coerce($in_args[$position], $sig);
				$position++;

				if (defined $value){

					return $value if $value->is_error;
					push @out_args, $value;
				}else{
					return $self->ret('Error', "Can't coerce argument $position to a $sig in function $self->{content}");
				}
			}
		}

		return &{$func}($self, \@out_args);

	}elsif ($self->{type} eq 'FunctionArg'){

		# a FunctionArg should have a single child

		return $self->ret('Error', 'FunctionArg should have 1 token') unless 1 == scalar @{$self->{tokens}};

		return $self->{tokens}->[0]->eval($context);

	}elsif (($self->{type} eq 'EqualityExpr') || ($self->{type} eq 'RelationalExpr')){

		my $v1 = $self->{tokens}->[0]->eval($context);
		my $v2 = $self->{tokens}->[1]->eval($context);
		my $t = "$v1->{type}/$v2->{type}";

		return $v1 if $v1->is_error;
		return $v2 if $v2->is_error;

		if ($v1->{type} gt $v2->{type}){
			$t = "$v2->{type}/$v1->{type}";
			($v1, $v2) = ($v2, $v1);
		}

		if ($t eq 'nodeset/string'){

			for my $node(@{$v1->{value}}){;

				my $v1_s = $self->ret('node', $node)->get_string;
				return $v1_s if $v1_s->is_error;

				my $ok = $self->compare_op($self->{content}, $v1_s, $v2);
				return $ok if $ok->is_error;

				return $ok if $ok->{value};
			}

			return $self->ret('boolean', 0);
		}

		if ($t eq 'string/string'){

			return $self->compare_op($self->{content}, $v1, $v2);
		}

		if ($t eq 'number/number'){

			return $self->compare_op($self->{content}, $v1, $v2);
		}

		return $self->ret('Error', "can't do an EqualityExpr on $t");

	}elsif ($self->{type} eq 'Literal'){

		return $self->ret('string', $self->{content});


	}elsif ($self->{type} eq 'UnionExpr'){

		my $a1 = $self->get_child_arg(0, 'nodeset');
		my $a2 = $self->get_child_arg(1, 'nodeset');

		return $a1 if $a1->is_error;
		return $a2 if $a2->is_error;

		my $out = $self->ret('nodeset', []);

		map{ push @{$out->{value}}, $_ } @{$a1->{value}};
		map{ push @{$out->{value}}, $_ } @{$a2->{value}};

		$out->normalize();

		return $out;

	}elsif ($self->{type} eq 'MultiplicativeExpr'){

		my $a1 = $self->get_child_arg(0, 'number');
		my $a2 = $self->get_child_arg(1, 'number');

		return $a1 if $a1->is_error;
		return $a2 if $a2->is_error;

		my $result = 0;
		$result = $a1->{value} * $a2->{value} if $self->{content} eq '*';
		$result = $self->op_mod($a1->{value}, $a2->{value}) if $self->{content} eq 'mod';
		$result = $self->op_div($a1->{value}, $a2->{value}) if $self->{content} eq 'div';

		return $self->ret('number', $result);

	}elsif (($self->{type} eq 'OrExpr') || ($self->{type} eq 'AndExpr')){

		my $a1 = $self->get_child_arg(0, 'boolean');
		my $a2 = $self->get_child_arg(1, 'boolean');

		return $a1 if $a1->is_error;
		return $a2 if $a2->is_error;

		return $self->ret('boolean', $a1->{value} || $a2->{value}) if $self->{type} eq 'OrExpr';
		return $self->ret('boolean', $a1->{value} && $a2->{value}) if $self->{type} eq 'AndExpr';

	}elsif ($self->{type} eq 'AdditiveExpr'){

		my $a1 = $self->get_child_arg(0, 'number');
		my $a2 = $self->get_child_arg(1, 'number');

		return $a1 if $a1->is_error;
		return $a2 if $a2->is_error;

		my $result = 0;
		$result = $a1->{value} + $a2->{value} if $self->{content} eq '+';
		$result = $a1->{value} - $a2->{value} if $self->{content} eq '-';

		return $self->ret('number', $result);

	}elsif ($self->{type} eq 'UnaryExpr'){

		my $a1 = $self->get_child_arg(0, 'number');

		return $a1 if $a1->is_error;

		$a1->{value} = - $a1->{value};

		return $a1;

	}else{
		return $self->ret('Error', "Don't know how to eval a '$self->{type}' node.");
	}
}

sub coerce {
	my ($self, $arg, $type) = @_;

	my $value = undef;

	$value = $arg->get_string if $type eq 'string';
	$value = $arg->get_number if $type eq 'number';
	$value = $arg->get_nodeset if $type eq 'nodeset';
	$value = $arg->get_boolean if $type eq 'boolean';
	$value = $arg if $type eq 'any';

	return $value;
}

sub get_child_arg {
	my ($self, $pos, $type) = @_;

	my $token = $self->{tokens}->[$pos];
	return $self->ret('Error', "Required child token {1+$pos} for $self->{type} token wasn't found.") unless defined $token;

	my $out = $token->eval($self->{context});
	return $out if $out->is_error;

	return $out->get_type($type);
}


sub get_function_handler {
	my ($self, $function) = @_;

	my $function_map = {

		# nodeset functions
		'last'			=> [\&function_last,		''			],
		'position'		=> [\&function_position,	''			],
		'count'			=> [\&function_count,		'nodeset'		],
		'id'			=> [\&function_id,		'any'			],
		'local-name'		=> [\&function_local_name,	'nodeset?'		],
		'namespace-uri'		=> [\&function_namespace_uri,	'nodeset?'		],
		'name'			=> [\&function_name,		'nodeset?'		],

		# string functions
		'string'		=> [\&function_string,		'any?'			],
		'concat'		=> [\&function_concat,		'string,string+'	],
		'starts-with'		=> [\&function_starts_with,	'string,string'		],
		'contains'		=> [\&function_contains,	'string,string'		],
		'substring-before'	=> [\&function_substring_befor,	'string,string'		],
		'substring-after'	=> [\&function_substring_after,	'string,string'		],
		'substring'		=> [undef,			'string,number,number?'	],
		'string-length'		=> [\&function_string_length,	'string?'		],
		'normalize-space'	=> [\&function_normalize_space,	'string?'		],
		'translate'		=> [undef,			'string,string,string'	],

		# boolean functions
		'boolean'		=> [undef,			'any'			],
		'not'			=> [\&function_not,		'boolean'		],
		'true'			=> [undef,			''			],
		'false'			=> [undef,			''			],
		'lang'			=> [undef,			'string'		],

		# number functions
		'number'		=> [undef,			'any?'			],
		'sum'			=> [undef,			'nodeset'		],
		'floor'			=> [\&function_floor,		'number'		],
		'ceiling'		=> [\&function_ceiling,		'number'		],
		'round'			=> [undef,			'number'		],

	};

	return $function_map->{$function} if defined $function_map->{$function};

	return undef;
}

sub function_last {
	my ($self, $args) = @_;

	return $self->ret('number', $self->{context}->{value}->{context_size});
}

sub function_not {
	my ($self, $args) = @_;

	my $out = $args->[0];
	$out->{value} = !$out->{value};

	return $out
}

sub function_normalize_space {
	my ($self, $args) = @_;

	my $value = $args->[0];

	unless (defined $value){
		$value = $self->{context}->get_string;
		return $value if $value->get_error;
	}

	$value = $value->{value};
	$value =~ s!^[\x20\x09\x0d\x0a]+!!;
	$value =~ s![\x20\x09\x0d\x0a]+$!!;
	$value =~ s![\x20\x09\x0d\x0a]+! !g;

	return $self->ret('string', $value);
}

sub function_count {
	my ($self, $args) = @_;

	my $subject = $args->[0];

	return $self->ret('number', scalar(@{$subject->{value}})) if $subject->{type} eq 'nodeset';

	die("can't perform count() on $subject->{type}");
}

sub function_starts_with {
	my ($self, $args) = @_;

	my $s1 = $args->[0]->{value};
	my $s2 = $args->[1]->{value};

	return $self->ret('boolean', (substr($s1, 0, length $s2) eq $s2));
}

sub function_contains {
	my ($self, $args) = @_;

	my $s1 = $args->[0]->{value};
	my $s2 = quotemeta $args->[1]->{value};

	return $self->ret('boolean', ($s1 =~ /$s2/));
}

sub function_string_length {
	my ($self, $args) = @_;

	my $value = $args->[0];

	unless (defined $value){
		$value = $self->{context}->get_string;
		return $value if $value->is_error;
	}

	return $self->ret('number', length $value->{value});
}

sub function_position {
	my ($self, $args) = @_;

	my $node = $self->{context}->get_nodeset;
	return $node if $node->is_error;

	$node = $node->{value}->[0];
	return $self->ret('Error', "No node in context nodeset o_O") unless defined $node;

	return $self->ret('number', $node->{proximity_position});
}

sub function_floor {
	my ($self, $args) = @_;

	my $val = $args->[0]->{value};
	my $ret = $self->simple_floor($val);

	$ret = - $self->simple_ceiling(-$val) if $val < 0;

	return $self->ret('number', $ret);
}

sub function_ceiling {
	my ($self, $args) = @_;

	my $val = $args->[0]->{value};
	my $ret = $self->simple_ceiling($val);

	$ret = - $self->simple_floor(-$val) if $val < 0;

	return $self->ret('number', $ret);
}

sub function_id {
	my ($self, $args) = @_;

	unless ($self->{context}->{type} eq 'node' || $self->{context}->{type} eq 'nodeset'){

		return $self->ret('Error', "Can only call id() in a node or nodeset context - not $self->{context}->{type}");
	}

	my $obj = $args->[0];
	my $ids = '';

	if ($obj->{type} eq 'nodeset'){

		for my $node(@{$obj->{value}}){

			$ids .= ' ' . $self->get_string_value($node);
		}
	}else{
		$ids = $obj->get_string->{value};
	}

	$ids =~ s!^\s*(.*?)\s*$!$1!;

	$self->ret('nodeset', []) unless length $ids;

	my @ids = split /[ \t\r\n]+/, $ids;


	#
	# we have a list of IDs to search for - now traverse the whole document,
	# checking every element node
	#

	my $root = {};

	if ($self->{context}->{type} eq 'nodeset'){
		$root = $self->{context}->{value}->[0];
	}
	if ($self->{context}->{type} eq 'node'){
		$root = $self->{context}->{value};
	}

	$root = $root->{parent} while defined $root->{parent};

	my $out = $self->_recurse_find_id($root, \@ids);

	return $self->ret('nodeset', $out);
}

sub _recurse_find_id {
	my ($self, $node, $ids) = @_;

	my $out = [];

	#
	# is it a match?
	#

	if ($node->{type} eq 'element' && length $node->{uid}){

		for my $id (@{$ids}){
			if ($id eq $node->{uid}){
				push @{$out}, $node;
				last;
			}
		}
	}


	#
	# do we need to recurse?
	#

	if ($node->{type} eq 'element' || $node->{type} eq 'root'){

		for my $child (@{$node->{children}}){

			my $more = $self->_recurse_find_id($child, $ids);

			for my $match (@{$more}){

				push @{$out}, $match;
			}
		}
	}

	return $out;
}

sub function_local_name {
	my ($self, $args) = @_;

	my $node = $self->_get_first_node_by_doc_order($args);

	return $node if $node->{type} eq 'Error';
	return $self->ret('string', '') unless defined $node;

	my $name = $self->get_expanded_name($node);

	return return $self->ret('string', $name->{local}) if defined $name;
	return $self->ret('string', '');
}

sub function_namespace_uri {
	my ($self, $args) = @_;

	my $node = $self->_get_first_node_by_doc_order($args);

	return $node if $node->{type} eq 'Error';
	return $self->ret('string', '') unless defined $node;

	my $name = $self->get_expanded_name($node);

	return return $self->ret('string', $name->{ns}) if defined $name;
	return $self->ret('string', '');
}

sub function_name {
	my ($self, $args) = @_;

	my $node = $self->_get_first_node_by_doc_order($args);

	return $node if $node->{type} eq 'Error';
	return $self->ret('string', '') unless defined $node;

	my $name = $self->get_expanded_name($node);

	return return $self->ret('string', $name->{qname}) if defined $name;
	return $self->ret('string', '');
}

sub _get_first_node_by_doc_order {
	my ($self, $args) = @_;


	#
	# for no args, take the first node in the context nodeset
	#

	unless (defined $args->[0]){

		return $self->{context}->{value} if $self->{context}->{type} eq 'node';
		return $self->{context}->{value}->[0] if $self->{context}->{type} eq 'nodeset';

		return $self->ret('Error', "If argument is ommitted, context must be node or nodeset - not $self->{context}->{type}");
	}


	#
	# we have a nodeset arg - return the node with the lowest doc order
	#

	return $args->[0]->{value} if $args->[0]->{type} eq 'node';

	if ($args->[0]->{type} eq 'nodeset'){

		my $min = $self->{max_order} + 1;
		my $low = undef;

		for my $node (@{$args->[0]->{value}}){

			if ($node->{order} < $min){

				$min = $node->{order};
				$low = $node;
			}
		}

		return $low;
	}

	return $self->ret('Error', "Argument to fucntion isn't expected node/nodeset");
}

sub function_string {
	my ($self, $args) = @_;


	#
	# for no args, use the context node
	#

	unless (defined $args->[0]){

		return $self->ret('string', $self->get_string_value($self->{context}->{value})) if $self->{context}->{type} eq 'node';
		return $self->ret('string', $self->get_string_value($self->{context}->{value}->[0])) if $self->{context}->{type} eq 'nodeset';

		return $self->ret('Error', "If argument to string() is ommitted, context must be node or nodeset - not $self->{context}->{type}");
	}

	if ($args->[0]->{type} eq 'number'){

		return $self->ret('string', $args->[0]->{value});
	}

	if ($args->[0]->{type} eq 'string'){

		return $self->ret('string', $args->[0]->{value});
	}

	if ($args->[0]->{type} eq 'node' || $args->[0]->{type} eq 'nodeset'){

		my $node = $self->_get_first_node_by_doc_order($args);
		return $node if $node->{type} eq 'Error';

		if ($node->{type} eq 'element'){
			return $self->ret('string', $self->get_string_value($node));
		}else{
			return $self->ret('string', '');
		}
	}

	if ($args->[0]->{type} eq 'boolean'){

		return $self->ret('string', $args->[0]->{value} ? 'true' : 'false');
	}

	return $self->ret('Error', "Don't know how to perform string() on a $args->[0]->{type}");
}

sub function_concat {
	my ($self, $args) = @_;

	my $out = '';
	$out .= $_->{value} for @{$args};

	return $self->ret('string', $out);
}

sub function_substring_befor {
	my ($self, $args) = @_;

	my $idx = index $args->[0]->{value}, $args->[1]->{value};

	if ($idx == -1){
		return $self->ret('string', '');
	}

	return $self->ret('string', substr $args->[0]->{value}, 0, $idx);
}

sub function_substring_after {
	my ($self, $args) = @_;

	my $idx = index $args->[0]->{value}, $args->[1]->{value};

	if ($idx == -1){
		return $self->ret('string', '');
	}

	return $self->ret('string', substr $args->[0]->{value}, $idx + length $args->[1]->{value});
}

sub simple_floor {
	my ($self, $value) = @_;
	return int $value;
}

sub simple_ceiling {
	my ($self, $value) = @_;
	my $t = int $value;
	return $t if $t == $value;
	return $t+1;
}

sub compare_op {
	my ($self, $op, $a1, $a2) = @_;

	if ($a1->{type} eq 'string'){
		if ($op eq '=' ){ return $self->ret('boolean', ($a1->{value} eq $a2->{value}) ? 1 : 0); }
		if ($op eq '!='){ return $self->ret('boolean', ($a1->{value} ne $a2->{value}) ? 1 : 0); }
		if ($op eq '>='){ return $self->ret('boolean', ($a1->{value} ge $a2->{value}) ? 1 : 0); }
		if ($op eq '<='){ return $self->ret('boolean', ($a1->{value} le $a2->{value}) ? 1 : 0); }
		if ($op eq '>' ){ return $self->ret('boolean', ($a1->{value} gt $a2->{value}) ? 1 : 0); }
		if ($op eq '<' ){ return $self->ret('boolean', ($a1->{value} lt $a2->{value}) ? 1 : 0); }
	}

	if ($a1->{type} eq 'number'){
		if ($op eq '=' ){ return $self->ret('boolean', ($a1->{value} == $a2->{value}) ? 1 : 0); }
		if ($op eq '!='){ return $self->ret('boolean', ($a1->{value} != $a2->{value}) ? 1 : 0); }
		if ($op eq '>='){ return $self->ret('boolean', ($a1->{value} >= $a2->{value}) ? 1 : 0); }
		if ($op eq '<='){ return $self->ret('boolean', ($a1->{value} <= $a2->{value}) ? 1 : 0); }
		if ($op eq '>' ){ return $self->ret('boolean', ($a1->{value} >  $a2->{value}) ? 1 : 0); }
		if ($op eq '<' ){ return $self->ret('boolean', ($a1->{value} <  $a2->{value}) ? 1 : 0); }
	}
 
	return $self->ret('Error', "Don't know how to compare $op on type $a1->{type}");
}

sub op_mod {
	my ($self, $n1, $n2) = @_;

	my $r = int ($n1 / $n2);
	return $n1 - ($r * $n2);
}

sub op_div {
	my ($self, $n1, $n2) = @_;

	return $n1 / $n2;
}

sub get_string_value {
	my ($self, $node) = @_;


	if ($node->{type} eq 'element' || $node->{type} eq 'root'){

		#
		# The string-value of an element node is the concatenation of the string-values
		# of all text node descendants of the element node in document order.
		#

		my $value = '';
		for my $child (@{$node->{children}}){
			if ($child->{type} eq 'element'){
				$value .= $self->get_string_value($child);
			}
			if ($child->{type} eq 'text'){
				$value .= $self->get_string_value($child);
			}
		}
		return $value;
	}

	if ($node->{type} eq 'attribute'){

		#
		# An attribute node has a string-value. The string-value is the normalized value
		# as specified by the XML Recommendation [XML]. An attribute whose normalized value
		# is a zero-length string is not treated specially: it results in an attribute node
		# whose string-value is a zero-length string.
		#
	}

	if ($node->{type} eq 'namespace'){

		#
		# The string-value of a namespace node is the namespace URI that is being bound to
		# the namespace prefix; if it is relative, it must be resolved just like a namespace
		# URI in an expanded-name.
		#
	}

		#
		# The string-value of a processing instruction node is the part of the processing
		# instruction following the target and any whitespace. It does not include the
		# terminating ?>.
		#

		#
		# The string-value of comment is the content of the comment not including the
		# opening <!-- or the closing -->.
		#

	if ($node->{type} eq 'text'){

		#
		# The string-value of a text node is the character data. A text node always has
		# at least one character of data.
		#

		return $node->{content};
	}

	print "# we can't find a string-value for this node!\n";
	print Dumper $node;

	return '';
}

sub get_expanded_name {
	my ($self, $node) = @_;

	if ($node->{type} eq 'element'){

		return {
			'ns'    => $node->{ns},
			'qname' => $node->{name},
			'local' => defined $node->{local_name} ? $node->{local_name} : $node->{name},
		};
	}

	if ($node->{type} eq 'root'){

		return undef;
	}

	print "# we can't find an expanded name for this node!\n";
	print Dumper $node;

	return undef;
}

1;

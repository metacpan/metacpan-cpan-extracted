package XML::Parser::Lite::Tree::XPath::Tree;

use strict;
use XML::Parser::Lite::Tree::XPath::Tokener;

sub new {
	my ($class) = @_;
	my $self = bless {}, $class;
	$self->{error} = 0;
	return $self;
}

sub build_tree {
	my ($self, $tokens) = @_;

	$self->{error} = 0;
	$self->{tokens} = $tokens;

	#
	# build a basic tree using the brackets
	#

	return 0 unless $self->make_groups();
	$self->recurse_before($self, 'del_links');


	#
	# simple groupings
	#

	return 0 unless $self->recurse_before($self, 'clean_axis_and_abbreviations');
	return 0 unless $self->recurse_before($self, 'claim_groups');
	return 0 unless $self->recurse_after($self, 'build_steps');
	return 0 unless $self->recurse_after($self, 'build_paths');


	#
	# get operator oprands
	#

	return 0 unless $self->binops(['|'], 'UnionExpr');
	return 0 unless $self->recurse_before($self, 'unary_minus');
	return 0 unless $self->binops(['*','div','mod'], 'MultiplicativeExpr');
	return 0 unless $self->binops(['+','-'], 'AdditiveExpr');
	return 0 unless $self->binops(['<','<=','>','>='], 'RelationalExpr');
	return 0 unless $self->binops(['=','!='], 'EqualityExpr');
	return 0 unless $self->binops(['and'], 'AndExpr');
	return 0 unless $self->binops(['or'], 'OrExpr');

	#return 0 unless $self->find_expressions(['UnionExpr', 'MultiplicativeExpr', 'AdditiveExpr', 'RelationalExpr', 'EqualityExpr', 'AndExpr', 'OrExpr']);


	return 1;
}

sub dump_flat {
	my ($self) = @_;
	$self->{dump} = '';

	for my $token(@{$self->{tokens}}){
		$self->dump_flat_go($token);
	}

	my $dump = $self->{dump};
	delete $self->{dump};
	return $dump;
}

sub dump_flat_go {
	my ($self, $node) = @_;

	$self->{dump} .= '['.$node->dump();

	for my $token(@{$node->{tokens}}){

		$self->dump_flat_go($token);
	}

	$self->{dump} .= ']';
}

sub dump_tree {
	my ($self) = @_;
	$self->{dump} = '';
	$self->{indent} = [''];

	for my $token(@{$self->{tokens}}){
		$self->dump_tree_go($token);
	}

	my $dump = $self->{dump};
	delete $self->{dump};
	delete $self->{indent};
	return $dump;
}

sub dump_tree_go {
	my ($self, $node) = @_;

	$self->{dump} .= @{$self->{indent}}[-1].$node->dump()."\n";

	push @{$self->{indent}}, @{$self->{indent}}[-1].' - ';

	for my $token(@{$node->{tokens}}){

		$self->dump_tree_go($token);
	}

	pop @{$self->{indent}};
}

sub make_groups {
	my ($self) = @_;

	my $tokens = $self->{tokens};
	$self->{tokens} = [];

	my $parent = $self;

	for my $token(@{$tokens}){

		if ($token->match('Symbol', '(')){

			my $group = XML::Parser::Lite::Tree::XPath::Token->new();
			$group->{type} = 'Group()';
			$group->{tokens} = [];
			$group->{parent} = $parent;

			push @{$parent->{tokens}}, $group;
			$parent = $group;

		}elsif ($token->match('Symbol', '[')){

			my $group = XML::Parser::Lite::Tree::XPath::Token->new();
			$group->{type} = 'Predicate';
			$group->{tokens} = [];
			$group->{parent} = $parent;

			push @{$parent->{tokens}}, $group;
			$parent = $group;

		}elsif ($token->match('Symbol', ')')){

			if ($parent->{type} ne 'Group()'){
				$self->{error} = "Found unexpected closing bracket ')'.";
				return 0;
			}

			$parent = $parent->{parent};

		}elsif ($token->match('Symbol', ']')){

			if ($parent->{type} ne 'Predicate'){
				$self->{error} = "Found unexpected closing bracket ']'.";
				return 0;
			}

			$parent = $parent->{parent};

		}else{
			$token->{parent} = $parent;
			push @{$parent->{tokens}}, $token;
		}
	}

	return 1;
}

sub recurse_before {
	my ($self, $root, $method) = @_;

	return 0 unless $self->$method($root);

	for my $token(@{$root->{tokens}}){

		return 0 unless $self->recurse_before($token, $method);
	}

	return 1;
}

sub recurse_after {
	my ($self, $root, $method) = @_;

	for my $token(@{$root->{tokens}}){

		return 0 unless $self->recurse_after($token, $method);
	}

	return 0 unless $self->$method($root);

	return 1;
}

sub binops {
	my ($self, $ops, $production) = @_;
	$self->{binops} = $ops;
	$self->{binop_production} = $production;

	my $ret = $self->recurse_after($self, 'do_binops');

	delete $self->{binops};
	delete $self->{binop_production};

	return $ret;
}

sub claim_groups {
	my ($self, $root) = @_;

	my $tokens = $root->{tokens};
	$root->{tokens} = [];

	while(my $token = shift @{$tokens}){


		#
		# makes claims
		#

		if ($token->match('NodeType')){

			# node type's claim the follow group node

			my $next = shift @{$tokens};

			if (!$next->match('Group()')){
				$self->{error} = "Found NodeType '$token->{content}' without a following '(' (found a following '$next->{type}').";
				return 0;
			}

			my $childs = scalar(@{$next->{tokens}});

			if ($token->{content} eq 'processing-instruction'){

				if ($childs == 0){

					#ok

				}elsif ($childs == 1){

					if ($next->{tokens}->[0]->{type} eq 'Literal'){

						$token->{argument} = $next->{tokens}->[0]->{content};

					}else{
						$self->{error} = "processing-instruction node has a non-Literal child node (of type '$next->{tokens}->[0]->{type}').";
						return 0;
					}
				}else{
					$self->{error} = "processing-instruction node has more than one child node.";
					return 0;
				}

			}else{
				if ($childs > 0){
					$self->{error} = "NodeType $token->{content} node has unexpected children.";
					return 0;
				}
			}

			$token->{type} = 'NodeTypeTest';
			push @{$root->{tokens}}, $token;

		}elsif ($token->match('FunctionName')){

			# FunctionNames's claim the follow group node - it should be an arglist

			my $next = shift @{$tokens};

			if (!$next->match('Group()')){
				$self->{error} = "Found FunctionName '$token->{content}' without a following '(' (found a following '$next->{type}').";
				return 0;
			}

			#
			# recurse manually - this node will never be scanned by this loop
			#

			return 0 unless $self->claim_groups($next);


			#
			# organise it into an arg list
			#

			return 0 unless $self->make_arg_list($token, $next);
			


			push @{$root->{tokens}}, $token;


		}elsif ($token->match('Group()')){

			$token->{type} = 'PrimaryExpr';

			push @{$root->{tokens}}, $token;

		}else{

			push @{$root->{tokens}}, $token;
		}

	}

	return 1;
}

sub make_arg_list {
	my ($self, $root, $arg_group) = @_;

	$root->{type} = 'FunctionCall';
	$root->{tokens} = [];

	# no need to construct an arg list if there aren't any args
	return 1 unless scalar @{$arg_group->{tokens}};

	my $arg = XML::Parser::Lite::Tree::XPath::Token->new();
	$arg->{type} = 'FunctionArg';
	$arg->{tokens} = [];

	while(my $token = shift @{$arg_group->{tokens}}){

		if ($token->match('Symbol', ',')){

			push @{$root->{tokens}}, $arg;

			$arg = XML::Parser::Lite::Tree::XPath::Token->new();
			$arg->{type} = 'FunctionArg';
			$arg->{tokens} = [];

		}else{

			$token->{parent} = $arg;
			push @{$arg->{tokens}}, $token;
		}
	}

	$arg->{parent} = $root;
	push @{$root->{tokens}}, $arg;
	

	return 1;
}

sub clean_axis_and_abbreviations {

	my ($self, $root) = @_;

	my $tokens = $root->{tokens};
	$root->{tokens} = [];

	while(my $token = shift @{$tokens}){

		if ($token->match('AxisName')){

			my $next = shift @{$tokens};

			unless ($next->match('Symbol', '::')){

				$self->{error} = "Found an AxisName '$token->{content}' without a following ::";
				return 0;
			}

			$token->{type} = 'AxisSpecifier';

			push @{$root->{tokens}}, $token;


		}elsif ($token->match('Symbol', '@')){

			$token->{type} = 'AxisSpecifier';
			$token->{content} = 'attribute';

			push @{$root->{tokens}}, $token;


		}elsif ($token->match('Operator', '//')){

			# // == /descendant-or-self::node()/

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'Operator';
			$token->{content} = '/';
			push @{$root->{tokens}}, $token;

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'AxisSpecifier';
			$token->{content} = 'descendant-or-self';
			push @{$root->{tokens}}, $token;

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'NodeTypeTest';
			$token->{content} = 'node';
			push @{$root->{tokens}}, $token;

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'Operator';
			$token->{content} = '/';
			push @{$root->{tokens}}, $token;


		}elsif ($token->match('Symbol', '.')){

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'AxisSpecifier';
			$token->{content} = 'self';
			push @{$root->{tokens}}, $token;

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'NodeTypeTest';
			$token->{content} = 'node';
			push @{$root->{tokens}}, $token;


		}elsif ($token->match('Symbol', '..')){

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'AxisSpecifier';
			$token->{content} = 'parent';
			push @{$root->{tokens}}, $token;

			$token = XML::Parser::Lite::Tree::XPath::Token->new();
			$token->{type} = 'NodeTypeTest';
			$token->{content} = 'node';
			push @{$root->{tokens}}, $token;


		}else{

			push @{$root->{tokens}}, $token;
		}
	}

	return 1;
}

sub build_steps {
	my ($self, $root) = @_;

	my $tokens = $root->{tokens};
	$root->{tokens} = [];

	while(my $token = shift @{$tokens}){

		if ($token->match('AxisSpecifier')){

			my $next = shift @{$tokens};

			unless (defined $next){

				$self->{error} = "AxisSpecifier found without following NodeTest.";
				return 0;
			}

			unless ($next->match('NodeTypeTest') || $next->match('NameTest')){

				$self->{error} = "AxisSpecifier found without following NodeTest (NodeTypeTest | NameTest) (found $next->{type} instead).";
				return 0;
			}

			my $step = XML::Parser::Lite::Tree::XPath::Token->new();
			$step->{type} = 'Step';
			$step->{axis} = $token->{content};
			$step->{tokens} = [];

			push @{$step->{tokens}}, $next;


			while(my $token = shift @{$tokens}){

				if ($token->match('Predicate')){

					push @{$step->{tokens}}, $token;
				}else{
					unshift @{$tokens}, $token;
					last;
				}
			}

			push @{$root->{tokens}}, $step;


		}elsif ($token->match('NodeTypeTest') || $token->match('NameTest')){

			my $step = XML::Parser::Lite::Tree::XPath::Token->new();
			$step->{type} = 'Step';
			$step->{tokens} = [];

			push @{$step->{tokens}}, $token;


			while(my $token = shift @{$tokens}){

				if ($token->match('Predicate')){

					push @{$step->{tokens}}, $token;
				}else{
					unshift @{$tokens}, $token;
					last;
				}
			}

			push @{$root->{tokens}}, $step;


		}elsif ($token->match('Predicate')){

			$self->{error} = "Predicate found without preceeding NodeTest.";
			return 0;

		}else{

			push @{$root->{tokens}}, $token;
		}
	}

	return 1;
}

sub build_paths {
	my ($self, $root) = @_;

	my $tokens = $root->{tokens};
	$root->{tokens} = [];

	while(my $token = shift @{$tokens}){

		if ($token->match('Step')){

			my $path = XML::Parser::Lite::Tree::XPath::Token->new();
			$path->{type} = 'LocationPath';
			$path->{absolute} = 0;
			$path->{tokens} = [$token];

			return 0 unless $self->slurp_path($path, $tokens);

			push @{$root->{tokens}}, $path;	

		}elsif ($token->match('Operator', '/')){

			unshift @{$tokens}, $token;

			my $path = XML::Parser::Lite::Tree::XPath::Token->new();
			$path->{type} = 'LocationPath';
			$path->{absolute} = 1;
			$path->{tokens} = [];

			return 0 unless $self->slurp_path($path, $tokens);

			unless (scalar @{$path->{tokens}}){
				$self->{error} = "Slash found at end of path.";
				return 0;
			}

			push @{$root->{tokens}}, $path;

		}else{

			push @{$root->{tokens}}, $token;
		}
	}

	return 1;
}

sub slurp_path {
	my ($self, $path, $tokens) = @_;

	while(1){

		my $t1 = shift @{$tokens};

		if (defined $t1){
			if ($t1->match('Operator', '/')){

				my $t2 = shift @{$tokens};

				if (defined $t2){
					if ($t2->match('Step')){

						push @{$path->{tokens}}, $t2;
					}else{
						$self->{error} = "Non Step token ($t2->{type}) found after slash.";
						return 0;
					}
				}else{
					$self->{error} = "Slash found at end of path.";
					return 0;
				}
			}else{
				unshift @{$tokens}, $t1;
				return 1;
			}
		}else{
			return 1;
		}
	}
}

sub do_binops {
	my ($self, $root) = @_;

	my $tokens = $root->{tokens};
	$root->{tokens} = [];

	while(my $token = shift @{$tokens}){


		for my $op(@{$self->{binops}}){
		
			if ($token->match('Operator', $op)){

				if (!scalar(@{$root->{tokens}})){
					$self->{error} = "Found a binop $token->{content} with no preceeding token";
					return 0;
				}

				if (!scalar(@{$tokens})){
					$self->{error} = "Found a binop $token->{content} with no following token";
					return 0;
				}

				my $prev = pop @{$root->{tokens}};
				my $next = shift @{$tokens};

				push @{$token->{tokens}}, $prev;
				push @{$token->{tokens}}, $next;
				$token->{type} = $self->{binop_production};

				last;
			}
		}

		push @{$root->{tokens}}, $token;
	}

	return 1;	
}

sub add_links {
	my ($self, $root) = @_;

	my $prev = undef;

	for my $token(@{$root->{tokens}}){

		$token->{prev} = $prev;
		$prev->{next} = $token if defined $prev;

		$prev = $token;
	}
}

sub del_links {
	my ($self, $root) = @_;

	for my $token(@{$root->{tokens}}){

		delete $token->{parent};
		delete $token->{prev};
		delete $token->{next};
	}
}

sub unary_minus {
	my ($self, $root) = @_;

	$self->add_links($root);

	my $tokens = $root->{tokens};
	$root->{tokens} = [];

	while(my $token = shift @{$tokens}){

		if ($token->match('Operator', '-')){

			if (defined($token->{next}) && defined($token->{prev}) && $token->{prev}->is_expression){

				# not unary
			}else{
				# unary minus

				$token->{type} = 'UnaryExpr';
				push @{$token->{tokens}}, shift @{$tokens};
			}
		}

		push @{$root->{tokens}}, $token;
	}

	return 1;
}

1;

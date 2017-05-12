package XML::Parser::Lite::Tree::XPath::Tokener;

use XML::Parser::Lite::Tree::XPath::Token;

sub new {
	my $class = shift;
 	my $self = bless {}, $class;

	return $self;
}

sub parse {
	my ($self, $input) = @_;

	$self->{tokens} = [];
	$self->{input} = $input;
	$self->{error} = 0;
	$self->{rx} = XML::Parser::Lite::Tree::XPath::Tokener::Rx::fetch();

	$self->trim();

	while($self->{input}){
		$self->step();
		last if $self->{error};
	}

	$self->{rx} = 0;

	warn $self->{error} if $self->{error};

	$self->special_rules();

	warn $self->{error} if $self->{error};

	return 1;
}

sub step {
	my ($self) = @_;

	$self->trim();


	#
	# Symbols
	#

	if ($self->{input} =~ m!^(\(|\)|\[|\]|\.\.|\.|\@|,|::)!){

		$self->push_token('Symbol', $1);
		$self->consume(length $1);
		return;
	}

	#
	# NameTest
	#

	if ($self->{input} =~ m!^(\*)!){

		$self->push_token('Star', '*');
		$self->consume(1);
		return;
	}

	if ($self->{input} =~ m!^($self->{rx}->{NCName})\:\*!){

		$self->push_token('NCName', $1);
		$self->push_token('NameTestPostfix', ':*');

		$self->consume(2 + length $1);
		return;
	}

	# QName test

	if ($self->{input} =~ m!^((($self->{rx}->{NCName})\\x3a)?($self->{rx}->{NCName}))!){

		$self->push_token('NCName', $3) if defined $3;
		$self->push_token('QNameSep', ':') if defined $3;
		$self->push_token('NCName', $4);
		$self->consume(length $1);
		return;
	}


	#
	# NodeType
	#

	if ($self->{input} =~ m!^(comment|text|processing-instruction|node)!){

		$self->push_token('NodeType', $1);
		$self->consume(length $1);
		return;
	}

	#
	# Operator
	#

	if ($self->{input} =~ m!^(and|or|mod|div|//|/|\||\+|-|=|\!=|<=|<|>=|>)!){

		$self->push_token('Operator', $1);
		$self->consume(length $1);
		return;
	}

	#
	# FunctionName (no need to test - it's a QName - it'll be found later on via special rules)
	#

	#
	# AxisName (no test - it's a NCName)
	#

	#
	# Literal
	#

	if ($self->{input} =~ m!^(('[^']*')|("[^"]*"))!){

		my $inner = $1;
		$inner =~ m!^.(.*).$!;

		$self->push_token('Literal', $1);
		$self->consume(2 + length $1);
		return;
	}

	#
	# Number
	#

	if ($self->{input} =~ m!^($self->{rx}->{Number})!){

		$self->push_token('Number', $1);
		$self->consume(length $1);
		return;
	}

	#
	# VariableReference
	#

	if ($self->{input} =~ m!^\$($self->{rx}->{QName})!){

		$self->push_token('VariableReference', $1);
		$self->consume(1 + length $1);
		return;
	}



	$self->{error} = "couldn't toke at >>>$self->{input}<<<";
}

sub push_token {
	my ($self, $type, $content) = @_;

	my $token = XML::Parser::Lite::Tree::XPath::Token->new();
	$token->{type} = $type;
	$token->{content} = $content if defined $content;

	push @{$self->{tokens}}, $token;
}

sub consume {
	my ($self, $count) = @_;
	$self->{input} = substr $self->{input}, $count;
}

sub trim {
	my ($self) = @_;
	$self->{input} =~ s!^[\x20\x09\x0D\x0A]+!!;
}

sub special_rules {
	my ($self) = @_;

	#
	# set up node chain
	#

	my $prev = undef;
	for my $token(@{$self->{tokens}}){

		$token->{prev} = $prev;
		$token->{next} = undef;
		$prev->{next} = $token if defined $prev;
		$prev = $token;
	}


	#
	# special rules
	#

	for my $token(@{$self->{tokens}}){

		#
		# rule 1
		#
		# If there is a preceding token and the preceding token is not one of @, ::, (, [, , or an Operator, 
		# then a * must be recognized as a MultiplyOperator and an NCName must be recognized as an OperatorName.
		#

		if (defined $token->{prev}){
			my $p = $token->{prev};

			unless ($p->match('Symbol', '@')
				|| $p->match('Symbol', '::')
				|| $p->match('Symbol', '(')
				|| $p->match('Symbol', '[')
				|| $p->match('Symbol', ',')
				|| $p->match('Operator')){

				if ($token->{type} eq 'Star'){

					$token->{type} = 'Operator';
				}else{
					if ($token->{type} eq 'NCName'){

						if ($self->is_OperatorName($token->{content})){

							$token->{type} = 'Operator';

						}else{
							$self->{error} = "Found NCName '$token->{content}' when an OperatorName was required";
							return;
						}
					}
				}
			}
		}

		#
		# rule 2
		#
		# If the character following an NCName (possibly after intervening ExprWhitespace) is (, 
		# then the token must be recognized as a NodeType or a FunctionName.
		#

		if ($token->match('NCName')){

			if (defined $token->{next}){

				if ($token->{next}->match('Symbol', '(')){

					if ($self->is_NodeType($token->{content})){

						$token->{type} = 'NodeType';
					}else{
						$token->{type} = 'FunctionName';
					}
				}
			}
		}

		#
		# rule 3
		#
		# If the two characters following an NCName (possibly after intervening ExprWhitespace) are ::, 
		# then the token must be recognized as an AxisName.
		#

		if ($token->match('NCName')){

			if (defined $token->{next}){

				if ($token->{next}->match('Symbol', '::')){

					if ($self->is_AxisName($token->{content})){

						$token->{type} = 'AxisName';
					}else{
						$self->{error} = "Found NCName '$token->{content}' when an AxisName was required";
						return;
					}
				}
			}
		}
	}

	for my $token(@{$self->{tokens}}){

		#
		# rule 4
		#
		# Otherwise, the token must not be recognized as a MultiplyOperator, an OperatorName, 
		# a NodeType, a FunctionName, or an AxisName.
		#
		# (this means we need to clean up Star and NCName tokens)
		#

		if ($token->match('Star')){
			$token->{type} = 'NameTest';
		}

		if ($token->match('NCName')){
			if (defined $token->{next} && $token->{next}->match('NameTestPostfix')){

				$token->{type} = 'NameTestBase';

			}else{

				if (defined $token->{next} && $token->{next}->match('QNameSep')
					&& defined $token->{next}->{next} && $token->{next}->{next}->match('NCName')){

					$token->{type} = 'QNamePre';
					$token->{next}->{next}->{type} = 'QNamePost';

				}else{

					$token->{type} = 'NameTest';
				}
			}
		}
	}

	#
	# remove the node chain
	# (it's a pain for debugging)
	#

	for my $token(@{$self->{tokens}}){

		delete $token->{prev};
		delete $token->{next};
	}


	#
	# squish temp token sequences together
	#

	my $old_tokens = $self->{tokens};
	$self->{tokens} = [];

	while(my $token = shift @{$old_tokens}){

		if ($token->match('NameTestBase')){

			$token->{type} = 'NameTest';
			$token->{content} .= ':*';

			shift @{$old_tokens};
		}

		if ($token->match('QNamePre')){

			shift @{$old_tokens};
			my $post = shift @{$old_tokens};

			$token->{type} = 'NameTest';
			$token->{content} .= ':'.$post->{content};
		}

		push @{$self->{tokens}}, $token;
	}

	#
	# TODO - need to check we don't have any temporaory tokens still in the list
	#        i.e. invalid sub-sequences. not sure what ones we could end up with
	#
}

sub is_OperatorName {
	my ($self, $content) = @_;

	return 1 if $content =~ m!^(and|or|mod|div)$!;
	return 0;
}

sub is_NodeType {
	my ($self, $content) = @_;

	return 1 if $content =~ m!^(comment|text|processing-instruction|node)$!;
	return 0;
}

sub is_AxisName {
	my ($self, $content) = @_;

	return 1 if $content =~ m!^(ancestor|ancestor-or-self|attribute|child|descendant|descendant-or-self|
				following|following-sibling|namespace|parent|preceding|preceding-sibling|self)$!x;
	return 0;
}


package XML::Parser::Lite::Tree::XPath::Tokener::Token;

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

sub dump {
	my ($self) = @_;

	my $ret = $self->{type};
	$ret .= ':absolute' if $self->{absolute};
	$ret .= ':'.$self->{content} if defined $self->{content};
	$ret .= $self->{axis} if defined $self->{axis};

	return $ret;
}

package XML::Parser::Lite::Tree::XPath::Tokener::Rx;

sub fetch {

my %rx;

$rx{CombiningChar}	= '\\x{300}-\\x{345}\\x{360}-\\x{361}\\x{483}-\\x{486}\\x{591}-\\x{5a1}\\x{5a3}-\\x{5b9}\\x{5bb}'
			.'-\\x{5bd}\\x{5bf}\\x{5c1}-\\x{5c2}\\x{5c4}\\x{64b}-\\x{652}\\x{670}\\x{6d6}-\\x{6dc}\\x{6dd}-\\'
			.'x{6df}\\x{6e0}-\\x{6e4}\\x{6e7}-\\x{6e8}\\x{6ea}-\\x{6ed}\\x{901}-\\x{903}\\x{93c}\\x{93e}-\\x'
			.'{94c}\\x{94d}\\x{951}-\\x{954}\\x{962}-\\x{963}\\x{981}-\\x{983}\\x{9bc}\\x{9be}\\x{9bf}\\x{9c'
			.'0}-\\x{9c4}\\x{9c7}-\\x{9c8}\\x{9cb}-\\x{9cd}\\x{9d7}\\x{9e2}-\\x{9e3}\\x{a02}\\x{a3c}\\x{a3e}'
			.'\\x{a3f}\\x{a40}-\\x{a42}\\x{a47}-\\x{a48}\\x{a4b}-\\x{a4d}\\x{a70}-\\x{a71}\\x{a81}-\\x{a83}\\'
			.'x{abc}\\x{abe}-\\x{ac5}\\x{ac7}-\\x{ac9}\\x{acb}-\\x{acd}\\x{b01}-\\x{b03}\\x{b3c}\\x{b3e}-\\x'
			.'{b43}\\x{b47}-\\x{b48}\\x{b4b}-\\x{b4d}\\x{b56}-\\x{b57}\\x{b82}-\\x{b83}\\x{bbe}-\\x{bc2}\\x{'
			.'bc6}-\\x{bc8}\\x{bca}-\\x{bcd}\\x{bd7}\\x{c01}-\\x{c03}\\x{c3e}-\\x{c44}\\x{c46}-\\x{c48}\\x{c'
			.'4a}-\\x{c4d}\\x{c55}-\\x{c56}\\x{c82}-\\x{c83}\\x{cbe}-\\x{cc4}\\x{cc6}-\\x{cc8}\\x{cca}-\\x{c'
			.'cd}\\x{cd5}-\\x{cd6}\\x{d02}-\\x{d03}\\x{d3e}-\\x{d43}\\x{d46}-\\x{d48}\\x{d4a}-\\x{d4d}\\x{d5'
			.'7}\\x{e31}\\x{e34}-\\x{e3a}\\x{e47}-\\x{e4e}\\x{eb1}\\x{eb4}-\\x{eb9}\\x{ebb}-\\x{ebc}\\x{ec8}'
			.'-\\x{ecd}\\x{f18}-\\x{f19}\\x{f35}\\x{f37}\\x{f39}\\x{f3e}\\x{f3f}\\x{f71}-\\x{f84}\\x{f86}-\\'
			.'x{f8b}\\x{f90}-\\x{f95}\\x{f97}\\x{f99}-\\x{fad}\\x{fb1}-\\x{fb7}\\x{fb9}\\x{20d0}-\\x{20dc}\\'
			.'x{20e1}\\x{302a}-\\x{302f}\\x{3099}\\x{309a}';

$rx{Extender}		= '\\xb7\\x{2d0}\\x{2d1}\\x{387}\\x{640}\\x{e46}\\x{ec6}\\x{3005}\\x{3031}-\\x{3035}\\x{309d}-\\'
			.'x{309e}\\x{30fc}-\\x{30fe}';

$rx{Digit}		= '\\x30-\\x39\\x{660}-\\x{669}\\x{6f0}-\\x{6f9}\\x{966}-\\x{96f}\\x{9e6}-\\x{9ef}\\x{a66}-\\x{a'
			.'6f}\\x{ae6}-\\x{aef}\\x{b66}-\\x{b6f}\\x{be7}-\\x{bef}\\x{c66}-\\x{c6f}\\x{ce6}-\\x{cef}\\x{d6'
			.'6}-\\x{d6f}\\x{e50}-\\x{e59}\\x{ed0}-\\x{ed9}\\x{f20}-\\x{f29}';

$rx{BaseChar}		= '\\x41-\\x5a\\x61-\\x7a\\xc0-\\xd6\\xd8-\\xf6\\xf8-\\xff\\x{100}-\\x{131}\\x{134}-\\x{13e}\\x{'
			.'141}-\\x{148}\\x{14a}-\\x{17e}\\x{180}-\\x{1c3}\\x{1cd}-\\x{1f0}\\x{1f4}-\\x{1f5}\\x{1fa}-\\x{'
			.'217}\\x{250}-\\x{2a8}\\x{2bb}-\\x{2c1}\\x{386}\\x{388}-\\x{38a}\\x{38c}\\x{38e}-\\x{3a1}\\x{3a'
			.'3}-\\x{3ce}\\x{3d0}-\\x{3d6}\\x{3da}\\x{3dc}\\x{3de}\\x{3e0}\\x{3e2}-\\x{3f3}\\x{401}-\\x{40c}'
			.'\\x{40e}-\\x{44f}\\x{451}-\\x{45c}\\x{45e}-\\x{481}\\x{490}-\\x{4c4}\\x{4c7}-\\x{4c8}\\x{4cb}-'
			.'\\x{4cc}\\x{4d0}-\\x{4eb}\\x{4ee}-\\x{4f5}\\x{4f8}-\\x{4f9}\\x{531}-\\x{556}\\x{559}\\x{561}-\\'
			.'x{586}\\x{5d0}-\\x{5ea}\\x{5f0}-\\x{5f2}\\x{621}-\\x{63a}\\x{641}-\\x{64a}\\x{671}-\\x{6b7}\\x'
			.'{6ba}-\\x{6be}\\x{6c0}-\\x{6ce}\\x{6d0}-\\x{6d3}\\x{6d5}\\x{6e5}-\\x{6e6}\\x{905}-\\x{939}\\x{'
			.'93d}\\x{958}-\\x{961}\\x{985}-\\x{98c}\\x{98f}-\\x{990}\\x{993}-\\x{9a8}\\x{9aa}-\\x{9b0}\\x{9'
			.'b2}\\x{9b6}-\\x{9b9}\\x{9dc}-\\x{9dd}\\x{9df}-\\x{9e1}\\x{9f0}-\\x{9f1}\\x{a05}-\\x{a0a}\\x{a0'
			.'f}-\\x{a10}\\x{a13}-\\x{a28}\\x{a2a}-\\x{a30}\\x{a32}-\\x{a33}\\x{a35}-\\x{a36}\\x{a38}-\\x{a3'
			.'9}\\x{a59}-\\x{a5c}\\x{a5e}\\x{a72}-\\x{a74}\\x{a85}-\\x{a8b}\\x{a8d}\\x{a8f}-\\x{a91}\\x{a93}'
			.'-\\x{aa8}\\x{aaa}-\\x{ab0}\\x{ab2}-\\x{ab3}\\x{ab5}-\\x{ab9}\\x{abd}\\x{ae0}\\x{b05}-\\x{b0c}\\'
			.'x{b0f}-\\x{b10}\\x{b13}-\\x{b28}\\x{b2a}-\\x{b30}\\x{b32}-\\x{b33}\\x{b36}-\\x{b39}\\x{b3d}\\x'
			.'{b5c}-\\x{b5d}\\x{b5f}-\\x{b61}\\x{b85}-\\x{b8a}\\x{b8e}-\\x{b90}\\x{b92}-\\x{b95}\\x{b99}-\\x'
			.'{b9a}\\x{b9c}\\x{b9e}-\\x{b9f}\\x{ba3}-\\x{ba4}\\x{ba8}-\\x{baa}\\x{bae}-\\x{bb5}\\x{bb7}-\\x{'
			.'bb9}\\x{c05}-\\x{c0c}\\x{c0e}-\\x{c10}\\x{c12}-\\x{c28}\\x{c2a}-\\x{c33}\\x{c35}-\\x{c39}\\x{c'
			.'60}-\\x{c61}\\x{c85}-\\x{c8c}\\x{c8e}-\\x{c90}\\x{c92}-\\x{ca8}\\x{caa}-\\x{cb3}\\x{cb5}-\\x{c'
			.'b9}\\x{cde}\\x{ce0}-\\x{ce1}\\x{d05}-\\x{d0c}\\x{d0e}-\\x{d10}\\x{d12}-\\x{d28}\\x{d2a}-\\x{d3'
			.'9}\\x{d60}-\\x{d61}\\x{e01}-\\x{e2e}\\x{e30}\\x{e32}-\\x{e33}\\x{e40}-\\x{e45}\\x{e81}-\\x{e82'
			.'}\\x{e84}\\x{e87}-\\x{e88}\\x{e8a}\\x{e8d}\\x{e94}-\\x{e97}\\x{e99}-\\x{e9f}\\x{ea1}-\\x{ea3}\\'
			.'x{ea5}\\x{ea7}\\x{eaa}-\\x{eab}\\x{ead}-\\x{eae}\\x{eb0}\\x{eb2}-\\x{eb3}\\x{ebd}\\x{ec0}-\\x{'
			.'ec4}\\x{f40}-\\x{f47}\\x{f49}-\\x{f69}\\x{10a0}-\\x{10c5}\\x{10d0}-\\x{10f6}\\x{1100}\\x{1102}'
			.'-\\x{1103}\\x{1105}-\\x{1107}\\x{1109}\\x{110b}-\\x{110c}\\x{110e}-\\x{1112}\\x{113c}\\x{113e}'
			.'\\x{1140}\\x{114c}\\x{114e}\\x{1150}\\x{1154}-\\x{1155}\\x{1159}\\x{115f}-\\x{1161}\\x{1163}\\'
			.'x{1165}\\x{1167}\\x{1169}\\x{116d}-\\x{116e}\\x{1172}-\\x{1173}\\x{1175}\\x{119e}\\x{11a8}\\x{'
			.'11ab}\\x{11ae}-\\x{11af}\\x{11b7}-\\x{11b8}\\x{11ba}\\x{11bc}-\\x{11c2}\\x{11eb}\\x{11f0}\\x{1'
			.'1f9}\\x{1e00}-\\x{1e9b}\\x{1ea0}-\\x{1ef9}\\x{1f00}-\\x{1f15}\\x{1f18}-\\x{1f1d}\\x{1f20}-\\x{'
			.'1f45}\\x{1f48}-\\x{1f4d}\\x{1f50}-\\x{1f57}\\x{1f59}\\x{1f5b}\\x{1f5d}\\x{1f5f}-\\x{1f7d}\\x{1'
			.'f80}-\\x{1fb4}\\x{1fb6}-\\x{1fbc}\\x{1fbe}\\x{1fc2}-\\x{1fc4}\\x{1fc6}-\\x{1fcc}\\x{1fd0}-\\x{'
			.'1fd3}\\x{1fd6}-\\x{1fdb}\\x{1fe0}-\\x{1fec}\\x{1ff2}-\\x{1ff4}\\x{1ff6}-\\x{1ffc}\\x{2126}\\x{'
			.'212a}-\\x{212b}\\x{212e}\\x{2180}-\\x{2182}\\x{3041}-\\x{3094}\\x{30a1}-\\x{30fa}\\x{3105}-\\x'
			.'{312c}\\x{ac00}-\\x{d7a3}';

$rx{IdeoGraphic}	= '\\x{4e00}-\\x{9fa5}\\x{3007}\\x{3021}-\\x{3029}';

$rx{Letter}		= $rx{BaseChar} . $rx{IdeoGraphic};

$rx{NCNameChar}		= $rx{Letter} . $rx{Digit} . '\\x2e\\x2d\\x5f' . $rx{CombiningChar} . $rx{Extender};

$rx{NCName}		= '['.$rx{Letter}.'\\x5f]['.$rx{NCNameChar}.']*';

$rx{QName}		=  '('.$rx{NCName}.'\\x3a)?'.$rx{NCName};

$rx{Digits}		= '[0-9]+';
$rx{Number}		= '([0-9]+(\\.([0-9]+)?)?)|(\\.[0-9]+)';

	return \%rx;
}

1;

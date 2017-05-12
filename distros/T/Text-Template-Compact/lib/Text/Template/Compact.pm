#!perl --
package Text::Template::Compact;
use utf8;
use strict;
use warnings;
use Encode;
use Carp;
our $VERSION = "0.1.11";

sub getDataType($){
	# return empty string if not reference type.
	return '' if not ref $_[0];
	# use scalar to avoid bless.
	$_[0]=~/(\w+)\(/; 
	return $1;
}

# decode "quoted" string to plain.
sub decodeQuote{
	return if not @_ or not defined $_[0];
	return $_[0] if not $_[0] =~ /^"/;
	my $r = substr($_[0],1,length($_[0])-2);
	$r =~ s/""/"/g;
	return $r;
}

# defined or ...
sub dor{
	for(@_){ defined($_) and return $_;}
	return;
}

# filter for variable expansion
our %filter_map =(
	raw => sub{
		return $_[0];
	},
	html => sub{
		my $a = $_[0];
		$a =~ s/&/&amp;/g;
		$a =~ s/</&lt;/g;
		$a =~ s/>/&gt;/g;
		$a =~ s/"/&quot;/g;
		$a =~ s/'/&#39;/g;
		$a =~ s/\n/<br>\n/g;
		return $a;
	},
	nobr => sub{
		my $a = $_[0];
		$a =~ s/&/&amp;/g;
		$a =~ s/</&lt;/g;
		$a =~ s/>/&gt;/g;
		$a =~ s/"/&quot;/g;
		$a =~ s/'/&#39;/g;
		return $a;
	},
	uri => sub{
		my $a = Encode::encode('utf8',$_[0]);
		$a =~ s/([^a-zA-Z0-9_.!~*'()-])/'%' . unpack('H2', $1)/eg;
		return $a;
	},
);

{
	package Text::Template::Compact::ExprParser;
	use Carp;
	our @ExprOperator;
	our %ExprOperator;
	our $token_re;
	our $dataset;
	our $list_op_prio;
	{
		my $prio=0;
		for(
			# 優先順序が同じ場合の結合順序： L=左結合((a+b)+c) R=右結合(a=(b=c)) _=非結合
			# 演算子の見た目:
			#        b (braket) (a) のような外見,
			#        l (left)   左側の単項演算子。 +num
			#        a (array)  a[b] のような外見,
			#        r (right)  右側の単項演算子。 num++
			#        m (middle) 二項演算子 a ** b 
			#        t (tri)    三項演算子  a?b:c
			#        k (keyword) 二項演算子  a.keyword 演算子の右側に式ではなくキーワードが入る
			#        c (const)  定数
			#        K (const)  キーワード
			# 優先順序の区切り: [] 
			['Lb','(',1,sub{ return $_[0];},')'],
			['La','(',1,sub{ 
				# find list operator
				my $key = $dataset->getV($_[0]);
				my $op = findOp($key,qr/l/);
				$op or return $dataset->encode("[Error: $op() is not found]");
				return $op->{_eval}->($_[1]);
			},')'],
			[],
			['Lk','.',2,sub{ return $dataset->child($_[0],$_[1]      ) }     ],
			['La','[',2,sub{ return $dataset->child($_[0],$dataset->encode($dataset->getV($_[1]))) },']' ],
			[],
			['_l','++',1,sub{ no warnings; my $v= $dataset->getV($_[0]); $dataset->setV($_[0],++$v); return $dataset->encode(  $v);} ],
			['_l','--',1,sub{ no warnings; my $v= $dataset->getV($_[0]); $dataset->setV($_[0],--$v); return $dataset->encode(  $v);} ],
			['_r','++',1,sub{ no warnings; my $v= $dataset->getV($_[0]); $dataset->setV($_[0],++$v); return $dataset->encode(--$v);} ],
			['_r','--',1,sub{ no warnings; my $v= $dataset->getV($_[0]); $dataset->setV($_[0],--$v); return $dataset->encode(++$v);} ],
			[],
			['Rm','**',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0])**$dataset->getV($_[1])); } ],
			[],
		    ['Rl','!',1,sub{ no warnings; return $dataset->encode(!$dataset->getV($_[0]))} ],
		    ['Rl','~',1,sub{ no warnings; return $dataset->encode(~(0+$dataset->getV($_[0])))} ],
		    ['Rl','+',1,sub{ no warnings; return $dataset->encode(+$dataset->getV($_[0]))} ],
		    ['Rl','-',1,sub{ no warnings; return $dataset->encode(-$dataset->getV($_[0]))} ],
			[],
			['Lm','*',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) * $dataset->getV($_[1])) }],
			['Lm','/',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) / $dataset->getV($_[1])) }],
			['Lm','%',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) % $dataset->getV($_[1])) }],
			['Lm','repeat',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) x $dataset->getV($_[1])) }],
			[],
			['Lm','+',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) + $dataset->getV($_[1])) } ],
			['Lm','-',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) - $dataset->getV($_[1])) } ],
			['Lm','cat',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) . $dataset->getV($_[1])) } ],
			[],
			['Lm','<<',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) << $dataset->getV($_[1])) } ],
			['Lm','>>',2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) >> $dataset->getV($_[1])) } ],
			[],
			['_l','defined' ,1,sub{ return $dataset->encode( defined($dataset->getV($_[0]))       ?1:0); }],
			['_l','bool'    ,1,sub{ return $dataset->encode($dataset->getV($_[0])                 ?1:0); }],
			['_l','nz'      ,1,sub{ no warnings; return $dataset->encode($dataset->getV($_[0])!=0 ?1:0); }],
			['_l','int'     ,1,sub{ no warnings; return $dataset->encode(int $dataset->getV($_[0]) ); }],
			['_l','length'  ,1,sub{
				my $v =$dataset->getV($_[0]); 
				defined($v) or return $dataset->encode(undef);
				ref($v)     or return $dataset->encode(length $v);
				my $type = Text::Template::Compact::getDataType($v);
				$type =~ /ARRAY/ and return $dataset->encode(scalar @$v);
				$type =~ /HASH/  and return $dataset->encode(scalar keys %$v);
				return $dataset->encode(length $v);
			}],
			['l','pop',1,sub{
				my $ra = $dataset->getV($_[0]);
				if(Text::Template::Compact::getDataType($ra) =~ /ARRAY/ ){
					return $dataset->encode( pop @$ra );
				}
				return $dataset->encode( undef );
			}],
			['l','shift',1,sub{
				my $ra = $dataset->getV($_[0]);
				if(Text::Template::Compact::getDataType($ra) =~ /ARRAY/ ){
					return $dataset->encode( shift @$ra );
				}
				return $dataset->encode( undef );
			}],
			[],
			['_m','<'   ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) <   $dataset->getV($_[1])) }],
			['_m','>'   ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) >   $dataset->getV($_[1])) }],
			['_m','<='  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) <=  $dataset->getV($_[1])) }],
			['_m','>='  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) >=  $dataset->getV($_[1])) }],
			['_m','lt'  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) lt  $dataset->getV($_[1])) }],
			['_m','gt'  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) gt  $dataset->getV($_[1])) }],
			['_m','le'  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) le  $dataset->getV($_[1])) }],
			['_m','ge'  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) ge  $dataset->getV($_[1])) }],
			[],
			['_m','=='  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) ==  $dataset->getV($_[1])) }],
			['_m','!='  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) !=  $dataset->getV($_[1])) }],
			['_m','<=>' ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) <=> $dataset->getV($_[1])) }],
			['_m','eq'  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) eq  $dataset->getV($_[1])) }],
			['_m','ne'  ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) ne  $dataset->getV($_[1])) }],
			['_m','cmp' ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0]) cmp $dataset->getV($_[1])) }],
			[],
			['Lm','&' ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0])+0 &  0+$dataset->getV($_[1])) }],
			[],
			['Lm','|' ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0])+0 |  0+$dataset->getV($_[1])) }],
			['Lm','^' ,2,sub{ no warnings; return $dataset->encode($dataset->getV($_[0])+0 ^  0+$dataset->getV($_[1])) }],
			[],
			['Lm','&&',2,sub{ return         $dataset->getV($_[0])  ?$_[1]:$_[0]; }],
			[],
			['Lm','||',2,sub{ return         $dataset->getV($_[0])  ?$_[0]:$_[1]; }],
			['Lm','//',2,sub{ return defined($dataset->getV($_[0])) ?$_[0]:$_[1]; }],
			[],
			['Rt','?' ,3,sub{ return $dataset->getV($_[0])? $_[1]:$_[2]; },':'],
			[],
			[ 'Rm',  '=',2,sub{              $dataset->setV($_[0],$dataset->getV($_[1])                           ); return $_[0]; }],
			[ 'Rm','**=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) **  $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm', '*=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) *   $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm', '/=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) /   $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm', '%=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) %   $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm', '+=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) +   $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm', '-=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) -   $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm','<<=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) <<  $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm','>>=',2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0]) >>  $dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm','&=' ,2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0])+0&0+$dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm','|=' ,2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0])+0|0+$dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm','^=' ,2,sub{ no warnings; $dataset->setV($_[0],$dataset->getV($_[0])+0^0+$dataset->getV($_[1]) ); return $_[0]; }],
			[ 'Rm','&&=',2,sub{         $dataset->getV($_[0]) and $dataset->setV($_[0],$dataset->getV($_[1])); return $_[0]; }],
			[ 'Rm','||=',2,sub{         $dataset->getV($_[0])  or $dataset->setV($_[0],$dataset->getV($_[1])); return $_[0]; }],
			[ 'Rm','//=',2,sub{ defined($dataset->getV($_[0])) or $dataset->setV($_[0],$dataset->getV($_[1])); return $_[0]; }],

			[],
			['Lm',',',2,sub{ return $dataset->makepathlist($_[0],$_[1]);}],
			[],
			['l','print',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				$dataset->print( @list);
				return $dataset->encode('');
			}],
			['l','join',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				@list or return $dataset->encode('');
				my $delm = shift @list;
				my $a = join $delm,@list;
				return $dataset->encode( $a );
			}],
			['l','scalar',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				return $dataset->encode( scalar @list );
			}],
			['l','push',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				if( @list and Text::Template::Compact::getDataType($list[0]) =~ /ARRAY/ ){
					my $ra = shift @list;
					push @$ra,@list;
				}
				return $dataset->encode( undef );
			}],
			['l','unshift',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				if(@list and Text::Template::Compact::getDataType($list[0]) =~ /ARRAY/ ){
					my $ra = shift @list;
					unshift @$ra,@list;
				}
				return $dataset->encode( undef );
			}],
			['l','call',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				local $_ = $dataset->{tmpl}{param};
				if(@list and Text::Template::Compact::getDataType($list[0]) =~ /CODE/ ){
					my $coderef = shift @list;
					my $rv = eval{  $coderef->(@list); };
					$@ and $rv = "[Error: $@]";
					return $dataset->encode( $rv );
				}elsif( @list >= 2 ){
					my $obj = shift @list;
					my $method = shift @list;
					my $rv = eval{  $obj->$method(@list); };
					$@ and $rv = "[Error: $@]";
					return $dataset->encode( $rv );
				}
				return $dataset->encode( undef );
			}],
			['l','makearray',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				return $dataset->encode( \@list );
			}],
			['l','makehash',1,sub{
				my @list;
				$dataset->getVlist(\@list,$_[0]);
				return $dataset->encode( {@list} );
			}],
			[],
			# not and or xor
			['Rl','not',1,sub{  return $dataset->encode(not $dataset->getV($_[0]));} ],
			[],
			['Lm','and',2,sub{  return $dataset->encode( $dataset->getV($_[0]) and  $dataset->getV($_[1]));  }],
			[],
			['Lm','or' ,2,sub{  return $dataset->encode( $dataset->getV($_[0]) or   $dataset->getV($_[1]));  }],
			['Lm','xor',2,sub{  return $dataset->encode( $dataset->getV($_[0]) xor  $dataset->getV($_[1]));  }],
		){
			if(not @$_){ ++$prio; next; }
			my $item = {
				prio     => $prio,
				assoc    => $_->[0],
				key1     => $_->[1],
				count    => $_->[2],
				_eval    => $_->[3],
				key2     => $_->[4],
			};
			( $item->{key1} eq 'print') and $list_op_prio=$prio;

			push @ExprOperator,$item;
	#		defined($ExprOperator{ $item->{key1} }) or $ExprOperator{ $item->{key1} }=[];
			push @{$ExprOperator{ $item->{key1} }},$item;
		}
		# make re 
		my %c;
		for( '#',',',';','-|','$','$$',map {$_->{key1},$_->{key2}} @ExprOperator){
			next if not defined or not length;
			next if /^\w+$/;
			my $text = $_;
			my $map = \%c;
			for(my $i=0;$i<length($text);++$i){
				my $c = substr($text,$i,1);
				$map->{$c} or $map->{$c}={};
				$map = $map->{$c};
			}
		}
		sub toRe{
			my($map)=@_;
			my @list;
			while(my($k,$v)=each %$map){
				my $sub = toRe($v);
				if($sub){
					push @list,quotemeta($k).$sub."?";
				}else{
					push @list,quotemeta($k);
				}
			}
			@list > 1 and return "(?:".join('|',@list).")";
			@list and return $list[0];
			return;
		}
		my $a = toRe(\%c);
		$token_re = qr/$a/;
	}

	sub findOp{
		my($token,$re)=@_;
		my $list = $ExprOperator{ $token } or return;
		for(@$list){ return $_ if $_->{assoc} =~ $re; }
		return;
	}

	{
		package Text::Template::Compact::ExprNode;
		sub new{
			my($class,$op,$text)=@_;
			if(not ref $op){
				# keyword?
				return $text if $op eq 'k';
				# root operator?
				$op = {
					assoc    => '_',
					key1     => 'root',
					_eval    => sub{ return $_[0]; },
					count    => 1,
					prio     => 999,
				};
			}
			return bless{ op=>$op, args=>[],},$class;
		};
		sub addArg{
			my $self=shift;
			push @{$self->{args}},@_;
		}
		sub toString{
			my($self,$mark)=@_;
			defined($mark) or $mark = '';
			if($self->{op}{key1} eq 'root'){
				return join(',',map{ ref($_)?$_->toString($mark):$_} @{$self->{args}});
			}
			return 
				$self->{op}{key1}
				.($self->{closed}?$self->{op}{key2}:'')
				.($mark eq $self ?"<=HERE=>":'')
				.'{'
				.join(',',map{ ref($_)?$_->toString($mark):$_ } @{$self->{args}} )
				.'}';
		}
		sub _eval{
			my($self)=@_;
			my @args = map{ ref($_) ? $_->_eval() : $Text::Template::Compact::ExprParser::dataset->token2path($_) } @{$self->{args}};
			my $r = ($self->{realop} || $self->{op})->{_eval}(@args);
			return $r;
		}
		sub eval{
			my($self,$dataset)=@_;
			local $Text::Template::Compact::ExprParser::dataset = $dataset;
			my $r = CORE::eval{ $self->_eval();};
			$@ and return ['i',"[Error: $@ in ".$self->toString." in Text::Template::Compact::ExprNode::eval]"];
			return $r;
		}
	}

	our $verbose = 0;

	sub peekToken{
		my $self = shift;
		@{$self->{token}} and return $self->{token}[0];
		return;
	}
	sub reduce{
		my($self,$where)=@_;

		return if $self->{allow_child};

		my $a = $self->peekToken;

		# スタックが空ならreduceできない
		return if @{$self->{stack}}==1;
		
		my $target = $self->{stack}[0];

		# 注目ノードの種別が () []だった
		if( $target->{op}{assoc} =~ /[ba]/ ){
			if( defined($a) and $a eq $target->{op}{key2}
			and @{$target->{args}} ==  $target->{op}->{count} 
			){
				$verbose>0 and warn "remove end of braket $target->{op}{key2}. reduce in $where\n";
				$target->{closed} = 1;
				shift @{$self->{token}};
				shift @{$self->{stack}};
				$self->{allow_child} = 0;
				return 1;
			}
		}else{
			if( @{$target->{args}} ==  $target->{op}->{count} ){
				$verbose>0 and warn "end of operator $target->{op}{key1} . reduce in $where\n";
				shift @{$self->{stack}};
				$self->{allow_child} = 0;
				return 1;
			}
			# ?:
			if( $target->{op}{assoc} =~ /t/ and $a and $a eq $target->{op}->{key2} ){
				$verbose>0 and warn "eating ':' operator . reduce in $where\n";
				shift @{$self->{token}};
				$self->{allow_child} = 1;
				return 1;
			}
		}
		return;
	}

	sub parse{
		my($list)=@_;

		my $self = bless{
			allow_child => 1,
			stack=>[new Text::Template::Compact::ExprNode('')],
			token=>$list,
		};

		my($op,$node);

		Loop: for(;;){
			my $target = $self->{stack}[0];
			my $token = $self->peekToken;
			$verbose>0 and warn "mode=$self->{allow_child} token:",($token||'')," stack:",join(',',map{$_->{op}{key1}} @{$self->{stack}}),"\n";


			# reduce if possible 
			if( not defined($token)
			or  not findOp( $token,qr/[armtk]/ )
			){
				next if $self->reduce('loop');
			}

			last if not defined($token);

			if( $self->{allow_child} ){
				my $op = findOp($token,qr/[bl]/);
				if($op){
					# listop(b) ??
					if( @{$self->{token}} >= 2
					and $op->{key1} =~/^\w/
					and $self->{token}[1] eq '('
					){
						$verbose>0 and warn "start of term $token(?) \n";
						shift @{$self->{token}};
						shift @{$self->{token}};
						$node =  new Text::Template::Compact::ExprNode(findOp('(',qr/a/));
						$target->addArg($node);
						unshift @{$self->{stack}},$node;
						$self->{allow_child} = 1;
						$node->{realop} = $op;
						next;
					}

					# unary left or '('
					$verbose>0 and warn "operator $token start\n";
					shift @{$self->{token}};
					$node =  new Text::Template::Compact::ExprNode($op);
					$target->addArg($node);
					unshift @{$self->{stack}},$node;
					$self->{allow_child} = 1;
					next;
				}
				
				# keyword or constant or $,$$
				if( $token =~/^["\w\d_\$]/ ){
					$verbose>0 and warn "constant or keyword $token\n";
					$target->addArg(shift @{$self->{token}});
					$self->{allow_child} = 0;

					# $keyword
					my $old_arg = $target->{args}[-1];
					$token = $self->peekToken;
					if( defined($token) and $token =~/^["\w\d_]/ and $old_arg =~/^\$/ ){
						$verbose>0 and warn "merge '$old_arg' and '$token'\n";
						$node =  new Text::Template::Compact::ExprNode(findOp('.',qr/[armtk]/));
						$target->{args}[-1] = $node;
						$node->addArg($old_arg,$token);
						shift @{$self->{token}};
					}
					next;
				}
			}else{

				$op = findOp($token,qr/[armtk]/);
				if($op){
					$node = new Text::Template::Compact::ExprNode($op);
					my $a;
					while(@{$self->{stack}}){
						my($left,$right) =($target->{op},$op);
						my($left_prio,$right_prio) =($left->{prio},$right->{prio});
						my($left_assoc,$right_assoc) =($left->{assoc},$right->{assoc});

						if( $left_assoc =~ /[ba]/ and not $target->{closed} ){
							# if inside of non closed braket, always right combination
							$a=1;
						}else{
							# List Operators (Leftward) has very high priority
							if( $right_prio == $list_op_prio ){
								$right_prio = 0;
							}
							# compare operator precedence 
							$a = $left_prio - $right_prio;
							if(!$a){
								# if same, check left or right associativity
								   if( $left_assoc =~/L/ ){ $a=-1;}
								elsif( $left_assoc =~/R/ ){ $a= 1;}
								else{
									die "repeating non-assoc operator. $left->{key1} $right->{key1}\n";
								}
							}
						}
						$verbose>0 and warn "lr=$a $left->{key1} $right->{key1}\n";

						if($a>0){ #right a+(b*c)
							$verbose>0 and warn "appending right combination\n";
							shift @{$self->{token}};
							my $b = pop @{$target->{args}};
							$target->addArg($node);
							unshift  @{$self->{stack}},$node;
							$node->addArg($b);
							$target=$self->{stack}[0];
							if( @{$target->{args}} < $target->{op}{count} ){
								$self->{allow_child} =1;
							}
							next Loop;
						}

						if( not $self->reduce("left combination $target->{op}->{key1} $op->{key1}") ){
						#	warn "reduce failed: ",Data::Dumper::Dumper($target),"\n";
							die "cannot resolve operator precedence between '$target->{op}->{key1}' and '$op->{key1}'\n";
						}
						$target=$self->{stack}[0];
					}
				}
			}
			last;
		}
		$verbose>0 and warn "end. stack=",join(',',map{$_->{op}->{key1}} @{$self->{stack}}),"\n";
		my $token = $self->peekToken;
		@{$self->{stack}}==1 or die "expression is not completed at '",(defined($token)?"'$token'":"end of statement"),"'\n";
		@{$self->{stack}[0]{args}} or die "expression not found\n";
		return $self->{stack}[0];
	}
}

{
	package Text::Template::Compact::Dataset;

	*getDataType = \&Text::Template::Compact::getDataType;
	*decodeQuote  = \&Text::Template::Compact::decodeQuote;

	sub new{
		my($class,$tmpl,$tag)=@_;
		return bless {
			tmpl=>$tmpl,
			tag=>$tag,
			enc => $tmpl->{paramEncoding},
		},$class;
	}

	sub print{
		my($self)=shift;
		my $printer = $self->{tmpl}{printer};
		my $filter  = ( $self->{tag}{filter} || $self->{tmpl}{filter_default} );
		for(@_){ $printer->( $filter->( Text::Template::Compact::dor($_,$self->{tmpl}{undef_supply}))); }
	}

	# make path from token
	sub token2path{
		my($self,$token)=@_;
		if( $token =~ /^"/
		or  $token =~ /^\d/
		){
			return ['i',decodeQuote($token)];
		}
		return ['k',$token];
	}

	sub makepathlist{
		my($self) = shift;
		return [ 'l',@_];
	}

	sub endoflist{
		my($self,$path)=@_;
		( $path->[0] eq 'l' ) and return $self->endoflist($path->[-1]);
		return $path;
	}

	sub getVlist{
		my($self,$result,$path)=@_;
		if( $path->[0] eq 'l' ){
			for(my $i=1;$i<@$path;++$i){
				$self->getVlist($result,$path->[$i]);
			}
		}else{
			my $val = $self->getV($path);
			push @$result,$val;
		}
	}

	# make data path from immediate value
	sub encode{
		my($self,$value)=@_;
		return ['i',$value];
	}	

	# make relative data path
	sub child{
		my($self,$path,$rel)=@_;
		my $r = ['p',[]];

		# get right item if arg is list
		$path = $self->endoflist($path);
		$rel = $self->endoflist($rel);

		# copy parent
		if($path->[0] eq 'p'){
			push @{$r->[1]} , @{$path->[1]};
		}else{
			push @{$r->[1]} , $path->[1];
		}

		# copy child
		if($rel->[0] eq 'p'){
			push @{$r->[1]} , @{$rel->[1]};
		}else{
			push @{$r->[1]} , $rel->[1];
		}

		# make
		return $r;
	}

	# get value in data path
	sub getV{
		my($self,$path)=@_;
		ref($path) or die "incorrect path\n";

		# get right item if arg is list
		$path = $self->endoflist($path);

		# immidiate value
		return $path->[1] if $path->[0] eq 'i';

		my @path;
		if( $path->[0] eq 'p' ){
			push @path,@{$path->[1]};
		}else{
			push @path,$path->[1];
		}

		my $param = $self->{tmpl}{param};
		my $path_str = '$';
		if( $path[0] eq '$' ){
			shift @path;
		}elsif( $path[0] eq '$$' ){
			shift @path;
			$param = $self->{tmpl};
		}

		while(@path){
			my $key = shift @path;
			my $type = getDataType($param);
			if( $type eq 'ARRAY' ){
				no warnings;
				$param = $param->[$key];
			}elsif($type eq 'HASH' ){
				no warnings;
				$param = $param->{$key};
			}else{
				die "incorrect data path $path_str\n";
			}
			$path_str .= (length($path_str)?'.':'').$key;
			(@path and not ref $param) and die "incorrect data path $path_str\n";
		}
		if( defined $param
		and not ref($param)
		and not utf8::is_utf8($param) 
		and defined $self->{enc}
		){
			return  Encode::decode($self->{enc},$param);
		}
		return $param;
	}
	# set value to data path
	sub setV{
		my($self,$path,$newval)=@_;

		# get right item if arg is list
		($path->[0] eq 'l') and $path = $self->endoflist($path);

		if( $path->[0] eq 'i' ){
			die "L-Value required\n";
		}

		my @path;
		if( $path->[0] eq 'p' ){
			push @path,@{$path->[1]};
		}else{
			push @path,$path->[1];
		}

		my $param = $self->{tmpl}{param};
		my $path_str = '$';
		if( $path[0] eq '$' ){
			shift @path;
		}elsif( $path[0] eq '$$' ){
			shift @path;
			$param = $self->{tmpl};
		}

		while(@path){
			my $key = shift @path;
			my $type = getDataType($param);
			if( $type eq 'ARRAY' ){
				if(not @path){
					my $old = $param->[$key];
					$param->[$key] = $newval;
					return \$old;
				}else{
					$param = $param->[$key];
				}
			}elsif($type eq 'HASH' ){
				if(not @path){
					my $old = $param->{$key};
					$param->{$key} = $newval;
					return \$old;
				}else{
					$param = $param->{$key};
				}
			}else{
				die "incorrect data path $path_str\n";
			}
			$path_str .= '.'.$key;
			(@path and not ref $param) and die "incorrect data path $path_str\n";
		}
	}
}

# record parse error and die (should be catch in parser)
sub parseError{
	my($self)=shift;
	my $msg = join('',"$self->{source_name} $self->{lno}: ",@_);
	$msg =~ s/[\x0d\x0a]+//g;
	push @{$self->{error}},$msg;
	croak $msg,"\n";
}

sub parseExpr{
	my($self,$list)=@_;
	my $r = eval{ Text::Template::Compact::ExprParser::parse($list);};
	$@ and $self->parseError($@);
	return $r;
}

sub evalExpr{
	my($tmpl,$tag,$expr)=@_;
	my $dataset = new Text::Template::Compact::Dataset($tmpl,$tag);
	my $r = eval{ $dataset->getV( $expr->eval($dataset) );};
	if($@){
		$r = "[Error: $@ in evalExpr]";
		$r =~s/[\x0d\x0a]+//g;
	}
	return $r;
}
sub evalExprList{
	my($tmpl,$tag,$expr)=@_;
	my $dataset = new Text::Template::Compact::Dataset($tmpl,$tag);
	my @list;
	eval{ $dataset->getVlist( \@list,$expr->eval($dataset) ); };
	if($@){
		my $r = "[Error: $@ in evalExprList]";
		$r =~s/[\x0d\x0a]+//g;
		return $r;
	}
	return @list;
}
sub evalExprKw{
	my($tmpl,$tag,$expr)=@_;
	my $dataset = new Text::Template::Compact::Dataset($tmpl,$tag);
	my $path = eval{ $expr->eval($dataset); };
	if($@){
		my $r = "[Error: $@ in evalExprKw]";
		$r =~s/[\x0d\x0a]+//g;
		return $r;
	}
	$path = $dataset->endoflist($path);
	return $path->[1] if $path->[0] =~/[ki]/;

	my $v = eval{ $dataset->getV( $path );};
	if($@){
		my $r = "[Error: $@ in evalExprKw]";
		$r =~s/[\x0d\x0a]+//g;
		return $r;
	}
	return $v;
}



sub setExprValue{
	my($tmpl,$tag,$expr,$newval)=@_;
	my $dataset = new Text::Template::Compact::Dataset($tmpl,$tag);
	my $path = $expr->eval($dataset);
	my $r = eval{ $dataset->setV($path,$newval);};
	if($@){
		$r = "[Error: $@ in setExprValue]";
		$r =~s/[\x0d\x0a]+//g;
	}
	return $r;
}

# eat specified token at head of the list. otherwise return undef.
sub eatType{
	my($list,$type)=@_;
	if( @$list and ref($list->[0]) and $list->[0]->{$type} ){
		return shift @$list;
	}
	return;
}

######################################


# print %eval tag
sub print_eval{
	my($tmpl,$tag)=@_;
	$tmpl->evalExpr($tag,$tag->{expr});
	return;
}

# print %var tag
sub print_var{
	my($tmpl,$tag)=@_;
	my $printer = $tmpl->{printer};
	my $filter =  dor( $tag->{filter} ,$tmpl->{filter_default} );
	for my $value ( $tmpl->evalExprList($tag,$tag->{expr}) ){
		$value = dor($value,$tmpl->{undef_supply});
		$printer->( $filter->($value));
	}
	return;
}

sub evalLabel($$$){
	my($tmpl,$tag,$label)=@_;
	return '' if not defined $label;
	return $tmpl->evalExprKw($tag,$label);
}

# print %for tag
sub print_for{
	my($tmpl,$tag)=@_;
	my $list = $tmpl->evalExpr($tag,$tag->{listname});
	my $index = 0;
	$tag->{indexstart} and $index = $tmpl->evalExpr($tag,$tag->{indexstart});
	for my $v (@$list){
		my $oldr;
		my $oldi;
		if($tag->{itemname}){
			$oldr = $tmpl->setExprValue($tag,$tag->{itemname},$v);
			ref($oldr) or $tmpl->{printer}->($oldr);
		}
		if($tag->{indexname}){
			$oldi = $tmpl->setExprValue($tag,$tag->{indexname},$index++);
			ref($oldi) or $tmpl->{printer}->($oldi);
		}
		my $exit_tag = $tmpl->printBlock( $tag->{block} );
		ref($oldr) and $tmpl->setExprValue($tag,$tag->{itemname} ,$$oldr);
		ref($oldi) and $tmpl->setExprValue($tag,$tag->{indexname} ,$$oldi);

		if($exit_tag){
			# not for this block?
			return $exit_tag if dor($tag->{label},'') ne evalLabel($tmpl,$tag,$exit_tag->{label});
			# for this block.
			next if $exit_tag->{continue};
			last if $exit_tag->{break};
		}
	}
	return;
}

sub print_while{
	my($tmpl,$tag)=@_;
	$tag->{ex_init} and $tmpl->evalExpr($tag,$tag->{ex_init});
	my $exit_tag;
	for(;;){
		last if $tag->{ex_precheck} and not $tmpl->evalExpr($tag,$tag->{ex_precheck});
		$exit_tag = $tmpl->printBlock( $tag->{block} );
		if($exit_tag){
			# not for this block?
			last if dor($tag->{label},'') ne evalLabel($tmpl,$tag,$exit_tag->{label});
			# for this block.
			if($exit_tag->{break}){
				undef $exit_tag;
				last;
			}
		}
		last if $tag->{ex_postcheck} and not $tmpl->evalExpr($tag,$tag->{ex_postcheck});
		$tag->{ex_step} and $tmpl->evalExpr($tag,$tag->{ex_step});
	}
	$tag->{ex_final} and $tmpl->evalExpr($tag,$tag->{ex_final});
	return $exit_tag;
}

# print %blockpaste tag
sub print_block{
	my($tmpl,$tag)=@_;
	my $block = $tmpl->{block}{$tag->{name}};
	if(not defined($block) ){
		$tmpl->{printer}->( "[Error: block '$tag->{name}' is not defined]" );
		return;
	}
	my $exit_tag = $tmpl->printBlock( $block );
	return if not $exit_tag;
	# not for this block?
	return $exit_tag if dor($tag->{label},'') ne evalLabel($tmpl,$tag,$exit_tag->{label});
	# for this block.
	# no difference between break or continue, just exit this block.
	return;
}

# print %eval tag
sub print_evalperl{
	my($tmpl,$tag)=@_;
	local $_ = $tmpl->{param};
	my $code = $tag->{code};
	my @data = map{ $tmpl->evalExpr($tag,$_) } @{$tag->{args}};
	my $a_code =ord('a');
	@data and $code = "my(".join(',',map{my $c=chr($_+$a_code);"\$$c"}(0..$#data)).")=\@data;$code";
	my $r = eval "{no warnings; $code;}";
	$@ and $tmpl->{printer}->( "[eval failed: $@]");
	$tag->{result} and $tmpl->setExprValue($tag,$tag->{result},$r);
	return;
}


# print %else tag
sub print_else{
	my($tmpl,$tag)=@_;

	my $exit_tag = $tmpl->printBlock( $tag->{block} );

	# normally 'if' is not match for break,continue
	# match only label is explicitly specified in both of block and break.
	if( $exit_tag
	and defined($exit_tag->{label})
	and defined($tag->{label})
	and $exit_tag->{label} eq $tag->{label}
	){
		# exit_tag is solved in this scope.
		return;
	}
	return $exit_tag;
}

# print %if tag
sub print_if_simple{
	my($tmpl,$tag)=@_;
	my $value = $tmpl->evalExpr($tag,$tag->{expr});
	$value and return print_else($tmpl,$tag);
	$tag=$tag->{next};
	$tag->{printer} and return $tag->{printer}($tmpl,$tag);
	return;
}

# print %if tag
sub print_if_code{
	my($tmpl,$tag)=@_;
	my @data = map{ $tmpl->evalExpr($tag,$_) } @{$tag->{args}};
	my $code = $tag->{code};
	my $a_code =ord('a');
	@data and $code = "my(".join(',',map{my $c=chr($_+$a_code);"\$$c"}(0..$#data)).")=\@data;$code";
	local $_ = $tmpl->{param};
	my $value = eval "no warnings; $code";
	$@ and $tmpl->{printer}->( "[eval failed: $@]");

	$value and return print_else($tmpl,$tag);
	$tag=$tag->{next};
	$tag->{printer} and return $tag->{printer}($tmpl,$tag);
	return;
}

#####################################################

# parse template tag
sub parseTemplateTag{
	my($self,$text)=@_;

	# split to token list
	my @list = $text =~ /$Text::Template::Compact::ExprParser::token_re|"(?:[^"]|"")*"|[\w_]+|\p{IsWord}+/g;
	@list or die $self->parseError("empty template tag");
	
	# parse filter
	my $filter;
	if( @list >= 2 and $filter_map{ $list[-1] } and $list[-2] eq '#' ){
		$filter = $filter_map{ $list[@list-1] };
		splice @list,@list-2;
	}
	
	my @taglist;
	my $type;
	while(@list){
		if($list[0] eq ';'){
			shift @list;
			next;
		}

		my $item = {lno=>$self->{lno}};
		$filter and $item->{filter} = $filter;

		# read label:
		if( @list >= 2
		and $list[1] eq ':'
		and $list[0] =~/^\w/
		){
			$item->{label} = $list[0];
			splice @list,0,2;
			last if not @list;
		}

		# % type
		if( $list[0] eq '%' ){
			# skip '%'
			shift @list; 
			# read type of tag
			@list or $self->parseError("no tag type after '%'");
			$type = lc decodeQuote(shift @list);
		}else{
			$type = 'print';
		}

		$item->{$item->{type}=$type}=1;

		if( $type eq 'print' ){
			# %print expr,expr... 
			$item->{printer}=\&print_var;
			$item->{expr} = $self->parseExpr(\@list);

		}elsif( $type eq 'eval' ){
			# %print expr,expr... 
			$item->{printer}=\&print_eval;
			$item->{expr} = $self->parseExpr(\@list);

		}elsif( $type eq 'if' or  $type eq 'elsif' ){
			# %if    expr
			# %elsif expr
			$item->{printer}=\&print_if_simple;
			$item->{expr} = $self->parseExpr(\@list);

		}elsif( $type eq 'ifc' or  $type eq 'elsifc' ){
			# %ifc    "code" dataspec dataspec ...
			# %elsifc "code" dataspec dataspec ...
			$item->{printer}=\&print_if_code;
			$item->{code} =decodeQuote(shift @list);
			$item->{args}=[];
			while(@list and $list[0] ne ';' ){
				push @{$item->{args}},$self->parseExpr(\@list);
			}

		}elsif( $type eq 'else'){
			# %else
			$item->{printer}=\&print_else;

		}elsif( $type eq 'end'){
			# %end

		}elsif( $type eq 'break' or $type eq 'continue' ){
			# %break [label]
			# %continue [label]
			if( @list and $list[0] ne ';'){
				$item->{label} = $self->parseExpr(\@list);
			}

		}elsif( $type eq 'end'){
			# %end

		}elsif( $type eq 'for' ){
			# %for item in list indexname indexstart
			$item->{printer}=\&print_for;
			$item->{itemname} = $self->parseExpr(\@list);

			(not @list or not $list[0] eq 'in' ) and  $self->parseError("expected 'in' keyword is not found.");
			shift @list;

			$item->{listname} = $self->parseExpr(\@list);

			(@list and $list[0] ne ';') and $item->{indexname} = $self->parseExpr(\@list);
			(@list and $list[0] ne ';') and $item->{indexstart} = $self->parseExpr(\@list);

		}elsif( $type eq 'while' ){
			# %for item in list indexname indexstart
			$item->{printer}=\&print_while;
			Loop: while( @list and $list[0] ne ';' ){
				for (qw( init precheck postcheck step final )){
					if( $list[0] eq $_ ){
						shift @list;
						$item->{"ex_$_"} = $self->parseExpr(\@list);
						next Loop;
					}
				}
				$self->parseError("expected 'init/precheck/postcheck/step/final' not found.");
			}

		}elsif( $type eq 'blockdefine' or  $type eq 'blockpaste' ){
			# %blockdefine blockname
			# %blockpaste blockname
			$item->{printer}=\&print_block;
			@list or $self->parseError("no block name after $type");
			$item->{name} = decodeQuote(shift @list);
			if( $type eq 'blockdefine' ){
				defined( $self->{block}{$item->{name}} ) and $self->parseError("redefined block '$item->{name}'");
				$self->{block}{$item->{name}} = [];
			}
		}elsif( $type eq 'evalperl' ){
			# %evalperl "code" [result] [arg]...
			$item->{printer}=\&print_evalperl;
			@list or $self->parseError("no text after 'evalperl'");
			$list[0] =~ /^"/ or $self->parseError("you must quote code with \"...\"");
			$item->{code} = decodeQuote(shift @list);
			@list and $item->{result} = $self->parseExpr(\@list);
			$item->{args} = [];
			while(@list and $list[0] ne ';' ){
				push @{$item->{args}},$self->parseExpr(\@list);
			}
		}else{
			# unsupported tag type 
			$self->parseError("unsupported tag type '$type'");
		}
		@list and $list[0] ne ';' and $self->parseError("unexpected token '$list[0]' in template tag");
		push @taglist,$item;
	}
	return @taglist;
}

# compose tree of tag and text.
sub parseBlock{
	my($self,$rList,$block)=@_;

	while(@$rList){
		my $item = $rList->[0];
		# normal text
		if( not ref($item) ){
			push @$block, shift @$rList;
			next;
		}
		# exit before end of block
		last if grep {$item->{type} eq $_} qw( end else elsif elsifc );

		# %blockdefine
		if( $item->{blockdefine} ){
			shift @$rList;
			$self->parseBlock( $rList,$self->{block}{$item->{name}});
			eatType($rList,'end') or $self->parseError("missing end of blockdefine (start at $item->{lno})");
			next;
		}

		# append to current block
		push @$block, shift @$rList;

		# %for 
		if( $item->{for} or $item->{while} ){
			$item->{block} = [];
			$self->parseBlock( $rList ,$item->{block});
			eatType($rList,'end') or $self->parseError("missing end of $item->{type} loop (start at $item->{lno})");
			next;
		}

		# %if ,%elsif,%else
		if( $item->{if} or $item->{ifc}){
			for(;;$item = $item->{next}){
				$item->{block} = [];
				$self->parseBlock( $rList ,$item->{block});
				@$rList or $self->parseError("missing end of if/elsif/else/elsifc block (start at $item->{lno})");
				$item->{next} = shift @$rList;
				last if $item->{next}{end};
				$item->{label} and not defined($item->{next}->{label}) and $item->{next}->{label}=$item->{label};
			}
			next;
		}
	}
}

sub closeLine{
	my($rAll,$rLine)=@_;
	my $a = grep{
		if( ref($_) ){
			$_->{print};
		}else{
			$_ =~ /[^\s　]/ ?1:0;
		}
	} @$rLine;
	if($a){
		for (@$rLine,"\x0a"){
			if(not ref($_)
			and @$rAll
			and not ref($rAll->[-1])
			){
				$rAll->[-1].= $_;
			}else{
				push @$rAll,$_;
			}
		}
	}else{
		for (@$rLine){
			ref($_) and push @$rAll,$_;
		}
	}
	@$rLine = ();
}

# convert from source text to template structure.
# $ok = $tmpl->loadText($filename,\$text [,$blockname]);
sub loadText{
	my $self = shift;
	$self->{error}=[];
	$self->{lno}=1;
	$self->{source_name} = $_[0];
	my $rText = ref($_[1])?$_[1]:\$_[1];
	my $blockname = ($_[2] || "");

	# split source to tag and text
	my @list;
	my @line;
	my $lastend = 0;
	while( $$rText =~ /(\x0D\x0A|\x0D|\x0A)|(?<!\$)(\$\{(?:[^}"]*|"(?:[^"]|"")*")+)\}/gs ){
		my $pre = substr($$rText,$lastend,$-[0] - $lastend); $lastend = $+[0];
		if( defined($1) ){
			$pre =~ s/\$\${/\$\{/g;
			length($pre) and push @line,$pre;
			closeLine(\@list,\@line);
			++$self->{lno};
		}else{
			my $inside = substr($2,2);
			$pre =~ s/\$\${/\$\{/g;
			length($pre) and push @line,$pre;
			push @line,eval{ $self->parseTemplateTag($inside);};
			$self->{lno} += $inside =~ tr/\x0a/\x0a/;
		}
	}
	if( $lastend < length($$rText) ){
		my $text =substr($$rText,$lastend);
		$text =~ s/\$\$\{/\$\{/g;
		warn "left=[$text]\n";
		push @line,$text;
		closeLine(\@list,\@line);
	}

	# parse control block
	$self->{block}{$blockname} = [];
	eval{ $self->parseBlock( \@list,$self->{block}{$blockname} ); };

	return !@{$self->{error}};
}


# $ok = $tml->loadFile("filename","utf8" [,$blockname]);
sub loadFile{
	my $self = shift;

	$self->{lno} = 0;
	$self->{source_name} = $_[0];
	my $enc = $_[1];
	my $blockname = $_[2];

	# find encoding object for source
	if(defined $enc){
		ref($enc) or $enc = Encode::find_encoding($enc);
		if(not ref($enc) =~/Encode/){
			push @{$self->{error}},"$self->{source_name} $self->{lno}: incorrect encode spec.";
			return;
		}
	}

	# read source text
	my $source;
	my $fh;
	if(not open $fh,"<",$self->{source_name} ){
		push @{$self->{error}},"$self->{source_name} $self->{lno}: $!";
		return;
	}else{
		local $/=undef;
		$source = <$fh>;
		defined($enc) and $source = Encode::decode($enc,$source);
		if(not close $fh ){
			push @{$self->{error}},"$self->{source_name} $self->{lno}: $!";
			return;
		}
	}
	return $self->loadText($self->{source_name},\$source,$blockname);
}

# $teml = Text::Template::Compact->new();
sub new{
	return bless{
		error => [], 
		paramEncoding => Encode::find_encoding('utf8'), 
		filter_default => $filter_map{'html'},
		undef_supply => '',
	} , shift;
}

# get error as string.
sub error{
	return join("\n",@{$_[0]->{error}},'');
}
# get error as string.
sub undef_supply{
	my $self = shift;
	if(@_){
		$self->{undef_supply} = $_[0];
	}
	return $self->{undef_supply};
}

# set encoding for decode parameter
sub param_encoding{
	my $self = shift;
	if(@_){
		my $enc = $_[0];
		# find encoding object for source
		if(defined $enc){
			ref($enc) or $enc = Encode::find_encoding($enc);
			ref($enc) =~/Encode/ or croak "incorrect encode spec.";
		}
		$self->{paramEncoding} = $enc;
	}
	return;
}

# set default of filter for variable expand.
sub filter_default{
	my $self = shift;
	if(@_){
		my $filtername = $_[0];
		if( not $filtername or not $filter_map{$filtername} ){
			croak "unknown filter '$filtername'";
		}
		$self->{filter_default} = $filter_map{$filtername};
	}
	return;
}

# print template block(low-level method)
sub printBlock{
	my($self,$block)=@_;
	for my $item ( @$block ){
		if( not ref $item ){
			$self->{printer}->($item);
		}elsif( $item->{break} or $item->{continue} ){
			return $item;
		}else{
			my $exit_tag = $item->{printer}($self,$item);
			$exit_tag and return $exit_tag;
		}
	}
	return;
}

# print to filehandle
sub print{
	my($self,$param,$fh,$enc)=@_;

	# generate closure to print
	if(defined $enc){
		# find encoding object for source
		ref($enc) or $enc = Encode::find_encoding($enc);
		ref($enc) =~/Encode/ or croak "incorrect encode spec.";
		$self->{printer} = sub{ for(@_){ print $fh Encode::encode($enc,$_); } };
	}else{
		$self->{printer} = sub{ print $fh @_; };
	}
	$self->{param} = $param;

	# start root node
	my $exit_tag = $self->printBlock( $self->{block}{""});
}

sub toString{
	my($self,$param)=@_;
	my $result='';
	$self->{param} = $param;
	$self->{printer} = sub{ for(@_){ $result .= $_; } };
	$self->printBlock( $self->{block}{""} );
	return $result;
}

1;

__END__

=head1 NAME

Text::Template::Compact - text base template expand module

=head1 SYNOPSIS

	use utf8;
	use Encode;
	use Text::Template::Compact;

	# create instance
	my $tmpl = new Text::Template::Compact();

	# load from file
	$tmpl->loadFile('template.html','utf8') or die $tmpl->error;

	# or load from text
	$tmpl->loadText('src1','hello, ${world}!','utf8') or die $tmpl->error;

	# prepare binding parameter
	my $param = { world=>'World' };

	# set default filter that used when output parameter or expression
	$tmpl->filter_default('html');

	# set encoding that used when read non-utf8 value from parameter.
	$tmpl->param_encoding('cp932');

	# set string that used for print instead of undefined value.
	$tmpl->undef_supply('(null)');

	# print to filehandle
	$tmpl->print($param,\*STDOUT,'utf8');

	# or get string output
	print Encode::encode('utf8',$tmpl->toString($param));

=head1 DESCRIPTION

The C<Text::Template::Compact> module is text base template expand module.
This module compile control tag in source text and output it with parameter data that gived at runtime.
Its main purpose is handling HTML templates in Web Application,
but it also available for other situation such as mail,XML,etc,.

=head1 FEATURE

=over

=item 

requires perl >= 5.8.3.

=item 

no extra dependency.

=item 

this module supports various expressions in control tags.

=item 

unicode support. it works correctly on 'use utf8;' situation.
you can apply different character encoding for source, output, and reading non-utf8 peremeter.

=item 

looks of control tags are ${...} or ${%...}

=item 

types of control tag are: print, if-elsif-else-end, for-end, while-end, eval, blockdefine, blockpaste.

=item 

escape filter support. also programmer can specify default filter for tags that fileter was abbreviated.

=back

=head1 TEMPLATE SYNTAX 

=head2 control tag

 ${ [label:] [% tagtype] tag-arg [;[label:] [% tagtype] tag-arg ...] [#filter]}

=over

=item *

in text of template source, looks of control tag is ${...}.

=item *

if you want to write ${ as normal text , please escape it to $${ .

=item *

tokens in control tag are:

=over 3

=item **

keyword that start with alphabet and underbar and follows alphabet,underbar,numeric.

=item **

"double quoted string" . if you want to write " in quoted string , please escape it to "".

=item **

numeric constant. (integer only. '.' is not supported)

=item **

any symbols except '}' and '"'

=back

=item * 

to specify escape filter, use  '#I<filtername>' in end of tags.
I<filtername> is one of B<raw>,B<html>,B<uri>,B<nobr>.
if you omit filter spec in tag, default filter that specified by program as $tmpl->filter_default('html'); is applied.

=item * 

you can write a number of control statement in a tag. each control statement is separated by ';' .

=item * 

type of control statement is specified as I<%command> in head of statement ( excepts label if exists.).
if you omit I<%command>, B<%print> is supplied.

=item * 

you can add I<label:> at head of control statement (before %).
this is used for B<break> and B<continue>.

=item *

if line of source text contains only whitespaces control tag excepts B<%print>, spaces and linefeed in the line is removed at compiling source.

=back

=head2 expression

you may use expression in control statement such as B<print>,B<eval>,B<for>,B<if> to reference data in parameter object.
supported operator and literarls are:

=over

=item almost same as perl:

B<()>
B<++>
B<-->
B<**>
B<!>
B<~>
B<unary+>
B<unary->
B<*>
B</>
B<%>
B<+>
B<->
B<E<lt>E<lt>>
B<E<gt>E<gt>>
B<int>
B<defined>
B<length>
B<E<lt>>
B<E<gt>>
B<E<lt>=>
B<E<gt>=>
B<lt>
B<gt>
B<le>
B<ge>
B<==>
B<!=>
B<E<lt>=E<gt>>
B<eq>
B<ne>
B<cmp>
B<eq>
B<ne>
B<cmp>
B<&>
B<|>
B<^>
B<&&>
B<||>
B<//>
B<?:>
B<=>
B<**=>
B<*=>
B</=>
B<%=>
B<+=>
B<-=>
B<E<lt>E<lt>=>
B<E<gt>E<gt>=>
B<&=>
B<|=>
B<^=>
B<&&=>
B<||=>
B<//=>
B<,>
B<print>
B<scalar>
B<join>
B<push>
B<pop>
B<shift>
B<unshift>
B<not>
B<and>
B<or>
B<xor>

=item notation is changed from perl:

=over

=item

B<cat> (same as . in perl)

=item

B<repeat> (same as x in perl)

=item

B<makearray> (same as [] in perl)

=item

B<makehash> (same as {} in perl)

=back

=item other operators:

=over

=item

B<bool> (same as not not )

=item

B<nz> (same as !=0 ) 

=item

B<call> coderef,args... (same as  coderef->(args,...) in perl)

=item

B<call> obj,"method",args... (same as  obj->"method"(args,...) in perl)

=back

=item literal:

=over 3

=item *

keyword that start with alphabet and underbar and follows alphabet,underbar,numeric.

=item *

"double quoted string" . if you want to write " in quoted string , please escape it to "".

=item *

numeric constant. (integer only. '.' is not supported)

=back

=back

=head3 expression for data reference 

	# for example, the parameter data structure that passed to template is this:
	$VAR1 = {
		h=>{ a=>1,b=>2,c=>3, ge=>4},
		v=>['a','b','c','d'],
		ge => 4,
		ge => 4,
	}
	#then data reference and its value is:
	h.c     => means 3
	v.1     => means 'b'
	v.(1+2) => means 'd'
	h[v.1]  => means  2  
	v[h.c]  => means 'd' 
	ge      => error.  because 'ge' is operator, not keyword.
	$ge     => means 4. using $ to change interpret of keyword and operator.
	h["ge"] => means 4. using [] to avoid interpret of keyword and operator.

looks of expression for data reference are like as name , name.key , name[2].key , $name.
each node that separated by . and [] indicate hash-key or array-index in parameter data structure.

=over

=item a[b]

reference hash-key or array-index of a by value of b.
left term must be data reference.

=item a.b

reference hash-key or array-index of a by keyowrd of b.
left term must be data reference.
if right term is keyword , use its name  as key or index. 
if right term is not keyword, use its value as key or index. 
if each term is data reference , concat the data path.

=item $

symbol $ is reference to whole of parameter data.
and you can use $keyword to avoid conflict between keyword and operator .

=item $$

symbol $$ is reference to whole of template object.

=back

=head4 examples

	${v}            # referencde parameter data by key 'v'.
	${"v"}          # string constant. not reference parameter data.
	${2}            # numeric constant.not reference parameter data.
	${va[2]}        # reffernce array by numeric subscript .
	${va[-1]}       # negative subscript to reference end of array.
	${va[v2]}       # use value of another data as subscript index of array.
	${vh["v2"]}     # use string constatnt  to subscript key of hash.
	${vh.v2}        # use keyword name      in right term of '.'
	${va.-1}        # use expression value  in right term of '.'
	${va.(1+2)}     # use expression value  in right term of '.'
	${vh."v2"}      # use string  constatnt in right term of '.'
	${va.2}         # use integer constatnt in right term of '.'
	${va.v3}        # same as 'va.0'. if left term is array,keyword of right term is interpolated in numeric context.
	${vh.(va.2)}    # same as 'vh.va.2'. if term is data reference, each path willbe concat.
	${$2.2}         # example of using $ in data reference
	${$.2.2}        # example of using $ in data reference
	${$[2].2}       # example of using $ in data reference
	${$defined}     # keyword after $/$$ is interpolated as dara reference although its looks is operator.
	${$"defined"}   # constant literal after $/$$ is interpolated as dara reference.
	${$.defined }   # Error. bare 'defined' is interpolated as operator.

=head2 %print

 Syntax:
	${ [%print] expr }
 Examples:
	${1,2,3}
	${client.5.address}
	${client[loopcount].address}
	${ "売り上げ"."合計" }
	${user.phone||"not available"}
	${user.mobile?"携帯ユーザ":"PCユーザ"}
	E<lt>a href="?who=${data#uri}"E<gt>${data#nobr}E<lt>/aE<gt>
	E<lt>textarea name="a"E<gt>${body#nobr}E<lt>/textareaE<gt>

Print expression to place of control tag.
And you can omit part of '%print' in tag, such as ${expr}.

=head2 %eval

 Syntax:
	${%eval expr}
 Examples:
	${%eval name="foo",caption="bar"}

Eval expression, but not print to outout.
Also you can use operator 'print' in this tag.

=head2 %evalperl

 Syntax:
	${%evalperl "perlcode" [result [arg [arg ...]]] }

You can write perl code in "perlcode". please quote it.
If you specify data reference at 'result', result of eval is stored to it.
If you specify data reference at 'arg', its value willbe copied to local variable $a,$b,... brfore eval.
reference of parameter object is copied to local variable $_ before eval.

=head2 %if,%elsif,%else,%end,%ifc,%elsifc

 Syntax:
	${ [label:] %if expr } or ${ [label:] %ifc    "perlcode" [arg [arg ...]] }
		block
	${%elsif expr }or ${%elsifc "perlcode" [arg [arg ...]] }
		block
	${%else}
		block
	${%end}

=head2 %for

 Syntax:
	${ [label:] %for item in array [index] [indexstart] }
		block
	${%end}

I<item> must have LValue.

I<array> must have array reference.

I<index> can be omit, or must have LValue.

I<indexstart> can be omit, or must have numeric value.

loops for each element of I<array>.

in the loop, element of index are copied to I<item> and I<index>.

If I<indexstart> is specified, initial value of I<index> will be changed.

=head2 %while

 Syntax:
	${ [label:] %while
	    [init init_expr]
	    [precheck precheck_expr]
	    [postcheck postcheck_expr]
	    [step step_expr]
	    [final final_expr]
	}
		block
	${%end}
 
 Examples:
	${%while init i=0 precheck i<10 step i++} ${i} ${%end}
	${%while init i=0 postcheck i<10 step i++} ${i} ${%end}
	${%while precheck left-- } ...  ${%end}
	${%while postcheck --left} ...  ${%end}
 
 pseudo code to explain timing of evaluate each expression 
	(init_expr);
	loop{
		if(!precheck_expr) break;
		block
	_CONTINUE:
		if(!postcheck_expr) break;
		(step_expr);
	}
	_BREAK:
	(final_expr);

=head2 %break,%continue

 Syntax:
	${%break [label] }
	${%continue [label] }

These tags are used to exit block.

=head2 %blockdefine,%blockpaste

 Syntax:
	${%blockdefine blockname }
		...
	${%end}
	
	${%blockpaste blockname }

=head1 AUTHOR

tateisu C<tateisu@gmail.com >

=cut

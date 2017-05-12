#$Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine.pm 25 2006-02-15T15:34:11.453583Z mrodrigu  $
package Tree::XPathEngine;

use warnings;
use strict;

use vars qw($VERSION $AUTOLOAD $revision);

$VERSION = '0.05';
$Tree::XPathEngine::DEBUG = 0;

use vars qw/
        $WILD
        $NUMBER_RE 
        $NODE_TYPE 
        $AXIS_NAME 
        %AXES 
        $LITERAL
        $REGEXP_RE
        $REGEXP_MOD_RE
        %CACHE/;

use Tree::XPathEngine::Step;
use Tree::XPathEngine::Expr;
use Tree::XPathEngine::Function;
use Tree::XPathEngine::LocationPath;
use Tree::XPathEngine::Variable;
use Tree::XPathEngine::Literal;
use Tree::XPathEngine::Number;
use Tree::XPathEngine::NodeSet;
use Tree::XPathEngine::Root;

# Axis name to principal node type mapping
%AXES = (
        'ancestor' => 'element',
        'ancestor-or-self' => 'element',
        'attribute' => 'attribute',
        'child' => 'element',
        'descendant' => 'element',
        'descendant-or-self' => 'element',
        'following' => 'element',
        'following-sibling' => 'element',
        'parent' => 'element',
        'preceding' => 'element',
        'preceding-sibling' => 'element',
        'self' => 'element',
        );

$WILD          = qr{\*};
$NODE_TYPE     = qr{(?:(text|node)\(\))};
$AXIS_NAME     = '(?:' . join('|', keys %AXES) . ')::';
$NUMBER_RE     = qr{(?:\d+(?:\.\d*)?|\.\d+)};
$REGEXP_RE     = qr{(?:m?/(?:\\.|[^/])*/)};
$REGEXP_MOD_RE = qr{(?:[imsx]+)};
$LITERAL       = qr{(?:"[^"]*"|'[^']*')};

sub new {
    my $class = shift;
    my( %option)= @_;
    
    my $self = bless {}, $class;

    $self->{NAME}= $option{xpath_name_re} || qr/(?:[A-Za-z_][\w.-]*)/;
    $self->{NAME}= qr/(?:$self->{NAME})/; # add parens just to make sure we have them
    
    _debug("New Parser being created.\n") if( $Tree::XPathEngine::DEBUG);
    $self->{context_set} = Tree::XPathEngine::NodeSet->new();
    $self->{context_pos} = undef; # 1 based position in array context
    $self->{context_size} = 0; # total size of context
    $self->{vars} = {};
    $self->{direction} = 'forward';
    $self->{cache} = {};
    
    return $self;
}

sub find {
    my $self = shift;
    my( $path, $context) = @_;
    my $parsed_path= $self->_parse( $path);
    return $parsed_path->evaluate( $context);
}


sub matches {
    my $self = shift;
    my ($node, $path, $context) = @_;

    my @nodes = $self->findnodes( $path, $context);

    if (grep { "$node" eq "$_" } @nodes) { return 1; }
    return;
}

sub findnodes {
    my $self = shift;
    my ($path, $context) = @_;
    
    my $results = $self->find( $path, $context);
    
    if ($results->isa('Tree::XPathEngine::NodeSet')) 
      { return $results->get_nodelist; }
    else
      { return ();   }
}


sub findnodes_as_string {
    my $self = shift;
    my ($path, $context) = @_;
    
    my $results = $self->find( $path, $context);
    
    if ($results->isa('Tree::XPathEngine::NodeSet')) {
        return join('', map { $_->to_string } $results->get_nodelist);
    }
    elsif ($results->isa('Tree::XPathEngine::Node')) {
        return $results->to_string;
    }
    else {
        return $results->value; # CHECK
    }
}

sub findvalue {
    my $self = shift;
    my ($path, $context) = @_;
    my $results = $self->find( $path, $context);
    return $results ? $results->xpath_to_literal : '';
}

sub exists
  { my $self = shift;
    my ($path, $context) = @_;
    my @nodeset = $self->findnodes( $path, $context);
    return scalar( @nodeset ) ? 1 : 0;
  }

sub get_var {
    my $self = shift;
    my $var = shift;
    $self->{vars}->{$var};
}

sub set_var {
    my $self = shift;
    my $var = shift;
    my $val = shift;
    $self->{vars}->{$var} = $val;
}

#sub _get_context_set  { $_[0]->{context_set}; }
sub _set_context_set  { $_[0]->{context_set} = $_[1]; }
sub _get_context_pos  { $_[0]->{context_pos}; }
sub _set_context_pos  { $_[0]->{context_pos} = $_[1]; }
sub _get_context_size { $_[0]->{context_set}->size; }
#sub _get_context_node { $_[0]->{context_set}->get_node($_[0]->{context_pos}); }

sub _parse {
    my $self = shift;
    my $path = shift;
    if ($CACHE{$path}) {
        return $CACHE{$path};
    }
    my $tokens = $self->_tokenize($path);

    $self->{_tokpos} = 0;
    my $tree = $self->_analyze($tokens);
    
    if ($self->{_tokpos} < scalar(@$tokens)) {
        # didn't manage to parse entire expression - throw an exception
        die "Parse of expression $path failed - junk after end of expression: $tokens->[$self->{_tokpos}]";
    }
    
    $CACHE{$path} = $tree;
    
    _debug("PARSED Expr to:\n", $tree->as_string, "\n") if( $Tree::XPathEngine::DEBUG);
    
    return $tree;
}

sub _tokenize {
    my $self = shift;
    my $path = shift;
    study $path;
    
    my @tokens;
    
    _debug("Parsing: $path\n") if( $Tree::XPathEngine::DEBUG);
    
    # Bug: We don't allow "'@' NodeType" which is in the grammar, but I think is just plain stupid.

    my $expected=''; # used to desambiguate conflicts (for REs)

    while( length($path))
      { my $token='';
        if( $expected eq 'RE' && ($path=~ m{\G\s*($REGEXP_RE $REGEXP_MOD_RE?)\s*}gcxs))
          { $token= $1; $expected=''; }
        elsif($path =~ m/\G
            \s* # ignore all whitespace
                ( # tokens
                $LITERAL|                           # literal string
                $NUMBER_RE|                         # digits
                \.\.|                               # parent
                \.|                                 # current
                ($AXIS_NAME)?$NODE_TYPE|            # node type test (probably useless in this context)
                \@($self->{NAME}|$WILD)|            # attribute
                \$$self->{NAME}|                    # variable reference
                ($AXIS_NAME)?($self->{NAME}|$WILD)| # NAME,NodeType,Axis::Test
                \!=|<=|\-|>=|\/\/|and|or|mod|div|   # multi-char seps
                =~|\!~|                             # regexp matching (not in the XPath spec)
                [,\+=\|<>\/\(\[\]\)]|               # single char seps
                (?<!(\@|\(|\[))\*|                  # multiply operator rules (see xpath spec)
                (?<!::)\*|
                $ # match end of query
            )
            \s* # ignore all whitespace
            /gcxs) 
          { 
            $token = $1;
            $expected= ($token=~ m{^[=!]~$}) ? 'RE' : '';
          }
        else
          { $token=''; last; }

        if (length($token))
          {
            _debug("TOKEN: $token\n") if( $Tree::XPathEngine::DEBUG);
            push @tokens, $token;
          }
      }
            
    if (pos($path) < length($path)) {
        my $marker = ("." x (pos($path)-1));
        $path = substr($path, 0, pos($path) + 8) . "...";
        $path =~ s/\n/ /g;
        $path =~ s/\t/ /g;
        die "Query:\n",
            "$path\n",
            $marker, "^^^\n",
            "Invalid query somewhere around here (I think)\n";
    }
    
    return \@tokens;
}

sub _analyze {
    my $self = shift;
    my $tokens = shift;
    # lexical analysis
    
    return _expr($self, $tokens);
}

sub _match {
    my ($self, $tokens, $match, $fatal) = @_;
    
    $self->{_curr_match} = '';
    return 0 unless $self->{_tokpos} < @$tokens;

    local $^W;
    
#    _debug ("match: $match\n") if( $Tree::XPathEngine::DEBUG);
    
    if ($tokens->[$self->{_tokpos}] =~ /^$match$/) {
        $self->{_curr_match} = $tokens->[$self->{_tokpos}];
        $self->{_tokpos}++;
        return 1;
    }
    else {
        if ($fatal) {
            die "Invalid token: ", $tokens->[$self->{_tokpos}], "\n";
        }
        else {
            return 0;
        }
    }
}

sub _expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _exprexpr\n") if( $Tree::XPathEngine::DEBUG);
    
    return _or_expr($self, $tokens);
}

sub _or_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _or_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _and_expr($self, $tokens); 
    while (_match($self, $tokens, 'or')) {
        my $or_expr = Tree::XPathEngine::Expr->new($self);
        $or_expr->set_lhs($expr);
        $or_expr->set_op('or');

        my $rhs = _and_expr($self, $tokens);

        $or_expr->set_rhs($rhs);
        $expr = $or_expr;
    }
    
    return $expr;
}

sub _and_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _and_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _match_expr($self, $tokens);
    while (_match($self, $tokens, 'and')) {
        my $and_expr = Tree::XPathEngine::Expr->new($self);
        $and_expr->set_lhs($expr);
        $and_expr->set_op('and');
        
        my $rhs = _match_expr($self, $tokens);
        
        $and_expr->set_rhs($rhs);
        $expr = $and_expr;
    }
    
    return $expr;
}

sub _match_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _match_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _equality_expr($self, $tokens);

    while (_match($self, $tokens, '[=!]~')) {
        my $match_expr = Tree::XPathEngine::Expr->new($self);
        $match_expr->set_lhs($expr);
        $match_expr->set_op($self->{_curr_match});
        
        my $rhs = _equality_expr($self, $tokens);
        
        $match_expr->set_rhs($rhs);
        $expr = $match_expr;
    }
    
    return $expr;
}

sub _equality_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _equality_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _relational_expr($self, $tokens);
    while (_match($self, $tokens, '!?=')) {
        my $eq_expr = Tree::XPathEngine::Expr->new($self);
        $eq_expr->set_lhs($expr);
        $eq_expr->set_op($self->{_curr_match});
        
        my $rhs = _relational_expr($self, $tokens);
        
        $eq_expr->set_rhs($rhs);
        $expr = $eq_expr;
    }
    
    return $expr;
}

sub _relational_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _relational_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _additive_expr($self, $tokens);
    while (_match($self, $tokens, '(<|>|<=|>=)')) {
        my $rel_expr = Tree::XPathEngine::Expr->new($self);
        $rel_expr->set_lhs($expr);
        $rel_expr->set_op($self->{_curr_match});
        
        my $rhs = _additive_expr($self, $tokens);
        
        $rel_expr->set_rhs($rhs);
        $expr = $rel_expr;
    }
    
    return $expr;
}

sub _additive_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _additive_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _multiplicative_expr($self, $tokens);
    while (_match($self, $tokens, '[\\+\\-]')) {
        my $add_expr = Tree::XPathEngine::Expr->new($self);
        $add_expr->set_lhs($expr);
        $add_expr->set_op($self->{_curr_match});
        
        my $rhs = _multiplicative_expr($self, $tokens);
        
        $add_expr->set_rhs($rhs);
        $expr = $add_expr;
    }
    
    return $expr;
}

sub _multiplicative_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _multiplicative_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _unary_expr($self, $tokens);
    while (_match($self, $tokens, '(\\*|div|mod)')) {
        my $mult_expr = Tree::XPathEngine::Expr->new($self);
        $mult_expr->set_lhs($expr);
        $mult_expr->set_op($self->{_curr_match});
        
        my $rhs = _unary_expr($self, $tokens);
        
        $mult_expr->set_rhs($rhs);
        $expr = $mult_expr;
    }
    
    return $expr;
}

sub _unary_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _unary_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    if (_match($self, $tokens, '-')) {
        my $expr = Tree::XPathEngine::Expr->new($self);
        $expr->set_lhs(Tree::XPathEngine::Number->new(0));
        $expr->set_op('-');
        $expr->set_rhs(_unary_expr($self, $tokens));
        return $expr;
    }
    else {
        return _union_expr($self, $tokens);
    }
}

sub _union_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _union_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _path_expr($self, $tokens);
    while (_match($self, $tokens, '\\|')) {
        my $un_expr = Tree::XPathEngine::Expr->new($self);
        $un_expr->set_lhs($expr);
        $un_expr->set_op('|');
        
        my $rhs = _path_expr($self, $tokens);
        
        $un_expr->set_rhs($rhs);
        $expr = $un_expr;
    }
    
    return $expr;
}

sub _path_expr {
    my ($self, $tokens) = @_;

    _debug( "in _path_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    # _path_expr is _location_path | _filter_expr | _filter_expr '//?' _relative_location_path
    
    # Since we are being predictive we need to find out which function to call next, then.
        
    # LocationPath either starts with "/", "//", ".", ".." or a proper Step.
    
    my $expr = Tree::XPathEngine::Expr->new($self);
    
    my $test = $tokens->[$self->{_tokpos}];
    
    # Test for AbsoluteLocationPath and AbbreviatedRelativeLocationPath
    if ($test =~ /^(\/\/?|\.\.?)$/) {
        # LocationPath
        $expr->set_lhs(_location_path($self, $tokens));
    }
    # Test for AxisName::...
    elsif (_is_step($self, $tokens)) {
        $expr->set_lhs(_location_path($self, $tokens));
    }
    else {
        # Not a LocationPath
        # Use _filter_expr instead:
        
        $expr = _filter_expr($self, $tokens);
        if (_match($self, $tokens, '//?')) { 
            my $loc_path = Tree::XPathEngine::LocationPath->new();
            push @$loc_path, $expr;
            if ($self->{_curr_match} eq '//') {
                push @$loc_path, Tree::XPathEngine::Step->new($self, 'descendant-or-self', 
                                        Tree::XPathEngine::Step::test_nt_node() );
            }
            push @$loc_path, _relative_location_path($self, $tokens);
            my $new_expr = Tree::XPathEngine::Expr->new($self);
            $new_expr->set_lhs($loc_path);
            return $new_expr;
        }
    }
    
    return $expr;
}

sub _filter_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _filter_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = _primary_expr($self, $tokens);
    while (_match($self, $tokens, '\\[')) {
        # really PredicateExpr...
        $expr->push_predicate(_expr($self, $tokens));
        _match($self, $tokens, '\\]', 1);
    }
    
    return $expr;
}

sub _primary_expr {
    my ($self, $tokens) = @_;

    _debug( "in _primary_expr\n") if( $Tree::XPathEngine::DEBUG);
    
    my $expr = Tree::XPathEngine::Expr->new($self);
    
    if (_match($self, $tokens, $LITERAL)) {
        # new Literal with $self->{_curr_match}...
        $self->{_curr_match} =~ m/^(["'])(.*)\1$/;
        $expr->set_lhs(Tree::XPathEngine::Literal->new($2));
    }
    elsif (_match($self, $tokens, "$REGEXP_RE$REGEXP_MOD_RE?")) {
        # new Literal with $self->{_curr_match} turned into a regexp... 
        my( $regexp, $mod)= $self->{_curr_match} =~  m{($REGEXP_RE)($REGEXP_MOD_RE?)};
        $regexp=~ s{^m?s*/}{};
        $regexp=~ s{/$}{};                        
        if( $mod) { $regexp=~ "(?$mod:$regexp)"; } # move the mods inside the regexp
        $expr->set_lhs(Tree::XPathEngine::Literal->new($regexp));
    }
    elsif (_match($self, $tokens, $NUMBER_RE)) {
        # new Number with $self->{_curr_match}...
        $expr->set_lhs(Tree::XPathEngine::Number->new($self->{_curr_match}));
    }
    elsif (_match($self, $tokens, '\\(')) {
        $expr->set_lhs(_expr($self, $tokens));
        _match($self, $tokens, '\\)', 1);
    }
    elsif (_match($self, $tokens, "\\\$$self->{NAME}")) {
        # new Variable with $self->{_curr_match}...
        $self->{_curr_match} =~ /^\$(.*)$/;
        $expr->set_lhs(Tree::XPathEngine::Variable->new($self, $1));
    }
    elsif (_match($self, $tokens, $self->{NAME})) {
        # check match not Node_Type - done in lexer...
        # new Function
        my $func_name = $self->{_curr_match};
        _match($self, $tokens, '\\(', 1);
        $expr->set_lhs(
                Tree::XPathEngine::Function->new(
                    $self,
                    $func_name,
                    _arguments($self, $tokens)
                )
            );
        _match($self, $tokens, '\\)', 1);
    }
    else {
        die "Not a _primary_expr at ", $tokens->[$self->{_tokpos}], "\n";
    }
    
    return $expr;
}

sub _arguments {
    my ($self, $tokens) = @_;
    
    _debug( "in _arguments\n") if( $Tree::XPathEngine::DEBUG);
    
    my @args;
    
    if($tokens->[$self->{_tokpos}] eq ')') {
        return \@args;
    }
    
    push @args, _expr($self, $tokens);
    while (_match($self, $tokens, ',')) {
        push @args, _expr($self, $tokens);
    }
    
    return \@args;
}

sub _location_path {
    my ($self, $tokens) = @_;

    _debug( "in _location_path\n") if( $Tree::XPathEngine::DEBUG);
    
    my $loc_path = Tree::XPathEngine::LocationPath->new();
    
    if (_match($self, $tokens, '/')) {
        # root
        _debug("h: Matched root\n") if( $Tree::XPathEngine::DEBUG);
        push @$loc_path, Tree::XPathEngine::Root->new();
        if (_is_step($self, $tokens)) {
            _debug("Next is step\n") if( $Tree::XPathEngine::DEBUG);
            push @$loc_path, _relative_location_path($self, $tokens);
        }
    }
    elsif (_match($self, $tokens, '//')) {
        # root
        push @$loc_path, Tree::XPathEngine::Root->new();
        my $optimised = _optimise_descendant_or_self($self, $tokens);
        if (!$optimised) {
            push @$loc_path, Tree::XPathEngine::Step->new($self, 'descendant-or-self',
                                Tree::XPathEngine::Step::test_nt_node);
            push @$loc_path, _relative_location_path($self, $tokens);
        }
        else {
            push @$loc_path, $optimised, _relative_location_path($self, $tokens);
        }
    }
    else {
        push @$loc_path, _relative_location_path($self, $tokens);
    }
    
    return $loc_path;
}

sub _optimise_descendant_or_self {
    my ($self, $tokens) = @_;
    
    _debug( "in _optimise_descendant_or_self\n") if( $Tree::XPathEngine::DEBUG);
    
    my $tokpos = $self->{_tokpos};
    
    # // must be followed by a Step.
    if ($tokens->[$tokpos+1] && $tokens->[$tokpos+1] eq '[') {
        # next token is a predicate
        return;
    }
    elsif ($tokens->[$tokpos] =~ /^\.\.?$/) {
        # abbreviatedStep - can't optimise.
        return;
    }                                                                                              
    else {
        _debug("Trying to optimise //\n") if( $Tree::XPathEngine::DEBUG);
        my $step = _step($self, $tokens);
        if ($step->{axis} ne 'child') {
            # can't optimise axes other than child for now...
            $self->{_tokpos} = $tokpos;
            return;
        }
        $step->{axis} = 'descendant';
        $step->{axis_method} = 'axis_descendant';
        $self->{_tokpos}--;
        $tokens->[$self->{_tokpos}] = '.';
        return $step;
    }
}

sub _relative_location_path {
    my ($self, $tokens) = @_;
    
    _debug( "in _relative_location_path\n") if( $Tree::XPathEngine::DEBUG);
    
    my @steps;
    
    push @steps,_step($self, $tokens);
    while (_match($self, $tokens, '//?')) {
        if ($self->{_curr_match} eq '//') {
            my $optimised = _optimise_descendant_or_self($self, $tokens);
            if (!$optimised) {
                push @steps, Tree::XPathEngine::Step->new($self, 'descendant-or-self',
                                        Tree::XPathEngine::Step::test_nt_node);
            }
            else {
                push @steps, $optimised;
            }
        }
        push @steps, _step($self, $tokens);
        if (@steps > 1 && 
                $steps[-1]->{axis} eq 'self' && 
                $steps[-1]->{test} == Tree::XPathEngine::Step::test_nt_node) {
            pop @steps;
        }
    }
    
    return @steps;
}

sub _step {
    my ($self, $tokens) = @_;

    _debug( "in _step\n") if( $Tree::XPathEngine::DEBUG);
    
    if (_match($self, $tokens, '\\.')) {
        # self::node()
        return Tree::XPathEngine::Step->new($self, 'self', Tree::XPathEngine::Step::test_nt_node);
    }
    elsif (_match($self, $tokens, '\\.\\.')) {
        # parent::node()
        return Tree::XPathEngine::Step->new($self, 'parent', Tree::XPathEngine::Step::test_nt_node);
    }
    else {
        # AxisSpecifier NodeTest Predicate(s?)
        my $token = $tokens->[$self->{_tokpos}];
        
        _debug("p: Checking $token\n") if( $Tree::XPathEngine::DEBUG);
        
        my $step;
        if ($token =~ /^\@($self->{NAME}|$WILD)$/) {
            $self->{_tokpos}++;
                        if ($token eq '@*') {
                            $step = Tree::XPathEngine::Step->new($self,
                                    'attribute',
                                    Tree::XPathEngine::Step::test_attr_any,
                                    '*');
                        }
                        elsif ($token =~ /^\@($self->{NAME})$/) {
                            $step = Tree::XPathEngine::Step->new($self,
                                    'attribute',
                                    Tree::XPathEngine::Step::test_attr_name,
                                    $1);
                        }
        }
        elsif ($token =~ /^$WILD$/) { # *
            $self->{_tokpos}++;
            $step = Tree::XPathEngine::Step->new($self, 'child', 
                                Tree::XPathEngine::Step::test_any,
                                $token);
        }
        elsif ($token =~ /^$self->{NAME}$/) { # name:name
            $self->{_tokpos}++;
            $step = Tree::XPathEngine::Step->new($self, 'child', 
                                Tree::XPathEngine::Step::test_name,
                                $token);
        }
        elsif ($token eq 'text()') {
            $self->{_tokpos}++;
            $step = Tree::XPathEngine::Step->new($self, 'child',
                    Tree::XPathEngine::Step::test_nt_text);
        }
        elsif ($token eq 'node()') {
            $self->{_tokpos}++;
            $step = Tree::XPathEngine::Step->new($self, 'child',
                    Tree::XPathEngine::Step::test_nt_node);
        }
        elsif ($token =~ /^($AXIS_NAME)($self->{NAME}|$WILD|$NODE_TYPE)$/) {
                    my $axis = substr( $1, 0, -2);
                    $self->{_tokpos}++;
                    $token = $2;
            if ($token =~ /^$WILD$/) { # *
                $step = Tree::XPathEngine::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ?
                                    Tree::XPathEngine::Step::test_attr_any
                                        :
                                    Tree::XPathEngine::Step::test_any),
                                    $token);
            }
            elsif ($token =~ /^$self->{NAME}$/) { # name:name
                $step = Tree::XPathEngine::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ?
                                    Tree::XPathEngine::Step::test_attr_name
                                        :
                                    Tree::XPathEngine::Step::test_name),
                                    $token);
            }
            elsif ($token eq 'text()') {
                $step = Tree::XPathEngine::Step->new($self, $axis,
                        Tree::XPathEngine::Step::test_nt_text);
            }
            elsif ($token eq 'node()') {
                $step = Tree::XPathEngine::Step->new($self, $axis,
                        Tree::XPathEngine::Step::test_nt_node);
            }
            else {
                die "Shouldn't get here";
            }
        }
        else {
            die "token $token doesn't match format of a 'Step'\n";
        }
        
        while (_match($self, $tokens, '\\[')) {
            push @{$step->{predicates}}, _expr($self, $tokens);
            _match($self, $tokens, '\\]', 1);
        }
        
        return $step;
    }
}

sub _is_step {
    my ($self, $tokens) = @_;
    
    my $token = $tokens->[$self->{_tokpos}];
    
    return unless defined $token;
        
    _debug("p: Checking if '$token' is a step\n") if( $Tree::XPathEngine::DEBUG);
    
    local $^W=0;
        
    if(   ($token eq 'processing-instruction') 
       || ($token =~ /^\@($self->{NAME}|$WILD)$/)
       || (    ($token =~ /^($self->{NAME}|$WILD)$/ )
            && ( ($tokens->[$self->{_tokpos}+1] || '') ne '(') )
       || ($token =~ /^$NODE_TYPE$/)
       || ($token =~ /^$AXIS_NAME($self->{NAME}|$WILD|$NODE_TYPE)$/)
      )
      { return 1; }
    else
      { _debug("p: '$token' not a step\n") if( $Tree::XPathEngine::DEBUG);
        return;
      }
}

sub _debug {
    
    my ($pkg, $file, $line, $sub) = caller(1);
    
    $sub =~ s/^$pkg\:://;
    
    while (@_) {
        my $x = shift;
        $x =~ s/\bPKG\b/$pkg/g;
        $x =~ s/\bLINE\b/$line/g;
        $x =~ s/\bg\b/$sub/g;
        print STDERR $x;
    }
}


__END__

=head1 NAME

Tree::XPathEngine - a re-usable XPath engine

=head1 DESCRIPTION

This module provides an XPath engine, that can be re-used by other
module/classes that implement trees.

It is designed to be compatible with L<Class::XPath>, ie it passes its
tests if you replace Class::XPath by Tree::XPathEngine.


This code is a more or less direct copy of the L<XML::XPath> module by
Matt Sergeant. I only removed the XML processing part (that parses an XML
document and load it as a tree in memory) to remove the dependency
on XML::Parser, applied a couple of patches, removed a whole bunch of XML
specific things (comment, processing inistructions, namespaces...), 
renamed a whole lot of methods to make Pod::Coverage happy, and changed 
the docs.

The article eXtending XML XPath, http://www.xmltwig.com/article/extending_xml_xpath/
should give authors who want to use this module enough background to do so.

Otherwise, my email is below ;--)

B<WARNING>: while the underlying code is rather solid, this module most likely
lacks docs.

As they say, "patches welcome"... but I am also interested in any experience 
using this module, what were the tricky parts, and how could the code or the 
docs be improved.

=head1 SYNOPSIS

    use Tree::XPathEngine;
    
    my $tree= my_tree->new( ...);
    my $xp = Tree::XPathEngine->new();
    
    my @nodeset = $xp->find('/root/kid/grankid[1]'); # find all first grankids

    package tree;

    # needs to provide these methods
    sub xpath_get_name              { ... }
    sub xpath_get_next_sibling      { ... }
    sub xpath_get_previous_sibling  { ... }
    sub xpath_get_root_node         { ... }
    sub xpath_get_parent_node       { ... }
    sub xpath_get_child_nodes       { ... }
    sub xpath_is_element_node       { return 1; }
    sub xpath_cmp                   { ... }
    sub xpath_get_attributes        { ... } # only if attributes are used
    sub xpath_to_literal            { ... } # only if you want to use findnodes_as_string or findvalue
    

=head1 DETAILS

=head1 API

The API of Tree::XPathEngine itself is extremely simple to allow you to get
going almost immediately. The deeper API's are more complex, but you
shouldn't have to touch most of that.

=head2 new %options

=head3 options

=over 4

=item xpath_name_re

a regular expression used to match names (node names or attribute names)
by default it is qr/[A-Za-z_][\w.-]*/ in order to work under perl 5.6.n,
but you might want to use something like qr/\p{L}[\w.-]*/ in 5.8.n, to 
accomodate letter outside of the ascii range.

=back


=head2 findnodes ($path, $context)

Returns a list of nodes found by C<$path>, in context C<$context>. 
In scalar context returns an C<Tree::XPathEngine::NodeSet> object.

=head2 findnodes_as_string ($path, $context)

Returns the text values of the nodes 

=head2 findvalue ($path, $context)

Returns either a C<Tree::XPathEngine::Literal>, a C<Tree::XPathEngine::Boolean>
or a C<Tree::XPathEngine::Number> object. If the path returns a NodeSet,
$nodeset->xpath_to_literal is called automatically for you (and thus a
C<Tree::XPathEngine::Literal> is returned). Note that
for each of the objects stringification is overloaded, so you can just
print the value found, or manipulate it in the ways you would a normal
perl value (e.g. using regular expressions).

=head2 exists ($path, $context)

Returns true if the given path exists.

=head2 matches($node, $path, $context)

Returns true if the node matches the path.

=head2 find ($path, $context)

The find function takes an XPath expression (a string) and returns either a
Tree::XPathEngine::NodeSet object containing the nodes it found (or empty if
no nodes matched the path), or one of Tree::XPathEngine::Literal (a string),
Tree::XPathEngine::Number, or Tree::XPathEngine::Boolean. It should always 
return something - and you can use ->isa() to find out what it returned. If 
you need to check how many nodes it found you should check $nodeset->size.
See L<Tree::XPathEngine::NodeSet>. 

=head2 XPath variables

XPath lets you use variables in expressions (see the XPath spec:
L<http://www.w3.org/TR/xpath>). 

=over 4

=item set_var ($var_name, $val)

sets the variable C<$var_name> to val

=item get_var ($var_name)

get the value of the variable (there should be no need to use this method from
outside the module, but it looked silly to have C<set_var> and C<_get_var>).

=back

=head1 How to use this module

The purpose of this module is to add XPah support to generic tree modules.

It works by letting you create a Tree::XPathEngine object, that will be called
to resolve XPath queries on a context. The context is a node (or a list of
nodes) in a tree.

The tree should share some characteristics with a XML tree: it is made of nodes,
there are 2 kinds of nodes, document (the whole tree, the root of the tree is 
a child of this node), elements(regular nodes in the tree) and attributes. 

Nodes in the tree are expected to provide methods that will be called by the
XPath engine to resolve the query. Not all of the possible methods need be 
available, depending on the type of XPath queries that need to be supported: 
for example if the nodes do not have a text value then there is no need for a
C<string_value> method, and XPath queries cannot include the C<string()> 
function (using it will trigger a B<runtime> error).

Most of the expected methods are usual methods for a tree module, so it should
not be too difficult to implement them, by aliasing existing methods to the 
required ones.

Just in case, here is a fast way to alias for example your own C<parent> method
to the C<get_parent_node> needed by Tree::XPathEngine:

  *get_parent_node= *parent; # in the node package

The XPath engine expects the whole tree and attributes to be full blown objects,
which provide a set of methods similar to nodes. If they are not, see below for
ways to "fake" it.

=head2 Methods to be provided by the nodes

=over 4

=item xpath_get_name              

returns the name of the node.

Not used for the document.

=item xpath_string_value

The text corresponding to the node, used by the C<string()> function (for 
queries like C<//foo[string()="bar"]>)

=item xpath_get_next_sibling      

=item xpath_get_previous_sibling  

=item xpath_get_root_node         

returns the document object. see L<Document object> below for more details. 

=item xpath_get_parent_node       

The parent of the root of the tree is the document node.

The parent of an attribute is its element.

=item xpath_get_child_nodes       

returns a list of children.

note that the attributes are not children of an element

=item xpath_is_element_node       

=item xpath_is_document_node       

=item xpath_is_attribute_node       

=item xpath_is_text_node 

only if the tree includes textual nodes

=item xpath_to_string

returns the node as a string

=item xpath_to_number

returns the node value as a number object

  sub xpath_to_number
    { return XML::XPath::Number->new( $_[0]->xpath_string_value); }

=item xpath_cmp ($node_a, $node_b)             

compares 2 nodes and returns -1, 0 or 1 depending on whether C<$a_node> is
before, equal to or after C<$b_node> in the tree.

This is needed in order to return sorted results and to remove duplicates.

See L<Ordering nodesets> below for a ready-to-use sorting method if your 
tree does not have a C<cmp> method

=back

=head2 Element specific methods

=over 4

=item xpath_get_attributes        

returns the list of attributes, attributes should be objects that support
the following methods:

=back

=head1 Tricky bits

=head2 Document object

The original XPath works on XML, and is roughly speaking based on the DOM
model of an XML document. As far as the XPath engine is concerned, it still
deals with a DOM tree.

One of the possibly annoying consequences is that in the DOM the document
itself is a node, that has a single element child, the root of the document
tree. If the tree you want to use this module on doesn't follow that model,
if its root element B<is> the tree itself, then you will have to fake it.

This is how I did it in L<Tree::DAG_Node::XPath>:

  # in package Tree::DAG_Node::XPath
  sub xpath_get_root_node
  { my $node= shift;
    # The parent of root is a Tree::DAG_Node::XPath::Root
    # that helps getting the tree to mimic a DOM tree
    return $node->root->xpath_get_parent_node; 
  }

  sub xpath_get_parent_node
    { my $node= shift;
  
      return    $node->mother # normal case, any node but the root
                # the root parent is a Tree::DAG_Node::XPath::Root object
                # which contains the reference of the (real) root node
             || bless { root => $node }, 'Tree::DAG_Node::XPath::Root'; 
    }

  # class for the fake root for a tree
  package Tree::DAG_Node::XPath::Root;

    
  sub xpath_get_child_nodes   { return ( $_[0]->{root}); }
  sub address                 { return -1; } # the root is before all other nodes
  sub xpath_get_attributes    { return []  }
  sub xpath_is_document_node  { return 1   }
  sub xpath_is_element_node   { return 0   }
  sub xpath_is_attribute_node { return 0   }

=head2 Attribute objects

If the attributes in the original tree are not objects, but simple fields in
a hash, you can generate objects on the fly:

  # in the element package
  sub xpath_get_attributes
    { my $elt= shift;
      my $atts= $elt->attributes; # returns a reference to a hash of attributes
      my $rank=-1;                # used for sorting
      my @atts= map { bless( { name => $_, value => $atts->{$_}, elt => $elt, rank => $rank -- }, 
                             'Tree::DAG_Node::XPath::Attribute') 
                    }
                     sort keys %$atts; 
      return @atts;
    }

  # the attribute package
  package Tree::DAG_Node::XPath::Attribute;
  use Tree::XPathEngine::Number;

  # not used, instead get_attributes in Tree::DAG_Node::XPath directly returns an
  # object blessed in this class
  #sub new
  #  { my( $class, $elt, $att)= @_;
  #    return bless { name => $att, value => $elt->att( $att), elt => $elt }, $class;
  #  }
  
  sub xpath_get_value         { return $_[0]->{value}; }
  sub xpath_get_name          { return $_[0]->{name} ; }
  sub xpath_string_value      { return $_[0]->{value}; }
  sub xpath_to_number         { return Tree::XPathEngine::Number->new( $_[0]->{value}); }
  sub xpath_is_document_node  { 0 }
  sub xpath_is_element_node   { 0 }
  sub xpath_is_attribute_node { 1 }
  sub to_string         { return qq{$_[0]->{name}="$_[0]->{value}"}; }

  # Tree::DAG_Node uses the address field to sort nodes, which simplifies things quite a bit
  sub xpath_cmp { $_[0]->address cmp $_[1]->address }
  sub address  
    { my $att= shift;
      my $elt= $att->{elt};
      return $elt->address . ':' . $att->{rank};
    }

=head2 Ordering nodesets

XPath query results must be sorted, and duplicates removed, so the XPath engine
needs to be able to sort nodes.

I does so by calling the C<cmp> method on nodes.

One of the easiest way to write such a method, for static trees, is to have a
method of the object return its position in the tree as a number.

If that is not possible, here is a method that should work (note that it only
compares elements):

 # in the tree element package
 
  sub xpath_cmp($$) 
    { my( $a, $b)= @_;
      if( UNIVERSAL::isa( $b, $ELEMENT))       # $ELEMENT is the tree element class
        { # 2 elts, compare them
				  return $a->elt_cmp( $b);
	      }
      elsif( UNIVERSAL::isa( $b, $ATTRIBUTE))  # $ATTRIBUTE is the attribute class
        { # elt <=> att, compare the elt to the att->{elt}
				  # if the elt is the att->{elt} (cmp return 0) then -1, elt is before att
          return ($a->elt_cmp( $b->{elt}) ) || -1 ;
        }
      elsif( UNIVERSAL::isa( $b, $TREE))        # $TREE is the tree class
        { # elt <=> document, elt is after document
				  return 1;
        } 
      else
        { die "unknown node type ", ref( $b); }
    }

 
  sub elt_cmp
    { my( $a, $b)=@_;

      # easy cases
      return  0 if( $a == $b);    
      return  1 if( $a->in($b)); # a starts after b 
      return -1 if( $b->in($a)); # a starts before b

      # ancestors does not include the element itself
      my @a_pile= ($a, $a->ancestors); 
      my @b_pile= ($b, $b->ancestors);

      # the 2 elements are not in the same twig
      return undef unless( $a_pile[-1] == $b_pile[-1]);

      # find the first non common ancestors (they are siblings)
      my $a_anc= pop @a_pile;
      my $b_anc= pop @b_pile;

      while( $a_anc == $b_anc) 
        { $a_anc= pop @a_pile;
          $b_anc= pop @b_pile;
        }

      # from there move left and right and figure out the order
      my( $a_prev, $a_next, $b_prev, $b_next)= ($a_anc, $a_anc, $b_anc, $b_anc);
      while()
        { $a_prev= $a_prev->_prev_sibling || return( -1);
          return 1 if( $a_prev == $b_next);
          $a_next= $a_next->_next_sibling || return( 1);
          return -1 if( $a_next == $b_prev);
          $b_prev= $b_prev->_prev_sibling || return( 1);
          return -1 if( $b_prev == $a_next);
          $b_next= $b_next->_next_sibling || return( -1);
          return 1 if( $b_next == $a_prev);
        }
    }

  sub in
    { my ($self, $ancestor)= @_;
      while( $self= $self->xpath_get_parent_node) { return $self if( $self ==  $ancestor); } 
    }

  sub ancestors
    { my( $self)= @_;
      while( $self= $self->xpath_get_parent_node) { push @ancestors, $self; }
      return @ancestors;
    }

  # in the attribute package
  sub xpath_cmp($$) 
    { my( $a, $b)= @_;
      if( UNIVERSAL::isa( $b, $ATTRIBUTE)) 
        { # 2 attributes, compare their elements, then their name 
          return ($a->{elt}->elt_cmp( $b->{elt}) ) || ($a->{name} cmp $b->{name});
        }
      elsif( UNIVERSAL::isa( $b, $ELEMENT))
        { # att <=> elt : compare the att->elt and the elt
          # if att->elt is the elt (cmp returns 0) then 1 (elt is before att)
          return ($a->{elt}->elt_cmp( $b) ) || 1 ;
        }
      elsif( UNIVERSAL::isa( $b, $TREE))
        { # att <=> document, att is after document 
          return 1;
        }
      else
        { die "unknown node type ", ref( $b); }
    }

  

=head1 XPath extension

The module supports the XPath recommendation to the same extend as XML::XPath 
(that is, rather completely).

It includes a perl-specific extension: direct support for regular expressions.

You can use the usual (in Perl!) C<=~> and C<!~> operators. Regular expressions 
are / delimited (no other delimiter is accepted, \ inside regexp must be 
backslashed), the C<imsx> modifiers can be used. 

  $xp->findnodes( '//@att[.=~ /^v.$/]'); # returns the list of attributes att
                                         # whose value matches ^v.$

=head1 TODO

provide inheritable node and attribute classes for typical cases, starting with
nodes where the root IS the tree, and where attributes are a simple hash (similar
to what I did in L<Tree::DAG_Node>).

better docs (patches welcome).

=head1 SEE ALSO

L<Tree::DAG_Node::XPath> for an exemple of using this module

L<http://www.xmltwig.com/article/extending_xml_xpath/ > for background information

L<Class::XPath>, which is probably easier to use, but at this point supports much
less of XPath that Tree::XPathEngine.

=head1 AUTHOR

Michel Rodriguez, C<< <mirod@cpan.org> >>

This code is heavily based on the code for L<XML::XPath> by Matt Sergeant
copyright 2000 Axkit.com Ltd 


=head1 BUGS

Please report any bugs or feature requests to
C<bug-tree-xpathengine@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tree-XPathEngine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

XML::XPath Copyright 2000-2004 AxKit.com Ltd.
Copyright 2006 Michel Rodriguez, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Tree::XPathEngine

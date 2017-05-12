# IfNode -- if-then-else construct
# condition (expressionNode ref): condition expression
# if_body (array ref): template to be executed on true (Node stack)
# else_body (array ref): templates to be executed on false (Node stack)
#
package Text::PORE::Node::If;

use Text::PORE::Node::Attr;
use Text::PORE::Node;
use English;
use strict;

@Text::PORE::Node::If::ISA = qw(Text::PORE::Node::Attr);

sub new {
    my $type = shift;
    my $lineno = shift;
    my $attrs = shift;
    my $then = shift;
    my $else = shift;

    my $self = bless {}, ref($type) || $type;

    $self = $self->SUPER::new($lineno, 'if', $attrs);

    $self->{'if_body'} = $then;
    $self->{'else_body'} = $else || new Text::PORE::Node($lineno);;

    bless $self, ref($type) || $type;
}

sub traverse {
    my $self = shift;
    my $globals = shift;

    my $context = $globals->GetAttribute('_context');
    my $result;
    my $return;

    $result = $self->evaluate($globals);

    $self->output("[IF:$self->{'lineno'}]") if $self->getDebug();

    # note - in other places, we load the error messages directly,
    #  but the syntax here would just get too confusing
    $return = $self->{$result ? 'if_body' : 'else_body'}->
	traverse($globals);

    $self->error($return);

    return $self->errorDump();
}

sub evaluate {
    my $self = shift;
    my $globals = shift;

    my $expr;
    my $return;

    # parse the condition into a perl expression
    $expr = $self->format_expr_for_perl($globals);
    #print STDERR "[$expr]\n";
    # evaluate the expression
    $return = eval ($expr);
    #print STDERR "return = [$return]\n";

    if ($EVAL_ERROR) {
	$self->error("Expression evaluation error:\n".
		     "\tMessage:    [$EVAL_ERROR]\n".
		     "\tExpression: [$expr]\n".
		     "\tContext:    [".
		     $globals->GetAttribute('_context')."]\n");
    }

    $return;
}

sub format_expr_for_perl {
    my $self = shift;
    my $globals = shift;

    my ($expr) = $self->{'attrs'}{'cond'};
    my (@expr_list);

    # Tokenize expression and check for correctness

  LOOP:
    while ($expr) {
	$expr =~ s/^\s+//;

	$_ = $expr;

      SWITCH: {
	  s/^([\'\"])(([^\\]|\\.)*?)\1// && do {    # Match constant
	      push @expr_list, $MATCH;
	      last SWITCH;
	  };
	  s/^([\.\w]+)// && do {                    # Match attribute
	      push @expr_list, $MATCH;
	      last SWITCH;
	  };
	  s/^(>=|<=|!=)// && do {                   # Match two-char operator
	      push @expr_list, $MATCH;
	      last SWITCH;
	  };
	  s/^[<>()+\-*\/\%]// && do {       # Match one-char operator
					    # < > ( ) + - * / %
	      push @expr_list, $MATCH;
	      last SWITCH;
	  };
	  s/^=// && do {                            # Match equals
	      push @expr_list, "==";
	      last SWITCH;
	  };
	  $self->error("Expression syntax error at [$expr]");
	  last LOOP;
      }

	$expr = $_;
    }


    #  Replace expression elements to translate to Perl
    # TODO - should combine this switch and the last for efficiency

    my $i;
    my $case_insensitive = 0;
    my $lc;

    for ($i=0; $i <= $#expr_list; $i++) {

	# NOTE - we want BOTH $_ and $lc for the following switch
	#  for purposes of efficiency
	$_ = $expr_list[$i];
	$lc = lc($_);

	# NOTE - arithmetic and inequality operators fall through
      SWITCH: {
	  ($lc eq 'and') && do {            # And
	      $expr_list[$i] = '&&'; last SWITCH;
	  };
	  ($lc eq 'or') && do {             # Or
	      $expr_list[$i] = '||'; last SWITCH;
	  };
	  ($lc eq 'not') && do {            # Not
	      $expr_list[$i] = '!'; last SWITCH;
	  };
	  ($lc eq 'eq') && do {             # Case-insensitive stirng equality
	      $expr_list[$i] = '=~'; 
	      $case_insensitive = 1;
	      last SWITCH;
	  };
	  ($lc eq 'eqs') && do {            # Case-sensitive string equality
	      $expr_list[$i] = 'eq'; last SWITCH;
	  };
	  /^([\'\"])(.*)\1$/ && do {     # Match constant
	      my $str = ($case_insensitive ? "/^$2\$\/i" : $MATCH);
	      $expr_list[$i] = $str; 
	      $case_insensitive = 0;
	      last SWITCH;
	  };
	  /^([\.\w]+)$/i && do {      # Slots
	      my $attr = $MATCH;

			### Modified by Zhengrong Tang to escape non-word chars.
			### Otherwise, eval() would generate warning messages
			### when slot value contains $, @, %, etc.
              my $slot_value = $self->retrieveSlot($globals, $attr);
              $slot_value =~ s/(\W)/\\$1/g;     # escape all non-word chars

	      $expr_list[$i] = "qq(". $slot_value . ")";
	      last SWITCH;
	  };
	      
      }
    }

    # Put expression back together into one string

    $expr = join(" ", @expr_list);
    return $expr;
}


1;

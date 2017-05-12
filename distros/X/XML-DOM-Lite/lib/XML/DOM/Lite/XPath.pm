package XML::DOM::Lite::XPath;

use XML::DOM::Lite::NodeList;
use XML::DOM::Lite::Constants qw(:nodeTypes);

#============ Innter Packages ============
package XML::DOM::Lite::XPath::ExprContext;

sub new {
  my ($class, $node, $position, $nodelist, $parent) = @_;
  return bless {
    node => $node,
    position => $position,
    nodelist => $nodelist,
    variables => { },
    parent => $parent,
    root => $parent ? $parent->{root} : $node->ownerDocument
  }, $class;
}

sub clone {
  my ($self, $node, $position, $nodelist) = @_;
  return XML::DOM::Lite::XPath::ExprContext->new(
    defined $node ? $node : $self->{node},
    defined $position ? $position : $self->{position},
    defined $nodelist ? $nodelist : $self->{nodelist},
    $self);
}

sub setVariable {
  my ($self, $name, $value) = @_;
  $self->{variables}->{name} = $value;
}

sub getVariable {
  my ($self, $name) = @_;
  if (defined $self->{variables}->{name}) {
    return $self->{variables}->{name};

  } elsif ($self->{parent}) {
    return $self->{parent}->getVariable($name);

  } else {
    return undef;
  }
}

sub setNode {
  my ($self, $node, $position) = @_;
  $self->{node} = $node;
  $self->{position} = $position;
}

package XML::DOM::Lite::XPath::StringValue;
sub new {
  my ($class, $value) = @_;
  return bless {
    value => $value,
    type  => 'string',
  }, $class;
}

sub stringValue {
  return $_[0]->{value};
}

sub booleanValue {
  return length($_[0]->{value}) > 0;
}

sub numberValue {
  return $_[0]->{value} - 0;
}

sub nodeSetValue {
  die $_[0];
}

package XML::DOM::Lite::XPath::BooleanValue;
sub new {
  my ($class, $value) = @_;
  return bless {
    value => $value,
    type => 'boolean'
  }, $class;
}

sub stringValue {
  return ''.$_[0]->{value};
}

sub booleanValue {
  return $_[0]->{value};
}

sub numberValue {
  return $_[0]->{value} ? 1 : 0;
}

sub nodeSetValue {
  die $_[0] . ' ';
}

package XML::DOM::Lite::XPath::NumberValue;
sub new {
  my ($class, $value) = @_;
  return bless {
    value => $value,
    type => 'number'
  }, $class;
}

sub stringValue {
  return '' . $_[0]->{value};
}

sub booleanValue {
  return not not $_[0]->{value};
}

sub numberValue {
  return $_[0]->{value} - 0;
}

sub nodeSetValue {
  die $_[0] . ' ';
}

package XML::DOM::Lite::XPath::NodeSetValue;
sub new {
  my ($class, $value) = @_;
  return bless {
    value => $value,
    type => 'node-set'
  }, $class;
}

sub stringValue {
  if (@{$_[0]->{value}} == 0) {
    return '';
  } else {
    return XML::DOM::Lite::XPath::xmlValue($_[0]->{value}->[0]);
  }
}

sub booleanValue {
  return $_[0]->{value}->length > 0;
}

sub numberValue {
  return $_[0]->stringValue() - 0;
}

sub nodeSetValue {
  return $_[0]->{value};
}

package XML::DOM::Lite::XPath::TokenExpr;
sub new {
  my ($class, $m) = @_;
  return bless { value => $m }, $class;
}

sub evaluate {
  return XML::DOM::Lite::XPath::StringValue->new($_->{value});
}

package XML::DOM::Lite::XPath::LocationExpr;

sub new {
  my ($class) = @_;
  return bless {
    absolute => 0,
    steps => [ ],
  }, $class;
}

sub appendStep {
  push @{$_[0]->{steps}}, $_[1];
}

sub prependStep {
  unshift @{$_[0]->{steps}}, $_[1];
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $start;
  if ($self->{absolute}) {
    $start = $ctx->{root};

  } else {
    $start = $ctx->{node};
  }

  my $nodes = [];
  xPathStep($nodes, $self->{steps}, 0, $start, $ctx);
  return XML::DOM::Lite::XPath::NodeSetValue->new($nodes);
}

sub xPathStep {
  my ($nodes, $steps, $step, $input, $ctx) = @_;
  my $s = $steps->[$step];
  my $ctx2 = $ctx->clone($input);
  my $nodelist = $s->evaluate($ctx2)->nodeSetValue();

  for (my $i = 0; $i < @$nodelist; ++$i) {
    if ($step == @$steps - 1) {
      push @$nodes, $nodelist->[$i];
    } else {
      xPathStep($nodes, $steps, $step + 1, $nodelist->[$i], $ctx);
    }
  }
}

package XML::DOM::Lite::XPath::StepExpr;
use XML::DOM::Lite::Constants qw(:nodeTypes);
sub new {
  my ($class, $axis, $nodetest, $predicate) = @_;
  return bless {
    axis => $axis,
    nodetest => $nodetest,
    predicate => $predicate || [],
  }, $class;
}

sub appendPredicate {
  my ($self, $p) = @_;
  push(@{$self->{predicate}}, $p);
}

our $xpathAxis = {
  ANCESTOR_OR_SELF => 'ancestor-or-self',
  ANCESTOR => 'ancestor',
  ATTRIBUTE => 'attribute',
  CHILD => 'child',
  DESCENDANT_OR_SELF => 'descendant-or-self',
  DESCENDANT => 'descendant',
  FOLLOWING_SIBLING => 'following-sibling',
  FOLLOWING => 'following',
  NAMESPACE => 'namespace',
  PARENT => 'parent',
  PRECEDING_SIBLING => 'preceding-sibling',
  PRECEDING => 'preceding',
  SELF => 'self'
};

sub evaluate {
  my ($self, $ctx) = @_;
  my $input = $ctx->{node};
  my $nodelist = XML::DOM::Lite::NodeList->new([ ]);

  if ($self->{axis} eq  $xpathAxis->{ANCESTOR_OR_SELF}) {
    push @$nodelist, $input;
    for (my $n = $input->parentNode; $n; $n = $input->parentNode) {
      push @$nodelist, $n;
    }

  } elsif ($self->{axis} eq $xpathAxis->{ANCESTOR}) {
    for (my $n = $input->parentNode; $n; $n = $input->parentNode) {
      push @$nodelist, $n;
    }

  } elsif ($self->{axis} eq $xpathAxis->{ATTRIBUTE}) {
    @$nodelist = @{$input->attributes};
  
  } elsif ($self->{axis} eq $xpathAxis->{CHILD}) {
    @$nodelist = @{$input->childNodes};

  } elsif ($self->{axis} eq $xpathAxis->{DESCENDANT_OR_SELF}) {
    push @$nodelist, $input;
    XML::DOM::Lite::XPath::xpathCollectDescendants($nodelist, $input);

  } elsif ($self->{axis} eq $xpathAxis->{DESCENDANT}) {
    XML::DOM::Lite::XPath::xpathCollectDescendants($nodelist, $input);

  } elsif ($self->{axis} eq $xpathAxis->{FOLLOWING}) {
    for (my $n = $input->parentNode; $n; $n = $n->parentNode) {
      for (my $nn = $n->nextSibling; $nn; $nn = $nn->nextSibling) {
        push @$nodelist, $nn;
        XML::DOM::Lite::XPath::xpathCollectDescendants($nodelist, $nn);
      }
    }

  } elsif ($self->{axis} eq $xpathAxis->{FOLLOWING_SIBLING}) {
    for (my $n = $input->nextSibling; $n; $n = $input->nextSibling) {
      push @$nodelist, $n;
    }

  } elsif ($self->{axis} eq $xpathAxis->{NAMESPACE}) {
    warn('not implemented: axis namespace');

  } elsif ($self->{axis} eq $xpathAxis->{PARENT}) {
    if ($input->parentNode) {
      push(@$nodelist, $input->parentNode);
    }

  } elsif ($self->{axis} eq $xpathAxis->{PRECEDING}) {
    for (my $n = $input->parentNode; $n; $n = $n->parentNode) {
      for (my $nn = $n->previousSibling; $nn; $nn = $nn->previousSibling) {
        push(@$nodelist, $nn);
        XML::DOM::Lite::XPath::xpathCollectDescendantsReverse($nodelist, $nn);
      }
    }

  } elsif ($self->{axis} eq $xpathAxis->{PRECEDING_SIBLING}) {
    for (my $n = $input->previousSibling; $n; $n = $input->previousSibling) {
      push(@$nodelist, $n);
    }

  } elsif ($self->{axis} eq $xpathAxis->{SELF}) {
    push(@$nodelist, $input);

  } else {
    die 'ERROR -- NO SUCH AXIS: ' . $self->{axis};
  }

  my $nodelist0 = $nodelist;
  $nodelist = [];
  for (my $i = 0; $i < @$nodelist0; ++$i) {
    my $n = $nodelist0->[$i];
    if ($self->{nodetest}->evaluate($ctx->clone($n, $i, $nodelist0))->booleanValue()) {
      push(@$nodelist, $n);
    }
  }

  for (my $i = 0; $i < @{$self->{predicate}}; ++$i) {
    my $nodelist0 = $nodelist;
    $nodelist = [];
    for (my $ii = 0; $ii < @$nodelist0; ++$ii) {
      my $n = $nodelist0->[$ii];
      if ($self->{predicate}->[$i]->evaluate($ctx->clone($n, $ii, $nodelist0))->booleanValue()) {
        push(@$nodelist, $n);
      }
    }
  }

  return XML::DOM::Lite::XPath::NodeSetValue->new($nodelist);
};

package XML::DOM::Lite::XPath::NodeTestAny;
sub new {
  my $class = shift;
  return bless { value => XML::DOM::Lite::XPath::BooleanValue->new(1) }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  return $self->{value};
}

package XML::DOM::Lite::XPath::NodeTestElement;
use XML::DOM::Lite::Constants qw(:nodeTypes);
sub new { return bless { }, $_[0] }

sub evaluate {
  my ($self, $ctx) = @_;
  return XML::DOM::Lite::XPath::BooleanValue->new($ctx->{node}->{nodeType} == ELEMENT_NODE);
}

package XML::DOM::Lite::XPath::NodeTestText;
use XML::DOM::Lite::Constants qw(:nodeTypes);
sub new { return bless { }, $_[0] }

sub evaluate {
  my ($self, $ctx) = @_;
  return XML::DOM::Lite::XPath::BooleanValue->new($ctx->{node}->{nodeType} == TEXT_NODE);
}

package XML::DOM::Lite::XPath::NodeTestComment;
use XML::DOM::Lite::Constants qw(:nodeTypes);
sub new { return bless { }, $_[0] }

sub evaluate {
  my ($self, $ctx) = @_;
  return XML::DOM::Lite::XPath::BooleanValue->new($ctx->{node}->{nodeType} == COMMENT_NODE);
}

package XML::DOM::Lite::XPath::NodeTestPI;
use XML::DOM::Lite::Constants qw(:nodeTypes);
sub new {
  my ($class, $target) = @_;
  return bless { target => $target }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  return XML::DOM::Lite::XPath::BooleanValue->new($ctx->{node}->{nodeType} == PROCESSING_INSTRUCTION_NODE and
    (not $self->{target} or $ctx->{node}->{nodeName} eq $self->{target}));
}

package XML::DOM::Lite::XPath::NodeTestNC;
use XML::DOM::Lite::Constants qw(:nodeTypes);
sub new {
  my ($class, $nsprefix) = @_;
  return bless {
    nsprefix => $nsprefix,
    regex => qr/^$nsprefix:/,
  }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $n = $ctx->{node};
  return XML::DOM::Lite::XPath::BooleanValue->new($n->{nodeName} =~ /$self->{regex}/);
}

package XML::DOM::Lite::XPath::NodeTestName;
sub new {
  my ($class, $name) = @_;
  return bless {
    name => $name,
  }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $n = $ctx->{node};
  return XML::DOM::Lite::XPath::BooleanValue->new($n->{nodeName} eq $self->{name});
}

package XML::DOM::Lite::XPath::PredicateExpr;
sub new {
  my ($class, $expr) = @_;
  return bless { expr => $expr }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $v = $self->{expr}->evaluate($ctx);
  if ($v->{type} eq 'number') {
    return XML::DOM::Lite::XPath::BooleanValue->new($ctx->{position} == $v->numberValue() - 1);
  } else {
    return XML::DOM::Lite::XPath::BooleanValue->new($v->booleanValue());
  }
}

package XML::DOM::Lite::XPath::FunctionCallExpr;
require POSIX;
sub new {
  my ($class, $name) = @_;
  return bless { name => $name, args => [ ] }, $class;
}

sub appendArg {
  my ($self, $arg) = @_;
  push @{$self->{args}}, $arg;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $fn = '' . $self->{name}->{value};
  my $f = $self->xpathfunctions->{$fn};
  if ($f) {
    return $f->($self, $ctx);
  } else {
    warn('XPath NO SUCH FUNCTION ' . $fn);
    return XML::DOM::Lite::XPath::BooleanValue->new(0);
  }
}

sub round { return int($_[0] + .5 * ($_[0] <=> 0)) }

sub assert {
  my $b = shift;
  die 'assertion failed' unless $b;
}

sub xpathfunctions {
  return {
  'last'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 0);
    return XML::DOM::Lite::XPath::NumberValue->new(scalar(@{$ctx->{nodelist}}));
  },

  'position'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 0);
    return XML::DOM::Lite::XPath::NumberValue->new($ctx->{position} + 1);
  },

  'count'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $v = $self->{args}->[0]->evaluate($ctx);
    return XML::DOM::Lite::XPath::NumberValue->new(scalar(@{$v->nodeSetValue()}));
  },

  'id'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $e = $self->{args}->evaluate($ctx);
    my $ret = [];
    my $ids;
    if ($e->{type} eq 'node-set') {
      $ids = [];
      for (my $i = 0; $i < @$e; ++$i) {
        my $v = XML::DOM::Lite::XPath::xmlValue(split(/\s+/, $e->[$i]));
        push @$ids, @$v;
      }
    } else {
      $ids = [split(/\s+/, @$e)];
    }
    my $d = $ctx->{node}->ownerDocument;
    for (my $i = 0; $i < @$ids; ++$i) {
      my $n = $d->getElementById($ids->[$i]);
      if ($n) {
        push(@$ret, $n);
      }
    }
    return XML::DOM::Lite::XPath::NodeSetValue->new($ret);
  },

  'local-name'=> sub {
    warn('not implemented yet: XPath function local-name()');
  },

  'namespace-uri'=> sub {
    warn('not implemented yet: XPath function namespace-uri()');
  },

  'name'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1 or @{$self->{args}} == 0);
    my $n;
    if (@{$self->{args}} == 0) {
      $n = [ $ctx->{node} ];
    } else {
      $n = $self->{args}->[0]->evaluate($ctx)->nodeSetValue();
    }

    if (@$n == 0) {
      return XML::DOM::Lite::XPath::StringValue->new('');
    } else {
      return XML::DOM::Lite::XPath::StringValue->new($n->[0]->{nodeName});
    }
  },

  'string'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1 or @{$self->{args}} == 0);
    if (@{$self->{args}} == 0) {
      return XML::DOM::Lite::XPath::StringValue->new(XML::DOM::Lite::XPath::NodeSetValue->new([ $ctx->{node} ])->stringValue());
    } else {
      return XML::DOM::Lite::XPath::StringValue->new($self->{args}->[0]->evaluate($ctx)->stringValue());
    }
  },

  'concat'=> sub {
    my ($self, $ctx) = @_;
    my $ret = '';
    for (my $i = 0; $i < @{$self->{args}}; ++$i) {
      $ret += $self->{args}->[$i]->evaluate($ctx)->stringValue();
    }
    return XML::DOM::Lite::XPath::StringValue->new($ret);
  },

  'starts-with'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 2);
    my $s0 = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $s1 = $self->{args}->[1]->evaluate($ctx)->stringValue();
    return XML::DOM::Lite::XPath::BooleanValue->new(index($s0, $s1) == 0);
  },

  'contains'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 2);
    my $s0 = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $s1 = $self->{args}->[1]->evaluate($ctx)->stringValue();
    return XML::DOM::Lite::XPath::BooleanValue->new(index($s0, $s1) != -1);
  },

  'substring-before'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 2);
    my $s0 = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $s1 = $self->{args}->[1]->evaluate($ctx)->stringValue();
    my $i = index($s0, $s1);
    my $ret;
    if ($i == -1) {
      $ret = '';
    } else {
      $ret = substr($s0, 0, $i);
    }
    return XML::DOM::Lite::XPath::StringValue->new($ret);
  },

  'substring-after'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 2);
    my $s0 = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $s1 = $self->{args}->[1]->evaluate($ctx)->stringValue();
    my $i = index($s0, $s1);
    my $ret;
    if ($i == -1) {
      $ret = '';
    } else {
      $ret = substr($s0, $i + length($s1));
    }
    return XML::DOM::Lite::XPath::StringValue->new($ret);
  },

  'substring'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 2 or @{$self->{args}} == 3);
    my $s0 = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $s1 = $self->{args}->[1]->evaluate($ctx)->numberValue();
    my $ret;
    if (@{$self->{args}} == 2) {
      my $i1 = (0 <=> round($s1 - 1)) ? 0 : round($s1 - 1);
      $ret = substr($s0, $i1);

    } else {
      my $s2 = $self->{args}->[2]->evaluate($ctx)->numberValue();
      my $i0 = round($s1 - 1);
      my $i1 = (0 <=> $i0) ? 0 : $i0;
      my $i2 = round('%d', $s2) - (0 <=> -$i0) ? 0 : -$i0;
      $ret = substr($s0, $i1, $i2);
    }
    return XML::DOM::Lite::XPath::StringValue->new($ret);
  },

  'string-length'=> sub {
    my ($self, $ctx) = @_;
    my $s;
    if (@{$self->{args}} > 0) {
      $s = $self->{args}->[0]->evaluate($ctx)->stringValue();
    } else {
      $s = XML::DOM::Lite::XPath::NodeSetValue->new([ $ctx->{node} ])->stringValue();
    }
    return XML::DOM::Lite::XPath::NumberValue->new(length($s));
  },

  'normalize-space'=> sub {
    my ($self, $ctx) = @_;
    my $s;
    if (@{$self->{args}} > 0) {
      $s = $self->{args}->[0]->evaluate($ctx)->stringValue();
    } else {
      $s = XML::DOM::Lite::XPath::NodeSetValue->new([ $ctx->{node} ])->stringValue();
    }
    $s =~ s/^\s*//;
    $s =~ s/\s*$//;
    $s =~ s/\s+/ /g;
    return XML::DOM::Lite::XPath::StringValue->new($s);
  },

  'translate'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 3);
    my $s0 = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $s1 = $self->{args}->[1]->evaluate($ctx)->stringValue();
    my $s2 = $self->{args}->[2]->evaluate($ctx)->stringValue();

    for (my $i = 0; $i < length($s1); ++$i) {
      my $chr1 = substr($s1, $i, 1);
      my $chr2 = substr($s2, $i, 1);
      $s0 =~ s/$chr1/$chr2/g;
    }
    return XML::DOM::Lite::XPath::StringValue->new($s0);
  },

  'boolean'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    return XML::DOM::Lite::XPath::BooleanValue->new($self->{args}->[0]->evaluate($ctx)->booleanValue());
  },

  'not'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $ret = not $self->{args}->[0]->evaluate($ctx)->booleanValue();
    return XML::DOM::Lite::XPath::BooleanValue->new($ret);
  },

  'true'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 0);
    return XML::DOM::Lite::XPath::BooleanValue->new(1);
  },

  'false'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 0);
    return XML::DOM::Lite::XPath::BooleanValue->new(0);
  },

  'lang'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $lang = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $xmllang;
    my $n = $ctx->{node};
    while ($n && $n != $n->parentNode) {
      $xmllang = $n->getAttribute('xml:lang');
      if ($xmllang) {
        last;
      }
      $n = $n->parentNode;
    }
    if (not $xmllang) {
      return XML::DOM::Lite::XPath::BooleanValue->new(1);
    } else {
      my $re = qr/^$lang$/i;
      return XML::DOM::Lite::XPath::BooleanValue->new($xmllang =~ /$re/ or ($xmllang =~ s/_.*$//) =~ /$re/);
    }
  },

  'number'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1 || @{$self->{args}} == 0);

    if (@{$self->{args}} == 1) {
      return XML::DOM::Lite::XPath::NumberValue->new($self->{args}->[0]->evaluate($ctx)->numberValue());
    } else {
      return XML::DOM::Lite::XPath::NumberValue(XML::DOM::Lite::XPath::NodeSetValue->new([ $ctx->{node} ])->numberValue());
    }
  },

  'sum'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $n = $self->{args}->[0]->evaluate($ctx)->nodeSetValue();
    my $sum = 0;
    for (my $i = 0; $i < @$n; ++$i) {
      $sum .= XML::DOM::Lite::XPath::xmlValue($n->[$i]) - 0;
    }
    return XML::DOM::Lite::XPath::NumberValue->new($sum);
  },

  'floor'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $num = $self->{args}->[0]->evaluate($ctx)->numberValue();
    return XML::DOM::Lite::XPath::NumberValue->new(POSIX::floor($num));
  },

  'ceiling'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $num = $self->{args}->[0]->evaluate($ctx)->numberValue();
    return XML::DOM::Lite::XPath::NumberValue->new(POSIX::ceil($num));
  },

  'round'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 1);
    my $num = $self->{args}->[0]->evaluate($ctx)->numberValue();
    return XML::DOM::Lite::XPath::NumberValue->new(round($num));
  },

  'ext-join'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 2);
    my $nodes = $self->{args}->[0]->evaluate($ctx)->nodeSetValue();
    my $delim = $self->{args}->[0]->evaluate($ctx)->stringValue();
    my $ret = '';
    for (my $i = 0; $i < @$nodes; ++$i) {
      if ($ret) {
        $ret .= $delim;
      }
      $ret .= XML::DOM::Lite::XPath::xmlValue($nodes->[$i]);
    }
    return XML::DOM::Lite::XPath::StringValue->new($ret);
  },

  'ext-if'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} == 3);
    if ($self->{args}->[0]->evaluate($ctx)->booleanValue()) {
      return $self->{args}->[1]->evaluate($ctx);
    } else {
      return $self->{args}->[2]->evaluate($ctx);
    }
  },

  'ext-sprintf' => sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} >= 1);
    my $args = [];
    for (my $i = 0; $i < @{$self->{args}}; ++$i) {
      push(@$args, $self->{args}->[$i]->evaluate($ctx)->stringValue());
    }
    return XML::DOM::Lite::XPath::StringValue->new(sprintf(@$args));
  },

  'ext-cardinal'=> sub {
    my ($self, $ctx) = @_;
    assert(@{$self->{args}} >= 1);
    my $c = $self->{args}->[0]->evaluate($ctx)->numberValue();
    my $ret = [];
    for (my $i = 0; $i < $c; ++$i) {
      push(@$ret, $ctx->{node});
    }
    return XML::DOM::Lite::XPath::NodeSetValue->new($ret);
  }
  };
}

package XML::DOM::Lite::XPath::UnionExpr;
sub new {
  my ($class, $expr1, $expr2) = @_;
  return bless { expr1 => $expr1, expr2 => $expr2 }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $nodes1 = $self->{expr1}->evaluate($ctx)->nodeSetValue();
  my $nodes2 = $self->{expr2}->evaluate($ctx)->nodeSetValue();
  my $I1 = scalar(@$nodes1);
  for (my $i2 = 0; $i2 < @$nodes2; ++$i2) {
    for (my $i1 = 0; $i1 < $I1; ++$i1) {
      if ($nodes1->[$i1] == $nodes2->[$i2]) {
        $i1 = $I1;
      }
    }
    push @$nodes1, $nodes2->[$i2];
  }
  return XML::DOM::Lite::XPath::NodeSetValue->new($nodes2);
}

package XML::DOM::Lite::XPath::PathExpr;
sub new {
  my ($class, $filter, $rel) = @_;
  return bless { filter => $filter, rel => $rel }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $nodes = $self->{filter}->evaluate($ctx)->nodeSetValue();
  my $nodes1 = [];
  for (my $i = 0; $i < @$nodes; ++$i) {
    my $nodes0 = $self->{rel}->evaluate($ctx->clone($nodes->[$i], $i, $nodes))->nodeSetValue();
    push @$nodes1, @$nodes0;
  }
  return XML::DOM::Lite::XPath::NodeSetValue->new($nodes1);
}

package XML::DOM::Lite::XPath::FilterExpr;
sub new {
  my ($class, $expr, $predicate) = @_;
  return bless { expr => $expr, predicate => $predicate }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $nodes = $self->{expr}->evaluate($ctx)->nodeSetValue();
  for (my $i = 0; $i < @$predicate; ++$i) {
    my $nodes0 = $nodes;
    $nodes = [];
    for (my $j = 0; $j < @$nodes0; ++$j) {
      my $n = $nodes0->[$j];
      if ($self->{predicate}->[$i]->evaluate($ctx->clone($n, $j, $nodes0))->booleanValue()) {
        push(@$nodes, $n);
      }
    }
  }

  return XML::DOM::Lite::XPath::NodeSetValue->new($nodes);
}

package XML::DOM::Lite::XPath::UnaryMinusExpr;
sub new {
  my ($class, $expr) = @_;
  return bless { expr => $expr }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  return XML::DOM::Lite::XPath::NumberValue->new(-$self->{expr}->evaluate($ctx)->numberValue());
}

package XML::DOM::Lite::XPath::BinaryExpr;
sub new {
  my ($class, $expr1, $op, $expr2) = @_;
  return bless { expr1 => $expr1, expr2 => $expr2, op => $op }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  my $ret;
  my $o = $self->{op}->{value};
  if ($o eq 'or') {
      $ret = XML::DOM::Lite::XPath::BooleanValue->new($self->{expr1}->evaluate($ctx)->booleanValue() ||
                               $self->{expr2}->evaluate($ctx)->booleanValue());
  } elsif ($o eq 'and') {
      $ret = XML::DOM::Lite::XPath::BooleanValue->new($self->{expr1}->evaluate($ctx)->booleanValue() &&
                               $self->{expr2}->evaluate($ctx)->booleanValue());
  } elsif ($o eq '+') {
      $ret = XML::DOM::Lite::XPath::BooleanValue->new($self->{expr1}->evaluate($ctx)->booleanValue() +
                               $self->{expr2}->evaluate($ctx)->booleanValue());
  } elsif ($o eq '-') {
      $ret = XML::DOM::Lite::XPath::BooleanValue->new($self->{expr1}->evaluate($ctx)->booleanValue() -
                               $self->{expr2}->evaluate($ctx)->booleanValue());
  } elsif ($o eq '*') {
      $ret = XML::DOM::Lite::XPath::BooleanValue->new($self->{expr1}->evaluate($ctx)->booleanValue() *
                               $self->{expr2}->evaluate($ctx)->booleanValue());
  } elsif ($o eq 'mod') {
      $ret = XML::DOM::Lite::XPath::BooleanValue->new($self->{expr1}->evaluate($ctx)->booleanValue() %
                               $self->{expr2}->evaluate($ctx)->booleanValue());
  } elsif ($o eq 'div') {
      $ret = XML::DOM::Lite::XPath::BooleanValue->new($self->{expr1}->evaluate($ctx)->booleanValue() /
                               $self->{expr2}->evaluate($ctx)->booleanValue());
  } elsif ($o eq '=') {
      $ret = $self->compare($ctx, sub { my ($x1, $x2) = @_; return $x1 == $x2; });
  } elsif ($o eq '!=') {
      $ret = $self->compare($ctx, sub { my ($x1, $x2) = @_; return $x1 != $x2; });
  } elsif ($o eq '<') {
      $ret = $self->compare($ctx, sub { my ($x1, $x2) = @_; return $x1 < $x2; });
  } elsif ($o eq '<=') {
      $ret = $self->compare($ctx, sub { my ($x1, $x2) = @_; return $x1 <= $x2; });
  } elsif ($o eq '>') {
      $ret = $self->compare($ctx, sub { my ($x1, $x2) = @_; return $x1 > $x2; });
  } elsif ($o eq '>=') {
      $ret = $self->compare($ctx, sub { my ($x1, $x2) = @_; return $x1 >= $x2; });
  } else {
      warn('BinaryExpr->evaluate: ' . $self->{op}->{value});
  }
  return $ret;
}

sub compare {
  my ($self, $ctx, $cmp) = @_;
  my $v1 = $self->{expr1}->evaluate($ctx);
  my $v2 = $self->{expr2}->evaluate($ctx);

  my $ret;
  if ($v1->{type} eq 'node-set' and $v2->{type} eq 'node-set') {
    my $n1 = $v1->nodeSetValue();
    my $n2 = $v2->nodeSetValue();
    $ret = 0;
    for (my $i1 = 0; $i1 < @$n1; ++$i1) {
      for (my $i2 = 0; $i2 < @$n2; ++$i2) {
        if (XML::DOM::Lite::XPath::xmlValue($n1->[$i1]) cmp XML::DOM::Lite::XPath::xmlValue($n2->[$i2])) {
          $ret = 1;
          $i2 = @$n2;
          $i1 = @$n1;
        }
      }
    }

  } elsif ($v1->{type} eq 'node-set' or $v2->{type} eq 'node-set') {

    if ($v1->{type} eq 'number') {
      my $s = $v1->numberValue();
      my $n = $v2->nodeSetValue();

      $ret = 0;
      for (my $i = 0;  $i < @$n; ++$i) {
        my $nn = XML::DOM::Lite::XPath::xmlValue($n->[$i]) - 0;
        if ($s cmp $nn) {
          $ret = 1;
          last;
        }
      }

    } elsif ($v2->{type} eq 'number') {
      my $n = $v1->nodeSetValue();
      my $s = $v2->numberValue();

      $ret = 0;
      for (my $i = 0;  $i < @$n; ++$i) {
        my $nn = XML::DOM::Lite::XPath::xmlValue($n->[$i]) - 0;
        if ($nn cmp $s) {
          $ret = 1;
          last;
        }
      }

    } elsif ($v1->{type} eq 'string') {
      my $s = $v1->stringValue();
      my $n = $v2->nodeSetValue();

      $ret = 0;
      for (my $i = 0;  $i < @$n; ++$i) {
        my $nn = XML::DOM::Lite::XPath::xmlValue($n->[$i]);
        if ($s cmp $nn) {
          $ret = 1;
          last;
        }
      }

    } elsif ($v2->{type} eq 'string') {
      my $n = $v1->nodeSetValue();
      my $s = $v2->stringValue();

      $ret = 0;
      for (my $i = 0;  $i < @$n; ++$i) {
        my $nn = XML::DOM::Lite::XPath::xmlValue($n->[$i]);
        if ($nn cmp $s) {
          $ret = 1;
          last;
        }
      }

    } else {
      $ret = ($v1->booleanValue() <=> $v2->booleanValue());
    }

  } elsif ($v1->{type} eq 'boolean' or $v2->{type} eq 'boolean') {
    $ret = ($v1->booleanValue() <=> $v2->booleanValue());

  } elsif ($v1->{type} eq 'number' or $v2->{type} eq 'number') {
    $ret = ($v1->numberValue() <=> $v2->numberValue());

  } else {
    $ret = ($v1->stringValue() <=> $v2->stringValue());
  }

  return XML::DOM::Lite::XPath::BooleanValue->new($ret);
}

package XML::DOM::Lite::XPath::LiteralExpr;
sub new {
  my ($class, $value) = @_;
  return bless { value => $value };
}

sub evaluate {
  my ($self, $ctx) = @_;
  return XML::DOM::Lite::XPath::StringValue->new($self->{value});
}

package XML::DOM::Lite::XPath::NumberExpr;
sub new {
  my ($class, $value) = @_;
  return bless { value => $value };
}

sub evaluate {
  my ($self, $ctx) = @_;
  return XML::DOM::Lite::XPath::NumberValue->new($self->{value});
}

package XML::DOM::Lite::XPath::VariableExpr;
sub new {
  my ($class, $name) = @_;
  return bless { name => $name }, $class;
}

sub evaluate {
  my ($self, $ctx) = @_;
  return $ctx->getVariable($self->{name});
}

package Array::Object;

use overload '@{}' => \&items;

sub new {
  my $class = CORE::shift;
  my $self = bless { _array => CORE::shift || [ ] }, $class;
  return $self;
}

sub items {
  CORE::shift()->{_array};
}

#========= XML::DOM::Lite::XPath package ===========
package XML::DOM::Lite::XPath;

#use Array::Object;

our $DEBUG = 0;

sub new { bless { }, $_[0] }

sub createContext {
    my $self = shift;
    return XML::DOM::Lite::XPath::ExprContext->new(@_);
}

sub evaluate {
    my ($self, $expr, $ctx) = @_;
    if ($ctx->nodeType) {
        $ctx = $self->createContext($ctx);
    }
    return $self->parse($expr)->evaluate($ctx)->{value};
}

our $PARSE_CACHE = { };
sub parse {
    my ($self, $expr) = @_;
    $DEBUG && warn('XPath parse ' . $expr);
    xpathParseInit();

    my $cached = cacheLookup($expr);
    if ($cached) {
        $DEBUG && warn(' ... cached');
        return $cached;
    }
    if ($expr =~ /^(\$|@)?\w+$/i) {
        my $ret = makeSimpleExpr($expr);
        $PARSE_CACHE->{$expr} = $ret;
        $DEBUG && warn(' ... simple');
        return $ret;
    }

    if ($expr =~ /^\w+(\/\w+)*$/i) {
        my $ret = makeSimpleExpr2($expr);
        $PARSE_CACHE->{$expr} = $ret;
        $DEBUG && warn(' ... simple2');
        return $ret;
    }

    my $cachekey = $expr;
    my $stack = [];
    my $ahead = undef;
    my $previous = undef;
    my $done = 0;

    my $parse_count = 0;
    my $lexer_count = 0;
    my $reduce_count = 0;
  
    until ($done) {
        $parse_count++;
        $expr =~ s/^\s*//;
        $previous = $ahead;
        $ahead = undef;

        my $rule = undef;
        my $match = '';
        foreach my $r (@$xpathTokenRules) {
            my $re = $r->{re};
            my @result = ($expr =~ /($re)/);
            $lexer_count++;
            if (@result and length($result[0]) > length($match)) {
                $rule = $r;
                $match = $result[0];
                last;
            }
        }

        if ($rule &&
            ($rule == $TOK_DIV || 
             $rule == $TOK_MOD ||
             $rule == $TOK_AND || 
             $rule == $TOK_OR) &&
            (!$previous || 
             $previous->{tag} == $TOK_AT || 
             $previous->{tag} == $TOK_DSLASH || 
             $previous->{tag} == $TOK_SLASH ||
             $previous->{tag} == $TOK_AXIS || 
             $previous->{tag} == $TOK_DOLLAR)) {
          $rule = $TOK_QNAME;
        }

        if ($rule) {
            $expr = substr($expr, length($match));
            $DEBUG && warn('token: ' . $match . ' -- ' . $rule->{label});
            $ahead = {
                tag   => $rule,
                match => $match,
                prec  => $rule->{prec} ? $rule->{prec} : 0,
                expr  => makeTokenExpr($match)
            };

        } else {
            $DEBUG && warn "DONE";
            $done = 1;
        }

        while (reduce($stack, $ahead)) {
            $reduce_count++;
            $DEBUG && warn ('stack: ' . stackToString($stack));
        }
    }

    $DEBUG && warn(stackToString($stack));

    if (@$stack != 1) {
        die 'XPath parse error ' . $cachekey . ":\n" . stackToString($stack);
    }

    my $result = $stack->[0]->{expr};
    $PARSE_CACHE->{$cachekey} = $result;

    $DEBUG && warn('XPath parse: '.$parse_count.' / '.$lexer_count.' / '.$reduce_count);

    return $result;
}

sub cacheLookup {
    my ($expr) = @_;
    return $PARSE_CACHE->{$expr};
}

sub reduce {
    my ($stack, $ahead) = @_;
    my $cand = undef;

    if (@$stack) {
        my $top = $stack->[@$stack-1];
        my $ruleset = $xpathRules->[$top->{tag}->{key}];
        if ($ruleset) {
            foreach my $rule (@$ruleset) {
                my $match = matchStack($stack, $rule->[1]);
                if (@$match) {
                    $cand = {
                        tag => $rule->[0],
                        rule => $rule,
                        match => $match
                    };
                    $cand->{prec} = grammarPrecedence($cand);
                    last;
                }
            }
        }
    }

    my $ret;
    if ($cand and ((not $ahead) or ($cand->{prec} > $ahead->{prec}) or 
        ($ahead->{tag}->{left} and $cand->{prec} >= $ahead->{prec}))) {
        for (my $i = 0; $i < $cand->{match}->{matchlength}; ++$i) {
            pop(@$stack);
        }

        $DEBUG && warn('reduce '. $cand->{tag}->{label}.' '
            .$cand->{prec}.' ahead '.(
                $ahead ? $ahead->{tag}->{label}.
                ' '.$ahead->{prec}.($ahead->{tag}->{left}
                    ? ' left' : '')
                    : ' none ')
            );
        my $matchexpr = [ map { $_->{expr} } @{$cand->{match}} ];
        $cand->{expr} = $cand->{rule}->[3]->(@$matchexpr);

        push @$stack, $cand;
        $ret = 1;

    } else {
        if ($ahead) {
            $DEBUG && warn('shift '.$ahead->{tag}->{label}.' '.
                $ahead->{prec}.($ahead->{tag}->{left} ? ' left' : '').
                ' over '.($cand ? $cand->{tag}->{label}.' '
                .$cand->{prec} : ' none'));
            push @$stack, $ahead;
        }
        $ret = 0;
    }
    return $ret;
}

sub matchStack {
  my ($stack, $pattern) = @_;

  my $S = @$stack;
  my $P = @$pattern;
  my ($p, $s);
  my $match = Array::Object->new([]);
  $match->{matchlength} = 0;
  my $ds = 0;
  for ($p = $P - 1, $s = $S - 1; $p >= 0 && $s >= 0; --$p, $s -= $ds) {
    $ds = 0;
    my $qmatch = Array::Object->new([]);
    if ($pattern->[$p] == $Q_MM) {
      $p -= 1;
      push @$match, $qmatch;
      while ($s - $ds >= 0 and $stack->[$s - $ds]->{tag} == $pattern->[$p]) {
        push(@$qmatch, $stack->[$s - $ds]);
        $ds += 1;
        $match->{matchlength} += 1;
      }

    } elsif ($pattern->[$p] == $Q_01) {
      $p -= 1;
      push(@$match, $qmatch);
      while ($s - $ds >= 0 and $ds < 2 and $stack->[$s - $ds]->{tag} == $pattern->[$p]) {
        push(@$qmatch, $stack->[$s - $ds]);
        $ds += 1;
        $match->{matchlength} += 1;
      }

    } elsif ($pattern->[$p] == $Q_1M) {
      $p -= 1;
      push(@$match, $qmatch);
      if ($stack->[$s]->{tag} == $pattern->[$p]) {
        while ($s - $ds >= 0 and $stack->[$s - $ds]->{tag} == $pattern->[$p]) {
          push(@$qmatch, $stack->[$s - $ds]);
          $ds += 1;
          $match->{matchlength} += 1;
        }
      } else {
        return [];
      }

    } elsif ($stack->[$s]->{tag} == $pattern->[$p]) {
      push(@$match, $stack->[$s]);
      $ds += 1;
      $match->{matchlength} += 1;

    } else {
      return [];
    }

    @$qmatch = reverse(@$qmatch);
    $qmatch->{expr} = [ map { $_->{expr} } @$qmatch ];
  }

  @$match = reverse(@$match);

  if ($p == -1) {
    return $match;

  } else {
    return [];
  }
}

sub tokenPrecedence {
  my ($tag) = @_;
  return $tag->{prec} || 2;
}

sub grammarPrecedence {
  my ($frame) = @_;
  my $ret = 0;

  if ($frame->{rule}) {
    if (@{$frame->{rule}} >= 3 and $frame->{rule}->[2] >= 0) {
      $ret = $frame->{rule}->[2];

    } else {
      for (my $i = 0; $i < @{$frame->{rule}->[1]}; ++$i) {
        my $p = tokenPrecedence($frame->{rule}->[1]->[$i]);
        $ret = max($ret, $p);
      }
    }
  } elsif ($frame->{tag}) {
    $ret = tokenPrecedence($frame->{tag});

  } elsif (ref $frame eq 'ARRAY' and @$frame) {
    for (my $j = 0; $j < @$frame; ++$j) {
      my $p = grammarPrecedence($frame->[$j]);
      $ret = max($ret, $p);
    }
  }

  return $ret;
}

sub max { if ($_[0] > $_[1]) { return $_[0] } else { return $_[1] } }

sub stackToString {
  my $stack = shift;
  my $ret = '';
  for (my $i = 0; $i < @$stack; ++$i) {
    if ($ret) {
      $ret .= "\n";
    }
    $ret .= $stack->[$i]->{tag}->{label};
  }
  return $ret;
}
sub makeTokenExpr {
  my ($m) = @_;
  return XML::DOM::Lite::XPath::TokenExpr->new($m);
}

sub passExpr {
  my ($e) = shift;
  return $e;
}

sub makeLocationExpr1 {
  my ($slash, $rel) = @_;
  $rel->{absolute} = 1;
  return $rel;
}

sub makeLocationExpr2 {
  my ($dslash, $rel) = @_;
  $rel->{absolute} = 1;
  $rel->prependStep(makeAbbrevStep($dslash->{value}));
  return $rel;
}

sub makeLocationExpr3 {
  my $slash = shift;
  my $ret = XML::DOM::Lite::XPath::LocationExpr->new();
  $ret->appendStep(makeAbbrevStep('.'));
  $ret->{absolute} = 1;
  return $ret;
}

sub makeLocationExpr4 {
  my $dslash = shift;
  my $ret = XML::DOM::Lite::XPath::LocationExpr->new();
  $ret->{absolute} = 1;
  $ret->appendStep(makeAbbrevStep($dslash->{value}));
  return $ret;
}

sub makeLocationExpr5 {
  my $step = shift;
  my $ret = XML::DOM::Lite::XPath::LocationExpr->new();
  $ret->appendStep($step);
  return $ret;
}

sub makeLocationExpr6 {
  my ($rel, $slash, $step) = @_;
  $rel->appendStep($step);
  return $rel;
}

sub makeLocationExpr7 {
  my ($rel, $dslash, $step) = @_;
  $rel->appendStep(makeAbbrevStep($dslash->{value}));
  return $rel;
}

sub makeStepExpr1 {
  my $dot = shift;
  return makeAbbrevStep($dot->{value});
}

sub makeStepExpr2 {
  my ($ddot) = shift;
  return makeAbbrevStep($ddot->{value});
}

sub makeStepExpr3 {
  my ($axisname, $axis, $nodetest) = @_;
  return XML::DOM::Lite::XPath::StepExpr->new($axisname->{value}, $nodetest);
}

sub makeStepExpr4 {
  my ($at, $nodetest) = @_;
  return XML::DOM::Lite::XPath::StepExpr->new('attribute', $nodetest);
}

sub makeStepExpr5 {
  my $nodetest = shift;
  return XML::DOM::Lite::XPath::StepExpr->new('child', $nodetest);
}

sub makeStepExpr6 {
  my ($step, $predicate) = @_;
  $step->appendPredicate($predicate);
  return $step;
}

sub makeAbbrevStep {
  my ($abbrev) = @_;
  if ($abbrev eq '//') {
    return XML::DOM::Lite::XPath::StepExpr->new('descendant-or-self', XML::DOM::Lite::XPath::NodeTestAny->new());
  } elsif ($abbrev eq '.') {
    return XML::DOM::Lite::XPath::StepExpr->new('self', XML::DOM::Lite::XPath::NodeTestAny->new());
  } elsif ($abbrev eq '..') {
    return XML::DOM::Lite::XPath::StepExpr->new('parent', XML::DOM::Lite::XPath::NodeTestAny->new());
  }
}

sub makeNodeTestExpr1 {
  my ($asterisk) = @_;
  return XML::DOM::Lite::XPath::NodeTestElement->new();
}

sub makeNodeTestExpr2 {
  my ($ncname, $colon, $asterisk) = @_;
  return XML::DOM::Lite::XPath::NodeTestNC->new($ncname->{value});
}

sub makeNodeTestExpr3 {
  my $qname = shift;
  return XML::DOM::Lite::XPath::NodeTestName->new($qname->{value});
}

sub makeNodeTestExpr4 {
  my ($type, $parenc) = @_;
  $type =~ s/\s*\($//;
  if ($type eq 'node') {
    return XML::DOM::Lite::XPath::NodeTestAny->new();
  } elsif ($type eq 'text') {
    return XML::DOM::Lite::XPath::NodeTestText->new();
  } elsif ($type eq 'comment') {
    return XML::DOM::Lite::XPath::NodeTestComment->new();
  } elsif ($type eq 'processing-instruction') {
    return XML::DOM::Lite::XPath::NodeTestPI->new;
  }
}

sub makeNodeTestExpr5 {
  my ($type, $target, $parenc) = @_;
  $type =~ s/\s*\($//;
  if ($type ne 'processing-instruction') {
    die $type.' ';
  }
  return XML::DOM::Lite::XPath::NodeTestPI->new($target->{value});
}

sub makePredicateExpr {
  my ($pareno, $expr, $parenc) = @_;
  return XML::DOM::Lite::XPath::PredicateExpr->new($expr);
}

sub makePrimaryExpr {
  my ($pareno, $expr, $parenc) = @_;
  return $expr;
}

sub makeFunctionCallExpr1 {
  my ($name, $pareno, $parenc) = @_;
  return XML::DOM::Lite::XPath::FunctionCallExpr->new($name);
}

sub makeFunctionCallExpr2 {
  my ($name, $pareno, $arg1, $args, $parenc) = @_;
  my $ret = XML::DOM::Lite::XPath::FunctionCallExpr->new($name);
  $ret->appendArg($arg1);
  for (my $i = 0; $i < @$args; ++$i) {
    $ret->appendArg($args->[$i]);
  }
  return $ret;
}

sub makeArgumentExpr {
  my ($comma, $expr) = @_;
  return $expr;
}

sub makeUnionExpr {
  my ($expr1, $pipe, $expr2) = @_;
  return XML::DOM::Lite::XPath::UnionExpr->new($expr1, $expr2);
}

sub makePathExpr1 {
  my ($filter, $slash, $rel) = @_;
  return XML::DOM::Lite::XPath::PathExpr->new($filter, $rel);
}

sub makePathExpr2 {
  my ($filter, $dslash, $rel) = @_;
  $rel->prependStep(makeAbbrevStep($dslash->{value}));
  return XML::DOM::Lite::XPath::PathExpr->new($filter, $rel);
}

sub makeFilterExpr {
  my ($expr, $predicates) = @_;
  if (@$predicates > 0) {
    return XML::DOM::Lite::XPath::FilterExpr->new($expr, $predicates);
  } else {
    return $expr;
  }
}

sub makeUnaryMinusExpr {
  my ($minus, $expr) = @_;
  return new XML::DOM::Lite::XPath::UnaryMinusExpr($expr);
}

sub makeBinaryExpr {
  my ($expr1, $op, $expr2) = @_;
  return new XML::DOM::Lite::XPath::BinaryExpr($expr1, $op, $expr2);
}

sub makeLiteralExpr {
  my ($token) = @_;
  my $value = substr($token->{value}, 1, length($token->{value}) - 1);
  return new XML::DOM::Lite::XPath::LiteralExpr($value);
}

sub makeNumberExpr {
  my $token = shift;
  return new XML::DOM::Lite::XPath::NumberExpr($token->{value});
}

sub makeVariableReference {
  my ($dollar, $name) = @_;
  return new XML::DOM::Lite::XPath::VariableExpr($name->{value});
}

sub makeSimpleExpr {
  my $expr = shift;
  if (substr($expr, 0, 1) eq '$') {
    return new XML::DOM::Lite::XPath::VariableExpr(substr($expr, 1));
  } elsif (substr($expr, 0, 1) eq '@') {
    my $a = new XML::DOM::Lite::XPath::NodeTestName(substr($expr, 1));
    my $b = new XML::DOM::Lite::XPath::StepExpr('attribute', $a);
    my $c = new XML::DOM::Lite::XPath::LocationExpr();
    $c->appendStep($b);
    return $c;
  } elsif ($expr =~ /^[0-9]+$/) {
    return new XML::DOM::Lite::XPath::NumberExpr($expr);
  } else {
    my $a = new XML::DOM::Lite::XPath::NodeTestName($expr);
    my $b = new XML::DOM::Lite::XPath::StepExpr('child', $a);
    my $c = new XML::DOM::Lite::XPath::LocationExpr();
    $c->appendStep($b);
    return $c;
  }
}

sub makeSimpleExpr2 {
  my $expr = shift;
  my @steps = split(/\//, $expr);
  my $c = new XML::DOM::Lite::XPath::LocationExpr();
  foreach my $s (@steps) {
    my $a = new XML::DOM::Lite::XPath::NodeTestName($s);
    my $b = new XML::DOM::Lite::XPath::StepExpr('child', $a);
    $c->appendStep($b);
  }
  return $c;
}

our $xpathAxis = $XML::DOM::Lite::XPath::StepExpr::xpathAxis;

our $xpathAxesRe = join('|', (
    $xpathAxis->{ANCESTOR_OR_SELF},
    $xpathAxis->{ANCESTOR},
    $xpathAxis->{ATTRIBUTE},
    $xpathAxis->{CHILD},
    $xpathAxis->{DESCENDANT_OR_SELF},
    $xpathAxis->{DESCENDANT},
    $xpathAxis->{FOLLOWING_SIBLING},
    $xpathAxis->{FOLLOWING},
    $xpathAxis->{NAMESPACE},
    $xpathAxis->{PARENT},
    $xpathAxis->{PRECEDING_SIBLING},
    $xpathAxis->{PRECEDING},
    $xpathAxis->{SELF}
));


our $TOK_PIPE =   { label => "|",   prec =>   17, re => qr/^\|/ };
our $TOK_DSLASH = { label => "//",  prec =>   19, re => qr/^\/\//  };
our $TOK_SLASH =  { label => "/",   prec =>   30, re => qr/^\//   };
our $TOK_AXIS =   { label => '::',  prec =>   20, re => qr/^::/  };
our $TOK_COLON =  { label => ":",   prec => 1000, re => qr/^:/   };
our $TOK_AXISNAME = { label => "[axis]", re => qr/^($xpathAxesRe)/ };
our $TOK_PARENO = { label => "(",   prec =>   34, re => qr/^\(/ };
our $TOK_PARENC = { label => ")",               re => qr/^\)/ };
our $TOK_DDOT =   { label => "..",  prec =>   34, re => qr/^\.\./ };
our $TOK_DOT =    { label => ".",   prec =>   34, re => qr/^\./ };
our $TOK_AT =     { label => "@",   prec =>   34, re => qr/^@/   };

our $TOK_COMMA =  { label => ",",               re => qr/^,/ };

our $TOK_OR =     { label => "or",  prec =>   10, re => qr/^or\b/ };
our $TOK_AND =    { label => "and", prec =>   11, re => qr/^and\b/ };
our $TOK_EQ =     { label => "=",   prec =>   12, re => qr/^=/   };
our $TOK_NEQ =    { label => "!=",  prec =>   12, re => qr/^!=/  };
our $TOK_GE =     { label => ">=",  prec =>   13, re => qr/^>=/  };
our $TOK_GT =     { label => ">",   prec =>   13, re => qr/^>/   };
our $TOK_LE =     { label => "<=",  prec =>   13, re => qr/^<=/  };
our $TOK_LT =     { label => "<",   prec =>   13, re => qr/^</   };
our $TOK_PLUS =   { label => "+",   prec =>   14, re => qr/^\+/, left => 1 };
our $TOK_MINUS =  { label => "-",   prec =>   14, re => qr/^\-/, left => 1 };
our $TOK_DIV =    { label => "div", prec =>   15, re => qr/^div\b/, left => 1 };
our $TOK_MOD =    { label => "mod", prec =>   15, re => qr/^mod\b/, left => 1 };

our $TOK_BRACKO = { label => "[",   prec =>   32, re => qr/^\[/ };
our $TOK_BRACKC = { label => "]",               re => qr/^\]/ };
our $TOK_DOLLAR = { label => '$',               re => qr/^\$/ };

our $TOK_NCNAME = { label => "[ncname]", re => qr/^[a-z][-\w]*/i };

our $TOK_ASTERISK = { label => "*", prec => 15, re => qr/^\*/, left => 1 };
our $TOK_LITERALQ = { label => "[litq]", prec => 20, re => qr/^'[^']*'/ };
our $TOK_LITERALQQ = {
  label => "[litqq]",
  prec => 20,
  re => qr/^"[^"]*"/
};

our $TOK_NUMBER  = {
  label => "[number]",
  prec => 35,
  re => qr/^\d+(\.\d*)?/
};

our $TOK_QNAME = {
  label => "[qname]",
  re => qr/^([a-z][-\w]*:)?[a-z][-\w]*/i
};

our $TOK_NODEO = {
  label => "[nodetest-start]",
  re => qr/^(processing-instruction|comment|text|node)\(/
};

our $xpathTokenRules = [
    $TOK_DSLASH,
    $TOK_SLASH,
    $TOK_DDOT,
    $TOK_DOT,
    $TOK_AXIS,
    $TOK_COLON,
    $TOK_AXISNAME,
    $TOK_NODEO,
    $TOK_PARENO,
    $TOK_PARENC,
    $TOK_BRACKO,
    $TOK_BRACKC,
    $TOK_AT,
    $TOK_COMMA,
    $TOK_OR,
    $TOK_AND,
    $TOK_NEQ,
    $TOK_EQ,
    $TOK_GE,
    $TOK_GT,
    $TOK_LE,
    $TOK_LT,
    $TOK_PLUS,
    $TOK_MINUS,
    $TOK_ASTERISK,
    $TOK_PIPE,
    $TOK_MOD,
    $TOK_DIV,
    $TOK_LITERALQ,
    $TOK_LITERALQQ,
    $TOK_NUMBER,
    $TOK_QNAME,
    $TOK_NCNAME,
    $TOK_DOLLAR
];

our $XPathLocationPath = { label => "LocationPath" };
our $XPathRelativeLocationPath = { label => "RelativeLocationPath" };
our $XPathAbsoluteLocationPath = { label => "AbsoluteLocationPath" };
our $XPathStep = { label => "Step" };
our $XPathNodeTest = { label => "NodeTest" };
our $XPathPredicate = { label => "Predicate" };
our $XPathLiteral = { label => "Literal" };
our $XPathExpr = { label => "Expr" };
our $XPathPrimaryExpr = { label => "PrimaryExpr" };
our $XPathVariableReference = { label => "Variablereference" };
our $XPathNumber = { label => "Number" };
our $XPathFunctionCall = { label => "FunctionCall" };
our $XPathArgumentRemainder = { label => "ArgumentRemainder" };
our $XPathPathExpr = { label => "PathExpr" };
our $XPathUnionExpr = { label => "UnionExpr" };
our $XPathFilterExpr = { label => "FilterExpr" };
our $XPathDigits = { label => "Digits" };

our $xpathNonTerminals = [
    $XPathLocationPath,
    $XPathRelativeLocationPath,
    $XPathAbsoluteLocationPath,
    $XPathStep,
    $XPathNodeTest,
    $XPathPredicate,
    $XPathLiteral,
    $XPathExpr,
    $XPathPrimaryExpr,
    $XPathVariableReference,
    $XPathNumber,
    $XPathFunctionCall,
    $XPathArgumentRemainder,
    $XPathPathExpr,
    $XPathUnionExpr,
    $XPathFilterExpr,
    $XPathDigits
];

our $Q_01 = { label => "?" };
our $Q_MM = { label => "*" };
our $Q_1M = { label => "+" };

our $ASSOC_LEFT = 1;

our $xpathGrammarRules =
  [
   [ $XPathLocationPath, [ $XPathRelativeLocationPath ], 18,
     \&passExpr ],
   [ $XPathLocationPath, [ $XPathAbsoluteLocationPath ], 18,
     \&passExpr ],

   [ $XPathAbsoluteLocationPath, [ $TOK_SLASH, $XPathRelativeLocationPath ], 18, 
     \&makeLocationExpr1 ],
   [ $XPathAbsoluteLocationPath, [ $TOK_DSLASH, $XPathRelativeLocationPath ], 18,
     \&makeLocationExpr2 ],

   [ $XPathAbsoluteLocationPath, [ $TOK_SLASH ], 0,
     \&makeLocationExpr3 ],
   [ $XPathAbsoluteLocationPath, [ $TOK_DSLASH ], 0,
     \&makeLocationExpr4 ],

   [ $XPathRelativeLocationPath, [ $XPathStep ], 31,
     \&makeLocationExpr5 ],
   [ $XPathRelativeLocationPath,
     [ $XPathRelativeLocationPath, $TOK_SLASH, $XPathStep ], 31,
     \&makeLocationExpr6 ],
   [ $XPathRelativeLocationPath,
     [ $XPathRelativeLocationPath, $TOK_DSLASH, $XPathStep ], 31,
     \&makeLocationExpr7 ],

   [ $XPathStep, [ $TOK_DOT ], 33,
     \&makeStepExpr1 ],
   [ $XPathStep, [ $TOK_DDOT ], 33,
     \&makeStepExpr2 ],
   [ $XPathStep,
     [ $TOK_AXISNAME, $TOK_AXIS, $XPathNodeTest ], 33,
     \&makeStepExpr3 ],
   [ $XPathStep, [ $TOK_AT, $XPathNodeTest ], 33,
     \&makeStepExpr4 ],
   [ $XPathStep, [ $XPathNodeTest ], 33,
     \&makeStepExpr5 ],
   [ $XPathStep, [ $XPathStep, $XPathPredicate ], 33,
     \&makeStepExpr6 ],

   [ $XPathNodeTest, [ $TOK_ASTERISK ], 33,
     \&makeNodeTestExpr1 ],
   [ $XPathNodeTest, [ $TOK_NCNAME, $TOK_COLON, $TOK_ASTERISK ], 33,
     \&makeNodeTestExpr2 ],
   [ $XPathNodeTest, [ $TOK_QNAME ], 33,
     \&makeNodeTestExpr3 ],
   [ $XPathNodeTest, [ $TOK_NODEO, $TOK_PARENC ], 33,
     \&makeNodeTestExpr4 ],
   [ $XPathNodeTest, [ $TOK_NODEO, $XPathLiteral, $TOK_PARENC ], 33,
     \&makeNodeTestExpr5 ],

   [ $XPathPredicate, [ $TOK_BRACKO, $XPathExpr, $TOK_BRACKC ], 33,
     \&makePredicateExpr ],

   [ $XPathPrimaryExpr, [ $XPathVariableReference ], 33,
     \&passExpr ],
   [ $XPathPrimaryExpr, [ $TOK_PARENO, $XPathExpr, $TOK_PARENC ], 33,
     \&makePrimaryExpr ],
   [ $XPathPrimaryExpr, [ $XPathLiteral ], 30,
     \&passExpr ],
   [ $XPathPrimaryExpr, [ $XPathNumber ], 30,
     \&passExpr ],
   [ $XPathPrimaryExpr, [ $XPathFunctionCall ], 30,
     \&passExpr ],

   [ $XPathFunctionCall, [ $TOK_QNAME, $TOK_PARENO, $TOK_PARENC ], -1,
     \&makeFunctionCallExpr1 ],
   [ $XPathFunctionCall,
     [ $TOK_QNAME, $TOK_PARENO, $XPathExpr, $XPathArgumentRemainder, $Q_MM,
       $TOK_PARENC ], -1,
    \&makeFunctionCallExpr2 ],
   [ $XPathArgumentRemainder, [ $TOK_COMMA, $XPathExpr ], -1,
    \&makeArgumentExpr ],

   [ $XPathUnionExpr, [ $XPathPathExpr ], 20,
    \&passExpr ],
   [ $XPathUnionExpr, [ $XPathUnionExpr, $TOK_PIPE, $XPathPathExpr ], 20,
    \&makeUnionExpr ],

   [ $XPathPathExpr, [ $XPathLocationPath ], 20, 
    \&passExpr ], 
   [ $XPathPathExpr, [ $XPathFilterExpr ], 19, 
    \&passExpr ], 
   [ $XPathPathExpr, 
     [ $XPathFilterExpr, $TOK_SLASH, $XPathRelativeLocationPath ], 20,
    \&makePathExpr1 ],
   [ $XPathPathExpr,
     [ $XPathFilterExpr, $TOK_DSLASH, $XPathRelativeLocationPath ], 20,
    \&makePathExpr2 ],

   [ $XPathFilterExpr, [ $XPathPrimaryExpr, $XPathPredicate, $Q_MM ], 20,
    \&makeFilterExpr ], 

   [ $XPathExpr, [ $XPathPrimaryExpr ], 16,
    \&passExpr ],
   [ $XPathExpr, [ $XPathUnionExpr ], 16,
    \&passExpr ],

   [ $XPathExpr, [ $TOK_MINUS, $XPathExpr ], -1,
    \&makeUnaryMinusExpr ],

   [ $XPathExpr, [ $XPathExpr, $TOK_OR, $XPathExpr ], -1,
    \&makeBinaryExpr ],
   [ $XPathExpr, [ $XPathExpr, $TOK_AND, $XPathExpr ], -1,
    \&makeBinaryExpr ],

   [ $XPathExpr, [ $XPathExpr, $TOK_EQ, $XPathExpr ], -1,
    \&makeBinaryExpr ],
   [ $XPathExpr, [ $XPathExpr, $TOK_NEQ, $XPathExpr ], -1,
     \&makeBinaryExpr ],

   [ $XPathExpr, [ $XPathExpr, $TOK_LT, $XPathExpr ], -1,
     \&makeBinaryExpr ],
   [ $XPathExpr, [ $XPathExpr, $TOK_LE, $XPathExpr ], -1,
     \&makeBinaryExpr ],
   [ $XPathExpr, [ $XPathExpr, $TOK_GT, $XPathExpr ], -1,
     \&makeBinaryExpr ],
   [ $XPathExpr, [ $XPathExpr, $TOK_GE, $XPathExpr ], -1,
     \&makeBinaryExpr ],

   [ $XPathExpr, [ $XPathExpr, $TOK_PLUS, $XPathExpr ], -1,
     \&makeBinaryExpr, $ASSOC_LEFT ],
   [ $XPathExpr, [ $XPathExpr, $TOK_MINUS, $XPathExpr ], -1,
     \&makeBinaryExpr, $ASSOC_LEFT ],

   [ $XPathExpr, [ $XPathExpr, $TOK_ASTERISK, $XPathExpr ], -1,
     \&makeBinaryExpr, $ASSOC_LEFT ],
   [ $XPathExpr, [ $XPathExpr, $TOK_DIV, $XPathExpr ], -1,
     \&makeBinaryExpr, $ASSOC_LEFT ],
   [ $XPathExpr, [ $XPathExpr, $TOK_MOD, $XPathExpr ], -1,
     \&makeBinaryExpr, $ASSOC_LEFT ],

   [ $XPathLiteral, [ $TOK_LITERALQ ], -1,
     \&makeLiteralExpr ],
   [ $XPathLiteral, [ $TOK_LITERALQQ ], -1,
     \&makeLiteralExpr ],

   [ $XPathNumber, [ $TOK_NUMBER ], -1,
     \&makeNumberExpr ],

   [ $XPathVariableReference, [ $TOK_DOLLAR, $TOK_QNAME ], 200,
     \&makeVariableReference ]
   ];

our $xpathRules = [];

sub xpathParseInit {
  if (@$xpathRules) {
    return;
  }
  @$xpathGrammarRules = sort {
    return scalar(@{$b->[1]}) <=> scalar(@{$a->[1]});
  } @$xpathGrammarRules;
  
  my $k = 1;
  for (my $i = 0; $i < @$xpathNonTerminals; ++$i) {
    $xpathNonTerminals->[$i]->{key} = $k++;
  }

  for ($i = 0; $i < @$xpathTokenRules; ++$i) {
    $xpathTokenRules->[$i]->{key} = $k++;
  }

  $DEBUG && warn('XPath parse INIT: ' . $k . ' rules');

  my $push_ = sub {
    my ($array, $position, $element) = @_;
    $array->[$position] = [ ] unless $array->[$position];
    push @{$array->[$position]}, $element;
  };

  for ($i = 0; $i < @$xpathGrammarRules; ++$i) {
    my $rule = $xpathGrammarRules->[$i];
    my $pattern = $rule->[1];

    for (my $j = @$pattern - 1; $j >= 0; --$j) {
      if ($pattern->[$j] == $Q_1M) {
        &$push_($xpathRules, $pattern->[$j-1]->{key}, $rule);
        last;
        
      } elsif ($pattern->[$j] == $Q_MM or $pattern->[$j] == $Q_01) {
        &$push_($xpathRules, $pattern->[$j-1]->{key}, $rule);
        --$j;

      } else {
        &$push_($xpathRules, $pattern->[$j]->{key}, $rule);
        last;
      }
    }
  }

  $DEBUG && warn('XPath parse INIT: ' . @$xpathRules . ' rule bins');
  
  my $sum = 0;
  map { if ($_) { $sum += @$_} } @$xpathRules;
  
  $DEBUG && warn('XPath parse INIT: ' . ($sum / @$xpathRules) . ' average bin size');
}

sub xpathCollectDescendants {
  my ($nodelist, $node) = @_;
  for (my $n = $node->firstChild; $n; $n = $n->nextSibling) {
    push(@$nodelist, $n);
    xpathCollectDescendants($nodelist, $n);
  }
}

sub xpathCollectDescendantsReverse {
  my ($nodelist, $node) = @_;
  for (my $n = $node->lastChild; $n; $n = $n->previousSibling) {
    push(@$nodelist, $n);
    xpathCollectDescendantsReverse($nodelist, $n);
  }
}


sub xpathDomEval {
  my ($expr, $node) = @_;
  my $expr1 = xpathParse($expr);
  my $ret = $expr1->evaluate(XML::DOM::Lite::XPath::ExprContext($node)->new);
  return $ret;
}

sub xpathSort {
  my ($input, $sort) = @_;
  return unless @$sort;

  my $sortlist = [];

  for (my $i = 0; $i < @{$input->{nodelist}}; ++$i) {
    my $node = $input->{nodelist}->[$i];
    my $sortitem = { node=> $node, key=> [] };
    my $context = $input->clone($node, 0, [ $node ]);
    
    for (my $j = 0; $j < @$sort; ++$j) {
      my $s = $sort->[$j];
      my $value = $s->{expr}->evaluate($context);

      my $evalue;
      if ($s->{type} eq 'text') {
        $evalue = $value->stringValue();
      } elsif ($s->{type} eq 'number') {
        $evalue = $value->numberValue();
      }
      push @{$sortitem->{key}}, { value=> $evalue, order=> $s->{order} };
    }

    push @{$sortitem->{key}}, {value => $i, order => 'ascending'};

    push @$sortlist, $sortitem;
  }

  @$sortlist = sort \&xpathSortByKey, @$sortlist;

  my $nodes = [];
  for ($i = 0; $i < @$sortlist; ++$i) {
    push(@$nodes, $sortlist->[$i]->{node});
  }
  $input->{nodelist} = $nodes;
  $input->setNode($nodes->[0], 0);
}

sub xpathSortByKey {
  my ($v1, $v2) = @_;
  for (my $i = 0; $i < @{$v1->{key}}; ++$i) {
    my $o = $v1->{key}->[$i]->{order} eq 'descending' ? -1 : 1;
    if ($v1->{key}->[$i]->{value} > $v2->{key}->[$i]->{value}) {
      return +1 * $o;
    } elsif ($v1->{key}->[$i]->{value} < $v2->{key}->[$i]->{value}) {
      return -1 * $o;
    }
  }

  return 0;
}

sub xmlValue {
  my $node = shift;
  return '' unless $node;

  my $ret = '';
  if ($node->{nodeType} == TEXT_NODE ||
      $node->{nodeType} == CDATA_SECTION_NODE ||
      $node->{nodeType} == ATTRIBUTE_NODE) {
    $ret .= $node->{nodeValue};

  } elsif ($node->{nodeType} == ELEMENT_NODE ||
             $node->{nodeType} == DOCUMENT_NODE ||
             $node->{nodeType} == DOCUMENT_FRAGMENT_NODE) {
    for (my $i = 0; $i < @{$node->childNodes}; ++$i) {
      $ret .= xmlValue($node->childNodes->[$i]);
    }
  }
  return $ret;
}

1;

__END__

=head1 NAME

XML::DOM::Lite::XPath - XPath support for XML::DOM::Lite

=head1 SYNOPSIS
 
 # XPath
 use XML::DOM::Lite qw(XPath);
 $result = XPath->evaluate('/path/to/*[@attr="value"]', $contextNode);
  
=head1 DESCRIPTION

This XPath library is fairly complete - there are still a few functions outstanding which need to be implemented, but it's already very usable and is being used by L<XML::DOM::Lite::XSLT>

=head1 ACKNOWLEDGEMENTS

Google - for implementing the XPath and XSLT JavaScript libraries which I shamelessly stole

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENCE

This library is free software and may be used under the same terms as
Perl itself.

=cut


package Test::Rest::Commands;
use strict;
use warnings;
use Test::More ();
use XML::LibXML;
use Data::Dumper;
use Carp;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my %opts = @_;
  return bless \%opts, $class;
}

sub get {
  my $self = shift;
  my $c = shift;
  if ($c->test->hasAttribute('check') and $c->test->getAttribute('check') =~ /^(0|false)$/misg) {
    $c->ua->{autocheck} = 0;
  }
  $c->add_response($c->ua->get($c->expand_url($c->test->textContent)));
  $c->ua->{autocheck} = 1;
}

sub head {
  my $self = shift;
  my $c = shift;
  $c->add_response($c->ua->head($c->expand_url($c->test->textContent)));
}

sub post {
  my $self = shift;
  my $c = shift;
  my $url = $c->expand_url($c->test->getAttribute('to'));
  my %hash;
  _children_to_hash($c, $c->test, \%hash);
  my @node = $c->test->findnodes('Content');
  if (@node and _has_child_elements($node[0])) {
    $hash{Content} = $c->expand_string(_first_child_element($node[0])->toString);
  }
  $hash{'Content-Type'} ||= $node[0]->getAttribute('type') || 'application/xml';
  $c->add_response($c->ua->post($url, %hash));
}

sub put {
  my $self = shift;
  my $c = shift;
  my $url = $c->expand_url($c->test->getAttribute('to'));
  my %hash;
  _children_to_hash($c, $c->test, \%hash);
  my @node = $c->test->findnodes('Content');
  if (@node and _has_child_elements($node[0])) {
    $hash{Content} = $c->expand_string(_first_child_element($node[0])->toString);
  }
  $hash{'Content-Type'} ||= $node[0]->getAttribute('type') || 'application/xml';
  $c->add_response($c->ua->put($url, %hash));
}

sub delete {
  my $self = shift;
  my $c = shift;
  $c->add_response($c->ua->request(HTTP::Request->new('DELETE', $c->expand_url($c->test->textContent))));
}

sub is {
  my $self = shift;
  my $c = shift;
  my $value = '';
  if ($c->test->hasAttribute('the')) {
    $value = $c->expand_string($c->test->getAttribute('the'));
  }
  else {
    croak "Nothing to test against";
  }
  
  if ($c->test->hasAttribute('like')) {
    Test::More::like($value, eval $c->expand_string($c->test->getAttribute('like')));
  }
  elsif ($c->test->hasAttribute('equalto')) {
    Test::More::is($value, $c->expand_string($c->test->getAttribute('equalto')));
  }
  else {
    Test::More::is($value, $c->expand_string($c->test->textContent));    
  }
}

sub like {
  my $self = shift;
  my $c = shift;
  my $value = '';
  if ($c->test->hasAttribute('the')) {
    $value = $c->expand_string($c->test->getAttribute('the'));
    Test::More::like($value, eval $c->test->textContent);
  }
}

sub submit_form {
  my $self = shift;
  my $c = shift;
  my %hash;
  _children_to_hash($c, $c->test, \%hash);
  $c->add_response($c->ua->submit_form(%hash));
}

sub default {
  my $self = shift;
  my $c = shift;
  $self->set($c) unless defined $c->stash->{$c->test->getAttribute('name')};
}

sub set {
  my $self = shift;
  my $c = shift;
  my $value = '';
  if ($c->test->hasAttribute('value')) {
    $value = $c->expand_string($c->test->getAttribute('value'));
  }
  else {
    $value = $c->expand_string($c->test->textContent);
  }
  if ($c->test->hasAttribute('replace')) {
    $_ = $value;
    eval $c->test->getAttribute('replace');
    die $@ if $@;
#    Test::More::diag($c->test->getAttribute('filter') . ": $_");
    $value = $_;
  }
  if ($c->test->hasAttribute('match')) {
    $_ = $value;
    eval $c->test->getAttribute('match') . "; \$value = \$1";
    die $@ if $@;
    #Test::More::diag($c->test->getAttribute('match') . ": $_");
  }
  $c->stash->{$c->test->getAttribute('name')} = $value;
}

sub diag {
  my $self = shift;
  my $c = shift;
  Test::More::diag($c->expand_string($c->test->textContent));
}

sub _children_to_hash {
  my $c = shift;
  my $node = shift;
  my $hash = shift;
  foreach my $child ($node->childNodes) {
    next unless $child->nodeType == XML_ELEMENT_NODE;
    if (_has_child_elements($child)) {
      $hash->{$child->localname} = {};
      _children_to_hash($c, $child, $hash->{$child->localname});
    }
    else {
      my $k = $child->localname;
      if ($child->hasAttribute('name')) {
        $k = $child->getAttribute('name');
      }
      $hash->{$k} = $c->expand_string($child->textContent);
    }
  }
}

sub _has_child_elements {
  my $e = shift;
  return $e->childNodes && grep($_->nodeType == XML_ELEMENT_NODE, $e->childNodes);
}

sub _first_child_element {
  my $e = shift;
  my @children = grep($_->nodeType == XML_ELEMENT_NODE, $e->childNodes);
  return $children[0];
}

1;

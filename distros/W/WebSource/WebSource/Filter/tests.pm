package WebSource::Filter::tests;
use strict;
use Carp;
use String::Approx qw/amatch/;

use WebSource::Filter;
our @ISA = ('WebSource::Filter');

=head1 NAME

WebSource::Filter::tests - apply tests to filter xmlnodes

=head1 DESCRIPTION

The tests type of filter allows to declare a series of tests
and apply them to the input data in order to determine whether
or not to send it further on.

The tests are executed in the order of their declaration until one of them
matches. They associated action (keep or reject) is taken. By default the
action is to keep elements matching the test. If the element does not match
any tests it is rejected.

Current existing tests include :

=over 2

=item B<exists> : Succeeds if a given XPATH expression returns a result

=item B<regexp> : Succeeds if a given regular expression matches the input

=item B<approx> : Succeeds of a given string is approximately found in the
                  input
=back

=head1 SYNOPSIS

B<In wsd file...>

<ws:filter name="somename" type="tests">
  <test type="exists" select"<xpath-expr>" action="keep" />
  <test type="regexp"   select="<xpath-expr>"
        match="<regexp>"  action="keep"/>
  <test type="approx"   select="<xpath-expr>"
        match="<pattern>" modifiers="" action="reject" />
  ...
</ws:filter>


=head1 METHODS

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  $self->{wsdnode} or croak("No description node given");
}

sub keep {
  my $self = shift;
  my $env = shift;
  $self->log(3,"Testing");
  $env->type eq "object/dom-node" or return 0; # only works for dom-nodes
  my @nodes = $self->{wsdnode}->findnodes("test");
  my $data = $env->data;
  my $result = undef;
  $self->log(3,"Found ",scalar(@nodes)," test nodes");
  while(!$result && @nodes) {
    my $match = 0;
    my $n = shift @nodes;
    my $type = $n->getAttribute("type");
    $type or $type = "regexp";
    if($type eq "exists") {
      my $select = $n->getAttribute("select");
      my @res = $data->findnodes($n->getAttribute("select"));
      $match = (scalar(@res) > 0);
      $self->log(5,"Existence with '$select' resulted in ",
                   scalar(@res)," nodes ($match)");
    } elsif($type eq "xpath") {
      my $select = $n->getAttribute("select");
      $match = $data->find("boolean(".$n->getAttribute("select").")")->value();
      $self->log(5,"Xpath test with '$select' resulted in $match");
    } else {
      my $str = $data->findvalue($n->getAttribute("select"));
      my $pat  = $n->getAttribute("match");
      if($type eq "regexp") {
        $self->log(3,"Trying to match '$str' with m/$pat/i");
        $match = $str =~ m/$pat/i;
      } elsif($type eq "approx") {
        my $mod = $n->getAttribute("modifiers");
        $self->log(3,"Matching '$str' approximately against",
                   " pattern '$pat' with modifier string '$mod'");
        $match = amatch($pat,[ $mod ],$str);
      }
    }
    if($match) {
      my $action = $n->getAttribute("action");
      $action or $action = "keep";
      $result = $action;
      $self->log(5,"Found a match, taking action : ",$result); 
    }
  }
  return ($result eq "keep");
}

=head1 SEE ALSO

B<WebSource>, B<WebSource::Filter>

=cut

1;

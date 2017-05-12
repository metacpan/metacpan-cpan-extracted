package Tree::Transform::XSLTish::Transformer;
use Moose;
use Moose::Util::TypeConstraints;
use Tree::Transform::XSLTish::Utils;
use Tree::Transform::XSLTish::Context;
use Carp::Clan qw(^Tree::Transform::XSLTish);

our $VERSION='0.3';

subtype 'Tree::Transform::XSLTish::Engine'
    => as 'Object'
    => where {
        return $_->can('findnodes') ? 1 : ();
    };

has 'rules_package' => (is => 'ro', isa => 'ClassName');

has 'context_stack' => (
    traits => ['Array'],
    is => 'rw',
    isa => 'ArrayRef[Tree::Transform::XSLTish::Context]',
    default => sub { [] },
    handles => {
        enter => 'push',
        leave => 'pop',
        has_context => 'count',
    },
);

sub context { return $_[0]->context_stack->[-1] }

has 'engine' => (
    is => 'ro',
    isa => 'Tree::Transform::XSLTish::Engine',
    lazy => 1,
    builder => '_build_engine',
);

sub _build_engine {
    my ($self)=@_;

    if ($self->rules_package) {
        my $factory=$self->rules_package->can($Tree::Transform::XSLTish::Utils::ENGINE_FACTORY_NAME);
        if ($factory) {
            return $factory->();
        }
    }
    require Tree::XPathEngine;
    return Tree::XPathEngine->new();
}

sub it { return $_[0]->context->current_node }

sub transform {
    my ($self,$tree)=@_;

    return $self->apply_rules($self->engine->findnodes('/',$tree));
}

sub apply_rules {
    my ($self,@nodes)=@_;

    unless (@nodes) {
        unless ($self->has_context) {
            carp 'apply_rules called without nodes nor context!';
            return;
        }
        @nodes=$self->engine->findnodes('*',$self->it);
    };

    my $guard=Tree::Transform::XSLTish::ContextGuard->new
        ($self,
         Tree::Transform::XSLTish::Context->new(node_list=>\@nodes)
       );

    my @ret;
    for my $node (@nodes) {
        $self->context->current_node($node);

        #warn "# applying rules to @{[ $node ]}";

        my $rule=$self->find_rule();
        push @ret,$rule->{action}->($self);
    }

    return @ret;
}

sub call_rule {
    my ($self,$name)=@_;

    unless ($name) {
        carp 'call_rule called without a rule name!';
        return;
    }

    unless ($self->has_context) {
        carp 'call_rule called without context!';
        return;
    }

    my $rule=$self->find_rule_by_name($name);
    return $rule->{action}->($self);
}

sub find_rule {
    my ($self,$context)=@_;

    for my $pack (Tree::Transform::XSLTish::Utils::_get_inheritance
          ($self->rules_package)) {
        my $ret=$self->find_rule_in_package($pack,$context);
        return $ret if $ret;
    }

    croak 'No valid rule';
}

sub find_rule_by_name {
    my ($self,$name,$context)=@_;

    for my $pack (Tree::Transform::XSLTish::Utils::_get_inheritance
          ($self->rules_package)) {
        my $ret=$self->find_rule_by_name_in_package($pack,$name,$context);
        return $ret if $ret;
    }

    croak "No rule named $name";
}

sub find_rule_in_package {
    my ($self,$package,$context)=@_;

    $context||=$self->context;

    my $store=Tree::Transform::XSLTish::Utils::_rules_store($package);

    my $rules=$store->{by_match};

    my @candidates=
        sort { $b->{priority} <=> $a->{priority} } ## no critic (ProhibitReverseSortBlock)
            grep { $self->rule_matches($_) } @{$rules};
    if (@candidates > 1 and
            $candidates[0]->{priority} ==
                $candidates[1]->{priority}) {
        croak 'Ambiguous rule application';
    }
    elsif (@candidates >= 1) {
        return $candidates[0];
    }

    return;
}

sub find_rule_by_name_in_package {
    my ($self,$package,$name,$context)=@_;

    $context||=$self->context;

    my $store=Tree::Transform::XSLTish::Utils::_rules_store($package);

    my $rules=$store->{by_name};

    if (exists $rules->{$name}) {
        return $rules->{$name};
    }

    return;
}

sub rule_matches {
    my ($self,$rule,$context)=@_;

    $context||=$self->context;

    my $node=$context->current_node;
    my $path=$rule->{match};

    # XXX check the semantic

    my $base_node=$node;

    # this is a ugly hack
    my $test_sub= ($node->can('isSameNode'))?
        sub { grep { $node->isSameNode($_) } @_ }
            :
        sub { grep { $node eq $_ } @_ };

    while ($base_node) {

        #warn "# Testing <$path> against @{[ $node ]} based on @{[ $base_node ]}";
        my @selected_nodes=$self->engine->findnodes($path,$base_node);
        #warn "#  selected: @selected_nodes\n";
        if ($test_sub->(@selected_nodes)) {
            #warn "ok\n";
            return 1;
        }

        ($base_node)=$self->engine->findnodes('..',$base_node);
    }
    return;
}

__PACKAGE__->meta->make_immutable;no Moose;

package Tree::Transform::XSLTish::ContextGuard; ## no critic (ProhibitMultiplePackages)

sub new {
    my ($class,$trans,$context)=@_;
    $trans->enter($context);
    return bless {trans=>$trans},$class;
}

sub DESTROY {
    $_[0]->{trans}->leave();
    return;
}

1;
__END__

=head1 NAME

Tree::Transform::XSLTish::Transformer - transformer class for L<Tree::Transform::XSLTish>

=head1 METHODS

=head2 C<new>

  $trans=Tree::Transform::XSLTish::Transformer->new(
    rules_package => 'Some::Package',
    engine => $engine_instance,
  );

You usually don't call this constructor directly, but instead use L<<
the C<new> function exported by
Tree::Transform::XSLTish|Tree::Transform::XSLTish/new >>, which passes
the correct C<rules_package> automatically.

If you don't specify an C<engine>, it will be constructed using the
class or factory declared in the rules package; if you didn't declare
anything, it will be an instance of L<Tree::XPathEngine>.

=head2 C<transform>

  @results=$trans->transform($tree);

When you call this function on a tree, the transformer will transform
it according to your rules and to the L<XSLT processing
model|http://www.w3.org/TR/xslt.html#section-Processing-Model>.

C<< $trans->transform($node) >> is equivalent to C<<
$trans->apply_rules($trans->engine->findnodes('/',$node)) >>.

Always call this method in list context.

=head2 C<apply_rules>

   $trans->apply_rules(@nodes);

Just like C<apply-rules> in XSLT, this function will apply the rules
to the specified nodes, or to the children of the current node if none
are passed, and return all the results in a single list.

This will die if there are no matching rules, or if there are more
than one matching rule with highest priority.

Always call this method in list context.

=head2 C<call_rule>

  $trans->call_rule('rule-name');

This fuction will apply the named rule to the current node, and return
the result.

This will die if there is no rule with the given name.

Always call this method in list context.

=head2 C<it>

  $current_node = $trans->it;

Inside a rule, this fuction will return the node to which the rule is
being applied.

=head1 INTERNAL FUNCTIONS

These functions should not be called from outside this module.

=head2 C<find_rule>

For each package in the linearized inheritance chain of the rules
package on which this transformer has been instantiated, calls
L<find_rule_in_package> and returns the first defined result.

=head2 C<find_rule_in_package>

Gets all the rules having a C<match> attribute, filters those for
which L<rule_matches> returns true, sorts them by priority, and returns
the one with the highest priority.

Dies if there is more than one rule with the highest priority; returns
undef if there are no matching rules.

=head2 C<find_rule_by_name>

For each package in the linearized inheritance chain of the rules
package on which this transformer has been instantiated, calls
L<find_rule_by_name_in_package> and returns the first defined result.

=head2 C<find_rule_by_name_in_package>

Returns the rule with the given name, if any; returns undef otherwise.

=head2 C<rule_matches>

Evaluates the C<match> XPath expression in a sequence of contexts, to
see if the current node appears in the resulting node-set. If it does,
returns true; if there is no such context, returns false.

The first context is the current node; following contexts are each the
parent node of the previous one.

NOTE: to check whether a node appears in a node-set, we either use the
C<isSameNode> method, or check the stringifications for equality.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=cut

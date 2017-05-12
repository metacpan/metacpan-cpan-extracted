package Shishi;

use 5.006;
use strict;
use warnings;
use Errno;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Insert the output of genconst here.

our @EXPORT = qw(
        SHISHI_MATCH_TEXT
        SHISHI_MATCH_CHAR
        SHISHI_MATCH_TOKEN
        SHISHI_MATCH_ANY
        SHISHI_MATCH_END
        SHISHI_MATCH_SKIP
        SHISHI_MATCH_TRUE
        SHISHI_MATCH_CODE
        SHISHI_ACTION_CONTINUE
        SHISHI_ACTION_FINISH
        SHISHI_ACTION_FAIL
        SHISHI_AGAIN
        SHISHI_MATCHED
        SHISHI_FAILED
);
our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Shishi::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    }
#XXX    else {
            *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}



bootstrap Shishi $VERSION;

# Preloaded methods go here.

package Shishi::Decision;

sub new {
    my $class = shift;
    my $dec = Shishi::Decision::create();
    my @dolater;

    while (@_) {
        my ($key, $value) = (shift @_, shift @_);
        # Do these last
        if ($key eq "target" or $key eq "code") {
            push @dolater, [$key, $value];
            next;
        }
        # Fixup accessors
        $dec->$key($value);
    }
    for (@dolater) { my $k=$_->[0]; $dec->$k($_->[1]); }
    return $dec;
}

package ShishiDecisionPtr;
use Carp;
my %typemap = 
    map { $_ => eval "Shishi::SHISHI_MATCH_".uc$_."()" }
    qw( skip any true text token code char end);

sub type {
    my $dec = shift;
    if (@_) {
        my $type = shift;
        croak "No such match type $type" unless exists $typemap{$type} or $type =~ /^\d+$/;
        return $dec->target_type($typemap{$type})
    }
    return $dec->target_type();
}

my %actmap =
   map { $_ => eval "Shishi::SHISHI_ACTION_".uc$_."()" }
   qw(continue finish fail);

sub action {
    my $dec = shift;
    if (@_) {
        my $type = shift;
        croak "No such action type $type" unless exists $actmap{$type} or $type =~ /^\d+$/;
        return $dec->_action($actmap{$type})
    }
    return $dec->_action();
}

sub target {
    my $d = shift;
    my $t = shift;
    if ($d->type == Shishi::SHISHI_MATCH_CHAR() || $d->type == Shishi::SHISHI_MATCH_TOKEN()) {
        $d->token($t);
    } elsif ($d->type == Shishi::SHISHI_MATCH_TEXT()) {
        $d->text($t);
    } else {
        die "Don't know how to handle target of type ", $d->type;
    }
}

sub token {
    my $d = shift;
    if (@_) {
        $d->_token(ord $_[0]);
    } else { $d->_token() }
}
*char = *token;

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Shishi - Perl wrapper for the C<shishi> parsing library

=head1 SYNOPSIS

  use Shishi;

  # Create a parser
  my $parser = new Shishi("some name");

  # Add a basic node
  my $nodea = Shishi::Node->new("start");
  $parser->add_node($nodea);

  # Add a node with a simple rule:
  # State C: match 'c' -> go to ACCEPT state
  my $nodec = Shishi::Node->new("C")->add_decision(
        new Shishi::Decision(target => 'c', type => 'char', action => 'finish')
  );

  # State B: match 'b' -> go to state C
  my $nodeb = Shishi::Node->new("B")->add_decision(
        new Shishi::Decision(target => 'b', type => 'char', action => 'continue',
        next_node=>$nodec));

  # From the first node: match 'a' -> go to state B
  $parser->start_node->add_decision(
     new Shishi::Decision(target => 'a', type => 'char', action => 'continue',
                          next_node => $nodeb)
  );

  # Tell the parser that these states belong. (Helps with GC)
  $parser->add_node($nodeb);
  $parser->add_node($nodec);

  # We now have a state machine which accepts 'abc':
  ok(!$parser->execute(Shishi->new_match("ab")));
  ok($parser->execute(Shishi->new_match("abc")));

=head1 DESCRIPTION

The C<shishi> library is a tool for creating state machines for parsing text.
Unlike most implementations of finite state automata, it doesn't use a 
transition table, but more directly implements the structure of a 
transition network diagram; that's to say, you have nodes which represent
states, and decisions which represent the arrows between states. The reason
for this rather curious design decision is to allow you to modify the state
machine while it's running, something you'll want to do if you're dealing
with user-modifiable grammars.

To do anything with shishi, you need a parser; parsers are labelled for
debugging purposes, so create one like this:

    my $parser = new Shishi ("my parser");

Now your parser needs some states:

    my $node = new Shishi::Node ("first") ;
    $parser->add_node($node);

    my $node2 = new Shishi::Node ("last") ;
    $parser->add_node($node2);

And now you need to have some transitions between those states; these are
called "decisions".

    $node->add_decision(
        target => "abc", 
        type => "text", 
        action => "continue",
        next_node => $node2
    );

This moves from the C<first> node to the C<last> node if it sees the text
C<abc>. Actually, moving to an accept state is also a transition.

    $node2->add_decision(
        type => "end",
        action => "finish"
    );

This says that we should accept the string if this we're now at the end
of the string. Otherwise, we fail.

As you can see, a decision has both a matching rule ("if you match the text
abc", "if you match the end of the string") and an action ("then move to
node 2", "then accept the string"). Here are the possible match types:

=head2 MATCH TYPES

=over 3

=item C<text>

Matches a string exactly. Pass the string in as C<target>.

=item C<char>

Matches a single character; equivalent to C<text> but more efficient for
single-character matching.

=item C<token>

Equivalent to C<char> currently; will be used to implement both parsing
(passing tokens instead of characters) and Unicode character support (token
values outside the range 0-255) in future versions.

=item C<end>

Match only the end of the string. Equivalent to the C<$> atom in
regular expressions. 

=item C<skip>, C<any>

Matches any character. Equivalent to C<.> in regular expressions.

=over 3 

=item Hint

This is particularly useful for doing non-anchored matches. Normally,
shishi begins matching at the start of a string, as if the C<^> RE
atom was a default. To "undo" this an allow non-anchored matches, do
this:

    $foo->start_node->add_decision(
     new Shishi::Decision(type => 'skip', next_node => $foo->start_node,
     action => 'continue')
    );

=back

=item C<true>

Always matches.

=item C<code>

Executes the supplied comparison function. Pass a subroutine in as C<code>.

The subroutine is called with the following parameters: the current
C<Shishi::Decision> being executed; the text to be parsed; the C<Shishi> parser
object; the C<Shishi::Match> object.

You're currently not able to modify the text. This will be fixed.

=back

=head2 ACTIONS

As for actions, you have the choice of:

=over 3

=item C<continue>

Transition to another node in the network, specified with C<next_node>.

=item C<finish>

Accept, return success.

=item C<fail>

Abort the match completely.

=back

Other actions, such as C<shift> and C<reduce>, may appear in time.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=cut

package Text::PromptBalanced;

use strict;
use warnings;

require Exporter;

use vars qw(@ISA $VERSION @EXPORT_OK);
@ISA = qw(Exporter);
$VERSION = 0.02;
@EXPORT_OK = qw(balance_factory);

# {{{ sub balance_factory
sub balance_factory {
  my %config = @_;
  # {{{ Clean up configuration
  # Assign default behavior
  #
  if(defined $config{escape} and !ref($config{escape})) {
    $config{escape} = { type => 'escape', open => '\\' }
  }
  # We implement the 'ignore_in' behavior of comments in code, so no
  # rejiggering of the hash should be needed.

  # Canonicalize the hash.
  # This basically means changing 'ignore_in' string values to arrays.
  #
  for my $key (keys %config) {
    next unless defined $config{$key}{ignore_in};
    next if ref($config{$key}{ignore_in});
    $config{$key}{ignore_in} = [$config{$key}{ignore_in}];
  }
  # }}}
  # {{{ Build state hash
  my $state = {};
  for(keys %config) {
    # An end-of-line comment is only valid until the end of the input line, so
    # it will never have any state.
    # Escape characters by design don't affect balance, so they don't have
    # a state either.
    #
    next if $_ eq 'comment' and $config{$_}{type} eq 'to-eol';
    next if $_ eq 'escape';
    $state->{$_} = 0;
  }
  # }}}
  # {{{ Build actions
  my $action = {};
  for my $key (keys %config) {
    my $conf = $config{$key};
    my $type = $conf->{type};
    # {{{ Balanced
    if($type eq 'balanced') {
      $action->{$conf->{open}} = {
        type => $type,
        name => $key,
        action => sub { $state->{$key}++ },
        ignore_in => $conf->{ignore_in},
      };
      $action->{$conf->{close}} = {
        type => $type,
        name => $key,
        action => sub { --$state->{$key} },
        ignore_in => $conf->{ignore_in},
      };
    }
    # }}}
    # {{{ Unbalanced
    elsif($type eq 'unbalanced') {
      $action->{$conf->{open}} = {
        type => $type,
        name => $key,
        action => sub { $state->{$key} = 1 },
        ignore_in => $conf->{ignore_in},
      };
      $action->{$conf->{close}} = {
        type => $type,
        name => $key,
        action => sub { $state->{$key} = 0 },
        ignore_in => $conf->{ignore_in},
      };
    }
    # }}}
    # {{{ To-EOL
    elsif($type eq 'to-eol') {
      $action->{$conf->{open}} = {
        type => $type,
        name => $key,
        ignore_in => $conf->{ignore_in} },
    }
    # }}}
    # {{{ Toggle
    elsif($type eq 'toggle') {
      $action->{$conf->{open}} = {
        type => $type,
        name => $key,
        action => sub { $state->{$key} = !$state->{$key} },
        ignore_in => $conf->{ignore_in},
      };
    }
    # }}}
    # {{{ Escape
    elsif($type eq 'escape') {
      $action->{$conf->{open}} = {
        type => $type,
        name => $key,
        ignore_in => $conf->{ignore_in},
      };
    }
    # }}}
  }
  # }}}
  # {{{ Build the closure
  return (
    $state,
    sub {
      my $input = shift;
      # {{{ Main loop
      my $cur_char = 0;
      my $escape = 0;
      SPLIT: for my $char(split //,$input) {
        $cur_char++;
        next unless exists $action->{$char}; # Skip non-metacharacters
        # {{{ Handle meta characters
        # Escape characters simply suppress the meta nature of the next
        # character to come along.
        #
        if($escape == 1) {
          $escape = 0;
          next;
        }
        elsif($action->{$char}{type} eq 'escape') {
          $escape = 1;
          next;
        }
        # }}}
        # {{{ Handle comments
        # Effectively skip to the end if a comment to the end of line is
        # encountered, unless the comment should be ignored.
        #
        if($action->{$char}{type} eq 'to-eol' and
           $action->{$char}{name} eq 'comment') {
          for(@{$action->{$char}{ignore_in}}) {
            next SPLIT if $state->{$_} > 0; 
          }
          last;
        }
        # }}}
        # {{{ Handle ignore_in tags
        for(@{$action->{$char}{ignore_in}}) {
          next SPLIT if $state->{$_} == 1;
        }
        $action->{$char}{action}->();
        # }}}
      }
      # }}}
      # {{{ The string is balanced only if all states are zero.
      for my $key (keys %$state) {
        next if $state->{$key} == 0;
        return 0;
      }
      return 1;
      # }}}
    }
  );
  # }}}
}
# }}}

1;
__END__

=head1 NAME

Text::PromptBalanced - Aid in creating CLI prompts that keep track of balanced text

=head1 SYNOPSIS

  use Text::PromptBalanced qw(balance_factory);
  ($state,$balance) = balance_factory(
    string => { type => 'toggle', open => '"' },
    paren => {
      type => 'balanced', open => '(', close => ')', ignore_in => 'string' },
    comment => { type =>' eol', open => ';', ignore_in => 'string' },
    escape => { type => 'escape', open => '\\' }
  );
  while(<STDIN>) {
    my $cur_balance = $balance->($_);
    if($state->{string}==1) { print q["> ] }
    elsif($state->{paren} > 0) { print qq[($cur_balance> ] }
    elsif($cur_balance < 0)
      { warn "Unbalanced paren at character $cur_balance" }
    else { print q[0> ] }
  }

=head1 DESCRIPTION

This is intended to be an aide to help generate the prompt strings that are
presented by applications like Postgres' psql tool and various Lisp compilers.

Specifically, these types of applications have prompts that tell the user how
deeply their parenthesis count is nested, and/or if they have closed strings
yet. The sole subroutine in this module creates and returns a function which is
designed to be called on every line of text a user inputs, and keeps track of
whether the parentheses, braces, strings, or what-have-you match as the user
types the input in.

For example, a typical interaction with the application might appear as follows:

  0> (+ 3 4)
  7
  0> (+ (* 2 -1)
  1> 2)
  0
  0> (print "(Hi there
  "> world")
  0> 

Note that the prompt changes from "0> " to "1> " when the user fails to close
a parenthesis. Also, later on notice that it informs the user that the string
has not been finished, but ignores the C<(> inside the string. This behavior
naturally is configurable when the parser is created.

The parser currently understands five basic types of nested and non-nested
constructs. Nested constructs include parentheses, braces and occasionally
brackets. Non-nested constructs can be things like UNIX and C comments, and
strings.

To make things even more flexible, constructs can be selectively ignored inside
others. For instance, you can choose to ignore (as we did above) parentheses
when inside a string, or ignoring strings inside of a C comment.

Constructs are specified to the parser roughly as follows (Taking our example
from earlier):

  ($state,$b) = balance_factory(
    parentheses => { # Give the type a name
      type => 'balanced', # Count occurrences of this type in and out
      open => '(', close => ')',
      ignored_in => 'string' }, # Ignore these when inside a string
    string => {
      type => 'toggle', # Occurrences of this type flip a toggle on and off.
      open => q<"> }, # Toggle on q<">.
  );

This tells the parser to keep track of C<(> and C<)>, as long as they're outside
(which is a synonym for 'ignored_in', incidentally) a string. The string
definition merely says to toggle the 'string' flag on and off as C<"> is
encountered while scanning the string. A running balance is kept as more lines
get fed to C<$b->($input)>, and the C<$state> variable changes as each new
character sequence is encountered.


The C<$state> is a hashref, with (in this case) keys 'parentheses' and 'string'.
You can inspect or change this state as you desire, and set your prompt
accordingly. The return values are in the reverse order from what you'd expect
so that the code fragment C<$b = balance_factory();> works with minimal fuss,
yet you can still get access to the internal state.

=over

=item balanced

Useful for parentheses, braces and brackets, this keeps a running count of the
number of left and right parentheses, with C<(> incrementing and C<)>
respectively decrementing the count. If the count should ever go negative, the
balance function returns a negative number equal to the position of the
character in the input string.

A sample configuration looks like:

  brace => { type => 'balanced', open => '{', close => '}' }

=item unbalanced

C comments fall into this category, and not much else. This type has both an
'open' and 'close' specifier like its cousin C<balanced>, but the count will
never go higher than one, so C</* /* foo */> would report as balanced, even
though the "second /*" never gets balanced out. Sample configuration is the
same as the C<balanced> type.

=item to-eol

Designed for UNIX and C++-style comments, a C<to-eol> comment starts when the
appropriate character (say, '#') is encountered, and runs until the end of the
line, when it is turned off. Thus, it will never be a factor in balancing, but
it still is represented by a state, in case you want to play with this.

Since its 'close' character is the end of the line, it need not be specified.
When configuring for a comment, just specify:

  'c++-style' => { type => 'to-eol', open => '//' }

=item toggle

Toggles start out off, and are simply switched each time their character is
encountered while scanning. The most common uses for this will be strings, most
likely. Perl strings are probably beyond the scope of this utility, although
patches are welcome...

Configure a string like this:

  'string' => { type => 'toggle', open => q<"> }

=item escape

Escape characters behave just like they do in any language. An escape character
before any special character (or any other, for that matter) nullifies any
meaning it might have had. The escape character is common enough that it's
given its own shortcut, C<escape => 1>. If you feel the need to specify a
character other than C<\\>, it follows the same format as the toggle above:

  'escape' => { type => 'escape', open => q<\\> }

=back

The names 'comment' and 'escape' are considered special. To wit, if a 'comment'
type is declared, all other types are ignored until the comment is finished.
If for whatever reason you want to override this behavior, simply name your type
something other than 'comment'.

The 'escape' type just needs to be defined as 'escape => 1' to get the common
definition of C<\\>. Other strings can be specified as desired. Last but not
least, types can be ignored within other types.

For instance, you probably don't want to count parentheses inside strings. To
arrange for this behavior, add C<ignore_in => 'string'> to the list of keys
in 'parentheses'. If you want a type to be ignored within any of a list of
other types, pass a list of those types instead of 'string'.

=head2 EXPORT

By default, C<balance_factory>

=head1 SEE ALSO

L<Term::Readline>, L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

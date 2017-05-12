package Test::NameNote;
use strict;
use warnings;
our $VERSION = '0.04';

=head1 NAME

Test::NameNote - add notes to test names

=head1 SYNOPSIS

Adds notes to test names in L<Test::Builder>-based test scripts.

  use Test::More tests => 10;
  use Test::NameNote;

  ok foo(), "foo true";
  foreach my $foo (0, 1) {
      my $n1 = Test::NameNote->new("foo=$foo");
      foreach my $bar (0, 1) {
          my $n2 = Test::NameNote->new("bar=$bar");
          is thing($foo, $bar), "thing", "thing returns thing";
          is thang($foo, $bar), "thang", "thang returns thang";
      }
  }
  ok bar(), "bar true";

  # prints:
  1..10
  ok 1 - foo true
  ok 2 - thing returns thing (foo=0,bar=0)
  ok 3 - thang returns thang (foo=0,bar=0)
  ok 4 - thing returns thing (foo=0,bar=1)
  ok 5 - thang returns thang (foo=0,bar=1)
  ok 6 - thing returns thing (foo=1,bar=0)
  ok 7 - thang returns thang (foo=1,bar=0)
  ok 8 - thing returns thing (foo=1,bar=1)
  ok 9 - thang returns thang (foo=1,bar=1)
  ok 10 - bar true

=cut

use Test::Builder;
use Sub::Prepend 'prepend';

our @_notes;
our $_wrapped_test_group_ok = 0;

_wrap('Test::Builder::ok');

sub _wrap {
    my $target = shift;

    prepend $target => sub {
        if (@_notes) {
            # Append any current notes to the test name in $_[2].
            my $note = join ',', map {$$_} @_notes;
            if (defined $_[2] and length $_[2]) {
                $note = "$_[2] ($note)";
            }
            @_ = (@_[0,1], $note, @_[3,-1]);
        } 
    };
}

=head1 CONSTRUCTORS

=over

=item new ( NOTE )

Builds a new C<Test::NameNote> object for the specifed NOTE text.  The note
will be added to the names of all L<Test::Builder> tests run while the
object is in scope.

=cut

sub new {
    my ($pkg, $note) = @_;

    if (!$_wrapped_test_group_ok and
                            exists &Test::Builder::_HijackedByTestGroup::ok) {
        _wrap('Test::Builder::_HijackedByTestGroup::ok');
        $_wrapped_test_group_ok = 1;
    }

    push @_notes, \$note;
    return bless { NoteRef => \$note }, ref($pkg)||$pkg;
}

=back

=cut

sub DESTROY {
    my $self = shift;

    @_notes = grep {$_ ne $self->{NoteRef}} @_notes;
}

=head1 AUTHOR

Nick Cleaton, C<< <nick at cleaton dot net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nick Cleaton, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

package Test::Smart::Question;

use strict;
use warnings;
use Carp;

=head1 NAME

Test::Smart::Question - Data wrapper for Test::Smart questions

=head1 DESCRIPTION

This object provides basic semantics and data encapsulation for Test::Smart
questions, feel free to subclass it as you need when writing Interfaces.

=head1 SYNOPSIS

  use Test::Smart::Question;

  $Qobj = Test::Smart::Question->new(question => "I can has cheesburger?",
                                     name     => "Cheesburger",
                                     id       => "Uniq123");

  $Qobj->skip("The person being asked doesn't know how to answer");
  $Qobj->test;

  $Qobj->answer('yes','commentary or diagnostics');
  ($answer,$comment) = $Qobj->answer;
  $answer = $Qobj->answer;

=head1 DETAILS

=head2 new(question => $question_text,id => $uniq_id, [name => $test_name,skip => $reason,other_key => $other_value])

The constructor takes its params as a hash, requiring question and id and
optionally taking name and skip. If skip is set it is equivalent to calling
C<< $Qobj->skip("Reason") >> with all of the semantic implications (you can no
longer provide an answer unless you explicitly call C<< $Qobj->test >>).

Test::Smart::Question also stores any other keys given to it in the blessed
hashref for the convinence of any Interface implementer who doesn't need a full
subclass. These should probably be treated as private unless documented
otherwise in the Interface's documentation.

=cut

sub new {
  my $class = shift;
  my %args = @_;
  
  my $self = {};
  $self->{_id}       = $args{id};
  $self->{_question} = $args{question};

  die "Test::Smart::Question requires a question and an id in the constructor"
    unless defined $self->{_id} and $self->{_question};

  $self->{_name}     = $args{name};
  $self->{_skip}     = $args{skip};
  foreach my $key (grep { $_ !~ /question|name|id/ } keys %args) {
    $self->{$key} = $args{$key};
  }
  bless $self,$class;
}

=head2 question

This is a read only accessor for the question string provided at object
construction. If you try to set question it simply ignores the pass.

=cut

sub question {
  my $self = shift;
  return $self->{_question};
}

=head2 id

Like C<question> but for the constructor set ID.

=cut

sub id {
  my $self = shift;
  return $self->{_id};
}

=head2 name([$new_name])

Mutator for the stored test name. This value is used when answering the
question for TAP output in the same way as the second parameter to C<ok>

=cut

sub name {
  my ($self,$name) = @_;
  $self->{_name} = $name if defined($name);
  return $self->{_name};
}

=head2 skip([$reason])

Sets the internal skip value. Once set it cannot be undefed unless you use
C<< $Qobj->test >> to indicate you do indeed want to test with this Question.
While a skip reason is set the object will silently reject answers submitted to
it.

=cut

sub skip {
  my ($self,$reason) = @_;
  $self->{_skip} = $reason if defined($reason);
  return $self->{_skip};
}

=head2 test

Indicate to the object that you're going to test it, which means it should
accept an answer and clear skip.

=cut

sub test {
  my $self = shift;
  $self->{_skip} = undef;
}

=head2 answer([$answer, $comment])

Mutator for the object's stored answer. When setting it the first parameter
must match C</yes|no/i> and should reflect the answer provided by the person.
If diagnostics or commentary is required it is provided in the $comment param,
though this is optional.

If there is currently a reason for skipping set (either through skip or in the
constructor) then answer will simply return undef and do nothing. You also 
cannot retrieve the answer if skip gets set.

=cut

sub answer {
  my ($self,$answer,$comment) = @_;

  return undef if defined($self->{_skip});
  return wantarray ? ($self->{_answer},$self->{_comment}) : $self->{_answer} unless defined($answer);
  croak "Answer must be yes or no, not [$answer]" unless $answer =~ /yes|no/i;

  ($self->{_answer},$self->{_comment}) = ($answer,$comment);
  return wantarray ? ($self->{_answer},$self->{_comment}) : $self->{_answer};
}

=head1 SUBCLASSING

If you want to make a custom interface for Test::Smart look at
L<Test::Smart::Interface>. If you do find the need to write something so
fancy that you must also subclass this, make sure your subclass is a perfect
drop-in replacement or else you'll break Test::Smart itsself.

=head1 SEE ALSO

L<Test::Smart>, L<Test::Smart::Interface>

=head1 AUTHOR

Edgar A. Bering, E<lt>trizor@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Edgar A. Bering

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
1;

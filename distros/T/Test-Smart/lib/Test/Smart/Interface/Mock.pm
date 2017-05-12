package Test::Smart::Interface::Mock;

use strict;
use warnings;
use base 'Test::Smart::Interface';

=head1 NAME

Test::Smart::Interface::Mock - Mock interface for testing Test::Smart

=head1 SYNOPSIS

  use Test::Smart;

  initialize('Test::Smart::Interface::Mock',
              answer  => 'always do this',
              comment => 'saying this about it',
              skip    => 'or skip because of this',
              error   => 'or give this error');

  # do some testing here to make sure Test::Smart
  # reacts properly.

=head1 DESCRIPTION

This is for internal testing. If you're re-implementing Test::Smart you might
find it useful yourself.

=cut

sub load {
  my $class = shift;
  my %args = @_;
  my $self = {};

  $self->{_answer} = $args{answer};
  $self->{_comment} = $args{comment};
  $self->{_skip} = $args{skip};
  $self->{_error} = $args{error};

  bless $self,$class;
}

sub submit {
  my ($self,$question,$name) = @_;

  $self->err($self->{_error}), return undef if $self->{_error};
  return Test::Smart::Question->new(question=>$question,
                                    name=>$name,
                                    id=>"id",
                                    skip=>$self->{_skip}) if $self->{_skip};
  return Test::Smart::Question->new(question=>$question,name=>$name,id=>"id");
}

sub has_answer {
  return 1;
}

sub answer {
  my ($self,$Qobj) = @_;

  $self->err($self->{_error}), return undef if $self->{_error};
  $Qobj->answer($self->{_answer},$self->{_comment});
}

=head1 AUTHOR

Edgar A. Bering, E<lt>trizor@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Edgar A. Bering

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;

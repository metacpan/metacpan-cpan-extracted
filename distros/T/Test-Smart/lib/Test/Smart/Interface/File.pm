package Test::Smart::Interface::File;

use strict;
use warnings;
use base qw(Test::Smart::Interface);

use File::Spec::Functions;
use File::Path;

use Test::Smart::Question;

=head1 NAME

Test::Smart::Interface::File - File based human interface layer for Test::Smart

=head1 SYNOPSIS

  use Test::Smart;

  initialize('Test::Smart::Interface::File',directory => '/home/tester');

  # Test::Smart normally from here

=head1 DESCRIPTION

=cut

sub load {
  my $class = shift;
  my %args  = @_;
  my $self  = {};
  $self->{_nextid}     = 0;
  $self->{_dir}       = $args{dir} ||= $args{directory} ||= '.';
  $self->{_questions} = [];

  unless( -e $self->{_dir}) {
    $self->{_dircreat} = 1;
    mkpath($self->{_dir}) or return undef;
  }

  bless $self,$class;
}

sub submit {
  my ($self,$question,$name) = @_;
  
  my $Qobj = Test::Smart::Question->new(
               question =>$question,
               name     =>$name,
               id       =>$self->{_nextid});

  push @{$self->{_questions}},$self->{_nextid};

  $self->{_nextid}++;

  open my $qfile, '>', $self->_get_filename($Qobj->id ,"q") or
    $self->err("Could not open question file: $!") and return undef;

  print $qfile <<QUESTION;
$name
---------
$question
QUESTION

  close $qfile;

  return $Qobj;
}

sub has_answer {
  my ($self,$Qobj) = @_;

  my @names = map { $self->_get_filename($Qobj->id,$_) } qw(y n s);

  foreach (@names) {
    return 1 if -e $_;
  }

  return 0;
}

sub answer {
  my ($self,$Qobj) = @_;

  $self->err('Question does not have an answer yet') and return undef unless $self->has_answer($Qobj);
  my $id = $Qobj->id;

  $Qobj->answer('yes',scalar $self->_getcomments($id,'y')), return 1 if $self->_is_y($id);
  $Qobj->answer('no',scalar $self->_getcomments($id,'n')), return 1 if $self->_is_n($id);
  $Qobj->skip(scalar $self->_getcomments($id,'s')),  return 1 if $self->_is_s($id);

  return undef;
}

sub _get_filename {
  my ($self,$id,$suffix) = @_;
  
  return catfile($self->{_dir},"question-$id.$suffix");
}

sub _getcomments {
  my ($self,$id,$suffix) = @_;

  open my $commentfile,'<',$self->_get_filename($id,$suffix);
  my @commentlines = <$commentfile>;
  close $commentfile;
  
  return wantarray ? @commentlines : join '',@commentlines;
}

foreach my $suffix (qw(y n s)){
  no strict 'refs';
  *{__PACKAGE__."::_is_$suffix"} = sub {
    my ($self,$id) = @_;
    return -e $self->_get_filename($id,$suffix);
  };
}

sub DESTROY {
  my $self = shift;

  foreach my $qid (@{$self->{_questions}}) {
    unlink glob catfile $self->_get_filename($qid,"*");
  }

  rmdir $self->{_dir} if $self->{_dircreat};
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

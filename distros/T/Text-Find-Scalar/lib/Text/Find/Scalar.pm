package Text::Find::Scalar;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.06';

sub new{
  my ($class) = @_;
  
  my $self = {};
  bless $self,$class;
  
  $self->_Counter(0);
  
  return $self;
}# new

sub find{
  my ($self,$text) = @_;
  my @array = ();
  $self->_Counter(0);
  if(defined $text){
    $text =~ s,<<'(.*?)'.*?\n\1,,sg;
    $text =~ s,'.*?',,sg;
    $text =~ s,q~.*?~,,sg;
    @array = $text =~ m/(?:(\$\w+(?:->)?(?:\[\$?\w+\]|\{\$?\w+\}))|(\$\{\w+\})|(\$\w+))/sg;
    @array = grep{defined}@array;
  }
  $self->_Elements(@array);
  return wantarray ? @{$self->_Elements()} : $self->_Elements();
}# find

sub unique{
  my ($self) = @_;
  my %seen;
  my @unique = grep{!$seen{$_++}}@{$self->_Elements()};
  return \@unique;
}# unique

sub count{
  my ($self,$name) = @_;
  my %counter;
  $counter{$_}++ for(@{$self->_Elements()});
  return $counter{$name};
}# count

sub hasNext{
  my ($self) = @_;
  my $count = $self->_Counter();
  if($count > scalar(@{$self->_Elements()}) - 1){
    return 0;
  }  
  return 1;
}# hasNext

sub nextElement{
  my ($self)  = @_;
  my $count   = $self->_Counter();
  my $all     = $self->_Elements();
  my $element = undef;
  if($count < scalar(@$all)){
    $element = ${$all}[$count];
  }
  $self->_Counter(++$count);
  return $element;
}# nextElement

sub _Counter{
  my ($self,$count) = @_;
  $self->{Counter} = $count if(defined $count);
  return $self->{Counter};
}# _Counter

sub _Elements{
  my ($self,@elements) = @_;
  $self->{Elements} = [@elements] if(scalar(@elements) > 0);
  return $self->{Elements};
}# _Elements

1;

=pod

=encoding UTF-8

=head1 NAME

Text::Find::Scalar

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Text::Find::Variable;
  
  my $finder = Text::Find::Variable->new();
  my $arrayref = $finder->find($string);
  
  # or
  
  $finder->find($string);
  while($finder->hasNext()){
    print $finder->nextElement();
  }

=head1 DESCRIPTION

This Class helps to find all Scalar variables in a text. It is recommended to
use L<PPI> to parse Perl programs. This module should help to find SCALAR names
e.g. in Error messages.

Scalars that should be found:

=over 10

=item * double quoted

  "$foo"

=item * references

  $foo->{bar}

=item * elements of arrays

  $array[0]

=back

Scalars that are not covered

=over 10

=item * single quoted

  '$foo'

=item

=back

=head1 NAME

Text::Find::Scalar - Find scalar names in a text.

=head1 EXAMPLE

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use Text::Find::Scalar;
  
  my $string = q~This is a $variable
         another $variable and another "$eine", but '$no' is not found.
         A $reference->{$key} is found. An array element $array[0]
         is also found~;
  
  my $finder = Text::Find::Scalar->new();
  my @scalars = $finder->find($string);
  
  print $_,"\n" for(@scalars);

prints

  /homes/reneeb/community>find_scalar.pl
  $variable
  $variable
  $eine
  $reference->{$key}
  $array[0]

=head1 METHODS

=head2 new

  my $finder = Text::Find::Scalar->new();

creates a new Text::Find::Scalar object.

=head2 find

  my $string = q~Test $test $foo '$bar'~;
  my $arrayref = $finder->find($string);
  my @found    = $finder->find($string);

parses the text and returns an arrayref that contains all matches.

=head2 hasNext

  while($finder->hasNext()){
    print $finder->nextElement();
  }

returns 1 unless the user walked through all matches.

=head2 nextElement

  print $finder->nextElement();
  print $finder->nextElement();

returns the next element in list.

=head2 unique

  my $uniquenames = $finder->unique();

returns an arrayref with a list of all scalars, but each match appears just once.

=head2 count

  my $counter = $finder->count('$foo');

returns the number of appearances of one scalar.

=head2 "private" methods

=head3 _Elements

returns an arrayref of all scalars found in the text

=head3 _Counter

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Renee Baecker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# Below is stub documentation for your module. You'd better edit it!


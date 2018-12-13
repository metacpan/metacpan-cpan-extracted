package Text::Find::Scalar;

# ABSTRACT: Find scalar names in a text.

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.09';

sub new {
    my ($class) = @_;

    my $self = {};
    bless $self,$class;

    $self->_counter(0);

    return $self;
}# new

sub find {
    my ($self,$text) = @_;
    my @array = ();

    $self->_counter(0);

    return if !defined $text;
    return if ref $text;

    $text =~ s,<<'(.*?)'.*?\n\1,,sg;
    $text =~ s,'.*?',,sg;
    $text =~ s,q~.*?~,,sg;

    @array = $text =~ m/(?:(\$\w+(?:->)?(?:\[\$?\w+\]|\{\$?\w+\}))|(\$\{\w+\})|(\$\w+))/sg;
    @array = grep{defined}@array;

    $self->_elements(@array);

    return wantarray ? @{$self->_elements()} : $self->_elements();
}# find

sub unique {
    my ($self) = @_;

    my %seen;
    my @unique = grep{!$seen{$_}++}@{$self->_elements()};

    return \@unique;
}# unique

sub count {
    my ($self, $name) = @_;

    return if !defined $name;
    return if $name !~ m{\A\$};

    my %counter;
    $counter{$_}++ for @{ $self->_elements };

    return $counter{$name};
}

sub hasNext{
    my ($self) = @_;

    my $count = $self->_counter();

    return 0 if $count > $#{ $self->_elements };
    return 1;
}

sub nextElement{
    my ($self)  = @_;

    my $count   = $self->_counter();
    my $all     = $self->_elements();

    my $element = undef;

    if( $count < scalar @$all ) {
        $element = $all->[$count];
    }

    $self->_counter(++$count);

    return $element;
}# nextElement

sub _counter{
    my ($self,$count) = @_;

    $self->{Counter} = $count if defined $count;

    return $self->{Counter};
}# _Counter

sub _elements{
    my ($self,@elements) = @_;

    $self->{Elements} = [@elements] if scalar @elements > 0;

    return $self->{Elements};
}# _Elements

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Find::Scalar - Find scalar names in a text.

=head1 VERSION

version 0.09

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

This class helps to find all scalar variables in a text. It is recommended to
use L<PPI> to parse Perl programs. This module should help to find SCALAR names
e.g. in error messages.

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

creates a new C<Text::Find::Scalar> object.

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

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Renee Baecker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

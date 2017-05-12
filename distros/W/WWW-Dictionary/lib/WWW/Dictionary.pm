package WWW::Dictionary;

use warnings;
use strict;

use WWW::Mechanize;
use HTML::Strip;

=head1 NAME

WWW::Dictionary - Interface with www.dictionary.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @unwanted;

BEGIN {

  our @unwanted = (
    'CancerWEB\'s On-line Medical Dictionary',
    'Download Now or Buy the Book',
    'in Acronym Finder',
  );

}

=head1 SYNOPSIS

    use WWW::Dictionary;

    my $dictionary = WWW::Dictionary->new();

    my $meaning = $dictionary->meaning( $word );

=head1 FUNCTIONS

=head2 new

Creates a new WWW::Dictionary object.

If passed an expression, sets that expression to the current one.

  my $dictionary = WWW::Dictionary->new();

or

  my $dictionary = WWW::Dictionary->new('current expression');

=cut

sub new {
  my $self       = shift;
  my $expression = shift || '';

  my %dictionary = (
    'current'    => $expression,
    'dictionary' => {},
  );

  bless \%dictionary => $self;
}

=head2 set_expression

Sets the current expression to look for (doesn't look, merely sets the expression).

  $dictionary->set_expression('new expression');

Returns the same expression.

=cut

sub set_expression {
  my $self = shift;

  my $expression = shift;

  if ($expression) {
    $self->{'current'} = $expression;
  }

  return $expression;
}

=head2 get_expression

Returns the current expression.

  my $expression = $dictionary->get_expression();

=cut

sub get_expression {
  my $self = shift;

  return $self->{'current'};
}

=head2 get_meaning

Returns the meaning of the current expression by fetching from
www.dictionary.com.

If the expression has already been fetched (if it still has the
information stored), returns what is already on memory.

  my $meaning = $dictionary->get_meaning();

You can also pass a new expression, which is set to be the current
expression before fetching is made:

  my $meaning = $dictionary->get_meaning('some other expression');

=cut

sub get_meaning {
  my $self = shift;

  my $expression = shift;

  if ($expression) {
    $self->set_expression($expression);
  }
  else {
    $expression = $self->get_expression();
  }

  if (defined $self->{'dictionary'}->{$expression}) {
    return $self->{'dictionary'}->{$expression};
  }
  else {

    # retrieve the webpage
    my $mech = WWW::Mechanize->new();

    $mech->get( "http://dictionary.reference.com/search?q=$expression" );

    my $cont = $mech->content;

    # if there's no meaning
    if ( $cont =~ /No entry found for <i>$expression<\/i>./ ) {
      $self->set_meaning( $expression, "Entry not found");
    }
    # if there's a meaning
    else {

      # remove extra information
      $cont =~ s/(.|\n)*?1 entry found for <i>$expression<\/i>.*//;
      $cont =~ s/(.|\n)*?entries found.*//;
      $cont =~ s/.*Perform a new search(.|\n)*//;

      # strip HTML
      my $hs = HTML::Strip->new();

      my $clean_text = $hs->parse( $cont );

      $clean_text =~ s/\nSource : .*//g; # we don't want no sources
      $clean_text =~ s/(\012\r|\r\012|\r)/\012/g; # removing trailing ^M

      # remove unwanted things
      for (@unwanted) {
        $clean_text =~ s/.*$_.*//;
      }

      $clean_text =~ y/ / /s; # compact spaces left by cleaning HTML

      $clean_text =~ s/\n\n\n+/\n\n/g; # compact empty newlines
      $clean_text =~ s/^\n+//; # remove leading newlines
      $clean_text =~ s/\n+$//; # remove trailing newlines

      $clean_text =~ s/\s*$expression$//;

      # store the meaning
      $self->set_meaning( $expression, $clean_text);

    }

    return $self->{'dictionary'}->{$expression};
  }
}

=head2 set_meaning

Sets a meaning in the object dictionary.

  $dictionary->set_meaning( $word, $meaning );

From this point on (until a C<reset_dictionary> is called), retrieving
the meaning of $word will return whatever was on $meaning.

=cut

sub set_meaning {
  my $self = shift;

  my ($expression, $meaning) = @_;

  if ($expression) {
    $self->{'dictionary'}->{$expression} = $meaning;
  }
  else {
    return undef;
  }
}

=head2 get_dictionary

Returns the current dictionary inside the object.

  my %dictionary = %{ $dictionary->get_dictionary };

=cut

sub get_dictionary {
  my $self = shift;

  return $self->{'dictionary'};
}

=head2 reset_dictionary

Resets the current dictionary.

  $dictionary->reset_dictionary;

=cut

sub reset_dictionary {
  my $self = shift;

  for (keys %{$self->{'dictionary'}}) {
    delete $self->{'dictionary'}->{$_};
  }
}

=head1 AUTHOR

Jose Castro, C<< <cog at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-dictionary at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Dictionary>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Dictionary

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Dictionary>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Dictionary>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Dictionary>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Dictionary>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jose Castro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Dictionary

=head1 NAME

Text::Structured - Manipulate fixed-format pages

=head1 SYNOPSIS

  use Text::Structured;
  $st  = new Text::Structured($page);
  $foo = $st->get_text_at($r,$c,$len);
  $foo = $st->get_text_re($r,$re);

=head1 DESCRIPTION

B<Text::Structured> is a class for manipulating fixed-format pages of
text.  A page is treated as a series of rows and columns with the row
and column of the top left hand corner of the page being (0,0).

=head1 SUPERCLASSES

B<Text::StructuredBase>

=cut

package Text::Structured;

use strict;
use base qw/Text::StructuredBase/;
use vars qw($VERSION);

$VERSION = '0.02';

my %fields = (
	      PAGE_L => undef,
	     );

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($page)

Create a new B<Text::Structured> object.  I<$page> is a string
containing a page of text.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields}, $class;
  my @page;
  for ( split /\n/,shift ) { push(@page,[ length, $_ ]) };
  $self->page_l(\@page);
  return $self;
};

##----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

## AUTOLOAD() methods

=head1 OBJECT METHODS

=head2 get_text_at($r,$c,$len)

Returns a substring of length I<$len> starting at row I<$r>, column
I<$c>.  This method will die() if I<$r> E<lt> 0 or I<$r> E<gt> the
number of lines in the page.  See also L<perlfunc/substr()>.

=cut

sub get_text_at($$$) {
  my $self = shift;
  my($r,$c,$len) = @_;
  my @page = @{$self->page_l};
  die "You specified row $r but there are $#page rows in the page"
    if $r > $#page or $r < 0;
  my $row = $page[$r];
  return substr $row->[1],$c,$len;
}

#------------------------------------------------------------------------------

=head2 get_text_re($r,$re)

Returns a string which is the result of applying the regular
expression I<$re> to row I<$r> of the page.  This method will die() if
I<$r> E<lt> 0 or I<$r> E<gt> the number of lines in the page.

=cut

sub get_text_re($$) {
  my $self = shift;
  my($r,$re) = @_;
  my @page = @{$self->page_l};
  die "You specified row $r but there are $#page rows in the page"
    if $r > $#page or $r < 0;
  my $row = $page[$r];
  my @matches = $row->[1] =~ /$re/;
  print STDERR "row = $row->[1], re = $re, matches = @matches\n"
    if $self->{_DEBUG};
  return "@matches";
}

#------------------------------------------------------------------------------

=head2 do_method()

This method can be used with the B<Text::FillIn> module (available
from CPAN) to fill a template using methods from B<Text::Structured>
e.g.

  use Text::FillIn;
  use Text::Structured;

  $page = q{foo bar
baz quux};
  $st = new Text::Structured($page);
  # set delimiters
  Text::FillIn->Ldelim('(:');
  Text::FillIn->Rdelim(':)');
  $template = new Text::FillIn;
  $template->object($st);
  $template->hook('&','do_method');
  $template->set_text(q{Oh (:&get_text_at(0,0,3):), it's a (:&get_text_re(1,(\w+)$):)!});
  $foo = $template->interpret;
  print "$foo\n";

Prints 'Oh foo, it's a quux!'.

=cut

sub do_method {
  my $self = shift;
  print STDERR "args = $_[0]\n" if $self->{_DEBUG};
  my($method,$args) = $_[0] =~ /(\w+)\((.*)\)/ or die ("Bad slot: $_[0]");
  print STDERR "About to \$self->$method($args)\n" if $self->{_DEBUG};
  return $self->$method(split/,/,$args);
}

1;

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

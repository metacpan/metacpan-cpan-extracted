package Test::FitNesse::Slim::MapResult;

use strict;
use warnings;
use Scalar::Util qw(blessed);

my $HTML_CELL = qr{
  \A <
  (p|hr|pre|ul|ol|dl|div|h[1-6]|hgroup|address|blockquote|ins|del|object|map|
   video|audio|figure|table|fieldset|canvas|a|em|strong|small|mark|abbr|dfn|
   i|b|s|u|code|var|samp|kbd|sup|sub|q|cite|span|br|img|embed|label|output|
   datalist|progress|command|time|meter)
  (?: [ >].* </\1> | [^>]* /> )
  \z
}isx;

sub convert {
  my($class,$map) = @_;
  return 'null' unless defined $map;
  die 'Map result must be a hash reference' unless ref($map) eq 'HASH';

  my @keys = sort keys %$map;
  return '<table class="hash_table"/>' unless @keys;

  my @rows = map {
    "\t<tr class=\"hash_row\">\n"
      . "\t\t<td class=\"hash_key\">" . _cell($_) . "</td>\n"
      . "\t\t<td class=\"hash_value\">" . _cell($map->{$_}) . "</td>\n"
      . "\t</tr>"
  } @keys;

  '<table class="hash_table">' . "\n"
    . join("\n", @rows) . "\n"
    . '</table>';
}

sub _cell {
  my($value) = @_;
  my $text = _value_to_string($value);
  $text =~ s/\A[\x00-\x20]+|[\x00-\x20]+\z//g;

  return $text if $text =~ $HTML_CELL || $text =~ /\A\[.*\]\z/s;
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  return $text;
}

sub _value_to_string {
  my($value) = @_;
  return 'null' unless defined $value;
  return "$value" unless ref $value;
  return convert(__PACKAGE__, $value) if ref($value) eq 'HASH';
  return '[' . join(', ', map _value_to_string($_), @$value) . ']'
    if ref($value) eq 'ARRAY';

  if (blessed($value)) {
    return $value->to_string if $value->can('to_string');
    return $value->toString if $value->can('toString');
    die 'Cannot convert object map value without an explicit string method: ' . blessed($value);
  }

  die 'Cannot convert reference map value of type ' . ref($value);
}

1;

=head1 NAME

Test::FitNesse::Slim::MapResult - Convert fixture maps to FitNesse table markup

=head1 DESCRIPTION

FitNesse's Java map converter renders map results as HTML tables. This
module provides the corresponding result conversion for Perl hash
references. Keys are sorted for deterministic output. Scalar cell text is
escaped, while recognized HTML and serialized list markup are preserved.
Nested maps and arrays are formatted recursively. Unsupported reference
types fail instead of being globally stringified.

=head1 METHODS

=head2 convert

    my $html = Test::FitNesse::Slim::MapResult->convert(\%map);

Return FitNesse-compatible table markup. An undefined map becomes the
protocol string C<null>; an empty map becomes an empty table. A non-hash
argument or an unsupported reference value throws an error for the caller
to format as a SLiM exception.

=cut

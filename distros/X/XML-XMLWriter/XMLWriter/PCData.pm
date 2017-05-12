=head1 NAME

XML::XMLWriter::PCData - XML::XMLWriter parsed character data class

=cut

######################################################################

package XML::XMLWriter::PCData;
require 5.8.0;

######################################################################

use strict;

######################################################################

=head2 Methods

=head3 new (@text)

@text must be an array of strings.

Every element of @text is parsed and saved. Parsing sofar only means
that &, < and > are replaced by their XML entities (&amp;, &lt; and
&gt;).

=cut

######################################################################

sub new {
  my($class, @text) = @_;
  my $self = bless({}, ref($class) || $class);
  for(my $i=0; $i<@text; $i++) {
    $text[$i] =~ s/&/&amp;/g;
    $text[$i] =~ s/</&lt;/g;
    $text[$i] =~ s/>/&gt;/g;
  }
  $self->{data} = \@text;
  return $self;
}

######################################################################

=head3 get ()

Returns the strings of parsed character data in an array.

=cut

######################################################################

sub _get {
  my($self) = @_;
  return @{$self->{data}};
}

######################################################################

return 1;

__END__

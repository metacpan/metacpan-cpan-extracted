package WebSource::Format;

use WebSource::Module;

use strict;
use Carp;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Format -  Format XML Nodes

=head1 DESCRIPTION

A format operator allows to prepare its input items for output to the user.

The following formats exist :

=over 2

=item B<string>  : returns the data as a string

=item B<xml>     : returns the data as XML

=item B<select>  : returns a selected (via the B<select> parameter) meta-information item on the data

=item B<details> : returns both meta-information and data in an XML format

=item B<replace> : returns the same data with a given string (B<find> parameter)
                   replaced by an other (B<replace> parameter)

=back

The C<format> attribut of the format declaration allows to determine which
format to use. Depending on the format different parameters are available.
The parameters are declared using the generic parameters/param elements.

A typical replacement formatting is declared as follows :

  <ws:format name="opname" forward-to="ops" format="replace">
    <parameters>
      <param name="find" value="string-to-find" />
      <param name="replace" value="string-to-replace" />
    </parameters>
  </ws:format>

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  my $wsd = $self->{wsdnode};
  if($wsd) {
    $self->{format} = $wsd->getAttribute("format");
  }
  return $self;
}

sub convertToXML {
  my $env = shift;
  my $t = $env->type;
  if($t eq "object/dom-node") {
    return $env->data->toString(1);
  } elsif($t eq "object/http-request") {
    return "<http-request>\n\t" . $env->data->as_string . "\n</http-request>";
  } else {
    return "<result>" . $env->dataString . "</result>";
  }
}

sub convertToDetails {
  my $env = shift;
  my $attrstr;
  foreach my $key (sort(keys(%$env))) {
    if(!($key eq 'data')) {
      my $val = $env->{$key};
      $val =~ s/"/&#34;/g; # "
      $val =~ s/&/&#38;/g;
      $attrstr .= "\n    " . $key . '="' . $val . '"'; 
    }
  }
  return "<result" . $attrstr . ">" . $env->dataString. "</result>";
}

sub handle {
  my $self = shift;
  my $env = shift;
  my $f = $self->{format};
  my $t = $env->type;
  if($f =~ /^xml$/) {
    return WebSource::Envelope->new(type => "text/xml", data => convertToXML($env));
  } elsif($f =~ "replace") {
    my $s = $self->{find};
    my $r = $self->{replace};
    my $data = $env->dataString;
    $data =~ s/$s/$r/;
    return WebSource::Envelope->new(type => "text/string", "data" => $data);
  } elsif($f =~ "details") {
    return WebSource::Envelope->new(type => "text/xml", "data" => convertToDetails($env));
  } elsif($f =~ "select") {
    return WebSource::Envelope->new(
              type => "text/string",
              data => $env->{$self->{select}}
      );
  } else {
    return WebSource::Envelope->new(type => "text/string", "data" => $env->dataString ."\n");
  }
}

=head1 SEE ALSO

WebSource

=cut

1;

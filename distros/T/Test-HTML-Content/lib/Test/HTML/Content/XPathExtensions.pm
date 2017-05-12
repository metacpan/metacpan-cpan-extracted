package Test::HTML::Content::XPathExtensions;

require 5.005_62;
use strict;
use File::Spec;
use HTML::TokeParser;

# we want to stay compatible to 5.5 and use warnings if
# we can
eval 'use warnings;' if ($] >= 5.006);
use vars qw( $HTML_PARSER_StripsTags $VERSION @exports );

$VERSION = '0.09';

@exports = qw( matches comment );

sub matches {
  my $self = shift;
  my ($node, @params) = @_;
  die "starts-with: incorrect number of params\n" unless @params == 2;
  my $re = $params[1]->string_value;
  return($params[0]->string_value =~ /$re/)
    ? XML::XPath::Boolean->True
    : XML::XPath::Boolean->False;
}

sub comment {
  my $self = shift;
  my ($node, @params) = @_;
  die "starts-with: incorrect number of params\n" unless @params == 1;
  my $re = $params[1]->string_value;
  return(ref $node =~ /Comment$/)
    ? XML::XPath::Boolean->True
    : XML::XPath::Boolean->False;
};


sub import {
  for (@exports) {
    no strict 'refs';
    # Install our extensions unless they already exist :
    *{"XML::XPath::Function::$_"} = *{"Test::HTML::Content::XPathExtensions::$_"}
      unless defined *{"XML::XPath::Function::$_"}{CODE};
  };
};

1;

__END__

=head1 NAME

Test::HTML::Content::XPathExtensions - Perlish XPath extensions

=head1 SYNOPSIS

=for example begin

  # This module patches the XML::XPath::Function namespace
  use Test::HTML::Content::XPathExtensions;

=for example end

=head1 DESCRIPTION

This is the module that provides RE support for XML::XPath
and support for matching comments through the two functions
C<matches> and C<comment>.

The two functions are modeled after what I found on the Saxon
website on the C<fn:> namespace :

=over 4

=item *
http://saxon.sourceforge.net/saxon7.3.1/functions.html

=item *
http://www.w3.org/TR/xquery-operators/

=back

=head2 EXPORT

Nothing. It stomps over the XML::XPath::Function namespace.

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

=head1 AUTHOR

Max Maischein, corion@cpan.org

=head1 SEE ALSO

L<XML::XPath>

=cut

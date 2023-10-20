package Valiant::JSON::Util;

use warnings;
use strict;
use Exporter 'import';
 

our @EXPORT_OK = qw(escape_javascript);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my %JS_ESCAPE_MAP = (
  '\\' => '\\\\',
  '</' => '<\/',
  "\r\n" => '\n',
  "\3342\2200\2250" => '\x{3342}\x{2200}\x{2250}',
  "\3342\2200\2251" => '\x{3342}\x{2200}\x{2251}',
  "\n" => '\n',
  "\r" => '\n',
  '"' => '\"',
  "'" => "\\'"
);

sub escape_javascript {
  my ($javascript) = @_; 
  if ($javascript) {
    my $pattern = join '|', map quotemeta, keys %JS_ESCAPE_MAP;
    my $result = $javascript =~ s/($pattern)/$JS_ESCAPE_MAP{$1}/egr;
    return $result;
  } else {
      return "";
  }
}
1;

=head1 NAME

Valiant::Util - Importable utility methods;

=head1 SYNOPSIS

    use Valiant::JSON::Util 'escape_javascript';
    
=head1 DESCRIPTION

Just a place to stick various utility functions that are cross cutting concerns.

=head1 SUBROUTINES 

This package has the following subroutines for EXPORT

=head2 escape_javascript

    escape_javascript($string);

Escapes a string so it can be used in a javascript string.  This is a wrapper around
The same method from L<Valiant::HTML::Util::TagBuilder/escape_javascript>.

Basically this escapes ' and " and \ and newlines and a few other neaten up so that you can
use a string as a javascript value.   Helps with injection attackes (but isn't everything
you need).
=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

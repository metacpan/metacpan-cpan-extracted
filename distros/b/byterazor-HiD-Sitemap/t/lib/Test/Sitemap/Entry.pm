# Minimal stand-in for a HiD page/post object, exposing only the
# interface that byterazor::HiD::Sitemap uses.

package Test::Sitemap::Entry;

use Moose;

use 5.014; # strict, unicode_strings

has url => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);

has input_filename => (
  is  => 'ro' ,
  isa => 'Str' ,
);

# Present on posts (a DateTime); absent on pages.
has date => (
  is  => 'ro' ,
  isa => 'DateTime' ,
);

__PACKAGE__->meta->make_immutable;
1;

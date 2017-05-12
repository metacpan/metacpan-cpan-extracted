=head1 NAME

WWW::Link::Redirect - redirect analysis

=head1 DESCRIPTION

Redirects are used for lots of reasons.  Most of them bad.  When doing
link checking, we want to ignore those redirects which are done for
bad reasons and only focus on those which are really telling us that
something has been reorganised.

The standards tell us that we can look at the difference between a
permanent redirect and a temporary one.  Unfortunately nobody reads
standards.

We use some heuristics to help us make our own assesment.

=head1 FUNCTION

=cut

=head2 implementation redirect

sometimes an artefact of software implementation means that a web page
may be referenced on one page but read on another.  This is a very bad
thing from their point of view, but means that we don't want to change
anything on our pages.

Example

  http://example.com/

  http://example.com/our_web_designers/start-here.active_summit_page

or

  http://example.com/

  http://web4.example.com/first.html.txt.zip.active.exe

our heuristic  is that if the  end of the authority  is maintained and
the  start of the  path is  maintained then  we consider  this mistake
simply a design mistake.

=cut

use URI;
use Carp;

sub implement_redirect {
  my $original=URI->new(shift);
  my $final=URI->new(shift);
  ref $original and ref $final or
    die "usage implement_redirect(orig_uri, final_uri)";
  URI::eq($original, $final) and return 1;
  $final->scheme() eq $original->scheme() or return 0;
  #FIXME non common URIs???

  $origauth=$original->authority();
  $origpath=$original->path();
  $final->authority =~ m/\Q$origauth\E$/ or return 0;
  $final->path =~ m/^\Q$origpath\E/ or return 0;
  #ignore fragment... who cares!
  return 1;
}

package URI::ImpliedBase;
use strict;
use Cwd;
use URI;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.08;
	@ISA         = qw (Exporter URI);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}


=head1 NAME

URI::ImpliedBase - magically force all URIs to be absolute

=head1 SYNOPSIS

  use URI::ImpliedBase;

  # Set the base to search.cpan.org
  $u = URI::ImpliedBase->new("http://search.cpan.org");

  $v = URI::ImpliedBase->new('subdir')
  print $v->as_string;  # prints http://search.cpan.org/subdir

  # No default now
  URI::ImpliedBase->clear();

  # Force current working directory to be the URI
  $w = URI::ImpliedBase->new("../wsdl/test.wsdl");
  print $w->as_string;  # prints (e.g.) file:///Users/joe/wsdl/test.wsdl

=head1 DESCRIPTION

This module is a drop-in replacement for URI. It wraps the new() method with
some extra code which automatically captures either the base of the supplied
URI (if it is absolute), or supplies the current base to C<URI->new_abs()>
(if it is relative). If the current base is unset when a relative URI is
supplied, the current working directory is used to build a "file:" URI and
this is saved as the current base.

You can force a new base at any time by calling C<URI::ImpliedBase->clear()>.

=head1 USAGE

See the X<SYNOPSIS> section for typical usage.

=head1 NOTES

Each time you call URI::ImpliedBase->new(), URI::ImpliedBase checks the scheme
of the supplied URL against @URI::ImpliedBase::accepted_schemes. If the 
scheme of the new URI is in the list of accepted schemes, we update the base.

The initial set of schemes which update the base are 'http' and 'https'. You
may update the list of schemes by altering @URI::ImpliedBase::accepted_schemes.

=head1 BUGS

Whether or not the current directory stuff works for a non-UNIX OS is currently
unknown.

The base is stored internally at the moment; this may be problematic for 
multi-threaded code.

=head1 SUPPORT

Contact the author for support on an informal basis. No guarantee of response
in a timely fashion.

=head1 AUTHOR

	Joe McMahon
	mcmahon@ibiblio.org
	http://ibiblio.org/mcmahon

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), C<perldoc> URI.

=head1 CLASS METHODS

=head2 new

The new method uses C<URI->new()> to convert the incoming string into a 
URI object. It extracts the scheme and path if it can, and saves them as
the new default base. 

If there is no scheme, but there is a path, and there's no existing default
base,C<URI::ImpliedBase> guesses that the path is a reference to the local
filesystem relative to the current working directory. It saves the current
working directory as the base and C<file:> as the scheme, then uses these to
build an absolute C<file:> URI and returns it.

If there's no scheme, and there is a path, and there is a default base, 
C<URI::ImpliedBase> uses the default base to convert the path to an absolute
URI.

The base is stored in a package lexical, C<$current_base>. This may be a 
problem for multithreaded code, or code under C<mod_perl> or C<mod_soap>;
this code has I<not> been tested in these environments.

=cut

our $current_base = "";
our @accepted_schemes = qw(http https);

=head1 METHODS

=head2 new

Accepts a URI and figures out what the proper base is for it.

If the scheme is defined, we can just save the current URI as
the base. If there's a path but no scheme, we have to determine
the proper base: if the base has already been determined by a 
previous call, then we use that. Otherwise we figure out the 
current working directory and use that.

=cut 

sub new {
  my ($class, $uri_string) = @_;
  my $result;

  my $probe_uri = URI->new($uri_string);
  if ($probe_uri->scheme and
      grep {$_ eq $probe_uri->scheme} @accepted_schemes) {
    # New base. Save it.
    $current_base = $probe_uri->as_string;
    $result = $probe_uri;
  }
  elsif ($probe_uri->path) {
    # Path but no scheme. Assume relative.
    if ($current_base) {
      # Use the current base to construct an absoute URI.
      $result = URI->new_abs($uri_string, $current_base);
    }
    else {
      # Relative, but no current base. Use the current working directory.
      $uri_string =~ s{^./}{};
      $result = URI->new("file://" . getcwd() . "/" . $uri_string); 
      $current_base = $result->as_string;
    }
  }
  else {
    # A scheme-only URI? Let URI bounce it.
    $result = $probe_uri;
  }
  $result;
}

=head2 current_base

Returns the currently-derived base URI.

=cut

sub current_base {
  $current_base;
}

=head2 clear

Deletes the current implied base.

=cut

sub clear {
  $current_base = "";
}


1; #this line is important and will help the module return a true value
__END__


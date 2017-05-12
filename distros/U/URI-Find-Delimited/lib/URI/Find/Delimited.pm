package URI::Find::Delimited;

use strict;

use vars qw( $VERSION );
$VERSION = '0.03';

use base qw(URI::Find);

# For 5.005_03 compatibility (copied from URI::Find::Schemeless)
use URI::Find ();
use URI::URL;

=head1 NAME

URI::Find::Delimited - Find URIs which may be wrapped in enclosing delimiters.

=head1 DESCRIPTION

Works like L<URI::Find>, but is prepared for URIs in your text to be
wrapped in a pair of delimiters and optionally have a title. This will
be useful for processing text that already has some minimal markup in
it, like bulletin board posts or wiki text.

=head1 SYNOPSIS

  my $finder = URI::Find::Delimited->new;
  my $text = "This is a [http://the.earth.li/ titled link].";
  $finder->find(\$text);
  print $text;

=head1 METHODS

=over 4

=item B<new>

  my $finder = URI::Find::Delimited->new(
      callback      => \&callback,
      delimiter_re  => [ '\[', '\]' ],
      ignore_quoted => 1               # defaults to 0
  );

All arguments are optional; defaults are provided (see below).

Creates a new URI::Find::Delimited object. This object works similarly
to a L<URI::Find> object, but as well as just looking for URIs it is also
aware of the concept of a wrapped, titled URI.  These look something like

  [http://foo.com/ the foo website]

where:

=over 4

=item * C<[> is the opening delimiter

=item * C<]> is the closing delimiter

=item * C<http://foo.com/> is the URI

=item * C<the foo website> is the title

=item * the URI and title are separated by spaces and/or tabs

=back

The URI::Find::Delimited object will extract each of these parts
separately and pass them to your callback.

=over 4

=item B<callback>

C<callback> is a function which is called on each URI found. It is
passed five arguments: the opening delimiter (if found), the closing
delimiter (if found), the URI, the title (if found), and any
whitespace found between the URI and title.

The return value of the callback will replace the original URI in the
text.

If you do not supply your own callback, the object will create a
default one which will put your URIs in 'a href' tags using the URI
for the target and the title for the link text. If no title is
provided for a URI then the URI itself will be used as the title. If
the delimiters aren't balanced (eg if the opening one is present but
no closing one is found) then the URI is treated as not being wrapped. 

Note: the default callback will not remove the delimiters from the
text. It should be simple enough to write your own callback to remove
them, based on the one in the source, if that's what you want.  In fact
there's an example in this distribution, in C<t/delimited.t>.

=item B<delimiter_re>

The C<delimiter_re> parameter is optional. If you do supply it then it
should be a ref to an array containing two regexes.  It defaults to
using single square brackets as the delimiters.

Don't use capturing groupings C<( )> in your delimiters or things
will break. Use non-capturing C<(?: )> instead.

=item B<ignore_quoted>

If the C<ignore_quoted> parameter is supplied and set to a true value,
then any URIs immediately preceded with a double-quote character will
not be matched, ie your callback will not be executed for them and
they'll be treated just as normal text.

This is a bit of a hack but it's in here because I need to be able to
ignore things like

  <img src="http://foo.com/bar.gif">

A better implementation may happen at some point.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my ( $callback, $delimiter_re, $ignore_quoted ) =
                        @args{ qw( callback delimiter_re ignore_quoted ) };

    unless (defined $callback) {
        $callback = sub {
            my ($open, $close, $uri, $title, $whitespace) = @_;
            if ( $open && $close ) {
                $title ||= $uri;
 	        qq|$open<a href="$uri">$title</a>$close|;
	    } else {
                qq|$open<a href="$uri">$uri</a>$whitespace$title$close|;
            }
        };
    }
    $delimiter_re ||= [ '\[', '\]' ];

    my $self = bless { callback      => $callback,
		       delimiter_re  => $delimiter_re,
		       ignore_quoted => $ignore_quoted
		     }, $class;
    return $self;
}

sub find {
    my($self, $r_text) = @_;

    my $urlsfound = 0;

    URI::URL::strict(1); # Don't assume any old thing followed by : is a scheme

    my $uri_re    = $self->uri_re;
    my $prefix_re = $self->{ignore_quoted} ? '(?<!["a-zA-Z])' : '';
    my $open_re   = $self->{delimiter_re}[0];
    my $close_re  = $self->{delimiter_re}[1];

    # Note we only allow spaces and tabs, not all whitespace, between a URI
    # and its title.  Also we disallow newlines *in* the title.  These are
    # both to avoid the bug where $uri1\n$uri2 leads to $uri2 being considered
    # as part of the title, and thus not wrapped.
    $$r_text =~ s{$prefix_re     # maybe don't match things preceded by a "
		  (?:
		    ($open_re)   # opening delimiter
                    ($uri_re)    # the URI itself
		    ([ \t]*)     # optional whitespace between URI and title
		    ((?<=[ \t])[^\n$close_re]+)? #title if there was whitespace
                    ($close_re)  # closing delimiter
	          |
                      ($uri_re)  # just the URI itself
                  )
                 }{
        my ($open, $uri_match, $whitespace, $title, $close, $just_uri) =
              ($1,         $2,          $3,     $4,     $5,        $6);
        $uri_match = $just_uri if $just_uri;
        foreach ( $open, $whitespace, $title, $close ) {
            $_ ||= "";
	}
        my $orig_text = qq|$open$uri_match$whitespace$title$close|;

        if( my $uri = $self->_is_uri( \$uri_match ) ) { # if not a false alarm
            $urlsfound++;
            $self->{callback}->($open,$close,$uri_match,$title,$whitespace);
	} else {
            $orig_text;
        }
    }egx;

    return $urlsfound;
}

=head1 SEE ALSO

L<URI::Find>.

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Tim Bagot helped me stop faffing over the name, by pointing out that
RFC 2396 Appendix E uses "delimited". Dave Hinton helped me fix the
regex to make it work for delimited URIs with no title. Nick Cleaton
helped me make C<ignore_quoted> work. Some of the code was taken from
L<URI::Find>.

=cut

1;

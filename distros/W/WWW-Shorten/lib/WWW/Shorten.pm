package WWW::Shorten;

use 5.008001;
use strict;
use warnings;

use base qw(WWW::Shorten::generic);
use Carp ();

our $DEFAULT_SERVICE = 'TinyURL';
our @EXPORT          = qw(makeashorterlink makealongerlink);
our $VERSION         = '3.093';
$VERSION = eval $VERSION;

my $style;

sub import {
    my $class = shift;
    $style = shift;
    $style = $DEFAULT_SERVICE unless defined $style;
    my $package = "${class}::${style}";
    eval {
        my $file = $package;
        $file =~ s/::/\//g;
        require "$file.pm";
    };
    Carp::croak($@) if $@;
    $package->import(@_);
}

1;

=head1 NAME

WWW::Shorten - Interface to URL shortening sites.

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use WWW::Shorten 'TinyURL'; # Recommended
  # use WWW::Shorten 'Linkz'; # or one of the others
  # use WWW::Shorten 'Shorl';

  # Individual modules have have their own syntactic variations.
  # See the documentation for the particular module you intend to use for details

  my $url = 'https://metacpan.org/pod/WWW::Shorten';
  my $short_url = makeashorterlink($url);
  my $long_url  = makealongerlink($short_url);

  # - OR -
  # If you don't like the long function names:

  use WWW::Shorten 'TinyURL', ':short';
  my $short_url = short_link($url);
  my $long_url = long_link( $short_url );

=head1 DESCRIPTION

A Perl interface to various services that shorten URLs. These sites maintain
databases of long URLs, each of which has a unique identifier.

# DEPRECATION NOTICE

The following shorten services have been deprecated as the endpoints no longer
exist or function:

=over

=item *

L<WWW::Shorten::LinkToolbot>

=item *

L<WWW::Shorten::Linkz>

=item *

L<WWW::Shorten::MakeAShorterLink>

=item *

L<WWW::Shorten::Metamark>

=item *

L<WWW::Shorten::TinyClick>

=item *

L<WWW::Shorten::Tinylink>

=item *

L<WWW::Shorten::Qurl>

=item *

L<WWW::Shorten::Qwer>

=back

When version C<3.100> is released, these deprecated services will not be part of
the distribution.

=head1 COMMAND LINE PROGRAM

A very simple program called F<shorten> is supplied in the
distribution's F<bin> folder. This program takes a URL and
gives you a shortened version of it.

=head1 BUGS, REQUESTS, COMMENTS

Please submit any L<issues|https://github.com/p5-shorten/www-shorten/issues> you
might have.  We appreciate all help, suggestions, noted problems, and especially patches.

Note that support for extra shortening services should be released as separate modules,
like L<WWW::Shorten::Googl> or L<WWW::Shorten::Bitly>.

Support for this module is supplied primarily via the using the
L<GitHub Issues|https://github.com/p5-shorten/www-shorten/issues> but we also
happily respond to issues submitted to the
L<CPAN RT|http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Shorten> system via the web
or email: C<bug-www-shorten@rt.cpan.org>

* https://github.com/p5-shorten/www-shorten/issues
* http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Shorten
* ( shorter URL: http://xrl.us/rfb )
* C<bug-www-shorten@rt.cpan.org>

=head1 AUTHOR

Iain Truskett C<spoon@cpan.org>

=head1 CONTRIBUTORS

=over

=item *

Alex Page -- for the original LWP hacking on which Dave based his code.

=item *

Ask Bjoern Hansen -- providing L<WWW::Shorten::Metamark>

=item *

Chase Whitener C<capoeirab@cpan.org>

=item *

Dave Cross dave@perlhacks.com -- Authored L<WWW::MakeAShorterLink> on which this was based

=item *

Eric Hammond -- writing L<WWW::Shorten::NotLong>

=item *

Jon and William (wjr) -- smlnk services

=item *

Kazuhiro Osawa C<yappo@cpan.org>

=item *

Kevin Gilbertson (Gilby) -- TinyURL API information

=item *

Martin Thurn -- bug fixes

=item *

Matt Felsen (mattf) -- shorter function names

=item *

Neil Bowers C<neilb@cpan.org>

=item *

PJ Goodwin -- code for L<WWW::Shorten::OneShortLink>

=item *

Shashank Tripathi C<shank@shank.com> -- for providing L<WWW::Shorten::SnipURL>

=item *

Simon Batistoni -- giving the `makealongerlink` idea to Dave.

=item *

Everyone else we might have missed.

=back

In 2004 Dave Cross took over the maintenance of this distribution
following the death of Iain Truskett.

In 2016, Chase Whitener took over the maintenance of this distribution.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 by Iain Truskett.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Shorten>, L<WWW::Shorten::Simple>

=cut

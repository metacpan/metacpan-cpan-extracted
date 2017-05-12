package URI::magnet;
use warnings;
use strict;

use parent qw( URI::_generic URI::QueryParam );

our $VERSION = 0.03;

sub tr {
  my $self = shift;
  my @tr = map { URI->new($_) } $self->query_param('tr');

  return wantarray ? @tr : $tr[0];
}

{
  no strict 'refs'; ## no critic
  foreach my $method ( qw( dn xl kt ) ) {
    *{ __PACKAGE__ . "::$method" } =
      sub {
        return shift->query_param( $method );
      };
  }

  foreach my $method ( qw( xt as xs mt ) ) {
    *{ __PACKAGE__ . "::$method" } =
      sub {
        return URI->new( shift->query_param($method) );
      };
  }
}

*display_name      = \&dn;
*exact_length      = \&xl;
*keyword_topic     = \&kt;
*exact_topic       = \&xt;
*acceptable_source = \&as;
*exact_source      = \&xs;
*manifest_topic    = \&mt;
*address_tracker   = \&tr;


42;
__END__

=head1 NAME

URI::magnet - Magnet URI scheme


=head1 SYNOPSIS

    use URI;

    my $magnet = URI->new( 'magnet:?xt=urn:ed2k:354B15E68FB8F36D7CD88FF94116CDC1&xl=10826029&dn=mediawiki-1.15.1.tar.gz&xt=urn:tree:tiger:7N5OAMRNGMSSEUE3ORHOKWN4WWIQ5X4EBOOTLJY&xt=urn:btih:QHQXPYWMACKDWKP47RRVIV7VOURXFE5Q&tr=http%3A%2F%2Ftracker.example.org%2Fannounce.php%3Fuk%3D1111111111%26&as=http%3A%2F%2Fdownload.wikimedia.org%2Fmediawiki%2F1.15%2Fmediawiki-1.15.1.tar.gz&xs=http%3A%2F%2Fcache.example.org%2FXRX2PEFXOOEJFRVUCX6HMZMKS5TWG4K5&xs=dchub://example.org' );

    say "found " . $magnet->display_name;
    say "size: " . $magnet->exact_length . " bytes";
   
    if ( my $source = $magnet->acceptable_source ) {
      say "has direct link: $source";
    }

    say "the following trackers are available: ";
    say join ', ' => $magnet->address_tracker;


=head1 DESCRIPTION

After this module is installed, the L<URI> package will be able to properly parse Magnet schemes, popular in torrents.


=head1 NEW METHODS

The resulting object will contain the same methods/accessors available by the URI class, and the following new ones:

=head2 dn()

=head2 display_name()

The URL-decoded filename to display to the user, for convenience.

=head2 xl()

=head2 exact_length()

The file size, in bytes.

=head2 xt()

=head2 exact_topic()

  my $topic_urn = $magnet->exact_topic;
  say "hash type:"  . $topic_urn->nid;
  say "hash value:" . $topic_urn->nss;

An URI::urn object containing the file hash. This is the most important part of a Magnet URI, as it is used to find and verify the specified files. You can access the type and value of the hash via the C<nid()> and C<nss()> methods, respectively.


=head2 as()

=head2 acceptable_source()

URI object containing the web link to the file online.

=head2 xs()

=head2 exact_source()

The P2P link.

=head2 kt()

=head2 keyword_topic()

Keywords for search terms, rather than a particular file.

=head2 mt()

=head2 manifest_topic()

URI object pointing to the metafile that contains a list of magneto (MAGMA - MAGnet MAnifest), e.g. a list of further items.

=head2 tr()

=head2 address_tracker()

  # scalar context:
  my $tracker = $magnet->address_tracker;

  # list context:
  foreach my $tracker ($magnet->address_tracker) {
    ...
  }

Object for the tracker URI, used to obtain resources for BitTorrent downloads. As any regular URI object, can be stringified and manipulated.

If this method is called in I<scalar> context, returns the first tr item found on the Magnet URI. In I<list> context, returns an array of items, in the same order they were encountered on the Magnet URI.

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration files or environment variables.


=head1 BUGS AND LIMITATIONS

Group settings (e.g. "xt.1=...&xt.2=...") are not supported. B<Patches welcome!>

Please report any bugs or feature requests to
C<bug-uri-magnet@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 CONTRIBUTING

Project repository is on Github L<http://github.com/garu/URI-magnet>.

=head1 AUTHOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012-2013, Breno G. de Oliveira C<< <garu@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

#
# This file is part of autobox-Junctions
#
# This software is Copyright (c) 2013 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package autobox::Junctions;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.001-6-gcbe3e58
$autobox::Junctions::VERSION = '0.002';

# ABSTRACT: Autoboxified junction-style operators

use strict;
use warnings;

use parent 'autobox';

sub import {
    my $class = shift @_;

    $class->SUPER::import(
        ARRAY => 'autobox::Junctions::ARRAY',
        @_,
    );
}

{
    package autobox::Junctions::ARRAY;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.001-6-gcbe3e58
$autobox::Junctions::ARRAY::VERSION = '0.002';

    use strict;
    use warnings;

    use Syntax::Keyword::Junction ();

    sub all  { Syntax::Keyword::Junction::all( @{ $_[0] }) }
    sub any  { Syntax::Keyword::Junction::any( @{ $_[0] }) }
    sub none { Syntax::Keyword::Junction::none(@{ $_[0] }) }
    sub one  { Syntax::Keyword::Junction::one( @{ $_[0] }) }
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Романов Сергей autoboxified autoboxifying AUTOBOXED

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

autobox::Junctions - Autoboxified junction-style operators

=head1 VERSION

This document describes version 0.002 of autobox::Junctions - released June 22, 2016 as part of autobox-Junctions.

=head1 SYNOPSIS

    # somewhere above...
    use autobox::Junctions;

    # somewhere below...
    my @explodey = qw{ bing bang boom };
    warn "boom!\n"
        if @explody->any eq 'boom';

    my $still_explody = [ @explodey ];
    warn "not all explody\n"
        unless $still_explody->all eq 'boom';

    # now, bonus points...
    use autobox::Core;

    my $weapons = {
        mateu => 'bow & arrow',     # fearsome hunter
        ether => 'disarming smile', # Canadian
        jnap  => 'shotgun',         # upstate NY
    };

    warn 'mateu is armed!'
        if $weapons->keys->any eq 'mateu'

    warn '...but at least no one has a nuke'
        if $weapons->values->none eq 'nuke';

=head1 DESCRIPTION

This is a simple autoboxifying wrapper around L<Syntax::Keyword::Junction>,
that provides array and array references with the functions provided by that
package as methods for arrays:
L<any|Syntax::Keyword::Junction/any>,
L<all|Syntax::Keyword::Junction/all>, L<one|Syntax::Keyword::Junction/one>,
and L<none|Syntax::Keyword::Junction/none>.

=head1 AUTOBOXED METHODS

See: L<Syntax::Keyword::Junction/any>, L<Syntax::Keyword::Junction/all>,
L<Syntax::Keyword::Junction/one>, and L<Syntax::Keyword::Junction/none>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Syntax::Keyword::Junction|Syntax::Keyword::Junction>

=item *

L<autobox|autobox>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/autobox-Junctions/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fautobox-Junctions&title=RsrchBoy's%20CPAN%20autobox-Junctions&tags=%22RsrchBoy's%20autobox-Junctions%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fautobox-Junctions&title=RsrchBoy's%20CPAN%20autobox-Junctions&tags=%22RsrchBoy's%20autobox-Junctions%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 CONTRIBUTOR

=for stopwords Сергей Романов

Сергей Романов <sromanov-dev@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

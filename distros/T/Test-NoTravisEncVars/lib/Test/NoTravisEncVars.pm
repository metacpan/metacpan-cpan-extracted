#
# This file is part of Test-NoTravisEncVars
#
# This software is Copyright (c) 2015 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Test::NoTravisEncVars;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: ca3b36b
$Test::NoTravisEncVars::VERSION = '0.001';

# ABSTRACT: Make sure "secret" Travis variables are not exposed.

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Test::NoTravisEncVars - Make sure "secret" Travis variables are not exposed.

=head1 VERSION

This document describes version 0.001 of Test::NoTravisEncVars - released April 10, 2015 as part of Test-NoTravisEncVars.

=head1 SYNOPSIS

    # ...

=head1 DESCRIPTION

This distribution currently provides no functionality.

...in here.  Its tests, however, do fail if it's run on Travis and the
decryption keys are available in the environment.

That is, we're a sanity check.  If our tests fail, our secrets may be
breached.  This is really only a concern if we're running third-party code;
e.g. installing CPAN packages and having running their tests.  It's possible
that someone may write a test in such a way as to accidentally -- or
deliberately -- make public the secrets guarding the encrypted data you've
stashed in your project.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<http://travis-ci.org|http://travis-ci.org>

=item *

L<https://github.com/RsrchBoy/travis-p5-cache#readme|https://github.com/RsrchBoy/travis-p5-cache#readme>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/test-notravisencvars>
and may be cloned from L<git://https://github.com/RsrchBoy/test-notravisencvars.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/test-notravisencvars/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Ftest-notravisencvars&title=RsrchBoy's%20CPAN%20Test-NoTravisEncVars&tags=%22RsrchBoy's%20Test-NoTravisEncVars%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Ftest-notravisencvars&title=RsrchBoy's%20CPAN%20Test-NoTravisEncVars&tags=%22RsrchBoy's%20Test-NoTravisEncVars%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

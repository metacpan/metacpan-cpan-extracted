#
# This file is part of Test-NoSmartComments
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Test::NoSmartComments;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.004-7-gfc4f436
$Test::NoSmartComments::VERSION = '0.005';

# ABSTRACT: Make sure no Smart::Comments escape into the wild

use strict;
use warnings;

use base 'Test::Builder::Module';

my $CLASS = __PACKAGE__;

use Module::ScanDeps;
use ExtUtils::Manifest qw( maniread );

our @EXPORT = qw{
    no_smart_comments_in
    no_smart_comments_in_all
    no_smart_comments_in_tests
};


sub no_smart_comments_in_all   { _no_smart_comments_in_matching(qr!^lib/.*\.pm$!) }
sub no_smart_comments_in_tests { _no_smart_comments_in_matching(qr!^t/.*\.t$!)  }

sub _no_smart_comments_in_matching {
    my $like = shift @_;

    my $tb = $CLASS->builder;
    my $manifest = maniread();
    my @files = sort grep { $like } keys %$manifest;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    no_smart_comments_in($_) for @files;

    return;
}

sub no_smart_comments_in {
    my $file = shift @_;
    my $tb = $CLASS->builder;

    $tb->diag("No such file: $file") unless -f $file;

    my $dep = scan_deps(files => [ $file ], recurse => 0);
    $tb->ok(!exists $dep->{'Smart/Comments.pm'}, "$file w/o Smart::Comments");
    return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Christopher Douglas Wilson

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Test::NoSmartComments - Make sure no Smart::Comments escape into the wild

=head1 VERSION

This document describes version 0.005 of Test::NoSmartComments - released December 02, 2014 as part of Test-NoSmartComments.

=head1 SYNOPSIS

    use Test::More;
    eval "use Test::NoSmartComments";
    plan skip_all => 'Test::NoSmartComments required for checking comment IQ'
        if $@ ;

    no_smart_comments_in;
    done_testing;

=head1 DESCRIPTION

L<Smart::Comment>s are great.  However, letting smart comments escape into the
wilds of the CPAN is just dumb.

This package provides a simple way to test for smart comments _before_ they
get away!

=head1 FUNCTIONS

=head2 no_smart_comments_in($file)

Called with a file name, this function scans it for the use of
L<the Smart::Comments module|Smart::Comments>.

=head2 no_smart_comments_in_all

no_smart_comments_in_all() scans the MANIFEST for all matching qr!^lib/.*.pm$!
and issues a pass or fail for each.

=head2 no_smart_comments_in_tests

Like no_smart_comments_in_all(), we scan the MANIFEST for all files matching
qr!^lib/.*.t$!  and issues a pass or fail for each.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Smart::Comments>, L<Dist::Zilla::Plugin::NoSmartCommentsTests>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/Test-NoSmartComments>
and may be cloned from L<git://https://github.com/RsrchBoy/Test-NoSmartComments.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/Test-NoSmartComments/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FTest-NoSmartComments&title=RsrchBoy's%20CPAN%20Test-NoSmartComments&tags=%22RsrchBoy's%20Test-NoSmartComments%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FTest-NoSmartComments&title=RsrchBoy's%20CPAN%20Test-NoSmartComments&tags=%22RsrchBoy's%20Test-NoSmartComments%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 CONTRIBUTOR

=for stopwords Douglas Christopher Wilson

Douglas Christopher Wilson <doug@somethingdoug.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

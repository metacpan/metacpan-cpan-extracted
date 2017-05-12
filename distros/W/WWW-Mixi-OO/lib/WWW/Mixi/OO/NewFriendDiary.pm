# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: NewFriendDiary.pm 96 2005-02-04 16:55:48Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/NewFriendDiary.pm $
package WWW::Mixi::OO::NewFriendDiary;
use strict;
use warnings;
use base qw(WWW::Mixi::OO::TableHistoryListPage);

=head1 NAME

WWW::Mixi::OO::NewFriendDiary - WWW::Mixi::OO's
L<http://mixi.jp/new_friend_diary.pl> class

=head1 SYNOPSIS

  my $page = $mixi->page('home');
  # fetch first 50 mixi diaries
  $page->fetch(limit => 50, diary_type => 1);
  # ...

=head1 DESCRIPTION

new_friend_diary page handler

=head1 METHODS

=over 4

=cut

=item parse

see super class (L<WWW::Mixi::OO::Page>).

this module handle following params

=over 4

=item diary_type

    0: ALL
    1: mixi only
    2: external only

=back

=cut

sub parse {
    my ($this, %options) = @_;

    my $diary_type = delete $options{diary_type};
    if ($diary_type) {
	$diary_type -= 1;
	return grep {
	    if ($diary_type) {
		$_->{link} !~ /[\?&]id=/o
	    } else {
		$_->{link} =~ /[\?&]id=/o
	    }
	} $this->SUPER::parse(%options);
    } else {
	return $this->SUPER::parse(%options);
    }
}

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO::ListPage>,
L<WWW::Mixi::OO::Page>,
L<WWW::Mixi::OO::Session>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


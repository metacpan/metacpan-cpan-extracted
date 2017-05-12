# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: NewComment.pm 31 2005-01-29 20:53:40Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/NewComment.pm $
package WWW::Mixi::OO::NewComment;
use strict;
use warnings;
use base qw(WWW::Mixi::OO::TableHistoryListPage);

sub _parse_body_subject {
    shift->_parse_body_subject_with_count(@_);
}

1;

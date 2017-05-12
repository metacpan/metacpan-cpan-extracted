#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

{
  require MIME::Entity;
  my $top = MIME::Entity->build('Path:'        => 'localhost',
                                'Newsgroups:'  => 'r2l.test',
                                'X-Mailer'     => 'foo 1.0',
                                Type           => 'text/html',
                                Encoding       => '-SUGGEST',
                                From           => "no\x{2022}body",
                                Subject        => 'hello',
                                # Date           => ($date || rfc822_time_now()),
                                # 'Message-ID'   => $msgid,
                                # Charset        => $body_charset,
                                Data           => "body text\n",
                                'Content-Language:' => "\x{2022}",
                                #'Date-Received:'    => rfc822_time_now(),
                                #'List-Post:'        => $list_email,
                                'X-Array:'      => ['one','two','three'],
                                #'X-Feed-Link:'      => $channel->{'link'},
                                #'X-RSS-Generator:'  => $generator
                                'X-Copyright:'  => [],# "Foo","Bar"],
                               );
  print $top->as_string;
  exit 0;
}


{
  my $resp = HTTP::Response->new();
  my $content = slurp (</var/www/index.html>);
  $resp->content($content);
  $resp->content_type('text/html');
  print html_title($resp);
  exit 0;
}


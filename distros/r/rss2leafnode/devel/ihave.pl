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

use 5.010;
use strict;
use warnings;
use Net::NNTP;

{
  use IO::Socket::SSL qw(debug3);
  use IO::Socket::INET;
  use Net::NNTP;
  use Hook::LexWrap;
  wrap 'Net::NNTP::new', pre => sub { print "NNTP new\n"; };
  wrap 'IO::Socket::SSL::SSL_Context::new', pre => sub { print "SSL new\n"; };
  wrap 'IO::Socket::INET::new', pre => sub { print "INET new\n"; };

  {
    {
      package MyNNTPS;
      use Net::NNTP;
      use IO::Socket::SSL;
      our @ISA = ('IO::Socket::SSL', 'Net::NNTP');
      no warnings 'once';
      *new = \&Net::NNTP::new;
    }
    my $nntp = MyNNTPS->new ('localhost:12345', Debug => 1);
    print $nntp;
    exit 0;
  }

  {
    local @Net::NNTP::ISA = map {$_ eq 'IO::Socket::INET'
                                   ? 'IO::Socket::SSL' : $_} @Net::NNTP::ISA;
    my $nntp = Net::NNTP->new ('localhost:12345', Debug => 1);
    print $nntp;
    exit 0;
  }
}

{
  require Net::NNTP;
  my $nntp = Net::NNTP->new ('localhost:8119', Debug => 1);
  #print $nntp->ihave('fsjdkfds'),"\n";

  print $nntp->postok(),"\n";
  print $nntp->group('r2l.test'),"\n";
  my $time = time();
  my $msg = <<"HERE";
From: foo
Subject: test $time
Message-ID: <$time.tag:%2C2010-02-09:something\@foo.com>
Newsgroups: r2l.test

Hello
HERE
# Message-ID: <$time\@1080.0.0.0.8.800.200C.417A...ipv6>
# Message-ID: <$time\@1.2.3.4>
  print $nntp->post($msg),"\n";
  exit 0;
}

{
  require URI;
  my $uri;
  $uri = URI->new ('http://foo.com/r2l.test');
  $uri = URI->new ('urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6');
  $uri = URI->new ('news://foo.com/r2l.test');
  $uri = URI->new ('news://localhost:123/r2l.test');
  $uri = URI->new ('news://localhost:119/r2l.test');
  $uri = URI->new ('r2l.test','news');
  $uri = URI->new ('news://foo.com:8119/r2l.test');
  $uri = $uri->abs('news://localhost');
  $uri = $uri->canonical;

  print ref($uri),"\n";
  print $uri,"\n";
  print "scheme:    ",$uri->scheme,"\n";
  print "authority: ",($uri->can('authority') && $uri->authority//'undef'),"\n";
  print "host:      ",($uri->can('host') && $uri->host//'undef'),"\n";
  print "port:      ",($uri->can('port') && $uri->port//'undef'),"\n";
  print "group:     ",($uri->can('group') && $uri->group//'undef'),"\n";
  print "path:      ",$uri->path//'undef',"\n";
  exit 0;
}

{
  require URI;
  # my $uri = URI->new('tag:foo.com,2010-02-09:something');
  my $uri = URI->new('http://foo.com/2010-02-09/something.html');
  print ref($uri),"\n";
  print $uri->can('authority'),"\n";
  print $uri->authority,"\n";
  $uri->authority('');
  print $uri,"\n";
  exit 0;
}


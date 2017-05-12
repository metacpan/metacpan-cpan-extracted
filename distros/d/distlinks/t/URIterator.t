#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More tests => 12;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Distlinks::URIterator;

{
  my $want_version = 11;
  is ($App::Distlinks::URIterator::VERSION, $want_version, 'VERSION variable');
  is (App::Distlinks::URIterator->VERSION,  $want_version, 'VERSION class method');

  ok (eval { App::Distlinks::URIterator->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::Distlinks::URIterator->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

foreach my $elem ([ 'printf("http://foo.com\n");',
                    ['http://foo.com'] ],

                  [ 'http://foo.com http://bar.com',
                    ['http://foo.com','http://bar.com'] ],

                  [ '<http://foo.com> <http://bar.com>',
                    ['http://foo.com','http://bar.com'] ],

                  [ '@uref{http://foo.com,some text}',
                    ['http://foo.com'] ],

                  [ '@uref{http://foo.com/x@comma{}@comma{},some text}',
                    ['http://foo.com/x,,'] ],

                  [ '\\tt http://foo.com/index.html\\#match\\#more',
                    ['http://foo.com/index.html#match#more'] ],

                  [ 'xxx\\"http://foo.com\\"xxx',
                    ['http://foo.com'] ],
                  [ 'http:%s http://%s',
                    [] ],
                 ) {
  my ($content, $want) = @$elem;

  my @got;
  my $it = App::Distlinks::URIterator->new (content => $content);
  while (my $found = $it->next) {
    push @got, $found->uri;
  }

  is_deeply (\@got, $want, "content: $content");
}

exit 0;


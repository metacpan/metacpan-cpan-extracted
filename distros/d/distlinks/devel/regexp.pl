#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
{
  #  use lib::abs '.';

 my $class = 'App::Distlinks::URIFind';
 # my $class = 'URI::Find';

  require Module::Load;
  Module::Load::load($class);

  my $str = <<'HERE';
some file:line: blah
@uref{http://foo.com/, Display text}
@uref{http://foo,Foo}
@indicateurl{http://foo/index.html}
http://bar/index.html#anchor-1
http://three/#
http://four/${foo}
http://five/$(foo)
mailto:foo@bar.com
news:foo.com

cat >&2 <<EOF
$0: unable to guess system type

This script, last modified $timestamp, has failed to recognize
the operating system you are using. It is advised that you
download the most up to date version of the config scripts from

  http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD
and
  http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD

If the version you run ($0) is already up to date, please
send the following data and any information you think might be
pertinent to <config-patches@gnu.org> in order to provide the needed
information to handle your system.

HERE
  my $finder = $class->new (sub {
                                 my ($uri, $orig) = @_;
                                 say $uri;
                                 say $orig;
                                 say pos($str);
                                 return $orig;
                               });
  say $finder->uri_re;
  say $finder->find (\$str);
  exit 0;
}

{
  #   { package Regexp::Common::URI::RFC2396;
  #     $param = "(?:(?:[{}a-zA-Z0-9\\-_.!~*'():\@&=+\$,]+|$escaped)*)";
  #   }
  use Regexp::Common;

  #  my $fragment_re = $Regexp::Common::URI::RFC2396::fragment;
  #  while ($content =~ /\@uref\{([^,}]+)|((#$fragment_re+)?)/og) {

  'http://foo/bar/${quux}' =~ /($RE{URI})/o;
  say $1;
  exit 0;
}

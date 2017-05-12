#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015 Kevin Ryde

# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# RSS2Leafnode is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
use MyMakeMakerGettext;

WriteMakefile
  (NAME         => 'rss2leafnode',
   ABSTRACT     => 'Download RSS feeds or web pages to an NNTP news server.',
   VERSION_FROM => 'lib/App/RSS2Leafnode.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   EXE_FILES    => [ 'rss2leafnode' ],
   MIN_PERL_VERSION => '5.010',

   clean     => { FILES => '$(POT_TEMP_FILE)', # if bad xgettext
                },

   PREREQ_PM    => {
                    # this is required by MIME-Tools anyway
                    'Date::Parse' => 0,

                    'Encode::Locale' => '0.06',

                    # LWP 5.832 for content_charset()
                    'LWP' => '5.832',
                    'LWP::UserAgent' => 0,
                    'HTTP::Message' => 0,
                    'HTTP::Request' => 0,
                    'HTTP::Response' => 0,

                    # MIME-Tools
                    'MIME::Entity' => 0,
                    'MIME::Tools' => 0,
                    'MIME::Words' => 0,

                    # 1.17 for __p()
                    'Locale::TextDomain' => '1.17',
                    'Locale::Messages' => 0, # part of libintl

                    # 1.5 for format_bytes() options
                    'Number::Format' => '1.5',

                    # version 1.02 for undef support
                    'Text::Trim' => '1.02',

                    # maybe URI 1.13 circa 2001 for dotted ipv6 support, if
                    # using that
                    'URI' => 0,
                    'URI::Escape' => 0,
                    'URI::tag' => 0, # for hostname of atom <id>

                    # version 3.34 for att_exists()
                    'XML::Twig' => '3.34',

                    'constant::defer' => 0,
                    'HTML::Entities::Interpolate' => 0,
                    'HTML::FormatText' => 0,
                    'HTML::Formatter' => 0,
                    'HTML::Parser' => 0,
                    'Text::WrapI18N' => 0,
                    'Scope::Guard' => 0,
                    'Sort::Key::Top' => 0,
                    'File::HomeDir' => 0,
                    'List::MoreUtils' => '0.24', # 0.24 for stack growing, maybe
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/rss2leafnode/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     recommends => {
                    # version 6.03 recognises "bzip2" as well as "x-bzip2"
                    'HTTP::Message' => '6.03',
                   },
     no_index => { directory=>['devel','po','xt'] },

     prereqs =>
     { test =>
       { suggests =>
         { 'Test::Weaken' => '2.0',
           'Test::Weaken::ExtraBits' => 1,
           'URI::Title' => 0,
         },
       },
     },

     optional_features =>
     { maximum_interoperation =>
       { description => 'All the optional and possible things RSS2Leafnode can use.',
         requires => { 'XML::Liberal' => 0,
                       'XML::RSS::Timing'       => 0 ,
                       'Time::Duration'         => 0,
                       'Time::Duration::Locale' => 0,
                       'Time::Duration::ja'     => 0,
                       'Time::Duration::sv'     => 0,
                       'HTML::ExtractMain'      => 0,
                       'HTML::FormatExternal'        => 16,
                       'HTML::FormatText::WithLinks' => 0,
                       'URI::Title'      => 0,
                       'Image::ExifTool' => '8.22',
                     },
       },
       maximum_repair =>
       { description => 'Modules for as much XML fixing-up as possible.',
         requires => { 'XML::Liberal' => 0 },
       },

       xml_rss_timing =>
       { description => 'Check RSS feed advertised update times before redownloading.',
         requires => { 'XML::RSS::Timing' => 0 },
       },
       xml_rss_timing_print =>
       { description => 'A prettier print of time to next RSS update.',
         requires => { 'Time::Duration' => 0 },
       },
       xml_rss_timing_print_locale =>
       { description => 'A prettier print of time to next RSS update, with language-specifics.',
         # bit unfortunate to hard-code the known
         # language-specifics here, it the idea takes off perhaps
         # there'll be a "Bundle::" to depend on
         requires => { 'Time::Duration::Locale' => 0,
                       'Time::Duration::ja'     => 0,
                       'Time::Duration::sv'     => 0,
                       # included for comic effect :-)
                       'Time::Duration::en_PIGLATIN' => 0,
                     },
       },

       render_text_with_links =>
       { description => 'Optionally render HTML to text using FormatText::WithLinks.',
         requires => { 'HTML::FormatText::WithLinks' => 0 },
       },
       render_text_external =>
       { description => 'Optionally render HTML to text using external programs like lynx.',
         # version 16 preferred for "base" parameter, but earlier
         # works fine
         requires => { 'HTML::FormatExternal' => 16 },
       },

       fetch_html_uri_title =>
       { description => ' A better Subject for fetch_html() messages using URI::Title.',
         requires => { 'URI::Title' => 0 },
       },
       fetch_html_exiftool =>
       { description => ' A better Subject for fetch_html() messages using Image::ExifTool.',
         # version 8.11 avoids warnings from an incompatible change
         # in perl 5.11.5, though probably any version works
         # version 8.22 is preferred as it gives back PNG tEXt/iTXt
         # in a consistent encoding
         requires => { 'Image::ExifTool' => '8.22' },
       },
     },
   },
  );

# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { 'XML::Atom' => 0,
#                 'XML::Atom::Feed' => 0,
#                 'XML::RSS' => 0,
#                 'XML::RSS::LibXML' => 0,
#                 'XML::LibXML' => 0,
#                 'XML::Liberal' => 0,
#                 'File::Slurp' => 0,
#                 'URI::file' => 0, # part of URI
#                 'URI::Title' => 0,
#                 'HTML::TreeBuilder' => 0,
#                 'HTML::FormatText' => 0,
#                 'HTML::Entities' => 0,
#                 'HTML::Lint' => 0,
#                 'DateTime' => 0,
#                 'DateTime::Format::Mail' => 0,
#                 'IO::Socket::SSL' => 0,
#                 'Hook::LexWrap' => 0,
#                 'Module::Find' => 0,
#                 'File::Slurp' => 0,
#                 'Gtk2' => 0,
#                 'HTML::FormatText::WithLinks' => 0,
#                 'Image::ExifTool' => 0,
#                 # maybe 1.881 for regexp fixes
#                 'Email::Address' => '1.881',
#               },


#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;
  $makemaker->{'PO_DOMAIN'} = 'App-RSS2Leafnode';
  return MyMakeMakerGettext::postamble($makemaker);
}

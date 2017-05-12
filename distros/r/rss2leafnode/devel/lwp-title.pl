#!/usr/bin/perl -w

# Copyright 2010, 2016 Kevin Ryde
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
use LWP::UserAgent;
use Cwd;
use FindBin;

# use lib "$ENV{HOME}/perl/image/Image-ExifTool-8.22/lib";

use Smart::Comments;
{
  @ARGV=('/usr/share/doc/texlive-doc/plain/impatient/book.pdf');
  require Image::ExifTool;
  Image::ExifTool->import(':Public');
  print values(%{ImageInfo($ARGV[0],['PageCount'])});
  exit 0;
}
{
  my $filename;
  $filename = '/usr/share/doc/sqlite3-doc/images/arch.png';
  $filename = "../../tux/web/gtk2-ex-clock/screenshot.png";
  $filename = "$ENV{HOME}/p/pngtext/devel/spacetag.png";
  $filename = "/usr/share/games/funnyboat/data/titanic.png";
  $filename = "$ENV{HOME}/image/samples/utf8.png";
  $filename = "$ENV{HOME}/image/samples/latin1-keyword.png";
  $filename = 'devel/lwp-title.html';
  $filename = 'samp/IDX0104.gif';
  $filename = '/usr/share/doc/texlive-doc/plain/impatient/book.pdf';

  -e $filename or die;
  require Image::ExifTool;
  print Image::ExifTool->VERSION,"\n";
  my $info = Image::ExifTool::ImageInfo
    ($filename,
#      ['Title','ImageWidth','ImageHeight'],
#      {List => 0,    # give list values as comma separated
#       Charset => 'UTF8'},
    );

  #   $e->ExtractInfo($filename,
  #                   ['Foo'],
  #                   List => 0,    # give list values as comma separated
  #                   Charset => 'UTF8',
  #                   Unknown => 1);
  #   my $info = $e->GetInfo('Title');

  require Data::Dumper;
  print Data::Dumper->new([\$info],['info'])->Dump;

  # my $fo = $info->{'FO'};
  my $fo = $info->{'Foo'};
  # my $fo = $info->{'Description'};
  print "$fo\n";
  print utf8::is_utf8($fo)?"yes":"no","\n";
  exit 0;
}
{
  require App::RSS2Leafnode;
  my $filename = "$ENV{HOME}/image/samples/latin1.png";
  $filename = "$ENV{HOME}/image/samples/utf8.png";
  my $ua = LWP::UserAgent->new;
  my $url = "file://$filename";
  my $resp = $ua->get($url);
  my $title = App::RSS2Leafnode::html_title($resp);
  print utf8::is_utf8($title)?"yes":"no","\n";
  print "$title\n";
  exit 0;
}
{
  require Gtk2;
  Gtk2->init;
  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
  my $label = Gtk2::Label->new ("\x{B1}");
  $toplevel->add ($label);
  $toplevel->show_all;
  Gtk2->main;
  exit 0;
}
{
  require Gtk2;
  Gtk2->init;
  my $output_filename = '/tmp/x';
  my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', 0, 8, 10, 10);
  eval {
    $pixbuf->save
      ($output_filename, 'png',
       # 'tEXt::Title' => "\x{2022}",
       'tEXt::Title' => "\x{B1}",
      );
  };
  print "$@";
  print "output $output_filename\n";
  exit 0;
}

{
  require URI::file;
  require URI::Title;
  my $url = "file://@{[Cwd::cwd()]}/../../tux/web/gtk2-ex-clock/screenshot.png";
  print "$url\n";

  my $ua = LWP::UserAgent->new;
  my $resp = $ua->get($url);
  print $resp->content_type,"\n";

  my $title = URI::Title::title($url);
  print $title,"\n";
  exit 0;
}

{
  require URI;
  my $uri = URI->new('data:,Foo');
  print $uri->data,"\n";
  print $uri->host;
  exit 0;
}

{
  my $ua = LWP::UserAgent->new;
  # my $url = 'http://localhost/index.html';
  my $url = "file://$FindBin::Bin/lwp-title.html";
  my $resp = $ua->get($url);
  my $title = $resp->title;
  print $title,"\n";
  # print $resp->as_string,"\n";

  require URI::Title;
  my $data = $resp->decoded_content(charset=>'none');
  $title = URI::Title::title({ data => \$data });
  print $title,"\n";
}

exit 0;


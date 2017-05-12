# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

package App::Distlinks::URInFiles;
use 5.010;
use strict;
use warnings;
use URI::file;
use List::Util qw(min max);
use File::Spec;
use Perl6::Slurp;
use Locale::TextDomain ('App-Distlinks');

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 11;

# my %exclude_dirs = (# 'b'    => 1,
#                     'blib' => 1,
#                     'CVS'  => 1,
#                     '.svn' => 1,
#                    );

# emacs backup foo~
# emacs lock .#foo or autosave #foo#
my $exclude_files_re = qr/~$|^\.?#/;

my $exclude_dirs_re = qr/^(blib|CVS|\.svn)$/;


#------------------------------------------------------------------------------
# generic

sub join_backslashed_newlines {
  my ($str) = @_;
  while ((my $eol = index ($str, "\\\n")) > 0) {
    my $bol = max (rindex ($str, "\n", $eol), 0);
    substr ($str, $eol,2, '');   # delete \ and newline
    substr ($str, $bol,0, "\n"); # insert newline
  }
  return $str;
}


#------------------------------------------------------------------------------
sub new {
  my ($class, @inputs) = @_;
  return bless { finders => [ $class->_make_finder(@inputs) ],
                 verbose => 0,
               }, $class;
}

sub _make_finder {
  my ($class, @inputs) = @_;
  require File::Find::Iterator;
  File::Find::Iterator->create (dir => \@inputs,
                                filter => \&_is_not_excluded);
}
sub _is_not_excluded {
  return (! -d
          && ! m{~$
               |(^|/)
                 (\.?\#
                 |(blib|CVS|\.svn)($|/)
                 )
              }x);
}

sub next {
  my ($self) = @_;
  ### URInFiles next() ...

  for (;;) {
    if (my $urit = $self->{'urit'}) {
      if (defined (my $ufound = $urit->next)) {
        return $ufound;
      }
    }
    my $finder = $self->{'finders'}->[0];
    my $filename = $finder->next // do {
      shift @{$self->{'finders'}};
      if (@{$self->{'finders'}}) {
        next;
      } else {
        return;
      }
    };
    ### URInFiles filename: $filename

    my $content = $self->file_text ($filename)
      // do {
        ### no content for: $filename
        next;
      };

    require App::Distlinks::URIterator;
    $self->{'urit'} = App::Distlinks::URIterator->new
      (filename => $filename,
       content  => $content,
       base     => URI::file->new_abs($filename));
  }
}

use constant::defer _FILETYPER => sub {
  require File::Type;
  return File::Type->new;
};

my %bom_coding = ("\x{EF}\x{BB}\x{BF}"       => 'UTF-8',
                  "\x{FF}\x{FE}"             => 'UTF-16le',
                  "\x{FE}\x{FF}"             => 'UTF-16be',
                  "\x{FF}\x{FE}\x{00}\x{00}" => 'UTF-32le',
                  "\x{00}\x{00}\x{FE}\x{FF}" => 'UTF-32be');
my %executable_types = ('application/x-executable-file'   => 1,
                        'application/x-ms-dos-executable' => 1);
my %archive_types = ('application/x-gtar' => 'untar',
                     'application/x-tar'  => 'untar',
                     'application/zip'    => 'unzip');
my %compress_types =
  ('application/x-gzip'  => [ 'IO::Uncompress::Gunzip',
                              'IO::Uncompress::Gunzip::gunzip' ],
   'application/x-bzip2' => [ 'IO::Uncompress::Bunzip2',
                              'IO::Uncompress::Bunzip2::bunzip2' ]);

my $exif;
my %exif_exclude = (HTML => 1,
                    ZIP  => 1);

sub file_text {
  my ($self, $filename) = @_;
  ### URInFiles file_text(): $filename

  my $content = eval { Perl6::Slurp::slurp($filename) }
    // do {
      print $@;
      return undef;
    };
  ### $content

  for (;;) {
    foreach my $bom (keys %bom_coding) {
      if ($content =~ /^\Q$bom/) {
        require Encode;
        return Encode::decode ($bom_coding{$bom}, $content);
      }
    }

    if ($content =~ /^(\x{DE}\x{12}\x{04}\x{95}|\x{95}\x{04}\x{12}\x{DE})/) {
      $content = $self->msgunfmt($filename, $content);
    }

    my $type = _FILETYPER()->checktype_contents($content);
    if ($self->{'verbose'} >= 2) {
      print __x("filetype {type}\n", type => $type);
    }
    if ($executable_types{$type}) {
      return $content;
    }

    if (my $method = $archive_types{$type}) {
      my $tempdir = $self->$method($filename, $content) // return;
      ### URInFiles also tempdir: $tempdir
      unshift @{$self->{'finders'}}, $self->_make_finder($tempdir);
      return;
    }

    if (my $info = $compress_types{$type}) {
      my ($class, $func) = @$info;
      ### URInFiles class: $class
      require Module::Load;
      Module::Load::load ($class);
      my $input = $content;
      no strict 'refs';
      my $status = &$func (\$input, \$content);
      next;
    }

    $exif ||= do {
      require Image::ExifTool;
      my $e = Image::ExifTool->new;
      $e->Options (List => 0,    # give list values as comma separated
                   Binary => 1,
                   Unknown => 1);
      $e };
    if ($exif->ExtractInfo (\$content)) {
      my $info = $exif->GetInfo;
      if ($self->{'verbose'} >= 2) {
        require Data::Dumper;
        print "  ExifTool info: ",
          Data::Dumper->new([$info],['info'])->Sortkeys(1)->Dump;
      }
      if ($exif_exclude{$info->{'FileType'}}) {
        last;
      }
      $content = '';
      while (my ($key, $value) = each %$info) {
        $content .= "$key -- $value\n";
      }
      if ($self->{'verbose'} >= 2) { print __("image text:\n"),$content; }
      return $content;
    }

    last;
  }
  ### URInFiles file_text() content: $content
  return $content;
}

# $filename is a .tar or .tar.gz file
# untar it into a temporary directory and return the name of that directory
#
sub untar {
  my ($self, $filename, $content) = @_;
  require File::Temp;
  my $tempdir = File::Temp->newdir ('distlinks-XXXXXX',
                                    TMPDIR => 1,
                                    CLEANUP => 0);
  if ($self->{'verbose'}) { print __x("untar to dir: {dir}\n",
                                      dir => $tempdir); }

  require Archive::Tar;
  require IO::String;
  my $io = IO::String->new ($content);
  my $tar = Archive::Tar->new;
  $tar->read ($io);
  { require File::chdir;
    local $File::chdir::CWD = $tempdir;
    $tar->extract;
  }
  $self->chmod_tree_readonly ($tempdir);
  return $tempdir;
}

sub unzip {
  my ($self, $filename, $content) = @_;
  require File::Temp;
  my $tempdir = File::Temp->newdir ('distlinks-XXXXXX',
                                    TMPDIR => 1,
                                    CLEANUP => 0);
  if ($self->{'verbose'}) { print __x("unzip to dir: {dir}\n",
                                      dir => $tempdir); }

  require Archive::Zip;
  require IO::String;
  my $zip = Archive::Zip->new;
  my $io = IO::String->new ($content);
  if ((my $ret = $zip->readFromFileHandle ($io))
      != Archive::Zip::AZ_OK()) {
    print __x("Cannot parse {filename}: {error}\n",
              filename => $filename,
              error    => $ret);
    return;
  }
  ### URInFiles zip members: $zip->memberNames

  if ((my $ret = $zip->extractTree (undef, "$tempdir/"))
      != Archive::Zip::AZ_OK()) {
    print __x("Cannot extract {filename}: {error}\n",
              filename => $filename,
              error    => $ret);
    return;
  }
  $self->chmod_tree_readonly ($tempdir);
  return $tempdir;
}

sub chmod_tree_readonly {
  my ($self, $tempdir) = @_;
  require File::Find::Iterator;
  my $find = File::Find::Iterator->create (dir => [$tempdir]);
  while (my $filename = $find->next) {
    my $mode = (stat $filename)[2] & ~0222; # no write perm
    if (chmod($mode, $filename) != 1) {
      print __x("Oops, cannot set readonly on {filename}: {error}\n",
                filename => $filename,
                error    => $!);
    }
  }
}


sub msgunfmt {
  my ($self, $filename, $content) = @_;
  if ($self->{'verbose'} >= 2) {
    print __x("msgunfmt {filename}\n", filename => $filename);
  }
  require File::Temp;
  my $fh = File::Temp->new (TEMPLATE => 'distlinks-XXXXXX',
                            SUFFIX   => '.mo',
                            TMPDIR   => 1);
  $fh->unlink_on_destroy(0);

  print $fh $content;
  close $fh;
  my $tempfile = $fh->filename;

  ### URInFiles msgunfmt: $tempfile
  $content = qx{msgunfmt $tempfile};

  if (my $charset = po_charset ($content)) {
    ### URInFiles charset: $charset
    require Encode;
    $content = Encode::decode ($charset, $content);
  }
  return $content;
}

sub po_charset {
  my ($content) = @_;
  return ($content =~ m{Content-Type: text/plain; charset=([^\\\n\"]+)}
          && $1);
}

1;
__END__

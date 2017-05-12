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

package App::Distlinks::URIterator;
use strict;
use warnings;

# uncomment this to run the ### lines
#use Devel::Comments;

our $VERSION = 11;

# filename => 
# content  =>
sub new {
  my ($class, %options) = @_;
  ### URIterator: %options
  return bless \%options, $class;
}
sub filename {
  my ($self) = @_;
  return $self->{'filename'};
}

my %open_paren = ('}' => '{',
                  ')' => '(',
                  ']' => '[',
                  '>' => '<');
my $scheme         = qr{(https?|s?ftp|news):/+[[:alnum:]]};
my %barehost_table = (www => 'http://',
                      ftp => 'ftp://',
                      rsync => 'rsync://');
my $barehost_re    = join('|', keys %barehost_table);
my $scheme_or_host = qr/\b($scheme|(?<barehost>$barehost_re)\d*\.)/o;
my $urlchar_not    = '\\\\<>"\'! [:cntrl:]';
my $urlchar_last   = qr/\\?[^]),.$urlchar_not]/;
my $urlchar        =     qr/\\?[^$urlchar_not]/;

# paired {} allowed like @uref{hello@comma{}world}
my $texinfo = qr<(?<texinfo>\@ur(ef|l)\{(?<url>([^\r\n,{}]|\{\})+)(,.*)?\})>o;
my $quoted  = qr<`(?<url>$scheme_or_host[^' \t\r\n]*)'>o;
my $angles  = qr/<(?<url>$scheme_or_host[^> \t\r\n]*)>/o;
my $uangle  = qr/<UR[IL]:(?<url>[[:alnum:]][^> \t\r\n]*)>/o;
my $bare    = qr{(?<url>$scheme$urlchar*$urlchar_last)}o;
my $href    = qr{(?<href>href=(\'(?<url>[^\'\n]*?)\'|\"(?<url>[^\"\n]*?)\"))};


sub next {
  my ($self) = @_;
  for (;;) {
    ### URIterator pos: pos($self->{'content'})
    ($self->{'content'} =~ m{$texinfo
                           |$quoted
                           |$angles
                           |$uangle
                           |$bare
                           |$href
                          }ogx)
      or return;
    my $url = $+{'url'};
    my $pos = $-[0];
    my $base;
    ### match: substr($self->{'content'},$-[0],$+[0]-$-[0])

    if ($+{'texinfo'}) {
      $url =~ s/\@comma\{\}/,/g;  # my @comma macro
    } elsif ($+{'href'}) {
      $base = $self->{'base'};
    } else {
      # C backslashes
      $url =~ s/\\t/\t/g;
      $url =~ s/\\r/\r/g;
      $url =~ s/\\n/\n/g;
      # others literal, in particular \# in emacs ru-refcard.tex
      $url =~ s/\\(.)/$1/g;
    }

    # unclosed trailing paren
    while ($url =~ /([])}>])$/) {
      if (index($url,$open_paren{$1}) < 0) {
        substr ($url, -1,1, '');
      } else {
        last;
      }
    }

    # disallow things with variable substitutions "$FOO", "$(FOO)" etc
    # $url =~ /\$$|\$[({]/
    if ($url =~ /\$/) {
      ### skip dollar subst: $url
      next;
    }

    my $url_raw = $url;
    if (my $barehost = $+{'barehost'}) {
      $url = $barehost_table{$barehost} . $url;
    }

    require URI;
    my $uri;
    ### $base
    if (defined $base) {
      $uri = URI->new_abs ($url, $base);
    } else {
      $uri = URI->new ($url);
    }
    if (! $uri->scheme) {
      $url = "http://$url";
      $uri = URI->new($url);
    }

    if (($uri->scheme eq 'http' || $uri->scheme eq 'ftp')
        && ! defined $uri->host) {
      ### skip no host part: $url
      next;
    }

    return App::Distlinks::URIfound->new
      (iterator => $self,
       pos      => $pos,
       uri      => $uri,
       url_raw  => $url_raw);
  }
}


package App::Distlinks::URIfound;

sub new {
  my ($class, @args) = @_;
  return bless { @args }, $class;
}
sub iterator {
  my ($self) = @_;
  return $self->{'iterator'};
}
sub filename {
  my ($self) = @_;
  return $self->{'iterator'}->filename;
}
sub uri {
  my ($self) = @_;
  return $self->{'uri'};
}
sub url_raw {
  my ($self) = @_;
  return $self->{'url_raw'};
}
sub pos {
  my ($self) = @_;
  return $self->{'pos'};
}
sub line_and_column {
  my ($self) = @_;
  return @{$self->{'line_and_column'}
             ||= [ _pos_to_line_and_column ($self->iterator->{'content'},
                                            $self->pos) ]};
}

sub _pos_to_line_and_column {
  my ($str, $pos) = @_;
  require Text::Tabs;
  $str = substr ($str, 0, $pos);
  my $nlpos = rindex ($str, "\n");
  my $lastline = substr ($str, $nlpos+1);
  $lastline = Text::Tabs::expand ($lastline);
  my $colnum = 1 + length ($lastline);
  my $linenum = 1 + scalar($str =~ tr/\n//);
  return ($linenum, $colnum);
}


#     # $url =~ s/\)[,.]?$//;         # close paren
#     #    $url =~ s/(\.[a-z]+)\.$/$1/;  # full stop after suffix


1;
__END__

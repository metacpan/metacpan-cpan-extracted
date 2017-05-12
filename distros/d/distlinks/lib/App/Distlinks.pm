# Copyright 2009, 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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


package App::Distlinks;
use 5.010;
use strict;
use warnings;
use File::Spec;
use List::MoreUtils;
use Locale::TextDomain ('App-Distlinks');

use App::Distlinks;

# uncomment this to run the ### lines
#use Smart::Comments;


our $VERSION = 11;

my %exclude_hosts
  = (
     'foo.com' => 1,
     'foo.org' => 1,
    );
sub exclude_host {
  my ($host) = @_;
  return (defined $host
          && (List::MoreUtils::any {is_host_in_domain($host,$_)}
              keys %exclude_hosts));
}
sub is_host_in_domain {
  my ($host, $domain) = @_;
  return scalar ($host =~ /(^|\.)\Q$domain\E$/);
}

my %exclude_urls
  = (
     #      'ftp://alpha.gnu.org/gnu/emacs/pretest/emacs-$NEW.tar.gz' => 1,
     #      'ftp://alpha.gnu.org/gnu/emacs/pretest/emacs-$OLD-$NEW.xdelta' => 1,
    );
my %nodb_urls
  = (
     'http://localhost' => 1,
    );


#------------------------------------------------------------------------------
sub dbh {
  my ($self) = @_;
  return $self->{'dbh'} ||= do {
    require App::Distlinks::DBI;
    return App::Distlinks::DBI->instance;
  };
}

#------------------------------------------------------------------------------

sub check_dir_or_file {
  my ($self, $dir_or_filename) = @_;
  ### Distlinks check_dir_or_file(): $dir_or_filename

  require App::Distlinks::URInFiles;
  my $it = App::Distlinks::URInFiles->new ($dir_or_filename);
  $it->{'verbose'} = $self->{'verbose'};
  while (defined (my $found = $it->next)) {
    my $uri = $found->uri;
    ### $uri
    ### scheme: $uri->scheme

    # secret undocumented feature ...
    if ($self->{'only_local'}) {
      unless ($uri->scheme eq 'file') {
        if ($self->{'verbose'}) { print __x("not local {url}\n",
                                            url => $uri); }
        next;
      }
    }

    if ($exclude_urls{$uri}
        || ($uri->can('host') && exclude_host($uri->host))) {
      if ($self->{'verbose'}) { print __x("skip {url}\n", url => $uri); }
      return;
    }
    if ($self->{'verbose'}) {
      print __x("file {filename} match {url}\n",
                filename => $found->filename,
                url => $found->url_raw);
      if ($found->url_raw ne $uri) {
        print __x("  is {url}\n", url => $uri);
      }
    }

    my ($line, $col) = $found->line_and_column;
    my $filename = $found->filename;
    $self->check_uri ($uri, $found->url_raw, "$filename:$line:$col");
  }

  ### Distlinks check_dir_or_file() finished ...
}



#------------------------------------------------------------------------------

my %printed;
my $count_ok = 0;
my $count_bad = 0;

sub mech {
  my ($self) = @_;
  return $self->{'mech'} ||= do {
    require Net::Config;
    if (! @{$Net::Config::NetConfig{'nntp_hosts'}}) {
      $Net::Config::NetConfig{'nntp_hosts'} = [ 'localhost' ];
    }

    require WWW::Mechanize;
    my $mech = WWW::Mechanize->new (autocheck => 0,
                                    agent => $self->progname . "/$VERSION");
    $mech->requests_redirectable([]); # no redirects

    if ($self->{'verbose'} >= 2) {
      require LWP::Debug;
      LWP::Debug::level('+trace');
      LWP::Debug::level('+debug');
    }

    my $decodable = HTTP::Message::decodable();
    $mech->default_header ('Accept-Encoding' => $decodable);
    if ($self->{'verbose'}) {
      print __x("HTTP decodable: {str}\n",
                str => $decodable);
    }
    if ($self->{'verbose'}) {
      print __x("User-Agent: {agent}\n", agent => $mech->agent);
    }
    $mech
  };
}

sub check_uri {
  my ($self, $uri, $url_raw, $where) = @_;

  my $anchor = $uri->fragment;
  if (defined $anchor) {
    require URI::Escape;
    $anchor = URI::Escape::uri_unescape ($anchor);
  }

  $uri = uri_sans_fragment ($uri);

  my $dbh = $self->dbh;
  my $info = $dbh->read_page ($uri, $anchor);

  if (! defined $info->{'status_code'}
      || ($self->{'retry_500'} && $info->{'status_code'} == 500)
      || (defined $anchor && ! $info->{'anchors'})) {

    my $mech = $self->mech;
    # $uri->scheme eq 'http' &&
    if (! defined $anchor) {
      if ($self->{'verbose'} >= 2) { print "HEAD $uri\n"; }
      $mech->head ($uri);
    } else {
      if ($self->{'verbose'} >= 2) { print "GET $uri\n"; }
      $mech->get ($uri);
    }

    my $resp = $mech->response;
    if ($self->{'verbose'} >= 2) {
      print $resp->headers->as_string;
      print "received content length: ", length($mech->content), "\n";
      print "code ", $resp->code, "\n";
      print "line ``", $resp->status_line, "''\n";
    }

    if ($resp->code == 304) {
      if ($self->{'verbose'}) {
        print __x("  not modified\n");
      }
    } else {
      if ($resp->code == 200) {
        if (defined (my $redir_uri = response_meta_refresh($resp))) {
          $uri = $redir_uri;
          if (! defined $anchor) {
            if ($self->{'verbose'} >= 2) { print "meta-refresh HEAD $uri\n"; }
            $mech->head ($uri);
          } else {
            if ($self->{'verbose'} >= 2) { print "meta-refresh GET $uri\n"; }
            $mech->get ($uri);
          }
          $resp = $mech->response;
          if ($self->{'verbose'} >= 2) {
            print $resp->headers->as_string;
            print "received content length: ", length($mech->content), "\n";
            print "code ", $resp->code, "\n";
            print "line ``", $resp->status_line, "''\n";
          }
        }
      }

      $info = { url            => $uri,
                is_success     => ($resp->is_success ? 1 : 0),
                status_code    => $resp->code,
                status_line    => $resp->status_line,
                etag           => scalar $resp->header('ETag'),
                last_modified  => scalar $resp->header('Last-Modified'),
                redir_location => scalar $resp->header('Location')
              };
      if ($resp->request->method eq 'GET'
          && $resp->is_success) {
        $info->{'anchors'} = [ html_anchors($mech->content) ];
      }

      if ($info->{'status_code'} == 500
          && $info->{'status_line'} =~ /File successfully transferred/) {
        if ($self->{'verbose'} >= 2) { print __("hack ftp 500 successful to 200\n"); }
        $info->{'status_code'} = 200;
        $info->{'is_success'} = 1;
      }

      $dbh->write_page ($info);
    }
  }
  if ($self->{'verbose'} >= 2) {
    print __x("code:     {code}\n", code => $info->{'status_code'});
    print __x("response: {status}\n", status => $info->{'status_line'});
  }

  $info = $dbh->read_page ($uri, $anchor);
  ### read_page: $uri, $anchor
  ### $info
  my $err;
  if ($self->{'suppress_500'}
      && $info->{'status_code'} == 500) {

  } elsif ($info->{'status_code'} == 301  # Moved Permanently
           && (sans_trailing_slash($uri)
               eq sans_trailing_slash($info->{'redir_location'}||''))) {
    # suppress redir only for different trailing slash
    # FIXME: anchor check on redir?

  } elsif (! $info->{'is_success'}) {
    $err = $info->{'status_line'};
    if (defined $info->{'redir_location'}) {
      $err .= "\n  $info->{'redir_location'}";
    }

  } elsif ($info->{'anchor_not_found'}) {
    my $have_anchors = join(',', @{$info->{'have_anchors'}});
    if (length($have_anchors) == 0) {
      $have_anchors = __('[none]');
    } elsif (length($have_anchors) > 256) {
      $have_anchors = __('[too many to list]');
    }
    $err = __x("no such anchor {anchor}\n  have: {have_anchors}\n",
               anchor => $anchor,
               have_anchors => $have_anchors);
  }

  if (defined $err && $printed{$url_raw}++ < 5) {
    print "$where:\n  $url_raw\n  $err\n";
  }
  if (defined $err) {
    $count_bad++;
  } else {
    $count_ok++;
  }
}

# $html is a string of html
# return a list of anchor names <a name="foo"> found in $html
#
sub html_anchors {
  my ($html) = @_;
  require HTML::Parser;
  my @anchors;
  my $handler = sub {
    my ($tagname, $attr) = @_;
    if ($tagname eq 'a') {
      my $name = $attr->{'name'};
      if (defined $name) { push @anchors, $name; }
    }
    my $id = $attr->{'id'};
    if (defined $id) { push @anchors, $id; }
  };
  my $parser = HTML::Parser->new
    (api_version => 3,
     start_h     => [ $handler, 'tagname,attr' ]);
  $parser->parse ($html);
  $parser->eof;

  require URI::Escape;
  require HTML::Entities;
  return map {HTML::Entities::decode_entities($_)} @anchors;
}

# $uri is a URI object, return a copy of it with the "fragment" part set to
# undef, or return $uri itself if it has no fragment already
#
sub uri_sans_fragment {
  my ($uri) = @_;
  $uri = $uri->clone;
  $uri->fragment(undef);
  return $uri;
}

sub sans_trailing_slash {
  my ($str) = @_;
  $str =~ s{/$}{};
  return $str;
}

# $resp is a HTML::Response
# if it's a meta-refresh then return a URI object of the redirect target,
# if not then return undef
sub response_meta_refresh {
  my ($resp) = @_;
  ### response_meta_refresh() ...

  my $content = $resp->decoded_content;
  ### $content
  if (defined $content
      && $content =~ /^<meta\s+http-equiv="refresh"\s+content=["']\d+;\s+url=([^'"]*)/i) {
    return $1;
  } else {
    return undef;
  }
}


#------------------------------------------------------------------------------

sub recheck {
  my ($self, $url) = @_;
  my $dbh = $self->dbh;
  $dbh->recheck ($url);
}
sub recheck_404 {
  my ($self) = @_;

  my $count = 0;
  my $dbh = $self->dbh;
  $count = $dbh->do ('DELETE FROM page WHERE status_code=404');
  $count += 0; # numize '0E0' return when none deleted
  print __nx("recheck 404 not founds discard {count} cached result\n",
             "recheck 404 not founds discard {count} cached results\n",
             $count,
             count => $count);
}

#------------------------------------------------------------------------------

sub new {
  my $class = shift;
  return bless { retry_500 => 1,
                 verbose => 0,
                 @_ }, $class;
}

sub progname {
  my ($self) = @_;
  require FindBin;
  return $FindBin::Script;
}

sub set_verbose {
  my ($self, $verbose) = @_;
  if (($self->{'verbose'} = $verbose)) {
    print __x("verbose: {verbose}\n", verbose => $verbose);
  }
}

sub command_line {
  my ($self) = @_;
  ### command_line(): @_
  if (! ref $self) {
    $self = $self->new;
  }

  my $option_vacuum = 0;
  my $show_usage = 1;
  my $action = 'check_dir_or_file';
  require Getopt::Long;
  Getopt::Long::Configure ('permute',  # options with args, callback '<>'
                           'no_ignore_case',
                           'bundling');
  Getopt::Long::GetOptions
      (# 'help|?'  => $help,
       'verbose:1' => sub {
         my ($opt,$value) = @_;
         $self->set_verbose ("$value");
       },
       version     => sub {
         print __x("{progname} version {VERSION}\n",
                   progname => $self->progname,
                   VERSION => $VERSION);
         $show_usage = 0;
       },
       vacuum      => \$option_vacuum,

       'recheck'     => sub { $action = 'recheck'; },
       'recheck-404' => sub { $self->recheck_404 },
       'suppress-500' => sub { $self->{'suppress_500'} = 1 },

       '<>' => sub {
         my ($dir_or_file) = @_;
         $dir_or_file = "$dir_or_file";  # stringize getopt object
         $show_usage = 0;
         $self->$action($dir_or_file);
       },
      );

  if ($count_ok || $count_bad) {
    print __x("{count_ok} ok, {count_bad} bad\n",
              count_ok => $count_ok,
              count_bad => $count_bad);
  }

  # expire after any checks
  if ($option_vacuum || App::Distlinks::DBI->can('instance')) {
    require App::Distlinks::DBI;
    App::Distlinks::DBI->instance->expire ($option_vacuum);
  }
  if ($option_vacuum) {
    require App::Distlinks::DBI;
    App::Distlinks::DBI->instance->vacuum;
    $show_usage = 0;
  }

  if ($show_usage) {
    print __x("Usage: {progname} FILES-OR-DIRECTORIES...\n",
              progname => $self->progname);
    return 1;
  }

  return 0;
}

1;
__END__

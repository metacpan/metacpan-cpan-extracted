# Copyright (C) 2007-8 Thomas Thurman <tthurman@gnome.org>
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

package App::BLT;

use strict;
use warnings;
use Cwd qw(abs_path);
use vars qw($VERSION @EXPORT @ISA);
use XML::Tiny qw(parsefile);
require Exporter;

our ($check, $set,
    $sync, $force, $help, $version, $username,
    $check_public,
    %rc_settings);

@ISA = qw(Exporter);
$VERSION = '0.22';
# Well, since we're mainly here so that most of blt's functionality can
# live in module space, let's export almost everything.  This needs
# cleaning up later, really, because it's not elegant.
@EXPORT = qw(twitter_post twitter_following print_masthead print_help
             already_running_in_background
             $check $set $help $version $force $sync $check_public $username
             %rc_settings $timeline $last_fetch_filename $home $pid_filename
             $rc_filename $last_fetch);

our $home = $ENV{HOME} || (getpwuid($<))[7];
our $rc_filename = "$home/.bltrc.xml";
our $pid_filename = "$home/.blt_pid";
our $last_fetch_filename = "$home/.blt_last_fetch";
our $timeline;

sub print_masthead {
  print <<EOT;
blt - bash loves twitter - shell/twitter integration
Copyright (c) 2008 Thomas Thurman - tthurman\@gnome.org - http://marnanel.org
blt is released in the hope that it will be useful, but with NO WARRANTY.
blt is released under the terms of the GNU General Public Licence.

EOT
}

sub print_help {
  print <<EOT;
Choose at most one mode:
  -c, --check = print updates from Twitter
  -s, --set = update Twitter from command line (default)
  -h, --help = show this text
  -v, --version = show version number
  -a, --as=USER = post as USER, if you add them in ~/.bltrc.xml

Switches:
  -F, --force  = always check, even if we checked recently
  -S, --sync   = don't check in the background
  -P, --public = read the public timeline (not for posting!)
EOT
}

sub add_to_bashrc {
  my $bashrc = "$main::home/.bashrc";

  if (-e $bashrc) { # if they don't have one, don't bother checking

    local $/;
    undef $/;

    open BASHRC, "<$bashrc" or die "Can't open $bashrc: $!";
    my $bashrc = <BASHRC>;
    close BASHRC or die "Can't close $bashrc: $!";

    return if ($bashrc =~ /^[^#\n]*PROMPT_COMMAND/m);
  }

  print "\nAttempting to add ourselves to $bashrc...";

  my $program = abs_path($0);
  open BASHRC, ">>$bashrc" or die "Can't open $bashrc: $!";
  print BASHRC "\n\n# Added by $program\nexport PROMPT_COMMAND=\"$program --check\"\n"
        or die "Can't write to $bashrc: $!";
  close BASHRC or die "Can't close $bashrc: $!";

  print "done.\n\n";
  print "You will need to log out and back in to get\n";
  print "automatic notifications.\n";
}

sub already_running_in_background {
  if (-e $pid_filename) {

    my @stats = stat($main::pid_filename);
    my $age = time-($stats[9]);

    if ($age > 60) {
      # oh, that's just silly. Nobody takes a whole minute
      unlink $main::pid_filename;
      return 0;
    }

    # Maybe we should also check that the PID is valid,
    # but I think that's overkill.

    return 1;
  } else {
    return 0;
  }
}

#############################
# Here's our roll-your-own Twitter library
# because Net::Twitter is a bit clunky.
# It is very simple, and still in a lot of flux.
#
# This will eventually become Net::Twitter::Simple,
# or something like that.
#############################

sub twitter_useragent {

  # If we get here, we need LWP. But don't "use" it because that's an
  # implicit BEGIN{} (so we will always incur the hit of loading it,
  # even though the general case is that we don't need it).
  eval { require LWP::UserAgent; };

  # Create a user agent object
  my $ua = LWP::UserAgent->new(timeout => 5);

  # Dn't authenticate if they're asking for -c -P
  unless ($check_public) {
      $ua->credentials('twitter.com:80', 'Twitter API',
          $rc_settings{user},
          $rc_settings{pass},
      );
  }

  $ua->default_header('X-Twitter-Client' => 'blt');
  $ua->default_header('X-Twitter-Client-Version' => $VERSION);
  $ua->default_header('X-Twitter-Client-URL' => 'http://marnanel.org/projects/blt/');

  return $ua;
}

sub twitter_post {
  my ($status) = @_;

  my $ua = twitter_useragent();
  my $response = $ua->post(
    'http://twitter.com/statuses/update.xml',
    {
      status => $status,
      source => 'blt',
    }
  );

  die $response->status_line unless $response->is_success;

}

sub twitter_following {

  my ($since) = @_;

  my $ua = twitter_useragent();

  if (defined $since) {
    eval {
      require POSIX; import POSIX qw(setlocale LC_ALL strftime);
      setlocale(LC_ALL(), 'C');
      # note that the "since" parameter is not currently working with Twitter
      $ua->default_header('If-Modified-Since', strftime("%a, %d %b %Y %T GMT", gmtime($since)));
    }
  }

  my $response = $ua->get(
    "http://twitter.com/statuses/${timeline}_timeline.xml",
  );

  unless ($check_public) {
    open LAST_FETCH, ">$last_fetch_filename" or die "Can't open $last_fetch_filename: $!";
    print LAST_FETCH time;
    close LAST_FETCH or die "Can't close $last_fetch_filename: $!";
  }

  if ($response->code == 500 && $response->status_line =~ /Can't connect/) {
    return "blt: failed to reach twitter; won't check again for a while\n".$response->status_line."\n";
  }

  return '' if $response->code == 304; # Not Modified
  die $response->status_line unless $response->is_success;

  my (@results, $screenname, $text);

  open my $fh, '<', \$response->content;
  for (@{parsefile($fh)->[0]->{'content'}}) {

    for my $field (@{ $_->{'content'} }) {
      if ($field->{'name'} eq 'text') {
        $text = $field->{'content'}->[0]->{'content'};
      } elsif ($field->{'name'} eq 'user') {
        for my $user_field (@{ $field->{'content'}}) {
          if ($user_field->{'name'} eq 'screen_name') {
            $screenname = $user_field->{'content'}->[0]->{'content'};
            last; # that's all we need to know about a user
          }
        }
      }
    }

    push @results, [$screenname, $text];
  }
  close $fh;

  my $result = '';

  foreach (@results) {

    my ($screenname, $text) = @{$_};
    $result .= "<$screenname> $text\n";
  }

  return $result;
}

1;


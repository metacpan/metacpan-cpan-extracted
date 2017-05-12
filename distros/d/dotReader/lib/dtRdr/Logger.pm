package dtRdr::Logger;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

# NOTE we don't strictly need this at the moment because we're loading
# Time::HiRes is the 0.pm and such, but I don't want to leave it up to
# coincidence.  Log::Log4perl needs to fix their buggy reimplementation
# of require and after 3 weeks, I'm tired of waiting.
BEGIN { # hotpatch
  require Log::Log4perl::Util;
  my $fixed = sub {
    my($mod_name) = @_;
    $mod_name = join('/', (split /::/, $mod_name)) . '.pm';
    return(eval { require($mod_name); });
  };
  no warnings 'redefine';
  *Log::Log4perl::Util::module_available = $fixed;
} # end hotpatch
use Log::Log4perl ();


=head1 NAME

dtRdr::Logger - global logging

=head1 SYNOPSIS

  use dtRdr::Logger;
  L->debug($message, ...);
  L->info($message, ...);
  L->warn($message, ...);
  L->error($message, ...);
  L->fatal($message, ...);

For a stacktrace:

  sub bar {
    L()->logcluck("foo");
  }

See L<Log::Log4perl> for more info.

=head1 ABOUT

This (currently) installs a $SIG{__WARN__}, though we'll probably try to
move away from that.

=cut

require Exporter;

=head2 import

  dtRdr::Logger->import(@args);

=cut

{
# the gymnastics here are really just to allow the test suite to run
# without doing dtRdr->init;
my $did_init = 0;
sub import {
  my ($package, $args) = @_;

  unless($did_init) {
    # if nobody ever inits us, we just dump everything on stderr
    my $conf = <<'    ---';
      log4perl.logger                 = WARN, Screen
      log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
      log4perl.appender.Screen.stderr = 1
      log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
      log4perl.appender.Screen.layout.ConversionPattern=%p - %m at %C line %L%n
    ---
    $conf =~ s/^\s+//mg;
    Log::Log4perl->init(\$conf) or die("$!");
    $did_init = 1;
  }
  goto \&Exporter::import;
} # end subroutine import definition
}
########################################################################

our @EXPORT = qw(L RL WARN DBG_DUMP);

=head1 Get Logger

=head2 L

A shortcut to return a logger object FOR YOUR NAMESPACE with an optional
list of subtags.

  L($subtag);

Example:

  package My::Package;
  my $logger = L;
  my $logger = L('#foo');

Now $logger will log into the class 'log4perl.logger.My.Package.#foo'.

$subtag MUST start with a #.  If this is omitted, it will be changed.

=cut

sub L (@) {
  my $class = caller;
  my ($tag) = @_;

  if(defined($tag) and $tag ne '') {
    $tag =~ s/^#*/#/;
    $class .= '.' . $tag;
  }

  Log::Log4perl->get_logger($class);
} # end subroutine L definition
########################################################################


=head2 RL

A shortcut to a root-level logger.

  RL($tag);

  my $logger = RL('#foo');

Now $logger which will log into the class 'log4perl.logger.#foo'.

$tag MUST start with a #.  If this is omitted, it will be changed.

=cut

sub RL {
  my ($tag) = @_;
  $tag or croak('must have a tag for a root logger');

  $tag =~ s/^#*/#/;
  Log::Log4perl->get_logger($tag);
} # end subroutine RL definition
########################################################################

sub WARN { local $SIG{__WARN__}; carp(@_); }

=head2 editor

Launches $ENV{THOUT_EDITOR} with a tempfile containing $string.

Just a handy way to get some debugging data into an editor.

  dtRdr::Logger->editor($string);

Or, to do lazy evaluation only when needed, pass a sub that returns a
string.

  dtRdr::Logger->editor(sub {do_stuff_that_takes_time()});

=cut

sub editor {
  my $package = shift;
  my ($string) = @_;
  unless($ENV{THOUT_EDITOR} and require File::Temp) {
    print STDERR "dtRdr::Logger->edit: too bad\n";
    return;
  }
  if(ref($string) eq 'CODE') {
    # enables lazy evals (for optimization sake)
    $string = $string->();
  }

  require File::Spec; # bah -- File::Temp won't use tmp with a template
  my ($fh, $filename) = File::Temp::tempfile( 'dr-data-' . 'X'x8,
    DIR => File::Spec->tmpdir,
    UNLINK => 1
    );
  print $fh $string;

  my @cmd = (split(/ /, $ENV{THOUT_EDITOR}), $filename);
  if(0) {
    my $pid = fork;
    $pid and return;
    defined($pid) or die;
    system(@cmd);
    sleep(1);
    unlink($filename);
    exit;
  }
  else {
    system(@cmd);
    sleep(1);
  }
} # end subroutine editor definition
########################################################################

=head2 DBG_DUMP

Similar to editor, but writes to a tempfile in "/tmp/$filename".

  DBG_DUMP($ENV_NAME, $filename, sub {$content});

Only acts if $ENV{"DBG_$ENV_NAME"} is set.

  DBG_FOO=1 ./Build test

...will cause this

  DBG_DUMP('foo', 'thisfile.txt', sub {$blah});

...to write the content of $blah to '/tmp/thisfile.txt'.

The sub {$thing} thing is a speed hack, but that variable is big enough
to make you want to open it in an editor, so...

=cut

sub DBG_DUMP {
  my ($var, $filename, $string) = @_;
  $var = 'DBG_' . $var unless($var =~ m/^DBG_/);

  # TODO the point of checking the var here is to allow a global disabler

  $ENV{$var} or return;
  if(ref($string) eq 'CODE') {
    # enables lazy evals (for optimization sake)
    $string = $string->();
  }
  require File::Spec;
  $filename = File::Spec->tmpdir . '/' . $filename;
  open(my $fh, '>:utf8', $filename);
  print STDERR "\$ENV{$var} -- dtRdr::Logger wrote $filename \n";
  print $fh $string;
} # end subroutine DBG_DUMP definition
########################################################################

=head2 init

  dtRdr::Logger->init(filename => "foo");

=cut

sub init {
  my $package = shift;
  (@_ % 2) and croak("odd number of elements in arguments");
  my %args = @_;

  $args{filename} or croak("filename is required");

  # TODO just use FAM to send a signal (or even do without the signal?)
  # alternatively, do without the watch (probably best in production)
  Log::Log4perl->init_and_watch($args{filename}, 'HUP');

  # this idea stolen from Jifty
  my $logger = Log::Log4perl->get_logger('#sigcaught');
  $SIG{__WARN__} = sub {
    my @mess = map({chomp; $_} map({"$_"} @_));
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;

    my $caller = caller;

    # I don't want to chase all of these, but this is really common
    my $excepted = 1;
    if($_[0] =~ m/^Use of uninitialized value/) { warn @_; }
    elsif($_[0] =~ m/^WARNING:/) { warn @_; }
    elsif($caller eq 'Carp')     { warn @_; }
    else { $excepted = 0; }
    $excepted and return;


    if(0) { # haven't decided if I want this or not
      0 and warn "get log for $caller (", Carp::longmess, ")";
      my $spec_log = Log::Log4perl->get_logger("caught.$caller");
      $spec_log->warn(@mess);
    }

    # the caught warnings get shortened
    #my $mess = substr(join(" ", @mess), 0, 70);
    my $mess = join(" ", @mess);
    $mess =~ s/ at .* line (\d+).*$//s;
    my $line = $1 || '?';
    $mess =~ s/\n/ /sg;
    if(length($mess) > 50) {
      $mess = substr($mess, 0, 50);
      $mess .= ' ...';
    }
    $logger->warn("#caught $caller ($line) - $mess");
  };
  { # XXX hope we don't need this.  CPAN gets angry about it
    # package warnings; local $SIG{__WARN__};
  }
} # end subroutine init definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;

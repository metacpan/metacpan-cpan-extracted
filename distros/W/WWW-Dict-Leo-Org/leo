#!/usr/bin/perl
#
# This little handy script grabs the german/english translation for a
# given term from http://dict.leo.org. Thanks the LEO folks for their
# good job!
#
# Usage is quite simple, the script requires just one parameter,
# the term to be translated. It will then return the results in
# an unformatted form.
#
# Copyleft (l) 2000-2017 by Thomas v.D. <tlinden@cpan.org>. leo may be
# used and distributed under the terms of the GNU General Public License.
# All other brand and product names are trademarks, registered trademarks
# or service marks of their respective holders.

use lib qw(blib/lib);

use utf8;

use strict;
use Getopt::Long;
use POSIX qw(isatty);
use WWW::Dict::Leo::Org;
use Data::Dumper;



#
# internal settings
#
my $highlight = 1;
my $default_c = "\033[0m";    # reset default terminal color
my $bold_c    = "\033[0;34m"; # blue color
my $copy_c    = "\033[0;35m"; # copyright message color (green)

my $version   = "2.02";
my $config    = $ENV{HOME} . "/.leo";
my $cache     = $ENV{HOME} . "/.leo-CACHE.db";

my $debugging = 0;

#defaults for config
my %conf      = (
                 use_cache => "no",
                 use_color => "yes",
                 use_latin => "yes"
                );

my %validopts = qw(use_cache 0 use_color 0 user_agent 0 use_latin 0);
my %line      = %validopts;
my %CACHE     = ();
my $site      = "";
my $proxy_user = "";
my $proxy_pass = "";

sub debug;

my($o_s, $o_m, $o_c, $o_l, $o_v, $o_h, $o_n, $o_f, $o_d, $o_u, $o_p);

isatty(1) && eval q{ use open OUT => ':locale'};

#
# commandline options
#
Getopt::Long::Configure( qw(no_ignore_case));
if (! GetOptions (
                  "spelltolerance|s=s" => \$o_s,
                  "morphology|m=s"     => \$o_m,
                  "chartolerance|c=s"  => \$o_c,
                  "language|l=s"       => \$o_l,
                  "force|f"            => \$o_f,
                  "version|v"          => \$o_v,
                  "help|h"             => \$o_h,
                  "debug|d"            => \$o_d,
                  "noescapechars|n"    => \$o_n,
                  "user|u=s"           => \$o_u,
                  "passwd|p=s"         => \$o_p
                 )    ) {
  &usage;
}

if ($o_h) {
  &usage;
}
if ($o_v) {
  print STDERR "leo version $version\n";
  exit;
}


#
# search term
#
my $string = shift;
if (!$string) {
  $string = <STDIN>;
  chomp $string;
}

if (eval { require I18N::Langinfo; require Encode; 1 }) {
  my $codeset = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());
  if ($codeset) {
    for ($string) {
      $_ = Encode::decode($codeset, $_);
    }
  }
}

#
# open the config, if any
#
if (-e $config) {
  open C, "<$config" or die "Could not open config $config: $!\n";
  local $_;
  while (<C>) {
    chomp;
    next if(/^\s*#/); # ignore comments
    next if(/^\s*$/); # ignore empty lines
    s/^\s*//;         # remove leading whitespace
    s/\s*$//;         # remove trailing whitespace
    s/\s*#.*$//;      # remove trailing comment
    my($opt, $val) = split /\s*=\s*/;
    $conf{$opt} = $val;
    $line{$opt} = $.;
  }
  close C;
}


#
# validate the config
#
foreach my $opt (keys %conf) {
  if (!exists $validopts{$opt}) {
    print "<$opt>\n";
    print STDERR "Error in config $config line: " .
      $line{$opt} . ". Unsupported option \"$opt\"!\n";
    exit;
  }
}

#
# feed config values into program
#
if ($conf{use_color} eq "no") {
  $highlight = 0;
}
elsif ($conf{use_color} eq "yes") {
  $highlight = 1;
}

#
# open the cache, if wanted
#
if ($conf{use_cache} eq "yes") {
  $conf{use_cache} = "no";
  no strict 'subs';
  foreach my $M (qw(DB_File NDBM_File GDBM_File)) {
    eval { require $M; };
    if (! $@) {
      tie(%CACHE, $M, $cache, O_RDWR|O_CREAT, 0600) or $conf{use_cache} = "no";
      $conf{use_cache} = "yes";
      last;
    }
  }
}

my %PARAM;

if ($o_l) {
  $PARAM{"-Language"} = $o_l;
}
if(exists $ENV{http_proxy}) {
  $PARAM{"-Proxy"} = $ENV{http_proxy};
}
if ($o_u) {
  $PARAM{"-ProxyUser"} = $o_u;
}
if ($o_p) {
  $PARAM{"-ProxyPass"} = $o_p;
}

if($o_n) {
  $highlight = 0;
}
else {
  # highlighting turned on, check if possible
  if (! isatty(1)) {
    $highlight = 0;
  }
}
if ($o_d) {
  # enable
  $PARAM{"-Debug"} = 1;
}

if($o_s) {
  $PARAM{"-SpellTolerance"} = $o_s;
}
if($o_m) {
  $PARAM{"-Morphology"} = $o_m;
}
if($o_c) {
  $PARAM{"-CharTolerance"} = $o_c;
}

if (exists $ENV{http_proxy} and $o_u) {
  # authenticate
  if (! $o_p) {
    # ask for it
    my $proxy_pass;
    local $| = 1;
    print "password: ";
    eval {
      local($|) = 1;
      local(*TTY);
      open(TTY,"/dev/tty") or die "No /dev/tty!";
      system ("stty -echo </dev/tty") and die "stty failed!";
      chomp($proxy_pass = <TTY>);
      print STDERR "\r\n";
      system ("stty echo </dev/tty") and die "stty failed!";
      close(TTY);
    };
    if ($@) {
      $proxy_pass = <>;
    }
    chomp $proxy_pass;
    $PARAM{"-ProxyPass"} = $proxy_pass;
  }
}

my (@match, $lines, $maxsize);
my $cache_key = join ("", sort keys %PARAM) . $string;
if ($o_f && $conf{use_cache} eq "yes") {
  delete $CACHE{$cache_key};
}

if(exists $CACHE{$cache_key} && $conf{use_cache} eq "yes") {
  # deliver from cache
  my $code = $CACHE{$cache_key};
  my ($VAR1, $VAR2, $VAR3);
  eval $code;
  @match = @{$VAR1};
  $lines = $VAR2;
  $maxsize = $VAR3;
}
else {
  my $leo = new WWW::Dict::Leo::Org(%PARAM) or
    die "Could not initialize WWW::Dict::Leo::Org: $!\n";
  @match   = $leo->translate($string);
  $lines   = $leo->lines();
  $maxsize = $leo->maxsize();

  if($conf{use_cache} eq "yes") {
    $CACHE{$cache_key} = Dumper(\@match, $lines, $maxsize);
  }
}

if ($conf{use_cache} eq "yes") {
  dbmclose(%CACHE);
}

if(! @match) {
  print STDERR "Search for \"$string\" returned no results.\n";
  exit 1;
}

$maxsize += 5;
print "Found $lines matches for '$string' on dict.leo.org:\n";

my $fmt;
my $c = "\$fmt = \" %-${maxsize}s %s\n\"";
eval $c;

#
# print it out in a formated manner, keep the order of dict.leo.org
#
foreach my $section (@match) {
  utf8::decode($section->{title}) if ($conf{use_latin});

  if ($highlight) {
    print "\n${bold_c}$section->{title}${default_c}\n";
  }
  else {
    print "\n$section->{title}\n";
  }

  foreach my $entry (@{$section->{data}}) {
    if ($conf{use_latin}) {
      utf8::decode($entry->{left});
      utf8::decode($entry->{right});
    }
    if ($highlight) {
      $entry->{left}  =~ s/(\Q$string\E)/$bold_c . $1 . $default_c/ei;
      $entry->{right} =~ s/(\Q$string\E)/$bold_c . $1 . $default_c/ei;
    }
    printf $fmt, $entry->{left}, $entry->{right};
  }
}


print "$copy_c" if $highlight;
print "\n     Fetched by leo $version via http://dict.leo.org/";
print "\n     Copyright (C) LEO  Dictionary Team 1995-2017";
print "\n     [leo] GPL Copyleft   Thomas v.D. 2000-2017\n\n";
print "$default_c" if $highlight;



sub parserror {
  my $msg = shift;
  print STDERR "Parse error $msg\n";
  print STDERR "Could not recognize site html of target site\n";
  print STDERR "dict.leo.org. This might be a bug or the site\n";
  print STDERR "might have changed. Please repeat the last step\n";
  print STDERR "with debugging enabled (-d) and send the output\n";
  print STDERR "to the author. Thanks.\n";
  exit 1;
}

sub usage {
  my $msg = shift;
  my $me        = $0;
  $me           =~ s(^.*/)();

  print "$msg\n" if($msg);

  print qq(Usage:   $me [-slmcfuphdv] [<term>]
Translate a term from german to english or vice versa.

-l, --language=[de2]<countrycode>[2de]        translation direction
-n, --noescapechars                           dont use escapes for highlighting
-f, --force                                   don't use the query cache
-u, --user=username                           user for proxy authentication
-p, --passwd=password                         cleartext passphrase for proxy authentication
-h, --help                                    display this help and exit
-d, --debug                                   enable debugging output
-v, --version                                 output version information and exit

<term> is the string you are asking to be translated. It will
be requested from STDIN if not specified on the commandline.

Supported <countrycode>s are:

en    english
es    spanish
fr    french
ru    russian
pt    portuguese
pl    polish
ch    chinese

You can  specify only the country  code, or append de2  in order to
force translation to german, or  preprend de2 in order to translate
to the other language. Valid examples:

ru     to or from russian
de2pl  to polish
es2de  spanish to german

Report bugs to <tlinden\@cpan.org> or on https://github.com/TLINDEN/leo/issues.
);

  exit 1;
}



1;



=head1 NAME

leo - commandline interface to http://dict.leo.org/.

=head1 SYNOPSIS

 leo [-slmcfuphdv] [<term>]

=head1 DESCRIPTION

B<leo> is a commandline interface to the german/english/french
dictionary on http://dict.leo.org/. It supports almost
all features which the website supports, plus more.

Results will be printed to the terminal. By default the
searched key word will be highlighted (which can be
turned off, see below).

To get faster results, B<leo> is able to cache queries
if you repeatedly use the same query.

B<leo> acts as a standard webbrowser as your mozilla or
what so ever does, it connects to the website, exectues
the query, parses the HTML result and finally prints
it somewhat nicely formatted to the terminal.

As of this writing B<leo> acts as:

 Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9

=head1 OPTIONS

=over

=item I<-s --spelltolerance>

Allow spelling errors.

Possible values: B<standard>, B<on> or B<off>.

Default setting: B<standard>.

=item I<-m --morphology>

Provide morphology information.

Possible values: B<standard>, B<none> or B<forcedAll>.

Default setting: B<standard>.

=item I<-c --chartolerance>

Allow umlaut alternatives.

Possible values: B<fuzzy>, B<exact> or B<relaxed>.

Default: B<relaxed>.

=item I<-l --language>

Translation direction. Please note that dict.leo.org always translates
either to or from german.

The following languages are supported: english, polish, spanish, portuguese
russian and chinese.

You can  specify only the country  code, or append B<de2>  in order to
force translation to german, or  preprend B<de2> in order to translate
to the other language.

Valid examples:

ru     to or from russian
de2pl  to polish
es2de  spanish to german

Valid country codes:

en    english
es    spanish
fr    french
ru    russian
pt    portuguese
pl    polish
ch    chinese

Default: B<en>.

=item I<-n --noescapechars>

Don't use escapes for highlighting.

Default: do highlighting.

Controllable via config file too. See below.

No highlighting will be used if STDOUT is not connected
to a terminal.

=item I<-f --force>

Don't use the query cache.

Default: use the cache.

This option has no effect if B<use_cache> is turned
off in the config file.

=item I<-u --user>

Specify the http proxy user to use if your proxy requires
authentication. Read the 'PROXY' section for more details.

=item I<-p --passwd>

Specify the cleartext password to use with http proxy
authentication.

This is not recommended and just implemented for completeness.

=item I<-h --help>

Display this help and exit.

=item I<-v --version>

Display version information and exit.

=item I<-d --debug>

Enable debugging output (a lot of it, beware!), which will be printed
to STDERR. If you find a bug you must supply the debugging output
along with your bugreport.

=back

B<term> is the key word which you want to translate.
If the term contains white spaces quote it using double
quotes.

If the B<term> parameter is not specified, B<leo> will read
it from STDIN.

=head1 CONFIG

B<leo> reads a config file B<.leo> in your home directory
if it exists. The following variables are supported:

=over

=item I<use_latin>

Turns on conversion of UTF8 characters to their latin*
encoding.

Default setting (if not given): B<yes>.

=item I<use_cache>

Controls the use of the cache (see later).

Possible values: B<yes> or B<no>.

Default setting(if not given): B<yes>.

If the commandline option B<-f> or B<--force> has been
set then the cache will not be used for the query and
if for this query exists an entry in the cache it will
be removed from it.

=item I<use_color>

Controls the use of escape sequences in the terminal
output to highlight the key-waord in the result.

Possible values: B<yes> or B<no>.

Default setting(if not given): B<yes>.

You can set this option via commandline too: B<-n>
or B<--noescapechars>.

The config option has higher precedence.

=item I<user_agent>

You may modify the user agent as B<leo> identifies itself
on the target site. The default is:

User-Agent: Mozilla/5.0 (compatible; Konqueror/3.3.1; X11)

=back

=head1 CACHING

B<leo> supports caching of queries for faster results
if you repeatedly use the same query. A query consists
of the given B<term> (the key word or string) plus the
translation option settings.

If you, for example, execute once the following query:

% leo langnase

and somewhere later:

% leo -c exact

then B<leo> will treat the latter query as a different
one than the previous one, because I<dict.leo.org>
behaves different when different translation options
are given.


=head1 PROXY

B<leo> can be used with a HTTP proxy service. For this to
work, you only have to set the environment variable
B<http_proxy>. It has the following format:

PROTO://[USER:PASSWD@]SERVER[:PORT]

The only supported protocol is B<http>. If your proxy works without
authentication, you can omit the B<user:passwd> part. If no
port is specified, B<80> will be used.

Here is an example (for bash):

export http_proxy=http://172.16.120.120:3128

and an example with authentication credentials:

export http_proxy=http://max:34dwe2@172.16.120.120:3128

As security is always important, I have to warn you, that
other users on the same machine can read your environment
using the 'ps -e ..' command, so this is not recommended.

The most secure way for proxy authentication is just to
specify the server+port with B<http_proxy> but no credentials,
and instead use the B<-u> commandline parameter to specify
a user (do not use B<-p> to specify the password, this will
also be readyble in process listing). In this case, B<leo>
will ask you interactively for the password. It will try its
best to hide it from being displayed when you type it (as
most such routines in other tools do it as well), it this
fails (e.g. because you do not have the 'stty' tool installed),
the password will be read from STDIN.

=head1 FILES

~/.leo             the config file for leo. Not required.
~/.leo-CACHE.db*   the cache file.


=head1 AUTHOR

Thomas v.D. <tlinden@cpan.org>


=head1 BUGS

B<leo> depends on http://dict.leo.org/. It may break B<leo>
if they change something on the site. Therefore be so kind and
inform me if you encounter some weird behavior of B<leo>.
In most cases it is not a bug of B<leo> itself, it is a
website change on http://dict.leo.org/.

In such a case repeat the failed query and use the commandline
flag B<-d> (which enables debugging) and send the full output
to me, thanks.


=head1 COPYRIGHT

B<leo> copyleft 2000-2017 Thomas v.D.. All rights reserved.

http://dict.leo.org/ copyright (c) 1995-2017 LEO Dictionary Team.


The search results returned by B<leo> are based on the work
of the people at LEO.org. Thanks for the great work.

Some time ago they told me that they are disagreed with B<leo>,
or in other words: from their point of view B<leo> seems to
break copyright law in some or another way.

I thought a long time about this, but I must deny this. B<leo>
acts as a simple web client, just like mozilla, IE or even
lynx are doing. They are providing the service to the public
so I use my favorite web browser to make use of it. In fact
my favorite browser to view dict.leo.org is B<leo>. There is
nothing wrong with that. IMHO.

If you disagree or are asked by the LEO team to stop using B<leo>
you may decide this for yourself. I in my case wrote kinda
browser, what is not prohibited. At least not today.

=head1 VERSION

This is the manpage for B<leo> version B<2.01>.

=cut

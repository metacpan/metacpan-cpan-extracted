#!/usr/local/bin/perl

use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";
chmod 0775, $file;

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
	if 0;
!GROK!THIS!
print OUT <<'!NO!SUBS!';
#                              -*- Mode: Perl -*- 
# Author          : Ulrich Pfeifer
# Created On      : Mon Jan 22 13:00:41 1996
# Last Modified On: Sun Jan  6 22:26:28 2013
# Language        : Perl
# Update Count    : 399
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996-2005, Ulrich Pfeifer, all rights reserved.
# This file is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# 
# 
# %SEEN                is used to store the mtime and absolute pathes to
#                      files which have been indexed.
# 
# %FN   $FN{'last'}    greatest documentid
#       $FN{$did}      a pair of $mtf and $filename where $mtf is the
#                      number of occurances of the most frequent word in
#                      the document with number $did.
# 
# %IDF  $IDF{'*all*'}  number of documents (essentially the same as 
#                      $FN{'last'})
#       $IDF{$word}    number of documents containing $word
# 
# %IF   $IF{$word}     list of pairs ($docid,$tf) where $docid is
#                      the number of a document containing $word $tf
# 
use Fcntl;
use less 'time';
use Getopt::Long;
use File::Basename;
use Text::English;
use Config;

# NDBM_File as LAST resort
BEGIN { @AnyDBM_File::ISA = qw(DB_File GDBM_File SDBM_File ODBM_File NDBM_File) }
use AnyDBM_File;

!NO!SUBS!

eval "\$x = pack 'w', 1;";
if ($x eq "\001") {
    print OUT "\$p          = 'w'; # compressed int patch available\n";
} else {
    print OUT "\$p          = 'S'; # change to 'I' for large collections\n";  
}

$index_dir = $Config{'man1direxp'};
$index_dir =~ s:/[^/]*$::;
$index_dir = $ENV{'INDEXDIR'} if $ENV{'INDEXDIR'};

print OUT <<"EOC";
\$nroff      = \'$Config{'nroff'}\' || \'nroff\';
\$man1direxp = \'$Config{'man1direxp'}\';
\$man3direxp = \'$Config{'man3direxp'}\';
\$IDIR       = \'$index_dir\';
\$prefix     = \'$Config{'prefix'}\';
EOC
;

# Use Term::ReadKey for character-at-a-time input if available.
# Else use "stty cbreak" if BSD, "stty icanon" if non-BSD.
if (eval 'require Term::ReadKey') {
  print OUT "use Term::ReadKey;\n";
  $BSD_STYLE= -1;
} elsif ($Config{'d_bsd'}) {
  $BSD_STYLE= 1;
} else {
  $BSD_STYLE= 0;
}

# # Let's look for a stemmer
# eval "use Text::English;";
# unless ($@) {
#     $stemmer = \&Text::English::stem;
# } else {
#     eval "require 'Stem.pl';";
#     unless ($@) {
#         $stemmer = \&stem;
#     }
# }

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

$pager= $Config{'pager'};
if ($Config{'osname'} eq 'hpux') {
  $pager= "col | $pager";
}
if (exists $ENV{PAGER}) {
  $pager=$ENV{PAGER}
}
$stemmer = \&Text::English::stem;
$debug       = 0;
$opt_index   = '';                # make perl -w happy
$opt_menu    = 1;
$opt_maxhits = 20;
$opt_cbreak  = 1;
&GetOptions(
            'index',
            'cbreak!',
            'maxhits=i',
            'menu!',
            'verbose',
            'dict:i',
            'idir=s',
            ) || die "Usage: $0 [-index] [words ...]\n";

if (defined $opt_idir) {
    $IDIR = $opt_idir;          # avoid to many changes below.
}

if (defined $opt_dict) {
    $opt_dict ||= 100;
}

my $GC_REQUIRED = 0; # garbage collect required? Global variable.

if ($opt_index) {

    # check whether we can use Pod::Text to extract POD
    $PodText     = 0;
    eval {
      require Pod::Text;
      print "Using Pod::Text\n";
      $PodText = 1;
    };


    $IoScalar    = 0;
    eval {
      require IO::Scalar;
      print "Using IO::Scalar\n";
      $IoScalar = 1;
    };

    &initstop;

    tie (%IF,   AnyDBM_File, "$IDIR/index_if",   O_CREAT|O_RDWR, 0644)
        or die "Could not tie $IDIR/index_if: $!\n";
    tie (%IDF,  AnyDBM_File, "$IDIR/index_idf",  O_CREAT|O_RDWR, 0644)
        or die "Could not tie $IDIR/index_idf: $!\n";
    tie (%SEEN, AnyDBM_File, "$IDIR/index_seen", O_CREAT|O_RDWR, 0644)
        or die "Could not tie $IDIR/index_seen: $!\n";
    tie (%FN,   AnyDBM_File, "$IDIR/index_fn",   O_CREAT|O_RDWR, 0644)
        or die "Could not tie $IDIR/index_fn: $!\n";

    require File::Find;

    unless (@ARGV) {            # breaks compatibility :-(
        my %seen;
        my @perllib = grep(length && -d && !$seen{$_}++,
            @Config{qw(installprivlib installarchlib installsitelib installvendorlib installscript installsitearch)});

        for $dir (@perllib) {
            print "Scanning $dir ... \n";
            if (-l $dir) { # debian symlinks installarchlib but we do not want to follow links in general
               my $target = readlink $dir;
               $dir =~ s:[^/]+$:$target:;
            }
            File::Find::find( \&wanted, $dir );
        }
    }

    for $name (@ARGV) {
      add_to_index($name);
    }
    # Check if all (previuosly) indexed files are still available
    # This may take some time.
    warn "Validating index ...\n";
    while (my ($fns, $value) = each %SEEN) {
      my $path = $fns; $path = $prefix.'/'.$path unless $path =~ m:^/:;
      unless (-f $path) {
        my ($mtime, $did) = unpack "$p$p", $value;
        # mark document as deleted
        warn "Marking document $did ($fns) as deleted\n";
        delete $FN{$did};
        delete $SEEN{$fns};
        $GC_REQUIRED++;
      }
    }
    if ($GC_REQUIRED) {
      print STDERR "Garbage collecting\r";
      # garbage collection, this is awfully slow
      my $progress = 0;
      my $words    = keys %IF;
      my %if_new;
      tie (%if_new,   AnyDBM_File, "$IDIR/index_if.new",   O_CREAT|O_RDWR, 0644)
        or die "Could not tie $IDIR/index_if: $!\n";
      while (my ($word,$list) = each %IF) {
        print STDERR "Garbage collecting ".(++$progress)."/".$words."\r";
        my %post = unpack($p.'*',$list);

        #delete $IF{$word};
	$IDF{$word} = 0;
        while (my ($did,$tf) = each %post) {
          if (exists $FN{$did}) {
            $if_new{$word} = '' unless defined $if{$word}; # perl -w
            $if_new{$word} .= pack($p.$p, $did, $tf);
            $IDF{$word}++;
          }
        }
      }
      untie %if_new;
      untie %IF;
      opendir(IDX, $IDIR) or die "Could not read dir '$IDIR': $!";
      for $file (readdir DIR) {
        my $old = $file;
        if ($file =~ s/^index_if\.new/index_if/) {
          rename "$IDIR/$old", "$IDIR/$file";
        }
      }
      print STDERR "\rGarbage collecting ... done";
    }
    untie %IF unless $GC_REQUIRED;
    untie %IDF;
    untie %FN;
    untie %SEEN;
} elsif ($opt_dict) {
    tie (%IDF,  AnyDBM_File, "$IDIR/index_idf",  O_RDONLY, 0644)
        or die "Could not tie $IDIR/index_idf: $!\n".
            "Did you run '$0 -index'?\n";
    while (($key,$val) = each %IDF) {
        printf "%-20s %d\n", $key, $val if $val >= $opt_dict;
    }
    untie %IDF;
} else {
    tie (%IF,   AnyDBM_File, "$IDIR/index_if",   O_RDONLY, 0644)
        or die "Could not tie $IDIR/index_if: $!\n".
            "Did you run '$0 -index'?\n";
    tie (%IDF,  AnyDBM_File, "$IDIR/index_idf",   O_RDONLY, 0644)
        or die "Could not tie $IDIR/index_idf: $!\n";
    tie (%FN,   AnyDBM_File, "$IDIR/index_fn",   O_RDONLY, 0644)
        or die "Could not tie $IDIR/index_fn: $!\n";
    &search(@ARGV);
    untie %IF;
    untie %IDF;
    untie %FN;
    untie %SEEN;
}

sub wanted {
    my $fns = $File::Find::name;

    if ($File::Find::name eq $man3direxp) {
        $File::Find::prune = 1;
    }
    if (-f $_ and $File::Find::name =~ /man|bin|\.(pod|pm|txt)$/) {
      add_to_index($File::Find::name);
    }
}

sub index {
    my $fn  = shift;
    my $fns = shift;
    my $did = shift;
    my %tf;
    my $maxtf = 0;

    if ($fn =~ /\.txt$/) {
       open (IN, "<$fn") || warn "Could not open $fn: $!\n", return (0);
       while ($line = <IN>) {
         warn "=> $line\n" if $debug;
         for $word (&normalize($line)) {
             next if $stop{$word};
             $tf{$word}++;
         }
       }
       close IN;
    } elsif($PodText and -T $fn) {
      my $result;
      my $parser = Pod::Text->new(sentence => 0, width => 78);
      if ($IoScalar) {
        my $tmpfile = new IO::Scalar;
        open(IN,"<$fn");
        $parser->parse_from_filehandle(*IN, $tmpfile);
        warn "===> $fn, $tmpfile" if $debug;
        #for my $line (split /\n/, $tmpfile) {
        while ($tmpfile =~ s/^(.*\n)//) {
          warn "=> $1\n" if $debug;
          for $word (&normalize($1)) {
              next if $stop{$word};
              $tf{$word}++;
          }
        }
        close IN;
      } else {
        my $tmpfile = "$IDIR/tmppod.txt";
        $parser->parse_from_file($fn, $tmpfile);
        open (IN, "<$tmpfile") || warn "Could not open $fn: $!\n", return (0);
        while ($line = <IN>) {
          warn "=> $line\n" if $debug;
          for $word (&normalize($line)) {
              next if $stop{$word};
              $tf{$word}++;
          }
        }
        close IN;
        unlink $tmpfile;
      }
    } else {
      # no Pod::Text found
      open(IN, "<$fn") || warn "Could not open $fn: $!\n", return (0);
      while ($line = <IN>) {
          warn "=> $line\n" if $debug;
          if ($line =~ /^=head/) {
              $pod = 1;
          } elsif ($line =~ /^=cut/){
              $pod = 0;
          } else {
              next unless $pod;
          }
          for $word (&normalize($line)) {
              next if $stop{$word};
              $tf{$word}++;
          }
      }
      close(IN);
    }
    for $tf (values %tf) {
        $maxtf = $tf if $tf > $maxtf;
    }
    for $word (keys %tf) {
        $IDF{$word}++;
        $IF{$word} = '' unless defined $IF{$word}; # perl -w
        $IF{$word} .= pack($p.$p, $did, $tf{$word});
    }
    $FN{$did} = pack($p, $maxtf).$fns; 
    print STDERR "$fns\n";
    1;
}

sub add_to_index {
  my ($name) = @_;
  my $fns = $name; $fns =~ s:\Q$prefix/::;

  if (exists $SEEN{$fns}) {
    my ($mtime, $did) = unpack "$p$p", $SEEN{$fns};
    if ((stat $name)[9] > $mtime) {
      # mark document as deleted
      delete $FN{$did};
      warn "Marking document $did ($name) as deleted\n";
      $GC_REQUIRED++;
    } else {
      # index up to date
      next;
    }
  }
  next unless -f $name;
  if ($name !~ /(~|,v)$/) {
    $did = $FN{'last'}++;
    if (&index($name, $fns, $did)) {
      my ($mtime) = (stat $name)[9];
      $SEEN{$fns} = pack "$p$p", (stat $name)[9], $did;
    }
  }
}

sub normalize {
    my $line = join ' ', @_;
    my @result;

    $line =~ tr/A-Z/a-z/;
    $line =~ tr/a-z0-9_/ /cs;
    for $word (split / /, $line ) {
        $word =~ s/^\d+//;
        next unless length($word) > 2;
        if ($stemmer) {
            push @result, &$stemmer($word);
        } else {
            push @result, $word;
        }
    }
    @result;
}

sub search {
    my %score;
    my $maxhits = $opt_maxhits;
    my (@unknown, @stop);

    &initstop if $opt_verbose;
    for $word (normalize(@_)) {
        unless ($IF{$word}) {
            if ($stop{$word}) {
                push @stop, $word;
            } else {
                push @unknown, $word;
            }
            next;
        }
        my %post = unpack($p.'*',$IF{$word});
        my $idf = log($FN{'last'}/$IDF{$word});
        for $did (keys %post) {
            # skip deleted documents
            next unless exists $FN{$did};
            my ($maxtf) = unpack($p, $FN{$did});
            $score{$did} = 0 unless defined $score{$did}; # perl -w 
            $score{$did} += $post{$did} / $maxtf * $idf;
        }
    }
    if ($opt_verbose) {
        print "Unkown:  @unknown\n" if @unknown;
        print "Ingnore: @stop\n" if @stop;
    }
    if ($opt_menu) {
        my @menu;
        my $answer = '';
        my $no = 0;
        my @s = ('1' .. '9', 'a' .. 'z');
        my %s;
        
        for $did (sort {$score{$b} <=> $score{$a}} keys %score) {
            my ($mtf, $path) = unpack($p.'a*', $FN{$did});
            my $s = $s[$no];
            push @menu, sprintf "%s %6.3f %s\n", $s, $score{$did}, $path;
            $s{$s} = ++$no;
            last unless --$maxhits;
        }
        &cbreak('on') if $opt_cbreak;
        while (1) {
            print @menu;
            print "\nEnter Number or 'q'> ";
            if ($opt_cbreak) {
                read(TTYIN,$answer,1);
                print "\n";
            } else {
                $answer = <STDIN>;
            }
            last if $answer =~ /^q/i;
            $answer = ($s{substr($answer,0,1)})-1;
            if ($answer >= 0 and $answer <= $#menu) {
                my $selection = $menu[$answer]; chomp($selection);
                my ($no, $score, $path) = split ' ', $selection, 3;
                $path = $prefix.'/'.$path unless $path =~ m:^/:;

                if ($path =~ /\.txt$/) {
                    my $pdf = $path; $pdf =~ s:pages/(\S+)_(\d+)\.txt$:$1.pdf:;
                    my $page = $2+0;
                    my $endp = $page+2;
                    my $tmp  = "/tmp/perlinde$$.pdf";

                    if (-f $pdf) {
                       print  "pdftk A=$pdf cat $page-$endp output $tmp\n";
                       system "pdftk", "A=".$pdf, 'cat', "$page-$endp", 'output', $tmp and
                       system "pdftk", "A=".$pdf, 'cat', "$page-end",   'output', $tmp;
                       system "acroread", $tmp;
                       unlink $tmp;
                    } else {
                       print STDERR "$pager '$path'\n";
                       system $pager, $path;
                    }
                } elsif ($selection =~ m:/man:) {
                    my ($page, $sect) = 
                        ($selection =~ m:([^/]*)\.(.{1,3})$:);
                    print STDERR "Running man $sect $page\n";
                    system 'man', $sect, $page;
                } else {
                    print STDERR "Running pod2man $path\n";
                    system "pod2man --official $path | $nroff -man | $pager";
                }
            } else {
                my $path = $prefix."/bin/perlindex";
                system "pod2man --official $path | $nroff -man | $pager";
            }
        }
        &cbreak('off') if $opt_cbreak;
    } else {
        for $did (sort {$score{$b} <=> $score{$a}} keys %score) {
            printf("%6.3f %s\n", $score{$did}, 
                   (unpack($p.'a*', $FN{$did}))[1]);
            last unless --$maxhits;
        }
    }
}

sub cbreak {
    my $mode = shift;
    if ($mode eq 'on') {
        open(TTYIN, "</dev/tty") || die "can't read /dev/tty: $!";
        open(TTYOUT, ">/dev/tty") || die "can't write /dev/tty: $!";
        select(TTYOUT);
        $| = 1;
        select(STDOUT);
        $SIG{'QUIT'} = $SIG{'INT'} = 'cbreak';
!NO!SUBS!
;

if ($BSD_STYLE == -1) {
    print OUT "\tReadMode 3; # Set cbreak mode\n";
} elsif ($BSD_STYLE) {
    print OUT "\tsystem \"stty cbreak </dev/tty >/dev/tty 2>&1\";\n";
    #print OUT "\tsystem \"stty cbreak echo </dev/tty >/dev/tty 2>&1\";\n";
} else {
    print OUT "\tsystem \"stty\", '-icanon', 'eol', \"\\001\";\n";
}
print OUT "    } else {\n";
if ($BSD_STYLE == -1) {
    print OUT "\tReadMode 0; # Restore non-cbreak mode\n";
} elsif ($BSD_STYLE) {
    print OUT "\tsystem \"stty -cbreak </dev/tty >/dev/tty 2>&1\";\n";
    #print OUT "\tsystem \"stty -cbreak echo </dev/tty >/dev/tty 2>&1\";\n";
    } else {
    print OUT "\tsystem \"stty\", 'icanon', 'eol', '^\@'; # ascii null\n";
        }

print OUT <<'!NO!SUBS!';
    }
}


$stopinited = 0;                # perl -w
sub initstop {
    return if $stopinited++;
    while (<DATA>) {
        next if /^\#/;
        for (normalize($_)) {
          $stop{$_}++;
        }
    }
}

=head1 NAME

perlindex - index and query perl manual pages

=head1 SYNOPSIS

    perlindex -index

    perlindex tell me where the flowers are

=head1 DESCRIPTION

"C<perlindex -index>" generates an AnyDBM_File index which can be
searched with free text queries "C<perlindex> I<a verbose query>".

Each word of the query is searched in the index and a score is
generated for each document containing it. Scores for all words are
added and the documents with the highest score are printed.  All words
are stemed with Porters algorithm (see L<Text::English>) before
indexing and searching happens.

The score is computed as:

    $score{$document} += $tf{$word,$document}/$maxtf{$document}
                         * log ($N/$n{$word});

where

=over 10

=item C<$N>

is the number of documents in the index,

=item C<$n{$word}>

is the number of documents containing the I<word>,

=item C<$tf{$word,$document}>

is the number of occurances of I<word> in the I<document>, and

=item C<$maxtf{$document}>

is the maximum freqency of any word in I<document>.

=back

=head1 OPTIONS

All options may be abreviated.

=over 10

=item B<-maxhits> maxhits

Maximum numer of hits to display. Default is 15.

=item B<-menu>

=item B<-nomenu>

Use the matches as menu for calling C<man>. Default is B<-menu>.q

=item B<-cbreak>

=item B<-nocbreak>

Switch to cbreak in menu mode or dont. B<-cbreak> is the default.

=item B<-verbose>

Generates additional information which query words have been not found
in the database and which words of the query are stopwords.

=back

=head1 EXAMPLE

    perlindex foo bar

    1  3.735 lib/pod/perlbot.pod
    2  2.640 lib/pod/perlsec.pod
    3  2.153 lib/pod/perldata.pod
    4  1.920 lib/Symbol.pm
    5  1.802 lib/pod/perlsub.pod
    6  1.586 lib/Getopt/Long.pm
    7  1.190 lib/File/Path.pm
    8  1.042 lib/pod/perlop.pod
    9  0.857 lib/pod/perlre.pod
    a  0.830 lib/Shell.pm
    b  0.691 lib/strict.pm
    c  0.691 lib/Carp.pm
    d  0.680 lib/pod/perlpod.pod
    e  0.680 lib/File/Find.pm
    f  0.626 lib/pod/perlsyn.pod
    Enter Number or 'q'>

Hitting the keys C<1> to C<f> will display the corresponding manual
page. Hitting C<q> quits. All other keys display this manual page.

=head1 FILES

The index will be generated in your man directory. Strictly speaking in 
C<$Config{man1direxp}/..>

    The following files will be generated:

    index_fn           # docid -> (max frequency, filename)
    index_idf          # term  -> number of documents containing term
    index_if           # term  -> (docid, frequency)*
    index_seen         # fn    -> indexed?
    

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@ls6.informatik.uni-dortmund.de>E<gt>

=cut

__END__
# freeWAIS-sf stopwords
a
about
above
according
across
actually
adj
after
afterwards
again
against
all
almost
alone
along
already
also
although
always
among
amongst
an
and
another
any
anyhow
anyone
anything
anywhere
are
aren't
around
as
at
b
be
became
because
become
becomes
becoming
been
before
beforehand
begin
beginning
behind
being
below
beside
besides
between
beyond
billion
both
but
by
c
can
can't
cannot
caption
co
co.
could
couldn't
d
did
didn't
do
does
doesn't
don't
down
during
e
each
eg
eight
eighty
either
else
elsewhere
end
ending
enough
etc
even
ever
every
everyone
everything
everywhere
except
f
few
fifty
first
five
vfor
former
formerly
forty
found "
four
from
further
g
h
had
has
hasn't
have
haven't
he
he'd
he'll
he's
hence
her
here
here's
hereafter
hereby
herein
hereupon
hers
herself
him
himself
his
how
however
hundred
i
i'd
i'll
i'm
i've
ie
if
in
inc.
indeed
instead
into
is
isn't
it
it's
its
itself
j
k
l
last
later
latter
latterly
least
less
let
let's
like
likely
ltd
m
made
make
makes
many
maybe
me
meantime
meanwhile
might
million
miss
more
moreover
most
mostly
mr
mrs
much
must
my
myself
n
namely
neither
never
nevertheless
next
nine
ninety
no
nobody
none
nonetheless
noone
nor
not
nothing
now
nowhere
o
of
off
often
on
once
one
one's
only
onto
or
other
others
otherwise
our
ours
ourselves
out
over
overall
own
p
per
perhaps
q
r
rather
recent
recently
s
same
seem
seemed
seeming
seems
seven
seventy
several
she
she'd
she'll
she's
should
shouldn't
since
six
sixty
so
some
somehow
someone
something
sometime
sometimes
somewhere
still
stop
such
t
taking
ten
than
that
that'll
that's
that've
the
their
them
themselves
then
thence
there
there'd
there'll
there're
there's
there've
thereafter
thereby
therefore
therein
thereupon
these
they
they'd
they'll
they're
they've
thirty
this
those
though
thousand
three
through
throughout
thru
thus
to
together
too
toward
towards
trillion
twenty
two
u
under
unless
unlike
unlikely
until
up
upon
us
used
using
v
very
via
w
was
wasn't
we
we'd
we'll
we're
we've
well
were
weren't
what
what'll
what's
what've
whatever
when
whence
whenever
where
where's
whereafter
whereas
whereby
wherein
whereupon
wherever
whether
which
while
whither
who
who'd
who'll
who's
whoever
whole
whom
whomever
whose
why
will
with
within
without
won't
would
wouldn't
x
y
yes
yet
you
you'd
you'll
you're
you've
your
yours
yourself
yourselves
z
# occuring in more than 100 files
acc
accent
accents
and
are
bell
can
character
corrections
crt
daisy
dash
date
defined
definitions
description
devices
diablo
dummy
factors
following
font
for
from
fudge
give
have
header
holds
log
logo
low
lpr
mark
name
nroff
out
output
perl
pitch
put
rcsfile
reference
resolution
revision
see
set
simple
smi
some
string
synopsis
system
that
the
this
translation
troff
typewriter
ucb
unbreakable
use
used
user
vroff
wheel
will
with
you

!NO!SUBS!

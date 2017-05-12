#AnyDBM handling from perlindex:
# NDBM_File as LAST resort

package
    AnyDBM_File; # hide from indexer
use vars '@ISA';
my @try; @try = qw(DB_File GDBM_File SDBM_File ODBM_File NDBM_File) unless @ISA;
my $mod;
for $mod (@try) {
    if (eval "require $mod") {
	@ISA = $mod;
	last;
    }
};

package Tk::Pod::Search_db;

use strict;
use vars qw($VERSION);

$VERSION = '5.09';

use Carp;
use Fcntl;
use File::Basename qw(dirname);
use File::Spec;
use Text::English;
use Config;

my $PREFIX = $Config::Config{prefix};
# Bug in perlindex: because of assuming Unix directory separators the
# index files are stored in man/man1, not in man on Windows:
my $IDXDIR = $^O eq 'MSWin32' ? $Config::Config{man1dir} : dirname $Config::Config{man1dir};
$IDXDIR ||= $PREFIX; # use perl directory if no manual directory exists
# Debian uses a non-standard directory:
if (-e "/etc/debian_version" && -d "/var/cache/perlindex") {
    $IDXDIR = "/var/cache/perlindex";
    # XXX What to do if perlindex is installed by the user and uses
    # the man directory for storing the index files?
}
# Deliberately ignore the INDEXDIR environment variable which is used
# by perlindex

sub new {
    my $class = shift;
    my $idir  = shift;
    $idir ||= $IDXDIR;
    my (%self, %IF, %IDF, %FN);
    my $if_file  = File::Spec->catfile($idir, "index_if");
    tie (%IF,   'AnyDBM_File', $if_file,   O_RDONLY, 0644)
        	or confess "Could not tie $if_file: $!\n".
           	"Did you install Text::English and run 'perlindex -index'?\n";
    my $idf_file = File::Spec->catfile($idir, "index_idf");
    tie (%IDF,  'AnyDBM_File', $idf_file,   O_RDONLY, 0644)
	       	or confess "Could not tie $idf_file: $!\n";
    my $fn_file  = File::Spec->catfile($idir, "index_fn");
    tie (%FN,   'AnyDBM_File', $fn_file,   O_RDONLY, 0644)
	       	or confess "Could not tie $fn_file: $!\n";

    $self{IF}  = \%IF;
    $self{IDF} = \%IDF;
    $self{FN}  = \%FN;
    #xxx: -idir depended but where can I get this info?
    #	o A fourth index file?
    #   o todo: check perlindex index routine
    $self{PREFIX} = $PREFIX;

    bless \%self, $class;
}

# changes to perlindex's normalize
#	o removed useless(?) stemmer check
#	o lexicalized $word

sub normalize {
    my $line = join ' ', @_;
    my @result;

    $line =~ tr/A-Z/a-z/;
    $line =~ tr/a-z0-9_/ /cs;

    my $word;
    for $word (split / /, $line ) {
        $word =~ s/^\d+//;
        next unless length($word) > 2;
        push @result, &Text::English::stem($word);
    }
    @result;
}

# changes for perlindex's search slightly modified
sub searchWords {
    my($self, $term, %args) = @_;

    my @words = split / /, $term;

    my $restrict_pod = $args{-restrictpod};
    if (defined $restrict_pod) {
	my(@modparts) = split /::/, $restrict_pod;
	$restrict_pod = join('[/\\\\]', map { quotemeta } @modparts);
    }

    #print "try words|", join('|',@_),"\n";
    my $p = 'w';
    my %score;
    my %termhits;
    my $maxhits = 50;
    my (@unknown, @stop);

    my $IF  = $self->{IF};
    my $IDF = $self->{IDF};
    my $FN  = $self->{FN};

    #&initstop if $opt_verbose;
    for my $word (normalize(@words)) {
        unless ($IF->{$word}) {
#             if ($stop{$word}) {
#                 push @stop, $word;
#             } else {
#                 push @unknown, $word;
#             }
            next;
        }
        my %post = unpack($p.'*',$IF->{$word});
        my $idf = log($FN->{'last'}/$IDF->{$word});
        for my $did (keys %post) {
            my ($maxtf) = unpack($p, $FN->{$did});
            $score{$did} = 0 unless defined $score{$did}; # perl -w 
            $score{$did} += $post{$did} / $maxtf * $idf;
	    $termhits{$did}++;
        }
    }

    my @results;
    for my $did (sort {	$termhits{$b} <=> $termhits{$a} || $score{$b} <=> $score{$a} } keys %score) {
	my ($mtf, $path) = unpack($p.'a*', $FN->{$did});
	# XXX Should not use Tk::Pod::Search::split_path, or split_path should be moved to another package
	if ($restrict_pod) {
	    my($check_path) = Tk::Pod::Search::split_path($path);
	    next if $check_path !~ /^$restrict_pod/;
	}
	#next if ($restrict_pod && $path !~ /$restrict_pod/);
	$path = File::Spec->catfile($self->prefix, $path) unless $^O eq 'MSWin32'; # This seems to be a perlindex bug in MSWin32
	push @results, { termhits => $termhits{$did}, score => $score{$did}, path => $path };
	last unless --$maxhits;
    }

    #print "results|", join('|',@results),"\n";
    @results;
}

sub prefix {
    shift->{PREFIX};
}

1;
__END__

=head1 NAME

Tk::Pod::Search_db - dirty OO wrapper for C<perlindex>'s search functionality

=head1 SYNOPSIS

    ** THIS IS ALPHA SOFTWARE everything may and should change **
    **   stuff here is more a scratch pad than docomentation!  **

    use Tk::Pod::Search_db;
    ...
    $idx = Tk::Pod::Search_db->new?(INDEXDIR)?;
    ...
    @hits = $idx->searchWords(WORD1,...); # @hits is a list of
                                             # relpath1,score1,...  where
                                             # score is increasing
    $prefix = $idx->prefix();

    @word = Tk::Pod::Search_db::normalize(STRING1,...);

=head1 DESCRIPTION

Module to search Pod documentation.  Before you can use
the module one should create the indices with C<perlindex -index>.

=head1 MISSING

Enable options like -maxhits (currently = 15).  Solve PREFIX
dependency.  Interface for @stop and @unknown also as methods
return lists for last searchWords call?

Lots more ...

=head1 METHODS

=over 4

=item $idx = Tk::Pod::Search_db->new(INDEXDIR)

Interface may change to support options like -maxhits

=item $idx->seachWords(WORD1?,...?)

search for WORD(s). Return a list of

  relpath1, score1, relpath2, score2, ...

or empty list if no match is found.

=item $pathprefix = $idx->pathprefix()

The return path prefix and C<$relpath> give together the full path
name of the Pod documentation.

	$fullpath = $patchprefix . '/' . $relpath

B<Note:> Should make it easy to use Tk::Pod::Search with perlindex but
index specific prefix handling is a mess up to know.

=back

=head1 SEE ALSO

L<tkpod>, L<perlindex>, L<perlpod>, L<Tk::Pod::Search>

=head1 AUTHORS

Achim Bohnet  <F<ach@mpe.mpg.de>>

Most of the code here is borrowed from L<perlindex> written by
Ulrich Pfeifer <F<Ulrich.Pfeifer@de.uu.net>>.

Current maintainer is Slaven ReziE<0x0107> <F<slaven@rezic.de>>.

Copyright (c) 1997-1998 Achim Bohnet. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

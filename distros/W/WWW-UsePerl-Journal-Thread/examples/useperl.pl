#!/usr/bin/perl -w
use strict;
$|++;

my $VERSION = '0.15';

#----------------------------------------------------------------------------

=head1 NAME

useperl.pl - script to collect journal postings for a given user.

=head1 SYNOPSIS

  perl useperl.pl [--verbose] [--comments] [-y=<file>] [-h][-v] [-u=]<user>

=head1 DESCRIPTION

Given a user, set as either the last parameter, or with the command line option
-u, will retrieve all the journal postings made by that user on use.perl. In
addition the optional --comments flag includes any comments posted against that
journal entry.

If a --yaml file is given, the results are written to file in YAML format. If
the --verbose flag is given, the text is printed to STDOUT.

=cut

# -------------------------------------
# Library Modules

use File::Basename;
use File::Path;
use File::Slurp;
use Getopt::ArgvFile default=>1;
use Getopt::Long;
use WWW::UsePerl::Journal;
use WWW::UsePerl::Journal::Thread;
use YAML;

# -------------------------------------
# Variables

my (%options,@entries);
my $first = 1;

# -------------------------------------
# Program

##### INITIALISE #####

init_options();

my $journal = WWW::UsePerl::Journal->new($options{user});
#$journal->debug(1);
my @ids = $journal->entryids(ascending => 1);
for my $id (@ids) {
    my $entry = $journal->entry($id);

    my @comments;

    if($options{comments}) {
        my $thread = WWW::UsePerl::Journal::Thread->new(j => $journal, entry => $id);
        my @cids = $thread->commentids();
        for my $cid (@cids) {
            my $ccontent = $thread->comment($cid)->content();
            next    unless($ccontent);
            $ccontent =~ s!\t! !g;

            my $comment = {
                user    => $thread->comment($cid)->user,
                date    => $thread->comment($cid)->date->epoch,
                subject => $thread->comment($cid)->subject,
                content => $ccontent
            };

            push @comments, $comment;
        }
    }

    # clean content string
    my $content = $entry->content;
    $content =~ s!\t! !g;

    # save for later
    my $post = {
        id       => $id,
        date     => $entry->date->epoch,
        subject  => $entry->subject,
        content  => $content,
    };

    $post->{comments} = \@comments  if(@comments);
    push @entries, $post    if($options{yaml});

    if($options{verbose}) {
        # print for now
        print  "\n---- POST ----\n\n" unless($first-- > 0);
        printf "Link: http://use.perl.org/~barbie/%d\n", $post->{id};
        printf "Date: %s\n",    $post->{date};
        printf "Subject: %s\n", $post->{subject};
        printf "\n%s\n",        ($post->{content}||'');
        for my $comment (@{$post->{comments}}) {
            print "\n#### COMMENT ####\n\n";
            printf "User: %s\n",    $comment->{user};
            printf "Date: %s\n",    $comment->{date};
            printf "Subject: %s\n", $comment->{subject};
            printf "\n%s\n",        ($comment->{content}||'');
        }
    }
}


# save hash as YAML
write_file($options{yaml}, Dump(\@entries)) if($options{yaml});

#print "LOG: ".$journal->log()."\n";

# -------------------------------------
# Functions

sub init_options {
    GetOptions( \%options,
        'verbose',
        'comments',
        'yaml|y=s',
        'user|u=s',
        'help|h',
        'version|V'
    );

    _help(1) if($options{help});
    _help(0) if($options{version});

    if(defined $options{yaml} && ! -f $options{yaml}) {
        mkpath(dirname($options{yaml}));
    }

    $options{user} ||= $ARGV[0];
    if(!$options{user}) {
    	print "No user specified\n\n";
	    _help(1);
    }

    unless($options{yaml} || $options{verbose}) {
    	print "No output specified\n\n";
	    _help(1);
    }
}

sub _help {
    my $full = shift;

    if($full) {
        print <<HERE;

Usage: $0 \\
         [--yaml=<file>] [--verbose] [--comments] \\
         [-h] [-V] [--user=]<user>]

  --yaml=<file>     YAML output file
  --verbose         print output to STDOUT
  --comments        include comments from postings
  --user=<user>     named user
  -h                this help screen
  -V                program version

HERE

    }

    print "$0 v$VERSION\n\n";
    exit(0);
}

__END__

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-UsePerl-Journal-Thread

=head1 SEE ALSO

L<WWW::UsePerl::Journal>

F<http://use.perl.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2015 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut


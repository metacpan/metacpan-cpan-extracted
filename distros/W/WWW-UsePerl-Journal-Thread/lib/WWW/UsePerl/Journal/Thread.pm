package WWW::UsePerl::Journal::Thread;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.16';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal::Thread - Handles the retrieval of UsePerl journal comment threads

=head1 SYNOPSIS

  use WWW::UsePerl::Journal;
  use WWW::UsePerl::Journal::Thread;

  my $journal = WWW::UsePerl::Journal->new('barbie');
  my @entries = $journal->entryids();

  my $thread = WWW::UsePerl::Journal::Thread->new(
        j       => $journal, 
        thread  => $entries[0]
  );

  my @comments = $thread->commentids();
  for my $id (@comments) {
    printf "\n----\n%s [%d %s %d] %s",
	  $thread->comment($id)->subject(),
	  $thread->comment($id)->score(),
	  $thread->comment($id)->user(),
	  $thread->comment($id)->uid(),
	  $thread->comment($id)->date(),
	  $thread->comment($id)->content();
  }

  my $threadid = $thread->thread();

=head1 DESCRIPTION

A collection of routines to handle the retrieval of threads from a
UsePerl (L<http://use.perl.org/>) journal entry.

Using WWW::UsePerl::Journal, journal entry ids can be obtain. Each entry id
can be used to obtain a comment thread. Each comment property is accessed
via a comment object from within the thread.

Note that as on late 2010 use.perl was decommissioned. A read-only version of
the site now exists on the perl.org servers, and a full database backup is
also available if you wish to host your own use.perl archive. 

A future edition of this distribution will allow a DBI interface to a local
database to retrieve journal entries.

=cut

# -------------------------------------
# Library Modules

use HTTP::Request::Common;
use LWP::UserAgent;
use Time::Piece;
use WWW::UsePerl::Journal::Comment;

# -------------------------------------
# Variables

use constant USEPERL => 'http://use.perl.org/use.perl.org';

my %months = (
	'January'   => 1,
	'February'  => 2,
	'March'     => 3,
	'April'     => 4,
	'May'       => 5,
	'June'      => 6,
	'July'      => 7,
	'August'    => 8,
	'September' => 9,
	'October'   => 10,
	'November'  => 11,
	'December'  => 12,
);

# -------------------------------------
# Public Interface

=head1 PUBLIC INTERFACE

=head2 The Constructor

=over 4

=item new

  use WWW::UsePerl::Journal;
  my $journal = WWW::UsePerl::Journal->new('barbie');

  use WWW::UsePerl::Journal::Thread;
  my $j = WWW::UsePerl::Journal::Thread->new(
            j       => $journal, 
            eid     => $entryid,
  );

Creates an thread instance for the specified journal entry. An entry ID 
returned from $journal->entryids() must use the entry => $entryid form to 
obtain the correct thread.

=back

=cut

sub new {
    my ($class,%opts) = @_;

    for(qw/j eid/) {
    	return	unless(exists $opts{$_});
    }

    die "No parent object"
	    unless $opts{j}->isa('WWW::UsePerl::Journal');

    my %atts = map {$_ => $opts{$_}} qw(j eid);
    my $self = bless \%atts, $class;

    return $self;
}

=head2 Methods

=over 4

=item thread()

Returns the current thread id.

=cut

sub thread {
    my $self = shift;
	$self->_commenthash	unless($self->{thread});
	return $self->{thread};
}

=item comment($commentid)

Returns a comment object of the given comment ID

=cut

sub comment {
    my $self = shift;
    my $cid  = shift;
	my %entries = $self->_commenthash;
    return $entries{$cid};
}

=item commentids()

Returns an ascending array of the comment IDs.

Can take an optional hash containing; {descending=>1} to return a descending
list of comment IDs, {ascending=>1} to return an ascending list or
{threaded=>1} to return a thread ordered list. 'ascending' being the default.

=back

=cut

sub commentids {
    my ($self,%hash) = @_;

	my ($key,$sorter) = ('_commentids_asc',\&_ascender);
   	   ($key,$sorter) = ('_commentids_dsc',\&_descender)	if(%hash && $hash{descending});
	   ($key,$sorter) = ('_commentids_thd',sub{-1})			if(%hash && $hash{threaded});

    $self->{$key} ||= do {
        my %entries = $self->_commenthash;
        my @ids = sort $sorter keys %entries;
        \@ids;
    };

    return @{$self->{$key}};
}

# -------------------------------------
# The Private Methods

# name: commenthash
# desc: Returns a hash of WWW::UsePerl::Journal::Comment objects

sub _commenthash {
    my $self = shift;

    return %{ $self->{_commenthash} }	if($self->{_commenthash});

	# URL depends upon which id we've been given, as thread and entry
	# are different, but both can still return the thread list, just in
	# different formats

    my $user = $self->{j}->user;
	my $url = USEPERL . "/_$user/journal/$self->{eid}.html";

	my $content;
    eval { $content = $self->{j}->{ua}->request(GET $url)->content; };
	return $self->{j}->error("could not create comment list") if($@ || !$content);

    if($self->{j}->debug) {
        $self->{j}->log('mess' => "#_commenthash: url=[$url]\n");
        $self->{j}->log('mess' => "#_commenthash: content=[$content]\n");
    }

	# main comment thread
	my %comments;
    my @cids = $content =~ m! <div\s+id="comment_top_(\d+)"  !sixg;
    if($self->{j}->debug) {
        $self->{j}->log('mess' => "#cids: @cids\n");
    }

    ($self->{thread}) = $content =~ m!sid=(\d+)!;

    for my $cid (@cids) {

        if($self->{j}->debug) {
            $self->{j}->log('mess' => "\n#_commenthash: cid=[$cid]\n");
        }

		next if($comments{$cid});

        my ($extract) = $content =~ m! (<ul\s+id="[^"]+"[^>]*>\s*<li\s+id="tree_$cid"\s+class="[^"]+">.*?<div\s+id="replyto_$cid"></div>) !six;
        if($self->{j}->debug) {
            $self->{j}->log('mess' => "\n#extract: [$extract]\n");
        }

		$comments{$cid} = WWW::UsePerl::Journal::Comment->new(
                j       => $self->{j},
                cid     => $cid,
                eid     => $self->{eid},
                extract => $extract
		);
	}

	%{ $self->{_commenthash} } = %comments;
	return %{ $self->{_commenthash} };
}

# sort methods

sub _ascender  { $a <=> $b }
sub _descender { $b <=> $a }

1;

__END__

=head1 SUPPORT

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: L<http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-UsePerl-Journal-Thread>

=head1 SEE ALSO

F<http://use.perl.org/use.perl.org>

L<WWW::UsePerl::Journal>,
L<WWW::UsePerl::Journal::Server>

=head1 AUTHOR

Barbie, E<lt>barbie@cpan.orgE<gt>
for Miss Barbell Productions L<http://www.missbarbell.co.uk>.

=head1 CREDITS

Russell Matbouli, for creating WWW::UsePerl::Journal in the first place
and giving me the idea to extend it further.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2015 Barbie for Miss Barbell Productions

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut

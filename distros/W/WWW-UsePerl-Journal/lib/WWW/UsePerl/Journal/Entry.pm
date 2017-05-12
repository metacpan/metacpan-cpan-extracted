package WWW::UsePerl::Journal::Entry;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.26';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal::Entry - use.perl.org journal entry

=head1 DESCRIPTION

Do not use directly. See L<WWW::UsePerl::Journal> for details of usage.

=cut

# -------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use HTTP::Cookies;
use HTTP::Request::Common;
use LWP::UserAgent;
use Time::Piece;
use Time::Seconds;

use WWW::UsePerl::Journal;

#----------------------------------------------------------------------------
# Accessors

=head2 The Accessors

The following accessor methods are available:

  date
  subject
  author
  uid
  content

All functions can be called to return the current value of the associated
object variable.

=cut

__PACKAGE__->mk_accessors($_) for qw(date subject author eid);

# -------------------------------------
# Constants & Variables

my $UP_URL = 'http://use.perl.org/use.perl.org';
use overload q{""}  => sub { $_[0]->stringify() };

my $UID = '
            <div \s+ class="title" \s+ id="user-info-title"> \s+
            <h4> \s+ (.*?) \s+ \((\d+)\) \s+ </h4> \s+ </div>
        ';

my %mons = (
	1  => 'January',
	2  => 'February',
	3  => 'March',
	4  => 'April',
	5  => 'May',
	6  => 'June',
	7  => 'July',
	8  => 'August',
	9  => 'September',
	10 => 'October',
	11 => 'November',
	12 => 'December',
);

# -------------------------------------
# The Public Interface

=head1 INTERFACE

=head2 Constructor

=over 4

=item * new

  use WWW::UsePerl::Journal::Entry;
  my $j = WWW::UsePerl::Journal::Entry->new(%hash);

Creates an instance for a specific entry. The hash must contain values for
the keys 'j' (journal object), 'author' (entry author) and 'eid' (entry id).

=back

=cut

sub new {
    my $class = shift;
    my %opts = (@_);

    for(qw/j author eid/) {
    	return	unless($opts{$_});
    }

    die "No parent object"
	    unless $opts{j}->isa('WWW::UsePerl::Journal');

#use Data::Dumper;
#print STDERR "\n#self->new: ".Dumper(\%opts);

    my $self = bless {%opts}, $class;
    return $self;
}

sub DESTROY {}

=head2 Methods

=over 4

=item * stringify

  use WWW::UsePerl::Journal::Entry;
  my $j = WWW::UsePerl::Journal::Entry->new(%hash);
  print "$j";

Returns the content of the journal entry when the object is directly referenced
in a string.

=cut

sub stringify {
    my $self = shift;
    $self->content();
}

=item * eid

Returns the entry id for the current journal entry.

=cut

sub eid {
    my $self = shift;
    return $self->{eid};
}

=item * content

Return the content of an journal entry.

=cut

sub content {
    my $self   = shift;
    $self->{content} ||= do { $self->_get_content };
}

=item * raw

For debugging purposes.

=back

=cut

sub raw {
    my $self   = shift;
    my $eid    = $self->{eid};
    my $author = $self->{author};
#print STDERR "\n#raw: URL=[". $UP_URL . "/_$author/journal/$eid.html]";
    return $self->{j}->{ua}->request(GET $UP_URL . "/_$author/journal/$eid.html")->content;
}

# -------------------------------------
# The Private Subs

# name:	_get_content
# args:	self .... the current object
# retv: content text
# desc: Given a uid and journal entry id, will retrieve a specific journal
#       entry and disassemble into component parts. returns the content text

sub _get_content {
    my $self   = shift;
    my $eid    = $self->{eid};
    my $author = $self->{author};
    my $content;

    eval {
        $content = $self->{j}->{ua}->request(GET $UP_URL . "/_$author/journal/$eid.html")->content;
    };

#print STDERR "\n#eval=[$@]\n";

    return $self->{j}->error("error getting entry") if($@);

#print STDERR "\n#e->_get_content: URL=[". $UP_URL . "/_$author/journal/$eid.html]";
#print STDERR "\n#content=[$content]\n";

    return $self->{j}->error("error getting entry") unless $content;
    return $self->{j}->error("error getting entry") if($content =~ m!<b>Error type:</b>\s+\d+!);

    return $self->{j}->error("$eid does not exist")
        if $content =~
        m#Sorry, there are no journal entries
        found for this user.</TD></TR></TABLE><P>#is;
    return $self->{j}->error("$eid does not exist")
        if $content =~ m!Sorry, the requested journal entries were not found.!is;

    ($author,$self->{uid}) = $content =~ m!$UID!six;
#print STDERR "\n#e->_get_content: UID=[". ($self->{uid}) ."]";

    ($self->{subject}) = $content =~ m!
        <div \s+ id="journalslashdot"> .*?
        <div \s+ class="title"> \s+
        <h3> \s* (.*?) \s* </h3>
        !six;

    # date/time fields
    my ($month, $day, $year, $hr, $mi, $amp) = $content =~ m!
        <div \s+ class="journaldate">\w+ \s+ (\w+) \s+ (\d+), \s+ (\d+)</div> .*?
        <div \s+ class="details">(\d+):(\d+) \s+ ([AP]M)</div>
        !six;

    unless($day) {
        (undef,$mi,$hr,$day,$month,$year) = localtime(time());
        $month = $mons{$month};
    }

    # just in case we can't get the time
    if($amp) {
        $hr += 12 if($hr >  12 && $amp eq 'PM');
        $hr = 0   if($hr == 12 && $amp eq 'AM');
    }

    # sometimes Time::Piece can't parse the date :(
    eval {
        $self->{date} = Time::Piece->strptime(
            "$month $day $year ${hr}:$mi",
            '%B %d %Y %H:%M'
        );
    };

    #$self->{date} += 4*ONE_HOUR; # correct TZ?

    $content =~ m! <div \s+ class="intro">\s*(.*?)\s*</div> !six;
    return $1;
}

1;

__END__

=head1 CAVEATS

Beware the stringification of WWW::UsePerl::Journal::Entry objects.
They're still objects, they just happen to look the same as before when
you're printing them. Use -E<gt>content instead.

The time on a journal entry is the localtime of the user that created the
journal entry. If you aren't in the same timezone, that time will be wrong.

=head1 SUPPORT

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: L<http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-UsePerl-Journal>

=head1 SEE ALSO

F<http://use.perl.org/use.perl.org>

L<WWW::UsePerl::Journal::Server>

=head1 AUTHOR

  Original author: Russell Matbouli
  <www-useperl-journal-spam@russell.matbouli.org>,
  <http://russell.matbouli.org/>

  Current maintainer: Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2004 Russell Matbouli.
  Copyright (C) 2005-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut

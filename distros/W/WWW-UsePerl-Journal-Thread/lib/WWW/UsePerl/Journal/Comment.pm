package WWW::UsePerl::Journal::Comment;

use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.16';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal::Comment - Handles the retrieval of UsePerl journal entry comments.

=head1 SYNOPSIS

  my $comment = WWW::UsePerl::Journal::Comment->new(
      # required
      j       => $journal,
      cid     => $commentid,
      eid     => $entryid,
      extract => $extract
  );

  $comment->subject();

  # called from WWW::UsePerl::Journal::Thread object
  $thread->comment( $cid )->content();

=head1 DESCRIPTION

A collection of routines to handle the retrieval of comments from a
UsePerl (L<http://use.perl.org/>) journal entry.

=cut

# -------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use HTTP::Request::Common;
use LWP::UserAgent;
use Time::Piece;
use WWW::UsePerl::Journal;

# -------------------------------------
# Constants & Variables

use constant USEPERL => 'http://use.perl.org/use.perl.org';
use overload q{""}  => sub { $_[0]->stringify() };

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

Each comment is retrieved as an object. Note that the parent object
(from WWW::UsePerl::Journal), thread id and comment id are mandatory
requirements to create the object.

=back

=cut

sub new {
    my ($class,%opts) = @_;

    for(qw/j eid cid extract/) {
    	return	unless(exists $opts{$_});
    }

    die "No parent object"
	    unless $opts{j}->isa('WWW::UsePerl::Journal');

    my %atts = map {$_ => $opts{$_}} qw(j eid cid extract);
    my $self = bless \%atts, $class;

    $self->_get_content();

    return $self;
}

#----------------------------------------------------------------------------
# Accessors

=head2 The Accessors

The following accessor methods are available:

  id
  date
  subject
  user
  uid
  score
  content

All functions can be called to return the current value of the associated
object variable.

=cut

__PACKAGE__->mk_accessors($_) for qw(cid date subject user uid score content);

=head2 Methods

=over 4

=item stringify - For String Context

When an object is called directly, stringification occurs. Safer to
use -E<gt>content instead.

=back

=cut

sub stringify {
    my $self = shift;
    return $self->content();
}

# -------------------------------------
# The Private Subs

# name:	_get_content
# args:	self .... object itself
# retv: content text
# desc: Retrieves the content and additional information for a given
#       comment. Splits the fields into object variables and returns
#       the content text

sub _get_content {
    my $self    = shift;

    my $content = $self->{extract};

    if($self->{j}->debug) {
        $self->{j}->log('mess' => "\n#_get_content: content=[$content]\n");
    }

    return $self->{j}->error("Error getting entry") unless $content;

    # remember there are different presentations for dates!!!!

	my ($string,$format);
	$content =~ s/\n//g;
	my @fields = ( $content =~ m!
            <li\s+id="tree_(\d+)"\s+class="comment[^"]*">   # comment id
    .*?     <h4><a[^>]+>([^<]+)</a>                         # subject
    .*?     <span\s+id="comment_score_\1"\s+class="score">
    .*?     Score:(\d+).*?</h4>                             # score
	.*?		<a\s+href="[./\w]+/index.html">\s*(\w+)         # username
	.*?		\((\d+)\)</a>						            # userid
            (?:\s+<span\s+class="otherdetails"
	.*?		    on\s+(\d+\.\d+.\d+\s\d+:\d+)  		        # date/time - "2003.05.20 17:31" or "Friday August 08 2003, @01:51PM"
    .*?     </span>)?
    .*?     <div\s+id="comment_body_\1">(.*?)</div>         # text
        !mixs );

    ($self->{pid}) = $content =~ m/id="commtree_(\d+)"/;
    
    if($self->{j}->debug) {
        $self->{j}->log('mess' => "\n#_get_content: fields=[".(join("][",map {$_||''} @fields))."]\n");
    }

    return  unless(@fields);

    if($fields[5]) {
        my ($year, $month, $day, $hr, $mi) = $fields[5] =~ m! (\d+)\.(\d+)\.(\d+) .*? (\d+):(\d+) !smx;
        unless($day) {
            my $amp;
            ($month, $day, $year, $hr, $mi, $amp) = $fields[5] =~ m! \w+\s+ (\w+) \s+(\d+)\s*(\d*), \s+ @(\d+):(\d+)([AP]M) !smx;
            $month = $months{$month};
            $year = (localtime)[5]  unless($year);	# current year formatting drops the year.
            $hr += 12 if ($amp eq 'PM');
            $hr = 0 if $hr == 24;
        }

        if($self->{j}->debug) {
            $self->{j}->log('mess' => "\n#_get_content: date=[$year $month $day ${hr}:$mi]\n");
        }

        # sometimes Time::Piece can't parse the date :(
        eval {
            $self->{date} = Time::Piece->strptime(
                "$month $day $year ${hr}:$mi",
                '%m %d %Y %H:%M'
            );
        };

        if($self->{j}->debug) {
            $self->{j}->log('mess' => "\n#_get_content: date=[".$self->{date}."]\n");
        }
    }

	$self->{subject}	= $fields[1];
	$self->{score}		= $fields[2];
	$self->{user}		= $fields[3];
	$self->{uid}		= $fields[4];
	$self->{content}	= $fields[6];

	return  unless($self->{content});				# What no content!

	$self->{content} =~ s!(\s+<(?:p|br /)>)*$!!gi;	# remove trailing whitespace formatting
	$self->{content} =~ s!\s+(<(p|br /)>)!$1!gi;	# remove whitespace before whitespace formatting
	$self->{content} =~ s!(<(p|br /)>){2,}!<p>!gi;	# remove repeated whitespace formatting

    return;
}

sub DESTROY {}

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

=head1 CREDITS

Russell Matbouli, for creating L<WWW::UsePerl::Journal> in the first place
and giving me the idea to extend it further.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut

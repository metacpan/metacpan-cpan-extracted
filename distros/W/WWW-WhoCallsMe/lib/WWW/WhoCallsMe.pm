package WWW::WhoCallsMe;

use strict;
use warnings;
use LWP::UserAgent;

our $VERSION = '0.02';

=head1 NAME

WWW::WhoCallsMe - Query WhoCallsMe.com for details about a caller's phone number

=head1 SYNOPSIS

  use WWW::WhoCallsMe;
  my $who = WWW::WhoCallsMe->new;

  my $number = '6305053008';
  my $calledme = $who->fetch($number);
  if ($calledme->{listed})
  {
    my $name = $calledme->{name};
    print "The number $number is listed.  ";
    print "It seems that $name was calling." if $name;
    print "I don't know who was calling, though." unless $name;
    print "\n";
  }
  else
  {
    print "This number is not listed.\n";
  }

=head1 DESCRIPTION

WhoCallsMe.com is a website that compiles reports from users about
companies that call people.  These callers might be telemarketers,
bill collectors, legit companies, or otherwise.  These reports are
filed by the person that received the call.  In some cases, the
report includes the name of the company that called.  This module
attempts to grab this information and report it back to your program.

You supply the phone number and it tells you if the number is listed,
what names have been reported for this number, and a guess at the
company name of the caller.

=head2 new

  my $who = WWW::WhoCallsMe->new;

Accepts no parameters.

Returns a new WWW::WhoCallsMe object for your enjoyment.

=cut

sub new
{
  my $class = shift;
  my $self = shift;

  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->agent("WWW::WhoCallsMe/$VERSION");

  return bless($self, $class);
}

=head2 fetch

  my $hashref = $who->fetch($number);

Accepts one I<required> argument: the phone number.

Returns a hashref containing this information:

=over

=item *

number - scalar: the number that was queried

=item *

success - scalar: whether or not the HTTP query succeeded

=item *

listed - scalar: determines if the number is listed

=item *

name - scalar: the guessed name of the caller (based on frequency of occurrences in the callername array)

=item *

callername - array: list of reported caller names (the "Caller:" field)

=item *

callerid - array: list of reported caller id values (the "Caller ID:" field)

=back

=cut

sub fetch
{
  my $self = shift;
  my $number = shift;
  $number =~ s/[^0-9]//g;

  my $req = HTTP::Request->new(GET => 'http://whocallsme.com/Phone-Number.aspx/'.$number);
  my $res = $self->{ua}->request($req);

  my $return = {
    number => $number,
  };

  my $content = $res->content;
  $return->{success} = ($res->is_success ? 1 : 0);
  $return->{listed} = (($content =~ m#\s+phone\s+number\s+comments:</h4>#i) ? 1 : 0); # no comments means no listing
  @{$return->{callername}} = $content =~ m#<div>Caller:\s*(.*?)\s*</div>#ig;
  @{$return->{callerid}} = $content =~ m#<div>Caller\s+ID:\s*(.*?)\s*</div>#ig;

  my $callernames = {};
  my $maxcallercount = 0;
  my $maxcallername = 'unknown';
  foreach my $callername (@{$return->{callername}})
  {
    $callername =~ s/[\?\'\s]+/ /g;
    $callername =~ s/^\s+//;
    $callername =~ s/\s+$//;
    next unless $callername;

    $callernames->{uc($callername)}++;
    if ($callernames->{uc($callername)} > $maxcallercount)
    {
      $maxcallercount = $callernames->{uc($callername)};
      $maxcallername = uc($callername);
    }
  }

  $return->{name} = $maxcallername;

  return $return;
}

=head1 DEPENDENCIES

L<LWP>

=head1 SEE ALSO

L<http://www.whocallsme.com/>

=head1 TODO

I have no plans to expand this module, but I welcome any wishlist
requests.  If you can think of something reasonable to add to this
module, I'll consider doing it.  I also accept patches from others.

=head1 BUGS

Report all bugs through CPAN's bug reporting tool.  Feel free to
file wishlist requests there as well.

=head1 COPYRIGHT / LICENSE

All data that is provided by this module is provided by
WhoCallsMe.com.  They probably own the copyright to all of the data.
Their site doesn't appear to specify any kind of copyright or licensing
information.  Be reasonable with it.  I'll leave it up to you to
interpret what they think is okay for you to do with their data.

The (short amount of) code in this module is (C) Dusty Wilson, but
no real rights are reserved.  Feel free to use it as you see fit,
as long as it doesn't get me in trouble.  ;-)

=cut

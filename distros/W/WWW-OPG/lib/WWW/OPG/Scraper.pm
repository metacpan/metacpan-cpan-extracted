# WWW::OPG::Scraper
#  Perl interface to Ontario Power Generation's site
#
# $Id: Scraper.pm 10925 2010-01-10 20:27:32Z FREQUENCY@cpan.org $

package WWW::OPG::Scraper;

use strict;
use warnings;
use Carp ();

use LWP::UserAgent;
use DateTime;

=head1 NAME

WWW::OPG::Scraper - Drop-in module using web page scraping

=head1 VERSION

Version 1.004 ($Id: Scraper.pm 10925 2010-01-10 20:27:32Z FREQUENCY@cpan.org $)

=cut

our $VERSION = '1.004';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use WWW::OPG::Scraper;

  my $opg = WWW::OPG::Scraper->new();
  eval {
    $opg->poll();
  };
  print "Currently generating ", $opg->power, "MW of electricity\n";

=head1 DESCRIPTION

This module was formerly the main interface provided in L<WWW::OPG>. It
provides a Perl interface to information published on Ontario Power
Generation's web site at L<http://www.opg.com> by scraping the main page.

=head1 METHODS

=head2 new

  WWW::OPG::Scraper->new( \%params )

Implements the interface as specified in C<WWW::OPG>

=cut

sub new {
  my ($class, $params) = @_;

  Carp::croak('You must call this as a class method') if ref($class);

  my $self = {
  };

  if (exists $params->{useragent}) {
    $self->{useragent} = $params->{useragent};
  }
  else {
    my $ua = LWP::UserAgent->new;
    $ua->agent(__PACKAGE__ . '/' . $VERSION . ' ' . $ua->_agent);
    $self->{useragent} = $ua;
  }

  bless($self, $class);
  return $self;
}

=head2 poll

  $opg->poll()

Implements the interface as specified in C<WWW::OPG>

=cut

sub poll {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  my $ua = $self->{useragent};
  my $r = $ua->get('http://www.opg.com/');

  Carp::croak('Error reading response: ' . $r->status_line)
    unless $r->is_success;

  if ($r->content =~ m{
      ([0-9]+),?([0-9]+)</span><span\ class='wht'>\ MW</span>
    }x)
  {
    $self->{power} = $1 . $2;

    if ($r->content =~ m{
        Last\ updated:\ (\d+)/(\d+)/(\d+)\ (\d+):(\d+):(\d+)\ (AM|PM)  
      }x)
    {
      my $hour = $4;
      # 12:00 noon and midnight are a special case
      if ($hour == 12) {
        # 12am is midnight
        if ($7 eq 'AM') {
          $hour = 0;
        }
      }
      elsif ($7 eq 'PM') {
        $hour += 12;
      }

      my $dt = DateTime->new(
        month     => $1,
        day       => $2,
        year      => $3,
        hour      => $hour, # derived from $4
        minute    => $5,
        second    => $6,
        time_zone => 'America/Toronto',
      );

      if (!exists $self->{updated} || $self->{updated} != $dt)
      {
        $self->{updated} = $dt;
        return 1;
      }
      return 0;
    }
  }

  die 'Error parsing response, perhaps the format has changed?';
  return;
}

=head2 power

  $opg->power()

Implements the interface as specified in C<WWW::OPG>

=cut

sub power {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return unless exists $self->{power};
  return $self->{power};
}

=head2 last_updated

  $opg->last_updated()

Implements the interface as specified in C<WWW::OPG>

=cut

sub last_updated {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return unless exists $self->{updated};
  return $self->{updated};
}

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 SEE ALSO

L<WWW::OPG>

=head1 SUPPORT

Please file bugs for this module under the C<WWW::OPG> distribution. For
more information, see L<WWW::OPG>'s perldoc.

=head1 LICENSE

This has the same copyright and licensing terms as L<WWW::OPG>.

=head1 DISCLAIMER OF WARRANTY

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

=cut

1;

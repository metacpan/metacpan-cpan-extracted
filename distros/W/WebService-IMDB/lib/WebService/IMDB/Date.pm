# $Id: Date.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Date

=head1 DESCRIPTION

Constructor always returns a L<DateTime::Incomplete>.

=cut

package WebService::IMDB::Date;

use strict;
use warnings;

our $VERSION = '0.05';

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Trivium);

use DateTime::Format::Strptime;
use DateTime::Incomplete;


sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    if (ref $data eq "HASH" && exists $data->{'normal'} && defined $data->{'normal'}) {
	# TODO: Check whehter locale affects this.
	my $dt = $data->{'normal'};
	my ($y, $m, $d) = $dt =~ m/^(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?$/ or die "Failed to parse '$dt'";
	if (defined $y && defined $m && defined $d) {
	    return DateTime::Incomplete->new('year' => $y, 'month' => $m, 'day' => $d);
	} elsif (defined $y && defined $m) {
	    return DateTime::Incomplete->new('year' => $y, 'month' => $m);
	} elsif (defined $y) {
	    return DateTime::Incomplete->new('year' => $y);
	} else {
	    die "";
	}

    } elsif (ref $data eq "HASH" && exists $data->{'text'}) {

	if (!defined $data->{'text'}) { # A bit hacky, but not sure how else to deal with this.
	    return undef;
	} else {
	    # Some 'text' dates are actually parseable, e.g. those of the format "July 14, 2007".  Attempt to detect them
	    # and parse to a DateTime::Incomplete
	    my $d = DateTime::Format::Strptime->new('pattern' => "%B %d, %Y", 'on_error' => "undef")->parse_datetime($data->{'text'});
	    if (defined $d) {
		return DateTime::Incomplete->new('year' => $d->year(), 'month' => $d->month(), 'day' => $d->day());

	    } elsif ($data->{'text'} =~ m/^\d{1,2}\/\d{2}$/) {
		my ($m, $y) = $data->{'text'} =~ m/^(\d{1,2})\/(\d{2})$/ or die "Failed to parse '$data->{'text'}'";
		return DateTime::Incomplete->new('year' => $y, 'month' => $m);

	    } elsif ($data->{'text'} =~ m/^\d{1,2}\/\d{1,2}\/\d{2}$/) {
		my ($m, $d, $y) = $data->{'text'} =~ m/^(\d{1,2})\/(\d{1,2})\/(\d{2})$/ or die "Failed to parse '$data->{'text'}'";
		return DateTime::Incomplete->new('year' => $y, 'month' => $m, 'day' => $d);

	    } else {
		return $data->{'text'};
	    }
	}

    } elsif (ref $data eq "" && $data =~ m/^\d{4}-\d{2}-\d{2}$/) {
	my ($y, $m, $d) = $data =~ m/^(\d{4})-(\d{2})-(\d{2})$/ or die "Failed to parse '$data'";
	return DateTime::Incomplete->new('year' => $y, 'month' => $m, 'day' => $d);

    } else {
	croak "Unable to parse date";
    }
}

1;

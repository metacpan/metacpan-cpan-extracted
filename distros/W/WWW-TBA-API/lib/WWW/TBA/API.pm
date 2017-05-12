package WWW::TBA::API;

use Carp;

use Exporter;

use LWP::UserAgent;

use XML::Simple;

=head1 NAME

WWW::TBA::API - Perl module for handling thebluealliance.net's API

=head1 VERSION

Version 1.00

=cut

our $VERSION='1.00';
@ISA=qw/Exporter/;
@EXPORT=qw/VERSION/;

=head1 SYNOPSIS

$tba=new WWW::TBA::API($apikey);

=head1 DESCRIPTION

WWW::TBA::API implements version 1 of thebluealliance.net's API.  More
information is available here:
http://thebluealliance.net/tbatv/api/readme.php.

This implementation is deliberately similar to the other
implementations (esecially the one written in php), so that people
switching will not have trouble learning the new one.

=head1 FUNCTIONS

=over

=item new API_KEY [API_URL]

Creates an interface to the API.  If API_URL is specified, queries are
made to that URL.  With ordinary usage, it should never be specified
(the default, http://thebluealliance.net/tbatv/api.php, should not
change).

=cut

sub new {
    my $class=shift;
    my $self={};
    $self->{API_KEY}=shift;
    $self->{API_URL}=shift || "http://thebluealliance.net/tbatv/api.php";
    $self->{API_VERSION}=1;
    my $ua=new LWP::UserAgent;
    $ua->agent("TBA API Client");
    $self->{USER_AGENT}=$ua;
    bless $self,$class;
    return $self;
}

=item makearray

Not implemented.  In other implementations, makes an array out of an
XML::Simple object.  This should not be necessary, or even remotely
desirable, in Perl.

=item ->user_agent [LWP::UserAgent]

Returns the old user agent, and changes if necessary.

=cut

sub user_agent {
    my $self=shift;
    my $old=$self->{USER_AGENT};
    $self->{USER_AGENT}=shift || $self->{USER_AGENT};
    return $old;
}

=item ->api_key [API_KEY]

Returns the old api key, and changes if necessary.

=cut

sub api_key {
    my $self=shift;
    my $old=$self->{API_KEY};
    $self->{API_KEY}=shift || $self->{API_KEY};
    return $old;
}

=item ->api_url [API_URL]

Returns the old api url, and changes if necessary.

=cut

sub api_url {
    my $self=shift;
    my $old=$self->{API_URL};
    $self->{API_URL}=shift || $self->{API_URL};
    return $old;
}

=item ->api_version

Returns the version of the API being used.  This value cannot be
changed, for obvious reasons.

=cut

sub api_version {
    my $self=shift;
    return $self->{API_VERSION};
}

#a secret, undocumented method. mwahahaha
sub urlencode {
    my $str=shift;
    $str=~s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $str;
}

=item ->query METHOD ARGUMENTS

The low-level API call.  Makes a query to TBA of METHOD with
ARGUMENTS.  ARGUMENTS must be a reference to a hash.

=cut

sub query {
    my ($self,$method,$arguments)=@_;
    my $api_key=$self->{API_KEY};
    my $api_url=$self->{API_URL};
    my $api_version=$self->{API_VERSION};
    my $ua=$self->user_agent;

    my $argument_string = "version=$version&api_key=$api_key&method=$method";
    foreach my $key (keys %$arguments) {
	my $value=$arguments->{$key};
	$argument_string.="&$key=".urlencode($value);
    }
    my $url=$api_url."?".$argument_string;
    my $xmlstr=$ua->get($url)->content;

    my $xml=XMLin($xmlstr);
    return $xml;
}

=item ->raw_query METHOD ARGUMENTS

Same as query, but returns a string instead of an XML::Simple object.
Generally for debugging purposes only.

=cut

sub raw_query {
    my ($self,$method,$arguments)=@_;
    my $api_key=$self->{API_KEY};
    my $api_url=$self->{API_URL};
    my $api_version=$self->{API_VERSION};
    my $ua=$self->user_agent;

    my $argument_string = "version=$version&api_key=$api_key&method=$method";
    foreach my $key (keys %$arguments) {
	my $value=$arguments->{$key};
	$argument_string.="&$key=".urlencode($value);
    }
    my $url=$api_url."?".$argument_string;
    return $ua->get($url)->content;
}

=item ->get_teams [STATE [TEAMNUMBER]]

Gets inormation on the specified teams.

=cut

sub get_teams {
    my $self=shift;
    my $state=shift || '';
    my $teamnumber=shift || '';
    return $self->query("get_teams",{
	"teamnumber"=>$teamnumber,
	"state"=>$state
		 });
}

=item ->get_events [YEAR [WEEK [EVENTID]]]

Gets information on the specified events.

=cut

sub get_events {
    my $self=shift;
    my $year=shift || '';
    my $week=shift || '';
    my $eventid=shift || '';
    return $self->query("get_events",{
	year=>$year,week=>$week,eventid=>$eventid
			});
}

=item ->get_matches [COMPLEVEL [EVENTID [TEAMNUMBER [MATCHID]]]]

Returns information on the specified matches.  

=cut

sub get_matches {
    my $self=shift;
    my $complevel=shift || '';
    my $eventid=shift || '';
    my $teamnumber=shift || '';
    my $matchid=shift || '';
    return $self->query("get_matches",{
	complevel=>$complevel,
	eventid=>$eventid,
	teamnumber=>$teamnumber,
	matchid=>$matchid
			});
}

=item ->get_attendance [EVENTID [TEAMNUMBER]]

Returns the attendance list for the specified event.

=cut

sub get_attendance {
    my $self=shift;
    my $eventid=shift || '';
    my $teamnumber=shift || '';
    return $self->query("get_attendance",{
	eventid=>$eventid,
	teamnumber=>$teamnumber
			});
}

=item ->get_official_record [TEAMNUMBER [YEAR [EVENTID]]]

Returns the official record of the team.

=cut

sub get_official_record {
    my $self=shift;
    my $eventid=shift || '';
    my $teamnumber=shift || '';
    return $self->query("get_official_record",{
	eventid=>$eventid,teamnumber=>$teamnumber
			});
}

=item ->get_elim_sets EVENTID NOUN

Undocumented.

=cut

sub get_elim_sets {
    my $self=shift;
    my $eventid=shift;
    my $noun=shift;
    return $self->query("get_elim_sets",{
	eventid=>$eventid,noun=>$noun
			});
    
}

sub throw_error {
    carp 'error thrown';
}

1;

__END__

=back

=head1 BUGS AND LIMITATIONS

The error handling for this module is currently less than spify.  Any
errors in fetching or parsing XML will cause undefined behaviour.

Please report any bugs or feature requests to C<bug-www-tba-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-TBA-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Scott Lawrence (bytbox@gmail.com)

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Scott Lawrence, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

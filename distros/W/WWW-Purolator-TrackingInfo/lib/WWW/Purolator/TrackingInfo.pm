package WWW::Purolator::TrackingInfo;

use warnings;
use strict;

our $VERSION = '1.0105';
use 5.006;
use LWP::UserAgent;
use JSON::PP qw//;
use base 'Class::Accessor::Grouped';
__PACKAGE__->mk_group_accessors( simple => qw/
    error
    _ua
/);

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless {}, $class;

    $self->_ua(
        LWP::UserAgent->new(
            agent => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:26.0) '
                . 'Gecko/20100101 Firefox/26.0', timeout => 30 ),
    );

    return $self;
}

sub track {
    my ( $self, $pin ) = @_;

    $self->error(undef);

    my $res = $self->_ua->get(
        'http://www.purolator.com/en/ship-track/tracking-details.page?pin='
            . $pin,
    );

    $res->is_success
        or return $self->_set_error('Network error: ' . $res->status_line);

    return $self->_parse( $pin, $res->decoded_content );
}

sub _parse {
    my ( $self, $pin, $content ) = @_;

    my %info = ( pin => $pin );

    $content =~ /Our online tracking system is currently unavailable/
        and return $self->_set_error(
            'Tracking system is currently unavailable'
        );

    my ( $z ) = $content =~ m{var jsHistoryTable = (\[.+?\]);}s;

    my $history_table = eval {
        JSON::PP->new->allow_singlequote->decode( $z );
    };
    $@
    and return $self->_set_error(
            'Error parsing Purolator\'s data: ' . $@
            . '. Perhaps you supplied an invalid PIN/tracking number?'
        );

    for ( @$history_table ) {
        my %data;
        @data{qw/scan_date  scan_time  location  comment/} = @$_;
        $_ =  \%data;
    }

    $info{history} = $history_table;


    my ( $status_code ) = $content =~ m{
        var \s+ detailsData \s+ =
        \s+
        \{
            \s+ "trackingNumber" .+?
            "status": \s+ '([^']+)'
        }six;

    my %possible_statuses = (
        InTransit       => 'in transit',
        Pickup          => 'package picked up',
        DataReceived    => 'shipping label created',
        Attention       => 'attention',
        Delivered       => 'delivered',
    );

    $info{status}
    = $possible_statuses{ $status_code } || 'unknown status code';

    return \%info;
}

sub _set_error {
    my ( $self, $error ) = @_;

    $self->error( $error );

    return;
}

q|
I'd like to make the world a better place,
but they won't give me the source code.
|;
__END__

=head1 NAME

WWW::Purolator::TrackingInfo - access Purolator's tracking information

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::Purolator::TrackingInfo;

    my $t = WWW::Purolator::TrackingInfo->new;

    my $info = $t->track('320698592781')
        or die "Error: " . $t->error;

    if ( $info->{status} eq 'delivered' ) {
        print "The package has been delivered! YEY!\n";
    }
    else {
        print "Package's latest update is: $info->{history}[0]{comment}\n";
    }

=head1 DESCRIPTION

The module accesses L<www.purolator.com|http://www.purolator.com>
and gets tracking information for the package, using the provided
PIN (tracking number, e.g. 320698592781).

=head1 CONSTRUCTOR

    my $t = WWW::Purolator::TrackingInfo->new;

Creates and returns a new C<WWW::Purolator::TrackingInfo> object.
Does not take any arguments.

=head1 METHODS/ACCESSORS

=head2 C<track>

    my $info = $t->track('320698592781')
        or die $t->error;

Instructs the object to obtain tracking information from Purolator using
a PIN. B<Takes> one mandatory argument: Purolator's PIN for
the package (or "tracking number"; years after dealing with Purolator,
I'm still unclear on their terminology).
B<On failure> returns C<undef> or an empty list, depending on the
context, and the reason for failure will be available
via C<< ->error >> method.
B<On success> returns a hashref with the following keys/values
(sample abridged data):

    {
        'status' => 'delivered'
        'pin' => '320698611680',
        'history' => [
            {
                'comment' => 'Shipping label created with reference(s): 2509543',
                'location' => 'Purolator',
                'scan_time' => '11:09:00',
                'scan_date' => '2014-01-16'
            }
        ],
    };

=head3 C<status>

    'in transit',
    'package picked up',
    'shipping label created',
    'attention',
    'delivered',

The C<status> value will be one of the above values, with a possible
additional one C<'unknown status code'>, though the unknown code
likely would mean this module is broken. The values are self-explanatory,
with exception of C<'attention'>, which means some unforseen event
has happened with the delivery and the package status requires attention.

=head3 C<pin>

    'pin' => '320698611680',

This is the PIN/tracking number that was used to call
C<< ->track >> with.

=head3 C<history>

    'history' => [
        {
            'comment' => 'Shipment delivered to MARY at: RECEPTION',
            'location' => 'Saskatoon, SK',
            'scan_time' => '10:44:00',
            'scan_date' => '2014-01-17'
        },
        {
            'comment' => 'On vehicle for delivery',
            'location' => 'Saskatoon, SK',
            'scan_time' => '09:57:00',
            'scan_date' => '2014-01-17'
        },
        {
            'comment' => 'Arrived at sort facility',
            'location' => 'Saskatoon, SK',
            'scan_time' => '06:57:00',
            'scan_date' => '2014-01-17'
        },
        {
            'comment' => 'Picked up by Purolator at  CALGARY AB ',
            'location' => 'Calgary, AB',
            'scan_time' => '15:23:00',
            'scan_date' => '2014-01-16'
        },
        {
            'comment' => 'Shipping label created with reference(s): 2509543',
            'location' => 'Purolator',
            'scan_time' => '11:09:00',
            'scan_date' => '2014-01-16'
        }
    ];

The value is an arrayref of hashrefs. Each hashref specifies a line
in package's tracking history, most recent first. Each
hashref contains four keys:

=head3 C<scan_date>

    'scan_date' => '2014-01-17'

The date of this particular update.

=head3 C<scan_time>

    'scan_time' => '15:23:00',

The time of this particular update.

=head3 C<location>

    'location' => 'Calgary, AB',

Location of where the update happened.

=head3 C<comment>

    'comment' => 'Shipping label created with reference(s): 2509543',

The comment/description of the update.

=head2 C<error>

    $t->track('320698592781')
        or die $t->error;

Takes no arguments. Returns a human readable reason for why
C<< ->track >> method failed.

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://haslayout.net/>, L<http://zoffix.com/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-purolator-trackinginfo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Purolator-TrackingInfo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Purolator::TrackingInfo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker
 LWP::UserAgent->new( agent => 'Opera 9.5', timeout => 30 )
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Purolator-TrackingInfo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Purolator-TrackingInfo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Purolator-TrackingInfo>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Purolator-TrackingInfo/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


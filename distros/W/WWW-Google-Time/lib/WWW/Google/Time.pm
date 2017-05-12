package WWW::Google::Time;

use warnings;
use strict;

our $VERSION = '1.001005'; # VERSION

use LWP::UserAgent;
use URI;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors( simple => qw/
    error
    data
    where
    ua
/);

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {}, $class;
    $self->ua( $args{ua} || LWP::UserAgent->new( agent => "Mozilla", timeout => 30, ) );

    return $self;
}

sub get_time {
    my ( $self, $where ) = @_;
    my $uri = URI->new("http://google.com/search");

    $self->$_(undef)
        for qw/error data/;

    $self->where( $where );

    $uri->query_form(
        num     => 100,
        hl      => 'en',
        safe    => 'off',
        btnG    => 'Search',
        meta    => '',
        'q'     => "time in $where",
    );
    my $response = $self->ua->get($uri);
    unless ( $response->is_success ) {
        return $self->_set_error( $response, 'net' );
    }

# open my $fh, '>', 'out.txt' or die;
# print $fh $response->decoded_content.'\n';
# close $fh;

    my %data;
    # print $response->content;
    @data{ qw/time day_of_week month month_day year time_zone where/ } = $response->content
    =~ m{<div class="_rkc _Peb">(.+?)</div><div class="_HOb _Qeb"> (\w+), <span style="white-space:nowrap">(\w+) (\d+), (\d+)</span> \((.+?)\) </div><span class="_HOb _Qeb">\s+Time in (.+?) </span>}
         # <div class="_rkc _Peb">12:23 PM</div><div class="_HOb _Qeb"> Wednesday, <span style="white-space:nowrap">December 31, 2014</span> (EST) </div><span class="_HOb _Qeb">  Time in Toronto, ON </span></div></div>
    or do {
        return $self->_set_error("Could not find time data for that location");
    };


# <td style="font-size:medium">&#8206;<b>2:29pm</b> Sunday (EST) - <b>Time</b> in <b>Toronto, ON, Canada</b></td>


    $data{where} =~ s{</?em>|</?b>}{}g;

    return $self->data( \%data );
}

sub _set_error {
    my ( $self, $error_or_response, $is_response ) = @_;

    if ( $is_response ) {
        $self->error( "Network error: " . $error_or_response->status_line );
    }
    else {
        $self->error( $error_or_response );
    }
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::Google::Time - get time for various locations via Google

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::Google::Time;

    my $t = WWW::Google::Time->new;

    $t->get_time("Toronto")
        or die $t->error;

    printf "It is %s, %s (%s) %s %s, %s in %s\n",
        @{ $t->data }{qw/
            day_of_week  time  time_zone  month  month_day  year  where
        /};

=head1 DESCRIPTION

Module is very simple, it takes a name of some place and returns the current time in that place
(as long as Google has that information).

=head1 CONSTRUCTOR

=head2 C<new>

    my $t = WWW::Google::Time->new;

    my $t = WWW::Google::Time->new(
        ua => LWP::UserAgent->new( agent => "Mozilla", timeout => 30 )
    );

Creates and returns a new C<WWW::Google::Time> object. So far takes one key/value pair argument
- C<ua>. The value of the C<ua> argument must be an object akin to L<LWP::UserAgent> which
has a C<get()> method that returns an L<HTTP::Response> object. The default object for the
C<ua> argument is C<< LWP::UserAgent->new( agent => "Mozilla", timeout => 30 ) >>

=head1 METHODS

=head2 C<get_time>

    $t->get_time('Toronto')
        or die $t->error;

Instructs the object to fetch time information for the given location. Takes one mandatory
argument which is a name of the place for which you want to obtain time data. On failure
returns either undef or an empty list, depending on the context, and the reason for
failure can be obtained via C<error()> method. On success returns a hashref with
the following keys/values:

    $VAR1 = {
          'time' => '7:00 AM',
          'time_zone' => 'EDT',
          'day_of_week' => 'Saturday',
          'month' => 'August',
          'month_day' => '30',
          'year' => '2014',
          'where' => 'Toronto, ON, Canada'
    };

=head3 C<time>

    'time' => '7:00 AM',

The C<time> key contains the time for the location as a string.

=head3 C<time_zone>

    'time_zone' => 'EDT',

The C<time_zone> key contains the time zone in which the given location is.

=head3 C<day_of_week>

    'day_of_week' => 'Saturday',

The C<day_of_week> key contains the day of the week that is right now in the location given.

=head3 C<month>

    'month' => 'August',

The C<month> key contains the current month at the location.

=head3 C<month_day>

    'month_day' => '30',

The C<month_day> key contains the date of the month at the location.

=head3 C<year>

    'year' => '2014',

The C<year> key contains the year at the location.

=head3 C<where>

    'where' => 'Toronto, ON, Canada'

The C<where> key contains the name of the location to which the keys described above correlate.
This is basically how Google interpreted the argument you gave to C<get_time()> method.

=head2 C<data>

    $t->get_time('Toronto')
        or die $t->error;

    my $time_data = $t->data;

Must be called after a successful call to C<get_time()>. Takes no arguments.
Returns the exact same hashref the last call to C<get_time()> returned.

=head2 C<where>

    $t->get_time('Toronto')
        or die $t->error;

    print $t->where; # prints 'Toronto'

Takes no arguments. Returns the argument passed to the last call to C<get_time()>.

=head2 C<error>

    $t->get_time("Some place that doesn't exist")
        or die $t->error;
    ### dies with "Could not find time data for that location"

When C<get_time()> fails (by returning either undef or empty list) the reason for failure
will be available via C<error()> method. The "failure" is both, not being able to find time
data for the given location or network errors. The error message will say which one it is.

=head2 C<ua>

    my $ua = $t->ua;
    $ua->proxy('http', 'http://foobarbaz.com');

    $t->ua( LWP::UserAgent->new( agent => 'Mozilla' ) );

Takes one optional argument which must fit the same criteria as the C<ua> argument to the
constructor (C<new()> method). Returns the object currently being used for accessing Google.

=head1 EXAMPLES

The C<examples/> directory of this distribution contains an executable script that uses this
module.

=head1 TO DO

Sometimes Google returns multiple times.. e.g. "time in Norway" returns three results.
Would be nice to be able to return all three results in an arrayref or something

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/WWW-Google-Time>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/WWW-Google-Time/issues>

If you can't access GitHub, you can email your request
to C<bug-WWW-Google-Time at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 CONTRIBUTORS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Patches by Neil Stott and Zach Hauri (L<http://zach.livejournal.com/>)

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
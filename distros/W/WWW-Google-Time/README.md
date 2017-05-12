# NAME

WWW::Google::Time - get time for various locations via Google

# SYNOPSIS

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

# DESCRIPTION

Module is very simple, it takes a name of some place and returns the current time in that place
(as long as Google has that information).

# CONSTRUCTOR

## `new`

    my $t = WWW::Google::Time->new;

    my $t = WWW::Google::Time->new(
        ua => LWP::UserAgent->new( agent => "Mozilla", timeout => 30 )
    );

Creates and returns a new `WWW::Google::Time` object. So far takes one key/value pair argument
\- `ua`. The value of the `ua` argument must be an object akin to [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) which
has a `get()` method that returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object. The default object for the
`ua` argument is `LWP::UserAgent->new( agent => "Mozilla", timeout => 30 )`

# METHODS

## `get_time`

    $t->get_time('Toronto')
        or die $t->error;

Instructs the object to fetch time information for the given location. Takes one mandatory
argument which is a name of the place for which you want to obtain time data. On failure
returns either undef or an empty list, depending on the context, and the reason for
failure can be obtained via `error()` method. On success returns a hashref with
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

### `time`

    'time' => '7:00 AM',

The `time` key contains the time for the location as a string.

### `time_zone`

    'time_zone' => 'EDT',

The `time_zone` key contains the time zone in which the given location is.

### `day_of_week`

    'day_of_week' => 'Saturday',

The `day_of_week` key contains the day of the week that is right now in the location given.

### `month`

    'month' => 'August',

The `month` key contains the current month at the location.

### `month_day`

    'month_day' => '30',

The `month_day` key contains the date of the month at the location.

### `year`

    'year' => '2014',

The `year` key contains the year at the location.

### `where`

    'where' => 'Toronto, ON, Canada'

The `where` key contains the name of the location to which the keys described above correlate.
This is basically how Google interpreted the argument you gave to `get_time()` method.

## `data`

    $t->get_time('Toronto')
        or die $t->error;

    my $time_data = $t->data;

Must be called after a successful call to `get_time()`. Takes no arguments.
Returns the exact same hashref the last call to `get_time()` returned.

## `where`

    $t->get_time('Toronto')
        or die $t->error;

    print $t->where; # prints 'Toronto'

Takes no arguments. Returns the argument passed to the last call to `get_time()`.

## `error`

    $t->get_time("Some place that doesn't exist")
        or die $t->error;
    ### dies with "Could not find time data for that location"

When `get_time()` fails (by returning either undef or empty list) the reason for failure
will be available via `error()` method. The "failure" is both, not being able to find time
data for the given location or network errors. The error message will say which one it is.

## `ua`

    my $ua = $t->ua;
    $ua->proxy('http', 'http://foobarbaz.com');

    $t->ua( LWP::UserAgent->new( agent => 'Mozilla' ) );

Takes one optional argument which must fit the same criteria as the `ua` argument to the
constructor (`new()` method). Returns the object currently being used for accessing Google.

# EXAMPLES

The `examples/` directory of this distribution contains an executable script that uses this
module.

# TO DO

Sometimes Google returns multiple times.. e.g. "time in Norway" returns three results.
Would be nice to be able to return all three results in an arrayref or something

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-Google-Time](https://github.com/zoffixznet/WWW-Google-Time)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-Google-Time/issues](https://github.com/zoffixznet/WWW-Google-Time/issues)

If you can't access GitHub, you can email your request
to `bug-WWW-Google-Time at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# CONTRIBUTORS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Patches by Neil Stott and Zach Hauri ([http://zach.livejournal.com/](http://zach.livejournal.com/))

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.

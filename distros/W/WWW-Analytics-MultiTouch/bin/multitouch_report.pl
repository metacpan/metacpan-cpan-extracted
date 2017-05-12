#! /usr/bin/perl

use strict;
use warnings;

use WWW::Analytics::MultiTouch;
use Getopt::Long;
use Pod::Usage;

my $opts = {
    class_name => 'WWW::Analytics::MultiTouch',
};

GetOptions($opts,
           'auth_file=s',
	   'id=s',
	   'event_category=s',
	   'fieldsep=s',
	   'recsep=s',
	   'patsep=s',
	   'debug',
	   'start_date=s',
	   'end_date=s',
	   'window_length=i',
	   'single_order_model',
	   'channel_pattern=s',
	   'filename=s',
	   'all_touches_report!',
	   'even_touches_report!',
	   'distributed_touches_report!',
	   'first_touch_report!',
	   'last_touch_report!',
	   'fifty_fifty_report!',
	   'transactions_report!',
	   'touchlist_report!',
	   'transaction_distribution_report!',
	   'channel_overlap_report!',
	   'format=s',
	   'conf=s',
           'class_name=s',
	   'bugfix1', # swap src/medium for organic, no public releases affected
	   'help|?',
    ) or pod2usage(2);
pod2usage(1) if $opts->{help};

$opts = WWW::Analytics::MultiTouch->parse_config($opts, delete $opts->{conf});
if ($opts->{debug}) {
    require Data::Dumper;
    print Data::Dumper::Dumper($opts);
}
eval "require $opts->{class_name}";
die "Failed to load class $opts->{class_name}: $@" if $@;
$opts->{class_name}->process($opts);


__END__

=head1 NAME

multitouch_report.pl - MultiTouch Analytics Reporting

=head1 SYNOPSIS

multitouch_report --ID=ANALYTICSID --start_date=YYYYMMDD --end_date=YYYYMMDD --filename=FILENAME

=head1 DESCRIPTION

Runs MultiTouch Analytics reports; see L<http://www.multitouchanalytics.com/> for details.

=head1 GOOGLE ACCOUNT AUTHORISATION

In order to give permission for the multitouch reporting to access your data, you must follow the authorisation process.  On first use, a URL will be displayed.  You must click on this URL or cut and paste it into a browser, log in as the Google user that has access to the Google Analytics profile that you wish to analyse, grant permission, and paste the resulting authorisation code into the console.  After this, the authorisation tokens will be stored and there should be no need to repeat the process.

In case you need to change user or profile or re-authenticate, see the information on the L<--auth_file> option.

NOTE: In versions prior to 0.30, it was necessary to specify a the username and password for your Google account. B<This is no longer necessary>.

=head2 BASIC OPTIONS

=over 4

=item * --id=ANALYTICSID

This is the Google Analytics reporting ID.  This parameter is mandatory.  This is NOT the ID that you use in the javascript code!  You can find the reporting id in the URL when you log into the Google Analytics console; it is the number following the letter 'p' in the URL, e.g.

  https://www.google.com/analytics/web/#dashboard/default/a111111w222222p123456/

In this example, the ID is 123456.

=item * --start_date=YYYYMMDD, --end_date=YYYYMMDD

Start and end dates respectively.  The total interval includes both start and
end dates.  Date format is YYYY-MM-DD or YYYYMMDD.

=item * --filename=FILENAME

Name of file in which to save reports.  If not specified, output is sent to the
screen.  The filename extension, if given, is used to determine the file format,
which can be xls, csv or txt.

=item * --conf=FILENAME

Specifies the name of a configuration file, through which any command line
option can be specified, as well as many more advanced options.  See L<CONFIGURATION FILE>.

=item * --auth_file=FILENAME

This is the file in which authentication keys received from Google are kept for subsequent use.  The default filename is derived from the configuration file (look for a file in the same directory as the configuration file ending in '.auth').  You may specify an alternative filename if you wish.  

The auth_file will be created on initial usage when authorisation keys are received from Google.  If you need to change the Google username, or re-authorise the software for any other reason, delete the auth_file or specify an auth_file of a different name that does not exist.  Then the initial authorisation process will be repeated and a new auth_file will be created.

=back

=head2 REPORT OPTIONS

=over 4

=item * --all_touches_report

If set, the generated report includes the all-touches report; enabled by
default.  The all-touches report shows, for each channel, the total number of
transactions and the total revenue amount in which that channel played a role.
Since multiple channels may have contributed to each transaction, the total of
all transactions across all channels will exceed the actual number of
transactions.

=item * --even_touches_report

If set, the generated report includes the even-touches report; enabled by
default.  The even-touches report shows, for each channel, a number of
transactions and revenue amount evenly distributed between the participating
channels.  For example, if Channel A has 3 touches and Channel B 2 touches, half
of the revenue/transactions will be allocated to Channel A and half to Channel
B.  Since each individual transaction is evenly distributed across the
contributing channels, the total of all transactions (revenue) across all
channels will equal the actual number of transactions (revenue).

=item * --distributed_touches_report

If set, the generated report includes the distributed-touches report; enabled by
default.  The distributed-touches report shows, for each channel, a number of
transactions and revenue amount in proportion to the number of touches for that
channel.  For example, if Channel A has 3 touches and Channel B 2 touches, 60%
(3/5) of the revenue/transactions will be allocated to Channel A and 40% (2/5)
to Channel B. Since each individual transaction is distributed across the
contributing channels, the total of all transactions (revenue) across all
channels will equal the actual number of transactions (revenue).

=item * --first_touch_report

If set, the generated report includes the first-touch report; enabled by
default.  The first-touch report allocates transactions and revenue to the
channel that received the first touch within the analysis window.

=item * --last_touch_report

If set, the generated report includes the last-touch report; enabled by
default.  The last-touch report allocates transactions and revenue to the
channel that received the last touch prior to the transaction.

=item * --fifty_fifty_report

If set, the generated report includes the fifty-fifty report; enabled by
default.  The fifty-fifty report allocates transactions and revenue equally
between first touch and last touch contributors.

=item * --transactions

If set, the generated report includes transactions report; enabled by default.
The transactions report lists each transaction and the channels that contributed
to it. 

=item * --window_length=DAYS

The analysis window length, in days.  Only touches this many days prior to any
given order will be included in the analysis.

=item * --single_order_model

If set, any touch is counted only once, toward the next order only; subsequent
repeat orders do not include touches prior to the initial order.

=item * --channel_pattern=PATTERN

Each "channel" is derived from the Google source (source), Google medium (med)
and a subcategory (subcat) field that can be set in the javascript calls, joined
using the pattern separator patsep (defined in L<new>, default '-').  

For example, the source might be 'yahoo' or 'google' and the medium 'organic' or
'cpc'.  To see a report on channels yahoo-organic, google-organic, google-cpc
etc, the channel pattern would be 'source-med'.  To see the report just at the
search engine level, channel pattern would be 'source', and to see the report
just at the medium level, the channel pattern would be 'med'.

Arbitrary ordering is permissible, e.g. med-subcat-source.

The default channel pattern is 'source-med-subcat'.

=back

=head2 ADVANCED OPTIONS

=over 4

=item * --patsep=C

The pattern separator for turning source, medium and subcategory information
into a "channel" identifier.  See the C<channel_pattern> option for more
information.  Defaults to '-'.

=item * --format=FORMAT

May be set to xls, csv or txt to specify Excel, CSV and Text format output
respectively.  The filename extension takes precedence over this parameter.

=item * --event_category=CATEGORY

The name of the event category used in Google Analytics to store multi-touch
data.  Defaults to 'multitouch' and only needs to be changed if the equivalent
variable in the associated javascript library has been customised.

=item * --fieldsep=C, --recsep=C

Field and record separators for stored multi-touch data.  These default to '!'
and '*' respectively and only need to be changed if the equivalent variables in
the associated javascript library has been customised.

=item * --debug

Enable debug output.

=item * --conf=FILENAME

Specify a configuration file from which to read options, including advanced templating options.

=item * --class_name=CLASS

Specify an alternative class name for WWW::Analytics::MultiTouch.  This allows
you to write a new class based on WWW::Analytics::MultiTouch but still invoke it
through this script.

=back

=head1 CONFIGURATION FILE

A configuration file can be used to store any of the command line options, plus
advanced options that control the type and layout of the reports.

The file format is L<Config::General>, per the following example:

  id = 5555555
  ga_timezone = -1300
  report_timezone = UTC

  channel_pattern = med-subcat

  <column_heading_format>
    bold = 1
    color = white
    bg_color = red
    right_color = white
    right = 1
  </column_heading_format>

  <row_heading_format>
    bold = 1
    bg_color = gray
  </row_heading_format>

  <header_layout>
    hide_gridlines = 2
    <image>
      row = 1
      col = 0
      filename = MyLogo.png
    </image>
    <header>
      row = 5
      col = 0
      colspan = 5
      text = Multi Touch Reporting
      <cell_format>
        align = center
        bold = 1
        bg_color = red
        color = white
        size = 16
      </cell_format>
    </header>
    <header>
      row = 7
      col = 0
      text = Generation Date:
      text = Report Type:
      text = Date Range:
      text = Analysis Window:
      <cell_format>
        align = right
        bold = 1
      </cell_format>
    </header>
    <header>
      row = 7
      col = 1
      text = @generation_date
      text = @title
      text = @start_date - @end_date
      text = @window_length days
    </header>

    start_row = 10
  </header_layout>

  <channel_map>
    (none)-(none) = Direct
    organic-(none) = Organic
    cpc-(none) = CPC
    email-(none) = Email
    referral-(none) = Referral
  </channel_map>

The configuration file contains a global section and may contain a report-specific section for each report.  Options from the report-specific section are merged with the global options before use.

For every type of report in the command-line options, (all_touches_report,
first_touch_report, transactions_report, etc), the report-specific section has a
corresponding name, e.g. 'all_touches', 'first_touch', 'transactions'.  For example, 

  <all_touches>
    title = Channel Contribution
    <title_format>
      bold = 1
    </title_format>
    sheetname = Channel Contribution
    <heading_map>
      Transactions = Contributed Transactions
      Revenue = Contributed Revenue
    </heading_map>
    <column_formats>
      bg_color = white
    </column_formats>
  </all_touches>


The options in the configuration file are the same as those described under
L<WWW::Analytics::MultiTouch/process>.  An example configuration file can be
found in the examples directory of this distribution.

The special variable $cwd may be used to refer to the directory in which the
configuration file is found, so filenames may be specified relative to this
directory, e.g.

  filename = $cwd/../images/MyLogo.png

=head1 RELATED INFORMATION

See L<http://www.multitouchanalytics.com> for further details.

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-analytics-multitouch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Analytics-MultiTouch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Analytics::MultiTouch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Analytics-MultiTouch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Analytics-MultiTouch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Analytics-MultiTouch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Analytics-MultiTouch/>

=back


=head1 COPYRIGHT & LICENSE

 Copyright 2010 YourAmigo Ltd.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.


=cut

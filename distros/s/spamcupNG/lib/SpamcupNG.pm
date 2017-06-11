package SpamcupNG;
use warnings;
use strict;
use LWP::UserAgent 6.05;
use HTML::Form 6.03;
use HTTP::Cookies 6.01;
use Getopt::Std;
use YAML::XS 0.62 qw(LoadFile);
use File::Spec;
use Hash::Util qw(lock_hash);
use Exporter 'import';

our @EXPORT_OK = qw(read_config main_loop get_browser %MAP);

our %MAP = (
    'nothing'     => 'n',
    'all'         => 'a',
    'stupid'      => 's',
    'quiet'       => 'q',
    'alt_code'    => 'c',
    'alt_user'    => 'l',
    'info_level'  => 'd',
    'debug_level' => 'D'
);

lock_hash(%MAP);

our $VERSION = '0.4'; # VERSION

=head1 NAME

SpamcupNG - module to export functions for spamcup program

=head1 SYNOPSIS

    use SpamcupNG qw(read_config get_browser);

=head1 DESCRIPTION

Spamcup NG is a Perl web crawler for finishing Spamcop.net reports automatically. This module implements the functions used by the spamcup program.

See the README.md file on this project for more details.

See the INSTALL for setup instructions.

=head1 EXPORTS

=head2 read_config

Reads a YAML file, sets the command line options and return the associated accounts.

Expects as parameter a string with the full path to the YAML file and a hash reference of the
command line options read (as returned by L<Getopts::Std> C<getopts> function).

The hash reference options will set as defined in the YAML file.
Options defined in the YAML have preference of those read on the command line then.

It will also return all data configured in the C<Accounts> section of the YAML file as a hash refence. Check the README.md file for more details about
the configuration file.

=cut

sub read_config {
    my ( $cfg, $cmd_opts ) = @_;
    my $data = LoadFile($cfg);

    for my $opt ( keys(%MAP) ) {

        if ( exists( $data->{ExecutionOptions}->{$opt} )
            and ( $data->{ExecutionOptions}->{$opt} eq 'y' ) )
        {
            $cmd_opts->{$opt} = 1;
        }
        else {
            $cmd_opts->{$opt} = 0;
        }

    }

    return $data->{Accounts};
}

=pod

=head2 get_browser

Creates a instance of L<LWP::UserAgent> and returns it.

Expects two string as parameters: one with the name to associated with the user
agent and the another as version of it.

=cut

# :TODO:23/04/2017 17:21:28:ARFREITAS: Add options to configure nice things
# like HTTP proxy

sub get_browser {
    my ( $name, $version ) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->agent("$name/$version");
    $ua->cookie_jar( HTTP::Cookies->new() );
    return $ua;
}

=pod

=head2 main_loop

Processes all the pending spam reports in a loop until finished.

Expects as parameter (in this sequence):

=over

=item *

a L<LWP::UserAgent> instance

=item *

A hash reference with the following key/values:

=over

=item *

ident => The identity to Spamcop

=item *

pass => The password to Spamcop

=item *

debug => true (1) or false (0) to enable/disable debug information

=item *

delay => time in seconds to wait for next iteration with Spamcop website

=item *

quiet => true (1) or false (0) to enable/disable messages

As confusing as it seems, current implementation may accept debug messages
B<and> disable other messages.

=item *

check_only => true (1) or false (0) to only check for unreported SPAM, but not reporting them

=back

=back

Returns true if everything went right, or C<die> if a fatal error happened.

=cut

# :TODO:23/04/2017 16:04:17:ARFREITAS: probably this sub is too large
# It should be refactored to at least separate the parsing from HTML content recover
sub main_loop {
    my ( $ua, $opts_ref ) = @_;

    # last seen SPAM id
    my $last_seen;

    # Get first page that contains link to next one...

# :TODO:23/04/2017 17:06:59:ARFREITAS: replace all this debugging checks with Log::Log4perl
    if ( $opts_ref->{debug} ) {
        if ( $opts_ref->{pass} ) {
            print 'D: GET http://', $opts_ref->{ident},
              ':******@members.spamcop.net/', "\n";
        }
        else {
            print 'D: GET http://www.spamcop.net/?code=', $opts_ref->{ident},
              "\n";
        }
    }

    if ( $opts_ref->{debug} ) {
        print 'D: sleeping for ', $opts_ref->{delay}, " seconds.\n";
    }

    sleep $opts_ref->{delay};

    my $req;

    if ( $opts_ref->{pass} ) {
        $req = HTTP::Request->new( GET => 'http://members.spamcop.net/' );
        $req->authorization_basic( $opts_ref->{ident}, $opts_ref->{pass} );
    }
    else {
        $req =
          HTTP::Request->new(
            GET => 'http://www.spamcop.net/?code=' . $opts_ref->{ident} );
    }

    my $res = $ua->request($req);

    # verify response
    if ( $res->is_success ) {
        if ( $opts_ref->{debug} ) {
            print "D: Got HTTP response\n";
        }
    }
    else {
        my $response = $res->status_line();
        if ( $response =~ /500/ ) {
            die "E: Can\'t connect to server: " . $response;
        }
        else {
            warn $response;
            die
"E: Can\'t connect to server or invalid credentials. Please verify your username and password and try again.\n";
        }
    }

    if ( $opts_ref->{debug} ) {
        print
"\n--------------------------------------------------------------------------\n";
        print $res->content;
        print
"--------------------------------------------------------------------------\n\n";
    }

    # Parse id for link
    if ( $res->content =~ /\>No userid found\</i ) {
        die
"E: No userid found. Please check that you have entered correct code. Also consider obtaining a password to Spamcop.net instead of using the old-style authorization token.\n";
    }

    my $fullname;

    if ( $res->content =~ /(Welcome, .*?)\./ ) {

        # found full name, print out the greeting string
        print "* $1\n";
    }

    my $nextid;

    if ( $res->content =~ /sc\?id\=(.*?)\"\>/gi ) {    # this is easy to parse
            # userid ok, new spam available
        $nextid = $1;
    }
    else {
        # userid ok, no new spam
        unless ( $opts_ref->{quiet} ) {
            print "* No unreported spam found. Quitting.\n";
        }
        return -1;    # quit
    }

    if ( $opts_ref->{quiet} ) {
        print "* ID of the next spam is '$nextid'.\n";
    }

    # avoid loops
    if ( ($last_seen) and ( $nextid eq $last_seen ) ) {
        die
"E: I have seen this ID earlier. We don't want to report it again. This usually happens because of a bug in Spamcup. Make sure you use latest version! You may also want to go check from Spamcop what's happening: http://www.spamcop.net/sc?id=$nextid\n";
    }

    $last_seen = $nextid;    # store for comparison

    $req = undef;
    $res = undef;

    # Fetch the spam report form

    if ( $opts_ref->{debug} ) {
        print "D: GET http://www.spamcop.net/sc?id=$nextid\n";
        print 'D: Sleeping for ', $opts_ref->{delay}, " seconds.\n";
    }

    sleep $opts_ref->{delay};

    $req =
      HTTP::Request->new( GET => 'http://www.spamcop.net/sc?id=' . $nextid );
    $res = $ua->request($req);

    if ( $res->is_success ) {
        if ( $opts_ref->{debug} ) {
            print "D: Got HTTP response\n";

            # print "D: Headers follow:\n". $res->headers->as_string ."\n\n";
        }

    }
    else {
        die "E: Can't connect to server. Try again later.\n\n";
    }

    if ( $opts_ref->{debug} ) {
        print
"\n--------------------------------------------------------------------------\n";
        print $res->content;
        print
"--------------------------------------------------------------------------\n\n";
    }

    # parse the spam

    my $_cancel = 0;

    my $base_uri = $res->base();
    if ( !$base_uri ) {
        print "E: No base uri found. Internal error? Please report this.\n";
        exit;
    }

    $res->content =~
      /(\<form action[^>]+name=\"sendreport\"\>.*?\<\/form\>)/sgi;
    my $formdata = "<html><body>$1</body></html>";
    my $form = HTML::Form->parse( $formdata, $base_uri );

    # print the header of the spam

    my $spamhead;
    if ( $res->content =~
/Please make sure this email IS spam.*?size=2\>\n(.*?)\<a href\=\"\/sc\?id\=$nextid/sgi
      )
    {    # this is also quite easy...
            # this is the normal case

        $spamhead = $1;
        unless ( $opts_ref->{quiet} ) {
            print "* Head of the spam follows >>>\n";
            $spamhead =~ s/\n/\t/igs;      # prepend a tab to each line
            $spamhead =~ s/<br>/\n/gsi;    # simplify a bit
            print "\t$spamhead\n";
            print "<<<\n";
        }

        # parse form fields
        # verify form
        unless ($form) {
            if ( $opts_ref->{debug} ) {
                print
"D: Spamcop returned invalid HTML form. Usually temporary error.\n";
            }
            die "E: Temporary Spamcop.net error. Try again later! Quitting.\n";
        }
        else {
            if ( $opts_ref->{debug} ) {
                print "D: Form data follows:\n" . $form->dump . "\n\n";
            }

            # how many recepients for reports
            my $max = $form->value("max");

            my $willsend;
            my $wontsend;

            # iterate targets
            for ( my $i = 1 ; $i <= $max ; $i++ ) {
                my $send   = $form->value("send$i");
                my $type   = $form->value("type$i");
                my $master = $form->value("master$i");
                my $info   = $form->value("info$i");

                # convert %2E -style stuff back to text, if any
                if ( $info =~ /%([A-Fa-f\d]{2})/g ) {
                    $info =~ s/%([A-Fa-f\d]{2})/chr hex $1/eg;
                }

                if (
                    $send
                    and (  ( $send eq 'on' )
                        or ( $type =~ /^mole/ and $send == 1 ) )
                  )
                {
                    $willsend .= "\t$master \t($info)\n";
                }
                else {
                    $wontsend .= "\t$master \t($info)\n";
                }
            }

            print
"Would send the report to the following addresses: (Reason in parenthesis)\n";
            if ($willsend) {
                print $willsend;
            }
            else {
                print "\t--none--\n";
            }

            print "Following addresses would not be used:\n";
            if ($wontsend) {
                print $wontsend;
            }
            else {
                print "\t--none--\n";
            }

        }

        # Run without confirming each spam? Stupid. :)
        unless ( $opts_ref->{stupid} ) {
            print "* Are you sure this is spam? [y/N] ";

            my $reply = <>;    # this should be done differently!
            if ( $reply && $reply !~ /^y/i ) {
                print "* Cancelled.\n";
                $_cancel = 1;    # mark to be cancelled
            }
            elsif ( !$reply ) {
                print "* Accepted.\n";
            }
            else {
                print "* Accepted.\n";
            }
        }
        else {
            # little delay for automatic processing
            sleep $opts_ref->{delay};
        }
        print "...\n";

    }
    elsif ( $res->content =~ /Send Spam Report\(S\) Now/gi ) {

# this happens rarely, but I've seen this; spamcop does not show preview headers for some reason
        unless ( $opts_ref->{stupid} ) {
            print
"* Preview headers not available, but you can still report this. Are you sure this is spam? [y/N] ";

            my $reply = <>;
            if ( $reply && $reply !~ /^y/i ) {

                # not Y
                print "* Cancelled.\n";
                $_cancel = 1;    # mark to be cancelled
            }
            else {
                # Y
                print "* Accepted.\n";
            }
        }

    }
    elsif ( $res->content =~
/Sorry, this email is too old.*This mail was received on (.*?)\<\/.*\>/gsi
      )
    {
        # perhaps it's too old then
        my $ondate = $1;
        unless ( $opts_ref->{quiet} ) {
            print
"W: This spam is too old. You must report spam within 3 days of receipt. This mail was received on $ondate. Deleted.\n";
        }
        return 0;

    }
    elsif ( $res->content =~
/click reload if this page does not refresh automatically in \n(\d+) seconds/gs
      )
    {
        my $delay = $1;
        print
"W: Spamcop seems to be currently overloaded. Trying again in $delay seconds. Wait...\n";
        sleep $opts_ref->{delay};

        # fool it to avoid duplicate detector
        $last_seen = 0;

        # fake that everything is ok
        return 1;
    }
    elsif ( $res->content =~
        /No source IP address found, cannot proceed. Not full header/gs )
    {
        print
"W: No source IP address found. Your report might be missing headers. Skipping.\n";
        return 0;
    }

    else {
        # Shit happens. If you know it should be parseable, please report a bug!
        print
"W: Can't parse Spamcop.net's HTML. If this does not happen very often you can ignore this warning. Otherwise check if there's new version available. Skipping.\n";
        return 0;
    }

    if ( $opts_ref->{check_only} ) {
        print
"* You gave option -n, so we'll stop here. The spam was NOT reported.\n";
        exit;
    }

    if ( $opts_ref->{debug} ) {
        print "\n\nD: Starting the parse phase...\n";
    }

    undef $req;
    undef $res;

    # Submit the form to Spamcop OR cancel report

    if ( !$_cancel ) {    # SUBMIT spam

        if ( $opts_ref->{debug} ) {
            print "D: Submitting form. We will use the default recipients.\n";
            print "D: GET http://www.spamcop.net/sc?id=$nextid\n";
            print 'D: Sleeping for ', $opts_ref->{delay}, " seconds.\n";
        }
        sleep $opts_ref->{delay};
        $res = LWP::UserAgent->new->request( $form->click() )
          ;               # click default button, submit
    }
    else {                # CANCEL SPAM
        if ( $opts_ref->{debug} ) {
            print "D: About to cancel report.\n";
        }
        $res = LWP::UserAgent->new->request( $form->click('cancel') )
          ;               # click cancel button
    }

    # Check the outcome of the response
    if ( $res->is_success ) {
        if ( $opts_ref->{debug} ) {
            print "D: Got HTTP response\n";
            print "D: -- content follows -------------------------\n";
            print $res->content;
            print "D: -- content ended   -------------------------\n\n";
        }

    }
    else {
        die "E: Can't connect to server. Try again later. Quitting.\n";
    }

    if ($_cancel) {
        return 1;    # user decided this mail is not spam
    }

    # parse respond
    my $report;
    if ( $res->content =~ /(Spam report id .*?)\<p\>/gsi ) {
        $report = $1 || "-none-\n";
        $report =~ s/\<br\>//gi;
    }
    elsif ( $res->content =~ /report for mole\@devnull.spamcop.net/ ) {
        $report = 'Mole report(s)';
    }
    else {
        print
"W: Spamcop.net returned unexpected content. If this does not happen very often you can ignore this. Otherwise check if there new version available. Continuing.\n";
    }

    # print the report

    unless ( $opts_ref->{quiet} ) {
        print "Spamcop.net sent following spam reports:\n";
        print "$report\n" if $report;
        print "* Finished processing.\n";
    }

    return 1;

    # END OF THE LOOP
}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of spamcupNG distribution.

spamcupNG is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

spamcupNG is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with spamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;

package SpamcupNG;
use warnings;
use strict;
use LWP::UserAgent 6.05;
use HTML::Form 6.03;
use HTTP::Cookies 6.01;
use Getopt::Std;
use HTML::Entities 3.69;
use YAML::XS 0.62 qw(LoadFile);
use File::Spec;
use Hash::Util qw(lock_hash);
use Exporter 'import';
use Log::Log4perl 1.48 qw(get_logger :levels);
use Carp;
use HTML::TreeBuilder::XPath 0.14;

our @EXPORT_OK = qw(read_config main_loop get_browser %MAP config_logger);
our %MAP       = (
    'check_only' => 'n',
    'all'        => 'a',
    'stupid'     => 's',
    'alt_code'   => 'c',
    'alt_user'   => 'l',
    'verbosity'  => 'V',
);

my %fatal_errors = (
    mailhost_problem => qr/Mailhost\sconfiguration\sproblem/i,
    too_old          => qr/^Sorry,\sthis\semail\sis\stoo\sold/
);

my %regexes = (
    no_user_id => qr/\>No userid found\</i,
    next_id    => qr/sc\?id\=(.*?)\"\>/i,
    http_500   => qr/500/,
);

lock_hash(%MAP);

our $VERSION = '1.2'; # VERSION

=head1 NAME

SpamcupNG - module to export functions for spamcup program

=head1 SYNOPSIS

    use SpamcupNG qw(read_config get_browser);

=head1 DESCRIPTION

B<DEPRECATED>: this module is deprecated. Please checkout L<App::SpamcupNG> for a replacement.

SpamcupNG is a Perl web crawler for finishing Spamcop.net reports
automatically. This module implements the functions used by the spamcup
program.

See the README.md file on this project for more details.

See the INSTALL for setup instructions.

=head1 EXPORTS

=head2 read_config

Reads a YAML file, sets the command line options and return the associated
accounts.

Expects as parameter a string with the full path to the YAML file and a hash
reference of the command line options read (as returned by L<Getopts::Std>
C<getopts> function).

The hash reference options will set as defined in the YAML file. Options
defined in the YAML have preference of those read on the command line then.

It will also return all data configured in the C<Accounts> section of the YAML
file as a hash refence. Check the README.md file for more details about the
configuration file.

=cut

sub read_config {
    my ( $cfg, $cmd_opts ) = @_;
    my $data = LoadFile($cfg);

    # sanity checking
    for my $opt ( keys( %{ $data->{ExecutionOptions} } ) ) {
        die
"$opt is not a valid option for configuration files. Check the documentation."
          unless ( exists( $MAP{$opt} ) );
    }

    for my $opt ( keys(%MAP) ) {

        if ( $opt eq 'verbosity' ) {
            $cmd_opts->{'V'} = $data->{ExecutionOptions}->{$opt};
            next;
        }

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

sub get_browser {
    my ( $name, $version ) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->agent("$name/$version");
    $ua->cookie_jar( HTTP::Cookies->new() );
    return $ua;
}

=pod

=head2 config_logger

Configures a L<Log::Log4perl> object, as defined by the verbosity parameter (-V
in the command line).

Expected parameters:

=over

=item *

level

=item *

path to a log file

=back

If the verbosity is set to DEBUG, all messages will be sent to a log file
opened as C<spamcup.log> in append mode.

Otherwise, all messages will be sent to C<STDOUT>.

Verbosity modes are:

=over

=item *

DEBUG

=item *

INFO

=item *

WARN

=item *

ERROR

=item *

FATAL

=back

Depending on the verbosity level, more or less information you be provided. See
L<Log::Log4perl> for more details about the levels.

=cut

sub config_logger {
    my ( $level, $log_file ) = @_;
    croak "Must receive a string for the level parameter"
      unless ( ( defined($level) ) and ( $level ne '' ) );
    croak "Must receive a string for the log file parameter"
      unless ( ( defined($log_file) ) and ( $log_file ne '' ) );

    my %levels = (
        DEBUG => $DEBUG,
        INFO  => $INFO,
        WARN  => $WARN,
        ERROR => $ERROR,
        FATAL => $FATAL
    );
    croak "The value '$level' is not a valid value for level"
      unless ( exists( $levels{$level} ) );

    my $conf;

    if ( $level eq 'DEBUG' ) {
        $conf = qq(
log4perl.category.SpamcupNG = DEBUG, Logfile
log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = $log_file
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = [%d] - %p - %F %L - %m%n
	);
    }
    else {
        $conf = qq(
log4perl.category.SpamcupNG = $level, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 0
log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
		);
    }

    Log::Log4perl::init( \$conf );
}

=pod

=head2 main_loop

Processes all the pending SPAM reports in a loop until finished.

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

delay => time in seconds to wait for next iteration with Spamcop website

=item *

verbosity => defines what level of information should be provided. Uses the
same values as defined by L<Log::Log4perl>.

As confusing as it seems, current implementation may accept debug messages
B<and> disable other messages.

=item *

check_only => true (1) or false (0) to only check for unreported SPAM, but not
reporting them

=back

=back

Returns true if everything went right, or C<die> if a fatal error happened.

=cut

sub _self_auth {
    my ( $ua, $opts_ref ) = @_;
    my $logger = get_logger('SpamcupNG');
    my $req;
    my $auth_is_ok = 0;

    if ( $opts_ref->{pass} ) {
        $req = HTTP::Request->new( GET => 'http://members.spamcop.net/' );
        $req->authorization_basic( $opts_ref->{ident}, $opts_ref->{pass} );
    }
    else {
        $req =
          HTTP::Request->new(
            GET => 'http://www.spamcop.net/?code=' . $opts_ref->{ident} );
    }

    if ( $logger->is_debug() ) {
        $logger->debug( "Request details:\n" . $req->as_string );
    }

    my $res = $ua->request($req);

    if ( $logger->is_debug() ) {
        $logger->debug( "Got HTTP response:\n" . $res->as_string );
    }

    # verify response
    if ( $res->is_success ) {
        $auth_is_ok = 1;
    }
    else {
        my $res_status = $res->status_line();

        if ( $res_status =~ $regexes{http_500} ) {
            $logger->fatal("Can\'t connect to server: $res_status");
        }
        else {
            $logger->warn($res_status);
            $logger->fatal(
'Cannot connect to server or invalid credentials. Please verify your username and password and try again.'
            );
        }
    }

    my $content = $res->content;

    # Parse id for link
    if ( $content =~ $regexes{no_user_id} ) {
        $logger->logdie(
'No userid found. Please check that you have entered correct code. Also consider obtaining a password to Spamcop.net instead of using the old-style authorization token.'
        );
    }

    if ($auth_is_ok) {
        return $content;
    }
    else {
        return undef;
    }

}

sub _check_next_id {
    my $content_ref = shift;
    my $next_id;
    my $logger = get_logger('SpamcupNG');

    if ( $$content_ref =~ $regexes{next_id} ) {
        $next_id = $1;
        $logger->info("ID of the next SPAM is '$next_id'");
    }
    else {
        # userid ok, no new spam
        $logger->info('No unreported SPAM found.');
    }

    return $next_id;
}

sub _check_warning {
    my $content_ref = shift;
    my $tree        = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @errors = $tree->findnodes('//div[@id="content"]/div[@class="warn"]');

    if ( scalar(@errors) > 0 ) {
        return $errors[0]->as_trimmed_text;
    }
    else {
        return;
    }
}

sub _check_error {
    my $content_ref = shift;
    my $tree        = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @errors = $tree->findnodes('//div[@id="content"]/div[@class="error"]');

    if ( scalar(@errors) > 0 ) {
        return $errors[0]->as_trimmed_text;
    }
    else {
        return;
    }
}

sub main_loop {
    my ( $ua, $opts_ref ) = @_;
    my $logger = get_logger('SpamcupNG');

    # last seen SPAM id
    my $last_seen;

    # Get first page that contains link to next one...

    if ( $logger->is_debug ) {
        $logger->debug( "Sleeping for " . $opts_ref->{delay} . ' seconds' );
    }

    sleep $opts_ref->{delay};
    my $response = _self_auth( $ua, $opts_ref );
    my $next_id;

    if ($response) {
        $next_id = _check_next_id( \$response );
        return -1 unless ( defined($next_id) );
    }
    else {
        return 0;
    }

    # avoid loops
    if ( ($last_seen) and ( $next_id eq $last_seen ) ) {
        $logger->fatal(
"I have seen this ID earlier, we do not want to report it again. This usually happens because of a bug in Spamcup. Make sure you use latest version! You may also want to go check from Spamcop what is happening: http://www.spamcop.net/sc?id=$next_id"
        );
    }

    $last_seen = $next_id;    # store for comparison

    # Fetch the SPAM report form
    if ( $logger->is_debug ) {
        $logger->debug( 'Sleeping for ' . $opts_ref->{delay} . ' seconds' );
    }

    sleep $opts_ref->{delay};

    # Getting a SPAM report
    my $req =
      HTTP::Request->new( GET => 'http://www.spamcop.net/sc?id=' . $next_id );

    if ( $logger->is_debug ) {
        $logger->debug( "Request to be sent:\n" . $req->as_string );
    }

    my $res = $ua->request($req);

    if ( $logger->is_debug ) {
        $logger->debug( "Got HTTP response:\n" . $res->as_string );
    }

    unless ( $res->is_success ) {
        $logger->fatal("Can't connect to server. Try again later.");
        return 0;
    }

    if ( my $warn_msg = _check_warning( \( $res->content ) ) ) {
        $logger->warn($warn_msg);
    }

    if ( my $error_msg = _check_error( \( $res->content ) ) ) {

        my $is_fatal = 0;

        for my $fatal_error ( keys(%fatal_errors) ) {

            if ( $error_msg =~ $fatal_errors{$fatal_error} ) {
                $is_fatal = 1;
                last;
            }

        }

        if ($is_fatal) {
            $logger->fatal($error_msg);

            # must stop processing the HTML for this report and move to next
            return 0;
        }
        else {
            $logger->error($error_msg);
        }
    }

    # parse the spam
    my $_cancel  = 0;
    my $base_uri = $res->base();

    unless ($base_uri) {
        $logger->fatal(
'No base URI found. Internal error? Please report this error by registering an issue on Github'
        );
    }

    $res->content =~
      /(\<form action[^>]+name=\"sendreport\"\>.*?\<\/form\>)/sgi;
    my $form_data = $1;

    if ( defined($form_data) ) {
        $form_data = "<html><body>$1</body></html>";
    }
    else {
        $logger->error('Could not parse form data from HTTP response');

        # :WORKAROUND:18/02/2018 14:20:17:ARFREITAS: to avoid warnings
        $form_data = '';
    }

    my $form = HTML::Form->parse( $form_data, $base_uri );

    if ( $res->content =~
/Please make sure this email IS spam.*?size=2\>\n(.*?)\<a href\=\"\/sc\?id\=$next_id/sgi
      )
    {

        if ( $logger->is_info ) {
            my $spamhead = decode_entities($1);
            $spamhead =~ s/\n/\t/igs;    # prepend a tab to each line
            $spamhead =~ s/<\/?strong>//gi;
            $spamhead =~ s/<br>/\n/gsi;
            $spamhead =~ s/<\/?font>//gi;
            binmode( STDOUT, ":utf8" );
            $logger->info("Head of the SPAM follows:\n$spamhead");
        }

        # parse form fields
        # verify form
        unless ($form) {

            $logger->fatal(
'Could not find the HTML form to report the SPAM! May be a temporary Spamcop.net error, try again later! Quitting...'
            );
        }
        else {

            if ( $logger->is_debug ) {
                $logger->debug( 'Form data follows: ' . $form->dump );
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

            if ( $logger->is_info ) {

                my $message =
'Would send the report to the following addresses (reason in parenthesis): ';

                if ($willsend) {
                    $message .= $willsend;
                }
                else {
                    $message .= '--none--';
                }

                $logger->info($message);
                $message = 'Following addresses would not be used: ';

                if ($wontsend) {
                    $message .= $wontsend;
                }
                else {
                    $message .= '--none--';
                }

                $logger->info($message);

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

    }
    elsif ( $res->content =~ /Send Spam Report\(S\) Now/gi ) {

# this happens rarely, but I've seen this; spamcop does not show preview headers for some reason
        unless ( $opts_ref->{stupid} ) {
            print
"* Preview headers not available, but you can still report this. Are you sure this is spam? [y/N] ";

            my $reply = <>;
            chomp($reply);

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
/click reload if this page does not refresh automatically in \n(\d+) seconds/gs
      )

    {
        my $delay = $1;
        $logger->warn(
"Spamcop seems to be currently overloaded. Trying again in $delay seconds. Wait..."
        );
        sleep $opts_ref->{delay};

        # fool it to avoid duplicate detector
        $last_seen = 0;

        # fake that everything is ok
        return 1;
    }
    elsif ( $res->content =~
        /No source IP address found, cannot proceed. Not full header/gs )
    {
        $logger->warn(
'No source IP address found. Your report might be missing headers. Skipping.'
        );
        return 0;
    }
    else {
        # Shit happens. If you know it should be parseable, please report a bug!
        $logger->warn(
"Can't parse Spamcop.net's HTML. If this does not happen very often you can ignore this warning. Otherwise check if there's new version available. Skipping."
        );
        return 0;
    }

    if ( $opts_ref->{check_only} ) {
        $logger->info(
'You gave option -n, so we\'ll stop here. The SPAM was NOT reported.'
        );
        exit;
    }

    undef $req;
    undef $res;

    # Submit the form to Spamcop OR cancel report
    unless ($_cancel) {    # SUBMIT spam

        if ( $logger->is_debug ) {
            $logger->debug(
                'Submitting form. We will use the default recipients.');
            $logger->debug(
                'Sleeping for ' . $opts_ref->{delay} . ' seconds.' );
        }
        sleep $opts_ref->{delay};
        $res = LWP::UserAgent->new->request( $form->click() )
          ;                # click default button, submit
    }
    else {                 # CANCEL SPAM
        $logger->debug('About to cancel report.');
        $res = LWP::UserAgent->new->request( $form->click('cancel') )
          ;                # click cancel button
    }

    if ( $logger->is_debug ) {
        $logger->debug( "Got HTTP response:\n" . $res->as_string );
    }

    # Check the outcome of the response
    unless ( $res->is_success ) {
        $logger->fatal('Cannot connect to server. Try again later. Quitting.');
        return 0;
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
    elsif ( $res->content =~ /\/dev\/null/ ) {
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse_content( $res->content );
        my @dev_nulling = $tree->findnodes('//*[@id="content"]');
        $report = $dev_nulling[0]->as_trimmed_text;
    }
    else {
        $logger->warn(
'Spamcop.net returned unexpected content (no SPAM report id). If this does not happen very often you can ignore this. Otherwise check if there new version available. Continuing.'
        );
    }

    # print the report
    if ( $logger->is_info ) {

        if ($report) {
            $logger->info("Spamcop.net sent following SPAM reports:\n$report");
        }

        $logger->info('Finished processing.');

    }

    return 1;

    # END OF THE LOOP
}

=head1 SEE ALSO

=over

=item *

L<Log::Log4perl>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

This file is part of spamcupNG distribution.

spamcupNG is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

spamcupNG is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
spamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;

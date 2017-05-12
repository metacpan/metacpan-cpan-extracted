package perfSONAR_PS::OWP::Navigation;

require 5.005;
require Exporter;
use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::OWP

=head1 DESCRIPTION

Various functions to provide navigation tables in web pages, this framework
shamelessly ripped off from Jeff and Anatoly's modules in OWP

=cut

use perfSONAR_PS::OWP::Utils;

our @ISA    = qw(Exporter);
our @EXPORT = qw(links timeselect);    # Symbols to be exported by default

=head2 links()

TDB

=cut

sub links {
    use POSIX qw(ceil);                # import the POSIX ceiling function

    my $navText = q{};

    # grab the passed values
    my ( $config_file, $selfdir, $tstamp, $limitBy, $limitVal, $bordersize ) = @_;
    my $protocol = q{};
    my $i        = 0;                  # iterators used in the table code
    my $numCols  = 0;                  # number of columns in the table
    my %cgiInfo;                       # hash used to store cgi urls and names
    my $status = open( CONFIG, "<", $config_file );    # open a filehandle to read the file

    # stolen from the perl cookbook 2nd ed recipe 8.16
    while (<CONFIG>) {
        chomp;                                         # no newline
        s/#.*//;                                       # no comments
        s/^\s+//;                                      # no leading white
        s/\s+$//;                                      # no trailing white
        next unless length;                            # anything left
        my ( $var, $value ) = split( /\s*=\s*/, $_, 2 );
        $cgiInfo{$var} = $value;
    }

    # get the number of keys in the hash
    my $numKeys = scalar keys %cgiInfo;

    # set defaults for $limitBy and $limitVal if none are passed
    # constrain by column and limit to 3 columns if nothing is specified
    # or if incorrect values are passed
    if (   !$limitBy
        && !$limitVal
        && $limitBy !~ m/row|col/
        && $limitVal !~ m/^[0-9]+$/ )
    {
        $limitBy  = "col";
        $limitVal = 3;
    }

    # calculate the table dimensions
    if ( $limitBy eq "row" ) {
        my $numRows = $limitVal;    # number of rows in the table
        $numCols = ceil( $numKeys / $numRows );
    }
    elsif ( $limitBy eq "col" ) {
        $numCols = $limitVal;
    }

    # set the bordersize to 0 if it is not passed by the caller
    if ( !defined $bordersize || $bordersize !~ m/^[0-9]+$/ ) {
        $bordersize = 0;
    }

    # create the table
    $navText .= "<table border=$bordersize>\n";
    foreach my $keyname ( keys %cgiInfo ) {
        if ( $i % $numCols == 0 ) {
            $navText .= "\t<tr>\n";
        }
        my $prefval = $cgiInfo{$keyname};

        # TODO: improve these regular expressions
        # check to see if the file is a cgi or static html and construct the url accordingly
        if ( $prefval =~ m/html/ ) {
            $navText .= "\t\t<td><a href=\"$selfdir/$prefval\">$keyname</a><td>\n";
        }

        # owamp is its own protocol, so dont add UDP or TCP to it
        elsif ( ( $prefval =~ m/cgi/ ) && ( $keyname =~ m/\bowamp/i ) ) {
            $navText .= "\t\t<td><a href=\"$selfdir/$prefval/$tstamp\">$keyname</a><td>\n";
        }

        # check to see if tcp or udp are being specified in the link text (not the file name)
        # add the appropriate protocol to the constructed url
        elsif ( ( $keyname =~ m/\btcp/i ) ) {
            $protocol = 'TCP';
            $navText .= "\t\t<td><a href=\"$selfdir/$prefval/$protocol/$tstamp\">$keyname</a><td>\n";
        }
        elsif ( ( $prefval =~ m/cgi/ ) && $keyname =~ m/\budp/i ) {
            $protocol = 'UDP';
            $navText .= "\t\t<td><a href=\"$selfdir/$prefval/$protocol/$tstamp\">$keyname</a><td>\n";
        }
        $i++;    # count the newly added table cell
                 # check again for the number of defined values and end a table row if needed
        if ( $i % $numCols == 0 ) {
            $navText .= "\t<tr>\n";
        }
    }
    $navText .= "</table>\n";    # end the table
    $status = close(CONFIG);
    return $navText;
}

=head2 timeselect()

this function outputs a time selection form
it has carried over almost all code from jeff's tselect.cgi

=cut

sub timeselect {

    # get passed arguments
    my ( $q, $duration ) = @_;

    # define variables to hold year, and month values
    my @years;
    my @monthnames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my %months;

    # define the default duration if one is not passed
    if ( !defined $duration ) {
        $duration = 900;
    }
    my $i = 0;

    # populate %months with @monthnames and their numerical values
    foreach (@monthnames) {
        $months{ $i++ } = $_;
    }

    # define a subroutine to do numerical sort
    sub numerically { $a <=> $b; }

    # sort the month order
    my @monthvalues = sort numerically keys %months;

    # define day, hour, minute, second values appropriately formatted
    my @dates = ( 1 .. 31 );
    my @hours;
    foreach ( 0 .. 23 ) {
        push @hours, sprintf "%02d", $_;
    }
    my @mins;
    foreach ( 0 .. 59 ) {
        push @mins, sprintf "%02d", $_;
    }
    my @secs = @mins;

    my ( $last, $first );
    my $tstamp     = $q->param("tstamp");
    my $tstamptype = $q->param("timetype");
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );
    if ( defined($tstamptype) && ( $tstamptype eq 'now' ) ) {
        ;
    }

    elsif ( defined($tstamptype) && ( $tstamptype eq 'range' ) ) {
        $sec  = $q->param("FSec");
        $min  = $q->param("FMin");
        $hour = $q->param("FHr");
        $mday = $q->param("FDay");
        $mon  = $q->param("FMonth");
        $year = $q->param("FYear");
        if (   !defined($sec)
            || !defined($min)
            || !defined($hour)
            || !defined($mday)
            || !defined($mon)
            || !defined($year) )
        {
            goto BADINPUT;
        }
        $year -= 1900;
        $first = owptimegm( $sec, $min, $hour, $mday, $mon, $year )
            || goto BADINPUT;
        $first = new Math::BigInt $first;

        $sec  = $q->param("TSec");
        $min  = $q->param("TMin");
        $hour = $q->param("THr");
        $mday = $q->param("TDay");
        $mon  = $q->param("TMonth");
        $year = $q->param("TYear");
        if (   !defined($sec)
            || !defined($min)
            || !defined($hour)
            || !defined($mday)
            || !defined($mon)
            || !defined($year) )
        {
            goto BADINPUT;
        }
        $year -= 1900;
        $last = owptimegm( $sec, $min, $hour, $mday, $mon, $year )
            || goto BADINPUT;
        $last = new Math::BigInt $last;
        if ( $first > $last ) {
            my $t = $first + 0;
            $first = $last + 0;
            $last  = $t + 0;
        }
        $tstamp = "${first}_${last}";
    }
    else {
    BADINPUT:
        $tstamp = $q->path_info;
        $tstamp =~ s#^/##o;
        if ($tstamp) {
            if ( $tstamp =~ /^now$/oi ) {
                undef $tstamp;
            }
            elsif ( ( $first, $last ) = ( $tstamp =~ m#(\d*)_(\d*)#o ) ) {
                $first      = new Math::BigInt $first;
                $last       = new Math::BigInt $last;
                $tstamptype = 'range';
                if ( $first > $last ) {
                    my $t = $first + 0;
                    $first = $last + 0;
                    $last  = $t + 0;
                }
            }
            else {
                $last       = new Math::BigInt $tstamp;
                $tstamptype = 'end';
            }
        }
        $q->delete('ok');
    }

    if ( !$tstamp ) {
        $last       = new Math::BigInt time2owptime( time() );
        $tstamptype = 'now';
        $tstamp     = 'now';
    }

    if ( $q->param('ok') && $q->param('back') ) {
        print $q->header(
            -Status   => '302 Found',
            -Location => $q->param('back') . "/" . $tstamp,
            -URI      => $q->param('back') . "/" . $tstamp,
            -type     => 'text/html'
        );
        print $q->start_html( -title => "Redirect Page", );
        print $q->h1("Goback! - you shouldn't be here!");
        print $q->p( "You should have been redirected to", $q->a( { href => $q->param('back') . "/" . $tstamp }, $q->param('back') . "/" . $tstamp ) );
        print $q->end_html;

        exit 0;
    }

    if ( !$first ) {
        $first = new Math::BigInt owptimeadd( $last, -$duration );
    }

    my $currstr = owpgmstring( time2owptime( time() ) );
    my ( $fsec, $fmin, $fhour, $fmday, $fmon, $fyear, $fwday, $fyday ) = owpgmtime($first);
    $fyear += 1900;
    my ( $lsec, $lmin, $lhour, $lmday, $lmon, $lyear, $lwday, $lyday ) = owpgmtime($last);
    $lyear += 1900;
    @years = ( $lyear - 5 .. $lyear + 5 );

    # my($base,$dir) = fileparse($q->script_name);
    # my $selfurl = "http://".$q->server_name.$dir;
    # my $back = $q->param('back');

    #print $q->header(	-type=>'text/html',
    #			-expires=>'now');
    #print $q->start_html(	-title=>'Time Selection',
    #			-author=>'owamp@internet2.edu',
    #			-xbase=>$selfurl,
    #		);
    print $q->h1("Time Selection");

    #$q->delete_all();

    #print $q->start_form(-action=>"test.cgi");
    print $q->start_form();
    my @radio;

    # current year selection
    push @radio,
        (
        -name   => 'timetype',
        -values => ['now'],
        -labels => { now => 'Current Time' },
        );
    push @radio, ( -default => $tstamptype );
    print $q->p( $q->radio_group(@radio), ": $currstr", $q->em("(ongoing)") ), "\n";

    # Range Selection
    undef @radio;
    push @radio,
        (
        -name   => 'timetype',
        -values => ['range'],
        -labels => { range => 'Specific Range' },
        );
    push @radio, ( -default => $tstamptype );

    print $q->p(
        $q->dl(
            $q->dt( $q->radio_group(@radio) ),
            "\n",
            $q->dd(
                "From Date:",
                $q->popup_menu(
                    -name    => 'FYear',
                    -Values  => \@years,
                    -default => $fyear,
                ),
                "\n",
                $q->popup_menu(
                    -name    => 'FMonth',
                    -Values  => \@monthvalues,
                    -labels  => \%months,
                    -default => $fmon,
                ),
                "\n",
                $q->popup_menu(
                    -name    => 'FDay',
                    -Values  => \@dates,
                    -default => $fmday,
                ),
                "\n", "Time:",
                $q->popup_menu(
                    -name    => 'FHr',
                    -Values  => \@hours,
                    -default => $fhour,
                ),
                "\n", ":",
                $q->popup_menu(
                    -name    => 'FMin',
                    -Values  => \@mins,
                    -default => $fmin,
                ),
                "\n", ":",
                $q->popup_menu(
                    -name    => 'FSec',
                    -Values  => \@secs,
                    -default => $fsec,
                ),
                "\n",
            ),
            $q->dd(
                "To Date:",
                $q->popup_menu(
                    -name    => 'TYear',
                    -Values  => \@years,
                    -default => $lyear,
                ),
                "\n",
                $q->popup_menu(
                    -name    => 'TMonth',
                    -Values  => \@monthvalues,
                    -labels  => \%months,
                    -default => $lmon,
                ),
                "\n",
                $q->popup_menu(
                    -name    => 'TDay',
                    -Values  => \@dates,
                    -default => $lmday,
                ),
                "\n", "Time:",
                $q->popup_menu(
                    -name    => 'THr',
                    -Values  => \@hours,
                    -default => $lhour,
                ),
                "\n", ":",
                $q->popup_menu(
                    -name    => 'TMin',
                    -Values  => \@mins,
                    -default => $lmin,
                ),
                "\n", ":",
                $q->popup_menu(
                    -name    => 'TSec',
                    -Values  => \@secs,
                    -default => $lsec,
                ),
                "\n",
            ),
            "\n",
        )
        ),
        "\n";
    print $q->submit( -name => 'ok', -value => " OK " );
    $q->end_form;
    return;
}

1;

__END__

=head1 SEE ALSO

L<perfSONAR_PS::OWP::Utils>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: Navigation.pm 1877 2008-03-27 16:33:01Z aaron $

=head1 AUTHOR

Ali Asad Lotia
Jeff Boote, boote@internet2.edu
Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2002-2008, Internet2

All rights reserved.

=cut
	

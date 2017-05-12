package URL::Check;

$URL::Check::VERSION   = '0.11';
$URL::Check::AUTHORITY = 'cpan:ALEXMASS';

=head1 NAME

URL::Check - Check a list of URL and respond accordingly.

=head1 VERSION

Version 0.11

=cut

use 5.006;
use strict; use warnings;

use LWP::Simple qw/get/;
use Time::HiRes qw /gettimeofday/;

=head1 DESCRIPTION

This module is not aimed at being used directly but via the script C<url-check>.

    url-check --config=my-config.txt

If no C<--config argument> is set, the value is taken from environment variable C<URL_CHECK_CONFIG>.

More examples can be found in the C<t/resources/config> directory but consist
in default parameter (mailto etc., then each url to be tested can be followed
by dedicated test (time.delay, xpath etc.)

More info can be found L<here|http://alexandre-masselot.blogspot.com/2011/10/perl-url-checker.html>

=head1 METHODS

=head2 readConfig($file_name)

Read the config file. Default file name is taken from C<$URL_CHECK_FILE>

=cut

our %config;
our @report;

sub readConfig {
    my $configFile = shift || $ENV{URL_CHECK_CONFIG}
    || die "ERROR: No config file is passed or env URL_CHECK_CONFIG is set.\n";

    my $FD;
    open ($FD, "<$configFile")
        || die "ERROR: Cannot open config file [$configFile]: $!\n";

    p_clearConfig();

    # $currenturl will contain at first the default map for handling error,
    # then, when a url is encountered, it will contain the url's error handlers
    my $currentUrl;
    while (my $line = <$FD>) {
        $line=~s/^#.*//;		# remove comments
        $line=~s/\s*$//;		# end of line spaces
        next unless $line =~/\S/;	# skip emplty lines

        if ($line=~/^onerror/i) {
            p_addOnErrorLine($line, $currentUrl || $config{default});
            next;
        }

        if ($line=~/^check/i) {
            p_addCheckLine($line, $currentUrl);
            next;
        }

        if ($line=~/^(ftp|http|file):\/\//i) {
            $currentUrl = p_addUrl($line);
            next;
        }

        die "ERROR: Cannot parse line: $line\n";
    }

    close($FD);
}

=head2 run()

Run the configured tests, and store the result into the local @report

=cut

sub run {

    undef @report;
    foreach my $urlConfig (@{$config{urls}}) {
      push @report, p_runOneUrl($urlConfig);
    }
}

=head2 submitReport(%report)

Print on console or send by mail the error output

=cut

sub submitReport {
    my %report = @_;

    if ($config{default}{onError}{console}) {
        print "ERROR REPORT: $report{subject}\n$report{contents}\n";
    }

    if ($config{default}{onError}{mailto}) {
        require  Mail::Sendmail;
        my $hostname  = `hostname`;
        chomp $hostname;
        my %mail = (
            To      => join(',', @{$config{default}{onError}{mailto}}),
            Subject => "[url-check] $report{subject}",
            From    => "url.check\@$hostname",
            Message => "$report{contents}\n",
        );

        warn "sending error report by mail: $report{subject}\n";
        Mail::Sendmail::sendmail(%mail) or die $Mail::Sendmail::error
    }
}

=head2 errorReport()

Build a map (subject => ..., content=> ...) with the errors after the run
return () if no error were detected

=cut

sub errorReport {
    my @errors = grep {! $_->{success}} @report;

    unless (@errors) {
        return ();
    }

    (
     subject  => ''.scalar(@errors).' errors reported',
     contents => join("\n", (map {$_->{url}." : ".$_->{message}} @errors))
    );
}

#
#
# PRIVATE METHODS

sub p_addOnErrorLine {
    my ($line, $conf) = @_;

    die "ERROR: Cannot parse error line: $line"
        unless $line=~/^onerror\.(.+?)=(.+)/i;

    my ($errorCat, $params) = ($1, $2);

    if ($errorCat eq 'mailto') {
        my @tmp = split(/,/, $params);
        $conf->{onError}{mailto}=\@tmp;
        return;
    }

    if ($errorCat eq 'console') {
        $conf->{onError}{console}= $params =~ /\s*(y(es)?|t(rue)?|1)\s*$/i;
        return;
    }

    die "ERROR: Unknown onerror type [$errorCat]\n";
}

sub p_addCheckLine {
    my ($line, $conf) = @_;

    die "ERROR: Cannot parse error line: $line\n"
        unless $line=~/^check\.(.+?)=(.+)/i;

    my ($cat, $params) = ($1, $2);

    if ($cat eq 'contains') {
        push @{ $conf->{check}{contains}}, $params ;
        return;
    }

    $conf->{check}{$cat} = $params
}

sub p_addUrl {
    my ($line) = @_;

    my $h = {
        url   => $line,
        check => {}
    };

    push @{$config{urls}}, $h;
    return $h;
}

sub p_clearConfig {

    %config = (
        default => { onError=>{} },
        urls    => [],
    );
}

sub p_runOneUrl {
    my %urlConfig = %{$_[0]};

    my $url              = $urlConfig{url};
    my ($sec0, $micros0) = gettimeofday;
    my $content          = get($url);

    unless ($content) {
        return {
	    url     => $url,
	    success => 0,
	    message => 'cannot load content'
        }
    }

    my ($sec1, $micros1) = gettimeofday;
    my $dtime = int(($sec1-$sec0)*1000 + ($micros1-$micros0)/1000);

    if ((exists $urlConfig{check}{overtime}) &&  ($urlConfig{check}{overtime} < $dtime)) {
        return {
	    url     => $url,
	    success => 0,
	    message => "overtime > $urlConfig{check}{overtime} (${dtime}ms)",
        }
    }

    if (exists $urlConfig{check}{contains}) {
        my @searchFor = @{$urlConfig{check}{contains}};
        foreach (@searchFor) {
            if (index($content, $_) < 0) {
                return {
                    url     => $url,
                    success => 0,
                    message => "does not contains \"$_\"",
	       }
            }
        }
    }

    return {
        url     => $url,
        success => 1
    };
}

=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot at gmail.com> >>

Currently maintained by Mohammad S Anwar (MANWAR) C<< <mohammad.anwar @ yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/URL-Check>

=head1 BUGS

Please report any bugs or feature requests to C<bug-url-check at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URL-Check>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URL::Check

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URL-Check>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URL-Check>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URL-Check>

=item * Search CPAN

L<http://search.cpan.org/dist/URL-Check/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Alexandre Masselot.

This program is free software; you can redistribute it and/or modify it under the
terms of either: the GNU General Public License as published by the Free Software
Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of URL::Check

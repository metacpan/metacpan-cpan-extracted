#!/usr/bin/perl -w
use strict;
$| = 1;

use vars qw( $VERSION );
$VERSION = '0.017';

use Cwd;
use File::Spec;
my $findbin;
use File::Basename;
BEGIN { $findbin = File::Spec->rel2abs( dirname $0 ); }
use lib File::Spec->catdir( $findbin, 'lib' );
use lib File::Spec->catdir( $findbin, 'lib', 'inc' );
use lib $findbin;
use lib File::Spec->catdir( $findbin, 'inc' );
use Test::Smoke::Reporter;
use Test::Smoke::Mailer;
use Test::Smoke;
use Test::Smoke::Util qw( do_pod2usage );

use Getopt::Long;
my %opt = (
    type         => undef,
    ddir         => undef,
    to           => undef,
    cc           => undef,
    ccp5p_onfail => undef,
    from         => undef,
    mserver      => undef,
    msuser       => undef,
    mspass       => undef,
    v            => undef,

    smokedb_url => undef,
    ua_timeout  => undef,

    rptfile    => 'mktest.rpt',
    jsnfile    => 'mktest.jsn',
    mail       => 0,
    report     => 1,
    defaultenv => undef,
    config     => undef,
    help       => 0,
    man        => 0,
);

my $defaults = Test::Smoke::Mailer->config( 'all_defaults' );

=head1 NAME

sendrpt.pl - Send the smoke report by protocol

=head1 SYNOPSIS

    $ ./sendrpt.pl -u URL -d ../perl-current [more options]

or

    $ ./sendrpt.pl -c [smokecurrent_config]

=head1 OPTIONS

Options depend on the B<type> option, exept for some.

=over 4

=item * B<Configuration file>

    -c | --config <configfile> Use the settings from the configfile

F<sendrpt.pl> can use the configuration file created by F<configsmoke.pl>.
Other options can override the settings from the configuration file.

=item * B<General options>

    -d | --ddir <directory>  Set the directory for the source-tree (cwd)
    --to <emailaddresses>    Comma separated list (smokers-reports@perl.org)
    --cc <emailaddresses>    Comma separated list

    -t | --type <type>       mail mailx sendmail sendemail Mail::Sendmail
                             [mandatory]

    --nomail                 Don't send the message
    --report                 Create a report anyway
    --defaultenv             It was a PERLIO-less smoke
    --[no]ccp5p_onfail       Do (not) send failure reports to perl5-porters

    -v | --verbose <0..2>    Set verbose level
    -h | --help              Show help message (needs Pod::Usage)
    --man                    Show the perldoc  (needs Pod::Usage)


=back

=head1 DESCRIPTION

This is a small front-end for L<Test::Smoke::Mailer>.

=cut

my $my_usage = "Usage: $0 -t <type> -d <directory> [options]";
GetOptions(
    \%opt => qw(
        type|t=s
        ddir|d=s
        to=s      cc=s      bcc=s     swcc=s swbcc=s
        mserver=s msuser=s  mspass=s

        ccp5p_onfail!
        v|verbose=i

        smokedb_url|u=s

        help|h         man

        config|c:s     rptfile|r=s

        mail|email! report! defaultenv!
    )
) or do_pod2usage(
    verbose => 1,
    myusage => $my_usage
);

$opt{ man} and do_pod2usage( verbose => 2, exitval => 0, myusage => $my_usage);
$opt{help} and do_pod2usage( verbose => 1, exitval => 0, myusage => $my_usage);

if ( defined $opt{config} ) {
    $opt{config} eq "" and $opt{config} = 'smokecurrent_config';
    read_config( $opt{config} ) or do {
        my $config_name = File::Spec->catfile( $findbin, $opt{config} );
        read_config( $config_name );
    };

    unless ( Test::Smoke->config_error ) {
        foreach my $option ( keys %opt ) {
            next if defined $opt{ $option };
            if ( $option eq 'type' ) {
                $opt{type} ||= $conf->{mail_type};
            } elsif ( exists $conf->{ $option } ) {
                $opt{ $option } ||= $conf->{ $option }
            }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

$opt{ddir} && -d $opt{ddir} or do_pod2usage( verbose => 0 );

my $has_report = check_for_report();
if ($has_report && $opt{mail}) {
    my $mailer = Test::Smoke::Mailer->new( $opt{type} => \%opt );
    $mailer->mail;
}

my $json = check_for_json();
if ($json && $opt{smokedb_url}) {
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new(
        agent => "Test::Smoke/$Test::Smoke::VERSION",
        (
            defined $opt{ua_timeout}
                ? (timeout => $opt{ua_timeout})
                : ()
        ),
    );
    $opt{v} and print "Posting to SmokeDB ($opt{smokedb_url})\n";
    my $response = eval {$ua->post($opt{smokedb_url}, {json => $json})};
    print $@ if $@
    $opt{v} and print $response->content;
}

# Basically: call mkovz.pl unless -f <builddir>/mktest.rpt
sub check_for_report {

    my $report = File::Spec->catfile( $opt{ddir}, $opt{rptfile} );

    if ( -f $report ) {
        $opt{v} and print "Found [$report]\n";
        $opt{report} or return 1;
    } else {
        $opt{v} and print "No report found in [$opt{ddir}].\n";
    }

    my $reporter = Test::Smoke::Reporter->new( $conf );
    if ( defined $reporter->{_outfile} ) {
        $reporter->write_to_file;

        if (!-f $report) {
            die "Hmmm... cannot find [$report]";
        }
        return 1;
    } else {
        $opt{v} and print "Skipped, no .out-file\n";
        return;
    }
}

sub check_for_json {
    my $jsnfile = File::Spec->catfile($opt{ddir}, $opt{jsnfile});
    if (-f $jsnfile) {
        $opt{v} and print "Found [$jsnfile]\n";
        if (! $opt{report}) {
            open my $jsn, '<', $jsnfile or die "Cannot open($jsnfile): $!";
            my $json = do {local $/; <$jsn> };
            close $jsn;
            $opt{v} and print "Using JSON from '$jsnfile'\n";
            return $json;
        }
        else {
            $opt{v} and print "Not reusing existing JSON, regenerate\n";
        }
    }
    else {
        $opt{v} and print "No JSON found in [$opt{ddir}]\n";
    }

    my $reporter = Test::Smoke::Reporter->new($conf);
    return $reporter->smokedb_data();
}

=head1 SEE ALSO

L<Test::Smoke::Mailer>, L<Test::Smoke::Reporter>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

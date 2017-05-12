#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
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
    to           => undef, #'smokers-reports@perl.org',
    cc           => undef,
    ccp5p_onfail => undef,
    from         => undef,
    mserver      => undef,
    msport       => 25,
    msuser       => undef,
    mspass       => undef,
    v            => undef,

    rptfile      => 'mktest.rpt',
    mail         => 1,
    report       => undef,
    defaultenv   => undef,
    config       => undef,
    help         => 0,
    man          => 0,
);

my $defaults = Test::Smoke::Mailer->config( 'all_defaults' );

my %valid_type = map { $_ => 1 } qw( mail mailx sendmail sendemail
                                     Mail::Sendmail MIME::Lite );

=head1 NAME

mailrpt.pl - Send the smoke report by mail

=head1 SYNOPSIS

    $ ./mailrpt.pl -t mailx -d ../perl-current [more options]

or

    $ ./mailrpt.pl -c [smokecurrent_config]

=head1 OPTIONS

Options depend on the B<type> option, exept for some.

=over 4

=item * B<Configuration file>

    -c | --config <configfile> Use the settings from the configfile

F<mailrpt.pl> can use the configuration file created by F<configsmoke.pl>.
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


=item * B<options for> -t mail/mailx

no extra options

=item * B<options for> -t sendmail

    --from <address>

=item * B<options for> -t sendemail

    --from <address>
    --mserver <smtpserver>  (localhost)
    --muser <smtpserverusername>
    --mpass <smtpserverpassword>

=item * B<options for> -t Mail::Sendmail | MIME::Lite

    --from <address>
    --mserver <smtpserver>  (localhost)

=back

=head1 DESCRIPTION

This is a small front-end for L<Test::Smoke::Mailer>.

=cut

my $my_usage = "Usage: $0 -t <type> -d <directory> [options]";
GetOptions( \%opt,
    'type|t=s', 'ddir|d=s', 'to=s', 'cc=s', 'bcc=s', 'ccp5p_onfail!',
    'v|verbose=i',

    'from=s', 'mserver=s', 'msport=i', 'msuser=s', 'mspass=s',

    'help|h', 'man',

    'config|c:s', 'rptfile|r=s',

    'mail|email!', 'report!', 'defaultenv!',
) or do_pod2usage( verbose => 1, myusage => $my_usage );

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

foreach( keys %$defaults ) {
    next if defined $opt{ $_ };
    $opt{ $_ } = defined $conf->{ $_ } ? $conf->{ $_ } : $defaults->{ $_ };
}

if ( $opt{mail} ) {
    exists $valid_type{ $opt{type} } or do_pod2usage( verbose => 0 );
}

$opt{ddir} && -d $opt{ddir} or do_pod2usage( verbose => 0 );

my $cont = check_for_report();

if ( $cont && $opt{mail} ) {
    my $mailer = Test::Smoke::Mailer->new( $opt{type} => \%opt );
    $mailer->mail;
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
    
        unless ( -f $report ) {
            die "Hmmm... cannot find [$report]";
        }
        return 1;
    } else {
        $opt{v} and print "Skipped, no .out-file\n";
        return;
    }
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

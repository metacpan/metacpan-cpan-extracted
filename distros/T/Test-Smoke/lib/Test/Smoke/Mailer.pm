package Test::Smoke::Mailer;
use warnings;
use strict;
use Carp;

our $VERSION = '0.016';

use Test::Smoke::Mailer::Sendmail;
use Test::Smoke::Mailer::Mail_X;
use Test::Smoke::Mailer::SendEmail;
use Test::Smoke::Mailer::Mail_Sendmail;
use Test::Smoke::Mailer::MIME_Lite;

=head1 NAME

Test::Smoke::Mailer - Factory for objects to send the report.

=head1 SYNOPSIS

    use Test::Smoke::Mailer;

    my %args = ( mhowto => 'smtp', mserver => 'smtp.your.domain' );
    my $mailer = Test::Smoke::Mailer->new( $ddir, %args );

    $mailer->mail or die "Problem in mailing: " . $mailer->error;

=head1 DESCRIPTION

This little wrapper still allows you to use the B<sendmail>, B<sendemail>,
B<mail> or B<mailx> programs, but prefers to use the B<Mail::Sendmail>
module (which comes with this distribution) to send the reports.

=head1 METHODS

=head2 Test::Smoke::Mailer->new( $mailer[, %args] )

Can we provide sensible defaults for the mail stuff?

    mhowto  => [Module::Name|sendmail|mail|mailx|sendemail]
    mserver => an SMTP server || localhost
    mbin    => the full path to the mail binary
    mto     => list of addresses (comma separated!)
    mfrom   => single address
    mcc     => list of addresses (coma separated!)

=cut

our $P5P       = 'perl5-porters@perl.org';
our $NOCC_RE   = ' (?:PASS\b|FAIL\(X\))';
my %CONFIG = (
    df_mailer        => 'Mail::Sendmail',
    df_ddir          => undef,
    df_v             => 0,
    df_rptfile       => 'mktest.rpt',
    df_to            => 'daily-build-reports@perl.org',
    df_from          => '',
    df_cc            => '',
    df_swcc          => '-c',
    df_swbcc         => '-b',
    df_bcc           => '',
    df_ccp5p_onfail  => 0,
    df_mserver       => 'localhost',
    df_msuser        => undef,
    df_mspass        => undef,

    df_mailbin       => 'mail',
    mail             => [qw( bcc cc mailbin )],

    df_mailxbin      => 'mailx',
    mailx            => [qw( bcc cc mailxbin swcc swbcc )],

    df_sendemailbin  => 'sendemail',
    sendemail        => [qw( from bcc cc sendemailbin mserver msuser mspass )],

    df_sendmailbin   => 'sendmail',
    sendmail         => [qw( from bcc cc sendmailbin )],
    'Mail::Sendmail' => [qw( from bcc cc mserver )],
    'MIME::Lite'     => [qw( from bcc cc mserver msuser mspass )],

    valid_mailer     => {
        sendmail         => 1,
        mail             => 1,
        mailx            => 1,
        sendemail        => 1,
        'Mail::Sendmail' => 1,
        'MIME::Lite'     => 1,
    },
);

sub  new {
    my $class = shift;

    my $mailer = shift || $CONFIG{df_mailer};

    if (! exists $CONFIG{valid_mailer}->{ $mailer } ) {
        croak( "Invalid mailer '$mailer'" );
    };

    my %args_raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

    my %args = map {
        ( my $key = $_ ) =~ s/^-?(.+)$/lc $1/e;
        ( $key => $args_raw{ $_ } );
    } keys %args_raw;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } ( rptfile => v => ddir => to => ccp5p_onfail => @{ $CONFIG{ $mailer } } );
    $fields{ddir} = File::Spec->rel2abs( $fields{ddir} );

    DO_NEW: {
        local $_ = $mailer;

        /^sendmail$/ && do {
            return Test::Smoke::Mailer::Sendmail->new(%fields);
        };
        /^mailx?$/ && do {
            return Test::Smoke::Mailer::Mail_X->new(%fields);
        };
        /^sendemail?$/ && do {
            return Test::Smoke::Mailer::SendEmail->new(%fields);
        };
        /^Mail::Sendmail$/ && do {
            return Test::Smoke::Mailer::Mail_Sendmail->new(%fields);
        };
        /^MIME::Lite$/ && do {
            return Test::Smoke::Mailer::MIME_Lite->new(%fields);
        };
    }

}

=head2 Test::Smoke::Mailer->config( $key[, $value] )

C<config()> is an interface to the package lexical C<%CONFIG>,
which holds all the default values for the C<new()> arguments.

With the special key B<all_defaults> this returns a reference
to a hash holding all the default values.

=cut

sub config {
    my $dummy = shift;

    my $key = lc shift;

    if ( $key eq 'all_defaults' ) {
        my %default = map {
            my( $pass_key ) = $_ =~ /^df_(.+)/;
            ( $pass_key => $CONFIG{ $_ } );
        } grep /^df_/ => keys %CONFIG;
        return \%default;
    }

    return undef unless exists $CONFIG{ "df_$key" };

    $CONFIG{ "df_$key" } = shift if @_;

    return $CONFIG{ "df_$key" };
}

=head1 COPYRIGHT

(c) 2002-2013, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

package Test::Smoke::Mailer::Base;
use warnings;
use strict;

use Test::Smoke::Util qw( parse_report_Config );

=head1 NAME

Test::Smoke::Mailer::Base - baseclass for Mailers

=head1 DESCRIPTION


=cut

our $P5P       = 'perl5-porters@perl.org';
our $NOCC_RE   = ' (?:PASS\b|FAIL\(X\))';

=head2 Test::Smoke::Mailer::Base->new()

constructor.

=cut

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

=head2 $mailer->fetch_report( )

C<fetch_report()> reads B<mktest.rpt> from C<{ddir}> and return the
subject line for the mail-message.

=cut

sub fetch_report {
    my $self = shift;

    $self->{file} = File::Spec->catfile( $self->{ddir}, $self->{rptfile} );

    local *REPORT;
    if ( open REPORT, "< $self->{file}" ) {
        $self->{body} = do { local $/; <REPORT> };
        close REPORT;
    } else {
        require Carp;
        Carp::croak( "Cannot read '$self->{file}': $!" );
    }

    my @config = parse_report_Config( $self->{body} );

    return sprintf "Smoke [%s] %s %s %s %s (%s)", @config[6, 1, 5, 2, 3, 4];
}

=head2 $mailer->error( )

C<error()> returns the value of C<< $mailer->{error} >>.

=cut

sub error {
    my $self = shift;

    return $self->{error} || '';
}

=head2 $self->_get_cc( $subject )

C<_get_cc()> implements the C<--ccp5p_onfail> option. It looks at the
subject to see if the smoke FAILed and then adds the I<perl5-porters>
mailing-list to the C<Cc:> field unless it is already part of C<To:>
or C<Cc:>.

The new behaviour is to only return C<Cc:> on fail. This is determined
by the new global regex kept in C<< $Test::Smoke::Mailer::NOCC_RE >>.

=cut

sub _get_cc {
    my( $self, $subject ) = @_;
    return "" if $subject =~ m/$Test::Smoke::Mailer::NOCC_RE/;

    return $self->{cc} || "" unless $self->{ccp5p_onfail};

    my $p5p = $Test::Smoke::Mailer::P5P or return $self->{cc};
    my @cc = $self->{cc} ? $self->{cc} : ();

    push @cc, $p5p unless $self->{to} =~ /\Q$p5p\E/ ||
                          $self->{cc} =~ /\Q$p5p\E/;
    return join ", ", @cc;
}


1;

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

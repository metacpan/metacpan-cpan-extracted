package Test::Smoke::App::SmokeStatus;
use warnings;
use strict;

our $VERSION = '0.001';

use base 'Test::Smoke::App::Base';

use POSIX qw/ strftime /;
use File::Spec::Functions;
use Test::Smoke::BuildCFG;
use Test::Smoke::Reporter;

=head1 NAME

Test::Smoke::App::SmokeStatus - Guess the status of the current smoke.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    return $self;
}

=head2 run

Analyse the report...

=cut

sub run {
    my $self = shift;

    my $report = $self->parse_out();
    return $self->guess_status if !$report;

    return $self->report_status($report);

}

sub report_status {
    my $self = shift;
    my ($rpt) = @_;

    my $bcfg = Test::Smoke::BuildCFG->new($self->option('cfg'));
    my $ccnt = 0;
    Test::Smoke::skip_config($_) or $ccnt++ for $bcfg->configurations;

    my $todo = $ccnt - $rpt->{ccount};
    my $est_curr = $rpt->{avg} > 0
        ? $rpt->{avg} - ( $rpt->{rtime} - $rpt->{ccount}*$rpt->{avg} ) : 0;
    my $est_todo = $todo > 0 && $rpt->{avg} > 0
        ? ( (($todo - 1) * $rpt->{avg}) + $est_curr ) : 0;
    $est_todo > $todo * $rpt->{avg} and $est_todo = $todo * $rpt->{avg};
    my $killtime = calc_timeout( $conf->{killtime}, $rpt->{started} )
        ? timeout_msg( $conf->{killtime}, $rpt->{started } )
        : "";

    my $todo_time = $rpt->{avg} <= 0  ? '.' :
        $est_todo <= 0
            ? has_lck( $config )
                ? ", smoke looks hanging delay " . time_in_hhmm( -$est_todo )
                : ", smoke looks terminated${killtime}."
            : ", estimated completion in " . time_in_hhmm( $est_todo );


    my $status = sprintf(
        "  Change number %s started on %s.\n",
        $rpt->{patch},
        strftime("%Y %m %d %H:%M:%S%z", localtime($rpt->{started}))
    );
    $status .= sprintf(
        "    %u out of %u configurations finished%s\n",
        $rpt->{ccount}, $ccnt,
        $rpt->{ccount} ? " in $rpt->{time}." : "."
    );
    $status .= sprintf(
        "    %u configuration%s showed failures%s.\n",
        $rpt->{fail}
        ($rpt->{fail} == 1 ? "" : "s"),
        $rpt->{stat} ? " ($rpt->{stat})":""
    ) if $rpt->{ccount};
    $status .= sprintf(
        "    %u failure%s in the running configuration.\n",
        $rpt->{running},
        ($rpt->{running} == 1 ? "" : "s")
    ) if exists $rpt->{running};
    $status .= sprintf(
        "    %u configuration%s to finish$todo_time\n",
        $todo, $todo == 1 ? "" : "s"
    ) if $todo;
    $status .= sprintf(
        "    Average smoke duration: %s.\n",
        time_in_hhmm( $rpt->{avg} )
    ) if $rpt->{ccount};

    print "\n$status\n";
}

=head2 parse_out($bldconfigs)

Uses the L<Test::Smoke::Reporter> object to parse the current B<outfile>.

=cut

sub parse_out {
    my $self = shift;
    my $outfile = catfile($self->option('ddir'), $self->option('out'));

    return if ! -f $outfile;

    my $reporter = Test::Smoke::Reporter->new(
        $self->options,
        v => $self->option('verbose')
    );
    my %rpt = %{ $reporter->{_rpt} };
}

1;

=head1 COPYRIGHT

(c) 2002-2021, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

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

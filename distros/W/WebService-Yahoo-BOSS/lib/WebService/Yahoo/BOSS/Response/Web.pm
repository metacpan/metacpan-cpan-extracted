package WebService::Yahoo::BOSS::Response::Web;

=head1 NAME

WebService::Yahoo::BOSS::Response::Web

=cut

use Moo;

use Carp qw(croak);

has 'abstract' => ( is => 'rw', required => 1 );
has 'date'     => ( is => 'ro', required => 1 );
has 'dispurl'  => ( is => 'ro', required => 1 );
has 'title'    => ( is => 'rw', required => 1 );
has 'url'      => ( is => 'ro', required => 1 );
has 'clickurl' => ( is => 'ro', required => 1 );

sub parse {
    my ($class, $bossresponse) = @_;

    my $web = $bossresponse->{web}
        or croak "bossresponse doesn't contain a 'web' data: @{[ keys %$bossresponse ]}";

    my @webresults;
    foreach my $result ( @{ $web->{results} } ) {
        push @webresults, $class->new($result);
    }

    return {
        count        => $web->{count},
        totalresults => $web->{totalresults},
        start        => $web->{start},
        results      => \@webresults,
    };
}


1;

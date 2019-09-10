package Mojo::Debugbar::Storage::DBIx;
use Mojo::Base "DBIx::Class::Storage::Statistics";

use Devel::StackTrace;
use Time::HiRes qw( time );

has 'app_name' => '';
has 'callback' => sub {
    sub {
        # do nothing by default
    }
};
has 'recorder';
has 'trace' => 1;
has 'query';

=head2 query_start
    When a query is started, store the query
=cut

sub query_start {
    my ($self, $string, @bind) = @_;

    $self->SUPER::query_start($string, @bind);

    my $sql = $string;

    foreach my $param (@bind) {
        $sql =~ s/\?/$param/;
    }

    my @frames;

    if ($self->trace) {
        my $app_name = $self->app_name;

        my $trace = Devel::StackTrace->new(
            filter_frames_early => 1,
            frame_filter        => sub {
                my $filename = shift->{ caller }->[1];

                return ($filename =~ /($app_name|template)/ && $filename !~ /Debugbar/) ? 1 : 0;
            }
        );

        @frames = $trace->frames;
    }

    $self->query({ string => $string, sql => $sql, params => \@bind, started_at => time(), frames => \@frames });
}

=head2 query_end
    After a query was executed, update the query log
=cut

sub query_end {
    my ($self, $string) = @_;

    $self->SUPER::query_end($string);

    my $query = $self->query;

    $query->{ ended_at } = time();
    $query->{ duration } = sprintf("%.4f", $query->{ ended_at } - $query->{ started_at });
    

    $self->query($query);

    $self->recorder->($self->query);
}

1;

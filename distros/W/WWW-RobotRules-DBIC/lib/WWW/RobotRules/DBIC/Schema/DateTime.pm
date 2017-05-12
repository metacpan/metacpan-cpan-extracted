package WWW::RobotRules::DBIC::Schema::DateTime;
use DateTime;

sub insert {
    my $self = shift;
    my $dt = DateTime->now;
    $dt->set_time_zone('local');
    $self->store_column('created_on', $dt->strftime('%Y-%m-%d %H:%M:%S'))
        if $self->result_source->has_column('created_on');
    $self->next::method(@_);
}

1;


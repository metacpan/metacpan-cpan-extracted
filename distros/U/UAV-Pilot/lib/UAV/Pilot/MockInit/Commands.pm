
sub uav_module_init
{
    my ($pack, $cmd, $args) = @_;
    $UAV::Pilot::mock_init_set = $$args{setting};
    return 1;
}


sub mock_init ()
{
    return 1;
}

1;

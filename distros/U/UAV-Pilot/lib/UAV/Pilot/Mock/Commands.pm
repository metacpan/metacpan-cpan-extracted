use v5.14;

use File::Glob; # To test that we can load other modules here

sub mock ()
{
    return 1;
}

sub uav_module_quit ()
{
    $main::DID_QUIT = 1;
}

1;

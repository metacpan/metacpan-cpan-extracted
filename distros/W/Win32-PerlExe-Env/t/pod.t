# ==============================================================================
# $Id: pod.t 485 2006-09-08 22:54:18Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Pod Test of Win32::PerlExe::Env
# ==============================================================================

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-PerlExe-Env.t'

#########################

    # -- Module Pod Test
    #    Win32::PerlExe::Env

    use Test::More;
    eval "use Test::Pod 1.00";
    plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
    all_pod_files_ok();

#########################

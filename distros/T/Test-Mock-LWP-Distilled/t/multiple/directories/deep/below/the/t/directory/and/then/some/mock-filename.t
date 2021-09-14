#!/usr/bin/env perl
# If you run tests multiple directories below a t/ directory, the path for the mocks
# is adjusted accordingly.

use strict;
use warnings;
use lib::abs '../../../../../../../../../../lib';

use File::Spec;
use Test::More;

use Simple::Mock::Class;

my $mock_object = Simple::Mock::Class->new(base_dir => File::Spec->tmpdir);
is $mock_object->mock_filename,
    File::Spec->catfile(File::Spec->tmpdir, 'directory', 'and', 'then', 'some', 
    'mock-filename-simple-mock.json'),
    'Our mock filename is derived from our path, with the latest t/ directory acting as the root';

done_testing();

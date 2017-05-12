use 5.008001;
use strict;
use warnings;
use Test::More;

plan tests => 13;

{

    package Foo;
    use Test::More;

    use recommended 'File::Spec';

    ok( recommended->has('File::Spec'), "has File::Spec" );

    use recommended 'Devel::Peek',
      {
        'IO::File'   => 1,
        'File::Temp' => 999,
      },
      'Acme::DoesNotExistNotInstalled';

    ok( !$INC{'Devel/Peek.pm'}, "Devel::Peek not yet loaded" );

    ok( recommended->has('Devel::Peek'), "has recommended Devel::Peek" );
    ok( recommended->has('IO::File'),    "has recommended IO::File 1" );
    ok( !recommended->has('File::Temp'), "doesn't have recommended File::Temp 999" );
    ok(
        !recommended->has('Acme::DoesNotExistNotInstalled'),
        "doesn't have recommended Acme::DoesNotExistNotInstalled"
    );

    ok( recommended->has( 'File::Temp', 0 ), "has recommended File::Temp 0" );

    use suggested 'File::Copy';

    ok( suggested->has('File::Copy'), "has suggested File::Copy" );
    ok( !suggested->has('IO::File'),  "IO::File was not suggested" );

}

{

    package Bar;
    use Test::More;

    use recommended 'File::Temp';

    ok( recommended->has('File::Temp'), "other package has recommended File::Temp 0" );
    ok( !recommended->has('Devel::Peek'),
        "other package doesn't have recommended Devel::Peek" );
    ok( !suggested->has('File::Copy'),
        "other package doesn't have recommended File::Copy" );

    my $use_if = eval "use if recommended->has('File::Basename'), 'Pod::Usage';";
    my $err    = $@;
    ok( !$INC{'Pod/Usage.pm'}, "Pod::Usage not loaded from 'use if ...'" );
    diag $err if $err;
}

done_testing;
#
# This file is part of recommended
#
# This software is Copyright (c) 2014 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et:

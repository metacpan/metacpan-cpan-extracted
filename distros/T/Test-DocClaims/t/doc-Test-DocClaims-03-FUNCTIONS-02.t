#!perl

use strict;
use warnings;
use Test::More tests => 7;

use lib "t/lib";
use TestTester;

BEGIN { use_ok('Test::DocClaims'); }

=head2 all_doc_claims [ I<DOC_DIRS> [ I<TEST_DIRS> ] ]

This is the easiest way to test the documentation claims.
It automatically searches for documentation and then locates the
corresponding test file or files.
By default, it searches the lib, bin and scripts directories and their
subdirectories for documentation.
For each of these files it looks in (by default) the t
directory for one or more matching files.
It does this with the following patterns, where PATH is the path of the
documentation file with the suffix removed (e.g., .pm or .pl) and slashes
(/) converted to dashes (-).
The patterns are tried in this order until one matches.

  doc-PATH-[0-9]*.t
  doc-PATH.t
  PATH-[0-9]*.t
  PATH.t

If none of the patterns match, the left most directory of the PATH is
removed and the patterns are tried again.
This is repeated until a match is found or the PATH is exhausted.
If the pattern patches multiple files, these files are processed in
alphabetical order and their documentation is concatenated to match against
the documentation file.

=cut

is( plan_count(), "no plan" );

findings_match( sub {
    all_doc_claims();
}, [
    ["ok", "doc claims in bin/dosomething.pl"],
    ["ok", "doc claims in lib/Foo/Bar01.pm"],
    ["ok", "doc claims in lib/Foo/Bar02.pm"],
    ["ok", "doc claims in lib/Foo/Bar03.pm"],
    ["ok", "doc claims in lib/Foo/Bar04.pm"],
    ["ok", "doc claims in lib/Foo/Bar05.pm"],
    ["ok", "doc claims in lib/Foo/Bar06.pm"],
    ["ok", "doc claims in lib/Foo/Bar07.pm"],
    ["ok", "doc claims in lib/Foo/Bar08.pm"],
    ["ok", "doc claims in lib/Foo/Bar09.pm"],
    ["ok", "doc claims in lib/Foo/Bar10.pm"],
    ["ok", "doc claims in lib/Foo/Bar11.pm"],
    ["ok", "doc claims in lib/Foo/Bar12.pm"],
    ["ok", "doc claims in scripts/util.pl"],
]);

is( plan_count(), 14 );
reset_plan_count();

=pod

If I<DOC_DIRS> is missing or undef, its default value of
[qw< lib bin scripts >] is used.
If I<TEST_DIRS> is missing or undef, its default value of
[qw< t >] is used.

When searching for documentation files, any file with one of these suffixes
is used:

   *.pl
   *.pm
   *.pod
   *.md

Also, any file who's first line matches /^#!.*perl/i is used.

The number of tests run is determined by the number of documentation files
found.
Do not set the number of tests before calling all_doc_claims because it
will do that automatically.

=cut

is( plan_count(), "no plan" );

findings_match( sub {
    all_doc_claims( [ "dir2" ], [ "t2" ] );
}, [
    ["ok", "doc claims in dir2/Foo1.pm"],
    ["ok", "doc claims in dir2/Foo2.pl"],
    ["ok", "doc claims in dir2/Foo3.pod"],
    ["ok", "doc claims in dir2/Foo4.md"],
    ["ok", "doc claims in dir2/Foo7"],
]);

is( plan_count(), 5 );
reset_plan_count();

=head1 SEE ALSO

L<Devel::Coverage>,
L<POD::Tested>,
L<Test::Inline>.
L<Test::Pod>,
L<Test::Pod::Coverage>,
L<Test::Pod::Snippets>,
L<Test::Synopsis>,
L<Test::Synopsis::Expectation>.

=head1 AUTHOR

Scott E. Lee, E<lt>ScottLee@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2016 by Scott E. Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__

FILE:<bin/dosomething.pl>------------------------------
=head2 dosomething
FILE:<scripts/util.pl>------------------------------
=head2 util 1
=head2 util 2
=head2 util 3
=head2 util 4

FILE:<t/bin-dosomething.t>------------------------------
=head2 dosomething
FILE:<t/scripts-util-1.t>------------------------------
=head2 util 1
FILE:<t/scripts-util-2.t>------------------------------
=head2 util 2
FILE:<t/scripts-util-3.t>------------------------------
=head2 util 3
FILE:<t/scripts-util-4.t>------------------------------
=head2 util 4

FILE:<lib/Foo/Bar01.pm>------------------------------
=head2 Bar01
FILE:<lib/Foo/Bar02.pm>------------------------------
=head2 Bar02
FILE:<lib/Foo/Bar03.pm>------------------------------
=head2 Bar03
FILE:<lib/Foo/Bar04.pm>------------------------------
=head2 Bar04
FILE:<lib/Foo/Bar05.pm>------------------------------
=head2 Bar05
FILE:<lib/Foo/Bar06.pm>------------------------------
=head2 Bar06
FILE:<lib/Foo/Bar07.pm>------------------------------
=head2 Bar07
FILE:<lib/Foo/Bar08.pm>------------------------------
=head2 Bar08
FILE:<lib/Foo/Bar09.pm>------------------------------
=head2 Bar09
FILE:<lib/Foo/Bar10.pm>------------------------------
=head2 Bar10
FILE:<lib/Foo/Bar11.pm>------------------------------
=head2 Bar11
FILE:<lib/Foo/Bar12.pm>------------------------------
=head2 Bar12

FILE:<t/doc-lib-Foo-Bar01-1.t>-------------------------------
=head2 Bar01
FILE:<t/doc-lib-Foo-Bar01.t>-------------------------------
=head2 this is the wrong file
FILE:<t/lib-Foo-Bar01-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/lib-Foo-Bar01.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Foo-Bar01-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Foo-Bar01.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar01-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar01.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar01-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar01.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar01-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar01.t>-------------------------------
=head2 this is the wrong file

FILE:<t/doc-lib-Foo-Bar02.t>-------------------------------
=head2 Bar02
FILE:<t/lib-Foo-Bar02-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/lib-Foo-Bar02.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Foo-Bar02-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Foo-Bar02.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar02-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar02.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar02-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar02.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar02-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar02.t>-------------------------------
=head2 this is the wrong file

FILE:<t/lib-Foo-Bar03-1.t>-------------------------------
=head2 Bar03
FILE:<t/lib-Foo-Bar03.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Foo-Bar03-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Foo-Bar03.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar03-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar03.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar03-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar03.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar03-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar03.t>-------------------------------
=head2 this is the wrong file

FILE:<t/lib-Foo-Bar04.t>-------------------------------
=head2 Bar04
FILE:<t/doc-Foo-Bar04-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Foo-Bar04.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar04-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar04.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar04-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar04.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar04-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar04.t>-------------------------------
=head2 this is the wrong file

FILE:<t/doc-Foo-Bar05-1.t>-------------------------------
=head2 Bar05
FILE:<t/doc-Foo-Bar05.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar05-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar05.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar05-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar05.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar05-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar05.t>-------------------------------
=head2 this is the wrong file

FILE:<t/doc-Foo-Bar06.t>-------------------------------
=head2 Bar06
FILE:<t/Foo-Bar06-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Foo-Bar06.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar06-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar06.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar06-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar06.t>-------------------------------
=head2 this is the wrong file

FILE:<t/Foo-Bar07-1.t>-------------------------------
=head2 Bar07
FILE:<t/Foo-Bar07.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar07-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar07.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar07-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar07.t>-------------------------------
=head2 this is the wrong file

FILE:<t/Foo-Bar08.t>-------------------------------
=head2 Bar08
FILE:<t/doc-Bar08-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/doc-Bar08.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar08-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar08.t>-------------------------------
=head2 this is the wrong file

FILE:<t/doc-Bar09-1.t>-------------------------------
=head2 Bar09
FILE:<t/doc-Bar09.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar09-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar09.t>-------------------------------
=head2 this is the wrong file

FILE:<t/doc-Bar10.t>-------------------------------
=head2 Bar10
FILE:<t/Bar10-1.t>-------------------------------
=head2 this is the wrong file
FILE:<t/Bar10.t>-------------------------------
=head2 this is the wrong file

FILE:<t/Bar11-1.t>-------------------------------
=head2 Bar11
FILE:<t/Bar11.t>-------------------------------
=head2 this is the wrong file

FILE:<t/Bar12.t>-------------------------------
=head2 Bar12



FILE:<dir2/Foo1.pm>-------------------------------
=head2 dir2/Foo1.pm
FILE:<dir2/Foo2.pl>-------------------------------
=head2 dir2/Foo2.pl
FILE:<dir2/Foo3.pod>-------------------------------
=head2 dir2/Foo3.pod
FILE:<dir2/Foo4.md>-------------------------------
=head2 dir2/Foo4.md
FILE:<dir2/Foo5.other>-------------------------------
=head2 dir2/Foo5.other
FILE:<dir2/Foo6>-------------------------------
=head2 dir2/Foo6
FILE:<dir2/Foo7>-------------------------------
#!perl
=head2 dir2/Foo7

FILE:<t2/Foo1.t>-------------------------------
=head2 dir2/Foo1.pm
FILE:<t2/Foo2.t>-------------------------------
=head2 dir2/Foo2.pl
FILE:<t2/Foo3.t>-------------------------------
=head2 dir2/Foo3.pod
FILE:<t2/Foo4.t>-------------------------------
=head2 dir2/Foo4.md
FILE:<t2/Foo5.t>-------------------------------
=head2 dir2/Foo5.other
FILE:<t2/Foo6.t>-------------------------------
=head2 dir2/Foo6
FILE:<t2/Foo7.t>-------------------------------
=head2 dir2/Foo7


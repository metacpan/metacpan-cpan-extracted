#! /usr/bin/perl -w
use strict;
$|++;

use File::Spec::Functions;
use FindBin;
use lib catdir($FindBin::Bin, 'lib');
use lib catdir($FindBin::Bin, updir(), 'lib');

use Test::Smoke::App::RunApp;
run_smoke_app("ConfigSmoke");

=head1 NAME

tsconfigsmoke.pl - Configure the Perl5 core tester suite (L<Test::Smoke>).

=head1 SYNOPSIS

    ../smoke/tsconfigsmoke.pl -c mysmoke

=head1 SEE ALSO

L<lib/configsmoke.pod> or L<HOWTO.md>

=cut

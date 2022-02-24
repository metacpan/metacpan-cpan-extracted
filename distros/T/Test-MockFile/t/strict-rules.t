#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< strict >;    # yeap it's strict

like dies { open( my $fh, ">", '/this/is/a/test' ) }, qr{Use of open to access unmocked file or directory},
  "Cannot open an unmocked file in strict mode";

note "add_strict_rule_for_filename";

Test::MockFile::add_strict_rule_for_filename( "/cherry" => 1 );
ok lives { open( my $fh, '>', '/cherry' ) },     "can open a file with a custom rule";
ok dies { open( my $fh, '>', '/cherry/abcd' ) }, "cannot open a file under the directory";

Test::MockFile::add_strict_rule_for_filename( "/another" => 1 );
foreach my $f (qw{/cherry /another}) {
    ok lives { open( my $fh, '>', $f ) }, "open $f with multiple rules";
}

Test::MockFile::clear_strict_rules();
ok dies { open( my $fh, '>', '/cherry' ) }, "clear_strict_rules removes all previous rules";

Test::MockFile::add_strict_rule_for_filename( qr{^/cherry} => 1 );
ok lives { open( my $fh, '>', '/cherry' ) },      "can open a file with a custom rule - regexp";
ok lives { open( my $fh, '>', '/cherry/abcd' ) }, "can open a file with a custom rule - regexp";

Test::MockFile::clear_strict_rules();

Test::MockFile::add_strict_rule_for_filename( [ qw{/foo /bar}, qr{^/cherry} ] => 1 );
ok lives { open( my $fh, '>', '/foo' ) },         "add_strict_rule_for_filename multiple rules";
ok lives { open( my $fh, '>', '/cherry/abcd' ) }, "add_strict_rule_for_filename multiple rules";

Test::MockFile::clear_strict_rules();

note "add_strict_rule_for_command";

ok dies { opendir( my $fh, '/whatever' ) }, "opendir fails without add_strict_rule_for_command";

Test::MockFile::add_strict_rule_for_command( 'opendir' => 1 );

ok lives { opendir( my $fh, '/whatever' ) }, "add_strict_rule_for_command";

Test::MockFile::clear_strict_rules();

Test::MockFile::add_strict_rule_for_command( qr{op.*} => 1 );

ok lives { opendir( my $fh, '/whatever' ) }, "add_strict_rule_for_command - regexp";
Test::MockFile::clear_strict_rules();

Test::MockFile::add_strict_rule_for_command( [ 'abcd', 'opendir' ] => 1 );

ok lives { opendir( my $fh, '/whatever' ) }, "add_strict_rule_for_command - list";
Test::MockFile::clear_strict_rules();

note "add_strict_rule_generic";

ok dies { open( my $fh, '>', '/cherry' ) }, "no rules setup";

my $context;
Test::MockFile::add_strict_rule_generic(
    sub {
        my ($ctx) = @_;

        $context = $ctx;

        return 1;
    }
);

ok lives { open( my $fh, '>', '/cherry' ) }, "add_strict_rule_generic";

if ( $^V >= 5.18.0 ) {    # behaving differently in 5.16 due to glob stuff...
    is $context, {
        'at_under_ref' => [
            D(),
            '>',
            '/cherry'
        ],
        'command'  => 'open',
        'filename' => '/cherry'
      },
      "context set for open" or diag explain $context;

}

ok lives { open( my $fh, '>', '/////cherry' ) }, "add_strict_rule_generic";
is $context->{filename}, '/cherry', "context uses normalized path";

my $is_exception;
Test::MockFile::clear_strict_rules();
Test::MockFile::add_strict_rule_generic( sub { $is_exception } );

ok dies { open( my $fh, '>', '/cherry' ) }, "add_strict_rule_generic - no exception";
$is_exception = 1;
ok lives { open( my $fh, '>', '/cherry' ) }, "add_strict_rule_generic - exception";

done_testing;

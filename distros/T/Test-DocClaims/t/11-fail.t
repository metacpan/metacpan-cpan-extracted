#!perl

use strict;
use warnings;
use lib "lib";
use Test::More tests => 3;
use lib "t/lib";
use TestTester;

BEGIN { use_ok("Test::DocClaims"); }

our %files = %{ files_from_data() };

{
local %files = %files;
$files{"Something/Foo.pm"} =~ s/example Perl module/example Perl module./;
findings_match( \%files, sub {
    doc_claims( "Something/Foo.pm", "t/90-DocClaims-Foo.t", "run test" );
}, [
    ["not ok", "run test"],
    "    at t/90-DocClaims-Foo.t line 9",
    "         got: 'Something::Foo - An example Perl module'",
    "    expected: 'Something::Foo - An example Perl module.'",
    "    at Something/Foo.pm line 8",
]);
}

{
local %files = %files;
$files{"t/90-DocClaims-Foo.t"} =~ s/example Perl module/example Perl module./;
findings_match( \%files, sub {
    doc_claims( "Something/Foo.pm", "t/90-DocClaims-Foo.t", "run test" );
}, [
    ["not ok", "run test"],
    "    at t/90-DocClaims-Foo.t line 9",
    "         got: 'Something::Foo - An example Perl module.'",
    "    expected: 'Something::Foo - An example Perl module'",
    "    at Something/Foo.pm line 8",
]);
}

__DATA__
FILE:<Something/Foo.pm>-------------------------------------------------------
package Foo;

use strict;
use warnings;

=head1 NAME

Something::Foo - An example Perl module

=head1 SYNOPSIS

  use Something::Foo;
  $foo = Something::Foo->new();
  $foo->dosomething();

=head1 DESCRIPTION

This module does something.

=head2 Constructor

=over 4

=item new [ I<STRING> ]

This method creates a new object.

=cut

sub new {
    my $class = shift;
    my $text = shift;
    my $self = bless { text => $text }, ref($class) || $class;
    return $self;
}

=back

=head1 BUGS

I was once told that all programs with more than ten lines have a bug.

=cut

1;
FILE:<t/90-DocClaims-Foo.t>---------------------------------------------------
#!perl

use strict;
use warnings;
use Test::More tests => 173;

=head1 NAME

Something::Foo - An example Perl module

=head1 SYNOPSIS

=begin DC_CODE

=cut

  use Something::Foo;
  $foo = Something::Foo->new();
  $foo->dosomething();

=end DC_CODE

=head1 DESCRIPTION

This module does something.

=cut

is($foo->dosomething, "results", "Foo does something");

=head2 Constructor

=over 4

=item new [ I<STRING> ]

This method creates a new object.

=cut

my $foo = Something::Foo->new("test");
isa_ok($foo, "Something::Foo", "constructor works");

=back

=head1 BUGS

I was once told that all programs with more than ten lines have a bug.

=cut

# ABSTRACT: Tools to test HTML/XML-based DOM representations
package Test2::Tools::DOM;

use v5.20;
use warnings;
use experimental qw( lexical_subs signatures );

use Carp ();
use Test2::API ();
use Test2::Compare ();
use Test2::Compare::Wildcard ();
use Test2::Tools::DOM::Check ();

our $VERSION = '0.004';

use Exporter 'import';
our @EXPORT = qw(
    all_text
    at
    attr
    content
    children
    dom
    find
    tag
    text
    val
);

sub dom :prototype(&) {
    Test2::Compare::build( 'Test2::Tools::DOM::Check', @_ );
}

my sub call ( $name, $args, $expect ) {
    Carp::croak 'Missing method name' unless $name;

    my $build = Test2::Compare::get_build
        or Carp::croak 'No current build!';

    Carp::croak "'$build' is not a Test2::Tools::DOM::Check"
        unless ref $build eq 'Test2::Tools::DOM::Check';

    my @caller = caller;
    $build->add_call(
        $name => $args,
        Test2::Compare::Wildcard->new(
            expect => $expect,
            file   => $caller[1],
            lines  => [ $caller[2] ],
        ),
    );
}

# Calls with either only a check, or a key and a check
my sub multi ( $method, $want, $check = '.oO NOT  A  REAL  VALUE Oo.' ) {
    $check && $check eq '.oO NOT  A  REAL  VALUE Oo.'
        ? call( $method => [       ] => $want  )
        : call( $method => [ $want ] => $check )
}

sub all_text (        $check ) { call all_text => [       ] => $check }
sub at       ( $want, $check ) { call at       => [ $want ] => $check }
sub content  (        $check ) { call content  => [       ] => $check }
sub find     ( $want, $check ) { call find     => [ $want ] => $check }
sub tag      (        $check ) { call tag      => [       ] => $check }
sub text     (        $check ) { call text     => [       ] => $check }
sub val      (        $check ) { call val      => [       ] => $check }

sub attr     { multi attr     => @_ }
sub children { multi children => @_ }

1;

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

our $VERSION = '0.100';

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
    my $build = Test2::Compare::get_build
        or Carp::croak "'$name' cannot be called in a context with no test build";

    Carp::croak "'$name' is not supported in a '$build' build"
        unless ref $build eq 'Test2::Tools::DOM::Check';

    my @caller = caller;
    $build->add_call(
        @$args ? [ $name => @$args ] : $name,
        Test2::Compare::Wildcard->new(
            expect => $expect,
            file   => $caller[1],
            lines  => [ $caller[2] ],
        ),
        $name,
        'scalar',
    );
}

# Calls with either only a check, or a key and a check
my sub multi {
    @_ > 2
        ? call( $_[0] => [ $_[1] ] => $_[2] )
        : call( $_[0] => [       ] => $_[1] )
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

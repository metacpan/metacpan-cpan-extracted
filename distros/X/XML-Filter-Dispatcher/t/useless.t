#!/usr/local/lib/perl -w

use strict;

use Test;
use XML::Filter::Dispatcher qw( :all );

sub t {
    my $path = shift;
    my $no_exception = eval {
        XML::Filter::Dispatcher->new(
            Rules => [
                $path => sub {},
            ],
#            Debug => 1,
        );
    };
    my $x = $@;
    if ( $no_exception ) {
        @_ = ( "no exception", "a 'can never match' exception", $path );
    }
    elsif ( $x =~ /can never match/ ) {
        @_ = ( $x, $x, $path );
    }
    else {
        @_ = ( $x, "a 'can never match' exception", $path );
    }
    goto &ok;
}

my @tests = (
sub { t "/a/start-document::*" },
sub { t "/a/end-document::*" },
sub { t "/attribute::*" },
sub { t "/a/attribute::*/*" },
sub { t "/a/attribute::*/start-element::*" },
sub { t "/a/attribute::*/end-element::*" },

sub { t "/a/attribute::text()" },
sub { t "/a/attribute::comment()" },
sub { t "/a/attribute::processing-instruction()" },
);

plan tests => scalar @tests;

$_->() for @tests;


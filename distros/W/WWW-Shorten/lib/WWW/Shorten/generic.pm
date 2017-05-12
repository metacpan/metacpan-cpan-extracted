package WWW::Shorten::generic;

use strict;
use warnings;

use Carp ();
use WWW::Shorten::UserAgent;

our $VERSION = '3.093';
$VERSION = eval $VERSION;

my %name_sets = (
    default => [qw( makeashorterlink makealongerlink )],
    short   => [qw( short_link long_link )],
);

sub import {
    my $class = shift;
    my ($package) = caller;
    ($package) = caller(1) if $package eq 'WWW::Shorten';
    my $set = shift;
    if (defined $set and $set =~ /^ : (\w+) $/x) {
        $set = $1;
    }
    else {
        $set = 'default';
    }
    if (exists $name_sets{$set}) {
        no strict 'refs';
        *{"${package}::$name_sets{$set}[0]"}
            = *{"${class}::$name_sets{default}[0]"};
        *{"${package}::$name_sets{$set}[1]"}
            = *{"${class}::$name_sets{default}[1]"};
    }
    else {
        Carp::croak("Unknown function set - $set.");
    }
}

my $ua;

sub ua {
    my $self = shift;
    return $ua if defined $ua;
    my $v = $self->VERSION();
    $ua = WWW::Shorten::UserAgent->new(
        env_proxy             => 1,
        timeout               => 30,
        agent                 => "$self/$v",
        requests_redirectable => [],
    );
    return $ua;
}

1;

=head1 NAME

WWW::Shorten::generic - Methods shared across all WWW::Shorten modules

=head1 SYNOPSIS

  use WWW::Shorten 'SomeSubclass';

=head1 DESCRIPTION

Contains methods that are shared across all WWW::Shorten implementation
modules.

=head1 FUNCTIONS

=head2 ua

Returns the object's LWP::Useragent attribute. Creates a new one if one
doesn't already exist.

=cut

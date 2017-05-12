# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Test;

use strict;
use warnings;

use base qw(Exporter);
use Test qw(ok skip plan);

our @EXPORT;
push @EXPORT, qw(ok skip plan have_lib skip_all);

sub have_lib {
    for (@_) {
        unless (eval "require $_") {
            $@ = "$_ not found\n" if $@ =~ /^Can't locate/;
            return undef;
        }
    }
    return 1;
}

sub skip_all {
    my $msg = $_[0] ? " # Skipped: $_[0]" : '';
    print "1..0$msg\n";
    exit;
}

1;
__END__

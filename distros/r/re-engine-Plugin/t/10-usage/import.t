use strict;
use lib 't/10-usage';
use Test::More skip_all => "Needs lameness in user code";

#    my $caller = caller;
#
# This won't work unless the subs are predeclared before the C<use> statement
#    # Handle import tags
#    if (@_ == 1) {
#        if ($_[0] ne ":import") {
#            require Carp;
#            Carp::croak("Unknown tag '$_[0]'");
#        }
#
#        # We have :import, generate import and unimport methods in the
#        # calling package
#        my %pkg;
#        for (qw<comp exec>) {
#            no strict 'refs';
#            $pkg{$_} = *{"$caller\::$_"}{CODE} if *{"$caller\::$_"}{CODE};
#        }
#
#        use Data::Dumper;
#        warn Dumper \%pkg;
#
#        no strict 'refs';
#        *{"$caller\::import"} = sub {
#            __PACKAGE__->import(%pkg);
#        };
#        *{"$caller\::unimport"} = \&unimport;
#
#        return;
#    }
#

use import;

"ook" =~ /pattern/;

is($1, "ook_1");

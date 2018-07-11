# Test object for testcases/DOConfig.pm
#
package XAO::DO::LocalConf;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Test1');

sub embeddable_methods ($) {
    return qw(fubar get);
}

sub fubar ($$) {
    my $self=shift;
    'X' . $_[0] . 'X';
}

sub init ($) {
    my $self=shift;
    $self->put(LocalConfig => 1);
}

1;

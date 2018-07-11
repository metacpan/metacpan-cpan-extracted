=head1 NAME

XAO::DO::Web::Debug - debug helper object

=head1 SYNOPSIS

 <%Debug text="Got here :)"%>

 <%Debug set="show-path"%>
 <%Page path="/bits/some-complex-template-that-fails"%>
 <%Debug clear="show-path"%>

=head1 DESCRIPTION

Allows to to spit debug messages into error_log and/or turn on or off
various debug parameters in Page.

XXX - incomplete description!

=cut

###############################################################################
package XAO::DO::Web::Debug;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

our $VERSION='2.001';

###############################################################################

sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    if($args->{on}) {
        XAO::Utils::set_debug(1);
        dprint "Debug on";
    }

    if($args->{off}) {
        dprint "Debug off";
        XAO::Utils::set_debug(0);
    }

    if($args->{set}) {
        my %set=map { $_ => 1 } split(/[,;\s]/,$args->{set});
        $self->debug_set(\%set);
        dprint "Debug set='",join(',',keys %set),"'";
    }

    if($args->{clear}) {
        my %set=map { $_ => 0 } split(/[,;\s]/,$args->{clear});
        $self->debug_set(\%set);
        dprint "Debug clear='",join(',',keys %set),"'";
    }

    if(defined($args->{text}) || defined($args->{template}) || $args->{path}) {
        my $text=$args->{text} ||
                 $self->object->expand($args);
        dprint $self->{objname}," - $text";
    }
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.

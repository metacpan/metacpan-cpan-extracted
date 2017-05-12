package eris::log::context::yum;

use Const::Fast;
use Moo;

use namespace::autoclean;
with qw(
    eris::role::context
);

sub sample_messages {
    my @msgs = split /\r?\n/, <<EOF;
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-filesystem-1.10.1-1.el6.noarch
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-mod-http-geoip-1.10.1-1.el6.x86_64
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-mod-mail-1.10.1-1.el6.x86_64
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-mod-stream-1.10.1-1.el6.x86_64
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-mod-http-image-filter-1.10.1-1.el6.x86_64
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-mod-http-perl-1.10.1-1.el6.x86_64
Sep  7 03:43:36 ether yum[26202]: Updated: nginx-1.10.1-1.el6.x86_64
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-mod-http-xslt-filter-1.10.1-1.el6.x86_64
Sep  7 03:43:36 ether yum[26202]: Installed: nginx-all-modules-1.10.1-1.el6.noarch
Sep  7 03:43:36 ether yum[26202]: Updated: libudev-147-2.73.el6_8.2.x86_64
Sep  7 03:43:36 ether yum[26202]: Updated: libgudev1-147-2.73.el6_8.2.x86_64
Sep  7 03:43:37 ether yum[26202]: Updated: udev-147-2.73.el6_8.2.x86_64
Sep  9 03:51:41 ether yum[12333]: Updated: puppetlabs-release-22.0-2.noarch
Sep 10 04:14:59 ether yum[22005]: Updated: perl-File-Next-1.16-1.el6.noarch
EOF
    return @msgs;
}

sub contextualize_message {
    my ($self,$log) = @_;
    my $str = $log->context->{message};
    my %ctxt = ();

    if($str =~ /^(\S+): (\S+)/) {
        $ctxt{action} = lc $1;
        $ctxt{file} = $2;
    }

    $log->add_context($self->name,\%ctxt) if keys %ctxt;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::yum

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

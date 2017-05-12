package encoding::split;
our $VERSION = '0.02';

1;
__END__
=head1 NAME

encoding::split - Metapackage (bundle) for automated upgrades

=head1 DESCRIPTION

In June 2007, encoding::source was removed from encoding-split, and the package
was renamed to encoding-stdio.

This module depends on RGARCIA's encoding-source and JUERD's encoding-stdio, so
that machines upgrading from encoding-split 0.01 will install both new modules.

If you find this module, encoding::split 0.02, on your computer, you may safely
remove it. It is no longer needed after its initial installation.

=head1 EXPIRY

This module will remain on CPAN at least one year, but not much longer.

=head1 SEE ALSO

L<encoding::source>, L<encoding::split>

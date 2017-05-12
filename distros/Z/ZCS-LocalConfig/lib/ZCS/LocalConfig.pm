package ZCS::LocalConfig;

use strict;
use warnings;

our $VERSION = '1.00';
our $DEBUG;

{
    my @Modules = qw(File Command);
    my %Mod_map = map { $_ => 1 } @Modules;

    sub new {
        my ( $class, %args ) = ( shift, @_ );

        my $type = delete $args{type};
        my @try  = @Modules;

        if ($type) {
            die("invalid arg type='$type'\n") unless $Mod_map{$type};
            @try = ($type);
        }

        foreach my $mod (@try) {
            $mod = __PACKAGE__ . '::' . $mod;
            eval "require $mod;";
            if ($@) {
                warn( __PACKAGE__, "::new: require '$mod' failed: $@\n" )
                  if $DEBUG;
                next;
            }
            my $obj = $mod->new(%args);
            return $obj if ($obj);
        }
        return undef;
    }
}

1;

__END__

=head1 NAME

ZCS::LocalConfig - Perl module for the Zimbra Collaboration Suite
(ZCS) Local Configuration data

=head1 SYNOPSIS

  use ZCS::LocalConfig;

  my $lc = ZCS::LocalConfig->new();
  ...

=head1 DESCRIPTION

The ZCS::LocalConfig Perl module provides an interface to work with
the Zimbra Collaboration Suite local configuration data via either the
zmlocalconfig command or directly to a localconfig XML configuration
file (/opt/zimbra/conf/localconfig.xml by default).

=head1 SEE ALSO

See the following documentation and links to related software and
topics:

=over 4

=item *

Zimbra Collaboration Suite L<http://www.zimbra.com/>

=back

=head1 AUTHOR

Phil Pearl E<lt>phil@zimbra.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Phil Pearl.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

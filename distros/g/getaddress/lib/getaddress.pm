package getaddress;

use 5.006001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use getaddress ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	ipwhere
);

our $VERSION = '0.04';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&getaddress::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('getaddress', $VERSION);

# Preloaded methods go here.
sub ipwhere
{
	my $ip = shift;
	my $ipfile = shift;
	$ipfile = "data/QQWry.Dat" unless ($ipfile);
	my $ipaddr = getipwhere ($ipfile, $ip);
	return '未知地区' unless ($ipaddr);
	$ipaddr =~ s/CZ88\.NET//ig;
	$ipaddr =~ s/^\s*//;
	$ipaddr =~ s/\s*$//;
	$ipaddr = '未知地区' if (!$ipaddr || $ipaddr =~ /未知|http/i);
	return $ipaddr;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

getaddress - Perl extension for get address

=head1 SYNOPSIS

  use getaddress;
  my $ipwhere = &ipwhere('127.0.0.1');

=head1 DESCRIPTION

The programe can known ip where is.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Junliang Li, E<lt>cnangel@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Junliang Li

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

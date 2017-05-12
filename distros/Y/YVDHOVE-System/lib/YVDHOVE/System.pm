package YVDHOVE::System;

use 5.008000;
use strict;
use warnings;

require Exporter;

# ---------------------------------------------------------------------------------

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( execCMD ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} });
our @EXPORT      = ();

our $VERSION     = '1.02';

# ---------------------------------------------------------------------------------

sub execCMD($$$) {
	my ($cmd, $captureoutput, $debug) = @_;

	print qq{execCMD: $cmd\n} if($debug);
		
	if ($captureoutput) {
		use IO::CaptureOutput qw(capture capture_exec qxx);
		my ($stdout, $stderr) = capture_exec("$cmd");
		my $rc       = ($? >> 8);
		my $signal   = ($? & 127);
		my $coredump = ($? & 128);
		my $rv = ($stderr eq '' && $signal == 0 && $coredump == 0) ? 1 : 0;
		if($debug) {
			print qq{command: $cmd\n};
			print qq{stdout:\n$stdout\n};
			print qq{stderr:\n$stderr\n} if (defined $stderr);
			print qq{rc: $rc\n};
			print qq{signal: $signal\n};
			print qq{coredump: $coredump\n};
			print qq{rv: $rv\n};
		}
		return ($rv, $stdout, $stderr);
	} else {
		my $rc = open(CMD, "$cmd 2>&1 |");
		if(defined $rc) {
			my $stdout = '';
			while(<CMD>) {
				$stdout .= $_;
			}
			close CMD;
			return (1, $stdout, '');
		} else {
			return (0, '', $!);
		}
	}
}

# ---------------------------------------------------------------------------------

1;

# ---------------------------------------------------------------------------------
__END__
=head1 NAME

YVDHOVE::System - This Perl module provides "System" functions for the YVDHOVE framework

=head1 SYNOPSIS

  use YVDHOVE::System;
  my($rc, $stdout, $stderr) = execCMD('ls -latr', 1, 0);

=head1 DESCRIPTION

This Perl module provides "System" functions for the YVDHOVE framework 

=head1 EXPORT

None by default.

=head1 METHODS

=over 4

=item execCMD(STRING, BOOLEAN, BOOLEAN);

my($rc, $stdout, $stderr) = execCMD('ls -latr', 1, 0);

$rc contains the resultcode (1=ok, 0=fail)
$stdout contains output written to STDOUT
$stderr contains output written to STDERR

=back

=head1 SEE ALSO

See F<http://search.cpan.org/search?query=YVDHOVE&mode=all>

=head1 AUTHORS

Yves Van den Hove, E<lt>yvdhove@users.sourceforge.netE<gt>

=head1 BUGS

See F<http://rt.cpan.org> to report and view bugs.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Yves Van den Hove, E<lt>yvdhove@users.sourceforge.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.x or,
at your option, any later version of Perl 5 you may have available.


=cut

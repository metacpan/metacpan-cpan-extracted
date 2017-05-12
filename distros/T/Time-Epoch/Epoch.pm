package Time::Epoch;

use strict;
use vars qw($VERSION @ISA @EXPORT);
require Exporter;

@ISA = 'Exporter';
@EXPORT = qw(
	perl2epoch epoch2perl
);
$VERSION = '0.02';


sub perl2epoch {
    my($perlsec, $epoch, @extra) = @_;
    my $epochsec;

    if ($epoch eq 'macos') {
        $epochsec = $perlsec + macos_offset();
        $epochsec += tz_offset($extra[0]);
    }

    return $epochsec;

}

sub epoch2perl {
    my($epochsec, $epoch, @extra) = @_;
    my $perlsec;

    if ($epoch eq 'macos') {
        $perlsec = $epochsec - macos_offset();
        $perlsec -= tz_offset($extra[0]);
    }

    return $perlsec;

}

sub macos_offset () { 2082844800 }
sub tz_offset {
    my($offset) = @_;
    my $tz_offset;

    if (defined $offset) {
        $tz_offset = $offset * 36;
    } else {
        require Time::Local;
        $tz_offset = sprintf "%+0.4d\n", (Time::Local::timelocal(localtime)
            - Time::Local::timelocal(gmtime));
    }

    return $tz_offset;
}

1;

__END__

=head1 NAME

Time::Epoch - Convert between Perl epoch and other epochs

=head1 SYNOPSIS

  #!/usr/bin/perl -wl
  use Time::Epoch;
  my $perlsec  = 966770660;  # Sun Aug 20 07:24:21 2000 -0400 on Mac OS
  my $epochsec = perl2epoch($perlsec, 'macos', '-0400');
  my $perlsec2 = epoch2perl($epochsec, 'macos', '-0400');

  print $perlsec;
  print $perlsec2;
  print $epochsec;
  # correct time on Unix:
  print scalar localtime $perlsec;
  # correct time on Mac OS (-0400):
  print scalar localtime $epochsec;


=head1 DESCRIPTION

Exports two functions, C<perl2epoch> and C<epoch2perl>.
Currently only goes between Perl (Unix) epoch and Mac OS
epoch.  This is in preparation for an eventual move of Perl
to its own universal epoch, so we can get the system epoch
of any platform that differs from Perl's.

=head2 Epochs

=over 4

=item * macos

Takes additional optional parameter of time zone differential.
If time zone differential not supplied, we guess by getting the
different between C<localtime> and C<gmtime> with
<Time::Local::timelocal>.

=back


=head1 BUGS

=over 4

=item *

Hm.  With the above test, C<scalar localtime $perlsec> under my Linux
box and C<scalar localtime $epochsec> under my Mac OS box are off by
one second from each other.  Maybe a leap second thing?  Odd.

=back


=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 2000-2003 Chris Nandor.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.

=head1 SEE ALSO

perl(1), perlport(1), Time::Local.

=cut

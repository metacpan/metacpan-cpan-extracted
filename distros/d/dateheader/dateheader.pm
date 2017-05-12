package dateheader;

use 5.00000;
use strict;
use vars qw( $VERSION );
$VERSION='1.0';
my @days=qw/Sun Mon Tue Wed Thu Fri Sat/;
my @months=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

sub TIESCALAR{
	my $x;
	bless \$x;
};
sub FETCH{
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday)
   =  gmtime(time);
   #adjust date for printability:
   $year += 1900;
   # zero-pad time-of-day components
   $hour = substr("0$hour", -2);
   $min = substr("0$min", -2);
   $sec = substr("0$sec", -2);

   # rfc 2822.3.3 says we should use -0000 but not all MUAs understand that
   return
   # "Date: $days[$wday], $mday $months[$mon] $year $hour:$min:$sec +0000";
   "Date: $days[$wday], $mday $months[$mon] $year $hour:$min:$sec -0000";
};

# tie $dateheader, 'dateheader';

sub import{
	no strict 'refs';
	# *{caller().'::dateheader'} = $dateheader;
	tie ${caller().'::dateheader'}, 'dateheader';
};


1;
__END__

=head1 NAME

dateheader - RFC2822-compliant "Date:" header with current gmtime

=head1 SYNOPSIS

  use dateheader;
  ...
  print MESSAGEHANDLE <<EOF;
$dateheader
From: Automated Customer Support <ACS@example.net>
To: $Firstname $Lastname <$email_address>
Subject: resolution of ticket number $ticketnumber

...
EOF


=head1 DESCRIPTION


Ties a scalar called $dateheader to the dateheader module.
This scalar, when stringified, gives a
RFC2822(section 3.3) compliant "Date:" header.


=head2 EXPORT

${caller().'dateheader'} gets tied to the dateheader package
by the import function.

=head1 HISTORY

=over 8

=item 0.0

A tied dateheader variable appeared in early versions of TipJar::MTA::queue

=item 1.0

We're now doing the C<tie>ing within the module, so C<use dateheader>
gives you the $dateheader variable, ready to interpolate.  We're also going
back to using time zone -0000, which is correct according to the RFC, but
might not be universally understood by broken MUA software which needs to
be fixed.


=back


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2003 David Nicol davidnico@cpan.org

I HEREBY PLACE THIS MODULE INTO THE PUBLIC DOMAIN

=cut



#!/usr/bin/perl

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use Getopt::Std;
use File::Spec::Functions;
use File::Basename;
use DBI;
use XML::Writer;


use constant {
	DB 			=> [qw(DBM PG ORA MYSQL)]
	,PERL		=> $ENV{PERL} // 'perl'
};

use constant {
	CMD		=> PERL.' -MCarp=verbose ./test.pl -c "%c" %x %L 1-52'

};

my %C=(F => 0,C => 0); #counters 

for my $db(@{&DB}) { #loop on database
	my $env='XSDSQL_'.$db;
	if (defined (my $connstr=$ENV{$env})) {
		for my $optx('','-x') {  #test with -x or not 
			my @optl=('');
			push @optl,'-L' unless $optx;  # -L with -x is ignored
			for my $optl(@optl) {
				my $cmd=CMD;
				$cmd=~s/\%c/$connstr/g;
				$cmd=~s/\%x/$optx/g;
				$cmd=~s/\%L/$optl/g;
				print STDERR "execute '$cmd'\n";
				system("$cmd");
				my $rc=$?;
				$C{C}++;
				$C{F}++ if $rc;
			}
		}	
	}
	else {
		print STDERR "(W) $env: the env variable is not set - test ignored\n";
	}
}

print STDERR 'tests: ',$C{C},' failed ',$C{F},"\n";

exit ($C{F} ? 1 : 0);

__END__

=head1 NAME testall.pl

=cut


=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

use 5.005;
use ExtUtils::MakeMaker;

our $VERSION = '1.02';

print <<EOM;

                ==========================
                =    Welcome to xDash    =
                ==========================

You can install:
[1] Modules needed only to be a Sender or Receiver;
[2] All modules needed to be a Sender, Receiver and Archivist.

EOM

print 'Please enter the number of the option from [ ] above: ';
my $option = <>;
if ( $option == 1 ){
    WriteMakefile(
	NAME => 'xDash',
	VERSION => $VERSION,
	PREREQ_PM => {  Net::Jabber => 0,
			Text::CSV_XS => 0},
	ABSTRACT_FROM => 'lib/xDash/About.pod', 
	AUTHOR => 'Jerzy Wachowiak <jwach@cpan.org>'
    )
}
elsif ( $option == 2 ){
    WriteMakefile(
	NAME => 'xDash',
	VERSION => $VERSION,
	PREREQ_PM => {  Net::Jabber => 0,
			DBI => 0,
			DBD::Pg => 0,
			Text::CSV_XS => 0},
	ABSTRACT_FROM => 'lib/xDash/About.pod', 
	AUTHOR => 'Jerzy Wachowiak <jwach@cpan.org>'
    )
}
else {
    print "There is no such option. Bye, bye ...\n\n"
}

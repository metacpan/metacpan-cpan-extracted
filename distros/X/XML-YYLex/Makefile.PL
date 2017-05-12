# $Log: Makefile.PL,v $
# Revision 1.2  2003/01/10 22:30:50  daniel
# version 0.3 (perl 5.6 and sablot 0.90)
#
# Revision 1.1.1.1  2002/11/24 17:18:15  daniel
# initial checkin
#
use strict;
#use 5.008;
use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::YYLex',
    'VERSION_FROM'	=> 'YYLex.pm', # finds $VERSION
#    'CONFIGURE'		=> \&check_for_dom_parsers,
    'PREREQ_PM'		=> &check_for_dom_parsers,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'YYLex.pm', # retrieve abstract from module
       AUTHOR     => 'Daniel Boesswetter <boesswetter@peppermind.de>') : ()),
);

sub check_for_dom_parsers {

    my @known_parsers = qw(XML::DOM XML::Sablotron::DOM);
    my @found_parsers = ();
    ## add more parsers here ...
    foreach my $dp (@known_parsers) {
	print "checking if $dp is present ... ";
	eval "use $dp;";
	if ( !$@ ) {
	    push( @found_parsers, $dp );
	    print "found\n";
	} else {
	    print "not found\n";
	}
    }

    if ( !@found_parsers ) {
	warn "\nYou don't seem to have a seem to have one of the supported 
DOM-parsers (".join( ", ", @known_parsers ).") installed ...

I will take XML::DOM as prerequisite now (maybe your CPAN-shell will
install it for you). If you would like to use anoter DOM-module, please
install it yourself.

";
	return( { "XML::DOM" => 0 } );
    }

    ## ugh, we really should require minimum versions ...
    #my @res = map { ( "PREREQ_PM", { $_ => 0 } ) } @found_parsers;
    return { map { $_ => 0 } @found_parsers };
    #return { @res };
}


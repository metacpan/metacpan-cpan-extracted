#!/usr/bin/perl -w

#=============================================================================
#
# $Id: test.t,v 0.01 2002/02/24 20:41:39 mneylon Exp $
# $Revision: 0.01 $
# $Author: mneylon $
# $Date: 2002/02/24 20:41:39 $
# $Log: test.t,v $
# Revision 0.01  2002/02/24 20:41:39  mneylon
# Initial Release
#
#
#=============================================================================


use Test;

# Borrowed from XML::Generator::DBI's test cases

BEGIN {
    eval {
        require XML::Handler::YAWriter;
    };
    if ($@) {
        print "1..0 # Skipping test on this platform\n";
        $skip = 1;
    }
    else {
        plan tests => 7;
    }
}

use XML::Generator::CGI;
use CGI;
unless ( $skip ) {
  ok(1);

  my $handler = XML::Handler::YAWriter->new( AsString => 1 );
  ok( $handler );

  my $generator = XML::Generator::CGI->new( Handler => $handler );
  ok( $generator );

  $query = new CGI('dinosaur=barney&dinosaur=grimus&color=purple');
  ok( $query );

  my $test1 = $generator->parsecgi( $query );
  ok ( $test1 );

  my $test2 = 
    $generator->parsecgi( 'dinosaur=barney&dinosaur=grimus&color=purple' );
  ok ( $test2 );

  my $test3 = $generator->parsecgi( );
  ok ( $test3 );
}

use Test::More tests => 6;
BEGIN { 
    use_ok( 'xDash::Sender' ); 
    use_ok( 'xDash::Receiver' );	
    use_ok( 'xDash::Spool::Dir' );
    use_ok( 'xDash::Spool::Dummy' );
    use_ok( 'xDash::Logger::File' );
    use_ok( 'xDash::Logger::Dumb' );
}



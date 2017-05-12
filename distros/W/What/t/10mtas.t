# $Id: 10mtas.t,v 1.1 2006/02/24 00:24:27 toni Exp $
use Test::More tests => 18;
use Test::Exception;
use lib qw(lib);
use strict;
BEGIN {
    use_ok( 'What' );
    use_ok( 'Data::Dumper' );
};

my ($obj,$err,$what, $data);

$data->{Exim} = "localhost ESMTP Exim 4.60 Mon, 20 Feb 2006 22:38:53 +0000";

$data->{Postfix} = "localhost ESMTP Postfix (Debian/GNU)";

$data->{Sendmail} = "galeb.somedomain.org ESMTP Sendmail 8.13.5/8.13.5/Debian-3; Mon, 20\n" .
"Feb 2006 22:41:04 GMT; (No UCE/UBE) logging access from:\n".
"localhost(OK)-localhost [127.0.0.1]";

$data->{XMail} = '<1140475332.2874633136@mast> [XMail 1.22 ESMTP Server] service ready;\n' .
"Mon, 20 Feb 2006 22:42:12 -0000";

$data->{MasqMail} = "mast MasqMail 0.2.21 ESMTP";

eval {
  $obj = What->new( Port => 1000 );
  $obj->mta
};

like ($@,
      qr/Couldn\'t create What::MTA object/,
      "Wrong port detected");

$what = What->new( Banner => $data->{Exim} );
is( $what->mta, "Exim", "mta is Exim");
is( $what->mta_version, "4.60", "version 4.60" );
is( $what->mta_banner, $data->{Exim}, "banner matches" );

$what = What->new( Banner => $data->{Sendmail} );
is( $what->mta, "Sendmail", "mta is Sendmail");
is( $what->mta_version, "8.13.5", "version 8.13.5" );
is( $what->mta_banner, $data->{Sendmail}, "banner matches" );

$what = What->new( Banner => $data->{XMail} );
is( $what->mta, "XMail", "mta is XMail");
is( $what->mta_version, "1.22", "version 1.22" );
is( $what->mta_banner, $data->{XMail}, "banner matches" );

$what = What->new( Banner => $data->{MasqMail} );
is( $what->mta, "MasqMail", "mta is MasqMail");
is( $what->mta_version, "0.2.21", "version 0.2.21" );
is( $what->mta_banner, $data->{MasqMail}, "banner matches" );

$what = What->new( Banner => $data->{Postfix} );
is( $what->mta, "Postfix", "mta is Postfix");
is( $what->mta_version, "unknown", "version unknown" );
is( $what->mta_banner, $data->{Postfix}, "banner matches" );

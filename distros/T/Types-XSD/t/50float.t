use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}E\\-\\d{2}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}E\-\d{2}$)/});
	should_pass("5E-16", $type, 0);
	should_pass("3E-18", $type, 0);
	should_pass("4E-26", $type, 0);
	should_pass("2E-18", $type, 0);
	should_pass("6E-13", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{2}E\\-\\d{1}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{2}E\-\d{1}$)/});
	should_pass("42E-2", $type, 0);
	should_pass("48E-5", $type, 0);
	should_pass("64E-2", $type, 0);
	should_pass("62E-1", $type, 0);
	should_pass("39E-8", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}\\.\\d{2}E\\d{1}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}\.\d{2}E\d{1}$)/});
	should_pass("6.77E7", $type, 0);
	should_pass("3.84E8", $type, 0);
	should_pass("9.84E6", $type, 0);
	should_pass("4.73E1", $type, 0);
	should_pass("4.74E2", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}\\.\\d{3}E\\d{2}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}\.\d{3}E\d{2}$)/});
	should_pass("9.966E21", $type, 0);
	should_pass("1.537E23", $type, 0);
	should_pass("6.815E27", $type, 0);
	should_pass("4.555E23", $type, 0);
	should_pass("6.645E12", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}\\.\\d{7}E\\-\\d{2}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}\.\d{7}E\-\d{2}$)/});
	should_pass("2.7821581E-24", $type, 0);
	should_pass("4.2646267E-21", $type, 0);
	should_pass("7.3748222E-24", $type, 0);
	should_pass("8.5676163E-27", $type, 0);
	should_pass("4.9665652E-22", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','1.9703874E-32','2.6927628E-19','2.7455975E-6','2.5357204E7','2.8222192E20','3.4028235E38']});
	should_pass("1.4E-45", $type, 0);
	should_pass("2.8222192E20", $type, 0);
	should_pass("2.6927628E-19", $type, 0);
	should_pass("2.5357204E7", $type, 0);
	should_pass("2.5357204E7", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','3.1628908E-25','3.3473630E-5','1.5006857E15','3.4028235E38']});
	should_pass("3.1628908E-25", $type, 0);
	should_pass("3.1628908E-25", $type, 0);
	should_pass("3.4028235E38", $type, 0);
	should_pass("3.3473630E-5", $type, 0);
	should_pass("3.3473630E-5", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','2.8312165E-25','1.5954879E-5','3.2481804E15','3.4028235E38']});
	should_pass("2.8312165E-25", $type, 0);
	should_pass("1.5954879E-5", $type, 0);
	should_pass("1.5954879E-5", $type, 0);
	should_pass("1.5954879E-5", $type, 0);
	should_pass("2.8312165E-25", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','1.7053130E-34','3.2152819E-23','2.4912911E-12','1.4657043E-1','3.1031987E10','2.7832936E21','3.4028235E38']});
	should_pass("2.7832936E21", $type, 0);
	should_pass("3.1031987E10", $type, 0);
	should_pass("2.7832936E21", $type, 0);
	should_pass("1.4657043E-1", $type, 0);
	should_pass("2.4912911E-12", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','1.8092974E-25','2.2696584E-5','2.0771560E15','3.4028235E38']});
	should_pass("2.0771560E15", $type, 0);
	should_pass("1.8092974E-25", $type, 0);
	should_pass("1.8092974E-25", $type, 0);
	should_pass("2.2696584E-5", $type, 0);
	should_pass("2.2696584E-5", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Float', {'whiteSpace' => 'collapse'});
	should_pass("-INF", $type, 0);
	should_pass("-3.4028235E38", $type, 0);
	should_pass("-2.7950497E18", $type, 0);
	should_pass("-2.0132317E-2", $type, 0);
	should_pass("-2.7053610E-22", $type, 0);
	should_pass("-1.4E-45", $type, 0);
	should_pass("-0", $type, 0);
	should_pass("0", $type, 0);
	should_pass("1.4E-45", $type, 0);
	should_pass("2.9102584E-25", $type, 0);
	should_pass("2.2788946E-5", $type, 0);
	should_pass("3.2699550E15", $type, 0);
	should_pass("3.4028235E38", $type, 0);
	should_pass("INF", $type, 0);
	should_pass("NaN", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}E\\-\\d{2}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}E\-\d{2}$)/});
	should_fail("5E3", $type, 0);
	should_fail("1E-5", $type, 0);
	should_fail("7E-9", $type, 0);
	should_fail("5E3", $type, 0);
	should_fail("8E-2", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{2}E\\-\\d{1}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{2}E\-\d{1}$)/});
	should_fail("9113754E-14", $type, 0);
	should_fail("624922E-25", $type, 0);
	should_fail("7576E19", $type, 0);
	should_fail("8E-27", $type, 0);
	should_fail("7578E22", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}\\.\\d{2}E\\d{1}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}\.\d{2}E\d{1}$)/});
	should_fail("4.92245E25", $type, 0);
	should_fail("7.3539E27", $type, 0);
	should_fail("8.749E25", $type, 0);
	should_fail("3.722388E14", $type, 0);
	should_fail("7.5E28", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}\\.\\d{3}E\\d{2}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}\.\d{3}E\d{2}$)/});
	should_fail("7.347924E4", $type, 0);
	should_fail("3.7562E7", $type, 0);
	should_fail("4.2438E5", $type, 0);
	should_fail("1.46E5", $type, 0);
	should_fail("8.3354E9", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet pattern with value \\d{1}\\.\\d{7}E\\-\\d{2}." => sub {
	my $type = mk_type('Float', {'pattern' => qr/(?ms:^\d{1}\.\d{7}E\-\d{2}$)/});
	should_fail("8.77683E-8", $type, 0);
	should_fail("4.48E-3", $type, 0);
	should_fail("2.36895E-6", $type, 0);
	should_fail("2.54836E-7", $type, 0);
	should_fail("8.5E8", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','3.3237194E-29','1.5755169E-13','2.8335234E3','2.1272429E19','3.4028235E38']});
	should_fail("-1.8868965E18", $type, 0);
	should_fail("-2.2511439E-14", $type, 0);
	should_fail("-INF", $type, 0);
	should_fail("1.4886925E-21", $type, 0);
	should_fail("-2.4423220E12", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','1.8901718E-32','2.9213084E-19','3.0553629E-6','2.9919429E7','1.6963260E20','3.4028235E38']});
	should_fail("0", $type, 0);
	should_fail("2.9645228E-37", $type, 0);
	should_fail("2.6648029E9", $type, 0);
	should_fail("-1.7993774E32", $type, 0);
	should_fail("-3.1408676E16", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','2.4814014E-36','2.6484107E-27','1.7944781E-18','2.5641745E-9','3.1836073E0','1.8404680E9','3.1833687E18','1.8920957E27','3.4028235E38']});
	should_fail("1.6820146E-7", $type, 0);
	should_fail("-2.8018486E2", $type, 0);
	should_fail("-1.8362160E22", $type, 0);
	should_fail("INF", $type, 0);
	should_fail("-2.0940774E6", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','2.1703468E-32','2.2458008E-19','1.8789427E-6','2.1360589E7','2.2878065E20','3.4028235E38']});
	should_fail("2.1227235E-41", $type, 0);
	should_fail("INF", $type, 0);
	should_fail("1.8456685E-43", $type, 0);
	should_fail("-3.0546106E-18", $type, 0);
	should_fail("2.1049167E-5", $type, 0);
	done_testing;
};

subtest "Type atomic/float is restricted by facet enumeration." => sub {
	my $type = mk_type('Float', {'enumeration' => ['1.4E-45','2.4589171E-32','2.2810632E-19','1.5252392E-6','1.5641128E7','2.8366848E20','3.4028235E38']});
	should_fail("2.2542101E-25", $type, 0);
	should_fail("-2.5676257E-10", $type, 0);
	should_fail("2.2542101E-25", $type, 0);
	should_fail("2.4031905E-43", $type, 0);
	should_fail("1.4401430E-19", $type, 0);
	done_testing;
};

done_testing;


use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}E\\-\\d{3}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}E\-\d{3}$)/});
	should_pass("4E-289", $type, 0);
	should_pass("3E-238", $type, 0);
	should_pass("2E-173", $type, 0);
	should_pass("2E-153", $type, 0);
	should_pass("3E-137", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{4}E\\-\\d{2}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{4}E\-\d{2}$)/});
	should_pass("5.2185E-22", $type, 0);
	should_pass("4.3272E-51", $type, 0);
	should_pass("3.1138E-51", $type, 0);
	should_pass("8.3266E-55", $type, 0);
	should_pass("8.3968E-76", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{8}E\\-\\d{1}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{8}E\-\d{1}$)/});
	should_pass("4.54918975E-8", $type, 0);
	should_pass("9.82585255E-8", $type, 0);
	should_pass("7.42727726E-4", $type, 0);
	should_pass("6.83242786E-5", $type, 0);
	should_pass("8.34238582E-8", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{12}E\\d{1}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{12}E\d{1}$)/});
	should_pass("4.319926813832E4", $type, 0);
	should_pass("4.462166867158E3", $type, 0);
	should_pass("4.642845497493E5", $type, 0);
	should_pass("8.388325397297E5", $type, 0);
	should_pass("3.693914247175E4", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{16}E\\d{3}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{16}E\d{3}$)/});
	should_pass("8.9765779385971216E261", $type, 0);
	should_pass("6.8222841673422587E283", $type, 0);
	should_pass("4.9578685246487246E116", $type, 0);
	should_pass("7.9774272498493962E262", $type, 0);
	should_pass("5.2646546428267367E153", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','2.2133245030541942E-234','2.2871337380701436E-144','4.8330246595957178E-54','3.5861613937406181E36','2.7457332729808998E126','2.8407030485906319E216','1.7976931348623157E308']});
	should_pass("3.5861613937406181E36", $type, 0);
	should_pass("2.8407030485906319E216", $type, 0);
	should_pass("4.9E-324", $type, 0);
	should_pass("4.9E-324", $type, 0);
	should_pass("2.8407030485906319E216", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','4.8523411539849754E-234','2.8869019830516350E-144','3.3925700348046903E-54','2.7311892445441031E36','2.9181385291440688E126','2.4983147023924484E216','1.7976931348623157E308']});
	should_pass("2.4983147023924484E216", $type, 0);
	should_pass("2.9181385291440688E126", $type, 0);
	should_pass("2.7311892445441031E36", $type, 0);
	should_pass("2.9181385291440688E126", $type, 0);
	should_pass("4.8523411539849754E-234", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','3.0828824769404266E-234','2.4426721708407727E-144','3.3142672291800245E-54','2.1028238996196812E36','2.5674850917565879E126','4.6505307100535510E216','1.7976931348623157E308']});
	should_pass("4.6505307100535510E216", $type, 0);
	should_pass("2.4426721708407727E-144", $type, 0);
	should_pass("2.1028238996196812E36", $type, 0);
	should_pass("3.3142672291800245E-54", $type, 0);
	should_pass("4.6505307100535510E216", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','1.9543492578327128E-234','4.6337466732941437E-144','4.2180257301126178E-54','2.0744434746534796E36','4.3411284761058989E126','3.4043189586904751E216','1.7976931348623157E308']});
	should_pass("4.3411284761058989E126", $type, 0);
	should_pass("2.0744434746534796E36", $type, 0);
	should_pass("3.4043189586904751E216", $type, 0);
	should_pass("4.3411284761058989E126", $type, 0);
	should_pass("4.9E-324", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','2.7409799988042133E-219','3.6407481234147934E-114','2.0102746771275176E-9','2.8428374096671001E96','4.6999860123584760E201','1.7976931348623157E308']});
	should_pass("2.0102746771275176E-9", $type, 0);
	should_pass("4.6999860123584760E201", $type, 0);
	should_pass("2.7409799988042133E-219", $type, 0);
	should_pass("2.0102746771275176E-9", $type, 0);
	should_pass("2.8428374096671001E96", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Double', {'whiteSpace' => 'collapse'});
	should_pass("-INF", $type, 0);
	should_pass("-1.7976931348623157E308", $type, 0);
	should_pass("-4.5400409861528464E150", $type, 0);
	should_pass("-2.4656082617219581E-8", $type, 0);
	should_pass("-2.4465657314964493E-166", $type, 0);
	should_pass("-4.9E-324", $type, 0);
	should_pass("-0", $type, 0);
	should_pass("0", $type, 0);
	should_pass("4.9E-324", $type, 0);
	should_pass("3.9962074390640384E-166", $type, 0);
	should_pass("4.7083935269121063E-8", $type, 0);
	should_pass("4.7439793877361399E150", $type, 0);
	should_pass("1.7976931348623157E308", $type, 0);
	should_pass("INF", $type, 0);
	should_pass("NaN", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}E\\-\\d{3}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}E\-\d{3}$)/});
	should_fail("3E6", $type, 0);
	should_fail("1E-12", $type, 0);
	should_fail("5E-47", $type, 0);
	should_fail("7E36", $type, 0);
	should_fail("5E-42", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{4}E\\-\\d{2}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{4}E\-\d{2}$)/});
	should_fail("5.532777422E-262", $type, 0);
	should_fail("4.84496778864735E7", $type, 0);
	should_fail("3.3664231457E-8", $type, 0);
	should_fail("5.39693584258676E139", $type, 0);
	should_fail("1.977777E-227", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{8}E\\-\\d{1}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{8}E\-\d{1}$)/});
	should_fail("2.938778577292527E-112", $type, 0);
	should_fail("8.687E-228", $type, 0);
	should_fail("7.2552325433887758E57", $type, 0);
	should_fail("6.264672671344E55", $type, 0);
	should_fail("4.564652616398648E-53", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{12}E\\d{1}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{12}E\d{1}$)/});
	should_fail("7.377E277", $type, 0);
	should_fail("7.44122758643E172", $type, 0);
	should_fail("5.37737654663E193", $type, 0);
	should_fail("9.253644E228", $type, 0);
	should_fail("3.61775E52", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet pattern with value \\d{1}\\.\\d{16}E\\d{3}." => sub {
	my $type = mk_type('Double', {'pattern' => qr/(?ms:^\d{1}\.\d{16}E\d{3}$)/});
	should_fail("8.9396649815531E32", $type, 0);
	should_fail("7.2936652792E4", $type, 0);
	should_fail("3.5827872E2", $type, 0);
	should_fail("6.49517724E8", $type, 0);
	should_fail("9.953E7", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','2.9847235681660356E-219','2.4705585733094389E-114','2.8648830854472200E-9','3.6123848814665702E96','4.8249539413456660E201','1.7976931348623157E308']});
	should_fail("-4.4342657606591980E-49", $type, 0);
	should_fail("3.7575966972397818E-198", $type, 0);
	should_fail("3.3981202785445614E201", $type, 0);
	should_fail("-1.7976931348623157E308", $type, 0);
	should_fail("-2.0203071715201305E119", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','4.3928576546766641E-234','3.3347484045339821E-144','2.2386392124584646E-54','3.8647439182760973E36','4.1209222777910337E126','3.7649749033120186E216','1.7976931348623157E308']});
	should_fail("3.0290494958619612E-240", $type, 0);
	should_fail("4.6549602908266423E-303", $type, 0);
	should_fail("-3.1835210975897257E56", $type, 0);
	should_fail("2.9265667529149958E-282", $type, 0);
	should_fail("-2.7763292621557008E-70", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','4.0820793024851395E-245','3.8230588179392781E-166','2.6979669918834709E-87','2.0834987530951218E-8','1.8962326902306018E71','2.0638057320113563E150','2.0453110403825455E229','1.7976931348623157E308']});
	should_fail("1.9833779215040069E96", $type, 0);
	should_fail("2.2670473638907323E-282", $type, 0);
	should_fail("-2.5987908015975612E-196", $type, 0);
	should_fail("3.4125183524111053E-135", $type, 0);
	should_fail("-1.8627286721557672E161", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','2.9770718680565462E-166','2.3503189286792878E-8','4.7144691099845778E150','1.7976931348623157E308']});
	should_fail("-3.2497254652116023E14", $type, 0);
	should_fail("-3.9755079320248947E-112", $type, 0);
	should_fail("4.6005443625421961E-177", $type, 0);
	should_fail("-1.8167207834888545E-217", $type, 0);
	should_fail("3.2695765668213063E-261", $type, 0);
	done_testing;
};

subtest "Type atomic/double is restricted by facet enumeration." => sub {
	my $type = mk_type('Double', {'enumeration' => ['4.9E-324','3.6799173280388714E-166','3.4791243588260355E-8','3.9190770335351561E150','1.7976931348623157E308']});
	should_fail("-3.1145780814992152E-196", $type, 0);
	should_fail("2.8562046481936448E12", $type, 0);
	should_fail("-4.7955738439334855E182", $type, 0);
	should_fail("-4.9E-324", $type, 0);
	should_fail("1.9560810896697008E-240", $type, 0);
	done_testing;
};

done_testing;


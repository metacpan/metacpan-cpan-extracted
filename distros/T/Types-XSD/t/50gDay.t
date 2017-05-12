use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---01." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---01'});
	should_pass("---02", $type, 0);
	should_pass("---17", $type, 0);
	should_pass("---26", $type, 0);
	should_pass("---06", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---20." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---20'});
	should_pass("---21", $type, 0);
	should_pass("---28", $type, 0);
	should_pass("---21", $type, 0);
	should_pass("---27", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---04." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---04'});
	should_pass("---05", $type, 0);
	should_pass("---14", $type, 0);
	should_pass("---25", $type, 0);
	should_pass("---14", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---04." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---04'});
	should_pass("---05", $type, 0);
	should_pass("---14", $type, 0);
	should_pass("---20", $type, 0);
	should_pass("---24", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---30." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---30'});
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---01." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---01'});
	should_pass("---01", $type, 0);
	should_pass("---09", $type, 0);
	should_pass("---17", $type, 0);
	should_pass("---14", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---16." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---16'});
	should_pass("---16", $type, 0);
	should_pass("---18", $type, 0);
	should_pass("---16", $type, 0);
	should_pass("---29", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---24." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---24'});
	should_pass("---24", $type, 0);
	should_pass("---29", $type, 0);
	should_pass("---24", $type, 0);
	should_pass("---30", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---08." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---08'});
	should_pass("---08", $type, 0);
	should_pass("---30", $type, 0);
	should_pass("---27", $type, 0);
	should_pass("---15", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---31." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---31'});
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---02." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---02'});
	should_pass("---01", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---25." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---25'});
	should_pass("---01", $type, 0);
	should_pass("---15", $type, 0);
	should_pass("---21", $type, 0);
	should_pass("---07", $type, 0);
	should_pass("---24", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---30." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---30'});
	should_pass("---01", $type, 0);
	should_pass("---20", $type, 0);
	should_pass("---24", $type, 0);
	should_pass("---22", $type, 0);
	should_pass("---29", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---15." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---15'});
	should_pass("---01", $type, 0);
	should_pass("---13", $type, 0);
	should_pass("---06", $type, 0);
	should_pass("---11", $type, 0);
	should_pass("---14", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---31." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---31'});
	should_pass("---01", $type, 0);
	should_pass("---06", $type, 0);
	should_pass("---22", $type, 0);
	should_pass("---09", $type, 0);
	should_pass("---30", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---01." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---01'});
	should_pass("---01", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---07." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---07'});
	should_pass("---01", $type, 0);
	should_pass("---01", $type, 0);
	should_pass("---01", $type, 0);
	should_pass("---02", $type, 0);
	should_pass("---07", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---01." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---01'});
	should_pass("---01", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---10." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---10'});
	should_pass("---01", $type, 0);
	should_pass("---02", $type, 0);
	should_pass("---05", $type, 0);
	should_pass("---08", $type, 0);
	should_pass("---10", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---31." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---31'});
	should_pass("---01", $type, 0);
	should_pass("---15", $type, 0);
	should_pass("---25", $type, 0);
	should_pass("---01", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---\\d5." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---\d5$)/});
	should_pass("---15", $type, 0);
	should_pass("---15", $type, 0);
	should_pass("---25", $type, 0);
	should_pass("---15", $type, 0);
	should_pass("---15", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---\\d5." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---\d5$)/});
	should_pass("---15", $type, 0);
	should_pass("---25", $type, 0);
	should_pass("---15", $type, 0);
	should_pass("---15", $type, 0);
	should_pass("---15", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---0\\d." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---0\d$)/});
	should_pass("---02", $type, 0);
	should_pass("---03", $type, 0);
	should_pass("---04", $type, 0);
	should_pass("---07", $type, 0);
	should_pass("---05", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---\\d2." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---\d2$)/});
	should_pass("---02", $type, 0);
	should_pass("---22", $type, 0);
	should_pass("---22", $type, 0);
	should_pass("---22", $type, 0);
	should_pass("---12", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---1\\d." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---1\d$)/});
	should_pass("---14", $type, 0);
	should_pass("---13", $type, 0);
	should_pass("---14", $type, 0);
	should_pass("---13", $type, 0);
	should_pass("---11", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---15','---29','---30','---26','---16','---08','---18','---07']});
	should_pass("---15", $type, 0);
	should_pass("---26", $type, 0);
	should_pass("---30", $type, 0);
	should_pass("---18", $type, 0);
	should_pass("---30", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---04','---04','---22','---20','---18','---12','---10','---08']});
	should_pass("---20", $type, 0);
	should_pass("---10", $type, 0);
	should_pass("---12", $type, 0);
	should_pass("---18", $type, 0);
	should_pass("---04", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---15','---27','---16','---22','---12','---30','---24','---14','---09']});
	should_pass("---12", $type, 0);
	should_pass("---24", $type, 0);
	should_pass("---12", $type, 0);
	should_pass("---30", $type, 0);
	should_pass("---24", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---15','---05','---17','---12','---21','---18']});
	should_pass("---12", $type, 0);
	should_pass("---05", $type, 0);
	should_pass("---18", $type, 0);
	should_pass("---12", $type, 0);
	should_pass("---17", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---21','---23','---13','---26','---23','---24','---18','---30','---14']});
	should_pass("---21", $type, 0);
	should_pass("---14", $type, 0);
	should_pass("---13", $type, 0);
	should_pass("---30", $type, 0);
	should_pass("---26", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('GDay', {'whiteSpace' => 'collapse'});
	should_pass("---01", $type, 0);
	should_pass("---25", $type, 0);
	should_pass("---22", $type, 0);
	should_pass("---26", $type, 0);
	should_pass("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---11." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---11'});
	should_fail("---01", $type, 0);
	should_fail("---08", $type, 0);
	should_fail("---05", $type, 0);
	should_fail("---08", $type, 0);
	should_fail("---10", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---05." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---05'});
	should_fail("---01", $type, 0);
	should_fail("---02", $type, 0);
	should_fail("---02", $type, 0);
	should_fail("---03", $type, 0);
	should_fail("---04", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---16." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---16'});
	should_fail("---01", $type, 0);
	should_fail("---09", $type, 0);
	should_fail("---13", $type, 0);
	should_fail("---10", $type, 0);
	should_fail("---15", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minInclusive with value ---31." => sub {
	my $type = mk_type('GDay', {'minInclusive' => '---31'});
	should_fail("---01", $type, 0);
	should_fail("---20", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---14", $type, 0);
	should_fail("---30", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---01." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---01'});
	should_fail("---02", $type, 0);
	should_fail("---07", $type, 0);
	should_fail("---30", $type, 0);
	should_fail("---29", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---30." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---30'});
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---05." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---05'});
	should_fail("---06", $type, 0);
	should_fail("---25", $type, 0);
	should_fail("---27", $type, 0);
	should_fail("---24", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---05." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---05'});
	should_fail("---06", $type, 0);
	should_fail("---10", $type, 0);
	should_fail("---07", $type, 0);
	should_fail("---07", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxInclusive with value ---12." => sub {
	my $type = mk_type('GDay', {'maxInclusive' => '---12'});
	should_fail("---13", $type, 0);
	should_fail("---26", $type, 0);
	should_fail("---20", $type, 0);
	should_fail("---22", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---01." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---01'});
	should_fail("---01", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---18." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---18'});
	should_fail("---01", $type, 0);
	should_fail("---05", $type, 0);
	should_fail("---16", $type, 0);
	should_fail("---17", $type, 0);
	should_fail("---18", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---02." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---02'});
	should_fail("---01", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---02", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---10." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---10'});
	should_fail("---01", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---03", $type, 0);
	should_fail("---10", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet minExclusive with value ---30." => sub {
	my $type = mk_type('GDay', {'minExclusive' => '---30'});
	should_fail("---01", $type, 0);
	should_fail("---27", $type, 0);
	should_fail("---21", $type, 0);
	should_fail("---02", $type, 0);
	should_fail("---30", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---02." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---02'});
	should_fail("---02", $type, 0);
	should_fail("---29", $type, 0);
	should_fail("---14", $type, 0);
	should_fail("---02", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---26." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---26'});
	should_fail("---26", $type, 0);
	should_fail("---27", $type, 0);
	should_fail("---28", $type, 0);
	should_fail("---28", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---05." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---05'});
	should_fail("---05", $type, 0);
	should_fail("---17", $type, 0);
	should_fail("---07", $type, 0);
	should_fail("---21", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---13." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---13'});
	should_fail("---13", $type, 0);
	should_fail("---28", $type, 0);
	should_fail("---13", $type, 0);
	should_fail("---16", $type, 0);
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet maxExclusive with value ---31." => sub {
	my $type = mk_type('GDay', {'maxExclusive' => '---31'});
	should_fail("---31", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---2\\d." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---2\d$)/});
	should_fail("---14", $type, 0);
	should_fail("---10", $type, 0);
	should_fail("---18", $type, 0);
	should_fail("---12", $type, 0);
	should_fail("---10", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---\\d3." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---\d3$)/});
	should_fail("---06", $type, 0);
	should_fail("---05", $type, 0);
	should_fail("---14", $type, 0);
	should_fail("---04", $type, 0);
	should_fail("---27", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---\\d4." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---\d4$)/});
	should_fail("---28", $type, 0);
	should_fail("---13", $type, 0);
	should_fail("---03", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---28", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---0\\d." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---0\d$)/});
	should_fail("---22", $type, 0);
	should_fail("---10", $type, 0);
	should_fail("---16", $type, 0);
	should_fail("---11", $type, 0);
	should_fail("---22", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet pattern with value ---1\\d." => sub {
	my $type = mk_type('GDay', {'pattern' => qr/(?ms:^---1\d$)/});
	should_fail("---22", $type, 0);
	should_fail("---02", $type, 0);
	should_fail("---24", $type, 0);
	should_fail("---06", $type, 0);
	should_fail("---06", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---26','---23','---25','---28','---05','---23','---18']});
	should_fail("---22", $type, 0);
	should_fail("---30", $type, 0);
	should_fail("---13", $type, 0);
	should_fail("---19", $type, 0);
	should_fail("---02", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---22','---04','---12','---12','---08','---23','---22','---09','---04']});
	should_fail("---18", $type, 0);
	should_fail("---26", $type, 0);
	should_fail("---26", $type, 0);
	should_fail("---16", $type, 0);
	should_fail("---17", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---30','---10','---18','---14','---03','---15','---25','---16','---23','---14']});
	should_fail("---17", $type, 0);
	should_fail("---08", $type, 0);
	should_fail("---01", $type, 0);
	should_fail("---17", $type, 0);
	should_fail("---01", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---24','---03','---03','---30','---12','---20']});
	should_fail("---27", $type, 0);
	should_fail("---26", $type, 0);
	should_fail("---28", $type, 0);
	should_fail("---23", $type, 0);
	should_fail("---25", $type, 0);
	done_testing;
};

subtest "Type atomic/gDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GDay', {'enumeration' => ['---29','---16','---22','---13','---29','---16','---27','---28','---15']});
	should_fail("---02", $type, 0);
	should_fail("---24", $type, 0);
	should_fail("---25", $type, 0);
	should_fail("---18", $type, 0);
	should_fail("---24", $type, 0);
	done_testing;
};

done_testing;


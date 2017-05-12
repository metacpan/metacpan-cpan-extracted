use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/boolean is restricted by facet pattern with value [1]{1}." => sub {
	my $type = mk_type('Boolean', {'pattern' => qr/(?ms:^[1]{1}$)/});
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet pattern with value false." => sub {
	my $type = mk_type('Boolean', {'pattern' => qr/(?ms:^false$)/});
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet pattern with value [1]{1}." => sub {
	my $type = mk_type('Boolean', {'pattern' => qr/(?ms:^[1]{1}$)/});
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet pattern with value false." => sub {
	my $type = mk_type('Boolean', {'pattern' => qr/(?ms:^false$)/});
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet pattern with value [1]{1}." => sub {
	my $type = mk_type('Boolean', {'pattern' => qr/(?ms:^[1]{1}$)/});
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Boolean', {'whiteSpace' => 'collapse'});
	should_pass("false", $type, 0);
	should_pass("1", $type, 0);
	should_pass("true", $type, 0);
	should_pass("false", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Boolean', {'whiteSpace' => 'collapse'});
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("true", $type, 0);
	should_pass("false", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Boolean', {'whiteSpace' => 'collapse'});
	should_pass("false", $type, 0);
	should_pass("true", $type, 0);
	should_pass("false", $type, 0);
	should_pass("1", $type, 0);
	should_pass("false", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Boolean', {'whiteSpace' => 'collapse'});
	should_pass("true", $type, 0);
	should_pass("false", $type, 0);
	should_pass("true", $type, 0);
	should_pass("false", $type, 0);
	should_pass("false", $type, 0);
	done_testing;
};

subtest "Type atomic/boolean is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Boolean', {'whiteSpace' => 'collapse'});
	should_pass("false", $type, 0);
	should_pass("0", $type, 0);
	should_pass("true", $type, 0);
	should_pass("true", $type, 0);
	should_pass("true", $type, 0);
	done_testing;
};

done_testing;


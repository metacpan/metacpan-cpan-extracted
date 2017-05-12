
#########################

use Test::More tests => 4;
BEGIN { use_ok('WebService::Validator::HTML::W3C::Fast') };

#########################

SKIP: {
	my $v;
	eval {
		$v = WebService::Validator::HTML::W3C::Fast->new();
	};
	skip("No validator available:$@", 3) if ($@);
	ok($v, "Launched a validator at " . $v->validator_uri());
	ok($v->validate_markup(<<_HTML_), "Gets back results");
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-au">
<head><title></title></head><body></body></html>
_HTML_
	ok($v->is_valid(), "Validates valid file");
}

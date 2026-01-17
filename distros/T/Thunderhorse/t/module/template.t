use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse::Module::Template works
################################################################################

package TemplateApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_module(
			'Template' => {
				paths => ['t/templates'],
				conf => {
					OUTLINE_TAG => qr{\V*%%},
				},
			}
		);

		$self->router->add(
			'/test/?ex' => {
				to => 'test',
			}
		);

		$self->router->add(
			'/test-inline' => {
				to => 'test_inline',
			}
		);

		$self->router->add(
			'/test-data' => {
				to => 'test_data',
			}
		);

		$self->router->add(
			'/test-bad' => {
				to => 'test_bad',
			}
		);
	}

	sub test ($self, $ctx, $ex)
	{
		$ex = defined $ex ? ".$ex" : '';
		return $self->template("test$ex", {name => 'World'});
	}

	sub test_inline ($self, $ctx)
	{
		return $self->template(\'Hello [% name %]!', {name => 'Inline'});
	}

	sub test_data ($self, $ctx)
	{
		return $self->template(\*main::DATA);
	}

	sub test_bad ($self, $ctx)
	{
		return $self->template('bad_template');
	}
}

my $app = TemplateApp->new;

subtest 'should render template from file with wrapper' => sub {
	http $app, GET '/test';
	http_status_is 200;
	http_header_is 'Content-Type', 'text/html; charset=utf-8';
	like http->text, qr{^zażółć gęślą jaźń Hello World!\v+$}, 'body ok';
};

subtest 'should render template from file with a custom extension' => sub {
	http $app, GET '/test/tpl';
	http_status_is 200;
	http_header_is 'Content-Type', 'text/html; charset=utf-8';
	like http->text, qr{^zażółć gęślą jaźń Hello World!\v+$}, 'body ok';
};

subtest 'should render inline template' => sub {
	http $app, GET '/test-inline';
	http_status_is 200;
	http_text_is 'Hello Inline!';
};

subtest 'should render DATA template' => sub {
	http $app, GET '/test-data';
	http_status_is 200;
	like http->text, qr{^Data contents\v+$}, 'body ok';

	# again - test handle rewinding
	http $app, GET '/test-data';
	like http->text, qr{^Data contents\v+$}, 'body ok';
};

subtest 'should not render bad template' => sub {
	http $app, GET '/test-bad';
	like http->text, qr{\Q[Template] file error - bad_template.tt: not found\E}, 'text ok';
};

done_testing;

__DATA__
Data contents


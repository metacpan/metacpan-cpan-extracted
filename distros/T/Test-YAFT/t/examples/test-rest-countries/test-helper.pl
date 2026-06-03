
use v5.14;
use warnings;

use Test::YAFT;
use HTTP::Response;
use HTTP::Status;
use JSON;

sub expect_http_success () {
	expect_methods (is_success => expect_true);
}

sub expect_json_content_type () {
	expect_methods (content_type => expect_re (qr/\bjson\b/));
}

sub expect_json_content ($) {
	state $class = Test::YAFT::test_deep_cmp (
		_decode => sub {
			my ($self, $got) = @_;
			return if eval {
				$self->{-json} = JSON::decode_json ($got->decoded_content);
				$self->{-lives_json} = 1;
			};

			$self->{-error_json} = $@;
		},

		descend => sub {
			my ($self, $got) = @_;
			delete @$self{qw{ -object -json -lives_json -error_json -compare }};

			$self->{-object} = expect_obj_isa (q (HTTP::Response));
			return unless $self->{-object}->descend ($got);

			$self->_decode ($got);
			return unless $self->{-lives_json};
			return unless $self->{-json};

			$self->{-content} = $self->Test::YAFT::Cmp::descend ($self->{-json});
			return $self->{-content};
		},

		renderGot => sub {
			my ($self, $got) = @_;

			return $self->{-object}->renderGot ($got)
				unless $self->{-object}->descend;

			return qq (Decoding json failed: $self->{-error_json}:\n${\ $got->decoded_json })
				unless $self->{-lives_json};

			return $got->decoded_json;
		}
	);

	return $class->new (@_);
}

my %data = (
	q (north-america) => [ qw [ Canada Mexico USA ] ],
	q (australia)     => [ qw [ Australia         ] ],
	q (antarctica)    => [                          ],
);

sub GET {
	my ($uri) = @_;

	die qq (Unrecognized URI: $uri)
		unless $uri =~ m: ^ /countries/ (?<continent> [^/\s]+ ) $:x;

	my $continent = $+{continent};

	my $response = HTTP::Response::->new (HTTP::Status::HTTP_OK);
	$response->content_type (q (application/json));

	unless (exists $data{$continent}) {
		$response->code (HTTP::Status::HTTP_BAD_REQUEST);
		$response->content (JSON::encode_json ({ error => q (Continent not found) }));

		return $response;
	}

	$response->content (JSON::encode_json ({ countries => $data{$continent}}));

	return $response;
}

1;

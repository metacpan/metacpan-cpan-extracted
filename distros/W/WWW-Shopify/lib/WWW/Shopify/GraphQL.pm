package WWW::Shopify::GraphQL;

use strict;
use warnings; 

use JSON qw(from_json decode_json);
use Encode;
use Scalar::Util qw(blessed);
use Data::Dumper;

sub new {
	my ($package, $sa) = @_;
	return bless {
		_sa => $sa
	}, $package;
}

sub sa { return $_[0]->{_sa}; }

sub encode_hash {
	my ($self, $object) = @_;
	return $object if !ref($object);
	return join(" ", map { $self->encode_hash($_) } @$object) if ref($object) eq 'ARRAY';
	return "" if int(keys(%$object)) == 0;
	die new WWW::Shopify::Exception("Invalid GraphQL hash: " . int(keys(%$object)) . " keys present.") unless int(keys(%$object)) == 1;
	my ($key) = keys(%$object);
	return "$key { " . $self->encode_hash($object->{$key}) . " }";
}

sub internal_query {
	my ($self, $hash) = @_;
	my $request = HTTP::Request->new(POST => $self->sa->encode_url('/admin/api/graphql.json'));
	my $content = ref($hash) ? encode("UTF-8", $self->encode_hash({ query => $hash })) : encode("UTF-8", $hash);
	$request->content($content);
	$request->header('Content-Length' => length($content));
	$request->header('Accept' => 'application/json');
	$request->header('Content-Type' => 'application/graphql');
	my $response = $self->sa->ua->request($request);
	print STDERR "POST " . $response->request->uri . "\n" if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} == 1;
	print STDERR Dumper($response) if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} > 1;
	# This is explicitly decode_json here. If not, the thing doesn't decode properly.
	$content = eval { decode_json($response->decoded_content) };
	if (!$response->is_success) {
		print STDERR Dumper($response) if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} > 1;
		die WWW::Shopify::Exception::CallLimit->new($response) if $response->code() == 429;
		die WWW::Shopify::Exception::InvalidKey->new($response) if $response->code() == 401;
		die WWW::Shopify::Exception::NotFound->new($response) if $response->code() == 404;
		# I honestly can't believe this.
		die WWW::Shopify::Exception::QueryParamTooLong->new($response) if $content->{errors} && $content->{errors} =~ m/query param length is too/i;
		die WWW::Shopify::Exception->new($response);
	}
	if ($content && $content->{errors}) {		
		die WWW::Shopify::Exception::CallLimit->new($response) if int(grep { $_->{message} eq "Throttled" } @{$content->{errors}}) > 0;
		die WWW::Shopify::Exception::ExceededCost->new($response) if int(grep { $_->{message} =~ m/Query has a cost of/i } @{$content->{errors}}) > 0;
		# Adding this in the hope tht they have reasonable error handling someday.
		die WWW::Shopify::Exception::QueryParamTooLong->new($response) if int(grep { $_->{message} =~ m/query param length is too/i } @{$content->{errors}}) > 0;
		die WWW::Shopify::Exception->new($response);
	}
	return $content->{data} unless wantarray;
	return ($response, $content->{data});
}

sub query {
	my ($self, $hash) = @_;
	
	my @result;
	while (int(@result) == 0) {
		eval {
			@result = $self->internal_query($hash);
		};
		if (my $exp = $@) {
			if ($self->sa->sleep_for_limit && blessed($exp) && $exp->isa('WWW::Shopify::Exception::CallLimit')) {
				sleep(1);
				next;
			}
			die $exp;
		}
	};
	return $result[1] unless wantarray;
	return @result;
}

use File::Temp qw(tempfile);
use List::Util qw(min max);
use IO::Handle;
use Fcntl qw(SEEK_SET SEEK_END SEEK_CUR);

sub bulk_operation_query {
	my ($self, $hash, $callback) = @_;
	my $content = ref($hash) ? $self->encode_hash({ query => $hash }) : $hash;
	my $query = "mutation { bulkOperationRunQuery(query: \"\"\"$content\"\"\") { bulkOperation { id status } userErrors { field message } } }";
	my ($response,  $result) = $self->query($query);
	die WWW::Shopify::Exception->new($response) if !$result->{bulkOperationRunQuery} || !$result->{bulkOperationRunQuery}->{bulkOperation}->{status} || $result->{bulkOperationRunQuery}->{bulkOperation}->{status} ne "CREATED";
	while (1) {
		my ($response, $result) = $self->query('query { currentBulkOperation { id status errorCode createdAt completedAt objectCount fileSize url partialDataUrl } }');
		die WWW::Shopify::Exception->new($response) if $result->{currentBulkOperation}->{errorCode};
		if ($result->{currentBulkOperation}->{status} eq "COMPLETED") {
			my $fh = tempfile();
			$self->sa->ua->set_my_handler(response_data => sub {
				 my($response, $ua, $handler, $data) = @_;
				 print $fh $data;
			});
			my $response = $self->sa->ua->request(HTTP::Request->new(GET => $result->{currentBulkOperation}->{url}));
			$fh->flush;
			$self->sa->ua->set_my_handler(reponse_data => undef);
			my $chunk_size = 10*1024;
			my $buffer = "";
			my $chunk;
			seek($fh, -1, SEEK_END);
			my $cursor_position = tell($fh);
			while ($cursor_position > 0) {
				my $to_read = $chunk_size;
				if ($cursor_position >= $chunk_size) {
					$cursor_position -= $chunk_size;
				} else {
					$to_read = $cursor_position;
					$cursor_position = 0;
				}
				seek($fh, $cursor_position, SEEK_SET);
				my $size_read = read($fh, $chunk, $to_read);
				$buffer = $chunk . $buffer;
				while ((my $index = rindex($buffer, "\n")) != -1) {
					my $line = substr($buffer, $index, length($buffer) - $index + 1, "");
					$callback->(substr($line, 1));
				}
			}
			$callback->($buffer);
			last;
		} else {
			sleep(1);
		}
	}
}

1;
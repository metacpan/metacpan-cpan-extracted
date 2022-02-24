package WebService::UK::Parliament::Base;

use Mojo::Base -base;
use Mojo::JSON qw/decode_json/;
use Mojo::UserAgent;

use OpenAPI::Client;

has "client";

has "private";

sub new {
  	my $class = shift;
  	my $self = bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
	my $spec = $self->private ? $self->read_file($self->private_url) : $self->read_url($self->public_url);
	$self->client(OpenAPI::Client->new($spec, base_url => $self->base_url));
	$self->client->ua->on(start => sub {
		my ($ua, $tx) = @_;
		$tx->req->headers->header('accept' => "text/plain");
	});
	$self->client->ua->transactor->name("Mozilla/8.0");
	return $self;
}

sub read_file {
	my ($self, $file) = @_;
	open my $fh, '<', $file or die "Cannot open file for reading: $file $!";
	my $content = do { local $/; <$fh> };
	close $fh;
	return $self->generate_operation_ids(decode_json($content));
}

sub read_url {
	my ($self, $url) = @_;
	my $ua  = Mojo::UserAgent->new;
	my $res = $ua->get($url)->res->json;
	return $self->generate_operation_ids($res);
}

sub generate_operation_ids {
	my ($self, $data) = @_;
	my %dedupe = ();
	delete $data->{info}->{contact};
	for my $path ( keys %{ $data->{paths} } ) {
		(my $clean = $path) =~ s/\/|(api)|(\{[^}]+\})//g;
		for my $method ( keys %{ $data->{paths}->{$path} } ) {
			my $operation_id = $method . $clean;
			$operation_id .= $dedupe{$operation_id} if (defined $dedupe{$operation_id});
			$dedupe{$operation_id}++;
			$data->{paths}->{$path}->{$method}->{operationId} = $operation_id; 
		}
	}
	return $data;
}

sub call {
	my ($self, $path, $id, $params, $content) = @_;
	if (ref $id) {
		$content = $params;
		$params = $id;
	} else {
		$params->{id} = $id;
	}
	my $data = $self->client->call($path, $params ? $params : (), $content ? $content : ());
	return $data->res->json;
}

sub AUTOLOAD {
	my ($self) = shift;
	my $classname =  ref $self;
        my $validname = '[a-zA-Z][a-zA-Z0-9_]*';
        our $AUTOLOAD =~ /^${classname}::($validname)$/;
	my $key = $1;
        die "illegal key name, must be of $validname form\n$AUTOLOAD" unless $key;
	return $self->call($key, @_);
}

1;

__END__

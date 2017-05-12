package Test::HTTP::MockServer::REST;
use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class) = shift;
    $class = ref $class || $class;
    my %dispatch = @_;
    return bless { d => \%dispatch }, $class;
}

sub _wrapped_rest_call {
    my $self = shift;
    my $wrapped = shift;
    return sub {
        # this is the coderef invoked by MockServer
        my ($req, $res) = @_;
        my $input_content = $req->content;
        my $input_data;
        my $input_ct = $req->header("Content-type");
        if ($input_content && $input_ct && $input_ct eq 'application/json') {
            eval {
                $input_data = decode_json $req->content;
            };
            if ($@) {
                $res->code(400);
                $res->message('Malformed Request');
                $res->content($@);
                return;
            }
        }
        my $selected_key;
        my @captures;
        my $s = join " ", $req->method(), $req->uri()->canonical()->path();
        foreach my $key (keys %{$self->{d}}) {
            my $rx = $self->{d}{$key};
            if (@captures = ($s =~ $rx)) {
                $selected_key = $key;
                last;
            }
        }
        if (!$selected_key) {
            $res->code(404);
            $res->message('Page not found');
            $res->content("$s not found");
            return;
        }

        my $return_data = $wrapped->(
            $selected_key, $req, $res, \@captures, $input_data
        );

        if ($return_data) {
            my $a = $req->header('Accept');
            if ($a && $a eq 'application/json') {
                eval {
                    my $out = encode_json $return_data;
                    $res->header('Content-type', 'application/json');
                    $res->content($out);
                };
                if ($@) {
                    $res->code(500);
                    $res->message('Internal Server Error');
                    $res->content($@);
                    return;
                }
            } else {
                $res->code(400);
                $res->message('Malformed Request');
                $res->content("Only support Accept: application/json");
                return;
            }
        }
    };
}

sub wrap_object {
    my $self = shift;
    my $object = shift;
    return $self->_wrapped_rest_call(
        sub {
            my $key = shift;
            return $object->$key(@_);
        }
    );
}

sub wrap_hash {
    my $self = shift;
    my $hash = shift;
    return $self->_wrapped_rest_call(
        sub {
            my $key = shift;
            return $hash->{$key}->(@_)
        }
    );
}

1;

__END__

=head1 NAME

Test::HTTP::MockServer::REST - REST Helper for Test::HTTP::MockServer

=head1 SYNOPSIS

  my $rest = Test::HTTP::MockServer::REST->new(
     'methoda_GET'  => qr{^GET /foo/([a-z0-9]+)/bar$},
     'methoda_POST' => qr{^POST /foo/([a-z0-9]+)/bar$},
  );
  
  # use an object, where methoda_GET and methoda_POST will be called
  my $requestprocessor = $rest->wrap_object(MyMockServer->new());
  
  # alternatively, just use a hash
  my $requestprocessor = $rest->wrap_hash({ methoda_GET => sub { ... } })

=head1 DESCRIPTION

This is a helper class to be used with Test::HTTP::MockServer to
easily implement the mock of a REST service, you will provide the
identifier to the operation and a regex to match the request against.

=head1 METHODS

=over

=item new

Creates a new helper. It takes a hash as input, where the key is the
identifier of the operation and the value is a regular expression to
be applied against the string "$method $path" with $method being the
all-caps http method name and $path being the path sent in the
request.

=item wrap_object

Return a coderef to be used as the request processor that dispatches
the calls as methods in the given object. If the object doesn't
implement the method listed, it will fail with error 500.

=item wrap_hash

A simplified version that dispatches based on a simple hash.

=back

=head1 CALLING THE WRAPPED CODE

The following arguments are sent to the code called by the wrapper:

=over

=item $self (wrap_object version only)

If the code was wrapped with wrap_object, the object-oriented calling
convention will be followed, therefore $self will be the first
argument. However, in the wrap_hash case, the invocation happens as a
simple invocation of the code reference, so there is no $self.

=item $request

The HTTP::Request object.

=item $response

The HTTP::Response object.

=item $captures

An array reference with the items captured by the regex.

=item $data

Decoded data submitted in the request. For now this is only available
if the input content type is 'application/json'.

=back

If data is returned by the code, and the request had an appropriate
Accept header, the data will be encoded in the given content type (for
now only JSON is supported).

If the code returns any data but there is no Accept header or the
accepted type is not supported, it will cause a failure.

=head1 COPYRIGHT

Copyright 2016 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

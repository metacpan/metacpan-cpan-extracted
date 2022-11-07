#!/usr/bin/env perl
package WebService::MyJSONs;
use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.002' }

use Carp qw< croak >;
use HTTP::Tiny;
use Scalar::Util 'blessed';
use Exporter 'import';

our @EXPORT_OK   = map { +"myjsons_$_" }
   qw< cmdline get get_json put put_json >;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
our $DEFAULT_ENDPOINT = 'https://www.myjsons.com';

sub code ($self, @new) {
   $self->{code} = $new[0] if @new > 0;
   return $self->{code};
}

sub __dump ($d) {
   require Data::Dumper;
   no warnings 'once';
   local $Data::Dumper::Indent = 1;
   print {*STDERR} Dumper($d);
} ## end sub __dump

sub get ($self, $code = undef) {
   require JSON::PP;
   return JSON::PP::decode_data($self->get_json($code));
}

sub get_json ($self, $code = undef) {
   $self = $self->new unless blessed $self;
   $code //= $self->code;
   croak "no code set for retrieval" unless defined $code;

   my $response = HTTP::Tiny->new->get($self->_url(v => $code));
   $self->{response_callback}->($response) if $self->{response_callback};
   __dump($response)                       if $ENV{MYJSONS_DUMP_RESPONSE};

   croak "Failed: $response->{status} $response->{reason}"
     unless $response->{success};
   return $response->{content};
} ## end sub get_json

sub myjsons_cmdline ($op = 'help', $code = undef) {
   my $p2u = sub ($message = undef) {
      require Pod::Usage;
      Pod::Usage::pod2usage(
         -input => __FILE__,
         -verbose => 99,
         -sections => 'NAME|SYNOPSIS',
         (defined $message ? (-message => $message) : ()),
      );
   };
   $p2u->() if $op =~ m{\A(?: -h | --help | help )\z}imxs;

   if ($op eq 'get') {
      $p2u->('undefined code for operation') unless defined $code;
      print {*STDOUT} __new($code)->get_json;
   }
   elsif ($op eq 'put') {
      my $json = do { local $/; <STDIN> };
      print {*STDOUT} __new($code)->put_json($json)->code;
   }
   else {
      $p2u->('invalid operation');
   }

   return 0;
} ## end if (!caller)

sub myjsons_get      ($code) { __new($code)->get }
sub myjsons_get_json ($code) { __new($code)->get_json }

sub myjsons_put (@args) {
   my ($code, $data) = @args == 1 ? (undef, $args[0]) : @args[0, 1];
   return __new($code)->put($data)->code;
}

sub myjsons_put_json (@args) {
   my ($code, $json) = @args == 1 ? (undef, $args[0]) : @args[0, 1];
   return __new($code)->put_json($json)->code;
}

sub new ($package, %args) {
   my $self = bless {
      code              => $args{code},
      endpoint          => ($args{endpoint} // $DEFAULT_ENDPOINT),
      response_callback => $args{response_callback},
   }, $package;
   return $self;
} ## end sub new

sub __new ($code) { __PACKAGE__->new(code => $code) }

sub put ($self, @args) {
   require JSON::PP;
   my ($code, $data) = @args == 1 ? (undef, $args[0]) : @args[0, 1];
   return $self->put_json($code, JSON::PP::encode_json($data));
}

sub put_json ($self, @args) {
   $self = __PACKAGE__->new unless blessed $self;
   my ($code, $json) = @args == 1 ? (undef, $args[0]) : @args[0, 1];
   $code //= $self->{code};

   my $url = $self->_url(defined($code) ? (e => $code) : ());
   my $response = HTTP::Tiny->new->post_form($url, {json => $json});
   $self->{response_callback}->($response) if $self->{response_callback};
   __dump($response)                       if $ENV{MYJSONS_DUMP_RESPONSE};

   croak "Failed: $response->{status} $response->{reason}"
     unless $response->{status} == 302;

   $self->code($response->{headers}{location} =~ m{/([^/]+)\s*\z}mxs)
     unless defined $code;
   return $self;
} ## end sub put_json

sub _url ($s, @pts) { join '/', ($s->{endpoint} =~ s{/+\z}{}rmxs), @pts }

exit myjsons_cmdline(@ARGV) unless caller;

1;
__END__

=pod

=encoding utf8

=head1 NAME

myjsons - interact with https://www.myjsons.com/ from the command line

=head1 SYNOPSIS

   # print a help message
   myjsons

   # create a new remote item, save code in env variable
   code=$(myjsons put </path/to/stuff.json)

   # update a remote item
   myjsons put $code </path/to/stuff.json

   # retrieve JSON stuff, printed on STDOUT
   myjsons get $code | jq .

=cut

package UserAgent::Any::Impl::Helper;

use 5.036;

use Carp;
use Exporter 'import';
use List::Util 'pairs';
use Readonly;
use UserAgent::Any::Response;

Readonly our @EXPORT_OK => qw(get_call_args generate_methods new_response params_to_hash);
Readonly our %EXPORT_TAGS => ('all' => \@EXPORT_OK);

Readonly our $VERSION => 0.01;

Readonly our @METHODS => qw(delete get head patch post put);
Readonly our @METHODS_WITH_DATA => qw(patch post put);
Readonly our %METHODS_WITH_DATA => map { $_ => 1 } @METHODS_WITH_DATA;
Readonly our @METHODS_WITHOUT_DATA => grep { !$METHODS_WITH_DATA{$_} } @METHODS;

sub get_call_args {  ## no critic (RequireArgUnpacking)
  my ($self, $method, $url) = (shift, shift, shift);
  my $content;
  $content = pop if @_ % 2 && $METHODS_WITH_DATA{$method};
  # Here, we can’t be in the $METHODS_WITH_DATA{$method} case.
  croak 'Invalid number of arguments, expected an even sized list after the url' if @_ % 2;
  return ($self, $method, $url, \@_, \$content,);
}

sub generate_methods {
  my $dest_pkg = caller(0);

  for my $m (@METHODS) {
    no strict 'refs';  ## no critic (ProhibitNoStrict)
    *{"${dest_pkg}::${m}"} = sub ($self, @args) { $self->call($m, @args) };
    *{"${dest_pkg}::${m}_cb"} = sub ($self, @args) { $self->call_cb($m, @args) };
    *{"${dest_pkg}::${m}_p"} = sub ($self, @args) { $self->call_p($m, @args) };
  }
  return;
}

sub new_response {
  my ($r) = @_;  # The undef is $self that we are not using.
  return UserAgent::Any::Response->new($r);
}

sub params_to_hash (@params) {
  my %hash;
  for my $kv (pairs @params) {
    my $v = $hash{$kv->key};
    if (defined $v) {
      if (ref($v)) {
        push @{$v}, $kv->value;
      } else {
        $hash{$kv->key} = [$v, $kv->value];
      }
    } else {
      $hash{$kv->key} = $kv->value;
    }
  }
  return \%hash;
}

1;

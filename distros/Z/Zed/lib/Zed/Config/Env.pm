package Zed::Config::Env;
use Term::ReadPassword;

=head1 NAME

Zed::Config::Env - Zed runtime variables.

=head1 SYNOPSIS

  use Zed::Config::Env;

  env 'foo' => 'value';    #Set foo
  env 'foo';               #Get foo

  passwd;                  #Get password. Input it if not defined.
  passwd(undef);           #Get password. Force to input it.

=cut

use base Exporter;
our @EXPORT = qw( env passwd );

use Zed::Output;
use base Zed::Config;

our $NAME = "Env";

sub env
{
    my ($key, $value) = @_;
    my $config = __PACKAGE__->config;
    debug("config", $config);
    debug("key:|$key| value:|$value|");
    $key ? $value ? $config->{$key} = $value : $config->{$key}
         : wantarray ? %$config : \%{$config};
}

my $passwd;

sub passwd
{
    $passwd = $_[0] if @_;
    $passwd ||= read_password('password: ');
}
1;

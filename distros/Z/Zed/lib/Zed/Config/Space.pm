package Zed::Config::Space;

use base Zed::Config;
use base Exporter;

use Zed::Range::Parser;

=head1 NAME

Zed::Config::Space - Control operation target space.

=head1 SYNOPSIS

  use Zed::Config::Space;

  space 'foo' => ['localhost'];     #add target to space 'foo'
  usespace 'foo';                   #switch target space to 'foo'

  my %one_target = space 'foo';     #return target in space 'foo'
  my %all_target = space;           #return all target in space

=cut

our @EXPORT = qw(targets space space_clean usespace );

use Zed::Output;
our $NAME = "Space";

my $use;

sub usespace
{ 
    my $key = shift;
    $use = $key =~ /^(none|undef)$/ ?  undef : $key if $key;
    $use
}

sub load
{
    my $this = shift;
    $this->SUPER::load();

    my $config = $this->config;

    debug("config:", $config);
    while(my($k, $v) = each %$config)
    {
        debug("key $k:", $v);
        next unless ref $v eq 'ARRAY';
        my @host = map{ Zed::Range::Parser->parse($_)->dump }@$v;
        debug("parse:", \@host);
        $config->{$k} = \@host;
    }
    debug("config:", $config);
}
sub dump
{
    my $this = shift;

    my $config = __PACKAGE__->config;
    for(keys %$config)
    {
        delete $config->{$_} if $_ =~ /\.(group\d+|suc|fail)$/;
    }
    $this->SUPER::dump();
}
sub space_clean
{
    my $pat = shift;
    my $config = __PACKAGE__->config;
    $pat = qr/^$pat\d+/;
    map{ delete $config->{$_} if $_ =~ $pat }keys %$config;
}

sub targets
{
    error("use no space!") and return unless $use;
    space($use);
}

sub space
{
    my ($key, $value) = @_;
    my $config = __PACKAGE__->config;
    debug("config", $config);
    debug("key:|$key| host:", $value);
    $key ? $value ? $config->{$key} = $value 
         : wantarray ? @{ $config->{$key} } : \@{ $config->{$key} }
         : wantarray ? %$config : \%{$config};
}
1;

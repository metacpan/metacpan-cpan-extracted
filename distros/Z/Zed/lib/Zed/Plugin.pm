package Zed::Plugin;

=head1 NAME

Zed::Plugin - Zed plugin management.

=head1 SYNOPSIS

  package Zed::Plugin::Sys::Echo;
  
  use Zed::Plugin;
  
  =head1 SYNOPSIS
  
      Echo some string just for testing plugin
      ex:
          echo foo bar
  
  =cut

  invoke "echo" => sub {                #function invoke
      print for @_;
      print "\n";

  }, sub{ qw(foo foo1 foo2) };          #matchs parameter
  
  1

=cut

use base Exporter; our @EXPORT = qw(invoke after_invoke);

use Zed::Output;
use Pod::Usage;
use Pod::Find qw(pod_where);

my( %plugins, %invoke, %complete_first );

sub plugins{ wantarray ? %plugins : {%plugins} }
sub complete_first{ $complete_first{ $_[0] } }

sub help
{
    my $cmd = shift;
    info("$cmd not defined") and return unless $plugins{invoke}->{$cmd};

    my $pod = pod_where({-inc => 1}, $plugins{invoke}->{$cmd});
    info("$cmd do not have pod") and return  unless $pod;

    Pod::Usage::pod2usage( -input => $pod, -output => \*STDERR, -verbose => 0, -exitval => 'NOEXIT' );
}

sub invoke
{
    my( $cmd, $sub, $complete_first ) = @_;
    return $invoke{$cmd} if $cmd && !$sub;

    my $des = "invoke plugin(cmd: $cmd)";
    my($package, $filename, $line) = caller;

    warn "load $des from $package failed\n" and return 
        unless $cmd && $sub
        && ref $sub eq 'CODE';

    warn "redefine $des in $package\n" if $invoke{ $cmd };

    $invoke{ $cmd } = $sub;

    $complete_first{ $cmd } = $complete_first 
                           if $complete_first && ref $complete_first eq 'CODE';

    $plugins{invoke}->{$cmd} = $package;

    debug( "load $des from $package suc" );
}


1;

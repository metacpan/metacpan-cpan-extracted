package Zed::Output;

=head1 NAME

Zed::Output - export some output method used by zed.

=head1 SYNOPSIS

  use Zed::Output;
  
  info   "info~~";
  error  "error~~";
  result 'first'  => 0, "bla bla fail~~";
  result 'second' => 1, "bla bla suc~~";
  text   "text~~";
  
  Zed::Output::_debug("PackageA");
  Zed::Output::_debug_off("PackageB");
  
  package PackageA;
  use Zed::Output;
  
  debug("debug msg!");
  
  package PackageB;
  use Zed::Output;
  
  debug("debug msg! you can't see!");

=cut

use base Exporter;
our @EXPORT = qw( debug info error result text);

use Term::ANSIColor qw(:constants colored);
$Term::ANSIColor::AUTORESET = 1;
use Data::Printer output => 'stdout';

my %switch;
sub _debug { my $pack = shift; $switch{ $pack } = 1;};
sub _debug_off { my $pack = shift; delete $switch{ $pack }; };

sub debug 
{
    my($package, $filename, $line) = caller;
    return unless $switch{ $package }; 
    print "[$package:$line] ";  
    ref $_ ? p $_ : print $_ for @_;
    print "\n" unless ref $_[-1]
}
sub result
{
    my( $prefix, $suc, $str ) = @_;
    print "[$prefix] ", $suc ?  colored(['green'], $str) : colored(['red'], $str), "\n";
}
sub info { _out('yellow', @_) }
sub error { _out('red', @_) }
sub text { _out('white', @_) }

sub _out
{
    my ( $color, $str, $out ) = shift;
    for(@_)
    {
        if( ref $_)
        {

            $out .= np(%$_, colored => 1) if ref $_ eq 'HASH';
            $out .= np(@$_, colored => 1) if ref $_ eq 'ARRAY';
            next;
        }
        $str = $_;
        while($str =~ /\[.+?\]/)
        {
            debug "prefix: |$`|";
            debug "match: |$&|";
            debug "suffix: |$'|";
            $out .= colored([$color], $`);
            $out .= colored([$color,'bold'], $&);
            $str = $';

        }
        $out .= colored([$color], $str);
        debug "out:|$out|";
    }
    $out =~ s/(\n*)?$/\n/;
    $out =~ s/(suc|success)/colored(['green'], $1)/ge;
    $out =~ s/(fail|failed)/colored(['red'], $1)/ge;
    print $out;
}

1;

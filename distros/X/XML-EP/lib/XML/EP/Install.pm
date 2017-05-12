# -*- perl -*-

use strict;

use Data::Dumper ();
use Symbol ();

package XML::EP::Install;

$XML::EP::Install::VERSION = '0.01';

sub new {
    my $proto = shift;
    my $self = [ (@_ == 1) ?  @{shift()} : @_ ];
    bless($self, "XML::EP::Install");
}

sub Save {
    my $self = shift;  my $file = shift;
    my $array = [ @$self ];
    my $dump = Data::Dumper->new([$array])->Terse(1)->Indent(1)->Dump();
    my $fh = Symbol::gensym();
    (open($fh, ">$file") and
     (print $fh "package XML::EP::Config;\n\$XML::EP::Config::config = $dump\n") and
     close($fh))  ||  die "Failed to create config file $file: $!";
}

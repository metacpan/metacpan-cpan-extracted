# -*- perl -*-

package XML::EP::Error;

$XML::EP::Error::VERSION = '0.01';

sub new {
    my $proto = shift;  my $msg = shift;  my $code = shift;
    $self = { msg => $msg, code => $code };
    bless($self, (ref($proto) || $proto));
}

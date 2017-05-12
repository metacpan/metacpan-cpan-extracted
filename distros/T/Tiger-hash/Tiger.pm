package Tiger;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Exporter;
require DynaLoader;
require AutoLoader;
@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default
@EXPORT = qw();
$VERSION = '1.0';

bootstrap Tiger $VERSION;

sub addfile
{
    no strict 'refs';
    my ($self, $handle) = @_;
    my ($package, $file, $line) = caller;
    my $data = ' ' x 8192;

    if (!ref($handle)) {
	$handle = "$package::$handle" unless ($handle =~ /(\:\:|\')/);
    }
    while (read($handle, $data, 8192)) {
	$self->add($data);
    }
}

sub hexdigest
{
    my ($self) = shift;
    my ($tmp);

    $tmp = unpack("H*", ($self->digest()));
    return(substr($tmp, 0,16) . " " . substr($tmp, 16,16) . " " .
	   substr($tmp,32,16));
}

sub hash
{
    my($self, $data) = @_;

    if (ref($self)) {
	$self->reset();
    } else {
	$self = new Tiger;
    }
    $self->add($data);
    $self->digest();
}

sub hexhash
{
    my($self, $data) = @_;

    if (ref($self)) {
	$self->reset();
    } else {
	$self = new Tiger;
    }
    $self->add($data);
    $self->hexdigest();
}

1;
__END__

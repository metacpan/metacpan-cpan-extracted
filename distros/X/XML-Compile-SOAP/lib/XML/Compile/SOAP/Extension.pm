# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::Extension;
use vars '$VERSION';
$VERSION = '3.21';

use Log::Report 'xml-compile-soap';

my @ext;


sub new($@) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my $self = shift;
    trace "loading extension ".ref $self;
    push @ext, $self;
    $self;
}

#--------

### For all methods named below: when called on an object, it is the stub
### for the extension. Only when called as class method, it will walk all
### extension objects.

sub wsdl11Init($$)
{   ref shift and return;
    $_->wsdl11Init(@_) for @ext;
}

#--------

sub soap11OperationInit($$)
{   ref shift and return;
    $_->soap11OperationInit(@_) for @ext;
}


sub soap11ClientWrapper($$$)
{   ref shift and return $_[1];
    my ($op, $call, $args) = @_;
    $call = $_->soap11ClientWrapper($op, $call, $args) for @ext;
    $call;
}


sub soap11HandlerWrapper($$$)
{   my ($thing, $op, $cb, $args) = @_;
    ref $thing and return $cb;
    $cb = $_->soap11HandlerWrapper($op, $cb, $args) for @ext;
    $cb;
}

#--------

sub soap12OperationInit($$)
{   ref shift and return;
    $_->soap12OperationInit(@_) for @ext;
}


sub soap12ClientWrapper($$$)
{   ref shift and return $_[1];
    my ($op, $call, $args) = @_;
    $call = $_->soap12ClientWrapper($op, $call, $args) for @ext;
    $call;
}


sub soap12HandlerWrapper($$$)
{   my ($thing, $op, $cb, $args) = @_;
    ref $thing and return $cb;
    $cb = $_->soap12HandlerWrapper($op, $cb, $args) for @ext;
    $cb;
}


1;

package VSGDR::UnitTest::TestSet::Representation;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.02';


use parent qw(Clone) ;

#TODO 1. Add support for test method attributes eg new vs2010 exceptions  ala : -[ExpectedSqlException(MessageNumber = nnnnn, Severity = x, MatchFirstError = false, State = y)]


use IO::File;

use Data::Dumper ;
use Carp ;

use vars qw($AUTOLOAD );

my %Types = ('XML'     => 1
             ,'NET::CS' => 1
             ,'NET::VB' => 1
             ,'XLS'     => 1
             ,'NET2::CS' => 1
             ,'NET2::VB' => 1
             ) ;


sub new {

    local $_ = undef ;

    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;

    my @elems            = @_ ;
    my $self             = bless {}, $class ;
   
    $self->_init(@elems) ;
    return $self ;
}


sub _init {

    local $_ = undef ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;

    return ;
    
}


sub make {

    local $_ = undef ;
    my $self         = shift ;

    my $objectType        = $_[0]->{TYPE} or croak 'No Representation type' ;
    croak "Invalid Representation language type " unless exists $Types{$objectType };
    ( my $objectTypePathFileName = ${objectType} ) =~ s{::}{/}xg ;
    require "VSGDR/UnitTest/TestSet/Representation/${objectTypePathFileName}.pm";
    return "VSGDR::UnitTest::TestSet::Representation::${objectType}"->new(@_) ;

}

## default standard implementations of code below..............
##XLS has to override them.
## ======================================================
sub serialise {
    my $self        = shift or croak 'no self' ;
    my $file        = shift or croak 'no file' ;
    my $object      = shift or croak 'no object';
    
    my $code        = $self->deparse($object);    
    
    my $data;
    my $fh = new IO::File "> ${file}" ;
    if (defined ${fh} ) {
        print ${fh} $code;
        $fh->close;
    }
    else {
        croak "Unable to write to ${file}.";
    }
    return ;
}
## ======================================================
sub deserialise {

    my $self        = shift or croak 'no self' ;
    my $file        = shift or croak 'no file' ;
    my $data;
    my $fh = new IO::File;
    if ($fh->open("< ${file}")) {
        { local $/ = undef ; $data = <$fh> ; }     
        $fh->close;
    }
    else {
        croak "Unable to read from ${file}.";
    }
    my $object    = $self->parse($data);
    return ${object} ;
}
## ======================================================


1 ;


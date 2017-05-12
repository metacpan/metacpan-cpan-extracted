#!/usr/bin/perl -w

use strict;
use Test::More;

# hack-mock Net::SMTP::SSL
BEGIN {
    package Net::SMTP::SSL;
    $INC{"Net/SMTP/SSL.pm"} = 1;
    use vars qw/@ISA/;
    @ISA = qw/Net::SMTP/;

    package Net::SMTP;
    $INC{"Net/SMTP.pm"} = 1;
    sub new { return bless {} }
    use vars qw/$AUTOLOAD $Response %Data/;
    $Response = 1;
    sub data { 1 }
    sub dataend { 1 }
    sub quit { return $Response }
    sub AUTOLOAD {
        my $self = shift;
        if ( @_ ) { $Data{ $AUTOLOAD } = [ @_ ] }
        return @{ $Data{ $AUTOLOAD } || [] };
    }
    
}

#--------------------------------------------------------------------------#

my $from = 'johndoe@example.net';

#--------------------------------------------------------------------------#

plan tests => 4;

require_ok( 'Test::Reporter' );

#--------------------------------------------------------------------------#
# simple test
#--------------------------------------------------------------------------#

my $reporter = Test::Reporter->new( transport => 'Net::SMTP::SSL' );
isa_ok($reporter, 'Test::Reporter');

$reporter->grade('pass');
$reporter->distribution('Mail-Freshmeat-1.20');
$reporter->distfile('ASPIERS/Mail-Freshmeat-1.20.tar.gz');
$reporter->from($from);

my $form = {
    key     => 123456789,
    via     => my $via = "Test::Reporter ${Test::Reporter::VERSION}",
    from    => $from,
    subject => $reporter->subject(),
    report  => $reporter->report(),
};

{
    local $Net::SMTP::Data;
    my $rc = $reporter->send;
    ok( $rc, "send() is true when successful" ) or diag $reporter->errstr;
}

{
    local $Net::SMTP::Data;
    local $Net::SMTP::Response = 0; # ok
    my $rc = $reporter->send;
    ok( ! $rc, "send() false on failure" ) or diag $reporter->errstr;
}

#--------------------------------------------------------------------------#
# test specifying arguments in the constructor
#--------------------------------------------------------------------------#
#
#my $transport_args = [$url, $form->{key}];
#
#$reporter = Test::Reporter->new(
#  transport => "HTTPGateway",
#  transport_args => $transport_args,
#);
#isa_ok($reporter, 'Test::Reporter');
#
#is_deeply( [ $reporter->transport_args ], $transport_args,
#  "transport_args set correctly by new()"
#);

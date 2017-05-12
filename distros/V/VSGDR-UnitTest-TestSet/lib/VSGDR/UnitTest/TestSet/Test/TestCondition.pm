package VSGDR::UnitTest::TestSet::Test::TestCondition;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.01';


#TODO 1. Add support for test method attributes eg new vs2010 exceptions  ala : -[ExpectedSqlException(MessageNumber = nnnnn, Severity = x, MatchFirstError = false, State = y)]


use Data::Dumper ;
use Carp ;


use vars qw($AUTOLOAD );

my %Types = (ScalarValue=> 1
             ,EmptyResultSet=> 1
             ,ExecutionTime=> 1
             ,Inconclusive=> 1
             ,NotEmptyResultSet=> 1
             ,RowCount=> 1
             ,Checksum=>1
             ,ExpectedSchema=>1
             );

sub make {

    local $_ = undef ;
    my $self         = shift ;
    my $objectType        = $_[0]->{TESTCONDITIONTYPE} or croak 'No object type' ;
    croak "Invalid Test Condition Type" unless exists $Types{$objectType };
    
    require "VSGDR/UnitTest/TestSet/Test/TestCondition/${objectType}.pm";
    return "VSGDR::UnitTest::TestSet::Test::TestCondition::${objectType}"->new(@_) ;

}

sub new {

    local $_ = undef ;

    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;

    my @elems            = @_ ;
    my $self             = bless {}, $class ;
   
    $self->_init(@elems) ;
    return $self ;
}


sub ok_field {
    my $self    = shift;
    my $attr    = shift;
    return $self->{OK_FIELDS}->{$attr} ;
}

sub commentifyName {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->conditionName()]}
            ${commentChars}
EOF
}

sub testAction {
    my $self    = shift;
    my $ta = $self->{CONDITIONTESTACTIONNAME} ;
    return $ta;
} 

sub testConditionAttributes {
    my $self    = shift;
    return keys %{$self->{OK_FIELDS}} ;
}
sub testConditionAttributeType {
    my $self    = shift;
    my $attr    = shift or croak 'no attribute' ;
    croak 'bad attribute'unless $self->ok_field($attr) ;
#warn Dumper $self->{OK_FIELDS_TYPE} ;    
    return $self->{OK_FIELDS_TYPE}->{$attr} ;
}

sub testConditionAttributeName {
    my $self    = shift;
    my $attr    = shift or croak 'no attribute' ;
    croak 'bad attribute'unless $self->ok_field($attr) ;
    ( my $n = $attr ) =~ s{^condition}{}x;
    return $n ;
}

sub conditionISEnabled {
    local $_                = undef ;
    my $self                = shift ;
    if ( $self->conditionEnabled() =~ m{\A 1 \z}ix ) {
        return scalar 1 ;
    }
    elsif ( $self->conditionEnabled() =~ m{\A True \z}ix ) {
        return scalar 1 ;
    }
    else {
        return scalar 0 ;
    }
}




sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
#warn Dumper $attr ;    
    $attr =~ s{.*::}{}x;
    return unless $attr =~ m{[^A-Z]}x;  # skip DESTROY and all-cap methods
#warn Dumper $attr ;    
#warn Dumper $ok_field{$attr} ;
#warn Dumper %ok_field;
    croak "invalid attribute method: ->$attr()" unless $self->ok_field($attr);
    
    my $UC_ATTR     = uc $attr ;
      
    $self->{$UC_ATTR} = shift if @_;
    return $self->{$UC_ATTR};
}


1 ;

__DATA__


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#print "#",q[],"\n";
#print "#",q[],"\n";
#print "#",q[],"\n";

use Test;
BEGIN { plan tests => 42, todo => [] }

use XML::TokeParser;

ok(1);

#parse from file
my $p = XML::TokeParser->new('TokeParser.xml');

ok($p);

my @tokens =(
      'S',
      'T',
      'S',
      'T',
      'S',
      'T',
      'E',
      'T',
      'E',
      'T',
      'S',
      'T',
      'S',
      'T',
      'E',
      'T',
      'S',
      'T',
      'E',
      'T',
      'S',
      'T',
      'E',
      'T',
      'S',
      'T',
      'E',
      'T',
      'S',
      'T',
      'E',
      'T',
      'S',
      'T',
      'E',
      'T',
      'S',
      'T',
      'E',
      'T'
);


my %Token2Method = (
    S  => 'is_start_tag',
    E  => 'is_end_tag',
    T  => 'is_text',
    C  => 'is_comment',
    PI => 'is_pi',
);


print "#",q[],"\n";
#push @tokens, ( $p->get_token() )->[0] for 1..40;use Data::Dumper;die Dumper\@tokens;

for( 0.. $#tokens ) {
    my $token = $p->get_token();

#use Data::Dumper;print Dumper $token;

    my $method = $Token2Method{$token->[0]} || 'is_tag';

    print '#$ ', $token->$method() ,$/;
    print '#$ ', $token->is_start_tag(),$/;

    ok( $token->$method() );
    
}

#$p->get_token()->toke;

__END__

sub is_start_tag {
    if( $_[0]->[0] eq 'S' ){
        if(defined $_[1]){
            return 1 if $_[0]->[1] eq $_[1];
        } else {
            return 1;
        }
    }
}

sub is_end_tag {
    if( $_[0]->[0] eq 'E' ){
        if(defined $_[1]){
            return 1 if $_[0]->[1] eq $_[1];
        } else {
            return 1;
        }
    }
}

sub is_tag {
    if( $_[0]->[0] eq 'S' or $_[0]->[0] eq 'E' ){
        if(defined $_[1]){
            return 1 if $_[0]->[1] eq $_[1];
        } else {
            return 1;
        }
    }
}


## the old ones
sub is_start_tag           { return $_[0]->_is( S => $_[1] ); }
sub is_end_tag             { return $_[0]->_is( E => $_[1] ); }
sub is_tag                 { return $_[0]->_is( S => $_[1] )
                                 || $_[0]->_is( E => $_[1] ); }

sub _is {
    if($_[0]->[0] eq $_[1]){
        if(defined $_[2]){
            return 1 if $_[0]->[1] eq $_[2];
        }else{
            return 1;
        }
    }
    return 0;
}
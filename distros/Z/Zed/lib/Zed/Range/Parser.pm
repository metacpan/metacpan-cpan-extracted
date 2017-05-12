package Zed::Range::Parser;
use strict;

use Zed::Output;
use Zed::Range::Set;

#  i{01~09,-05}.xx.corp.net,i{1~3,9}.yy.corp.com,-/4/,&/net/
#transter to:
#  i*{01~09-05}*.xx.corp.net,i*{1~3,9}*.yy.corp.com-/4/&/net/
#priority:
#  0: }
#  1: - &
#  2: ,
#  3: *
#  4: ~
#  5: { 

our %PRI = (
 '}' => 0, '#' => 0,
 '-' => 1, '&' => 1,
 ',' => 2,
 '*' => 3,
 '~' => 4,
 '{' => 5,
);

sub _pri { $_[0] eq '{' ? $_[1] eq '}' : $PRI{ $_[0] } >= $PRI{ $_[1] } }

sub _toset{ map{ ref $_ ? $_ : Zed::Range::Set->new($_) }@_ }

sub oprange
{
    my $values = shift;
    return if @$values < 2;

    my ($a, $b, $zero) = splice @$values, -2 ,2;

    map{$zero = length $_ if $zero < length $_; s/^(0*)//; }($a, $b);

    my @num = $a > $b ? ($b..$a) : ($a..$b);
    debug("num:", \@num);
    debug("zero:", $zero);

    my $set = Zed::Range::Set->new( map{sprintf "%0$zero\d",$_}@num );
    push @$values, $set;

}
sub opdescart
{
    my $values = shift;
    my ($a, $b) = _toset( splice @$values, -2 ,2 );
    push @$values, $a*$b;
    
}
sub opunion 
{
    my $values = shift;
    my ($a, $b) = _toset( splice @$values, -2 ,2 );
    push @$values, $a + $b;
}
sub opdiff
{
    my $values = shift;
    my ($a, $b) = splice @$values, -2 ,2;
    $a = ref $a ? $a : Zed::Range::Set->new($a);
    $b = ref $b ? $b : $b =~ qr!^/(.*)/$! ? $1 : Zed::Range::Set->new($b);
    push @$values, $a - $b;
}
sub opintersec
{
    my $values = shift;
    my ($a, $b) = splice @$values, -2 ,2;
    $a = ref $a ? $a : Zed::Range::Set->new($a);
    $b = ref $b ? $b : $b =~ qr!^/(.*)/$! ? $1 : Zed::Range::Set->new($b);
    push @$values, $a & $b;
}

sub parse
{
    my( $class, $str )  = @_;       
    $str =~ s/$/#/;
    $str =~ s/,([\,\&])/$1/g;
    #add *
    #foo.{} => foo.*{}
    #{}.bar => {}*.bar
    #{foo,bar}{baz,foobar} => {foo,bar}*{baz,foobar}
    $str =~ s!([\w\.}]){!$1*{!g;
    $str =~ s!}([\w\.])!}*$1!g;

    my @strs = split qr!(,-)|([{},~&*#])!, $str;

    my (@values, @ops);
    my $calcu = sub {
        return if @values < 2;

        #use feature "switch";
        #for(pop @ops) 
        #{
        #    when(/\~/) { oprange(\@values) }
        #    when(/\*/) { opdescart(\@values) }
        #    when(/\,/) { opunion(\@values) }
        #    when(/\-/) { opdiff(\@values) }
        #    when(/\&/) { opintersec(\@values) }
        #}
        $_ = pop @ops;
        {
            if(/\~/) { oprange(\@values);    last }
            if(/\*/) { opdescart(\@values);  last }
            if(/\,/) { opunion(\@values);    last }
            if(/\-/) { opdiff(\@values);     last }
            if(/\&/) { opintersec(\@values); last }
        }

    };
    PARSE: foreach my $str (@strs)
    {
        next unless $str;
        $str =~ s!,-!-!;
        push @values, $str and next unless $str =~ /^[\{\}\,\~\-\&*\#]$/;

        while( $ops[-1] && _pri( $ops[-1], $str ) )
        {
            pop @ops and next PARSE if $ops[-1] eq '{' && $str eq '}';
            $calcu->($str);
        }
        push @ops, $str;
    }
    debug("ops:", \@ops);
    debug("values:", \@values);
    warn "Range expression error!" and return if scalar @ops > 1 || scalar @values > 1;
    my $ret = $values[0];
    return ref $ret ? $ret : Zed::Range::Set->new($ret);
}

1;

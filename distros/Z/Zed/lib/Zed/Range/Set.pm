package Zed::Range::Set;
use strict;
use overload
    '""' => \&dump,
    '*' => \&descartes,
    '&' => \&intersection,
    '-' => \&diff,
    '+' => \&union;

sub new
{
    my( $class, @vars) = @_;
    bless [@vars], $class;
}
sub _list{ map{ ref $_ ? $_ : [$_] }@_ }

sub add
{
    my( $this, @vars ) = @_;
    push @$this, ref $_ ? $_->dump : $_ for @vars;
}

sub union
{
    my( $left, $right ) =  _list(@_);
    Zed::Range::Set->new(@$left, @$right);
}
sub descartes
{
    my @values = _list( splice @_, 0, 2 );
    my( $left, $right ) = $_[0] ? reverse @values : @values;
    
    Zed::Range::Set->new(
        map{ my $front = $_; map{ $front.$_ }@$right }@$left
    );
}
sub intersection
{
    my( $left, $right ) = @_;

    $right = qr/$right/ unless ref $right;
    my $cut = ref $right eq "Regexp" ? sub{$_ =~ $right} : sub{my $t = shift; grep { $t =~ /$_/ } @$right};
    
    Zed::Range::Set->new( grep{ $cut->($_) }@$left );
}
sub diff
{
    my( $left, $right ) = @_;
    $right = qr/$right/ unless ref $right;
    my $cut = ref $right eq "Regexp" ? sub{$_ !~ $right} : sub{my $t = shift; !grep { $t =~ /$_/ } @$right};
    Zed::Range::Set->new( grep{ $cut->($_) }@$left );
}
sub dump
{
    my $self = shift;        
    wantarray ? @$self : $self;
}


1;

__END__

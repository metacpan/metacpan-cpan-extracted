package Text::Orientation::StringOperation;
use String::Multibyte;

sub new{
    return bless { MB => String::Multibyte->new($_[1]) }, $_[0] if $_[1];
    bless {},$_[0];
}

sub length  { $_[0]->{MB} ? $_[0]->{MB}->length($_[1]) : length $_[1] }
sub reverse { $_[0]->{MB} ? $_[0]->{MB}->strrev($_[1]) : reverse $_[1] }
sub substr  {
    my $pkg = shift;
    $pkg->{MB} ? $pkg->{MB}->substr(@_) : 
	substr(shift, shift, shift);
}


1;

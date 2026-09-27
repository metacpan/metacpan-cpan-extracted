package WebDyne::Cloudflare::R2::Error;

use 5.020;
use strict;
use warnings;
use overload '""' => 'as_string', fallback => 1;

our $VERSION='0.001';

sub new {
    my ($class, %opt)=@_;
    my $self=bless({
        name    => $opt{'name'}||'R2_ERROR',
        message => $opt{'message'}||'Cloudflare R2 request failed',
        code    => $opt{'code'},
        cause   => $opt{'cause'},
    }, $class);
    return $self;
}


sub name    { return shift()->{'name'}; }
sub message { return shift()->{'message'}; }
sub code    { return shift()->{'code'}; }
sub cause   { return shift()->{'cause'}; }

sub as_string {
    my ($self)=@_;
    my $code=defined($self->{'code'}) ? " [$self->{'code'}]" : '';
    return "$self->{'name'}$code: $self->{'message'}";
}

1;

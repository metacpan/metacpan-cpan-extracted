package WebDyne::Cloudflare::R2::Object;

use 5.020;
use strict;
use warnings;

our $VERSION='0.001';

sub new {
    my ($class, $value_hr)=@_;
    die "R2 object metadata must be a hash reference\n" unless ref($value_hr) eq 'HASH';
    my $self=bless({%{$value_hr}}, $class);
    return $self;
}


sub key             { return shift()->{'key'}; }
sub version         { return shift()->{'version'}; }
sub size            { return shift()->{'size'}; }
sub etag            { return shift()->{'etag'}; }
sub http_etag       { return shift()->{'http_etag'}; }
sub uploaded        { return shift()->{'uploaded'}; }
sub http_metadata   { return shift()->{'http_metadata'}; }
sub custom_metadata { return shift()->{'custom_metadata'}; }
sub storage_class   { return shift()->{'storage_class'}; }
sub range           { return shift()->{'range'}; }
sub body            { return shift()->{'body'}; }

sub as_hash {
    my ($self)=@_;
    return {%{$self}};
}

1;

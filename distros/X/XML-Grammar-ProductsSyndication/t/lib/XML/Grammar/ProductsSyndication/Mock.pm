package XML::Grammar::ProductsSyndication::Mock;

use strict;
use warnings;

use File::Spec;

BEGIN
{
    $INC{'LWP/UserAgent.pm'} = "/usr/lib/perl5/site_perl/5.8.6/LWP/UserAgent.pm",
    $INC{'XML/Amazon.pm'} = "/usr/lib/perl5/site_perl/5.8.6/XML/Amazon.pm",
}

package XML::Amazon;

our @got_new_params;
sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self = shift;
    push @got_new_params, [@_];
    return 0;
}

sub asin
{
    my $self = shift;
    my $asin = shift;

    return XML::Amazon::Item->new($asin);
}

package XML::Amazon::Item;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

our @got_new_params = ();

sub _init
{
    my $self = shift;

    push @got_new_params, [@_];

    my ($asin) = @_;

    $self->{asin} = $asin;

    return 0;
}

our @got_image_params = ();

sub image
{
    my ($self, $size) = @_;
    push @got_image_params, [$size];
    return "http://www.amazon.com/image-for/size=$size/asin=$self->{asin}/";
}

package LWP::UserAgent;

our @got_get_params;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init 
{
    return 0;
}

sub get
{
    my $self = shift;

    push @got_get_params, [@_];

    my $url = shift;

    if ($url !~ m{http://www.amazon.com/image-for/size=(\w+)/asin=(\w+)/})
    {
        die "Incorrect url.";
    }
    
    my ($size, $asin) = ($1, $2);

    return HTTP::Response->new({size => $size, asin => $asin});
}

package HTTP::Response;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ($self, $args) = @_;

    $self->{asin} = $args->{asin};
    $self->{size} = $args->{size};

    return 0;
}

sub is_success
{
    return 1;
}

sub content
{
    my $self = shift;
    my $asin = $self->{asin};
    my $size = $self->{size};

    open my $in, "<", File::Spec->catfile("t", "data", "images", "$asin-$size.jpg");
    my $content;
    {
        local $/;
        $content = <$in>;
    }
    close ($in);

    return $content;
}

1;


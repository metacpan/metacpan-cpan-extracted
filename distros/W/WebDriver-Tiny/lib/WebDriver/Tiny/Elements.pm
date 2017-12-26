package WebDriver::Tiny::Elements 0.100;

use 5.020;
use feature 'postderef';
use warnings;
no  warnings 'experimental::postderef';

# Manip
sub append { bless [ shift->@*, map @$_[ 1.. $#$_ ], @_ ] }
sub first  { bless [ $_[0]->@[ 0,  1 ] ] }
sub last   { bless [ $_[0]->@[ 0, -1 ] ] }
sub size   { $#{ $_[0] } }
sub slice  { my ( $drv, @ids ) = shift->@*; bless [ $drv, @ids[@_] ] }
sub split  { my ( $drv, @ids ) = $_[0]->@*; map { bless [ $drv, $_ ] } @ids }

sub uniq {
    my ( $drv, @ids ) = $_[0]->@*;

    bless [ $drv, keys %{ { map { $_ => undef } @ids } } ];
}

sub attr { $_[0]->_req( GET => "/attribute/$_[1]" ) }
sub css  { $_[0]->_req( GET =>       "/css/$_[1]" ) }
sub prop { $_[0]->_req( GET =>  "/property/$_[1]" ) }

sub clear { $_[0]->_req( POST => '/clear' ); $_[0] }
sub click { $_[0]->_req( POST => '/click' ); $_[0] }
sub tap   { $_[0]->_req( POST => '/tap'   ); $_[0] }

sub enabled  { $_[0]->_req( GET => '/enabled'   ) }
sub rect     { $_[0]->_req( GET => '/rect'      ) }
sub selected { $_[0]->_req( GET => '/selected'  ) }
sub tag      { $_[0]->_req( GET => '/name'      ) }
sub visible  { $_[0]->_req( GET => '/displayed' ) }

sub html { $_[0][0]->js( 'return arguments[0].outerHTML', $_[0] ) }

*find = \&WebDriver::Tiny::find;

sub screenshot {
    my ($self, $file) = @_;

    require MIME::Base64;

    my $data = MIME::Base64::decode_base64(
        $self->_req( GET => '/screenshot' )
    );

    if ( @_ == 2 ) {
        open my $fh, '>', $file or die $!;
        print $fh $data;
        close $fh or die $!;

        return $self;
    }

    $data;
}

sub send_keys {
    my ( $self, $keys ) = @_;

    $self->_req( POST => '/value', { text => "$keys" } );

    $self;
}

sub text {
    my ( $drv, @ids ) = $_[0]->@*;

    join ' ', map $drv->_req( GET => "/element/$_/text" ), @ids;
}

# Call driver's ->_req, prepend "/element/:id" to the path first.
sub _req { $_[0][0]->_req( $_[1], "/element/$_[0][1]$_[2]", $_[3] ) }

1;

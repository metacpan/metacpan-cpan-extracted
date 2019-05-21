package WebDriver::Tiny::Elements 0.102;

use 5.020;
use feature qw/postderef signatures/;
use warnings;
no  warnings 'experimental';

# Manip
sub append { bless [ shift->@*, map @$_[ 1.. $#$_ ], @_ ] }
sub first  { bless [ $_[0]->@[ 0,  1 ] ] }
sub last   { bless [ $_[0]->@[ 0, -1 ] ] }
sub size   { $#{ $_[0] } }
sub slice  { my ( $drv, @ids ) = shift->@*; bless [ $drv, @ids[@_] ] }
sub split  { my ( $drv, @ids ) = $_[0]->@*; map { bless [ $drv, $_ ] } @ids }

sub uniq($self) {
    my ( $drv, @ids ) = @$self;

    bless [ $drv, keys %{ { map { $_ => undef } @ids } } ];
}

sub attr($self, $value) { $self->_req( GET => "/attribute/$value" ) }
sub  css($self, $value) { $self->_req( GET =>       "/css/$value" ) }
sub prop($self, $value) { $self->_req( GET =>  "/property/$value" ) }

sub clear($self) { $self->_req( POST => '/clear' ); $self }
sub click($self) { $self->_req( POST => '/click' ); $self }
sub   tap($self) { $self->_req( POST => '/tap'   ); $self }

sub  enabled($self) { $self->_req( GET => '/enabled'   ) }
sub     rect($self) { $self->_req( GET => '/rect'      ) }
sub selected($self) { $self->_req( GET => '/selected'  ) }
sub      tag($self) { $self->_req( GET => '/name'      ) }
sub  visible($self) { $self->_req( GET => '/displayed' ) }

sub html { $_[0][0]->js( 'return arguments[0].outerHTML', $_[0] ) }

*find = \&WebDriver::Tiny::find;

sub screenshot($self, $file = undef) {
    require MIME::Base64;

    my $data = MIME::Base64::decode_base64(
        $self->_req( GET => '/screenshot' )
    );

    if ( defined $file ) {
        open my $fh, '>', $file or die $!;
        print $fh $data;
        close $fh or die $!;

        return $self;
    }

    $data;
}

sub send_keys($self, $keys) {
    $self->_req( POST => '/value', { text => "$keys" } );
    $self;
}

sub text($self) {
    my ( $drv, @ids ) = @$self;

    join ' ', map $drv->_req( GET => "/element/$_/text" ), @ids;
}

# Call driver's ->_req, prepend "/element/:id" to the path first.
sub _req { $_[0][0]->_req( $_[1], "/element/$_[0][1]$_[2]", $_[3] ) }

1;

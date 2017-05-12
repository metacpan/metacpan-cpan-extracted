package WebDriver::Tiny::Elements 0.006;

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

sub attr { $_[0]->_req( GET => "/attribute/$_[1]" )->{value} }
sub css  { $_[0]->_req( GET =>       "/css/$_[1]" )->{value} }

sub clear { $_[0]->_req( POST => '/clear' ); $_[0] }
sub click { $_[0]->_req( POST => '/click' ); $_[0] }
sub tap   { $_[0]->_req( POST => '/tap'   ); $_[0] }

sub enabled  { $_[0]->_req( GET => '/enabled'   )->{value} }
sub rect     { $_[0]->_req( GET => '/rect'      )->{value} }
sub selected { $_[0]->_req( GET => '/selected'  )->{value} }
sub tag      { $_[0]->_req( GET => '/name'      )->{value} }
sub visible  { $_[0]->_req( GET => '/displayed' )->{value} }

# Slice off just 'x' & 'y' as various backends like to supply other junk too.
sub location { +{ $_[0]->_req( GET => '/location' )->{value}->%{'x', 'y'} } }
sub location_in_view {
    +{ $_[0]->_req( GET => '/location_in_view' )->{value}->%{'x', 'y'} };
}

*find       = \&WebDriver::Tiny::find;
*screenshot = \&WebDriver::Tiny::screenshot;

sub move_to {
    $_[0][0]->_req( POST => '/moveto', { element => $_[0][1] } );

    $_[0];
}

sub send_keys {
    my ( $self, $keys ) = @_;

    $self->_req( POST => '/value', { value => [ split //, $keys ] } );

    $self;
}

sub submit {
    my ( $self, %values ) = @_;

    # For each key in %values, try to find an element under $self with that
    # name, then depending on what type of element that is, work out if a
    # click, send_keys, etc. method is needed.
    #
    # This logic is done in JS rather than Perl to reduce the amount of calls
    # to the server from one plus calls per element to just one total call!
    #
    # This improves performance at the cost of having to read JS ;-)
    my $drv   = $self->[0];
    my $elems = $drv->js( <<'JS', { ELEMENT => $self->[1] }, \%values );
        'use strict';

        var form = arguments[0], values = arguments[1], click = [], keys = [];

        for ( var name in values ) {
            var elems = form.elements[name], value = values[name];

            // FIXME - bodge for radio.
            var elem = elems.length > 1 ? elems[0] : elems;

            if ( elem.tagName == 'OPTION' ) {
                var options = elems.querySelectorAll(
                    '[value="' + (
                        value.constructor === Array
                            ? value.join('"],[value="') : value
                    ) + '"]'
                );

                for ( var i = 0; i < options.length; i++ )
                    click.push(options[i]);
            }
            else {
                if ( elem.type == 'checkbox' ) {
                    if ( !value != !elem.selected )
                        click.push(elem);
                }
                else if ( elem.type == 'radio' )
                    click.push(
                        form.querySelector(
                            '[name="' + name + '"][value="' + value + '"]')
                    );
                else
                    keys.push([
                        elem,
                        // Press CTRL+A then BACKSPACE before typing
                        ( elem.type == 'file' ? '' : '\uE009a\uE000\uE003' ) +
                        value
                    ]);
            }
        }

        return [ click, keys ];
JS

    $drv->_req( POST => "/element/$_->{ELEMENT}/click" ) for $elems->[0]->@*;

    $drv->_req(
        POST => "/element/$_->[0]{ELEMENT}/value", { value => [ $_->[1] ] },
    ) for $elems->[1]->@*;

    $self->_req( POST => '/submit' );

    $self;
}

sub text {
    my ( $drv, @ids ) = $_[0]->@*;

    join ' ', map $drv->_req( GET => "/element/$_/text" )->{value}, @ids;
}

# Call driver's ->_req, prepend "/element/:id" to the path first.
sub _req { $_[0][0]->_req( $_[1], "/element/$_[0][1]$_[2]", $_[3] ) }

1;

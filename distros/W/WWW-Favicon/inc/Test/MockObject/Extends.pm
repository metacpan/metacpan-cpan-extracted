#line 1
package Test::MockObject::Extends;

use strict;
use warnings;

use Test::MockObject;

use Devel::Peek  'CvGV';
use Scalar::Util 'blessed';

use vars qw( $VERSION $AUTOLOAD );
$VERSION = '1.09';

sub new
{
    my ($class, $fake_class) = @_;

    return Test::MockObject->new() unless defined $fake_class;

    my $parent_class = $class->get_class( $fake_class );
    $class->check_class_loaded( $parent_class );
    my $self         = blessed( $fake_class ) ? $fake_class : {};

    bless $self, $class->gen_package( $parent_class );
}

sub check_class_loaded
{
    my ($self, $parent_class) = @_;
    my $result                = Test::MockObject->check_class_loaded(
        $parent_class
    );
    return $result if $result;

    (my $load_class  = $parent_class) =~ s/::/\//g;
    require $load_class . '.pm';
}

sub get_class
{
    my ($self, $invocant) = @_;

    return $invocant unless blessed $invocant;
    return ref $invocant;
}

my $packname = 'a';

sub gen_package
{
    my ($class, $parent)         = @_;
    my $package                  = 'T::MO::E::' . $packname++;

    no strict 'refs';
    *{ $package . '::mock'          } = \&mock;
    *{ $package . '::unmock'        } = \&unmock;
    @{ $package . '::ISA'           } = ( $parent );
    *{ $package . '::can'           } = $class->gen_can( $parent );
    *{ $package . '::isa'           } = $class->gen_isa( $parent );
    *{ $package . '::AUTOLOAD'      } = $class->gen_autoload( $parent );
    *{ $package . '::__get_parents' } = $class->gen_get_parents( $parent );

    return $package;
}

sub gen_get_parents
{
    my ($self, $parent) = @_;
    return sub
    {
        no strict 'refs';
        return @{ $parent . '::ISA' };
    };
}

sub gen_isa
{
    my ($class, $parent)    = @_;

    sub
    {
        local *__ANON__    = 'isa';
        my ($self, $class) = @_;
        return 1 if $class eq $parent;
        my $isa = $parent->can( 'isa' );
        return $isa->( $self, $class );
    };
}

sub gen_can
{
    my ($class, $parent) = @_;

    sub
    {
        local *__ANON__     = 'can';
        my ($self, $method) = @_;
        my $parent_method   = $self->SUPER::can( $method );
        return $parent_method if $parent_method;
        return Test::MockObject->can( $method );
    };
}

sub gen_autoload
{
    my ($class, $parent) = @_;

    sub
    {
        my $method = substr( $AUTOLOAD, rindex( $AUTOLOAD, ':' ) +1 );
        return if $method eq 'DESTROY';

        my $self   = shift;

        if (my $parent_method  = $parent->can( $method ))
        {
            return $self->$parent_method( @_ );
        }
        elsif (my $mock_method = Test::MockObject->can( $method ))
        {
            return $self->$mock_method( @_ );
        }
        elsif (my $parent_al = $parent->can( 'AUTOLOAD' ))
        {
            my ($parent_pack) = CvGV( $parent_al ) =~ /\*(.*)::AUTOLOAD/;
            {
                no strict 'refs';
                ${ "${parent_pack}::AUTOLOAD" } = "${parent}::${method}";
            }
            unshift @_, $self;
            goto &$parent_al;
        }
        else
        {
            die "Undefined method $method at ", join( ' ', caller() ), "\n";
        }
    };
}

sub mock
{
    my ($self, $name, $sub) = @_;

    Test::MockObject::_set_log( $self, $name, ( $name =~ s/^-// ? 0 : 1 ) );

    my $mock_sub = sub 
    {
        my ($self) = @_;
        $self->log_call( $name, @_ );
        $sub->( @_ );
    };

    {
        no strict 'refs';
        no warnings 'redefine';
        *{ ref( $self ) . '::' . $name } = $mock_sub;
    }

    return $self;
}

sub unmock
{
    my ($self, $name) = @_;

    Test::MockObject::_set_log( $self, $name, 0 );
    no strict 'refs';
    my $glob = *{ ref( $self ) . '::' };
    delete $glob->{ $name };
    return $self;
}

1;
__END__


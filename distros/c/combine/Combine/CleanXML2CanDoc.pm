package Combine::CleanXML2CanDoc;

$VERSION = '0.1';

#############################################################################
#
#  A "clean XML" (in UTF8) -> canonicalDocument converter class
#
#      Options:
#  
#            'indentation'           The number of ' ' chars * L inserted
#                                    at the beginning of the line at 
#                                    <canonicalDocument> tree level L.
#
#     Kimmo Valtonen 
#
#############################################################################

use Alvis::Canonical;

#
# Return codes
#

($OK,
 $CAN_EXT_FAILED,
 $VALIDATION_FAILED)=(0,1,2);

#
# Default values for parameters
#
my $DEFAULT_INDENTATION=2;

sub new
{
    my $proto=shift;

    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_init(@_);

    $self->{converter}=Alvis::Canonical->new(cleanChars=>1);
    if (!defined($self->{converter}))
    {
	warn Alvis::Canonical::errmsg();
	return undef;
    }

    return $self;
}

sub _init
{
    my $self=shift;
    
    $self->{indentation}=$DEFAULT_INDENTATION;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args } = values( %args );
    }
}

sub convert
{
    my $self=shift;
    my $xml=shift;

    #
    # Extract a canonical version
    #
    my ($txt,$header)=$self->{converter}->HTML($xml);
    if (!defined($txt))
    {
	$err=Alvis::Canonical::errmsg();
	return ($CAN_EXT_FAILED,undef,$err);
    }

    my $ind=join(""," " x $self->{indentation});
    $txt=~s/^/$ind/mgo;

    $canonical="<canonicalDocument>${txt}</canonicalDocument>";

    return ($OK,$canonical,"");
}

1;

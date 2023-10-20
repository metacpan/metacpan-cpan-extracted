##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Version.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/24
## Modified 2021/09/24
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Version;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $IETF_VERSIONS );
    use Module::Generic::Number ();
    use overload (
        '""'    => \&as_string,
        '0+'    => \&numify,
        '-'     => sub { return( shift->_compute( @_, { op => '-', return_object => 1 }) ); },
        '+'     => sub { return( shift->_compute( @_, { op => '+', return_object => 1 }) ); },
        '*'     => sub { return( shift->_compute( @_, { op => '*', return_object => 1 }) ); },
        '/'     => sub { return( shift->_compute( @_, { op => '/', return_object => 1 }) ); },
        '%'     => sub { return( shift->_compute( @_, { op => '%', return_object => 1 }) ); },
        '<'     => sub { return( shift->_compute( @_, { op => '<', boolean => 1 }) ); },
        '<='    => sub { return( shift->_compute( @_, { op => '<=', boolean => 1 }) ); },
        '>'     => sub { return( shift->_compute( @_, { op => '>', boolean => 1 }) ); },
        '>='    => sub { return( shift->_compute( @_, { op => '>=', boolean => 1 }) ); },
        '<=>'   => sub { return( shift->_compute( @_, { op => '<=>', return_object => 0 }) ); },
        '=='    => sub { return( shift->_compute( @_, { op => '==', boolean => 1 }) ); },
        '!='    => sub { return( shift->_compute( @_, { op => '!=', boolean => 1 }) ); },
        'eq'    => sub { return( shift->_compute( @_, { op => 'eq', boolean => 1 }) ); },
        'ne'    => sub { return( shift->_compute( @_, { op => 'ne', boolean => 1 }) ); },
        'cmp'   => \&_compare,
        'bool'  => \&as_string,
        fallback => 1,
    );
    
    our $IETF_VERSIONS =
    [
'draft-ietf-hybi-17' => { serial => 17, issued => '2011-09-30', expires => '2012-04-02', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-17', version => 13, offset => 0 },
'draft-ietf-hybi-16' => { serial => 16, issued => '2011-09-27', expires => '2012-03-30', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-16', version => 13, offset => 1 },
'draft-ietf-hybi-15' => { serial => 15, issued => '2011-09-17', expires => '2012-03-20', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-15', version => 13, offset => 2 },
'draft-ietf-hybi-14' => { serial => 14, issued => '2011-09-08', expires => '2012-03-11', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-14', version => 13, offset => 3 },
'draft-ietf-hybi-13' => { serial => 13, issued => '2011-08-31', expires => '2012-03-03', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-13', version => 13, offset => 4 },
'draft-ietf-hybi-12' => { serial => 12, issued => '2011-08-24', expires => '2012-02-25', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-12', version => 8, offset => 5 },
# "Although drafts -09, -10 and -11 were published, as they were mostly comprised of editorial changes and clarifications and not changes to the wire protocol, values 9, 10 and 11 were not used as valid values for Sec-WebSocket-Version."
# <https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-11> section 5.1, page 30
'draft-ietf-hybi-11' => { serial => 11, issued => '2011-08-23', expires => '2012-02-24', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-11', version => 8, offset => 6 },
'draft-ietf-hybi-10' => { serial => 10, issued => '2011-07-11', expires => '2012-01-12', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-10', version => 8, offset => 7 },
'draft-ietf-hybi-09' => { serial => 9, issued => '2011-06-13', expires => '2011-12-15', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-09', version => 8, offset => 8 },
'draft-ietf-hybi-08' => { serial => 8, issued => '2011-06-07', expires => '2011-12-09', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-08', version => 8, offset => 9 },
'draft-ietf-hybi-07' => { serial => 7, issued => '2011-04-22', expires => '2011-10-24', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-07', version => 7, offset => 10 },
'draft-ietf-hybi-06' => { serial => 6, issued => '2011-02-25', expires => '2011-08-29', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-06', version => 6, offset => 11 },
'draft-ietf-hybi-05' => { serial => 5, issued => '2011-02-08', expires => '2011-08-12', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-05', version => 5, offset => 12 },
'draft-ietf-hybi-04' => { serial => 4, issued => '2011-01-11', expires => '2011-07-15', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-04', version => 4, offset => 13 },
'draft-ietf-hybi-03' => { serial => 3, issued => '2010-10-17', expires => '2011-04-20', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-03', version => 2, offset => 14 },
'draft-ietf-hybi-02' => { serial => 2, issued => '2010-09-24', expires => '2011-03-28', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-02', version => 2, offset => 15 },
# v8 of the rfc says hybi0 and hybi are versions 0 and 1 respectively
# <https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-08#section-11.12>
'draft-ietf-hybi-01' => { serial => 1, issued => '2010-08-31', expires => '2011-03-04', status => 'draft', type => 'hybi', draft => 'draft-ietf-hybi-01', version => 1, offset => 16 },
'draft-ietf-hybi-00' => { serial => 0, issued => '2010-05-23', expires => '2010-11-24', status => 'obsolete', type => 'hybi', draft => 'draft-ietf-hybi-00', version => 0, offset => 17 },
'draft-hixie-76'     => { serial => -1, issued => '2010-05-06', expires => '2010-11-08', status => 'obsolete', type => 'hixie', draft => 'draft-hixie-76', version => undef, offset => 18 },
'draft-hixie-75'     => { serial => -2, issued => '2010-02-04', expires => '2010-08-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-75', version => undef, offset => 19 },
'draft-hixie-74'     => { serial => -3, issued => '2010-02-02', expires => '2010-08-06', status => 'draft', type => 'hixie', draft => 'draft-hixie-74', version => undef, offset => 20 },
'draft-hixie-73'     => { serial => -4, issued => '2010-02-02', expires => '2010-08-06', status => 'draft', type => 'hixie', draft => 'draft-hixie-73', version => undef, offset => 21 },
'draft-hixie-72'     => { serial => -5, issued => '2010-02-01', expires => '2010-08-05', status => 'draft', type => 'hixie', draft => 'draft-hixie-72', version => undef, offset => 22 },
'draft-hixie-71'     => { serial => -6, issued => '2010-02-01', expires => '2010-08-05', status => 'draft', type => 'hixie', draft => 'draft-hixie-71', version => undef, offset => 23 },
'draft-hixie-70'     => { serial => -7, issued => '2010-01-31', expires => '2010-08-04', status => 'draft', type => 'hixie', draft => 'draft-hixie-70', version => undef, offset => 24 },
'draft-hixie-69'     => { serial => -8, issued => '2010-01-30', expires => '2010-08-03', status => 'draft', type => 'hixie', draft => 'draft-hixie-69', version => undef, offset => 25 },
'draft-hixie-68'     => { serial => -9, issued => '2009-12-16', expires => '2010-06-19', status => 'draft', type => 'hixie', draft => 'draft-hixie-68', version => undef, offset => 26 },
'draft-hixie-67'     => { serial => -10, issued => '2009-12-16', expires => '2010-06-19', status => 'draft', type => 'hixie', draft => 'draft-hixie-67', version => undef, offset => 27 },
'draft-hixie-66'     => { serial => -11, issued => '2009-12-09', expires => '2010-06-12', status => 'draft', type => 'hixie', draft => 'draft-hixie-66', version => undef, offset => 28 },
'draft-hixie-65'     => { serial => -12, issued => '2009-12-09', expires => '2010-06-12', status => 'draft', type => 'hixie', draft => 'draft-hixie-65', version => undef, offset => 29 },
'draft-hixie-64'     => { serial => -13, issued => '2009-12-07', expires => '2010-06-10', status => 'draft', type => 'hixie', draft => 'draft-hixie-64', version => undef, offset => 30 },
'draft-hixie-63'     => { serial => -14, issued => '2009-12-07', expires => '2010-06-10', status => 'draft', type => 'hixie', draft => 'draft-hixie-63', version => undef, offset => 31 },
'draft-hixie-62'     => { serial => -15, issued => '2009-12-07', expires => '2010-06-10', status => 'draft', type => 'hixie', draft => 'draft-hixie-62', version => undef, offset => 32 },
'draft-hixie-61'     => { serial => -16, issued => '2009-12-04', expires => '2010-06-07', status => 'draft', type => 'hixie', draft => 'draft-hixie-61', version => undef, offset => 33 },
'draft-hixie-60'     => { serial => -17, issued => '2009-12-04', expires => '2010-06-07', status => 'draft', type => 'hixie', draft => 'draft-hixie-60', version => undef, offset => 34 },
'draft-hixie-59'     => { serial => -18, issued => '2009-12-04', expires => '2010-06-07', status => 'draft', type => 'hixie', draft => 'draft-hixie-59', version => undef, offset => 35 },
'draft-hixie-58'     => { serial => -19, issued => '2009-12-03', expires => '2010-06-06', status => 'draft', type => 'hixie', draft => 'draft-hixie-58', version => undef, offset => 36 },
'draft-hixie-57'     => { serial => -20, issued => '2009-12-03', expires => '2010-06-06', status => 'draft', type => 'hixie', draft => 'draft-hixie-57', version => undef, offset => 37 },
'draft-hixie-56'     => { serial => -21, issued => '2009-12-03', expires => '2010-06-06', status => 'draft', type => 'hixie', draft => 'draft-hixie-56', version => undef, offset => 38 },
'draft-hixie-55'     => { serial => -22, issued => '2009-11-02', expires => '2010-05-06', status => 'draft', type => 'hixie', draft => 'draft-hixie-55', version => undef, offset => 39 },
'draft-hixie-54'     => { serial => -23, issued => '2009-10-23', expires => '2010-04-26', status => 'draft', type => 'hixie', draft => 'draft-hixie-54', version => undef, offset => 40 },
'draft-hixie-53'     => { serial => -24, issued => '2009-10-23', expires => '2010-04-26', status => 'draft', type => 'hixie', draft => 'draft-hixie-53', version => undef, offset => 41 },
'draft-hixie-52'     => { serial => -25, issued => '2009-10-23', expires => '2010-04-26', status => 'draft', type => 'hixie', draft => 'draft-hixie-52', version => undef, offset => 42 },
'draft-hixie-51'     => { serial => -26, issued => '2009-10-21', expires => '2010-04-24', status => 'draft', type => 'hixie', draft => 'draft-hixie-51', version => undef, offset => 43 },
'draft-hixie-50'     => { serial => -27, issued => '2009-10-21', expires => '2010-04-24', status => 'draft', type => 'hixie', draft => 'draft-hixie-50', version => undef, offset => 44 },
'draft-hixie-49'     => { serial => -28, issued => '2009-10-17', expires => '2010-04-20', status => 'draft', type => 'hixie', draft => 'draft-hixie-49', version => undef, offset => 45 },
'draft-hixie-48'     => { serial => -29, issued => '2009-10-13', expires => '2010-04-16', status => 'draft', type => 'hixie', draft => 'draft-hixie-48', version => undef, offset => 46 },
'draft-hixie-47'     => { serial => -30, issued => '2009-10-13', expires => '2010-04-16', status => 'draft', type => 'hixie', draft => 'draft-hixie-47', version => undef, offset => 47 },
'draft-hixie-46'     => { serial => -31, issued => '2009-10-06', expires => '2010-04-09', status => 'draft', type => 'hixie', draft => 'draft-hixie-46', version => undef, offset => 48 },
'draft-hixie-45'     => { serial => -32, issued => '2009-10-05', expires => '2010-04-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-45', version => undef, offset => 49 },
'draft-hixie-44'     => { serial => -33, issued => '2009-09-28', expires => '2010-04-01', status => 'draft', type => 'hixie', draft => 'draft-hixie-44', version => undef, offset => 50 },
'draft-hixie-43'     => { serial => -34, issued => '2009-09-21', expires => '2010-03-25', status => 'draft', type => 'hixie', draft => 'draft-hixie-43', version => undef, offset => 51 },
'draft-hixie-42'     => { serial => -35, issued => '2009-09-17', expires => '2010-03-21', status => 'draft', type => 'hixie', draft => 'draft-hixie-42', version => undef, offset => 52 },
'draft-hixie-41'     => { serial => -36, issued => '2009-09-17', expires => '2010-03-21', status => 'draft', type => 'hixie', draft => 'draft-hixie-41', version => undef, offset => 53 },
'draft-hixie-40'     => { serial => -37, issued => '2009-09-04', expires => '2010-03-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-40', version => undef, offset => 54 },
'draft-hixie-39'     => { serial => -38, issued => '2009-09-04', expires => '2010-03-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-39', version => undef, offset => 55 },
'draft-hixie-36'     => { serial => -39, issued => '2009-09-02', expires => '2010-03-06', status => 'draft', type => 'hixie', draft => 'draft-hixie-36', version => undef, offset => 56 },
'draft-hixie-35'     => { serial => -40, issued => '2009-08-16', expires => '2010-02-17', status => 'draft', type => 'hixie', draft => 'draft-hixie-35', version => undef, offset => 57 },
'draft-hixie-34'     => { serial => -41, issued => '2009-08-15', expires => '2010-02-16', status => 'draft', type => 'hixie', draft => 'draft-hixie-34', version => undef, offset => 58 },
'draft-hixie-33'     => { serial => -42, issued => '2009-08-14', expires => '2010-02-15', status => 'draft', type => 'hixie', draft => 'draft-hixie-33', version => undef, offset => 59 },
'draft-hixie-32'     => { serial => -43, issued => '2009-08-14', expires => '2010-02-15', status => 'draft', type => 'hixie', draft => 'draft-hixie-32', version => undef, offset => 60 },
'draft-hixie-31'     => { serial => -44, issued => '2009-08-07', expires => '2010-02-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-31', version => undef, offset => 61 },
'draft-hixie-30'     => { serial => -45, issued => '2009-08-07', expires => '2010-02-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-30', version => undef, offset => 62 },
'draft-hixie-29'     => { serial => -46, issued => '2009-08-04', expires => '2010-02-05', status => 'draft', type => 'hixie', draft => 'draft-hixie-29', version => undef, offset => 63 },
'draft-hixie-28'     => { serial => -47, issued => '2009-07-30', expires => '2010-01-31', status => 'draft', type => 'hixie', draft => 'draft-hixie-28', version => undef, offset => 64 },
'draft-hixie-27'     => { serial => -48, issued => '2009-07-29', expires => '2010-01-30', status => 'draft', type => 'hixie', draft => 'draft-hixie-27', version => undef, offset => 65 },
'draft-hixie-26'     => { serial => -49, issued => '2009-07-28', expires => '2010-01-29', status => 'draft', type => 'hixie', draft => 'draft-hixie-26', version => undef, offset => 66 },
'draft-hixie-25'     => { serial => -50, issued => '2009-07-28', expires => '2010-01-29', status => 'draft', type => 'hixie', draft => 'draft-hixie-25', version => undef, offset => 67 },
'draft-hixie-24'     => { serial => -51, issued => '2009-07-28', expires => '2010-01-29', status => 'draft', type => 'hixie', draft => 'draft-hixie-24', version => undef, offset => 68 },
'draft-hixie-23'     => { serial => -52, issued => '2009-07-27', expires => '2010-01-28', status => 'draft', type => 'hixie', draft => 'draft-hixie-23', version => undef, offset => 69 },
'draft-hixie-22'     => { serial => -53, issued => '2009-07-13', expires => '2010-01-14', status => 'draft', type => 'hixie', draft => 'draft-hixie-22', version => undef, offset => 70 },
'draft-hixie-21'     => { serial => -54, issued => '2009-07-08', expires => '2010-01-09', status => 'draft', type => 'hixie', draft => 'draft-hixie-21', version => undef, offset => 71 },
'draft-hixie-20'     => { serial => -55, issued => '2009-07-08', expires => '2010-01-09', status => 'draft', type => 'hixie', draft => 'draft-hixie-20', version => undef, offset => 72 },
'draft-hixie-19'     => { serial => -56, issued => '2009-07-07', expires => '2010-01-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-19', version => undef, offset => 73 },
'draft-hixie-18'     => { serial => -57, issued => '2009-07-07', expires => '2010-01-08', status => 'draft', type => 'hixie', draft => 'draft-hixie-18', version => undef, offset => 74 },
'draft-hixie-17'     => { serial => -58, issued => '2009-06-16', expires => '2009-12-18', status => 'draft', type => 'hixie', draft => 'draft-hixie-17', version => undef, offset => 75 },
'draft-hixie-16'     => { serial => -59, issued => '2009-06-05', expires => '2009-12-07', status => 'draft', type => 'hixie', draft => 'draft-hixie-16', version => undef, offset => 76 },
'draft-hixie-15'     => { serial => -60, issued => '2009-06-05', expires => '2009-12-07', status => 'draft', type => 'hixie', draft => 'draft-hixie-15', version => undef, offset => 77 },
'draft-hixie-13'     => { serial => -61, issued => '2009-06-01', expires => '2009-12-01', status => 'draft', type => 'hixie', draft => 'draft-hixie-13', version => undef, offset => 78 },
'draft-hixie-12'     => { serial => -62, issued => '2009-05-30', expires => '2009-12-01', status => 'draft', type => 'hixie', draft => 'draft-hixie-12', version => undef, offset => 79 },
'draft-hixie-11'     => { serial => -63, issued => '2009-04-24', expires => '2009-10-26', status => 'draft', type => 'hixie', draft => 'draft-hixie-11', version => undef, offset => 80 },
'draft-hixie-10'     => { serial => -64, issued => '2009-04-24', expires => '2009-10-26', status => 'draft', type => 'hixie', draft => 'draft-hixie-10', version => undef, offset => 81 },
'draft-hixie-07'     => { serial => -65, issued => '2009-03-23', expires => '2009-09-24', status => 'draft', type => 'hixie', draft => 'draft-hixie-07', version => undef, offset => 82 },
'draft-hixie-06'     => { serial => -66, issued => '2009-03-23', expires => '2009-09-24', status => 'draft', type => 'hixie', draft => 'draft-hixie-06', version => undef, offset => 83 },
'draft-hixie-05'     => { serial => -67, issued => '2009-03-23', expires => '2009-09-24', status => 'draft', type => 'hixie', draft => 'draft-hixie-05', version => undef, offset => 84 },
'draft-hixie-03'     => { serial => -68, issued => '2009-02-25', expires => '2009-08-29', status => 'draft', type => 'hixie', draft => 'draft-hixie-03', version => undef, offset => 85 },
'draft-hixie-02'     => { serial => -69, issued => '2009-02-17', expires => '2009-08-21', status => 'draft', type => 'hixie', draft => 'draft-hixie-02', version => undef, offset => 86 },
'draft-hixie-01'     => { serial => -70, issued => '2009-01-09', expires => '2009-07-13', status => 'draft', type => 'hixie', draft => 'draft-hixie-01', version => undef, offset => 87 },
'draft-hixie-00'     => { serial => -71, issued => '2009-01-09', expires => '2009-07-13', status => 'draft', type => 'hixie', draft => 'draft-hixie-00', version => undef, offset => 88 },
    ];
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "No version numeric or string was provided." ) ) if( !defined( $this ) || !length( $this ) );
    $self->{_exception_class} = 'WebSocket::Exception' unless( defined( $self->{_exception_class} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $dict;
    if( $this =~ /^\d+$/ )
    {
        $dict = $self->get_dictionary( version => $this ) || return( $self->pass_error );
        return( $self->error({code => 404, message => "No data found for version \"$this\"." }) ) if( !scalar( keys( %$dict ) ) );
    }
    elsif( ref( $this ) eq 'HASH' && exists( $this->{serial} ) )
    {
        $dict = $this;
    }
    else
    {
        $dict = $self->get_dictionary( draft => $this ) || return( $self->pass_error );
        return( $self->error({code => 404, message => "No data found for draft \"$this\"." }) ) if( !scalar( keys( %$dict ) ) );
    }
    my @k = keys( %$dict );
    @$self{ @k } = @$dict{ @k };
    $self->{revision} = int( $self->draft->match( qr/\-(\d+)$/ )->capture->first );
    return( $self );
}

sub as_string { return( shift->{version} ); }

sub draft { return( shift->_set_get_scalar_as_object( 'draft', @_ ) ); }

sub expires { return( shift->_set_get_datetime( 'expires', @_ ) ); }

sub get_dictionary
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No argument provided. Use either 'version' or 'draft'" ) ) if( !length( $opts->{version} ) && !length( $opts->{draft} ) && !length( $opts->{serial} ) );
    if( exists( $opts->{version} ) && length( $opts->{version} ) )
    {
        return( $self->error( "version option value provided is not an integer." ) ) if( $opts->{version} !~ /^\d+$/ );
        for( my $i = 0; $i < scalar( @$IETF_VERSIONS ); $i += 2 )
        {
            my $dict = $IETF_VERSIONS->[ $i + 1 ];
            next if( !exists( $dict->{version} ) );
            if( $dict->{version} == $opts->{version} )
            {
                # Return a copy
                return( { %$dict } );
            }
        }
        return( {} );
    }
    elsif( exists( $opts->{draft} ) && length( $opts->{draft} ) )
    {
        return( $self->error( "draft option value contains illegal characters." ) ) if( $opts->{draft} !~ /^[\w\-]+$/ );
        my $draft = lc( $opts->{draft} );
        for( my $i = 0; $i < scalar( @$IETF_VERSIONS ); $i += 2 )
        {
            if( $IETF_VERSIONS->[$i] eq $draft )
            {
                # Return a copy
                return( { %{$IETF_VERSIONS->[ $i + 1 ]} } );
            }
        }
        return( {} );
    }
    elsif( $opts->{type} && $opts->{revision} )
    {
        return( $self->error( "Unknow draft type \"$opts->{type}\"." ) ) if( $opts->{type} !~ /^(hixie|hybi)$/i );
        my $draft = lc( $opts->{type} ) eq 'hybi'
            ? sprintf( 'draft-ietf-hybi-%02d', $opts->{revision} )
            : sprintf( 'draft-hixie-%02d', $opts->{revision} );
        return( $self->get_dictionary( draft => $draft ) );
    }
    elsif( $opts->{serial} )
    {
        return( $self->error( "Serial option provided is not an integer." ) ) if( $opts->{serial} !~ /^\d+$/ );
        for( my $i = 0; $i < scalar( @$IETF_VERSIONS ); $i += 2 )
        {
            my $dict = $IETF_VERSIONS->[ $i + 1 ];
            if( $dict->{serial} == $opts->{serial} )
            {
                return( { %$dict } );
            }
        }
        return( {} );
    }
    else
    {
        return( $self->error( "Unknown arguments: '", join( "', '", @_ ), "'" ) );
    }
}

sub issued { return( shift->_set_get_datetime( 'issued', @_ ) ); }

sub new_from_request
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $req  = shift( @_ ) || return( $self->error( "No WebSocket::Request object was provided." ) );
    return( $self->error( "Object provided (", overload::StrVal( $req ), ") is not a WebSocket::Request object." ) ) if( !$self->_is_a( $req, 'WebSocket::Request' ) );
    my $h = $req->headers || return( $self->error( "Unable to find the WebSocket::Headers object." ) );
    unless( ref( $self ) )
    {
        $self = bless( {} => $class )->SUPER::init( @_ );
    }
    my $new;
    # From version 4 onward
    if( $h->header( 'Sec-WebSocket-Version' )->length ||
        $h->header( 'Sec-WebSocket-Key' )->length )
    {
        if( $h->header( 'Sec-WebSocket-Version' )->length &&
            $h->header( 'Sec-WebSocket-Version' )->match( qr/^\d{1,2}$/ ) )
        {
            $new = $self->new( $h->header( 'Sec-WebSocket-Version' )->scalar, debug => $self->debug ) || return( $self->pass_error );
        }
        # Version 10 or lower; From version 11, it uses 'Origin' only; but from version 0 to 3, it uses also Origin
        elsif( $h->header( 'Sec-WebSocket-Origin' )->length )
        {
            $new = $self->new( 'draft-ietf-hybi-10', debug => $self->debug ) || return( $self->pass_error );
        }
        # Sec-WebSocket-Key has started to be used since version 4
        # We default to the latest version 17
        else
        {
            $new = $self->new( 'draft-ietf-hybi-17', debug => $self->debug ) || return( $self->pass_error );
        }
    }
    # From version 2 to 3 for Sec-WebSocket-Draft and from version Hixie 76 for Sec-WebSocket-Key1 and Sec-WebSocket-Key2
    elsif( $h->header( 'Sec-WebSocket-Draft' )->length ||
           ( $h->header( 'Sec-WebSocket-Key1' ) && $h->header( 'Sec-WebSocket-Key2' ) ) )
    {
        if( $h->header( 'Sec-WebSocket-Draft' ) )
        {
            $new = $self->new( $h->header( 'Sec-WebSocket-Draft' )->scalar, debug => $self->debug ) || return( $self->pass_error );
        }
        # draft version 3 is the latest one using key1 and key2
        else
        {
            $new = $self->new( 'draft-ietf-hybi-03', debug => $self->debug ) || return( $self->pass_error );
        }
    }
    # No Sec-WebSocket-Key1? then it is Hixie75
    else
    {
        if( $h->header( 'Sec-WebSocket-Protocol' )->length )
        {
            # $new would stringify to undef since there is no version in the WebSocket protocol for those early drafts
            $new = $self->new( 'draft-hixie-76', debug => $self->debug );
            return( $self->pass_error ) if( !defined( $new ) );
        }
        elsif( $h->header( 'WebSocket-Protocol' )->length )
        {
            $new = $self->new( 'draft-hixie-75', debug => $self->debug );
            return( $self->pass_error ) if( !defined( $new ) );
        }
        # No WebSocket headers found, so this looks like a draft version 7 when there was only
        # Connect, Upgrade, Host and Origin
        else
        {
            $new = $self->new( 'draft-hixie-07', debug => $self->debug );
            return( $self->pass_error ) if( !defined( $new ) );
        }
    }
    return( $new );
}

sub next
{
    my $self = shift( @_ );
    return( $self->error( "Somehow this version lost its offset number !" ) ) if( !defined( $self->{offset} ) || !length( $self->{offset} ) );
    my $offset = $self->{offset};
    # Reached the end
    return if( $offset == 0 );
    my $next_def = $IETF_VERSIONS->[ $offset - 3 ];
    return( $self->error( "No data found in data at offset ", $offset - 3 ) ) if( !ref( $next_def ) || !scalar( keys( %$next_def ) ) );
    my $new = $self->new( $next_def ) || return( $self->pass_error );
    return( $new );
}

sub numify
{
    my $self = shift( @_ );
    return( $self->new_number( $self->{version} ) ) if( defined( $self->{version} ) && length( $self->{version} ) );
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->new_null( wants => 'object' ) )
    }
    return;
}

sub offset { return( shift->{offset} ); }

sub prev { return( shift->previous( @_ ) ); }

sub previous
{
    my $self = shift( @_ );
    return( $self->error( "Somehow this version lost its offset number !" ) ) if( !defined( $self->{offset} ) || !length( $self->{offset} ) );
    my $offset = $self->{offset};
    my $serial = $self->{serial};
    # Reached the end
    return if( $offset == int( $#$IETF_VERSIONS / 2 ) );
    my $prev_def = $IETF_VERSIONS->[ $offset + 3 ];
    return( $self->error( "No data found in data at offset ", $offset + 3 ) ) if( !ref( $prev_def ) || !scalar( keys( %$prev_def ) ) );
    my $new = $self->new( $prev_def ) || return( $self->pass_error );
    return( $new );
}

sub revision { return( shift->_set_get_number( 'revision', @_ ) ); }

sub serial { return( shift->_set_get_number( 'serial', @_ ) ); }

sub status { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

sub version { return( shift->_set_get_number( 'version', @_ ) ); }

sub _compare
{
    my $self = shift( @_ );
    my( $other, $swap ) = @_;
    # If both are our objects, we use our internal serial to compare
    if( $self->_is_a( $other => ( ref( $self ) || $self ) ) )
    {
        return( "$self->{serial}" cmp "$other->{serial}" );
    }
    #... otherwise we use the draft name such as draft-ietf-hybi-17 to compare
    return( $swap ? "$other" cmp "$self->{draft}" : "$self->{draft}" cmp "$other" );
}

sub _compute
{
    my( $self, $other, $swap, $opts ) = @_;
    my $other_val = $self->_is_a( $other => ( ref( $self ) || $self ) ) 
        ? $other->{serial} 
        : ( defined( $other ) && "$other" =~ /^\d+$/ )
            ? "$other"
            : "\"$other\"";
    my $serial = "$self->{serial}";
    my $operation = $swap ? "${other_val} $opts->{op} \$serial" : "\$serial $opts->{op} ${other_val}";
    if( $opts->{return_object} )
    {
        my $new_serial = eval( $operation );
        no overloading;
        warn( "Error with return formula \"$operation\" using object $self having serial '$self->{serial}' and version '$self->{version}': $@" ) if( $@ && $self->_warnings_is_enabled );
        return if( $@ );
        if( $new_serial !~ /^\-?\d+$/ )
        {
            warn( "Resulting value '$new_serial' is not an integer." ) if( $self->_warnings_is_enabled );
            return;
        }
        # Lower than -71? Not good
        if( $new_serial < $IETF_VERSIONS->[ $#$IETF_VERSIONS ]->{serial} )
        {
            warn( "Resulting value '$new_serial' is lower than 0" ) if( $self->_warnings_is_enabled );
            return;
        }
        # Greater than 17? Not good either
        if( $new_serial > $IETF_VERSIONS->[1]->{serial} )
        {
            warn( "Resulting value '$new_serial' is out of bound, exceeds total entries in the IETF draft repository." ) if( $self->_warnings_is_enabled );
            return;
        }
        my $dict = $self->get_dictionary( serial => $new_serial ) || do
        {
            warn( "Unable to get dictionary for resulting serial '$new_serial': ", $self->error ) if( $self->_warnings_is_enabled );
            return;
        };
        if( !scalar( keys( %$dict ) ) )
        {
            return;
        }
        my $new  = $self->new( $dict ) || do
        {
            warn( $self->error ) if( $self->_warnings_is_enabled );
            return;
        };
        return( $new );
    }
    elsif( $opts->{boolean} )
    {
        my $res = eval( $operation );
        no overloading;
        warn( "Error with boolean formula \"$operation\" using object $self having serial '$self->{serial}' and version '$self->{version}': $@" ) if( $@ && $self->_warnings_is_enabled );
        return if( $@ );
        # return( $res ? $self->true : $self->false );
        return( $res );
    }
    # like <=>
    else
    {
        return( eval( $operation ) );
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Version - WebSocket Version

=head1 SYNOPSIS

    use WebSocket::Version;
    my $ver = WebSocket::Version->new( 'draft-ietf-hybi-17' ) || die( WebSocket::Version->error, "\n" );
    my $ver = WebSocket::Version->new(13) || die( WebSocket::Version->error, "\n" );
    my $ver = WebSocket::Version->new_from_request( $req ) || die( WebSocket::Version->error, "\n" );
    print( $ver->numify, "\n" );
    print( $ver->draft, "\n" );
    print( "Version is: $ver\n" ); # Version is: 13

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A WebSocket class representing the version of the protocol used.

Version numbering used in the protocol headers started to be used since L<version 4|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-04#section-1.3>, thus to allow numeric comparison this class uses an internal version number as a simple increment.

L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455> is also known as L<draft-ietf-hybi-17|http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-17> (version 13).

=head1 CONSTRUCTOR

=head2 new

Takes an integer representing a WebSocket protocol version (the latest being 13), or a draft version such as C<draft-ietf-hybi-17> and this will return a new object.

It can take also an hash or hash reference of optional parameters with the only one being C<debug>. You can provide it an integer value to set the level of debugging. Nothing meaningful is displayed below 3.

=head1 METHODS

=head2 as_string

Returns the numeric value of the version. However, note that IETF drafts before revision C<00>, i.e. of type C<hixie> do not have version number, so this method will return C<undef> then.

=head2 draft

Returns the draft version such as C<draft-ietf-hybi-17>, as a scalar object (L<Module::Generic::Scalar>)

=head2 expires

Returns the draft expiration date as a L<DateTime> object.

=head2 get_dictionary

Takes an hash or hash reference of options and returns a dictionary hash containing all the attributes for the draft found.

Current supported options are:

=over 4

=item C<draft>

The draft version, such as C<draft-ietf-hybi-17>

=item C<revision>

The draft revision number such as C<17>. This is used in conjunction with the I<type> option

=item C<serial>

The serial number to search for. This is an internal number not part of the L<rfc6455|>https://datatracker.ietf.org/doc/html/rfc6455.

=item C<type>

The draft type, which is either C<hiby> or C<hixie>. This is used in conjunction with the I<revision> option

=item C<version>

Its value is an integer representing the WebSocket protocol version. For example C<13>, the latest version.

=back

If none of those options are provided, C<undef> is return and an L<error|Module::Generic/error> is set.

=head2 issued

Returns the draft issue date as a L<DateTime> object.

=head2 new_from_request

Given a L<WebSocket::Request> object, this will analyse the request headers and based on the information found, it will infer a WebSocket protocol version and return the corresponding most recent object matching that version.

=head2 next

Returns the next version object. For example, if the current object is the draft C<draft-ietf-hybi-16>, calling C<next> will return a version object matching the draft version C<draft-ietf-hybi-17>.

Note that some draft version share the same protocol version. For example, C<draft-ietf-hybi-13> to C<draft-ietf-hybi-17> all use protocol version 13.

Also note that version prior to C<draft-ietf-hybi-00>, such as C<draft-hixie-76> to C<draft-hixie-00> have no version number and thus the stringification of the object returns C<undef>.

=head2 numify

Returns the numeric representation of the version as a L<Module::Generic::Number> object. For example, C<13> which is the latest version of the WebSocket protocol.

=head2 offset

Returns the offset position of the object in the repository of all IETF drafts for the WebSocket protocol.

=head2 prev

Alias for L</previous>.

=head2 previous

Returns the previous version object. For example, if the current object is the draft C<draft-ietf-hybi-16>, calling C<next> will return a version object matching the draft version C<draft-ietf-hybi-15>

Note that some draft version share the same protocol version. For example, C<draft-ietf-hybi-13> to C<draft-ietf-hybi-17> all use protocol version 13.

Also note that version prior to C<draft-ietf-hybi-00>, such as C<draft-hixie-76> to C<draft-hixie-00> have no version number and thus the stringification of the object returns C<undef>.

=head2 revision

Returns the draft revision number. For example in C<draft-ietf-hybi-17>, the revision number is C<17>

=head2 serial

Returns the internal serial number used to identify and manipulate the version objects. This value is used by internal private methods to handle overloading. See L</OPERATIONS>

=head2 status

Returns the status as scalar object (L<Module::Generic::Scalar>). Typical status is C<draft>, C<obsolete>

=head2 type

Returns the type as scalar object (L<Module::Generic::Scalar>). Possible types are: C<hybi> or C<hixie>

=head2 version

Returns the WebSocket protocol version. Below is a summary table[1] of the IETF drafts and their version.

=begin text

    +--------------------+------------+
    | Draft              | Version    |
    +--------------------+------------+
    | draft-ietf-hybi-17 | 13         |
    | draft-ietf-hybi-16 |            |
    | draft-ietf-hybi-15 |            |
    | draft-ietf-hybi-14 |            |
    | draft-ietf-hybi-13 |            |
    +--------------------+------------+
    | draft-ietf-hybi-12 | 8          |
    | draft-ietf-hybi-11 |            |
    | draft-ietf-hybi-10 |            |
    | draft-ietf-hybi-09 |            |
    | draft-ietf-hybi-08 |            |
    +--------------------+------------+
    | draft-ietf-hybi-07 | 7          |
    +--------------------+------------+
    | draft-ietf-hybi-06 | 6          |
    +--------------------+------------+
    | draft-ietf-hybi-05 | 5          |
    +--------------------+------------+
    | draft-ietf-hybi-04 | 4          |
    +--------------------+------------+
    | draft-ietf-hybi-03 | 2          |
    +--------------------+------------+
    | draft-ietf-hybi-02 | 2          |
    +--------------------+------------+
    | draft-ietf-hybi-01 | 1          |
    +--------------------+------------+
    | draft-ietf-hybi-00 | 0          |
    +--------------------+------------+
    | draft-hixie-76     | No version |
    | to                 |            |
    | draft-hixie-00     |            |
    +--------------------+------------+

=end text

[1] Courtesy of L<Table Generator|https://www.tablesgenerator.com/text_tables>

=head1 OPERATIONS

The L<WebSocket::Version> object supports the following overloaded operators: "", -, +, *, /, %, <, <=, >, >=, <=>, ==, !=, eq, ne, cmp, bool

    my $v = WebSocket::Version->new(13);
    # Now draft version draft-ietf-hybi-17, which is the latest 
    # draft version for protocol version 13
    my $v16 = $v - 1;
    # Now draft version draft-ietf-hybi-16

But be careful that, if as a result of an operation, the product yields a version out of bound, i.e. above the latest C<draft-ietf-hybi-17> or prior to C<draft-hixie-00>, then it will return C<undef>. For example:

    my $non_existing = $v16 * 2;
    # $non_existing is undef because there is no draft version 32

Likewise, if a product yields a fractional number, it will return C<undef>. For example:

    my $undef_too = $v / 2;
    # This would yield 8.5, which is not usable and thus returns undef

=head1 IETF WORKING DRAFTS

=head2 Headers and Versions

Below is a table of the availability of headers by IETF draft revision number.

"all" means all the versions that are relevant and listed below after the table. Other earlier versions such as drafts Hixie C<0> to C<74> are not meaningful nor relevant, thus, C<75> means C<draft-hixie-75>, otherwise those revisions are from drafts C<draft-ietf-hybi-00> to C<draft-ietf-hybi-17>

=begin text

    +--------------------------+--------------+--------------+
    | Header                   | Request      | Response     |
    +--------------------------+--------------+--------------+
    | Connection               | all          | all          |
    +--------------------------+--------------+--------------+
    | Host                     | all          |              |
    +--------------------------+--------------+--------------+
    | Origin                   | 0..3,        |              |
    |                          | 11..17       |              |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Accept     |              | 4..17        |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Draft      | 2,3          |              |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Extensions | 4..17        | 4..17        |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Key        | 4..17        |              |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Key1       | 0..3         |              |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Key2       | 0..3         |              |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Location   |              | 76, 0..3     |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Nonce      |              | 4,5          |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Origin     | 4..10        | 76, 0..3     |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Protocol   | 76..17       | 76..17       |
    +--------------------------+--------------+--------------+
    | Sec-WebSocket-Version    | 4..17        | 4..17        |
    +--------------------------+--------------+--------------+
    | Upgrade                  | all          | all          |
    +--------------------------+--------------+--------------+
    | WebSocket-Location       |              | Hixie 0..75  |
    +--------------------------+--------------+--------------+
    | WebSocket-Origin         |              | Hixie 0..75  |
    +--------------------------+--------------+--------------+
    | WebSocket-Protocol       | Hixie 10..75 | Hixie 10..75 |
    +--------------------------+--------------+--------------+

=end text

=head2 HyBi 17

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-09-30

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-17>

L<Diff from HyBi 16|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-16>

=over 4

=item * Only editorial changes

=item * Sec-WebSocket-Version value is still 13 and this must be the version for RFC

=back

=head2 HyBi 16

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-09-27

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-16>

L<Diff from HyBi 15|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-16>

Only editorial changes

=head2 HyBi 15

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-09-17

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-15>

L<Diff from HyBi 14|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-15>

Sec-WebSocket-Version is still 13.

Editorial changes only.

=over 4

=item * If servers doesn't support the requested version, they MUST respond with Sec-WebSocket-Version headers containing all available versions.

=item * The servers MUST close the connection upon receiving a non-masked frame with status code of 1002.

=item * The clients MUST close the connection upon receiving a masked frame with status code of 1002.

=back

=head2 HyBi 14

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-09-08

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-14>

L<Diff from HyBi 13|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-14>

Sec-WebSocket-Version is still 13.

=over 4

=item * L<Version negotiation|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-14#section-4.4>

The following example demonstrates version negotiation:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    ...
    Sec-WebSocket-Version: 25

The response from the server might look as follows:

    HTTP/1.1 400 Bad Request
    ...
    Sec-WebSocket-Version: 13, 8, 7

Note that the last response from the server might also look like:

    HTTP/1.1 400 Bad Request
    ...
    Sec-WebSocket-Version: 13
    Sec-WebSocket-Version: 8, 7

The client now repeats the handshake that conforms to version 13:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    ...
    Sec-WebSocket-Version: 13

=item * Extension values in extension-param could be quoted-string in addition to token.

=item * Clarify the way to support multiple versions of WebSocket protocol.

=item * Payload length MUST be encoded in minimal number of bytes.

=item * WebSocket MUST support TLS.

=item * Sec-WebSocket-Key and Sec-WebSocketAccept header field MUST NOT appear more than once.

=item * Sec-WebSocket-Extensions and Sec-WebSocket-Protocol header filed MAY appear multiple times in requests, but it MUST NOT appear more than once in responses. See L<rfc6455 section 11.3.2 for more information|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-14#page-62>

=item * Sec-WebSocket-Version header filed MAY appear multiple times in responses, but it MUST NOT appear more than once in requests.

=item * Status code 1007 was changed.

=back

=head2 HyBi 13

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-08-31

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-13>

L<Diff from HyBi 12|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-13>

=over 4

=item * Now spec allow to use WWW-Authenticate header and 401 status explicitly.

=item * Servers might redirect the client using a 3xx status code, but client are not required to follow them.

=item * Clients' reconnection on abnormal closure must be delayed (between 0 and 5 seconds is a reasonable initial delay, and subsequent reconnection should be delayed longer by exponential backoff.

=item * Sec-WebSocket-Version is 13.

=item * Clients must fail the connection on receiving a subprotocol indication that was not present in the client requests in the opening handshake.

=item * Status Codes was changes (Change 1004 as reserved, and add 1008, 1009, 1010).

=back

=head2 HyBi 12

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 8

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-08-24

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-12>

L<Diff from HyBi 11|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-12>

=over 4

=item * Only editorial changes

=item * Sec-WebSocket-Version value is still 8.

=back

=head2 HyBi 11

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 8

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-08-23

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-11>

L<Diff from HyBi 10|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-11>

Sec-WebSocket-Version value is still 8, and 9/10/11 were reserved but were not and will not be used.

=over 4

=item * Sec-WebSocket-Origin -> Origin

=item * Servers send all supported protocol numbers in Sec-WebSocket-Version header.

=back

=head2 HyBi 10

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 8

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-07-11

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-10>

L<Diff from HyBi 09|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-10>

Sec-WebSocket-Version value is still 8.

=over 4

=item * Status code 1007.

=item * Receiving strings including invalid UTF-8 result in Fail.

=back

=head2 HyBi 09

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 8

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-06-13

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-09>

L<Diff from HyBi 08|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-09>

Sec-WebSocket-Version value is still 8.

=over 4

=item * On receiving a frame with any of RSV1-3 raised but no extension negotiated, Fail the WebSocket Connection.

=back

=head2 HyBi 08

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 8

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-06-07

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-08>

L<Diff from HyBi 07|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-08>

=over 4

=item * Absolute path is now allowed for resource.

=item * extension parameter is token.

=item * Sec-WebSocket-Protocol from server to client is token.

=item * Status code 1005 and 1006 are added, and all codes are unsigned.

=item * Internal error results in 1006.

=item * HTTP fallback status codes are clarified.

=item * The value of Sec-WebSocket-Version is now 8

=back

=head2 HyBi 07

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 7

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-04-22

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-07>

L<Diff from HyBi 06|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-07>

=head2 HyBi 06

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 6

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

Date: 2011-02-25

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-06>

L<Diff from HyBi 05|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-06>

=over 4

=item * The closing handshake was clarified and re-written. See L<rfc6455 changelog|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-06#section-13.1>

=item * Removed C<Sec-WebSocket-Nonce>

=item * C<Sec-WebSocket-Origin> is optional for non-browser clients.

=item * C<Connection> header must INCLUDE C<Upgrade>, rather than is equal to C<Upgrade>

=item * Editorial changes

=back

=head2 HyBi 05

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 5

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Nonce: AQIDBAUGBwgJCgsMDQ4PEC==
    Sec-WebSocket-Protocol: chat

Date: 2011-02-08

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-05>

L<Diff from HyBi 04|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-05>

=over 4

=item * Changed masking : SHA-1, client nonce, server nonce, CSPRNG -> CSPRNG only

=item * Specified the body of close frame explicitly

=item * ABNF fix for origin and protocol

=item * Added detailed C<Sec-WebSocket-Extensions> format specification

=item * Removed all occurrence of Sec-WebSocket-Location

=item * Added IANA C<Sec-WebSocket-Accept> section

=item * The value of C<Sec-WebSocket-Version> is now 5

=back

=head2 HyBi 04

Request:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 4

Response:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: me89jWimTRKTWwrS3aRrL53YZSo=
    Sec-WebSocket-Nonce: AQIDBAUGBwgJCgsMDQ4PEC==
    Sec-WebSocket-Protocol: chat

Date: 2011-01-11

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-04>

L<Diff from HyBi 03|https://tools.ietf.org/rfcdiff?url2=draft-ietf-hybi-thewebsocketprotocol-04>

Requires L<BASE64|MIME::Base64> and L<SHA-1|Digest::SHA1>

=over 4

=item * Added frame masking

=item * Changed opening handshake (C<Sec-WebSocket-Key1>, C<Sec-WebSocket-Key2>, key3, response -> C<Sec-WebSocket-Key>, C<Sec-WebSocket-Nonce>, C<Sec-WebSocket-Accept>)

=item * No more challenge and checksum in request and response body

=item * C<Sec-WebSocket-Nonce> containing a base64 16 bytes nonce in server response (see L<section 5.2.2|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-04#page-30>)

=item * Added C<Sec-WebSocket-Extensions> for extension negotiation

=item * Upgrade header is now case-insensitive (HTTP compliant)

=item * Value of response header C<Upgrade> is changed from C<WebSocket> to C<websocket> (all lower case)

=item * Flipped MORE bit and renamed it to FIN bit

=item * Renamed C<Sec-WebSocket-Draft> to C<Sec-WebSocket-Version>

=item * Renamed Origin to C<Sec-WebSocket-Origin>

=item * Added ABNF (one used in HTTP RFC2616) clarification to C<Sec-WebSocket-Protocol>

=item * Changed subprotocols separator from SP to ‘,’

=item * Removed C<Sec-WebSocket-Location>

=back

=head2 HyBi 03

Request:

    GET /demo HTTP/1.1
    Host: example.com
    Connection: Upgrade
    Sec-WebSocket-Key2: 12998 5 Y3 1  .P00
    Sec-WebSocket-Protocol: sample
    Upgrade: WebSocket
    Sec-WebSocket-Key1: 4 @1  46546xW%0l 1 5
    Origin: http://example.com

    ^n:ds[4U

Response:

    HTTP/1.1 101 WebSocket Protocol Handshake
    Upgrade: WebSocket
    Connection: Upgrade
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Location: ws://example.com/demo
    Sec-WebSocket-Protocol: sample

    8jKS'y:G*Co,Wxa-

Date: 2010-10-17

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-03>

The value of Sec-WebSocket-Draft is still 2

=over 4

=item * Added one known extension “compression”

=item * Added close frame body matching step to closing handshake

=back

=head2 HyBi 02

Request:

    GET /demo HTTP/1.1
    Host: example.com
    Connection: Upgrade
    Sec-WebSocket-Key2: 12998 5 Y3 1  .P00
    Sec-WebSocket-Protocol: sample
    Upgrade: WebSocket
    Sec-WebSocket-Key1: 4 @1  46546xW%0l 1 5
    Origin: http://example.com

    ^n:ds[4U

Response:

    HTTP/1.1 101 WebSocket Protocol Handshake
    Upgrade: WebSocket
    Connection: Upgrade
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Location: ws://example.com/demo
    Sec-WebSocket-Protocol: sample

    8jKS'y:G*Co,Wxa-

Date: 2010-09-24

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-02>

=over 4

=item * Added /defer cookies/ flag

=item * Added Sec-WebSocket-Draft with a value of 2

=back

=head2 HyBi 01

Request:

    GET /demo HTTP/1.1
    Host: example.com
    Connection: Upgrade
    Sec-WebSocket-Key2: 12998 5 Y3 1  .P00
    Sec-WebSocket-Protocol: sample
    Upgrade: WebSocket
    Sec-WebSocket-Key1: 4 @1  46546xW%0l 1 5
    Origin: http://example.com

    ^n:ds[4U

Response:

    HTTP/1.1 101 WebSocket Protocol Handshake
    Upgrade: WebSocket
    Connection: Upgrade
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Location: ws://example.com/demo
    Sec-WebSocket-Protocol: sample

    8jKS'y:G*Co,Wxa-

Date: 2010-08-31

L<Reference|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-01>

=over 4

=item * Changed frame format

=item * Added extension mechanism (no negotiation yet)

=back

=head2 Hixie 76 (HyBi 00)

Request:

    GET /demo HTTP/1.1
    Host: example.com
    Connection: Upgrade
    Sec-WebSocket-Key2: 12998 5 Y3 1  .P00
    Sec-WebSocket-Protocol: sample
    Upgrade: WebSocket
    Sec-WebSocket-Key1: 4 @1  46546xW%0l 1 5
    Origin: http://example.com

    ^n:ds[4U

Response:

    HTTP/1.1 101 WebSocket Protocol Handshake
    Upgrade: WebSocket
    Connection: Upgrade
    Sec-WebSocket-Origin: http://example.com
    Sec-WebSocket-Location: ws://example.com/demo
    Sec-WebSocket-Protocol: sample

    8jKS'y:G*Co,Wxa-

Date: 2010-05-06

L<Reference HyBi 00|https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-00>

L<Reference Hixie 76|https://datatracker.ietf.org/doc/html/draft-hixie-thewebsocketprotocol-76>

Requires L<Digest::MD5>

=over 4

=item * Added challenge/response handshaking using binary data with header fields C<Sec-WebSocket-Key1> and C<Sec-WebSocket-Key2>

=item * Added closing handshake

=back

=head2 Hixie 75

Date: 2010-02-04

L<Reference|https://datatracker.ietf.org/doc/html/draft-hixie-thewebsocketprotocol>

From version 10 to 75 there is an optional C<WebSocket-Protocol> header field, but from version 0 to 7, there is none at all. Note that version 8 and 9 are skipped.

Request:

    GET /demo HTTP/1.1
    Upgrade: WebSocket
    Connection: Upgrade
    Host: example.com
    Origin: http://example.com
    WebSocket-Protocol: sample

Response:

    HTTP/1.1 101 Web Socket Protocol Handshake
    Upgrade: WebSocket
    Connection: Upgrade
    WebSocket-Origin: http://example.com
    WebSocket-Location: ws://example.com/demo
    WebSocket-Protocol: sample

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut

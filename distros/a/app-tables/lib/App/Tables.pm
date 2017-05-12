package App::Tables::Provider::xls;
use Modern::Perl;
require App::Tables::Excel;
 
=head1 TODO

everything works fine now. need comments, tests and documentation.

=head1 Contribute

yes, please

    https://github.com/eiro/app-tables

=cut

# qw< tables2xls xls2tables >;
# qw< tables2xls xls2tables >;
# use Data::Table::Excel qw< tables2xls xls2tables >;
# use Modern::Perl;

sub new {
    my $self = pop;
    state $io =
    { reader => sub {
            App::Tables::Excel::tables_from_file
            ( (shift)
            , qw( format 2003 headers_are built ))
        }
    , writer => Data::Table::Excel->can('tables2xls') }; 
    bless { %$self, %$io } , __PACKAGE__;
}

sub read {
    my ( $self ) = @_;
    my ( $data, $headers ) = $self->{reader}( $$self{base} );
    my %whole;
    @whole{@$headers} = @$data;
    \%whole;
}

sub write {
    my ( $self, $data ) = @_;
    my @headers = keys %$data;
    my @data = map { $$data{$_} } @headers; 
    $self->{writer}( $$self{base}, \@data, \@headers );
} 

package App::Tables::Provider::xlsx;
require Data::Table::Excel;
use Modern::Perl;
our @ISA = 'App::Tables::Provider::xls'; 
# use parent 'App::Tables::Provider::xls';

sub new {
    my $self = pop;
    state $io =
    { reader => sub {
            App::Tables::Excel::tables_from_file
            ( (shift)
            , qw( format 2007 headers_are built ))
        }
    , writer => Data::Table::Excel->can('tables2xlsx') }; 
    bless { %$self, %$io } , __PACKAGE__;
}

package App::Tables::Provider::dir;
use Modern::Perl;
use IO::All;

sub new { bless pop, __PACKAGE__ }

sub read {
    my ( $self ) = @_;
    my @headers;
    my @data = map {
        push @headers, m{ ([^/]+) $ }x; # basename
        Data::Table::fromTSV $_ 
    } glob "$$self{base}/*";
    my %whole;
    @whole{ @headers } = @data;
    \%whole
}

sub write {
    my ( $self, $data ) = @_;
    map { -d $_ or io($_)->mkpath } $$self{base};
    while ( my ( $name, $sheet) = each $data ) {
        io( "$$self{base}/$name" ) < $sheet->tsv(0);
    }
}

package App::Tables;
# ABSTRACT: manipulation of tables from any sources 
our $VERSION = '0.4';

use Modern::Perl;
use Exporter 'import';
our @EXPORT_OK = qw<
    init
>;

our %EXPORT_TAGS =
( all=> \@EXPORT_OK );

# possible types are xls, xslx and /
# could be some urlized dsn+query stuff

sub _init_file {
    my ( $put, $type, $desc, $args ) = @_;
    { base => ($$args{$put}  || die "no data while grabbing $desc" )
    , type => ($$args{$type} || do {
        }) }
}

sub extension_of {
    (shift) =~ qr{
        (?: (?<type> / )
            | [.] (?<type> xlsx? )
        )$
    }x and $+{type};
}

sub _file_spec {
    my ( $data, $type ) = @_;
    defined $data or die "no data";
    map { $_ eq '/' and $_ = 'dir' }
        $type ||= extension_of($data) || 'dir';

    { base => $data
    , type => $type }

}

sub init {
    my %args = @_ ? @_ : @ARGV;
    my %conf = map {
        $args{$_}
        ? ( $_ => [ split /,/, $args{$_} ] )
        : ()
    } qw< can >;

    map { die "no $_" unless $args{$_} }
        qw< from to >;

    $conf{from} = _file_spec @args{qw< from is >};
    $conf{to}   = _file_spec @args{qw< to will >};
    \%conf
}

sub provider {
    my $spec = shift;
    my $provider = "App::Tables::Provider::$$spec{type}";
    $provider->new( $spec )
}

1;

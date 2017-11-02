package YAML::SyckWrapper;

=encoding utf8

=cut


# ABSTRACT: Loads YAML files in old and new fashion encoding ways.

our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Carp qw( croak );
use YAML::Syck qw( Load LoadFile Dump );
use Exporter qw( import );
use File::Slurp qw( read_file );


our @EXPORT = ();
our @EXPORT_OK = qw(
    &load_yaml_utf8
    &load_yaml_bytes
    &load_yaml
    &load_yaml_objects
    &dump_yaml
    &parse_yaml
    &yaml_merge_hash_fix
);

our $allow_blessed = 0;

=head1 FUNCTIONS

None exported by default.

=over

=item B<load_yaml_utf8>

    load_yaml_utf8( $file_name );

Loads specified YAML file.
Source file should be in UTF-8.
Output is UTF-8 binary string. UTF-8 validation performed.

=cut

sub _load_yaml_and_close {
    my ( $file_name, $fh ) = @_;

    local $YAML::Syck::LoadBlessed = $allow_blessed; # никаких bless по умолчанию
    my ( $res, $err ) = ( undef, undef );
    eval {
        $res = LoadFile( $fh );
        1;
    } or do {
        $err = $@;
    };
    close $fh;
    if ( $err ) {
        croak "Cannot load $file_name: $err";
    }
    return $res;
}

sub load_yaml_utf8 {
    my ( $file_name ) = @_;

    # This misleading hack taken from YAML::Syck documentation. We use encoding(UTF-8) layer here - obviously
    # output should be Perl character string, but YAML::Syck::LoadFile will output binary UTF-8 (with
    # YAML::Syck::ImplicitUnicode == false, which is default)
    # Also YAML format defined as bytes (UTF-8 , UTF-16), so passing character filehandle to YAML::Syck::LoadFile is
    # a hack too.
    # encoding(UTF-8) does nothing here, except forcing perl to validate UTF-8
    open ( my $fh, '<:encoding(UTF-8)', $file_name )
        or die "Cannot open $file_name: $!";

    return _load_yaml_and_close( $file_name, $fh );
}

=item B<load_yaml>

    load_yaml( $file_name );

Loads specified YAML file.
Source file should be in UTF-8.
Output is UTF-8 character string. UTF-8 validation performed.

=cut

sub load_yaml {
    my ( $file_name ) = @_;

    local $YAML::Syck::ImplicitUnicode = 1;
    return load_yaml_utf8( $file_name );
}

=item B<load_yaml_bytes>

    load_yaml_bytes( $file_name );

Loads specified as-is (no charset processing is involved). For old cp1251 yamls only.
Output is binary string, same as input data.

=cut

sub load_yaml_bytes {
    my ( $file_name ) = @_;
    open ( my $fh, '<:bytes', $file_name )
        or die "Cannot open $file_name: $!";
    return _load_yaml_and_close( $file_name, $fh );
}


=item B<load_yaml_objects>

    load_yaml_objects( $file_name )


Loads specified file and outputs data in configured encoding.
Source file always in UTF-8.
Output format is text (unicode)

Any !perl tag will be blessed.

Syntax:

    myobj: !!perl/Some::Class
        prop: value

Don't use on insecure data!

=cut

sub load_yaml_objects {
    my ( $file_name ) = @_;
    local $allow_blessed = 1;
    local $SIG{__WARN__} = sub {};
    my $data = load_yaml( $file_name );
    return  unless defined $data;
    return $data;
}

=item B<dump_yaml>

    dump_yaml( $data );

Dumps data in YAML in Unicode.
Возвращает уникод.

=cut

sub dump_yaml {
    my ( $data ) = @_;
    local $YAML::Syck::ImplicitUnicode = 1;
    local $YAML::Syck::SortKeys = 1;
    return  Dump( $data );
}

=item B<parse_yaml>

    parse_yaml( $yaml_text );

Parses YAML text into Unicode structure.

Принимает unicode  или UTF-8.

=cut

sub parse_yaml {
    my ( $yaml_text ) = @_;
    local $YAML::Syck::LoadBlessed = $allow_blessed; # никаких bless по умолчанию
    local $YAML::Syck::ImplicitUnicode = 1;
    return Load( $yaml_text );
}


=item B<yaml_merge_hash_fix>

    yaml_merge_hash_fix( $ref );

YAML hash merge bugfix
http://www.perlmonks.org/?node_id=813443.

=cut

sub yaml_merge_hash_fix {
    my ($ref) = @_;

    my $type = ref $ref;
    if ( $type eq 'HASH' ) {
        while ( exists $ref->{'<<'} ) {
            my $tmphref = $ref->{'<<'};
            if ($tmphref) {
                if (ref $tmphref eq 'HASH') {
                    my %tmphash = %$tmphref;
                    delete $ref->{'<<'};
                    %$ref = (%tmphash, %$ref);
                }
                elsif (ref $tmphref eq 'ARRAY') {
                    delete $ref->{'<<'};
                    %$ref = ( (map %$_, reverse @$tmphref ), %$ref);
                }
                else {
                    die "Merge key only support merging hashes or arrays";
                }
            }
        }
        yaml_merge_hash_fix($_) for ( values %$ref );
    }
    elsif ( $type eq 'ARRAY' ) {
        yaml_merge_hash_fix($_) for (@$ref);
    }
    return $ref;
}

=back

=cut

1;

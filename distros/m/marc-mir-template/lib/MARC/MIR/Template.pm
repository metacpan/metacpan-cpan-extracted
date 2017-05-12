package MARC::MIR::Template;
use Modern::Perl;
use YAML ();
sub FOR_MIR  { 0 }
sub FOR_DATA { 1 }
sub OPT      { 2 }

our $DEBUG   = 0;
our $VERSION = '0.1';

# ABSTRACT: templating system for marc records

sub _data_control {
    my $k = shift;
    sub {
        my ( $out, $content ) = @_;
        ref $content and die "trying to load a ref in $k";
        $$out{ $k } = $content;
    }
}

sub _data_data {
    my ( $field, $tag ) = @_;
    sub {
        my ( $out, $content ) = @_;
        push @{ $$out{$field}[0] }, [ $tag, $content ];
    }
}

sub _data_prepare_data {
    my ( $template, $k, $v ) = @_;
    while ( my ( $subk, $subv ) = each %$v ) {
        $$template[FOR_DATA]{ $subv } = _data_data $k, $subk;
    }
}

sub by_tag { $$a[0] cmp $$b[0] }

sub _data_mvalued {
    my ( $k, $rspec ) = @_;
    my %spec = map { $$rspec{$_} => $_  } keys %$rspec;
    sub {
        my ( $out, $v ) = @_;
        push @{ $$out{$k} }
        , map { 
            my $item = $_;
            # TODO: optimize by not sorting every subfield ?
            # (it's 2am, sorry) 
            [ map {  
                my $tag = $spec{$_} or die;
                map {
                    if ( ref ) {  map [ $tag, $_], @$_ }
                    else { [ $tag, $_ ] }
                } $$item{$_} 
            } keys %$item ]
        } @$v 
    }
}

sub new {
    my ( $pkg, $spec, $options ) = @_;
    my $template = [ $spec ];
    while ( my ( $k, $v ) = each %$spec ) {
        given ( ref $v ) {
            when ('')     { $$template[FOR_DATA]{ $v } = _data_control $k }
            when ('HASH') { _data_prepare_data $template, $k, $v }
            when ('ARRAY') {
                my ( $mvalued, $fieldspec ) = @$v;
                $$template[FOR_DATA]{ $mvalued } = _data_mvalued $k, $fieldspec;
            }
        }
    };
    $template->[OPT] = $options || {};
    bless $template, __PACKAGE__;
}

sub debug {
    my $self = shift;
    for ($self->[OPT]{debug}) {
        @_ and $_ = shift;
        return $_;
    }
}

sub data {
    my ( $template, $source ) = @_;
    my $out = {};
    while ( my ( $k, $v ) = each %$source ) {
        my $cb = $$template[FOR_DATA]{ $k } or next;
        $cb->( $out, $v );
    }
    [ map {
        my $field = $_;
        my $data = $$out{$field};
        if ( ref $data ) {
            map {
                # sorting keys clearly is a middleware! so the next line must 
                # be replaced by
                # [ $field, $_ ]
                # also remove the t/00* 
                [$field, [ sort by_tag @$_ ] ]
            } @$data
        }
        else { [ $field, $data ] }
      } sort keys %$out ]

}

sub _set_or_push_value {
    my ( $target, $key, $v ) = @_;
    for ( $$target{$key} ) {
        if (defined) {
            # so it happens to be multivalued
            if (ref) { push @$_, $v  } # and i knew it :)
            else     { $_ = [$_, $v] } # gee!
        }
        # the first time: just store $v
        else { $_ = $v }
    }
}

sub _mir_hash {
    my ( $data, $spec, $subfields ) = @_;
    for my $s ( @$subfields ) {
        my ( $tag, $v ) = @$s;
        my $key = $$spec{ $tag };
        if ( defined $key ) { _set_or_push_value $data, $key, $v }
        else { $DEBUG && warn "can't manage $tag" }
    }
}

sub mir {
    my ( $template, $fields ) = @_;
    my $tmpl = $$template[FOR_MIR];
    my %data;
    for (@$fields) {
        my ($tag,$v,$ind) = @$_;
        my $spec = $$tmpl{ $tag } or do {
            say STDERR "unsuported,$tag" if $template->debug;
            next;
        };
        if ( my $ref = ref $spec ) {
            if    ( $ref eq 'HASH'  ) { _mir_hash \%data, $spec, $v }
            elsif ( $ref eq 'ARRAY' ) {
                push @{ $data{ $$spec[0] } ||= [] }
                , my $entry = {};
                _mir_hash $entry, $$spec[1], $v
            }
            else { die "don't know how to manage $ref" }
        }
        else { $data{$spec} = $v }
    }
    \%data;
}

1;

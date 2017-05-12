package WSST::Schema::Method;

use strict;
use base qw(WSST::Schema::Base);
__PACKAGE__->mk_accessors(qw(name title desc url params params_footnotes return
                             return_footnotes error error_footnotes tests
                             sample_response));

use WSST::Schema::Param;
use WSST::Schema::Return;
use WSST::Schema::Error;
use WSST::Schema::Test;

our $VERSION = '0.1.1';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    if ($self->{params}) {
        foreach my $param (@{$self->{params}}) {
            $param = WSST::Schema::Param->new($param);
        }
    }
    $self->{return} = WSST::Schema::Return->new($self->{return});
    $self->{error} = WSST::Schema::Error->new($self->{error});
    if ($self->tests) {
        foreach my $test (@{$self->{tests}}) {
            $test = WSST::Schema::Test->new($test);
        }
    }
    foreach my $fld_base (qw(params return error)) {
        my $fld = "${fld_base}_footnotes";
        next unless defined $self->{$fld};
        my $ref = ref $self->{$fld};
        if ($ref eq 'ARRAY') {
            my $n = 1;
            $self->{$fld} = [map {{name=>$n++, value=>$_}} @{$self->{$fld}}];
        } elsif ($ref eq 'HASH') {
            $self->{$fld} = [map {{name=>$_, value=>$self->{$fld}->{$_}}}
                             sort keys %{$self->{$fld}}];
        }
    }
    return $self;
}

sub sample_query {
    my $self = shift;
    $self->{sample_query} = $_[0] if scalar(@_);
    return $self->{sample_query} if defined $self->{sample_query};
    my $good_test = $self->first_good_test || return;
    require URI;
    my $url = URI->new($self->url);
    my $params = {%{$good_test->params}};
    foreach my $key (keys %$params) {
        $params->{$key} =~ s/^\$(.*)$/$ENV{$1}||'XXXXXXXX'/e;
    }
    $url->query_form(%$params);
    my $sample_query = {
        url => $url->as_string,
    };
    return $sample_query;
}

sub first_good_test {
    my $self = shift;
    return unless defined $self->tests;
    foreach my $test (@{$self->tests}) {
        return $test if $test->type eq 'good';
    }
    return undef;
}

=head1 NAME

WSST::Schema::Method - Schema::Method class of WSST

=head1 DESCRIPTION

This class represents the method element of schema.

=head1 METHODS

=head2 new

Constructor.

=head2 name

Accessor for the name.

=head2 title

Accessor for the title.

=head2 desc

Accessor for the desc.

=head2 url

Accessor for the url.

=head2 params

Accessor for the params.

=head2 params_footnotes

Accessor for the params_footnotes.

=head2 return

Accessor for the return.

=head2 return_footnotes

Accessor for the return_footnotes.

=head2 error

Accessor for the error.

=head2 error_footnotes

Accessor for the error_footnotes.

=head2 tests

Accessor for the tests.

=head2 sample_response
 
Accessor for the sample_response.

=head2 first_good_test

Returns the first good test or undef.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;

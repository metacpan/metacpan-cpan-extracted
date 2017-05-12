package Test::Environment::Plugin::Apache2::Apache2::Filter;

our $VERSION = "0.07";

1;

package Apache2::Filter;

=head1 NAME

Test::Environment::Plugin::Apache2::Apache2::Filter - fake Apache2::Filter for Test::Environment

=head1 SYNOPSIS

    use Test::Environment qw{
        Apache2
    };
    
    my $filter = Apache2::Filter->new(
        'data' => \$data,
    );
    
    is(
        My::App:Apache2::Filter::handler($filter),
        Apache2::Const::OK,
    );
    is($$filter->r->pnotes('any_news'), 'no');

=head1 DESCRIPTION

Will populate Apache2::Filter namespace with fake methods that can be used for Apache2::Filter
testing.

=cut

use warnings;
use strict;

our $VERSION = "0.07";

use IO::String;
use Carp::Clan ();

use base 'Class::Accessor::Fast';
=head1 PROPERTIES

    ctx
    data
    max_buffer_size
    data_for_next_filter
    seen_eos

=cut

__PACKAGE__->mk_accessors(qw{
    ctx
    data
    max_buffer_size
    seen_eos
});

=head1 METHODS

=head2 new()

Filter object contructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new({
        'data'            => '',
        'request_rec'     => {},
        'max_buffer_size' => 100,
        @_,
    });
    
    if (ref $self->data eq 'SCALAR') {
        $self->{'data'} = IO::String->new(${$self->data});
    }
    elsif (ref $self->data eq '') {
        my $filename = $self->{'data'};
        open($self->{'data'}, '<', $filename)
            or die 'failed to open "'.$filename.'": '.$!;
    }
    elsif (eval { $self->data->can('read'); }) {
    }
    else {
        Carp::Clan::croak('wrong "data" argument passed');
    }
    
    return $self;
}


=head2 read($bufer, $len)

Will put $len (or $self->max_bufer_size if smaller) characters from $self->data
into the buffer.

=cut

sub read {
    my $self   = shift;

    my $buffer   = \$_[0];
    my $len      =  $_[1];
    
    $len = $self->max_buffer_size
        if $len > $self->max_buffer_size;
    
    return read($self->data, $$buffer, $len);
}


=head2 print(@args)

Will append @args to the $self->data_for_next_filter. 

=cut

sub print {
    my $self   = shift;

    $self->{'data_for_next_filter'} .= @_;
}


'man who sold the world';

__END__

=head1 TODO

	* implement sending/setting eos

=head1 AUTHOR

Jozef Kutej

=cut

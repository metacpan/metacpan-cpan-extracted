package Text::MicroTemplate::DataSectionEx;
use strict;
use warnings;
use base 'Text::MicroTemplate::Extended', 'Exporter';

our $VERSION = '0.01';
our @EXPORT_OK = qw(render_mt);

use Carp;
use Encode;
use Data::Section::Simple;

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{package} ||= scalar caller;
    $self->{section} = Data::Section::Simple->new( $self->{package} );

    $self;    
}

sub build_file {
    my ($self, $file) = @_;

    # return cached entry
    if (my $e = $self->{cache}{ $file }) {
        return $e;
    }

    my $data = $self->{section}->get_data_section($file);
    if ($data) {
        $self->parse(decode_utf8 $data);

        local $Text::MicroTemplate::_mt_setter = 'my $_mt = shift;';
        my $f = $self->build();

        $self->{cache}{$file} = $f if $self->{use_cache};
        return $f;
    }
    croak "could not find template file: $file in __DATA__ section";
}

sub render_mt {
    my $self = ref $_[0] ? shift : __PACKAGE__->new(package => scalar caller);
    $self->render_file(@_);
}

1;


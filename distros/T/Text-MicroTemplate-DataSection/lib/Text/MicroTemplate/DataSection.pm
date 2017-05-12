package Text::MicroTemplate::DataSection;
use strict;
use warnings;
use base 'Text::MicroTemplate::File', 'Exporter';

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

sub render { goto $_[0]->can('render_file') };

1;

__END__

=for stopwords OO MicroTemplate

=head1 NAME

Text::MicroTemplate::DataSection - Render Text::MicroTemplate from __DATA__.

=head1 SYNOPSIS

    use Text::MicroTemplate::DataSection 'render_mt';
    
    # Functional interface -- reads template from caller package __DATA__
    $html = render_mt('index');  # render index.mt
    
    # OO - allows reading from other packages
    my $mt = Text::MicroTemplate::DataSection->new( package => $package );
    $html = $mt->render('index');
    
    # support Text::MicroTemplate::Extended with 'Ex' postfix.
    use Text::MicroTemplate::DataSectionEx 'render_mt';
    
    $html = render_mt('child');  # template inheritance also supported
    
    __DATA__
    
    @@ index.mt
    <html>
     <body>Hello</body>
    </html>
    
    @@ base.mt
    <html>
     <body><? block body => sub { ?>default body<? } ?></body>
    </html>
    
    @@ child.mt
    ? extends 'base';
    
    ? block body => sub {
    child body
    ? } # endblock body

=head1 DESCRIPTION

Text::MicroTemplate::DataSection is simple wrapper module allows you to render MicroTemplate template from __DATA__ section.

This module based L<Text::MicroTemplate::File>, if you want to use extended feature such as template inheritance, macro or etc by L<Text::MicroTemplate::Extended>, use "Text::MicroTemplate::DataSectionEx" instead of "Text::MicroTemplate::DataSection".

=head1 SEE ALSO

L<Text::MicroTemplate>, L<Text::MicroTemplate::Extended>, L<Data::Section::Simple>.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

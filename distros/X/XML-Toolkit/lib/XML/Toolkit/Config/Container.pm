package XML::Toolkit::Config::Container;
{
  $XML::Toolkit::Config::Container::VERSION = '0.15';
}
use Moose;
use namespace::autoclean;
use Bread::Board;

extends qw(Bread::Board::Container);

with qw(
  XML::Toolkit::Config
  XML::Toolkit::Cmd::ClassTemplate
  XML::Toolkit::Builder::NamespaceRegistry
);

has '+name' => ( default => 'XML::Toolkit::Application' );

sub BUILD {
    my $self = shift;

    container $self => as {

        service 'template' => $self->template;

        service 'xmlns' => $self->xmlns;

        container Builder => as {
            service filter => (
                lifecycle    => 'Singleton',
                class        => 'XML::Toolkit::Builder::Filter',
                dependencies => {
                    template => depends_on('/template'),
                    xmlns    => depends_on('/xmlns'),
                }
            );

            service parser => (
                class            => 'XML::SAX::ParserFactory',
                constructor_name => 'parser',
                dependencies     => { Handler => depends_on('filter') },
            );

            service instance => (
                class        => 'XML::Toolkit::Builder',
                dependencies => {
                    filter => depends_on('filter'),
                    parser => depends_on('parser'),

                },
            );
        };
        container Loader => as {

            service filter => (
                lifecycle    => 'Singleton',
                class        => 'XML::Toolkit::Loader::Filter',
                dependencies => {
                    template => depends_on('/template'),
                    xmlns    => depends_on('/xmlns'),
                }
            );

            service parser => (
                class            => 'XML::SAX::ParserFactory',
                constructor_name => 'parser',
                dependencies     => { Handler => depends_on('filter') },
            );

            service instance => (
                class        => 'XML::Toolkit::Loader',
                dependencies => {
                    filter    => depends_on('filter'),
                    parser    => depends_on('parser'),
                    generator => depends_on('/Generator/instance'),
                }
            );
        };

        container Generator => as {
            service output => (
                block     => sub { [] },
                lifecycle => 'Singleton',
            );
            service quote_charecter => q['];
            service handler         => (
                class        => 'XML::SAX::Writer',
                dependencies => {
                    Output         => depends_on('output'),
                    QuoteCharacter => depends_on('quote_charecter'),
                }
            );
            service engine => (
                class        => 'XML::Toolkit::Generator::Default',
                dependencies => {
                    Handler => depends_on('handler'),
                    xmlns   => depends_on('/xmlns'),
                }
            );
            service instance => (
                class        => 'XML::Toolkit::Generator',
                dependencies => {
                    output => depends_on('output'),
                    engine => depends_on('engine'),
                }
            );
        }

    };
}

sub builder   { shift->fetch('Builder/instance')->get }
sub loader    { shift->fetch('Loader/instance')->get }
sub generator { shift->fetch('Generator/instance')->get }

1;
__END__

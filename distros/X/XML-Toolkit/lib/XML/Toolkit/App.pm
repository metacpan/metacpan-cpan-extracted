package XML::Toolkit::App;
{
  $XML::Toolkit::App::VERSION = '0.15';
}
use Moose;

use XML::Toolkit::Config::Container;

with qw( XML::Toolkit::Builder::NamespaceRegistry );

has _config => (
    does     => 'XML::Toolkit::Config',
    handles  => 'XML::Toolkit::Config',
    lazy     => 1,
    init_arg => 'config',
    builder  => '_build_config_container',
);

sub _build_config_container {
    my ($self) = @_;
    XML::Toolkit::Config::Container->new( xmlns => $self->xmlns ),;
}

1;
__END__

=head1 NAME

XML::Toolkit::App - An XML::Toolkit Application

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use XML::Toolkit::App;
    
    my $loader = XML::Toolkit::App->new( xmlns => { '' => 'MyApp' } )->loader;
    $loader->parse_file( $file );
    print join '', @{ $loader->render };

or

    use XML::Toolkit::App;
    my $builder = XML::Toolkit::App->new( xmlns => { '' => 'MyApp' } )->builder
    $builder->parse_string($xml)
    say $builder->render()
    
=head1 DESCRIPTION

=head1 SUBROUTINES / METHODS

=head1 DEPENDENCIES

Moose

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut

package XML::Toolkit::Cmd::Command::validate;
{
  $XML::Toolkit::Cmd::Command::validate::VERSION = '0.15';
}
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class qw(File);
use XML::Toolkit::App;

extends qw(MooseX::App::Cmd::Command);

with qw(MooseX::Getopt::Dashes);

has input => (
    isa      => File,
    is       => 'ro',
    coerce   => 1,
    required => 1,
);

has package => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

sub run {
    my ($self) = @_;
    
    my $loader = XML::Toolkit::App->new(xmlns => { '' => $self->package})->loader;
    $loader->parse_file( $self->input->stringify );
    
    my $generator = XML::Toolkit::App->new( xmlns => { '' => '' } )->generator;
    $generator->render_object( $loader->root_object );
    print $generator->output;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

XML::Toolkit::Cmd::Command::validate - validate XML round tripping

=head1 VERSION

version 0.15

=head1 SYNOPSIS

     xmltk generate 

=head1 DESCRIPTION

The XML::Toolkit::Cmd::Command::validate class implements ...

=head1 SUBROUTINES / METHODS

=head2 _build_namespace()

[Description of subroutine]

=head2 _build__loader()

Arguments:
    $_[0]

[Description of method]

=head2 run(self)

[Description of method]

=head1 DEPENDENCIES

Modules used, version dependencies, core yes/no

Moose

namespace::autoclean

XML::Toolkit::Loader

Moose::Util::TypeConstraints

=head1 NOTES

...

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (dcp@domain.tld)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut

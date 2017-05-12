package XML::Toolkit::Cmd::Command::generate;
{
  $XML::Toolkit::Cmd::Command::generate::VERSION = '0.15';
}
use Moose;
use namespace::autoclean;

extends qw(MooseX::App::Cmd::Command);

use XML::Toolkit::Config::Container;
use MooseX::Types::Path::Class qw(File);
use Moose::Util::TypeConstraints;

with qw(
    MooseX::Getopt::Dashes
    XML::Toolkit::App::Config
    XML::Toolkit::Cmd::ClassTemplate
);

sub default_xmlns { { '' => 'MyApp', } }

has input => (
    isa      => File,
    is       => 'ro',
    coerce   => 1,
    required => 1,
);

around _build_template => sub {
    my ( $next, $self ) = ( shift, shift );
    my $template = <<'END_TEMPLATE';
    
[% PERL %]        
 use Devel::PackagePath;
 my $p = Devel::PackagePath->new( package => "[% meta.name %]");
 my $file  = (split '::', "[% meta.name %]")[-1];
 $p->create;
 $stash->set(filename => "${\$p->path}/$file.pm");
[% END %]
[%- FILTER redirect("${filename}") -%]
END_TEMPLATE

    $template .= $self->$next(@_) . "__END__\n[% END %]";
    return $template;
};

sub run {
    my ($self) = @_;
    my $builder = XML::Toolkit::Config::Container->new(
        namespace => $self->namespace,
        xmlns     => $self->xmlns,
        template  => $self->template,
    )->builder;

    $builder->parse_file( $self->input->stringify );
    print $builder->render;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

XML::Toolkit::Cmd::Command::generate - generate clases from XML

=head1 VERSION

version 0.15

=head1 SYNOPSIS

     xmltk generate 

=head1 DESCRIPTION

The XML::Toolkit::Cmd::Command::generate class implements ...

=head1 METHODS

Insert description of method here...

=head2 run()

Insert description of method here...

=head1 DEPENDENCIES

Moose

namespace::autoclean

XML::Toolkit::Builder

Moose::Util::TypeConstraints

Devel::PackagePath

Moose

MooseX::AttributeHelpers

XML::Toolkit

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut

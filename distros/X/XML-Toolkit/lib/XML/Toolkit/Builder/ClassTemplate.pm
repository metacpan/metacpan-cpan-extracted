package XML::Toolkit::Builder::ClassTemplate;
{
  $XML::Toolkit::Builder::ClassTemplate::VERSION = '0.15';
}
use Moose::Role;
use Template;
use namespace::autoclean;

with qw(XML::Toolkit::Cmd::ClassTemplate);

has tt_config => (
    isa     => 'HashRef',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        {
            OUTPUT_PATH => '.',
            EVAL_PERL   => 1,
            POST_CHOMP  => 1,
        };
    },
);

has tt => (
    isa        => 'Template',
    is         => 'ro',
    lazy_build => 1,
    handles    => [qw(error)],
);

sub _build_tt { Template->new( $_[0]->tt_config ) }

sub render {
    return join '', map { $_[0]->render_class($_) } $_[0]->classes;
}

sub render_class {
    my ( $self, $class ) = @_;
    my $output;
    $self->tt->process( \$self->template, { meta => $class }, \$output )
      || die $self->error;
    return $output;
}

1;
__END__

=head1 NAME

XML::Toolkit::Builder::ClassTemplate

=head1 VERSION

version 0.15

=head1 SYNOPSIS

use XML::Toolkit::Builder::ClassTemplate;

=head1 DESCRIPTION

The XML::Toolkit::Builder::ClassTemplate class implements ...

=head1 METHODS

=head2 _build_template (method)

Parameters:
    none

Arguments:
    $_[0]

Insert description of method here...

=head2 render (method)

Parameters:
    none

Insert description of method here...

=head2 render_class (method)

Parameters:
    class

Insert description of method here...

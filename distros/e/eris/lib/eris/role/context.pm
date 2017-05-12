package eris::role::context;

use Moo::Role;
use Types::Standard qw(Str Defined Int);
use namespace::autoclean;

########################################################################
# Interface
requires qw(
    contextualize_message
    sample_messages
);
with qw(
    eris::role::plugin
);

########################################################################
# Attributes
has 'field' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_field',
);
has 'matcher' => (
    is      => 'ro',
    isa     => Defined,
    lazy    => 1,
    builder => '_build_matcher',
);
########################################################################
# Select our config from the plugin config
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    my @try = ( $class, (split /::/, $class)[-1] );
    my %cfg = ();
    foreach my $try (@try) {
        if( exists $args{$try} ) {
            %cfg = %{ $args{$try} };
            last;
        }
    }

    $class->$orig(%cfg);
};
########################################################################
# Builders
sub _build_name {
    my ($self) = shift;
    my ($class) = ref $self;
    my ($name) = ($class =~ /eris::log::context::(.+)$/);
    $name ||= $class;

    return $name;
}
# By default, we look for program and default to use name, so
# if I want to write a context for sshd, I just need to create
# eris::log::context::sshd.
sub _build_field { 'program'; }
sub _build_matcher { my ($self) = shift; $self->name; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::context

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

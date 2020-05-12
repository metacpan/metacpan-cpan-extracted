package IteratorTest;
use Test2::Roo::Role;

use MooX::Types::MooseLike::Base qw/:all/;
use Class::Load qw/load_class/;
use Path::Tiny;

has [qw/iterator_class result_type/] => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has test_files => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub {
        return [
            qw(
              aaaa
              bbbb
              cccc/dddd
              eeee/ffff/gggg
              )
        ];
    },
);

has tempdir => (
    is  => 'lazy',
    isa => InstanceOf ['Path::Tiny']
);

has rule_object => (
    is      => 'lazy',
    isa     => Object,
    clearer => 1,
);

sub _build_description { return shift->iterator_class }

sub _build_tempdir {
    my ($self) = @_;
    my $dir = Path::Tiny->tempdir;
    $dir->child($_)->touchpath for @{ $self->test_files };
    return $dir;
}

sub _build_rule_object {
    my ($self) = @_;
    load_class( $self->iterator_class );
    return $self->iterator_class->new;
}

sub test_result_type {
    my ( $self, $file ) = @_;
    if ( my $type = $self->result_type ) {
        isa_ok( $file, $type, $file );
    }
    else {
        is( ref($file), '', "$file is string" );
    }
}

test 'find files' => sub {
    my $self = shift;
    $self->clear_rule_object; # make sure have a new one each time

    $self->tempdir;
    my $rule = $self->rule_object;
    my @files = $rule->file->all( $self->tempdir, { relative => 1 } );

    is_deeply( \@files, $self->test_files, "correct list of files" )
      or diag explain \@files;

    $self->test_result_type($_) for @files;
};

# ... more tests ...

1;

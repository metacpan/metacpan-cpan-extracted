package WebService::Raygun::Message::Environment;
$WebService::Raygun::Message::Environment::VERSION = '0.030';
use Mouse;

=head1 NAME

WebService::Raygun::Message::Environment - Represent the I<Environment> data in a raygun request.

=head1 SYNOPSIS

  use WebService::Raygun::Message::Environment;
  my $environment = WebService::Raygun::Message::Environment->new(
    processor_count       => 2,
    cpu                   => 34,
    architecture          => 'x84',
    total_physical_memory => 3
  );


=head1 DESCRIPTION

The environment data is all optional and may be left blank. This class just
initialises them with empty strings or 1s or 0s depending on the context. The
L<prepare_raygun> method may be called to retreive the structure in a form
that can be converted directly to JSON.


=head1 INTERFACE

=cut

use Filesys::DfPortable;
use Sys::Info;
use Sys::Info::OS;
use POSIX ();

use Mouse::Util::TypeConstraints;
subtype 'Environment' => as 'Object' => where {
    $_->isa('WebService::Raygun::Message::Environment');
};

coerce 'Environment' => from 'HashRef' => via {
    return WebService::Raygun::Message::Environment->new( %{$_} );
};
no Mouse::Util::TypeConstraints;

has browser => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has browser_name => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has browser_version => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has platform => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has info => (
    is      => 'ro',
    isa     => 'Sys::Info',
    default => sub {
        return Sys::Info->new;
    },
);

has info_os => (
    is      => 'rw',
    isa     => 'Sys::Info::OS',
    default => sub {
        return Sys::Info::OS->new();
    },
);

has processor_count =>
  ( is => 'rw', isa => 'Int', default => sub { return 1; } );
has os_version => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->info->os->name( long => 1 );
    }
);
has fs => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return dfportable( "/", 1024 );
    },
);

has window_bounds_width =>
  ( is => 'rw', isa => 'Int', default => sub { return 0; } );
has window_bounds_height =>
  ( is => 'rw', isa => 'Int', default => sub { return 0; } );
has resolution_scale =>
  ( is => 'rw', isa => 'Str', default => sub { return ''; } );
has current_orientation => ( is => 'rw', isa => 'Str', default => 'Landscape' );
has model               => ( is => 'rw', isa => 'Str', default => '' );
has cpu                 => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->info->device("CPU")->identify;
    }
);
has package_version =>
  ( is => 'rw', isa => 'Str', default => sub { return ''; } );
has architecture => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return (POSIX::uname)[4];
    }
);
has total_physical_memory => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->fs->{blocks};
    }
);
has available_physical_memory => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->fs->{bfree};
    }
);
has total_virtual_memory =>
  ( is => 'rw', isa => 'Int', default => sub { return 0; } );
has available_virtual_memory =>
  ( is => 'rw', isa => 'Int', default => sub { return 0; } );
has disk_space_free =>
  ( is => 'rw', isa => 'ArrayRef', default => sub { return [] }, );
has device_name => ( is => 'rw', isa => 'Str', default => sub { return ''; } );
has locale => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->info_os->locale;
    },
);

has browser_width => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has browser_height => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has screen_width => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has screen_height => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has color_depth => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has utc_offset => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

=head2 prepare_raygun

Return the data structure that will be sent to raygun.io

=cut

sub prepare_raygun {
    my $self = shift;
    return {
        processorCount          => $self->processor_count,
        osVersion               => $self->os_version,
        windowBoundsWidth       => $self->window_bounds_width,
        windowBoundsHeight      => $self->window_bounds_height,
        resolutionScale         => $self->resolution_scale,
        currentOrientation      => $self->current_orientation,
        cpu                     => $self->cpu,
        packageVersion          => $self->package_version,
        architecture            => $self->architecture,
        totalPhysicalMemory     => $self->total_physical_memory,
        availablePhysicalMemory => $self->available_physical_memory,
        totalVirtualMemory      => $self->total_virtual_memory,
        availableVirtualMemory  => $self->available_virtual_memory,
        diskSpaceFree           => $self->disk_space_free,
        deviceName              => $self->device_name,
        locale                  => $self->locale,
        "browser-Width"         => $self->browser_width,
        "browser-Height"        => $self->browser_height,
        "screen-Width"          => $self->screen_width,
        "screen-Height"         => $self->screen_height,
        "color-Depth"           => $self->color_depth,
        "utcOffset"             => $self->utc_offset,
        browser                 => $self->browser,
        browserName             => $self->browser_name,
        "browser-Version"       => $self->browser_version,
        platform                => $self->platform,
    };

}

=head1 DEPENDENCIES


=head1 SEE ALSO

=cut

__PACKAGE__->meta->make_immutable();

1;

__END__

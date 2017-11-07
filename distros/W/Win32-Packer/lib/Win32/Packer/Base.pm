package Win32::Packer::Base;

use Log::Any;
use Path::Tiny;
use Win32::Packer::Helpers qw(assert_dir assert_file assert_file_name assert_guid
                              mkpath guid to_uc);
use Carp;
use Capture::Tiny qw(capture);

use Moo;
use namespace::autoclean;

has log             => ( is => 'rw', default => sub { Log::Any->get_logger } );
has work_dir        => ( is => 'lazy', coerce => \&mkpath, isa => \&assert_dir );
has output_dir      => ( is => 'ro', coerce => \&mkpath, isa => \&assert_dir,
                         default => sub { path('.')->realpath } );
has app_name        => ( is => 'ro', default => sub { 'PerlApp' },
                         isa => \&assert_file_name );
has app_version     => ( is => 'ro', isa => \&assert_file_name);

has app_vendor      => ( is => 'ro', default => 'Acme Ltd.');

has app_id          => ( is => 'lazy', default => \&guid, coerce => \&to_uc,
                         isa => \&assert_guid );

has app_description => ( is => 'ro' );

has app_keywords    => ( is => 'ro' );

has app_comments    => ( is => 'ro' );

has icon            => ( is => 'ro', isa => \&assert_file, coerce => \&path );

has system_drive    => ( is => 'lazy', isa => \&assert_dir, coerce => \&path,
                         default => sub { $ENV{SystemDrive} // 'C://' } );

sub _die { croak shift->log->fatal(@_) }
sub _dief { croak shift->log->fatalf(@_) }

sub _run_cmd {
    my $self = shift;
    my @cmd = map { ref eq 'SCALAR' ? grep length, split /\s+/, $$_ : "$_" } @_;
    $self->log->debugf("running command: %s", \@cmd);
    my ($out, $err, $rc) = capture {
        system @cmd;
    };
    $self->log->debugf("command rc: %s, out: %s, err: %s", $rc, \$out, \$err);
    wantarray ? (($rc == 0), $out, $err) : ($rc == 0)
}

1;

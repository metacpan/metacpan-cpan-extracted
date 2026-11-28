package Web::Session::File;

use strict;

use Apache::Session;
use Apache::Session::Lock::File;
use Web::Session::Store::File;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;
use Web::Session::_common;

use constant SL => ( $^O and $^O =~ /(?:MSWin|Windows)/i ? '\\' : '/' );

our $VERSION = '1.0.0';
our @ISA     = qw(Apache::Session Web::Session::_common);

sub populate {
    my $self = shift;

    $self->{object_store} = new Web::Session::Store::File $self;
    $self->{lock_manager} = new Apache::Session::Lock::File $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->save;
    $self->{object_store}->close;
    $self->release_all_locks;
}

sub get_key_from_all_sessions {
    my ( $class, $args, $data ) = @_;
    $args->{Directory} ||= $Apache::Session::Store::File::Directory;

    unless ( opendir DIR, $args->{Directory} ) {
        die "Cannot open directory $args->{Directory}\n";
    }
    my @t =
      grep { -f $args->{Directory} . SL . $_ and /^[A-Za-z0-9@\-]+$/ }
      readdir(DIR);
    closedir DIR;
    my %res;
    for my $f (@t) {
        eval {
            open F, $args->{Directory} . SL . $f or die $!;
            my $row = join '', <F>;
            if ( ref($data) eq 'CODE' ) {
                $res{$f} =
                  &$data( &Web::Session::Serialize::JSON::_unserialize($row),
                    $f );
            }
            elsif ($data) {
                $data = [$data] unless ( ref($data) );
                my $tmp = &Web::Session::Serialize::JSON::_unserialize($row);
                $res{$f}->{$_} = $tmp->{$_} foreach (@$data);
            }
            else {
                $res{$f} =
                  &Web::Session::Serialize::JSON::_unserialize($row);
            }
        };
        if ($@) {
            print STDERR "Error in session $f: $@\n";
            delete $res{$f};
        }
    }
    return \%res;
}

1;
__END__


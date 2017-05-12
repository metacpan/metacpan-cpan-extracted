
package WebService::Pinterest::Upload;
$WebService::Pinterest::Upload::VERSION = '0.1';
use Moose;

has args => (
    is       => 'ro',
    required => 1,
    isa      => 'ArrayRef',
);

sub file {
    shift->args->[0];
}

# Valid if file is a readable file
sub is_valid {
    my $file = shift()->file;
    $file && -r -f $file;
}

sub lwp_file_spec {
    shift()->args;
}

1;


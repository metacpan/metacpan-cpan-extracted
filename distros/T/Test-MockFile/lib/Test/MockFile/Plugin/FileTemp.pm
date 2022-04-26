package Test::MockFile::Plugin::FileTemp;

use strict;
use warnings;

use parent 'Test::MockFile::Plugin';

use Test::MockModule qw{strict};

use Carp qw(croak);

our $VERSION = '0.034';

sub register {
    my ($self) = @_;

    if ( $^V lt 5.28.0 ) {
        croak( __PACKAGE__ . " is only supported for Perl >= 5.28" );
    }

    foreach my $pkg (qw{ File::Temp File::Temp::Dir File::Temp::END File::Temp::Dir::DESTROY }) {
        Test::MockFile::authorized_strict_mode_for_package($pkg);
    }

    Test::MockFile::add_strict_rule_generic( \&_allow_file_temp_calls );

    my $mock = Test::MockModule->new('File::Temp');

    # tempfile
    $mock->redefine(
        tempfile => sub {
            my (@in) = @_;

            my @out = $mock->original('tempfile')->(@in);

            Test::MockFile::add_strict_rule_for_filename( $out[1] => 1 );

            return @out if wantarray;

            File::Temp::unlink0( $out[0], $out[1] );
            return $out[0];
        }
    );

    # tempdir
    $mock->redefine(
        tempdir => sub {
            my (@in) = @_;

            my $out = $mock->original('tempdir')->(@in);
            my $dir = "$out";

            Test::MockFile::add_strict_rule_for_filename( [ $dir, qr{^${dir}/} ] => 1 );

            return $out;
        }
    );

    # newdir
    $mock->redefine(
        newdir => sub {
            my (@args) = @_;

            my $out = $mock->original('newdir')->(@args);
            my $dir = "$out";

            Test::MockFile::add_strict_rule_for_filename( [ $dir, qr{^$dir/} ] => 1 );

            return $out;
        }
    );

    $self->{mock} = $mock;

    return $self;
}

sub _allow_file_temp_calls {
    my ($ctx) = @_;

    foreach my $stack_level ( 1 .. Test::MockFile::_STACK_ITERATION_MAX() ) {
        my @stack = caller($stack_level);
        last if !scalar @stack;
        last if !defined $stack[0];    # We don't know when this would ever happen.

        return 1 if $stack[0] eq 'File::Temp'    #
          || $stack[0] eq 'File::Temp::Dir';
    }

    return;
}

1;

=encoding utf8

=head1 NAME

Test::MockFile::Plugin::FileTemp - Plugin to allow File::Temp calls

=head1 SYNOPSIS

  use Test::MockFile 'strict', plugin => 'FileTemp';

  # using FileTemp plugin, all calls from FileTemp bypass the Test::MockFile strict mode

  my $dir = File::Temp->newdir();
  ok opendir( my $dh, "$dir" );
  ok open( my $f, '>', "$dir/myfile.txt" );

=head1 DESCRIPTION

L<Test::MockFile::Plugin::FileTemp> provides plugin to Test::MockFile
to authorize any calls from File::Temp package.

=head1 METHODS

=head2 register( $self )

Public method to register the plugin.

=head1 SEE ALSO

L<Test::MockFile>, L<Test::MockFile::Plugins>, L<Test::MockModule>

=cut

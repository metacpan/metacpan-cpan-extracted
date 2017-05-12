package Test::Kantan::Caller;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Cwd ();
use File::Spec;

our $BASE_DIR = Cwd::getcwd();
our %FILECACHE;

sub package { shift->{package} }
sub filename { shift->{filename} }
sub line { shift->{line} }
sub code { shift->{code} }

sub new {
    my $class = shift;

    my $level   = shift || 0;
    my $binmode = shift || '<:encoding(utf-8)';

    my ($package, $filename, $line) = caller($level+1);
    return unless defined($package);

    my $code = sub {
        undef $filename if $filename eq '-e';
        if (defined $filename) {
            my $abs_filename = File::Spec->rel2abs($filename, $BASE_DIR);
            my $file = $FILECACHE{$abs_filename} ||= [
                do {
                    # Do not die if we can't open the file
                    open my $fh, $binmode, $abs_filename
                        or return '';
                    <$fh>
                }
            ];
            my $code = $file->[ $line - 1 ];
            $code =~ s{^\s+|\s+$}{}g;
            $code;
        } else {
            "";
        }
    }->();
    return bless +{
        package  => $package,
        filename => $filename,
        line     => $line,
        code     => $code,
    }, $class;
}

1;
__END__

=head1 NAME

Test::Kantan::Caller - Kantan caller

=head1 SYNOPSIS

    my $caller = Test::Kantan::Caller->new();

=head1 DESCRIPTION

This is the caller object for Test::Kantan.

=head1 METHODS

=over 4

=item C<< my $caller = Test::Kantan::Caller->new([$level=0[, $binmode="<:encoding(utf-8)"]) >>

Create new C<Test::Kantan::Caller> object from the caller information.

I<$level>: Caller level.

I<$binmode>: Binmode for reading source code.

I<Return Value>: New object. If there is no caller, return C<()> or undef.

=back

=head1 ATTRIBUTES

=over 4

=item package

The caller package name

=item filename

The caller file name.

=item line

The caller line number.

=item code

The source code at caller file at line number.

=back

package App::Grok::Resource::File;
BEGIN {
  $App::Grok::Resource::File::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Resource::File::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';

use base qw(Exporter);
our @EXPORT_OK = qw(file_index file_fetch file_locate);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

sub file_fetch {
    my ($file) = @_;
    
    # TODO: at some point we'll search through $PERL6LIB, but for now
    # we only accept a concrete path
    
    if (-f $file) {
        open my $handle, '<', $file or die "Can't open $file: $!";
        my $pod = do { local $/ = undef; scalar <$handle> };
        close $handle;
        return $pod;
    }

    return;
}

sub file_index {
    # this might recurse through $PERL6LIB or something at some point
    return;
}

sub file_locate {
    my ($file) = @_;
    
    return $file if -f $file;
    return;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Resource::File - Standard file resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::File qw<:ALL>;

 # this will return everything in $PERL6LIB sometime in the future
 my @index = file_index();

 # get a filehandle to the thing we want
 my $handle = file_fetch('perlintro');

=head1 DESCRIPTION

This resource finds arbitrary documentation on the filesystem.

=head1 FUNCTIONS

=head2 C<file_index>

This method doesn't return anything useful yet.

=head2 C<file_fetch>

Takes a module name, program name, or Pod page name. Since the details of
C<$PERL6LIB> are still fuzzy, it currently just returns the contents of
the supplied file.

=head2 C<file_locate>

Returns the filename given if it is a real file. Not very useful.

=cut

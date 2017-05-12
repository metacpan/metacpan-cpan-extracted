package App::Grok::Resource::Spec;
BEGIN {
  $App::Grok::Resource::Spec::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Resource::Spec::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';
use App::Grok::Common qw<data_dir download>;
use File::ShareDir qw<dist_dir>;
use File::Spec::Functions qw<catdir catfile splitpath>;

use base qw(Exporter);
our @EXPORT_OK = qw(spec_index spec_fetch spec_locate spec_update);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

my %index;
my $dist_dir = dist_dir('Perl6-Doc');
my %docs = map {
    substr($_, 0, 1) => catdir($dist_dir, $_) 
} qw<Apocalypse Exegesis Magazine Synopsis>;

sub spec_update {
    my $res_dir = catdir(data_dir(), 'resources', 'spec');
    if (!-d $res_dir) {
        mkdir $res_dir or die "Can't create $res_dir: $!\n";

    }
    my $s32_dir = catdir($res_dir, 'S32-setting-library');
    if (!-d $s32_dir) {
        mkdir $s32_dir or die "Can't create $s32_dir: $!\n";
    }

    print "Downloading specs...\n";
    my @specs = map { chomp; $_ } <DATA>;

    my $i = 0;
    for my $spec_url (@specs) {
        $i++;
        my $s32 = $spec_url =~ /S32/;
        my ($filename) = $spec_url =~ m{(?<=/)([^/]+)$};
        my $title = "($i/".scalar @specs.") ".($s32?'S32-setting-library/': '').$filename;
        my $content = download($title, $spec_url);
        my $file = catfile(($s32 ? $s32_dir : $res_dir), $filename);
        open my $fh, '>:encoding(utf8)', $file or die "Can't open $file: $!\n";
        print $fh $content;
        close $fh;
    }

    return;
}

sub spec_fetch {
    my ($topic) = @_;
    _build_index() if !%index;
    
    for my $doc (keys %index) {
        if ($doc =~ /^\Q$topic/i) {
            open my $handle, '<', $index{$doc} or die "Can't open $index{$doc}: $!";
            my $pod = do { local $/ = undef; scalar <$handle> };
            close $handle;
            return $pod;
        }
    }
    return;
}

sub spec_index {
    _build_index() if !%index;
    return keys %index;
}

sub spec_locate {
    my ($topic) = @_;
    _build_index() if !%index;
    
    for my $doc (keys %index) {
        return $index{$doc} if $doc =~ /^$topic/i;
    }

    return;
}

sub _build_index {
    while (my ($type, $dir) = each %docs) {
        for my $file (glob "$dir/*.pod") {
            my $name = (splitpath($file))[2];
            $name =~ s/\.pod$//;
            $index{$name} = $file;
        }
    }

    # man pages (perlintro, etc)
    my $pages_dir = catdir($dist_dir, 'man_pages');
    for my $file (glob "$pages_dir/*.pod") {
        my $name = (splitpath($file))[2];
        $name =~ s/\.pod$//;
        $index{$name} = $file;
    }

    # synopsis 32
    my $S32_dir = catdir($docs{S}, 'S32-setting-library');
    for my $file (glob "$S32_dir/*.pod") {
        my $name = (splitpath($file))[2];
        $name =~ s/\.pod$//;
        $name = "S32-$name";
        $index{$name} = $file;
    }

    return;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Resource::Spec - Perl 6 specification resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::Spec qw<:ALL>;

 # list of all Synopsis, Exegeses, etc
 my @index = spec_index();

 # get the contents of Synopsis 02
 my $pod = spec_fetch('s02');

 # filename containing S02
 my $file = spec_locate('s02');

=head1 DESCRIPTION

This module the locates Apocalypses, Exegeses, Synopsis and magazine articles
distributed with L<Perl6::Doc>.

It also includes user documentation like F<perlintro> and F<perlsyn>.

=head1 FUNCTIONS

=head2 C<spec_update>

Takes no arguments. Downloads the latest specifications (Synopses) into
grok's data dir.

=head2 C<spec_index>

Doesn't take any arguments. Returns a list of all documents known to this
resource.

=head2 C<spec_fetch>

Takes the name of a document as an argument. It is case-insensitive and you
only need to specify the first three characters (though more are allowed),
e.g. C<spec_fetch('s02')>. Returns the Pod text of the document.

=head2 C<spec_locate>

Takes the same argument as L<C<spec_fetch>|/spec_fetch>. Returns the filename
corresponding to the given document.

=cut
__DATA__
https://github.com/perl6/specs/raw/master/S01-overview.pod
https://github.com/perl6/specs/raw/master/S02-bits.pod
https://github.com/perl6/specs/raw/master/S03-operators.pod
https://github.com/perl6/specs/raw/master/S04-control.pod
https://github.com/perl6/specs/raw/master/S05-regex.pod
https://github.com/perl6/specs/raw/master/S06-routines.pod
https://github.com/perl6/specs/raw/master/S07-iterators.pod
https://github.com/perl6/specs/raw/master/S08-capture.pod
https://github.com/perl6/specs/raw/master/S09-data.pod
https://github.com/perl6/specs/raw/master/S10-packages.pod
https://github.com/perl6/specs/raw/master/S11-modules.pod
https://github.com/perl6/specs/raw/master/S12-objects.pod
https://github.com/perl6/specs/raw/master/S13-overloading.pod
https://github.com/perl6/specs/raw/master/S14-roles-and-parametric-types.pod
https://github.com/perl6/specs/raw/master/S16-io.pod
https://github.com/perl6/specs/raw/master/S17-concurrency.pod
https://github.com/perl6/specs/raw/master/S19-commandline.pod
https://github.com/perl6/specs/raw/master/S21-calling-foreign-code.pod
https://github.com/perl6/specs/raw/master/S22-package-format.pod
https://github.com/perl6/specs/raw/master/S24-testing.pod
https://github.com/perl6/specs/raw/master/S26-documentation.pod
https://github.com/perl6/specs/raw/master/S28-special-names.pod
https://github.com/perl6/specs/raw/master/S29-functions.pod
https://github.com/perl6/specs/raw/master/S31-pragmatic-modules.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Basics.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Callable.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Containers.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Exception.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/IO.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Numeric.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Rules.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Str.pod
https://github.com/perl6/specs/raw/master/S32-setting-library/Temporal.pod

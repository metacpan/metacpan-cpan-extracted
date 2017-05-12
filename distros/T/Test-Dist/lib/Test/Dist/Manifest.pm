package # hide
	Test::Dist::Manifest;

# Copypast from Module::CPANTS::Kwalitee::Manifest with only change:
# ignore files, ignored by ExtUtils::Manifest

=head1 NAME

Test::Dist::Manifest

=head1 DESCRIPTION

Copypast from L<Module::CPANTS::Kwalitee::Manifest> with only change:
ignore files, ignored by ExtUtils::Manifest, since we're running under source, not unpacked distribution

For internal use by L<Test::Dist>

=head1 FUNCTIONS

=head2 order

=head2 analyse

=head2 kwalitee_indicators

=cut

use strict;
use warnings;
use ExtUtils::Manifest;
use File::Spec::Functions qw(catfile);
use Array::Diff;

sub order { 100 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $me=shift;
    my $skip = ExtUtils::Manifest::maniskip();
    
    my @files=@{$me->d->{files_array}};
    if (my $ignore = $me->d->{ignored_files_array}) {
        push @files, @$ignore;
    }
    
    @files = grep !$skip->($_), @files; # skip files, ignored by make manifest

    my $distdir=$me->distdir;
    my $manifest_file=catfile($distdir,'MANIFEST');

    if (-e $manifest_file) {
        # read manifest
        open(my $fh, '<', $manifest_file) || die "cannot read MANIFEST $manifest_file: $!";
        my @manifest;
        while (<$fh>) {
            chomp;
            next if /^\s*#/; # discard pure comments

            s/\s.*$//; # strip file comments
            next unless $_; # discard blank lines
            push(@manifest,$_);
        }
        close $fh;

        @manifest=sort @manifest;
        my @files=sort @files;

        my $diff=Array::Diff->diff(\@manifest,\@files);
        if ($diff->count == 0) {
            $me->d->{manifest_matches_dist}=1;
        }
        else {
            $me->d->{manifest_matches_dist}=0;
            my @error = ( 
                'MANIFEST ('.@manifest.') does not match dist ('.@files."):",
                "Missing in MANIFEST: ".join(', ',@{$diff->added}), 
                "Missing in Dist: " . join(', ',@{$diff->deleted}));
            $me->d->{error}{manifest_matches_dist} = \@error;
        }
    }
    else {
        $me->d->{manifest_matches_dist}=0;
        $me->d->{error}{manifest_matches_dist}=q{Cannot find MANIFEST in dist.};
    }
}

##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
    return [
        {
            name=>'manifest_matches_dist',
            error=>q{MANIFEST does not match the contents of this distribution. See 'error_manifest_matches_dist' in the dist view for more info.},
            remedy=>q{Use a buildtool to generate the MANIFEST. Or update MANIFEST manually.},
            code=>sub { shift->{manifest_matches_dist} ? 1 : 0 },
        }
    ];
}

1;

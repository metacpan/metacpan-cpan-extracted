package Module::CPANTS::Kwalitee::FindModules;
use warnings;
use strict;
use File::Spec::Functions qw(catfile);

our $VERSION = '0.96';
$VERSION = eval $VERSION; ## no critic

sub order { 30 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $me=shift;
    my $files=$me->d->{files_array} || [];
  
    if ($me->d->{meta_yml} && $me->d->{meta_yml}{provides}) {
        my $provides = $me->d->{meta_yml}{provides};
        while (my ($module,$data)=each %$provides) {
            next unless ref $data eq ref {}; # ignore wrong format
            my $file=$data->{file} || '';
            my $found={
                module=>$module,
                file=>$file,
                in_basedir=>0,
                in_lib=>0,
            };
            my $loc;
            if ($file=~/^lib\W/) {
                $found->{in_lib}=1;
            }
            elsif ($file !~/\//) {
                $found->{in_basedir}=1;
            }
            
            push(@{$me->d->{modules}},$found);
            if (exists $me->d->{files_hash}{$file}) {
                $me->d->{files_hash}{$file}{module} = $module;
            }
        }
    }
    else {
        my %in_basedir= map {$_=>1} grep {/^[^\/]+\.pm$/} @$files;
        
        foreach my $file (@$files) {
            next unless $file=~/\.pm$/;
            next if $file=~m{^x?t/};
            next if $file=~m{^test/};
            next if $file=~m/^(bin|scripts?|ex|eg|examples?|samples?|demos?)\/\w/i;
            next if $file=~m{^inc/};   # skip Module::Install stuff
            next if $file=~m{^(local|perl5|fatlib)/};

            # proper file in lib/
            if ($file=~m|^lib/(.*)\.pm$|) {
                my $module=$1;
                $module=~s|/|::|g;
                push (@{$me->d->{modules}},{
                    module=>$module,
                    file=>$file,
                    in_basedir=>0,
                    in_lib=>1,
                });
                $me->d->{files_hash}{$file}{module} = $module;
            }
            else {
                # open file and find first package
                my $module;
                my $max_lines_to_look_at=666;
                open (my $fh,"<",catfile($me->distdir,$file)) || die "__PACKAGE__: Cannot open $file to find package declaration: $!";
                while (my $line = <$fh>) {
                    next if $line =~/^\s*#/; # ignore comments
                    if ($line =~/^\s*package\s*(.*?)\s*;/) {
                        $module=$1;
                        last;
                    }
                    last if $line =~/^__(DATA|END)__/;
                    $max_lines_to_look_at--;
                    last unless $max_lines_to_look_at;
                }
                # try to guess from filename
                unless ($module) {
                    $file=~m|(.*)\.pm$|;
                    $module=$1;
                    $module=~s|^[a-z]+/||;  # remove lowercase prefixes which most likely are not part of the distname (but something like 'src/')
                    $module=~s|/|::|g;
                }
                if ($module) {
                    push(@{$me->d->{modules}}, {
                        module=>$module,
                        file=>$file,
                        in_basedir=> $in_basedir{$file} ? 1 : 0,
                        in_lib=>0,
                    });
                    $me->d->{files_hash}{$file}{module} = $module;
                }
            }
        }
    }

    for my $file (keys %{$me->d->{files_hash}}) {
        next unless $file =~ /^inc\/(.+)\.pm/;
        my $module = $1;
        $module =~ s|/|::|g;
        push @{$me->d->{included_modules} ||= []}, $module;
    }

    return 1;
}



##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
    return [
        {
            name=>'proper_libs',
            error=>q{There is more than one .pm file in the base dir, or the .pm files are not in lib/ directory.},
            remedy=>q{Move your *.pm files in a directory named 'lib'. The directory structure should look like 'lib/Your/Module.pm' for a module named 'Your::Module'.},
            is_extra => 1,
            code=>sub { 
                my $d=shift;
                my @modules = @{$d->{modules} || []};
                return 1 unless @modules;

                my @not_in_lib = grep { !$_->{in_lib} } @modules;
                return 1 unless @not_in_lib;

                my @in_basedir=grep { $_->{in_basedir} } @not_in_lib;
                return 1 if @in_basedir == 1;

                $d->{error}{proper_libs} = join ', ', map {$_->{file}} @not_in_lib;

                return 0;
            },
            details=>sub {
                my $d = shift;
                my @modules = @{$d->{modules} || []};
                return "No modules were found" unless @modules;
                return "The following files were found: ".$d->{error}{proper_libs};
            },
        },
    ];
}


q{Favourite record of the moment:
  Fat Freddys Drop: Based on a true story};


__END__

=encoding UTF-8

=head1 NAME

Module::CPANTS::Kwalitee::FindModules - Find modules provided by a dist

=head1 SYNOPSIS

Finds and reports all modules (i.e. F<*.pm> files) in a distribution.

=head1 DESCRIPTION

=head2 Methods

=head3 order

Defines the order in which Kwalitee tests should be run.

Returns C<30>, as data generated by C<MCK::FindModules> is used by other tests.

=head3 analyse

C<MCK::FindModules> first looks in C<basedir> and F<lib/> for C<*.pm> files. If it doesn't find any, it looks in the whole dist, but the C<proper_libs> kwalitee point is only awarded if the modules are F<lib/> or there's only one module in C<basedir>.

=head3 kwalitee_indicators

Returns the Kwalitee Indicators datastructure.

=over

=item * proper_libs

=back

=head1 SEE ALSO

L<Module::CPANTS::Analyse>

=head1 AUTHOR

L<Thomas Klausner|https://metacpan.org/author/domm>

=head1 COPYRIGHT AND LICENSE

Copyright © 2003–2006, 2009 L<Thomas Klausner|https://metacpan.org/author/domm>

You may use and distribute this module according to the same terms
that Perl is distributed under.

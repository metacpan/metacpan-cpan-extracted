package Module::CPANTS::Analyse;
use 5.006;
use strict;
use warnings;
use base qw(Class::Accessor);
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile catdir splitpath);
use File::Copy;
use File::stat;
use Archive::Any::Lite;
use Carp;
use IO::Capture::Stdout;
use IO::Capture::Stderr;
use CPAN::DistnameInfo;

our $VERSION = '0.96';
$VERSION = eval $VERSION; ## no critic

# setup logger
if (! main->can('logger')) {
    *main::logger = sub {
        print "## $_[0]\n" if $main::logging;
    };
}

__PACKAGE__->mk_accessors(qw(dist opts tarball distdir d mck capture_stdout capture_stderr));
__PACKAGE__->mk_accessors(qw(_testdir _dont_cleanup _tarball _x_opts));

sub import {
    my $class = shift;
    require Module::CPANTS::Kwalitee;
    Module::CPANTS::Kwalitee->import(@_);
}

sub new {
    my $class=shift;
    my $opts=shift || {};
    $opts->{d}={};
    $opts->{opts} ||= {};
    my $me=bless $opts,$class;
    $main::logging = 1 if $me->opts->{verbose};
    Carp::croak("need a dist") if not defined $opts->{dist};
    main::logger("distro: $opts->{dist}");

    $me->mck(Module::CPANTS::Kwalitee->new);

    # For Test::Kwalitee and friends
    $me->d->{is_local_distribution} = 1 if -d $opts->{dist};
    
    unless ($me->opts->{no_capture} or $INC{'Test/More.pm'}) {
        my $cserr=IO::Capture::Stderr->new;
        my $csout=IO::Capture::Stdout->new;
        $cserr->start;
        $csout->start;
        $me->capture_stderr($cserr);
        $me->capture_stdout($csout);
    }
    return $me; 
}

sub run {
    my $me = shift;
    $me->unpack unless $me->d->{is_local_distribution};
    $me->analyse;
    $me->calc_kwalitee;
    $me->d;
}

sub unpack {
    my $me=shift;
    return 'cant find dist' unless $me->dist;

    my $di=CPAN::DistnameInfo->new($me->dist);
    my $ext=$di->extension || 'unknown';
    
    $me->d->{package}=$di->filename;
    $me->d->{vname}=$di->distvname;
    $me->d->{extension}=$ext;
    $me->d->{version}=$di->version;
    $me->d->{dist}=$di->dist;
    $me->d->{author}=$di->cpanid;
    $me->d->{released} = stat($me->dist)->mtime;
    $me->d->{size_packed}=-s $me->dist;

    unless($me->d->{package}) {
        $me->d->{package}=$me->tarball;
    }

    copy($me->dist,$me->testfile);

    eval {
        my $archive=Archive::Any::Lite->new($me->testfile);
        $archive->extract($me->testdir);
    };

    if (my $error=$@) {
        if (not $INC{'Test/More.pm'}) {
            $me->capture_stdout->stop;
            $me->capture_stderr->stop;
        }
        $me->d->{extractable}=0;
        $me->d->{error}{extractable}=$error;
        $me->d->{kwalitee}{extractable}=0;
        my ($vol,$dir,$name)=splitpath($me->dist);
        $name=~s/\..*$//;
        $name=~s/\-[\d\.]+$//;
        $name=~s/\-TRIAL[0-9]*//;
        $me->d->{dist}=$name;
        return $error;
    }
    
    $me->d->{extractable}=1;
    unlink($me->testfile);
   
    opendir(my $fh_testdir,$me->testdir) || die "Cannot open ".$me->testdir.": $!";
    my @stuff=grep {/\w/} readdir($fh_testdir);

    if (@stuff == 1) {
        $me->distdir(catdir($me->testdir,$stuff[0]));
        if (-d $me->distdir) {

          my $vname = $di->distvname;
          $vname =~ s/\-TRIAL[0-9]*//;

          $me->d->{extracts_nicely}=1 if $vname eq $stuff[0];
        } else {
          $me->distdir($me->testdir);
          $me->d->{extracts_nicely}=0;
        }
    } else {
        $me->distdir($me->testdir);
        $me->d->{extracts_nicely}=0;
    }
    return;
}

sub analyse {
    my $me=shift;

    foreach my $mod (@{$me->mck->generators}) {
        main::logger("analyse $mod");
        $mod->analyse($me);
    }
}

sub calc_kwalitee {
    my $me=shift;

    my $kwalitee=0;
    $me->d->{kwalitee}={};
    my %x_ignore = %{$me->x_opts->{ignore} || {}};
    foreach my $i ($me->mck->get_indicators) {
        next if $i->{needs_db};
        main::logger($i->{name});
        my $rv=$i->{code}($me->d, $i);
        $me->d->{kwalitee}{$i->{name}}=$rv;
        if ($x_ignore{$i->{name}} && $i->{ignorable}) {
            $me->d->{kwalitee}{$i->{name}} = 1;
            if ($me->d->{error}{$i->{name}}) {
                $me->d->{error}{$i->{name}} .= ' [ignored]';
            }
        }
        $kwalitee+=$rv;
    }

    $me->d->{'kwalitee'}{'kwalitee'}=$kwalitee;
    main::logger("done");
}

#----------------------------------------------------------------
# helper methods
#----------------------------------------------------------------

sub testdir {
    my $me=shift;
    return $me->_testdir if $me->_testdir;
    if ($me->_dont_cleanup) {
        return $me->_testdir(tempdir());
    } else {
        return $me->_testdir(tempdir(CLEANUP => 1));
    }
}

sub testfile {
    my $me=shift;
    return catfile($me->testdir,$me->tarball); 
}

sub tarball {
    my $me=shift;
    return $me->_tarball if $me->_tarball;
    my (undef,undef,$tb)=splitpath($me->dist);
    return $me->_tarball($tb);
}

sub x_opts {
    my $me = shift;
    return $me->_x_opts if $me->_x_opts;
    my %opts;
    if (my $x_cpants = $me->d->{meta_yml}{x_cpants}) {
        if (my $ignore = $x_cpants->{ignore}) {
            if (ref $ignore eq ref {}) {
                $opts{ignore} = $ignore;
            }
            else {
                $me->d->{error}{x_cpants} = "x_cpants ignore should be a hash reference (key: metric, value: reason to ignore)";
            }
        }
    }
    $me->_x_opts(\%opts);
}

q{Favourite record of the moment:
  Jahcoozi: Pure Breed Mongrel};

__END__

=encoding UTF-8

=head1 NAME

Module::CPANTS::Analyse - Generate Kwalitee ratings for a distribution

=head1 SYNOPSIS

    use Module::CPANTS::Analyse;

    my $analyser=Module::CPANTS::Analyse->new({
        dist=>'path/to/Foo-Bar-1.42.tgz',
    });
    $analyser->run;
    # results are in $analyser->d;

=head1 DESCRIPTION

=head2 Methods

=head3 new

  my $analyser=Module::CPANTS::Analyse->new({dist=>'path/to/file'});

Plain old constructor.

=head3 unpack

Unpack the distribution into a temporary directory.

Returns an error if something went wrong, C<undef> if all went well.

=head3 analyse

Run all analysers (defined in C<Module::CPANTS::Kwalitee::*> on the dist.

=head3 calc_kwalitee

Check if the dist conforms to the Kwalitee indicators. 

=head3 run

Unpacks, analyses, and calculates kwalitee, and returns a resulting stash.

=head2 Helper Methods

=head3 testdir

Returns the path to the unique temp directory.

=head3 testfile

Returns the location of the unextracted tarball.

=head3 tarball

Returns the filename of the tarball.

=head3 x_opts

Returns a hash reference that holds normalized information set in the "x_cpants" custom META field.

=head1 WEBSITE

L<http://cpants.cpanauthors.org/>

=head1 BUGS

Please report any bugs or feature requests, or send any patches, to
bug-module-cpants-analyse at rt.cpan.org, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-CPANTS-Analyse>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 AUTHOR

L<Thomas Klausner|https://metacpan.org/author/domm>

Please use the C<perl-qa> mailing list for discussing all things CPANTS:
L<http://lists.perl.org/list/perl-qa.html>

Based on work by L<Léon Brocard|https://metacpan.org/author/lbrocard> and the
original idea proposed by
L<Michael G. Schwern|https://metacpan.org/author/schwern>.

=head1 LICENSE

This code is Copyright © 2003–2006
L<Thomas Klausner|https://metacpan.org/author/domm>.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

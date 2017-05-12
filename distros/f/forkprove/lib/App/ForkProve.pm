package App::ForkProve;

use strict;
use 5.008_001;
use version; our $VERSION = "v0.4.10";

use App::Prove;
use Getopt::Long ':config' => qw(bundling pass_through no_ignore_case);
use Scalar::Util 'openhandle';

use App::ForkProve::SourceHandler;

our @Blacklists = qw( Test::SharedFork );
our %Data;

sub run {
    my($class, @args) = @_;

    # Probably have to copy to @ARGV so that App::Prove can mangle it
    # in theory we don't need to, but doing so will make some tests fail
    # even with local @ARGV = () in SourceHandler. Not sure why...
    local @ARGV = @args;

    @ARGV = map { /^(-M)(.+)/ ? ($1,$2) : $_ } @ARGV;

    my @modules;
    my $lib;
    my $blib;
    my @inc;
    Getopt::Long::GetOptions('M=s@', \@modules);
    Getopt::Long::GetOptionsFromArray([@ARGV],
        'l|lib',  \$lib,
        'b|blib', \$blib,
        'I=s@',   \@inc,
    );

    if ($lib) {
        unshift @inc, 'lib';
    }

    if ($blib) {
        unshift @inc, 'blib/lib', 'blib/arch';
    }


    for (@modules) {
        my($module, @import) = split /[=,]/;
        local @INC{map pkg_to_file($_), @Blacklists} = (__FILE__) x scalar(@Blacklists);
        local @INC = (@inc, @INC);

        eval "require $module" or die $@;
        $module->import(@import);
    }

    for my $loaded (keys %INC) {
        next unless $loaded =~ /\.pm$/;

        my $mod = $loaded;
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{};

        my $fh = do {
            no strict 'refs';
            *{ $mod . '::DATA' }
        };

        $Data{$mod} = [!!openhandle($fh), $INC{$loaded}];
        push @{ $Data{$mod} }, tell($fh)
            if $Data{$mod}[0];
    }

    my $app = App::Prove->new;
    $app->process_args(@ARGV);
    $app->run;
}

sub pkg_to_file {
    local $_ = shift;
    s|::|/|g;
    "$_.pm";
}


1;
__END__

=encoding utf-8

=head1 NAME

App::ForkProve - forking prove

=head1 SYNOPSIS

  use App::ForkProve;
  App::ForkProve->run(@ARGV);

=head1 DESCRIPTION

App::ForkProve is a backend for L<forkprove>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2012- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<forkprove>

=cut

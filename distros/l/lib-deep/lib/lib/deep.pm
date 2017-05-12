package lib::deep;
use 5.008001;
use strict qw(vars subs);
our $VERSION = qw(0.93);
my %cache;
our $is_unix = $^O eq 'linux' || $^O =~m#bsd\z# || $^O eq 'cygwin';
sub path_need_canonize{ # Path isn't absolute
    if ( $is_unix ){
        return 1 if $_[0] !~m#\A/#;
        return 1 if $_[0] =~m#/\.\.?/#;
        return 1 if $_[0] =~ m#/\.\z#;
        return 1 if $_[0] =~ m#/\.\.\z#;
        return '';
    }
    return 1;
}
sub mkapath{
    my ($file, $depth, $lib) = @_;
    my @l = split /[\/\/]+/, $file, -1;
    my $path;
    pop @l; 
    @l = '.' if !@l;
    if ( $depth == 0 ){
        $path = join "/", @l;
    }
    else {
        $path = join "/", @l, ('..') x $depth;
    }
    my $r = sub { length $lib ? "$_[0]/lib" : $_[0] };
    if ( ! path_need_canonize( $path ) ){
        return $r->($path);
    }
    else {
        return $r->(abs_path( $path ));
    }
}

sub import{
    my $class = shift;
    my $up_depth;
    my ( $pkg, $file ) = (caller )[0,1];
    if ( @_ ){
        if ( $_[0] eq 0 ){
            $up_depth = 0;
        } 
        elsif ($_[0]=~m#^-(\d+)$# ){
            $up_depth = $1;
        }
        else {
            require Carp;
            Carp::croak( "lib::deep unknown path spec '$_[0]'");
            return;
        }
    }
    else {
        $up_depth = 0;
        if ( ( $pkg || 'main' ) eq 'main' ){
            my $test0 = mkapath( $file, 0, 'lib' );
            $up_depth = -d $test0 ? 0 : 1;
        }
        else {
            ++$up_depth;
            ++$up_depth while $pkg=~s/\A\w+:://;
        }
    }
    my $abs_lib = mkapath( $file, $up_depth, 'lib' );
    unshift @INC, $abs_lib if ! grep $abs_lib eq $_, @INC;
}

my $abs_path_generic = sub { 
    require Cwd;
    \&Cwd::abs_path;
};
my $abs_path_linux = sub {
    my $relpath = shift;
    
    my $path;
    my $doth;;
    my $can_ok = eval {
        my $start;
        opendir $doth, '.' or die '1';
        chdir $doth or die '2';
        
        opendir $start, $relpath or die "2.4 $relpath";
        chdir $start or die '2.5';
        my @pathr;
        my $current = $start;
        my $current_info = [ stat $start ];
        opendir my $down, ".." or die '3';
        my $down_info = [ stat  $down ];
        my $match = sub { $_[0][1] == $_[1][1] && $_[0][0] == $_[1][0] };
        while( ! $match->( $current_info, $down_info )){
            chdir $down;
            my $found;
            while( defined ( $found = readdir $down )){
                my $i = [ lstat $found ];
                last if $match->( $i, $current_info );
            }
            if ( defined $found ){
                push @pathr, $found;
                $current = $down;
                $current_info = $down_info;
                $down = undef;
                opendir $down, '..' or die '5';
                $down_info = [ stat $down ];
            }
            else {
                die '4';
            }
        }
        push @pathr, '';
        $path = join "/", reverse @pathr;
        1;
    };
    if ( $can_ok ){
        chdir $doth if $doth;
        return $path;
    };
    warn "getcwd-$@ -$!";
    return $relpath;
};
*abs_path = $^O eq 'linux' && ! $INC{'Cwd.pm'} ? $abs_path_linux : $abs_path_generic;
1;
__END__

=head1 NAME

lib::deep - C<lib> that choose lib path for you if you want ...

=head1 SYNOPSIS

    
    package A::B::C;
    use lib::deep; # same as 'use lib::abs qw(../../../lib);'
    # same as lib::abs qw(../..); 
    # almost same as use lib qw(../..);
    

    use lib::abs -1; # same as 'use lib::abs qw(../lib);'

    use lib::abs -2; # same as 'use lib::abs qw(../../lib);'

    use lib::abs -0; # same as 'use lib::abs qw(lib);'


=head1 SEE ALSO

    lib::abs,  lib

=head1 BUGS

    This module wasn't tested for windows.

=head1 AUTHOR

Grishayev Anatoliy, E<lt>grian@E<gt>cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Grishayev Anatoliy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

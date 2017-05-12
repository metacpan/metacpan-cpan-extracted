
use 5.010;
use strict;
use warnings;
use File::Find;

sub wanted_func_interface {
    my $file = $_;
    
    if ( $file =~ / \A \w+ \.pm \z /xms ) {
        open ( my $perlmodule, '<', $file );
        
        my $content = q{};
        my $function_list = q{};
        my @functions     = ();
        my $method_list   = q{};
        my @methods       = ();
        
        while ( <$perlmodule> ) {
            $content .= $_;
        }

        ($function_list) = ($content =~ m{
            \A .*
                func \s* => \s* \[ \s*
                    (.*?) ,?
                \s* \] \s* ,?
            .* \z
        }xms);
        
        ($method_list)   = ($content =~ m{
            \A .*
                oo   \s* => \s* \[ \s*
                    (.*?) ,?
                \s* \] \s* ,?
            .* \z
        }xms);
        
        return if ! ($function_list && $method_list);
        
        print $file, ":\n";
        
        @functions = split ( /,/, $function_list );
        @methods   = split ( /,/, $method_list );

        chomp ( @functions );
        chomp ( @methods   );
        
        # Filter out empty entries
        @functions = grep { /\w/ } @functions;
        @methods   = grep { /\w/ } @methods;
        
        # Trim leading and trailing whitespace
        @functions = map { trim($_) } @functions;
        @methods   = map { trim($_) } @methods;
        
        # Get rid of private subroutines
        @functions = grep { / \A \s* [^_] .* \z /xms } @functions;
        @methods   = grep { / \A \s* [^_] .* \z /xms } @methods;
        
        print "\tFunctional Interface:\n";
        print map { "\t\t$_\n" } @functions;
        
        print "\n";

        print "\tOO Interface:\n";
        print map { "\t\t$_\n" } @methods;
    }
}

sub trim {
    my($string) = @_;
    $string =~ s|.*'(.*)'.*|$1|xms;
    return $string;
}

sub find_use_api {
    my $file = $_;
    if ( $file =~ /\.pm$/ ) {
        open ( my $fh, $file );
        print "$file:\n";
        while (<$fh>) {
            print "$_\n" if /use .*API/;
        }
    }
}

find ( \&find_use_api, '.' );

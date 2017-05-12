package namespace;

=head1 NAME

namespace - Perl pragma to use like C++ namespace aliasing

=head1 SYNOPSIS

 use namespace File => IO::File;

 my $fh = new File "foo", O_CREAT|O_WRONLY;
 if( defined $fh )
 {
     print $fh "bar\n";
     $fh->close;
 }

=head1 DESCRIPTION

Allow aliasing namespace. May be useful for reusability increase.

 use namespace ALIAS => PACKAGE 
    [, qw/IMPORT_LIST [ ::SUBPACKAGE [ IMPORT_LIST ]] /];

 ALIAS and PACKAGE is required parameters;
 IMPORT_LIST is the usual list of import.


Also may be undefined namespace and they subnamespaces:

 no namespace ALIAS;


If ALIAS begin with '::', then alias will be expandet to 
caller namespace. If following example of pragma namespace 
called from main:: module, then alias will be expandet to main::ALIAS::.
     
 use namespace ::ALIAS => PACKAGE
    

=head1 EXAMPLES

 EXAMPLE 1

 use namespace DOM => XML::DOM, qw/$VERSION ::Document $VERSION/;

    # DOM is alias for XML::DOM
    #       $VERSION from XML::DOM will be imported to DOM
    #
    # ::Document subpackage of XML::DOM will be aliased to DOM::Document
    #       $VERSION from XML::DOM::Document will be imported to DOM::Document

 my $doc = new DOM::Document;
 print "Current used DOM version is $DOM::VERSION \n";

 no namespace DOM;

    # namespace DOM and all subnamespaces will be destroyed



 EXAMPLE 2

 use namespace DOM => XML::DOM, qw/::Document/;
 # or
 # use namespace DOM => XML::Sablotron::DOM, qw/:constants ::Document/;

 my $doc = new DOM::Document;
 print "Constant 'TEXT_NODE' = ", TEXT_NODE;

=head1 AUTHOR

Albert MICHEEV <amichauer@cpan.org>

=cut

use strict qw/subs vars/;
$namespace::VERSION = '0.05';


sub import{
    my ($slf, $als, $pkg) = (shift, shift, shift);
    my $clr = (caller)[0];

    $als = $clr.$als if substr($als, 0, 2) eq '::';

    die "Package '$als' already defined!" if defined %{$als.'::'};

    require join( '/', split '::', $pkg ) . '.pm' unless defined %{$pkg.'::'};
    @{$als.'::ISA'} = $pkg;

    if( @_ and $_[0] eq '()' ){ shift }
    else{ unshift @_, @{$pkg.'::EXPORT'} if defined @{$pkg.'::EXPORT'} }

    my ($Pkg, $Als) = ($pkg, $als);

    while( my $imp = shift ){
        if( substr($imp, 0, 2) eq '::' ){
            $Pkg = $pkg.$imp;
            $Als = $als.$imp;
            @{$Als.'::ISA'} = $Pkg;
            if( @_ and $_[0] eq '()' ){ shift }
            else{ unshift @_, @{$Pkg.'::EXPORT'} if defined @{$Pkg.'::EXPORT'} }
        }
        elsif( $imp =~ /^:(.+)$/ ){
            die "Can't find '$imp' export tag in $Pkg!\n" unless
                defined ${$Pkg.'::'}{EXPORT_TAGS}{$1};
            unshift @_, @{ ${$Pkg.'::'}{EXPORT_TAGS}{$1} };
        }
        elsif( $imp =~ /^([\$%@])?(.+)$/ ){
            die "Can't find '$imp' from $Pkg!\n" unless
                !$1       && defined \&{$Pkg.'::'.$2} or
                $1 eq '$' && defined \${$Pkg.'::'.$2} or
                $1 eq '@' && defined \@{$Pkg.'::'.$2} or
                             defined \%{$Pkg.'::'.$2};
            *{$clr.'::'.$2} = 
            *{$Als.'::'.$2} = 
               !$1        ? \&{$Pkg.'::'.$2} :
                $1 eq '$' ? \${$Pkg.'::'.$2} :
                $1 eq '@' ? \@{$Pkg.'::'.$2} : 
                            \%{$Pkg.'::'.$2};
        }
        else{ die "Undefined behavior!\n" }
    }
}

sub unimport{
    undef %{(substr($_[1], 0, 2) eq '::' ? (caller)[0] : '' ).$_[1].'::'};
}

1;

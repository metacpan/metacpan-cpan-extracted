package VJF::MITDT; 
use strict;
use vars qw(@ISA @EXPORT_OK $VERSION %EXPORT_TAGS);

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(cree_data1 set_trio get_trio make_freq_cum make_imput init_tab compt_geno compt_untrans new_param new_posterior cree_data1_H0 init_tab_H0 compt_hap_H0 new_param_H0 new_posterior_H0 print_data);
%EXPORT_TAGS = ('all' => \@EXPORT_OK);
$VERSION   = '1.01';

require XSLoader;
XSLoader::load('VJF::MITDT', $VERSION);

return 1;

=head1 NAME

VJF::MITDT - Multiple Imputation for Transmission Disequilibrium Test.

=head1 SYNOPSIS

  use VJF::MITDT qw(:all);

=head1 DESCRIPTION

This module intended to be used by the L<MI-TDT> script. Install it to get the script.

=head1 INSTALLATION

To install this module, the Gnu Scientific Library (GSL) L<http://www.gnu.org/software/gsl/> needs to be installed.

If you are familiar with Perl modules installation, just install the VJF::MITDT module by your favorite method. If you are a profane to Perl modules, here are some short instructions.

=head2 Global install

If you are root or a sudoer, just use the following command (assuming Perl is installed on your system):

 sudo perl -MCPAN -e 'install VJF::MITDT' 

And that's all!

=head2 Local install

If you wan to perform a local installation, for example in a directory named ~/myperl/. 

The three following commands will initialize the CPAN module, and and modify its default configuration. You just have to run these lines one time, the CPAN module won't forget the configuration. Just copy-paste the following lines in a terminal:

 echo "o conf init" | perl -MCPAN -e shell
 echo -e "o conf prerequisites_policy yes\n o conf commit"\
 | perl -MCPAN -e shell
 echo -e "o conf makepl_arg 'PREFIX=~/myperl\
 LIB=~/myperl/lib INSTALLSCRIPT=~/myperl/bin\ 
 INSTALLBIN=~/myperl/bin INSTALLMAN1DIR=~/myperl/man/man1\
 INSTALLMAN3DIR=~/myperl/man/man3'\no conf commit"\ 
 | perl -MCPAN -e shell

Then, your CPAN module is ready for use. You just have to type:

 perl -MCPAN -e 'install VJF::MITDT'

Before using MI-TDT, you must tell Perl and the system about the ~/myperl/ directory. 

If you are a bash user, you should add in ~/.bash_profile 

 export PATH=$PATH:~/myperl/bin
 export PERL5LIB=$PERL5LIB:~/myperl/lib
 export MANPATH=$MANPATH:~/myperl/man

If you are a bash user, you should add in ~/.tcshrc

 setenv PATH $PATH:~/myperl/bin
 setenv PERL5LIB $PERL5LIB:~/myperl/lib
 setenv MANPATH $MANPATH:~/myperl/man


=head1 SEE ALSO

L<MI-TDT>

=head1 CITATION

If you use MI-TDT for a publication, thank you to refer the original paper where this method is described.

Croiseau P, Génin E, Cordell HJ. Dealing with missing data in family-based association studies: A multiple imputation approach. I<Human Heredity> 2007; 63:229-238


=cut


package ToolSet::y;
use strict;
use warnings;
use base 'ToolSet';
#ToolSet->use_pragma( 'strict' );
#ToolSet->use_pragma( 'warnings' );
BEGIN {
    if ( $] >= 5.010 ){
        ToolSet->use_pragma(qw(feature :5.10));    # perl 5.10
    }
    my @optional = ();
    my @alias = ();
    my $mod;
    
    eval { require DBI };
    eval { require List::Pairwise };
    push @optional, ( 'List::Pairwise'  => '
                            mapp
                            grepp
                            firstp
                            lastp
                            pair
                            map_pairwise
                            grep_pairwise
                            first_pairwise
                            last_pairwise
    ') unless $@;

    $mod = 'Statistics::Descriptive';
    eval { require Statistics::Descriptive };
    unless ($@){
        push @optional, ($mod => undef);
        push @alias, "SDF ${mod}::Full";
    }

    eval { require File::ReadBackwards };
    unless ($@){
        push @alias, "FRB File::ReadBackwards";
    }
    eval { require File::Find::Rule };
    unless ($@) {
        push @alias, "FFR File::Find::Rule";
    }

    $mod = 'Package::Alias';
    eval { require Package::Alias };
    @alias=() if $@; # don't load aliases if Package::Alias is not installed

# define exports from other modules
ToolSet->export(
    'Env'             => undef,

    'Class::Autouse'  => ':superloader',
    'autouse'         => 'Attempt attempt(&;@)',
    'autouse'         => 'Data::Dumper Dumper',
    'autouse'         => 'Data::Dump dd pp',
    'autouse'         => 'Carp carp croak confess cluck',
    'autouse'         => 'File::Find find',
    'autouse'         => 'Scalar::Util
                           dualvar
                           isweak
                           readonly
                           tainted
                           weaken
                           isvstring
                           looks_like_number
                           set_prototype
                           blessed($)
                           refaddr($)
                           reftype($)
    ',
    'autouse'         => 'List::Util
                            reduce(&@)
                            first(&@)
                            sum(@)
                            min(@)
                            max(@)
                            minstr(@)
                            maxstr(@)
                            shuffle(@)
    ',

    'autouse'         => 'List::MoreUtils 
                            any(&@)
                            all(&@)
                            none(&@)
                            notall(&@)
                            true(&@)
                            false(&@)
                            firstidx(&@)
                            lastidx(&@)
                            insert_after(&$\@)
                            insert_after_string($$\@)
                            apply(&@)
                            after(&@)
                            after_incl(&@)
                            before(&@)
                            before_incl(&@)
                            indexes(&@)
                            lastval(&@)
                            firstval(&@)
                            pairwise(&\@\@)
                            each_array(\@;\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@)
                            each_arrayref
                            natatime($@)
                            mesh(\@\@;\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@)
                            uniq(@)
                            minmax(@)
                            part(&@)
    ',
     'autouse'         => 'Storable store retrieve nstore store_fd nstore_fd fd_retrieve freeze
                          nfreeze thaw dclone retrieve_fd lock_store lock_nstore
                          lock_retrieve file_magic read_magic',

     # modules you can't load via autouse
     @optional,
     # where you like to add a package alias
     map( {("Package::Alias" => $_)} @alias ),
);
}

our $VERSION = '0.01';
no warnings 'void';
"oneliner roolz";

__END__
=head1 NAME

ToolSet::y - -My one-liner ToolSet

=head1 SYNOPSIS

   # get super productive and install this module as package "y" via ./Build install_short

   # using Class::AutoUse ':superloader'
   perl -MToolSet::y -e '$i=Net::IP->new("193.0.1/24"); say $i->ip'

   # Package::Alias aliased Statistics::Descriptive::Full -> SDF
   perl -MToolSet::y -e '$s=SDF->new;$s->add_data(0 .. 10); print $s->variance'

   # perl 5.10 features + Scalar::Util
   perl -MToolSet::y -e 'given ($ARGV[0]) { when (looks_like_number($_)) {say "looks like a number"}}' 2E42

   # Package::Alias aliased File::ReadBackwards -> FRB
   perl -MToolSet::y -e '$r=FRB->new($INC{"y.pm"}); print while(defined ($_=$r->readline))'

   # List::Pairwise unfortunately no autouse possible
   perl -MToolSet::y -e '%lc_keys = mapp {"\L$a"=>$b} (A => 1, B => 2, C => 3); say "@$_" for pair %lc_keys'

   # File::Find::Rule + Env shortcut
   perl -MToolSet::y -e'say for FFR->name("*.pm")->in("$HOME/lib")'

=head1 DESCRIPTION

ToolSet::y.pm is richly packed ToolSet, it excessivly uses autouse and Class::Autouse and loads
commonly used perlmodules and OO Modules on demand.
Because of its excessive magic it is not recommended,
that you use it anywhere else except for quickndirty one-liners.

That beeing said, welcome new age of productivity.

=head1 BUGS AND LIMITATIONS

There are some limitations on Class::Autouse. t/02-dumper.t complains about
deprecated AUTOLOADING in main::02-dumper.t when warnings are enabled.

I have no desire to analyse this, but I would appreciate a fix if you send it to me :-)

Examples in the synopsis only work when the modules used are installed.
With all the autouse stuff errors may pop up later at runtime.

DBI when Class::Autouse'd gives some strange "Can't locate DBD/Switch/dr_mem.pm" warnings.
So some bugs can still lurk here.

Please report any bugs or feature requests to
C<bug-toolset-y@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

   codeacrobat, C<< <joerg{at}joergmeltzer.de> >>

   Please share your favorite one-liner modules with me.
   You can also find me on http://twitter.com/perloneliner

=head1 COPYRIGHT & LICENSE

Copyright 2009 codeacrobat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


package vars::global;
{
   use version; $VERSION = qv('0.0.4');

   use warnings;
   use strict;
   use Carp;

   # Module implementation here
   # Where we keep existing globals
   my %ref_for;

   sub import {
      my $package = shift;
      my $caller  = caller;
      my @import;
      GRAB_IMPORTS:
      while (@_) {
         my $param = shift;
         last GRAB_IMPORTS if lc($param) eq 'create';

         if (lc($param) eq ':all') {
            @import = keys %ref_for;
            while (@_) {
                last GRAB_IMPORTS if shift eq 'create';
            }
            last GRAB_IMPORTS;
         }
            
         push @import, $param;
      }
      $package->_create($caller, @_);
      $package->_import($caller, @import, @_);
      return;
   } ## end sub import

   sub create {
      my $package = shift;
      my $caller  = caller;
      $package->_create($caller, @_);
      $package->_import($caller, @_);
      return;
   } ## end sub create

   sub has {
      my $package = shift;
      my ($symbol) = @_;
      return unless exists $ref_for{$symbol};
      return $ref_for{$symbol};
   } ## end sub has

   sub _create {
      my $package = shift;
      my $caller  = shift;
      my @symbols = @_;
      no strict 'refs';
      no warnings 'once';
      foreach my $symbol (@symbols) {

         # Some checks
         croak "undefined symbol" unless defined $symbol;
         croak "empty symbol"     unless length $symbol;
         my $identifier = substr $symbol, 1;
         croak "invalid identifier '$identifier'"
           unless $identifier =~ /\A \w+ \z/mxs;

         my $fqn = $package . '::' . $identifier;
         my $sigil = substr $symbol, 0, 1;
         $ref_for{$symbol} =
             $sigil eq '$' ? \${$fqn}
           : $sigil eq '@' ? \@{$fqn}
           : $sigil eq '%' ? \%{$fqn}
           : croak "invalid sigil: '$sigil'";
      } ## end foreach my $symbol (@symbols)
      return;
   } ## end sub _create

   sub _import {
      my $package = shift;
      my $caller  = shift;
      no strict 'refs';
      foreach my $symbol (@_) {
        my $ref = $package->has($symbol)
           or croak "non existent global: '$symbol'";
         *{$caller . '::' . substr $symbol, 1} = $ref;
      }
      return;
   } ## end sub _import
}

1;    # Magic true value required at end of module
__END__

=encoding iso-8859-1

=head1 NAME

vars::global - try to make global variables a little safer


=head1 VERSION

This document describes vars::global version 0.0.1. But don't trust this
number, see $VERSION at the very beginning of the module (you can see
the source with 

   perldoc -m vars::global
   
did you know?)


=head1 SYNOPSIS

    # In the place/package where we want to create globals
    use vars::global create => qw( $foo @bar %baz );

    # Add some more global symbols
    vars::global->create(qw( $hello @world %now ));

    # Somewhere else, where we need to access those globals
    use vars::global qw( $foo @bar %baz );

    # Don't try to use globals that do not exist
    use vars::global qw( $Foo ); # typo, croaks
    use vars::global qw( @inexistent ); # we don't create by default
                                        # use 'create' as above

    # You can also import and create new globals
    use vars::global qw( $foo %baz ), create => qw( $hey @joe );

    # If you're lazy, you can import all the globals defined so far
    use vars::global ':all';

  
=head1 DESCRIPTION

This module lets you define 'global' variables and gain a slight
advantage over blind use of package variables.

The global variables live inside the C<vars::global> package, with the
names given by the user. Where' the advantage? It's two-fold:

=over

=item *

there is an import mechanism that lets you access the global variable
without the need to fully qualify its name (i.e. using C<$foo> instead
of C<$vars::global::foo>);

=item *

the import mechanism ensures that you can import only the global variables
that have been explicitly declared so far, which reduces the possibility
of a typo.

=back

If you have already "created" the global variable C<$foo>, the import
operation is equivalent to do:

   *{__PACKAGE__ . '::foo'} = \$vars::global::foo;

that is, the package variable in the current package is made an alias for
the global variable.

The anti-typo check is simply obtained by doing a check before the above
import.

Typical usage is as follows:

=over

=item creation

Early in the module or in the program you create variables prepending
the C<create> word, as follows:

   use vars::global create => qw( $foo @bar %baz );

=item access

In the modules where you need to access a given global variable, you
can import them very simply:

   use vars::global qw( $foo %baz ); # I don't need @bar here ;)

The creation step above automatically imports all the new globals
into the current package.

=back

=head1 INTERFACE 

=head2 vars::global->import( @LIST );

Import symbols in C<@LIST> as global variables into the current package.
C<@LIST> must contain one of the following:

=over

=item *

a valid Perl variable name, i.e. an initial sigil among '$', '@'
and '%', followed by a valid non-empty identifier (i.e. a string
matching /\A\w+\z/);

=item *

the 'create' word, in which case the following items will be added
to the list of valid global variables before the import

=item *

the ':all' string, in which case all the currently available global
variables are imported.

=back

=head2 vars::global->create( @LIST );

Add symbols in C<@LIST> to the list of valid global variables. These
symbols must be valid Perl variable names (see above for 'import').

=head2 my $ref = vars::global->has( $varname );

Check if a given simbol (contained into $varname in the example) is
a global variable. Return undef if the symbol is not a currently
registered global variable, otherwise it returns a reference to the
variable itself.

=head1 DIAGNOSTICS

=over

=item C<< undefined symbol >>

Please don't pass the C<undef> value in the import or create list, but
only names of allowable Perl variables!

=item C<< empty symbol >>

You tried to pass a bare sigil without specifing an identifier for the
variable.

=item C<< invalid identifier '%s' >>

The symbol name should consist of a sigil (any among '$', '@' and '%')
followed by a string that can be considered an identifier, i.e.
matching /\A\w+\z/.

=item C<< invalid sigil: '%s' >>

What's unclear about the fact that the first character of every symbol
you try to import should start with '$', '@' or '%'?!?

=item C<< non existent global: '%s' >>

You tried to import a variable that hasn't been registered as a valid
global one. Chances are that you are either forgetting to create it,
or that you made a typo.

=back


=head1 CONFIGURATION AND ENVIRONMENT

vars::global requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<strict> and C<warnings> are almost always on, except the few points
where we really need to shut them down. Complaining is made via C<Carp>.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Not really a bug, but it has to be noted that the import mechanism
aliases package variables in the current package with those in the
C<vars::global> package. These settings are program-wide, i.e. they
apply whenever and wherever you enter the package from which you
imported. They're globals, and you should use them very sparingly!

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


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

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=cut

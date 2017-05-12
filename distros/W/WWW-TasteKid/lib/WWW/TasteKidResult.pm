package WWW::TasteKidResult;

# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */
#$Id$

use 5.008001;    # require perl 5.8.1 or later

use warnings;
use strict;

#use criticism 'brutal';

use version; our $VERSION = qv('0.1.2');

use Carp qw/croak/;
use Data::Dumper qw/Dumper/;
use Scalar::Util qw/refaddr/;
use Class::InsideOut qw/public/;

# should probably be using moose, just seems like
# overkill for a module this simple/small

public name    => my %name;
public type    => my %type;
public wteaser => my %wteaser;
public wurl    => my %wurl;
public ytitle  => my %ytitle;
public yurl    => my %yurl;

sub new {
    my $class = shift;
    my $self = bless \do { my $s }, $class;

    Class::InsideOut::register($self);

    $name{ refaddr $self }    = undef;
    $type{ refaddr $self }    = undef;
    $wteaser{ refaddr $self } = undef;
    $wurl{ refaddr $self }    = undef;
    $ytitle{ refaddr $self }  = undef;
    $yurl{ refaddr $self }    = undef;

    return $self;
}

sub inspect_result_object {
    print Dumper \%name;
    print Dumper \%type;
    print Dumper \%wteaser;
    print Dumper \%wurl;
    print Dumper \%ytitle;
    print Dumper \%yurl;
    return;
}

1;

__END__

=head1 NAME

WWW::TasteKidResult - An object encapsulating a reponse from the TasteKid API

=head1 VERSION

Version 0.1.2

=head1 SYNOPSIS

    my $tc = WWW::TasteKid->new;
    $tc->query({ type => 'music', name => 'bach' });
    $tc->query({ type => 'movie', name => 'amadeus' });
    $tc->query({ type => 'book',  name => 'star trek' });
    $tc->ask;

    my $info = $tc->info_resource;
    # returns a array ref of WWW::TasteKidResult objects
    # i.e.
    # [
    #   bless( do{\(my $o = undef)}, 'WWW::TasteKidResult' ),
    #   bless( do{\(my $o = undef)}, 'WWW::TasteKidResult' ),
    #   bless( do{\(my $o = undef)}, 'WWW::TasteKidResult' )
    # ];
     which you iterate over, calling the accessors for the 
     fields you desire

    foreach my $tkr (@{$info}) {
        print $tkr->name, $tkr->type; #accessors for a WWW::TasteKidResult object
    }

=head1 DESCRIPTION

This module useless standalone, it's only used to hold responses as 
 objects from WWW::TasteKid;

See: L<WWW::TasteKid> or (if installed) perldoc WWW::TasteKid;

=head1 OVERVIEW

See: L<WWW::TasteKid> or (if installed) perldoc WWW::TasteKid;

=head1 USAGE

See Synopsis

=head1 SUBROUTINES/METHODS

An object of this class represents an TasteKid API results object

=head2 new

my $taste_kid = WWW::TasteKidResults->new; 

Create a new WWW::TasteKidResults Object; 

Takes no arguments

=head2 name

     the name of a query

     mandatory, no object without this

=head2 type

     the type of a query

     optional, if set will return one of: music, movie, book

=head2 wteaser

     wteaser - a brief description, if found (wikipedia)

     part of the 'rich data' output, only set if the 'verbose' 
     parameter is passed to the 'ask' method

=head2 wurl

     wurl - url where the brief description was found (wikipedia)

     part of the 'rich data' output, only set if the 'verbose' 
     parameter is passed to the 'ask' method

=head2 ytitle

     ytitle - video title, if video found (youtube)

     part of the 'rich data' output, only set if the 'verbose' 
     parameter is passed to the 'ask' method

=head2 yurl

     yurl  - video url, if video found (youtube)

     part of the 'rich data' output, only set if the 'verbose' 
     parameter is passed to the 'ask' method

=head2 inspect_result_object

    'dump' our internal data structure for manual inspection, used for 
     debugging only. 

     (Data::Dumper does not work on this object since it's an inside out 
      object).

=head1 DIAGNOSTICS

None currently known

=head1 CONFIGURATION AND ENVIRONMENT

if you are running perl > 5.8.1 and have access to
install cpan modules, you should have no problem install this module

no special configuration used

=head1 DEPENDENCIES

WWW::TasteKidResult uses the following modules:

L<Carp>

L<Data::Dumper>

L<criticism>(pragma - enforce Perl::Critic if installed)

L<version> (pragma - version numbers)

L<Test::More>

L<Scalar::Util>

L<Class::InsideOut>

there shouldn't be any restrictions on versions of the above modules, as long
as you have a relativly new perl > 5.0008
most of these are in the standard Perl distribution, otherwise they are common 
enough to be pre packaged for your operating systems package system or easilly
downloaded and installed from the CPAN.

=head1 INCOMPATIBILITIES

none known of

=head1 SEE ALSO

L<http://www.tastekid.com/>


=head1 AUTHOR

David Wright, C<< <david_v_wright at yahoo.com> >>


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-www-tastekid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-TasteKid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::TasteKid


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-TasteKid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-TasteKid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-TasteKid>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-TasteKid>

=back


=head1 ACKNOWLEDGEMENTS

Some common acronems went into the making of this module:

PBP

TDD

OOP

vim


this module was created with module-starter

module-starter --module=WWW::TasteKid \
        --author="David Wright" --email=david_v_wright@yahoo.com


=head1 LICENSE AND COPYRIGHT

Copyright 2009 David Wright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::TasteKidResult


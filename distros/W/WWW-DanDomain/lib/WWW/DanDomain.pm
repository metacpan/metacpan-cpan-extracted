package WWW::DanDomain;

use warnings;
use strict;
use WWW::Mechanize;
use WWW::Mechanize::Cached;
use Carp qw(croak);
use Try::Tiny;
use 5.008;

our $VERSION = '0.08';

sub new {
    my ( $class, $param ) = @_;

    my $mech;

    my $agent = __PACKAGE__ . "-$VERSION";

    if ( $param->{mech} ) {
        $mech = $param->{mech};
    } elsif ( $param->{cache} ) {
        $mech = WWW::Mechanize::Cached->new( agent => $agent );
    } else {
        $mech = WWW::Mechanize->new( agent => $agent );
    }

    my $self = bless {
        base_url  => 'http://www.billigespil.dk/admin',
        username  => $param->{username},
        password  => $param->{password},
        url       => $param->{url},
        verbose   => $param->{verbose} || 0,
        mech      => $mech,
        processor => $param->{processor},
    }, $class;

    return $self;
}

sub retrieve {
    my ( $self, $stat ) = @_;

    if ( $self->{username} || $self->{password} ) {
        if ( ( not $self->{username} ) or ( not $self->{password} ) ) {
            croak 'Both username and password is required for authentication';
        }

        $self->{mech}->get( $self->{base_url} )
            or croak "Unable to retrieve base URL: $@";

        if (not $self->{mech}->submit_form(
                form_number => 0,
                fields      => {
                    UserName => $self->{username},
                    Password => $self->{password},
                }
            )
            )
        {
            croak 'Unable to authenticate';
        }
    }

    $self->{mech}->get( $self->{url} ) or croak "Unable to retrieve URL: $@";

    my $content = $self->{mech}->content();

    if ( ref $self->{processor} eq 'CODE' ) {
        return &{ $self->{processor} }( \$content, $stat );
    } elsif ( ref $self->{processor} ) {
        try {
            $self->{processor}->can('process');
        }
        catch {
            croak q{Your processor does not implement 'process' method};
        };
        return $self->{processor}->process( \$content, $stat );
    } else {
        return $self->process( \$content, $stat );
    }
}

sub processor {
    my ( $self, $content ) = @_;

    return $self->process($content);
}

sub process {
    my ( $self, $content ) = @_;

    if ( $self->{verbose} ) {
        print STDERR "${$content}.\n";
    }

    return $content;
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/WWW-DanDomain.svg)](http://badge.fury.io/pl/WWW-DanDomain)
[![Build Status](https://travis-ci.org/jonasbn/dand.svg?branch=master)](https://travis-ci.org/jonasbn/dand)
[![Coverage Status](https://coveralls.io/repos/jonasbn/dand/badge.png)](https://coveralls.io/r/jonasbn/dand)

=end markdown

=head1 NAME

WWW::DanDomain - class to assist in interacting with DanDomain admin interface

=head1 VERSION

This documentation describes version 0.08

=head1 SYNOPSIS

The module lets the user interact with DanDomains administrative web interface.
This can be used for automating tasks of processing data exports etc.

    use WWW::DanDomain;

    #All mandatory parameters
    #Please note DanDomain can be configured to use authorization on IP
    #meaning authentication is unnessesary
    my $wd = WWW::DanDomain->new({
        url => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
    });

    #With optional authentication credentials
    my $wd = WWW::DanDomain->new({
        username => 'topshop',
        password => 'topsecret',
        url => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
    });

    #with verbosity enabled
    my $wd = WWW::DanDomain->new({
        username => 'topshop',
        password => 'topsecret',
        url      => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
        verbose  => 1,
    });

    #With caching
    my $wd = WWW::DanDomain->new({
        username => 'topshop',
        password => 'topsecret',
        url      => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
        cache    => 1,
    });


    #With custom WWW::Mechanize object
    use WWW::Mechanize;

    my $mech = WWW::Mechanize->new(agent => 'MEGAnice bot');

    my $wd = WWW::DanDomain->new({
        username => 'topshop',
        password => 'topsecret',
        url      => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
        mech     => $mech,
    });


    #The intended use
    package My::WWW::DanDomain::Subclass;

    sub processor {
        my ( $self, $content ) = @_;

        #Note the lines terminations are Windows CRLF
        my @lines = split /\r\n/, $$content;

        ...

        }
    }


    #Using your new class
    my $my = My::WWW::DanDomain::Subclass->new({
        username => 'topshop',
        password => 'topsecret',
        url      => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
    });

    my $content = $my->retrieve();

    print $$content;


    #Using a processor implemented as a code reference
    $wd = WWW::DanDomain->new({
        username  => 'topshop',
        password  => 'topsecret',
        url       => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
        processor => sub {
            ${$_[0]} =~ s/test/fest/;
            return $_[0];
        },
    });


    #Implementing a processor class
    my $processor = MY::Processor->new();

    $processor->can('process');

    $wd = WWW::DanDomain->new({
        username  => 'topshop',
        password  => 'topsecret',
        url       => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
        processor => $processor,
    });

    my $content = $wd->retrieve();

    print ${$content};

=head1 DESCRIPTION

This module is a simple wrapper around L<WWW::Mechanize> it assists the user
in getting going with automating tasks related to the DanDomain administrative
web interface.

Such as:

=over

=item * manipulating data exports (removing, adjusting, calculating, adding
columns)

=item * filling in missing data (combining data)

=item * converting formats (from CSV to XML, JSON, CSV, whatever)

=back

=head1 METHODS

=head2 new

This is the constructor.

The constructor takes a hash reference as input. The hash reference should
contain keys according to the following conventions:

=over

=item * username, optional username credential to access DanDomain

=item * password, optional password credential to access DanDomain

=item * url, the mandatory URL to retrieve data from (L</retrieve>)

=item * mech, a L<WWW::Mechanize> object if you have a pre instantiated object
or some other object implementing the the same API as L<WWW::Mechanize>.

The parameter is optional.

See also cache parameter below for an example.

=item * verbose, a flag for indicating verbosity, default is 0 (disabled), the
parameter is optional

=item * cache, usage of a cache meaning that we internally use
L<WWW::Mechanize::Cached> instead of L<WWW::Mechanize>.

The parameter is optional

=item * processor

This parameter can be used of you do not want to implement a subclass of
WWW::DanDomain.

The processor parameter can either be:

=over

=item * an object implementing a L</proces> method, with the following profile:

    proces(\$content);

=item * a code reference with the same profile, adhering to the following example:

    sub { return ${$_[0]} };

=back

=back

=head2 retrieve

Parameters:

=over

=item * a hash reference, the reference can be populated with statistic
information based on the lineprocessing (L</processor>) initiated from
L</retrieve>.

=back

The method returns a scalar reference to a string containing the content
retrieved from the URL provided to the contructor (L</new>). If the
L</processor> method is overwritten you can manipulate the content prior
to being returned.

=head2 process

Takes the content retrieved (see: L</retrieve>) from the URL parameter provided
to the constructor (see: L</new>). You can overwrite the behaviour via the
constructor (see: L</new>).

Parameters:

=over

=item * a scalar reference to a string to be processed line by line

=back

The stub does however not do anything, but it returns the scalar reference
I<untouched>.

=head2 processor

This is a wrapper for L</process>, provided for backwards compatibility.

=head1 DIAGNOSTICS

=over

=item * Unable to authenticate, username and password not valid credentials

=item * Both username and password is required for authentication

If you want to use authentication you have to provide both B<username> and
B<password>.

=item * Unable to retrieve base URL: $@

The base URL provided to retrieve gives an error.

Please see: L<http://search.cpan.org/perldoc?HTTP%3A%3AResponse> or
L<http://search.cpan.org/~gaas/libwww-perl/lib/HTTP/Status.pm>

Test the URL in your browser to investigate.

=item * Unable to retrieve URL: $@

The base URL provided to retrieve gives an error.

Please see: L<http://search.cpan.org/perldoc?HTTP%3A%3AResponse> or
L<http://search.cpan.org/~gaas/libwww-perl/lib/HTTP/Status.pm>

Test the URL in your browser to investigate.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The module requires Internet access to make sense and an account with DanDomain
with username and password is required.

=head1 DEPENDENCIES

=over

=item * L<WWW::Mechanize>

=item * L<Carp>

=back

=head1 TEST AND QUALITY

The tests are based on L<Test::MockObject::Extends> and example data are
mocked dummy data. Please see the TODO section.

The test suite uses the following environment variables as flags:

=over

=item TEST_AUTHOR, to test prerequisites, using L<Test::Prereq>

=item TEST_CRITIC, to do a static analysis of the code, using L<Perl::Critic>,
see also QUALITY AND CODING STANDARD

=back

=head2 TEST COVERAGE

The following data are based on an analysis created using L<Devel::Cover> and
the distributions own test suite, instantiated the following way.

    % ./Build testcover --verbose

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/WWW/DanDomain.pm     100.0  100.0  100.0  100.0  100.0  100.0  100.0
    Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

Please note the report is based on version 0.03 of WWW::DanDomain

=head1 QUALITY AND CODING STANDARD

The code passes L<Perl::Critic> tests a severity: 1 (brutal)

The following policies have been disabled:

=over

=item L<Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint>

=back

L<Perl::Critic> resource file, can be located in the t/ directory of the
distribution F<t/perlcritic.rc>

L<Perl::Tidy> resource file, can be obtained from the original author

=head1 BUGS AND LIMITATIONS

No known bugs at this time.

=head1 BUG REPORTING

Please report any bugs or feature requests via:

=over

=item * email: C<bug-www-dandomain at rt.cpan.org>

=item * HTTP: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-DanDomain>

=back

=head1 DEVELOPMENT

=over

=item * Git repository: L<https://github.com/jonasbn/dand.git>

=back

=head1 TODO

=over

=item * Most of the work is done in the classes inheriting from this class,
there could however be work to do in the maintenance area, making this class
more informative if failing

=item * I would like to add some integration test scripts so I can see that the
package works with real data apart from the mock.

=back

=head1 SEE ALSO

=over

=item * L<http://www.dandomain.dk>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::DanDomain

You can also look for information at:

=over 4

=item * Official Wiki

L<http://logiclab.jira.com/wiki/display/DAND/Home+-+WWW-DanDomain>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-DanDomain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-DanDomain>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-DanDomain>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-DanDomain>

=back

=head1 AUTHOR

=over

=item * jonasbn, C<< <jonasbn at cpan.org> >>

=back

=head1 MOTIVATION

This module grew out of a small script using L<WWW::Mechanize> to fetch some
data from a website and changing it to satisfy the client utilizing the data.

More a more scripts where based on the original script giving a lot of redundant
code. Finally I refactored the lot to use some common code base.

After some time I refactored to an object oriented structure making it even
easier to maintain and adding more clients. This made the actual connectivity
into a package (this package) letting it loose as open source.

=head1 ACKNOWLEDGEMENTS

=over

=item * Andy Lester (petdance) the author of L<WWW::Mechanize> and
L<WWW::Mechanize:Cached>, this module makes easy things easy and hard things
possible.

=item * Iain Truskett, the author of L<WWW::Mechanize> and
L<WWW::Mechanize:Cached>

=item * Steen Schnack, who understand the power and flexibility of computer
programming and custom solutions and who gave me the assignment.

=item * Slaven Rezic, for his CPAN testers work and assistance in pointing out
an issue with release 0.03

=back

=head1 LICENSE AND COPYRIGHT

WWW-DanDomain and related modules are (C) by Jonas B. Nielsen, (jonasbn)
2009-2014

WWW-DanDomain and related modules are released under the artistic license 2.0

=cut

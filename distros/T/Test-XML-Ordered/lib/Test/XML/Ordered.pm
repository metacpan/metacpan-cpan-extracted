package Test::XML::Ordered;
$Test::XML::Ordered::VERSION = '0.2.2';
use strict;
use warnings;

use 5.010;

use XML::LibXML::Reader;

use Test::More;

use base 'Exporter';

use vars '@EXPORT_OK';

@EXPORT_OK = (qw(is_xml_ordered));

sub new
{
    my $class = shift;
    my $self  = {};

    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _got
{
    return shift->{got_reader};
}

sub _expected
{
    return shift->{expected_reader};
}

sub _init
{
    my ( $self, $args ) = @_;

    $self->{got_reader} =
        XML::LibXML::Reader->new( @{ $args->{got_params} } );
    $self->{expected_reader} =
        XML::LibXML::Reader->new( @{ $args->{expected_params} } );

    $self->{diag_message} = $args->{diag_message};

    $self->{got_end}      = 0;
    $self->{expected_end} = 0;

    return;
}

sub _got_end
{
    return shift->{got_end};
}

sub _expected_end
{
    return shift->{expected_end};
}

sub _read_got
{
    my $self = shift;

    if ( $self->_got->read() <= 0 )
    {
        $self->{got_end} = 1;
    }

    return;
}

sub _read_expected
{
    my $self = shift;

    if ( $self->_expected->read() <= 0 )
    {
        $self->{expected_end} = 1;
    }

    return;
}

sub _next_elem
{
    my $self = shift;

    $self->_read_got();
    $self->_read_expected();

    return;
}

sub _ns
{
    my $elem = shift;
    my $ns   = $elem->namespaceURI();

    return defined($ns) ? $ns : "";
}

sub _compare_loop
{
    my $self = shift;

    my $calc_prob = sub {
        my $args = shift;

        if ( !exists( $args->{param} ) )
        {
            die "No 'param' specified.";
        }
        return {
            verdict => 0,
            param   => $args->{param},
            (
                exists( $args->{got} )
                ? ( got => $args->{got}, expected => $args->{expected} )
                : ()
            ),
        };
    };

NODE_LOOP:
    while ( ( !$self->_got_end() ) && ( !$self->_expected_end() ) )
    {
        my $type     = $self->_got->nodeType();
        my $exp_type = $self->_expected->nodeType();

        if ( $type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE() )
        {
            $self->_read_got();
            redo NODE_LOOP;
        }
        elsif ( $exp_type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE() )
        {
            $self->_read_expected();
            redo NODE_LOOP;
        }
        elsif ( $type != $exp_type )
        {
            return $calc_prob->( { param => "nodeType" } );
        }
        elsif ( $type == XML_READER_TYPE_TEXT() )
        {
            my $got_text      = $self->_got->value();
            my $expected_text = $self->_expected->value();

            foreach my $t ( $got_text, $expected_text )
            {
                $t =~ s{\A\s+}{}ms;
                $t =~ s{\s+\z}{}ms;
                $t =~ s{\s+}{ }gms;
            }
            if ( $got_text ne $expected_text )
            {
                return $calc_prob->(
                    {
                        param    => "text",
                        got      => $got_text,
                        expected => $expected_text,
                    }
                );
            }
        }
        elsif ( $type == XML_READER_TYPE_ELEMENT() )
        {
            my $check = sub {
                if ( $self->_got->localName() ne $self->_expected->localName() )
                {
                    return $calc_prob->( { param => "element_name" } );
                }
                if ( _ns( $self->_got ) ne _ns( $self->_expected ) )
                {
                    return $calc_prob->( { param => "mismatch_ns" } );
                }

                my $list_attrs = sub {
                    my ($elem) = @_;

                    my @list;

                    if ( $elem->moveToFirstAttribute() )
                    {
                        my $add = sub {

                            my $ns = _ns($elem);
                            if ( $ns ne 'http://www.w3.org/2000/xmlns/' )
                            {
                                push @list,
                                    {
                                    ns        => $ns,
                                    localName => $elem->localName()
                                    };
                            }
                        };

                        $add->();
                        while ( $elem->moveToNextAttribute() > 0 )
                        {
                            $add->();
                        }
                        if ( $elem->moveToElement() <= 0 )
                        {
                            die "Cannot move back to element.";
                        }
                    }

                    foreach my $attr (@list)
                    {
                        $attr->{value} = (
                            (
                                length( $attr->{ns} )
                                ? $elem->getAttributeNs( $attr->{localName},
                                    $attr->{ns}, )
                                : $elem->getAttribute( $attr->{localName} )
                            ) // ''
                        );
                    }

                    return [
                        sort {
                                   ( $a->{ns} cmp $b->{ns} )
                                or ( $a->{localName} cmp $b->{localName} )
                        } @list
                    ];
                };

                my @got_attrs = @{ $list_attrs->( $self->_got() ) };
                my @exp_attrs = @{ $list_attrs->( $self->_expected() ) };

                while ( @got_attrs and @exp_attrs )
                {
                    my $got_a = shift(@got_attrs);
                    my $exp_a = shift(@exp_attrs);

                    if ( $got_a->{ns} ne $exp_a->{ns} )
                    {
                        return $calc_prob->(
                            {
                                param    => "attr_ns",
                                got      => $got_a->{ns},
                                expected => $exp_a->{ns},
                            }
                        );
                    }
                    if ( $got_a->{localName} ne $exp_a->{localName} )
                    {
                        return $calc_prob->(
                            {
                                param    => "attr_localName",
                                got      => $got_a->{localName},
                                expected => $exp_a->{localName},
                            }
                        );
                    }
                    if ( $got_a->{value} ne $exp_a->{value} )
                    {
                        return $calc_prob->(
                            {
                                param    => "attr_value",
                                got      => $got_a->{value},
                                expected => $exp_a->{value},
                            }
                        );
                    }
                }
                if (@got_attrs)
                {
                    return $calc_prob->(
                        {
                            param    => "extra_attr_got",
                            got      => $self->_got,
                            expected => $self->_expected,
                        }
                    );
                }
                if (@exp_attrs)
                {
                    return $calc_prob->(
                        {
                            param    => "extra_attr_expected",
                            got      => $self->_got,
                            expected => $self->_expected,
                        }
                    );
                }
                return;
            };

            if ( my $ret = $check->() )
            {
                return $ret;
            }

            my $is_got_empty      = $self->_got->isEmptyElement;
            my $is_expected_empty = $self->_expected->isEmptyElement;

            if ( $is_got_empty && ( !$is_expected_empty ) )
            {
                $self->_read_expected();
                if ( my $ret = $check->() )
                {
                    return $ret;
                }
            }
            elsif ( $is_expected_empty && ( !$is_got_empty ) )
            {
                $self->_read_got();
                if ( my $ret = $check->() )
                {
                    return $ret;
                }
            }
        }
    }
    continue
    {
        $self->_next_elem();
    }

    return { verdict => 1 };
}

sub _get_diag_message
{
    my ( $self, $status_struct ) = @_;

    if ( $status_struct->{param} eq "nodeType" )
    {
        return
              "Different Node Type!\n" . "Got: "
            . $self->_got->nodeType()
            . " at line "
            . $self->_got->lineNumber() . "\n"
            . "Expected: "
            . $self->_expected->nodeType()
            . " at line "
            . $self->_expected->lineNumber();
    }
    elsif ( $status_struct->{param} eq "text" )
    {
        return
              "Texts differ: Got <<$status_struct->{got}>> at "
            . $self->_got->lineNumber()
            . " ; Expected <<$status_struct->{expected}>> at "
            . $self->_expected->lineNumber();
    }
    elsif ( $status_struct->{param} eq "element_name" )
    {
        return
              "Got name: "
            . $self->_got->localName() . " at "
            . $self->_got->lineNumber() . " ; "
            . "Expected name: "
            . $self->_expected->localName() . " at "
            . $self->_expected->lineNumber();
    }
    elsif ( $status_struct->{param} eq "mismatch_ns" )
    {
        return
              "Got Namespace: "
            . _ns( $self->_got ) . " at "
            . $self->_got->lineNumber() . " ; "
            . "Expected Namespace: "
            . _ns( $self->_expected ) . " at "
            . $self->_expected->lineNumber();
    }
    elsif ( $status_struct->{param} eq "extra_attr_got" )
    {
        return
              "Extra attribute for got at "
            . $self->_got->lineNumber() . " ; "
            . "Expected at "
            . $self->_expected->lineNumber();
    }
    elsif ( $status_struct->{param} eq "attr_localName" )
    {
        return
              "Got Attribute localName: <<$status_struct->{got}>> at "
            . $self->_got->lineNumber() . " ; "
            . "Expected Attribute localName: <<$status_struct->{expected}>> at  "
            . $self->_expected->lineNumber();
    }
    elsif ( $status_struct->{param} eq "attr_value" )
    {
        return
              "Got Attribute value: <<$status_struct->{got}>> at "
            . $self->_got->lineNumber() . " ; "
            . "Expected Attribute value: <<$status_struct->{expected}>> at  "
            . $self->_expected->lineNumber();
    }
    else
    {
        die "Unknown param: $status_struct->{param}";
    }
}

sub compare
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;

    $self->_next_elem();

    my $status_struct = $self->_compare_loop();
    my $verdict       = $status_struct->{verdict};

    if ( !$verdict )
    {
        diag( $self->_get_diag_message($status_struct) );
    }

    return ok( $verdict, $self->{diag_message} );
}

sub is_xml_ordered
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ( $got_params, $expected_params, $args, $message ) = @_;

    my $comparator = Test::XML::Ordered->new(
        {
            got_params      => $got_params,
            expected_params => $expected_params,
            diag_message    => $message,
        }
    );

    return $comparator->compare();
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::XML::Ordered - compare two XML files for equivalency, in an ordered
fashion.

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

    use Test::More tests => 1;

    use Test::XML::Ordered qw(is_xml_ordered);

    # TEST:$c++;
    is_xml_ordered(
        [ string => $got_xml_source, ], # Got.
        [ string => $expected_xml_source, ], # Expected.
        {}, # Options
        "Equivalent", # Blurb
    );

=head1 DESCRIPTION

This module is a test module which compares two XML files for equivalence
in an ordered fashion. It was written after I (= Shlomi Fish) realised that
L<XML::SemanticDiff>, which is the basis for L<Test::XML>, and which I
maintain, compares two XML files for equivalence in a "semantic" fashion
where elements can be present in several possible orders. (It does not always
do the right thing with this respect, but even if it did, it is not normally
what I want.).

Other advantages of Test::XML::Ordered are:

=over 4

=item * Based on XML::LibXML instead of XML::Parser.

=item * Handles namespaces properly.

=back

=head1 EXPORTS

The following function is exported upon request:

=head2 is_xml_ordered($got_params, $expected_params, $args, $message)

Compares two XMLs for equivalance. $got_params and $expected_params are
array references passed to L<XML::LibXML::Reader> . $args is an hash reference
of options (currently not used but will be used in the future). $message
is the blurb.

=head1 METHODS

=head2 new

For internal use for now.

=head2 compare

For internal use for now.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Test-XML-Ordered>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-XML-Ordered>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Test-XML-Ordered>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-XML-Ordered>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-XML-Ordered>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::XML::Ordered>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-xml-ordered at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-XML-Ordered>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/test-xml-ordered>

  git clone git://github.com/shlomif/test-xml-ordered.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/test-xml-ordered/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut

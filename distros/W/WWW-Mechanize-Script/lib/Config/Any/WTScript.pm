package Config::Any::WTScript;

# ABSTRACT: Parse wtscript files.


use strict;
use warnings;

use vars qw($VERSION @extensions);

use base 'Config::Any::Base';

use Text::Balanced qw(extract_codeblock extract_delimited);
use File::Slurp qw(read_file);

use constant ST_FILE       => 0;
use constant ST_TEST_BLOCK => 1;

$VERSION = '0.100';

# horizontal space regexp
my $reHS = qr/[\t ]/;
# sequence of any chars which doesn't contain ')', space chars and '=>'
my $reWORD = qr/(?: (?: [^=)\s] | [^)\s] (?!>) )+ )/x;
# eat comments regexp
my $reCOMMENT = qr/(?: \s*? ^ \s* \# .* )+/mx;


@extensions = qw(wts wtscript);

sub extensions
{
    my ( $class, @new_ext ) = @_;
    @new_ext and @extensions = @new_ext;
    return @extensions;
}


sub load
{
    my $class    = shift;
    my $filename = shift;

    my $data = read_file($filename);

    my ( $tests, $opts ) = eval { _parse($data) };

    if ($@)
    {
        my $exc = $@;
        chomp $exc;

        my $parse_pos = pos($data) || 0;

        # find reminder of string near error (without surrounding
        # whitespace)
        $data =~ /\G $reHS* (.*?) $reHS* $/gmx;
        my $near = $1;
        if ( $near eq '' )
        {
            $near = 'at the end of line';
        }
        else
        {
            $near = "near '$near'";
        }

        # count lines
        my $line_num = () = substr( $data, 0, $parse_pos ) =~ m|$|gmx;
        pos($data) = $parse_pos;
        $line_num-- if $data =~ /\G \z/gx;

        die <<MSG;
Config::WebTest: wtscript parsing error
Line $line_num $near: $exc
MSG
    }

    my @configs;
    foreach my $test_item (@$tests)
    {
        my %test = %$test_item;
        my %cfg = (
                    request => {
                                 agent  => {},
                                 method => 'get',
                               },
                    check => { response => 200, },
                  );
        my $agent_cfg = $cfg{request}->{agent};
        # convert params
        defined( $test{user_agent} ) and $agent_cfg->{agent} = delete $test{user_agent};
        defined( $test{handle_redirects} )
          and $agent_cfg->{requests_redirectable} = delete $test{handle_redirects};
        defined( $test{proxies} ) and $agent_cfg->{proxy} = { @{ delete $test{proxies} } };
        defined( $agent_cfg->{requests_redirectable} )
          and looks_like_number( $agent_cfg->{requests_redirectable} )
          and $agent_cfg->{requests_redirectable} = [qw(GET POST)];

        $cfg{request}->{uri} = delete $test{url};
        defined $test{method} and $cfg{request}->{method} = lc delete $test{method};
        defined $test{http_headers}
          and $cfg{request}->{http_headers} = { @{ delete $test{http_headers} } };

        $cfg{check} = \%test;
        $cfg{opts}  = $opts;

        push @configs, \%cfg;
    }

    return \@configs;
}

sub _eval_in_playground
{
    my $code = shift;

    return eval <<CODE;
package Config::WebTest::PlayGround;

no strict;
local \$^W; # aka no warnings in new perls

$code
CODE
}

sub _make_sub_in_playground
{
    my $code = shift;

    return _eval_in_playground("sub { local \$^W; $code }");
}

sub _parse
{
    my $data = shift;

    my $state = ST_FILE;
    my $opts  = {};
    my $tests = [];
    my $test  = undef;

  PARSER:
    while (1)
    {
        # eat whitespace and comments
        $data =~ /\G $reCOMMENT /gcx;

        # eat whitespace
        $data =~ /\G \s+/gcx;

        if ( $state == ST_FILE )
        {
            if ( $data =~ /\G \z/gcx )
            {
                # end of file
                last PARSER;
            }
            elsif ( $data =~ /\G test_name (?=\W)/gcx )
            {
                # found new test block start
                $test  = {};
                $state = ST_TEST_BLOCK;

                # find test block name
                if ( $data =~ /\G $reHS* = $reHS* (?: \n $reHS*)?/gcx )
                {
                    $test->{test_name} = _parse_scalar($data);

                    die "Test name is missing\n"
                      unless defined $test->{test_name};
                }
            }
            else
            {
                # expect global test parameter
                my ( $name, $value ) = _parse_param($data);

                if ( defined $name )
                {
                    _set_test_param( $opts, $name, $value );
                }
                else
                {
                    die "Global test parameter or test block is expected\n";
                }
            }
        }
        elsif ( $state == ST_TEST_BLOCK )
        {
            if ( $data =~ /\G end_test (?=\W)/gcx )
            {
                push @$tests, $test;
                $state = ST_FILE;
            }
            else
            {
                # expect test parameter
                my ( $name, $value ) = _parse_param($data);

                if ( defined $name )
                {
                    _set_test_param( $test, $name, $value );
                }
                else
                {
                    die "Test parameter or end_test is expected\n";
                }
            }
        }
        else
        {
            die "Unknown state\n";
        }
    }

    return ( $tests, $opts );
}

sub _set_test_param
{
    my $href  = shift;
    my $name  = shift;
    my $value = shift;

    if ( exists $href->{$name} )
    {
        $href->{$name} = [ $href->{$name} ]
          if ref( $href->{$name} )
          and ref( $href->{$name} ) eq 'ARRAY';
        push @{ $href->{$name} }, $value;
    }
    else
    {
        $href->{$name} = $value;
    }
}

sub _parse_param
{
    my $name;

    if (
        $_[0] =~ /\G ([a-zA-Z_]+)                 # param name
                 $reHS* = $reHS* (?: \n $reHS*)? # = (and optional space chars)
                /gcx
       )
    {
        $name = $1;
    }
    else
    {
        return;
    }

    my $value = _parse_value( $_[0] );
    return unless defined $value;

    return ( $name, $value );
}

sub _parse_value
{
    if ( $_[0] =~ /\G \(/gcx )
    {
        # list elem
        #
        # ( scalar
        #   ...
        #   scalar )
        #
        # ( scalar => scalar
        #   ...
        #   scalar => scalar )

        my @list = ();

        while (1)
        {
            # eat whitespace and comments
            $_[0] =~ /\G $reCOMMENT /gcx;

            # eat whitespace
            $_[0] =~ /\G \s+/gcx;

            # exit loop on closing bracket
            last if $_[0] =~ /\G \)/gcx;

            my $value = _parse_value( $_[0] );

            die "Missing right bracket\n"
              unless defined $value;

            push @list, $value;

            if ( $_[0] =~ /\G $reHS* => $reHS* /gcx )
            {
                # handles second part of scalar => scalar syntax
                my $value = _parse_value( $_[0] );

                die "Missing right bracket\n"
                  unless defined $value;

                push @list, $value;
            }
        }

        return \@list;
    }
    else
    {
        # may return undef
        return _parse_scalar( $_[0] );
    }
}

sub _parse_scalar
{
    my $parse_pos = pos $_[0];

    if ( $_[0] =~ /\G (['"])/gcx )
    {
        my $delim = $1;

        pos( $_[0] ) = $parse_pos;
        my ($extracted) = extract_delimited( $_[0] );
        die "Can't find string terminator \"$delim\"\n"
          if $extracted eq '';

        if ( $delim eq "'" or $extracted !~ /[\$\@\%]/ )
        {
            # variable interpolation impossible - just evalute string
            # to get rid of escape chars
            my $ret = _eval_in_playground($extracted);

            chomp $@;
            die "Eval error\n$@\n" if $@;

            return $ret;
        }
        else
        {
            # variable interpolation possible - evaluate as subroutine
            # which will be used as callback
            my $ret = _make_sub_in_playground($extracted);

            chomp $@;
            die "Eval error\n$@\n" if $@;

            return $ret;
        }
    }
    elsif ( $_[0] =~ /\G \{/gcx )
    {
        pos( $_[0] ) = $parse_pos;
        my ($extracted) = extract_codeblock( $_[0] );
        die "Missing right curly bracket\n"
          if $extracted eq '';

        my $ret = _make_sub_in_playground($extracted);

        chomp $@;
        die "Eval error\n$@\n" if $@;

        return $ret;
    }
    else
    {
        $_[0] =~ /\G ((?: $reWORD $reHS+ )* $reWORD )/gcxo;
        my $extracted = $1;

        # may return undef
        return $extracted;
    }
}


1;

__END__

=pod

=head1 NAME

Config::Any::WTScript - Parse wtscript files.

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use Config::Any::WTScript;

    my $tests = Config::Any::WTScript->parse($data);

=head1 DESCRIPTION

Parses a wtscript file and converts it to a set of test objects.

=head1 METHODS

=head2 extensions(;@extensions)

When list of extensions to accept given, replace current list with given list.

Return an array of valid extensions (default: C<wts>, C<wtscript>).

=head2 load( $file )

Parses wtscript text data passed in a scalar variable C<$data>.

=head3 Returns

A list of two elements - a reference to an array that contains test
objects and a reference to a hash that contains test parameters.

=head1 ACKNOWLEDGEMENTS

The original parsing code is from L<HTTP::WebTest::Parser>, written by
Ilya Martynov.

=head1 SEE ALSO

L<HTTP::WebTest>

L<HTTP::WebTest::Parser>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script or by email
to bug-www-mechanize-script@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jens Rehsack <rehsack@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

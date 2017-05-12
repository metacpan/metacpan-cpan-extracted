package Test::WWW::Selenium::HTML;

use warnings;
use strict;

use Params::Validate qw(validate validate_pos SCALAR HASHREF);
use Test::More;
use Test::Builder;
use Time::HiRes qw(sleep);
use XML::LibXML;

# Accessors that do not take a locator as an argument.
use constant NO_LOCATOR => 
    { map { $_ => 1 }
        qw(Alert 
           AlertPresent
           AllButtons 
           AllFields
           AllLinks 
           BodyText 
           HtmlSource
           Confirmation 
           Location
           Prompt 
           Title) };

# Accessors that store single values (strings, numbers).
use constant VALUE_STORES =>
    { map { $_ => 1 }
        qw(Attribute 
           Alert
           BodyText
           Confirmation
           Cookie
           CursorPosition
           ElementWidth
           ElementHeight
           ElementIndex
           ElementPositionLeft
           ElementPositionTop
           Eval
           Expression
           HtmlSource
           Location
           Prompt
           SelectedId
           SelectedIndex
           SelectedLabel
           SelectedValue
           Table
           Text
           Title
           Value
           WhetherThisFrameMatchFrameExpression) };

# Accessors that store an array of values.
use constant ARRAY_VALUE_STORES =>
    { map { $_ => 1 } 
        qw(AllButtons
           AllFields
           AllLinks
           AllWindowIds
           AllWindowNames
           AllWindowTitles
           AttributeFromAllWindows
           LogMessages
           SelectedIds
           SelectedIndexes
           SelectedLabels
           SelectedValues
           SelectOptions) };

# Accessors that store a boolean value.
use constant BOOL_VALUE_STORES =>
    { map { $_ => 1 }
        qw(AlertPresent
           AlertNotPresent
           Checked
           NotChecked
           ConfirmationPresent
           ConfirmationNotPresent
           Editable
           NotEditable
           ElementPresent
           ElementNotPresent
           Ordered
           NotOrdered
           PromptPresent
           PromptNotPresent
           SomethingSelected
           NotSomethingSelected
           TextPresent
           TextNotPresent
           Visible
           NotVisible) };

# All accessors.
use constant STORES =>
    { map { $_ => 1 }
        keys %{VALUE_STORES()},
        keys %{ARRAY_VALUE_STORES()},
        keys %{BOOL_VALUE_STORES()} };

our $VERSION = '0.02';

sub new
{
    my $class = shift;
    my ($selenium) = validate_pos(@_, { isa => 'Test::WWW::Selenium' });

    my $test = Test::Builder->new;
    $test->exported_to(__PACKAGE__);

    my $self = { selenium                  => $selenium,
                 test_builder              => $test,
                 vars                      => {},
                 diag_body_text_on_failure => 1 };
    
    bless $self, $class;

    return $self;
}

# Takes an accessor name as its only argument. Returns a boolean
# indicating whether the accessor takes a locator argument.

sub _has_no_locator
{
    my ($accessor) = @_;

    return exists NO_LOCATOR->{$accessor};
}

# Takes an L<XML::LibXML::Node> and returns the 'literal' content. At
# the moment, that involves joining all the text parts together and
# converting C<br> elements into newlines.

sub _node_literal
{
    my $node = shift;

    my $literal = '';
    foreach my $child ($node->childNodes()) {
        my $type = $child->nodeType;

        # Does the node require special processing?
        if (    $child->nodeType == XML_ELEMENT_NODE
            and $child->nodeName =~ /^br$/i) {
            # BR elements need to be converted to newlines.
            $literal .= "\n";
        }
        else {
            # If it's not a 'special' node, just grab the text.
            $literal .= $child->textContent();
        }
    }

    return $literal;
}

# Takes the document element of an L<XML::LibXML::Document> as its
# single argument. Extracts and returns the Selenium test specifications
# from that XML as a list of arrayrefs. Each arrayref comprises the test
# command (e.g. C<storeAttribute>), the two arguments for the command
# and the line number where the test specification begins in the XML. If
# the command takes fewer than two arguments, the unused parts of the
# arrayref will contain empty strings.

sub _xml_to_testdata
{
    my ($doc) = @_;

    my $xmlns = $doc->getAttribute('xmlns');
    if (not $xmlns) {
        die "Test document must have an xmlns attribute.";
    }
    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs('x', $xmlns);
    my $trs  = $xpc->findnodes('//x:tbody//x:tr'); 
    my $trsc = $trs->size();
    if (not $trsc) {
        die "Test document contains no tests.";
    }
    
    my @data = 
        map { [ (map { _node_literal($_) }
                     ($_->nonBlankChildNodes())),
                $_->line_number() ] }
            @{$trs};

    return @data;
}

# Takes a string as its only argument. Converts it from 'camel-case' to
# 'perl-case' and returns it. For example, if passed the string
# C<verifyElementHeight>, this will return C<verify_element_height>.

sub _perl_case
{
    my ($str) = @_;
    
    $str =~ s/([a-z])([A-Z])/$1_\L$2/g;
    $str = lcfirst $str;

    return $str;
}

# Takes the variable hashref and a variable name as its arguments. If
# the name designates an array variable, returns the contents of that
# array as a single string, joined with commas. Otherwise, returns the
# scalar value of the variable.

sub _var_to_string
{
    my ($vars, $name) = @_;

    return
        (ref $vars->{$name} eq 'ARRAY')
            ? join ',', @{$vars->{$name}}
            : $vars->{$name};
}

# Takes the variable hashref and a string as its arguments. If the
# string contains variable placeholders, these are replaced with the
# corresponding values from the variable hashref. Returns the string
# after substitution has occurred.

sub _substitute_vars
{
    my ($vars, $str) = @_;

    my @varnames = 
        grep { exists $vars->{$_} } 
            ($str =~ /\${(.*?)}/g);
    
    for my $varname (@varnames) {
        my $value = _var_to_string($vars, $varname);
        $str =~ s/\${$varname}/$value/g;
    }

    if ($str =~ /^javascript{.*}/) {
        my @varnames =
            grep { exists $vars->{$_} }
                ($str =~ /storedVars\[['"](.*?)['"]\]/);
        
        for my $varname (@varnames) {
            my $value = '"'.(_var_to_string($vars, $varname)).'"';
            $str =~ s/storedVars\[['"]$varname['"]\]/$value/g;
        }
    }

    return $str;
}

# Takes the L<Test::WWW::Selenium> object as its only argument. Returns
# the timeout that should be used for operations that involve waiting.

sub _get_timeout_in_seconds
{
    my ($sel) = @_;

    # There's no other way to get the timeout from the
    # Test::WWW::Selenium object, unfortunately.

    return
        (defined $sel->{_timeout})
            ? int ($sel->{_timeout} / 1000)
            : 30;
}

# Takes a pattern as its only argument. Returns a Regexp object for
# testing values against this pattern.

sub _get_regexp_from_pattern
{
    my ($pattern) = @_;

    if ($pattern =~ s/^regexp://) {
        return qr/$pattern/;
    }
    if ($pattern =~ s/^exact://) {
        return qr/\Q$pattern\E/;
    }
    for ($pattern) {
        s/^glob://;
        s/\*/\.\*/g;
        s/\?/\./g;
    }
    return qr/$pattern/;
}

# Takes a pattern and a boolean describing the 'sense' of the test
# command as its arguments (the boolean argument should be true for a
# test like C<assertElementPresent>, and false for a test like
# C<assertElementNotPresent>). Returns a verb that can be used in a test
# case string to describe the type of match that is occurring.

sub _get_match_str_from_pattern
{
    my ($pattern, $success) = @_;

    return
        ($pattern =~ /^exact:/)
            ? ($success)
                ? 'equals'
                : 'does not equal'
            : ($success)
                ? 'matches'
                : 'does not match';
}

# Takes a command name (any string), a target, a value, a boolean
# describing whether the command has no locator argument, a boolean
# describing whether the test command is a boolean accessor and a
# boolean describing the 'sense' of the test command (see
# L<_get_match_str_from_pattern>). Returns a string that can be used as
# the description of the test case.

sub _get_test_case_str
{
    my ($pcommand, $target, $value, $has_no_locator, $is_bool, $success) = @_;

    my $str = "$pcommand " .(($has_no_locator) ? '' : "'$target'");

    if ($is_bool) {
        return $str;
    }
 
    $value = ($has_no_locator ? $target : $value);
    my $match_str = _get_match_str_from_pattern($value, $success);
 
    return "$str $match_str '$value'";
}
 
# Takes an accessor type (the prefix of the accessor, e.g. C<store>), an
# accessor name (including the type), a target (first test argument), a
# value (second test argument), the filename of the Selenium HTML test
# file, the line number of the test, a L<Test::WWW::Selenium> object, a
# L<Test::Builder> object and a variable hashref as its arguments. Runs
# the accessor test using the L<Test::Builder> and returns a boolean
# describing whether the test succeeded. Updates the variable hashref if
# necessary, as well.

sub _handle_accessor
{
    my ($type, $command, $target, $value, $slnm_file, $line_number, 
        $sel, $tb, $vars, $diag) = @_;

    my ($part)           = ($command =~ /^$type(.*)/);
    my ($part_minus_not) = ($part =~ /Not([A-Z].*)/);
    
    if (not exists STORES->{$part} 
            and (not defined $part_minus_not 
                    or not exists STORES->{$part_minus_not})) {
        die "Invalid accessor '$part' at line $line_number.";
    }

    my $is_bool  = exists BOOL_VALUE_STORES->{$part};
    my $is_array = exists ARRAY_VALUE_STORES->{$part};

    my $not = $part =~ s/Not([A-Z])/$1/;
    my $has_no_locator = _has_no_locator($part);
    my $pcmd = _perl_case($part);
    my $get_pcmd = 'get_'.$pcmd;
    my $is_pcmd  = 'is_'.$pcmd;
    my $pcommand = _perl_case($command);

    $value = ($has_no_locator ? $target : $value);
    my @get_args = ($has_no_locator ? () : $target);
    my $regexp = _get_regexp_from_pattern($value);

    my (undef, $test_file, $test_line_number) = $tb->caller(1);

    my $test_case_str = 
        _get_test_case_str($pcommand, $target, $value,
                           $has_no_locator, $is_bool, not $not).
            " ($slnm_file:$line_number; ".
              "$test_file:$test_line_number)";

    if ($type eq 'waitFor') {
        my $timeout = _get_timeout_in_seconds($sel);

        my $test_coderef =
            ($is_bool)
                ? sub { my $res = $sel->$is_pcmd($target);
                        ($not) ? not $res : $res }
                : sub { my $new_value = $sel->$get_pcmd(@get_args);
                        my $res = ($new_value =~ $regexp);
                        ($not) ? not $res : $res };

        WAIT: {
            for (1..$timeout + 1) {
                if (eval { $test_coderef->() }) {
                    pass($test_case_str); 
                    last WAIT;
                }
                sleep(1);
            }
            $tb->ok(0, "$test_case_str ".
                       "(timed out, see line $line_number)");
            if ($diag) {
                my $html = "Response HTML source:\n".$sel->get_html_source();
                $tb->diag($html);
            }
            return 0;
        }
        return 1;
    }
        
    my @check_values = 
        ($is_bool)
            ? $sel->$is_pcmd($target)
            : $sel->$get_pcmd(@get_args);

    my $check_value = join ',', @check_values;

    if ($type eq 'store') {
        $vars->{$value} = 
            ($is_array) 
                ? \@check_values 
                : $check_value;
        return 1;
    }

    my $res;
    if ($is_bool) {
        $res =
            ($not)
                ? $tb->ok((not $check_value), $test_case_str)
                : $tb->ok(($check_value),     $test_case_str);
    } else {
        $res =
            ($not)
                ? $tb->unlike($check_value, $regexp, $test_case_str)
                : $tb->like(  $check_value, $regexp, $test_case_str);
    }
       
    if (not $res) {
        if ($diag) {
            my $html = "Response HTML source:\n".$sel->get_html_source();
            $tb->diag($html);
        }
        if ($type eq 'assert') {
            return 0;
        }
    }
    return 1;
}

# Takes a L<Test::WWW::Selenium> object, a L<Test::Builder> object, a
# hashref of variables, the filename of the Selenium HTML test file and
# a test specification (as per L<_xml_to_testdata>) as its arguments.
# Runs the test and returns a boolean indicating whether the test was
# successful.
 
sub _run_test
{
    my ($sel, $tb, $vars, $slnm_file, $test, $diag) = @_;

    my ($command, $target, $value, $line_number) = @{$test};

    $target = _substitute_vars($vars, $target);
    $value  = _substitute_vars($vars, $value);

    my @accessor_args = ($command, $target, $value, 
                         $slnm_file, $line_number, 
                         $sel, $tb, $vars, $diag);

    my (undef, $test_file, $test_line_number) = $tb->caller();

    if ($command eq 'store') {
        my $script;
        $vars->{$value} = 
            (($script) = ($target =~ /^javascript{(.*)}$/))
                ? $sel->get_eval($script)
                : $target;
        return 1;
    }
    if ($command eq 'echo') {
        print $target."\n";
        return 1;
    }
    if ($command eq 'waitForCondition') {
        my ($script, $timeout) = ($target, $value);
        if (not $timeout) {
            $timeout = _get_timeout_in_seconds($sel) * 1000;
        }
        my $test_str = "waitForCondition($target, $value) ".
                       "($slnm_file:$line_number; ".
                       "$test_file:$test_line_number)";
        my $res = eval { $sel->wait_for_condition($script, $timeout) };
        my $error = $@;
        $tb->ok($res, $test_str);
        if ($error) {
            $tb->diag($error);
        }
        return $res;
    }
    if ($command eq 'waitForPageToLoad') {
        my $timeout = $target;
        if (not $timeout) {
            $timeout = _get_timeout_in_seconds($sel) * 1000;
        }
        my $test_str = "waitForPageToLoad($target, $value) ".
                       "($slnm_file:$line_number; ".
                       "$test_file:$test_line_number)";
        my $res = eval { $sel->wait_for_page_to_load($timeout) };
        my $error = $@;
        $tb->ok($res, $test_str);
        if ($error) {
            $tb->diag($error);
        }
        return $res;
    }
    if (my ($type) = ($command =~ /(^assert|^verify|^waitFor|^store)/)) {
        return _handle_accessor($type, @accessor_args);
    }
    
    # Convert the command to 'perl-case' and append '_ok' (this will
    # be the corresponding method name, assuming that it exists).  If
    # the command ends in 'AndWait', call C<wait_for_page_to_load>
    # afterwards. Note that C<can> cannot be used, because
    # L<Test::WWW::Selenium> uses autoload.
    
    my $pcmd = _perl_case($command);
    my $wait = ($pcmd =~ s/_and_wait$//);
    $pcmd .= '_ok';

    my $res = eval { 
        my (@args) = grep { defined $_ } ($target, $value);
        # Including the command in the test description means that
        # information is repeated for successful cases, but is
        # necessary because the command is not included in the failure
        # message (if the test fails).
        my $test_desc = "$command(".(join ', ', @args).") ".
                        "($slnm_file:$line_number; ".
                        "$test_file:$test_line_number)";
        my $res = $sel->$pcmd(@args, $test_desc);
        if ($res and $wait) {
            my $timeout = _get_timeout_in_seconds($sel) * 1000;
            $sel->wait_for_page_to_load($timeout);
        }
        $res;
    };
    if (my $error = $@) {
        my $str =
            join ', ',
            map  { "'$_'" }
            grep { $_     }
                (@{$test})[0..2];
        my $die_msg =
            ($error =~ /Undefined subroutine|Can't locate.*method/)
                ? "Unhandled command at $slnm_file:$line_number: [$str]"
                : "Died while running test: $error: [$str]";
        die $die_msg;
    }
    if (not $res) {
        if ($diag) {
            my $html = "Response HTML source:\n".$sel->get_html_source();
            $tb->diag($html);
        }
        return 0;
    }

    return 1;
}

sub run
{
    my $self = shift;

    my %args = validate(@_,
        { data => { type => SCALAR,  optional => 1 },
          path => { type => SCALAR,  optional => 1 }, }
    );

    if (not $args{'data'} and not $args{'path'}) {
        die "Either 'data' or 'path' must be provided.";
    }
    if ($args{'data'} and $args{'path'}) {
        die "One (and only one) of 'data' and 'path' must be provided.";
    }

    my $parser = XML::LibXML->new();
    $parser->load_ext_dtd(0);
    $parser->line_numbers(1);
    
    if ($args{'path'}) {
        open my $fh, '<', $args{'path'}
            or die "Unable to open ".$args{'path'}.": $!";
        $args{'data'} = do { local $/; <$fh> };
        close $fh;
    }

    my $filename = $args{'path'} ? $args{'path'} : '[no filename]';
    
    my $doc = $parser->parse_string($args{'data'});
    my @testdata = _xml_to_testdata($doc->getDocumentElement());
    
    my $sel = $self->{'selenium'};
    if (not $self->{'opened'}) {
        $self->{'opened'} = 1;
        $sel->open('/');
    }

    for my $test (@testdata) {
        my $res = _run_test($sel, $self->{'test_builder'}, 
                            $self->{'vars'}, $filename, $test,
                            $self->diag_body_text_on_failure());
        if (not $res) {
            return;
        }
    }

    return 1;
}

sub vars
{
    my ($self) = @_;

    return $self->{'vars'};
}

sub diag_body_text_on_failure
{
    my ($self, $value) = @_;

    my $current_value = $self->{'diag_body_text_on_failure'};

    if (@_ == 2) {
        $self->{'diag_body_text_on_failure'} = $value;
    }

    return $current_value;
}

1;

__END__

=head1 NAME

Test::WWW::Selenium::HTML - Run Selenium HTML tests directly

=head1 VERSION

0.02

=head1 SYNOPSIS

Provides for running Selenium HTML tests against a
L<Test::WWW::Selenium> object and producing TAP output:

    my $sel =
        Test::WWW::Selenium->new(
            host        => "localhost",
            port        => 4444,
            browser     => "*firefox",
            browser_url => "http://localhost:$port/"
        );
    my $selh = Test::WWW::Selenium::HTML->new($sel);
    $selh->run(path => "./path/to/selenium/file.html");

L<run> will print TAP output as it progresses through the specified
tests. L<run> may be called multiple times, and other tests may occur
before and after calls to L<run>. For example, given a Selenium HTML
file like so:

    ...
    <tr>
        <td>open</td>
        <td>test.html</td>
        <td></td>
    </tr>
    <tr>
        <td>click</td>
        <td>id=button</td>
        <td></td>
    </tr>
    ...

and a test file (test.t) like so:

    ...
    ok(1, "Some test");
    $selh->run(path => "./path/to/selenium/file.html");
    ok(1, "Some other test");
    $selh->run(path => "./path/to/selenium/file.html");
    ok(1, "Yet another test");
    ...

the output will be:

    ok 1 - Some test
    ok 2 - open(test.html, ) (./path/to/selenium/file.html:14; t/test.t:9)
    ok 3 - click(id=button, ) (./path/to/selenium/file.html:19; t/test.t:9)
    ok 4 - Some other test
    ok 5 - open(test.html, ) (./path/to/selenium/file.html:14; t/test.t:11)
    ok 6 - click(id=button, ) (./path/to/selenium/file.html:19; t/test.t:11)
    ok 7 - Yet another test

The Selenium HTML file/string provided to L<run> must be valid XML.
This will not normally be a problem, because the HTML produced by the
Selenium IDE (via the 'Save Test Case' option) satisfies this
requirement.

=head1 CONSTRUCTOR

=over 4

=item B<new>

Takes an instance of L<Test::WWW::Selenium> as its only argument.

=cut

=back

=head1 PUBLIC METHODS

=over 4

=item B<run>

Takes a hash of arguments:

=over 8

=item data

A Selenium HTML document as a string.

=item path

A path to a Selenium HTML document.

=back

Either C<data> or C<path> must be provided. The relevant Selenium HTML
document in both cases must contain Selenium test specifications (the
argument here will generally be the result of exporting in HTML format
from the Selenium IDE). Runs the test specifications and returns a
boolean indicating whether all of the tests were completed
successfully.

=cut

=item B<vars>

Returns the current internal variable state as a hashref.
Modifications to this hashref will be reflected in the object, so it
can be prepopulated (after calling L<new> but before calling L<run>)
with variables needed by the tests. Any C<store> test specifications
in the tests proper will cause this hashref to be updated as per the
specification.

=cut

=item B<diag_body_text_on_failure>

Controls whether L<run_test> will display the body text on test
failure. If passed a true value, this feature is enabled, and vice
versa; in both cases, the previous value of this switch is returned.
If no argument is passed, returns the value of the switch. Defaults to
true.

=cut

=back

=head1 NOTES

Tested against Selenium IDE 1.0.12 and Selenium Servers 2.0rc2, 2.8.0,
2.12.0 and 2.19.0.

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-www-selenium-html at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WWW-Selenium-HTML>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::WWW::Selenium::HTML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-WWW-Selenium-HTML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-WWW-Selenium-HTML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-WWW-Selenium-HTML>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-WWW-Selenium-HTML/>

=back

=head1 AUTHOR

 Tom Harrison
 APNIC Software, C<< <cpan at apnic.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 APNIC Pty Ltd.

This library is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The full text of the license can be found in the LICENSE file included
with this module.
 
=cut

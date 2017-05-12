package Test::HTML::W3C;

use strict;
use vars qw($VERSION @EXPORT);
$VERSION = "0.04"; 

=head1 NAME

Test::HTML::W3C - Perform W3C HTML validation testing

=head1 SYNOPSIS

  use Test::HTML::W3C tests => $test_count;
  # or
  use Test::HTML::W3C 'show_detail';
  # or when using both
  use Test::HTML::W3C tests => $test_count, 'show_detail';

  is_valid_markup($my_html_scalar);

  is_valid_file("/path/to/my/file.html");

  is_valid("http://example.com");

  # Get the underlying WebService:;Validator::W3C::HTML object
  my $validator = validator();

=head1 DESCRIPTION

The purpose of this module is to provide a wrapper around the W3C
that works with the L<Test::More> testing framework.

=head1 ABUSE

Please keep in mind that the W3C validation pages and services are
a shared resource. If you plan to do many many tests, please consider
using your own installation of the validation programs, and then use
your local install by modifying the local validtor:

  my $v = validator();
  $v->validator_uri($my_own_validator);

See the documentation for WebService:;Validator::W3C::HTML and the W3C's
site at http://validator.w3.org/ for details

=over 4

=cut

use WebService::Validator::HTML::W3C;
use base qw(Test::Builder::Module);
@EXPORT = qw(
             plan
             diag_html
             is_valid_markup
             is_valid_file
             is_valid
             validator
            );

my $v = WebService::Validator::HTML::W3C->new();
my $not_checked = 1;
my $show_detail = 0;

sub import_extra {
    my ($class, $list) = @_;
    my @other = ();
    my $idx = 0;
    while( $idx <= $#{$list} ) {
        my $item = $list->[$idx];

        if( defined $item and $item eq 'show_detail' ) {
            $show_detail = 1;
            $v = WebService::Validator::HTML::W3C->new(detailed => 1);
        } else {
            push @other, $item;
        }
        $idx++;
    }
    @$list = @other;
}

=item validator();

B<Description:> Returns the underlying WebService::Validator::HTML::W3C object

B<Parameters:> None.

B<Returns:> $validator

=cut

sub validator {
    return $v;
}


=item plan();

B<Description:> Access to the underlying C<plan> method provided by
L<Test::Builder>.

B<Parameters:> As per L<Test::Builder>

=cut

sub plan {
    __PACKAGE__->builder->plan(@_);
}

sub _check_plan {
    $not_checked = 0;
    if (! __PACKAGE__->builder->has_plan()) {
        plan("no_plan");
    }
}

=item is_valid_markup($markup[, $name]);

B<Description:> is_valid_markup tests whether the text in the provided scalar
value correctly validates according to the W3C specifications. This is useful
if you have markup stored in a scalar that you wish to test that  you might get
from using LWP or WWW::Mechanize for example...

B<Parameters:> $markup, a scalar containing the data to test, $name, an
optional descriptive test name.

B<Returns:> None.

=cut

sub is_valid_markup {
    _check_plan() if $not_checked;
    my ($markup, $message) = @_;
    if ($v->validate_markup($markup)) {
        _result($v, $message);
    } else {
        _validator_err($v, "markup");
    }
}

=item is_valid_file($path[, $name]);

B<Description:> is_valid_file works the same way as is_valid_markup, except that
you can specify the text to validate with the path to a filename. This is useful
if you have pregenerated all your HTML files locally, and now wish to test them.

B<Parameters:> $path, a scalar, $name, an optional descriptive test name.

B<Returns:> None.

=cut

sub is_valid_file {
    my ($file, $message) = @_;
    _check_plan() if $not_checked;
    if ($v->validate_file($file)) {
        _result($v, $message);
    } else {
        _validator_err($v, "file");
    }
}


=item is_valid($url[, $name]);

B<Description:> is_valid, again, works very similarly to the is_valid_file and
is_valid_file, except you specify a document that is already online with its
URL. This can be useful if you wish to periodically test a website or webpage
that dynamically changes over time for example, like a blog or a wiki, without
first saving the html to a file using your browswer, or a utility such as wget.

B<Parameters:> $url, a scalar, $name, an optional descriptive test name.

B<Returns:> None.

=cut

sub is_valid {
    my ($uri, $message) = @_;
    _check_plan() if $not_checked;
    if ($v->validate($uri)) {
       _result($v, $message);
    } else {
        _validator_err($v, "URI");
    }
}

sub _validator_err {
    my ($validator, $type) = @_;
    __PACKAGE__->builder->ok(0, "Failed to validate $type.");
    __PACKAGE__->builder->diag($v->validator_error());
}

sub _result {
    my ($validator, $message) = @_;
    if ($validator->is_valid()) {
        __PACKAGE__->builder->ok(1, $message);
    } else {
        my $num = $validator->num_errors();
        my $plurality = ($num == 1) ? "error" : "errors";
        __PACKAGE__->builder->ok(0, $message . " ($num $plurality).");
    }
}


=item diag_html($url);

B<Description:> If you want to display the actual errors reported by
the service for a particular test, you can use the diag_html function.
Please note that you must have imported 'show_detail' for this to
work properly.

  use Test::HTML::W3C 'show_detail';

  is_valid_markup("<html></html">, "My simple test") or diag_html();

B<Parameters:> $url, a scalar.

B<Returns:> None.

=cut

sub diag_html {
    my $tb = __PACKAGE__->builder();
    if ($show_detail) {
        my @errs = $v->errors();
        my $e;
        foreach my $error ( @{$v->errors()} ) {
             $e .= sprintf("%s at line %d\n", $error->msg, $error->line);
        }
        $tb->diag($e);
    } else {
        $tb->diag("You need to import 'show_detail' in order to call diag_html\n");
    }
}


1;

__END__

=back

=head1 SEE ALSO

L<Test::Builder::Module> for creating your own testing modules.

L<Test::More> for another popular testing framework, also based on
Test::Builder

L<Test::Harness> for detils about how test results are interpreted.

=head1 AUTHORS

Victor E<lt>victor73@gmail.comE<gt> with inspiration
from the authors of the Test::More and WebService::Validator::W3C:HTML
modules.

=head1 BUGS

See F<http://rt.cpan.org> to report and view bugs.

=head1 COPYRIGHT

Copyright 2006 by Victor E<lt>victor73@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

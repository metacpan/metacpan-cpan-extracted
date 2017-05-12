package XTaTIK::Docs::Appendix::SASSVariables;

use strict;
use warnings;

our $VERSION = '0.005002'; # VERSION

1;
__END__

=encoding utf8

=head1 NAME

XTaTIK::Docs::Appendix::SASSVariables - List of XTaTIK SASS Variables

=head1 BOOTSTRAP

XTaTIK uses Bootstrap3, so you can override any of
L<its variables|https://github.com/twbs/bootstrap-sass/blob/master/assets/stylesheets/bootstrap/_variables.scss>
in your Company and Site vars files.

=head1 XTaTIK VARIABLES

XTaTIK also defines some of its own SASS variables:

    $xtatik-primary1: #FF6600 !default;
    $xtatik-primary2: #000 !default;
    $xtatik-light-on-dark-text: #fff !default;
    $xtatik-lighter-border-color: #eee !default;

    $xtatik-productnumber-text-color: #999 !default;

    $xtatik-footer-text-color:  $navbar-inverse-link-color !default;
    $xtatik-footer-contacts-bg: $navbar-inverse-link-active-bg !default;
    $xtatik-footer-link-color:  $navbar-inverse-link-color !default;
    $xtatik-footer-bg:          $navbar-inverse-bg !default;

    $xtatik-feeback-button-bg:  $navbar-inverse-bg !default;
    $xtatik-feeback-button-link-color:
                                $navbar-inverse-link-color !default;
    $xtatik-feeback-button-link-hover-color:
                                $navbar-inverse-link-hover-color !default;
    $xtatik-feeback-button-link-active-color:
                                $navbar-inverse-link-active-color !default;
    $xtatik-feeback-button-border-color:
                                $navbar-inverse-toggle-border-color !default;

=head2 C<$xtatik-primary1>

    $xtatik-primary1: #FF6600 !default;

Specifies primary theme colour. Defaults to C<#FF6600>.

=head2 C<$xtatik-primary2>

    $xtatik-primary2: #000 !default;

Specifies secondary theme colour. Defaults to C<#000>.

=head2 C<$xtatik-light-on-dark-text>

    $xtatik-light-on-dark-text: #fff !default;

Specifies light-on-dark text colour. Defaults to C<#fff>.
B<Note: this variable might be removed in future releases.>

=head2 C<$xtatik-lighter-border-color>

    $xtatik-lighter-border-color: #eee !default;

Specifies light border colour. Defaults to C<#eee>.
B<Note: this variable might be removed in future releases.>

=head2 C<$xtatik-productnumber-text-color>

    $xtatik-productnumber-text-color: #999 !default;

Colour for product numbers. Defaults to C<#999>

=head2 FOOTER

=head3 C<$xtatik-footer-text-color>

    $xtatik-footer-text-color:  $navbar-inverse-link-color !default;

Colour for footer text. Defaults to
    Bootstrap's C<$navbar-inverse-link-color>

=head3 C<$xtatik-footer-contacts-bg>

    $xtatik-footer-contacts-bg: $navbar-inverse-link-active-bg !default;

Colour for background of contacts footer portion. Defaults to
    Bootstrap's C<$navbar-inverse-link-active-bg>

=head3 C<$xtatik-footer-link-color>

    $xtatik-footer-link-color:  $navbar-inverse-link-color !default;

Colour for footer links. Defaults to
    Bootstrap's C<$navbar-inverse-link-color >

=head3 C<$xtatik-footer-bg>

    $xtatik-footer-bg: $navbar-inverse-bg !default;

Colour for footer's background. Defaults to
    Bootstrap's C<$navbar-inverse-bg>

=head2 FEEDBACK BUTTON

=head3 C<$xtatik-feeback-button-bg>

    $xtatik-feeback-button-bg: $navbar-inverse-bg !default;

Colour for the feedback button's background. Defaults to
    Bootstrap's C<$navbar-inverse-bg>

=head3 C<$xtatik-feeback-button-link-color>

    $xtatik-feeback-button-link-color:
                            $navbar-inverse-link-color !default;

Colour for the feedback button's link colour. Defaults to
    Bootstrap's C<$navbar-inverse-link-color>

=head3 C<$xtatik-feeback-button-link-hover-color>

    $xtatik-feeback-button-link-hover-color:
                            $navbar-inverse-link-hover-color !default;

Colour for the feedback button's link in hover state colour. Defaults to
    Bootstrap's C<$navbar-inverse-link-hover-color>

=head3 C<$xtatik-feeback-button-link-active-color>

    $xtatik-feeback-button-link-active-color:
                            $navbar-inverse-link-active-color !default;

Colour for the feedback button's link in active state colour. Defaults to
    Bootstrap's C<$navbar-inverse-link-active-color>

=head3 C<$xtatik-feeback-button-border-color>

    $xtatik-feeback-button-border-color:
                            $navbar-inverse-toggle-border-color !default;

Colour for the feedback button's border colour. Defaults to
    Bootstrap's C<$navbar-inverse-toggle-border-color>

=cut
package Web::PerlDistSite::Component::MainScss;

our $VERSION = '0.001011';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

with 'Web::PerlDistSite::Component';

sub filename ( $self ) {
	return '_build/main.scss';
}

sub raw_content ( $self ) {
	state $content = do { local $/ = <DATA> };
	if ( $self->project->root->child( 'custom.scss' )->is_file ) {
		return $content . qq{\n\@import "../custom";\n\n}
	}
	return $content;
}

1;

__DATA__
// 1. Include functions first (so you can manipulate colors, SVGs, calc, etc)
@import "../node_modules/bootstrap/scss/functions";

// 2. Include any default variable overrides here
@import "variables";

// 3. Include remainder of required Bootstrap stylesheets (including any separate color mode stylesheets)
@import "../node_modules/bootstrap/scss/variables";

// 4. Include any default map overrides here

// 5. Include remainder of required parts
@import "../node_modules/bootstrap/scss/maps";
@import "../node_modules/bootstrap/scss/mixins";
@import "../node_modules/bootstrap/scss/root";
@import "../node_modules/bootstrap/scss/utilities";

$sizes: (
	25: 25%,
	50: 50%,
	75: 75%,
	100: 100%,
	60px: 60px,
	80px: 80px,
	100px: 100px,
	auto: auto
);

@each $breakpoint in map-keys($grid-breakpoints) {
	@include media-breakpoint-up($breakpoint) {
		$infix: breakpoint-infix($breakpoint, $grid-breakpoints);
		@each $prop, $abbrev in (width: w, height: h) {
			@each $size, $length in $sizes {
				.#{$abbrev}#{$infix}-#{$size} { #{$prop}: $length !important; }
			}
		}
	}
}

// 6. Optionally include any other parts as needed
@import "../node_modules/bootstrap/scss/reboot";
@import "../node_modules/bootstrap/scss/type";
@import "../node_modules/bootstrap/scss/images";
@import "../node_modules/bootstrap/scss/containers";
@import "../node_modules/bootstrap/scss/grid";
@import "../node_modules/bootstrap/scss/helpers";
@import "../node_modules/bootstrap/scss/tables";
@import "../node_modules/bootstrap/scss/forms";
@import "../node_modules/bootstrap/scss/buttons";
@import "../node_modules/bootstrap/scss/transitions";
@import "../node_modules/bootstrap/scss/dropdown";
@import "../node_modules/bootstrap/scss/button-group";
@import "../node_modules/bootstrap/scss/nav";
@import "../node_modules/bootstrap/scss/navbar";
@import "../node_modules/bootstrap/scss/card";
@import "../node_modules/bootstrap/scss/accordion";
@import "../node_modules/bootstrap/scss/breadcrumb";
@import "../node_modules/bootstrap/scss/pagination";
@import "../node_modules/bootstrap/scss/badge";
@import "../node_modules/bootstrap/scss/alert";
@import "../node_modules/bootstrap/scss/progress";
@import "../node_modules/bootstrap/scss/list-group";
@import "../node_modules/bootstrap/scss/close";
@import "../node_modules/bootstrap/scss/toasts";
@import "../node_modules/bootstrap/scss/modal";
@import "../node_modules/bootstrap/scss/tooltip";
@import "../node_modules/bootstrap/scss/popover";
@import "../node_modules/bootstrap/scss/carousel";
@import "../node_modules/bootstrap/scss/spinners";
@import "../node_modules/bootstrap/scss/offcanvas";
@import "../node_modules/bootstrap/scss/placeholders";

// 7. Optionally include utilities API last to generate classes based on the Sass map in `_utilities.scss`
@import "../node_modules/bootstrap/scss/utilities/api";

// 8. Add additional custom code here
@import "layout";

package Web::PerlDistSite::Component::LayoutScss;

our $VERSION = '0.001010';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

with 'Web::PerlDistSite::Component';

sub filename ( $self ) {
	return '_build/layout.scss';
}

sub raw_content ( $self ) {
	state $content = do { local $/ = <DATA> };
	return $content;
}

1;

__DATA__

body {
	@extend .d-flex;
	@extend .flex-column;
	@extend .min-vh-100;
	
	&.at-top header {
		box-shadow: none;
	}
	&.is-scrolled header {
		box-shadow: 0px 0px 12px 0px $dark;
	}
}

header {
	@extend .sticky-top;
	@extend .bg-primary;
	@extend .text-light;
	
	transition: box-shadow 1s ease-in-out;
	
	.nav-link, .navbar-brand {
		@extend .text-light;
		@include border-radius($btn-border-radius);
	}
	.nav-link:hover {
		background: darken($primary, 5%);
	}
	.dropdown-menu {
		@extend .bg-secondary;
		@extend .text-light;
		.dropdown-item {
			@extend .text-light;
		}
		.dropdown-item:hover {
			background: darken($secondary, 5%);
		}
	}
}

#main {
	height: 1px;
	width: 1px;
}

.homepage-hero {
	@extend .bg-primary;
	position: relative;
	
	&.homepage-hero-dark, &.homepage-hero-banner {
		@extend .bg-dark;
	}
	
	.homepage-hero-text {
		position: absolute;
		top: 20vh;
		width: 100%;
		
		div {
			@extend .container;
			@extend .text-white;
			@extend .text-center;
		}
		
		h1 {
			@extend .display-1;
			@extend .fw-bold;
		}
		
		h2 {
			@extend .display-6;
			@extend .fw-bold;
			@extend .pt-4;
		}
	}
	
	.homepage-hero-graphic {
		width: 100%;
		height: 95vh;
		height: calc(100vh - 56px);
		height: calc(100dvh - 56px);
	}
}

.homepage-hero-button {
	@extend .text-white;
	@extend .text-center;
	position: absolute;
	bottom: 18vh;
	width: 100%;
	font-size: 2rem;
	
	opacity: 1;
	pointer-events: auto;
	transition: opacity 0.6s ease-in-out;
	
	a:link, a:visited {
		@extend .text-white;
		text-decoration: underline;
		position: relative;
		i {
			position: absolute;
			top: 0;
			left: -0.67rem;
			animation: bounce 1.2s infinite alternate;
		}
	}
}

body.is-scrolled .homepage-hero-button {
	opacity: 0;
	pointer-events: none;
}

@keyframes bounce {
	to { transform: scale(1.2); }
}

.homepage-hero-banner {
	width: 100%;
	height: 95vh;
	height: calc(100vh - 56px);
	.homepage-hero-text, .homepage-hero-button {
		text-shadow: 0px 0px 6px $dark;
		opacity: 0.9;
	}
}

body.page main {
	@extend .my-4;
}

.heading-wrapper {
	.heading {
		@extend .container;
		@extend .py-3;
		h1 {
			@extend .display-2;
		}
	}
}

main {
	.has-sections {
		& > section {
			@extend .py-5;
		}
		& > section:nth-child(even) {
			@extend .bg-light;
			@extend .text-dark;
			&:last-child {
				@extend .bg-white;
				@extend .text-dark;
				@extend .border-top;
			}
		}
	}
	
	pre code {
		@include border-radius($card-border-radius);
		display: block;
		padding: calc($spacer / 2);
		background: lighten($light, 5%) !important;
		border: 1px solid $light;
	}
}

footer {
	@extend .py-3;
	@extend .mt-auto;
	@extend .bg-dark;
	@extend .text-light;
	a:link, a:visited {
		@extend .text-light;
	}
}

#return-to-top {
	@extend .text-secondary;
	font-size: 2rem;
	text-decoration: none;

	opacity: 0;
	pointer-events: none;
	transition: opacity 0.6s ease-in-out;

	position: fixed;
	bottom: 2rem;
	right: 3rem;
	
	i {
		animation: bounce 1.2s infinite alternate;
	}
}

body.is-scrolled-deeply #return-to-top {
	opacity: 0.75;
	pointer-events: auto;
	&:hover {
		opacity: 1;
	}
}
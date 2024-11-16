# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

requires 'perl', '5.36.0';

on 'configure' => sub {
  requires 'perl', '5.36.0';
  requires 'ExtUtils::MakeMaker::CPANfile', '0.0.9';
};

on 'test' => sub {
  requires 'Test::CPANfile';
  requires 'Test::More';
  requires 'Test2::V0';
  requires 'Readonly';
  recommends 'Test::Pod', '1.22';
  recommends 'CPAN::Common::Index::Mux::Ordered';
  suggests 'IPC::Run3';  # Only used for spell-checking which is not included in the distribution
  suggests 'Test2::Tools::PerlCritic';
  suggests 'Perl::Tidy', '20220613';
};

# Develop phase dependencies are usually not installed, this is what we want as
# Devel::Cover has many dependencies.
on 'develop' => sub {
  recommends 'Devel::Cover';
  suggests 'CPAN::Uploader';
  suggests 'PAR::Packer';
  suggests 'Dist::Setup';
};

# End of the template. You can add custom content below this line.

requires 'Moo';
requires 'Readonly';
requires 'namespace::clean';

feature 'LwpUserAgent', 'Support for LWP::UserAgent' => sub {
  requires 'LWP::UserAgent';
  requires 'LWP::Protocol::https';
  requires 'HTTP::Response';
};

feature 'AnyEventUserAgent', 'Support for AnyEvent::UserAgent' => sub {
  requires 'AnyEvent';
  requires 'AnyEvent::UserAgent', '0.09';
  requires 'HTTP::Response';
  requires 'Promise::XS';
};

feature 'HttpPromise', 'Support for HTTP::Promise' => sub {
  requires 'HTTP::Promise';
  requires 'Promise::Me';
};

feature 'MojoUserAgent', 'Support for Moje::UserAgent' => sub {
  requires 'Mojo::UserAgent';
};

on 'test' => sub {
  requires 'AnyEvent';
  requires 'Test::HTTP::MockServer';  #, '0.0.2';  # not yet released.
  requires 'Promise::XS';
}

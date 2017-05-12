package Tiffany::Template::Declare;
use strict;
use warnings;
use Template::Declare;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    # T::D throws exception when strict => 1.
    # This is required for Tiffany spec.
    Template::Declare->init( strict => 1, %$args );
    bless { }, $class;
}

sub render {
    my ($self, @args) = @_;
    Template::Declare->show(@args);
}

1;
__END__

=head1 NAME

Tiffany::Template::Declare - Tiffany gateway for Template::Declare

=head1 SYNOPSIS

    use Tiffany;

    {
        package MyPage;
        use Template::Declare::Tags;    # defaults to 'HTML'
        use base 'Template::Declare';

        template simple => sub {
            my ( $class, $name ) = @_;
            html {
                head {} body {
                    p { "Hello, $name." };
                }
            }
        };
    }

    my $tmpl = Tiffany->load('Template::Declare', {dispatch_to => ['MyPage']});
    like $tmpl->render('simple', 'john'), qr/Hello, john./;

=head1 AUTHOR

Tokuhiro Matsuno


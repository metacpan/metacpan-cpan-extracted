package HTML::HTPL;

BEGIN{
    $VERSION = q!3.14!;
}

sub import {
    EVAL <<'EOV';
    require HTML::HTPL::Lib;
    require HTML::HTPL::Sys;
    import HTML::HTPL::Sys;
    import HTML::HTPL::Lib;
EOV
}


1;
__END__
=head1 Soon
Documentaiton soon

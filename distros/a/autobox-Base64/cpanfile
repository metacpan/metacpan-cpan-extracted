requires "MIME::Base64" => "0";
requires "autobox" => "0";
requires "parent" => "0";
requires "perl" => "v5.10.0";
requires "strict" => "0";
requires "utf8" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Find" => "0";
  requires "File::Temp" => "0";
  requires "Test::More" => "0.88";
  requires "constant" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};

my $app = sub {
  my $env = shift;
  return ['200', ['Content-Type' => 'text/html'], [<<'  HTML'] ];
    <!DOCTYPE html>
    <html>
      <head><title>Hello world!</title></head>
      <body><p id="phrase">Why not Zoidberg?</p></body>
    </html>
  HTML
}

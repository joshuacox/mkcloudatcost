  use HTML::TokeParser;
  $p = HTML::TokeParser->new(shift||"index.html");

  while (my $token = $p->get_tag("a")) {
      my $url = $token->[1]{href} || "-";
      my $text = $p->get_trimmed_text("/a");
      my $title = $token->[1]{title} || "-";
      #print "$url\t$text\n";
      print "$title\n";
  }


package App::TinyMVC::Handler;
  
use strict;
use warnings;
  
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

use App::TinyMVC;
use App::TinyMVC::UrlParser;
use App::TinyMVC::Controller::Index;
use App::TinyMVC::Controller::Test;
use Template;

{
	package App::TinyMVC;

	$App::TinyMVC::CONFDIR = '/home/smash/playground/App-TinyMVC/config';
}

sub handler {
	my $r = shift;

	my $parser = new App::TinyMVC::UrlParser($r);
	my $tinymvc = App::TinyMVC->new(
			controller => $parser->controller,
			action => $parser->action,
			args => [@{$parser->args}],
		);
	$r->content_type('text/html');
	my $output = $tinymvc->process;
	if ($output) {
		$r->print($output);
	}
	else {
		$r->print('something went wrong, redirect somewhere');
	}

	return Apache2::Const::OK;
}

1;


package App::TinyMVC::Controller::Test;

use warnings;
use strict;

sub new {
    my($class) = shift;
    my $self = bless({}, $class);

    return $self;
}

sub auto {
	my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::Test->auto");

	my $cache_id = $tinymvc->{'controller'}.$tinymvc->{'action'}.join '', @{$tinymvc->{'args'}};
	$tinymvc->log('cache', "cache id is: $cache_id\n");
	my $cache_type = App::TinyMVC::CACHE_VIEW;

	return($cache_id,$cache_type);
}

sub index {
    my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::Test->index");

	my $date = localtime;

	$tinymvc->stash('date', $date);
}

sub test {
    my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::Test->test");

	my $string = 'hello world';
	if (@{$tinymvc->args}) {
		$string = 'got '.join ' ', @{$tinymvc->args};
	}

	$tinymvc->stash('string', $string);
}

sub one {
    my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::Test->one");

	sleep 10;

	$tinymvc->stash('string', 'the one');
}

1;

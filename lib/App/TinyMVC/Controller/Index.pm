
package App::TinyMVC::Controller::Index;

use warnings;
use strict;

sub new {
    my($class) = shift;
    my $self = bless({}, $class);

    return $self;
}

sub auto {
	my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::Index->auto");

	my $cache_id = $tinymvc->{'controller'}.$tinymvc->{'action'}.join '', @{$tinymvc->{'args'}};
	$tinymvc->log('cache', "cache id is: $cache_id\n");
	my $cache_type = App::TinyMVC::CACHE_VIEW;

	return($cache_id,$cache_type);
}

sub index {
    my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::Index->view");

	my $date = localtime;

	$tinymvc->stash('date', $date);
}

1;

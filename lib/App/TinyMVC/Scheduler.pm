#!/usr/bin/perl

package App::TinyMVC::Scheduler;

use strict;
use warnings;

our $VERSION = '0.01_2';

use Cache::Memcached;

sub new {
	my($class) = @_;
	my $self = bless({}, $class);

	my $memd = new Cache::Memcached {
    		'servers' => [ "127.0.0.1:11211" ],
    		'debug' => 0,
    		'compress_threshold' => 10_000,
		};

	$self->{'memd'} = $memd;
	return $self;
}

sub workers {
	my($self,$tinymvc,$cache_id) = @_;

	$self->{'memd'}->get('app_tinymvc::'.$cache_id.'_working');
}

sub processing {
	my($self,$tinymvc,$cache_id) = @_;
	
	$self->{'memd'}->set('app_tinymvc::'.$cache_id.'_working', '1', 10);
}

sub finished {
    my($self,$tinymvc,$cache_id) = @_;

	$self->{'memd'}->delete('app_tinymvc::'.$cache_id.'_working');
}

1;

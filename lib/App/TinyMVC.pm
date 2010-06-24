
package App::TinyMVC;

use warnings;
use strict;

use constant {
    NO_CACHE   => -1,
    CACHE_VIEW => 0,
    CACHE_DATA => 1,
};

use App::TinyMVC::Cache;
use App::TinyMVC::Scheduler;
use App::TinyMVC::Controller::Template;

use YAML::AppConfig;
use Template;
use Template::Constants;
use File::Slurp qw/slurp/;
use Data::Dumper;

=head1 NAME

App::TinyMVC - A lightweight MVC framework for dynamic content

=head1 VERSION

Version 0.01_2

=cut

our $VERSION = '0.01_2';

=head1 SYNOPSIS

    use App::TinyMVC;

    my $tinymvc = new App::TinyMVC (
      controller => 'books',
      action => 'list',
      args => [@args],
      context => {
        params => {...},
        ...
      }
    );

    $tinymvc->process;

=head1 FUNCTIONS

=head2 new

Create a new App::TinyMVC object.

=cut

sub new {
	my ($class) = shift;
	my $self = { @_ };
	$self = bless($self, $class);

	# Set defaults
	$self->{'controller'} = 'index'						unless $self->{'controller'};
	$self->{'action'} = 'index'						unless $self->{'action'};
	$self->{'template'} = $self->{'controller'}.'/'.$self->{'action'}	unless $self->{'template'};
	$self->{'context'}->{'params'} = {}							unless $self->{'context'}->{'params'};
	$self->{'args'} = []						unless $self->{'args'};
	$self->{'siteEnclosure'} = 0						unless $self->{'siteEnclosure'};

	# Read config files
	my $confdir = '';
	if ($App::TinyMVC::CONFDIR) {
		$confdir = $App::TinyMVC::CONFDIR;
		unless ($confdir and $confdir =~ m/\/$/) {
			$confdir .= '/';
		}
	}
	$self->{'confdir'} = $confdir;

	$self->{'config'} = new YAML::AppConfig(file => $confdir."tinymvc.yaml")->config;

	$self->{'context'}->{'query_string'} = {}		unless ( $self->{'context'}->{'query_string'}->{'key'} and $self->{'context'}->{'query_string'}->{'key'} eq $self->{'config'}->{'query_string_key'} );
	$self->{'cache'} = undef;

	$self->log("info","controller: ".$self->{'controller'}." | action: ".$self->{'action'}." | args: ".(join ',',@{$self->{'args'}})." | template: ".$self->{'template'}." | siteEnclosure: ".$self->{'siteEnclosure'});
	$self->log('info', 'App::TinyMVC::new() ended..');

	return $self;
}

=head2 process

Process requested action from a controller.

=cut

sub process {
	my $self = shift;
	$self->log('info',"App::TinyMVC::process() entering..");

	my $output;
	my $cache = App::TinyMVC::Cache->new;
	my $scheduler = App::TinyMVC::Scheduler->new;

	# validate routes in request XXX

	#unless ($self->validate_routes) {
	#	return "ERRO";
	#}

	# create new controller instance
	my $contName = "App::TinyMVC::Controller::".ucfirst($self->controller);
	eval "use $contName";
	if ($@) {
		# build new controller module and eval
		my $controller_tt = Template->new();
		my $tt = App::TinyMVC::Controller::Template->dump;
		my $source = slurp($self->{'config'}->{'controllers'}->{'dir'}.'/'.$self->controller);
		my $functions = {};
		while ($source =~ /ACTION\s+(\w[\w\d\_]+)\s+(.*?)\s+RETURNS\s+(.*?);/gs) {
   		$functions->{$1}->{'source'} = $2;
   		$functions->{$1}->{'returns'} = [split /,/, $3];
		}
		my $vars = {
      		name => ucfirst $self->controller,
      		functions => $functions,
   		};
		my $code;
		$controller_tt->process(\$tt, $vars, \$code);
		eval $code;
	}
	my $controller = $contName->new; # XXX


	# let controller decide cache type and cache id
	# also let controller validate args if needed
	my($cache_id,$cache_type,$cache_expire) = $controller->auto($self);

	$self->log('info',"App::TinyMVC::process():  Controller said: cache_id: $cache_id, cache_type: $cache_type, cache_expire: ".(defined($cache_expire)?$cache_expire:"no-expire"));

	# schedule requests
	my $workers = $scheduler->workers($self, $cache_id);
	if ($workers) {
		my $waiting_for = 10;
		while ($scheduler->workers($self, $cache_id) and $waiting_for) {
			sleep 1 and $waiting_for--;
		}
	}
	else {
		# no workers, start processing
		$scheduler->processing($self, $cache_id);
	}

	# Can i use view cache ?
	if ($cache_type eq CACHE_VIEW and $cache_id) {

		# try to return cached view for request
		$output = $cache->get($self,$cache_type,$cache_id);
		if ( defined $output ) {
			$self->log('info',"App::TinyMVC::process():   Have cached view, returning..");
			$scheduler->finished($self, $cache_id);
			return $output;
		}
	}

	# Can i use data cache ?
	my $return = '';
	if ($cache_type eq CACHE_DATA and $cache_id) {
		$self->{'stash'} = $cache->get($self,$cache_type,$cache_id);
	}
	unless ($self->{'stash'}) {
		my $action = $self->action;

		# XXX run index if called from handler only
		# XXX or if we need to build entire site
		if ($self->{'siteEnclosure'} or $self->controller eq 'index') {
			my $zbr = App::TinyMVC::Controller::Index->new;
			$zbr->index($self);
		}

		# run action
		if ($action) {
	    		$return = $controller->$action($self);
		}
		else {
	    		$controller->index($self);
		}

		# store data cache
		if ($cache_type eq CACHE_DATA and $cache_id) {
			$cache->set($self,$cache_type,$cache_id,$self->{'stash'},$cache_expire);
		}
	}

	if ($return eq '404') {
		$scheduler->finished($self, $cache_id);
		return $return;
	}

	my $template_dir = $self->{'config'}->{'templates'}->{'dir'} || 'templates/App::TinyMVC';
	$self->log('info',"App::TinyMVC::process():   Using template dir: $template_dir");

	my $template = Template->new({
		CACHE_SIZE => 0,
		INCLUDE_PATH => $template_dir,
	});
	#if ($self->controller eq 'index') {
	#	$self->{'content'} = 'src/homepage';
	#}
	#$self->log('info','calling template '.$vars->{'template'});

	# handle stash and some needed stuff for templates
	my $vars = $self->{'stash'};
	if ($self->{'context'}) {
		$vars->{'context'} = $self->{'context'};
	}
	$vars->{'config'} = $self->{'config'};

	#$vars->{'make_url'} = 
	#	sub { 
	#		'/mspapp_handler/'.join '/', @_; # XXX
	#	};

	# process template and save output
	if($self->{'siteEnclosure'}) {
		$vars->{'template'} = $self->{'template'};
		$template->process('index', $vars, \$output);
	}
	else {
		$template->process($self->{'template'}, $vars, \$output);
	}

	# cache view before returning
	if ($cache_type eq CACHE_VIEW and $cache_id and $output) {
		$cache->set($self,$cache_type,$cache_id,$output,$cache_expire);
	}

	$self->log('info',"App::TinyMVC::process() leaving..");

	# return output to handler

	$scheduler->finished($self, $cache_id);
	$output;
}

=head2 validate_args

Validate arguments.

=cut

sub validate_args {
	my $self = shift;

	# check controller name
	my $found = grep {$self->{'controller'} eq $_} keys %{$self->{'config'}->{'controllers'}};
	unless ($found) {
		$self->log('error',"controller not found: ".$self->controller);
		return 0;
	}

	# check action name
	unless ($self->controller eq 'index') {
		$found = grep {$self->{'action'} eq $_} keys %{$self->{'config'}->{'controllers'}->{$self->{'controller'}}};
		unless ($found) {
			$self->log('error',"action not found for controller ".$self->controller.": ".$self->action);
			return 0;
		}
	}

	# check number of args
	unless ($self->{'config'}->{'controllers'}->{$self->controller}->{$self->action}->{'args'} == @{$self->args}) {
		$self->log('error',"invalid number of args for controller ".$self->controller." action ".$self->action." args: ".(join ',',@{$self->{'args'}}));
		return 0;
	}

	1;
}

=head2 log

Log information somewhere...

=cut

sub log {
	my($self,$level,$msg) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
	my $timestamp = sprintf("%s-%02d-%s %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);

	my $str = "[$timestamp] [".(uc $level)."] $msg";

	if ($self->{'config'}->{'log'}->{'enabled'}) {
		print STDERR "App::TinyMVC $str\n";
	}
}

=head2 controller

Returns requested controller.

=cut

sub controller {
	my $self = shift;

	$self->{'controller'}
}

=head2 action

Returns requested action.

=cut

sub action {
    my $self = shift;

    $self->{'action'}
}

=head2 args

Returns arguments given by request.

=cut

sub args {
    my $self = shift;

	$self->{'args'} = shift if @_;
    $self->{'args'};
}

=head2 sapo

Returns SAPO object.

=cut

sub sapo {
    my $self = shift;

	$self->{'context'}->{'sapo'};
}

=head2 stash

XXX

=cut

sub stash {
	my($self, $key, $value) = @_;

	if ($key and $value) {
		$self->{'stash'}->{$key} = $value;
	}
}

=head1 AUTHOR

Nuno Carvalho, C<< <smash at cpan.org> >>
David Oliveira, C<< <doliveira at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-tinymvc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-TinyMVC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::TinyMVC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-TinyMVC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-TinyMVC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-TinyMVC>

=item * Search CPAN

L<http://search.cpan.org/dist/App-TinyMVC>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Nuno Carvalho, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::TinyMVC

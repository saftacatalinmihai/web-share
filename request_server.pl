#!/usr/bin/env perl
#===============================================================================
#
#         FILE: request_server.pl
#
#        USAGE: ./request_server.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (),
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 12/14/2014 06:57:25 PM
#     REVISION: ---
#===============================================================================

use 5.14.1;
use strict;
use warnings;
use utf8;
use Mojolicious::Lite;

my $websocket_listeners = {};

sub send_listeners{
	my $msg = shift;
	for my $l (keys %$websocket_listeners) {
		$websocket_listeners->{$l}->send($msg);
	}
}

get '/' => 'index';

websocket '/listener/register' => sub {
	my $c = shift;

	# Remove inactivity timeout
	$c->inactivity_timeout(0);

  	# Opened
  	$c->app->log->debug('Client connected');

	my $id = "$c->tx";
	$websocket_listeners->{$id} = $c->tx;

	$c->on(message => sub {
			my ($c, $message) = @_;
			$c->app->log->debug("Recieved: $message");
			$c->send("pong") if $message eq 'ping';
		});

#	my $rid = Mojo::IOLoop->recurring(250 => sub {
#			$c->app->log->debug("ping $c->tx");
#			$c->tx->send('ping');
#		});

	$c->on(finish => sub {
			$c->app->log->debug("Client disconected");
			delete $websocket_listeners->{$id};
#			Mojo::IOLoop->remove($rid);
		});

};

get '/open' => sub {
		my $c = shift;
		send_listeners($c->param);
		$c->render(text => $c->param);
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
	<head><title>Echo</title></head>
	<body>
		<script>
		var ws = new WebSocket('<%= url_for('listenerregister')->to_abs %>');
		// Incoming messages
		ws.onmessage = function(event) {
			var data = event.data;
			if (data !== 'pong') {
				console.log(data);
				document.body.innerHTML += data + '<br/>';
				window.open("http://"+data,  "_blank");
			} else {
				console.log('pong recieved');
			}
		};
		window.setInterval(function () { ws.send('ping') }, 300000);
		</script>
	</body>
</html>

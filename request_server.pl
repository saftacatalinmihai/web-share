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

my $current_request = "";

get '/play/:song' => sub { 
	my $c = shift;
	my $search_string = $c->stash('song');
	$current_request = $search_string;
	$c->render(text => $current_request);
};

get '/' => sub {
	my $c = shift;
	$c->render(text => $current_request);
	$current_request = "";
};

app->start;


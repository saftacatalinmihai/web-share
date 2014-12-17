use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'request_server.pl',
	VERSION      => '1.0',
	AUTHOR       => 'Safta Catalin Mihai <saftacatalinmihai@gmail.com>',
	EXE_FILES    => ['request_server.pl'],
	PREREQ_PM    => {'Mojolicious' => '5.69'},
);

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME 			=> 'Mojoforum',
	ABSTRACT		=> 'Forum sofware',
	AUTHOR			=> 'Ivan Penchev',
	EXE_FILES		=> ['mojoforum'],
	PREREQ_PM		=> {
		'Mojolicious'		=> 1.1,
		'DBD::SQLite'	=> 0,
		'DateTime'		=> 0
	}
);

1;
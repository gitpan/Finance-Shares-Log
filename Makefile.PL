use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Finance::Shares::Log',
    'VERSION_FROM'	=> 'Log.pm',
    'PREREQ_PM'		=> { File::Spec => 0,
			     Date::Pcalc => 0 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Log.pm', # retrieve abstract from module
      AUTHOR     => 'Christopher Willmot <chris@willmot.org.uk') : ()),
);

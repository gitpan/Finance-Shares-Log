use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Finance::Shares::Log',
    'VERSION_FROM'	=> 'Log.pm',
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Log.pm', # retrieve abstract from module
      AUTHOR     => 'Christopher Willmot <chris@willmot.org.uk') : ()),
);


use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'publish messages and subscribe to topics',
  'AUTHOR' => 'Scott Beck <sabeck@cpan.org>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'English' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Black-Board',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Black::Board',
  'PREREQ_PM' => {
    'Moose' => '0',
    'Moose::Autobox' => '0',
    'Moose::Exporter' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::ClassAttribute' => '0',
    'MooseX::Clone' => '0',
    'MooseX::Declare' => '0',
    'MooseX::Params::Validate' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'Scalar::Util' => '0'
  },
  'VERSION' => '0.0001',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);




# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "Attribute::Handlers" => "0";
requires "Carp" => "0";
requires "DDP" => "0";
requires "Scalar::Util" => "0";
requires "Type::Params" => "0";
requires "Type::Tiny" => "1.012004";
requires "Types::Common::Numeric" => "0";
requires "Types::Common::String" => "0";
requires "Types::Standard" => "0";
requires "Variable::Magic" => "0";
requires "perl" => "v5.20.0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "PadWalker" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "lib" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Perl::Critic::Policy::Moose::ProhibitMultipleWiths" => "0";
  requires "Perl::Critic::Policy::Moose::RequireMakeImmutable" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "version" => "0.77";
};

package Cache::Reddit::Bleach;
use warnings;
use strict;

sub wash
{
  local $_ = unpack "b*", pop; tr/01/ \t/;$_
}

sub dry
{
  local $_ = pop; tr/ \t/01/; pack "b*", $_
}
1;

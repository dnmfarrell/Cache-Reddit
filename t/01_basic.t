use strict;
use warnings;
use Test::More;

use_ok 'Cache::Reddit';

SKIP: {
  skip 'missing environment variables: reddit_username, reddit_password and reddit_subreddit', 2
    unless $ENV{reddit_username} && $ENV{reddit_password} && $ENV{reddit_subreddit};

  my $data = { some => 'data' };
  ok my $id = set($data), 'set some data';
  is_deeply get($id), $data, 'check set data matches';
  ok remove($id), 'remove the cache entry';
};
done_testing;

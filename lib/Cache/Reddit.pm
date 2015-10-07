use strict;
use warnings;
package Cache::Reddit;
use Cache::Reddit::Bleach;

#ABSTRACT: a caching API that uses Reddit as the backend

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/get set remove/;
use Reddit::Client;

die 'Cache::Reddit requires the following environment variables: reddit_username, reddit_password and reddit_subreddit'
  unless $ENV{reddit_username} && $ENV{reddit_password} && $ENV{reddit_subreddit};

my $session_file = '~/.reddit';
my $reddit       = Reddit::Client->new(
    session_file => $session_file,
    user_agent   => 'Cache::Reddit/0.1',
);

use Storable ();

sub serialize { Storable::nfreeze($_[0]) }

sub deserialize { Storable::thaw($_[0]) }

sub authenticate
{
  unless ($reddit->is_logged_in) {
      $reddit->login($ENV{reddit_username}, $ENV{reddit_password});
      $reddit->save_session();
  }
}

=head1 DESCRIPTION

Cache::Reddit is a module for cacheing your application data on Reddit.
Data is serialized using L<Storable> and posted to a subreddit. The data
is posted as a text post, and the title of the post set to Cache::Reddit::
+ a random number.

The text is bleached before posting (converted to binary, C<tr/01/ \t/g>)
so it appears as whitespace on Reddit.

Due to the list-like search function, data retrieval performs at 0(n). However
deletion and insertion performs at 0(1).

It requires three environment variables to be set:

=over 4

=item * reddit_username - the reddit username to login with

=item * reddit_password - the reddit password to login with

=item * reddit_subreddit - the target subreddit to post data to

=back

=head1 SYNOPSIS

  use Cache::Reddit;

  my $id = set($data_ref);  # serialize data and post to subreddit
  my $data = get($id);      # retrieve the data back
  remove($id);              # delete the data from Reddit

=head1 EXPORTED FUNCTIONS

=head2 set($dataref)

Serializes and saves the data in the subreddit as a text post.
Returns the key for cached entry;

=cut

sub set
{
  my ($value) = @_;

  die 'set() only accepts references' unless $value && ref $value;

  authenticate();

  my $data = serialize($value);
  my $bleached_data = Cache::Reddit::Bleach::wash($data);

  $reddit->submit_text(
      subreddit => $ENV{reddit_subreddit},
      title     => 'Cache::Reddit::' . (int rand 100000),
      text      => $bleached_data,
  );
}

=head2 get ($key)

Deserializes and returns the cached entry.

=cut

sub get
{
  my $key = shift;

  die 'get() requires a key argument' unless $key;

  authenticate();

  my $data;

  for my $link ( @{$reddit->fetch_links(subreddit => $ENV{reddit_subreddit})->{items}} )
  {
    if ($link->{name} eq $key)
    {
      $data = $link->{selftext};
      last;
    }
  }
  deserialize(Cache::Reddit::Bleach::dry($data)) if $data;
}

=head2 remove ($key)

Deletes the item from the subreddit.

=cut

sub remove
{
  my $key = shift;
  die 'remove() requires a key argument' unless $key;

  authenticate();

  $reddit->delete_item(name => $key);
  1;
}

1;

package Twitter::Bot::Set;

use warnings;
use strict;
use Carp;

=head1 NAME

Twitter::Bot::Set - Session storage for watching a particular Twitter
  user's friends or followers list.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Utility data class used by C<Twitter::Bot>. Stores friends or
followers sets from the given user. When asked to check, rechecks that
user's friends [followers] set and reports those friends [or
followers] added and deleted.

B<THIS IS A UTILITY CLASS>. It is explicitly designed to be called
entirely within C<Twitter::Bot>; even subclasses of C<Twitter::Bot>
need not use this interface.

=head1 CLASS METHODS

=over

=item new()

Takes the following arguments as a k/v hash:

=cut

sub new {
  my $class = shift;
  my %args = @_;

=over

=item state

a hashref indicating current state. C<Twitter::Bot> initializes these
from MLDBM files on disk.

=cut

  croak "no state key defined to $class->new()"
    unless defined $args{state};
  croak "state key not a hashref"
    unless ref $args{state} eq 'HASH';

=item set

a hashref pointing to the set of current links. keys are userids,
values are actual userinfo.

=cut

  croak "no set key defined to $class->new"
    unless defined $args{set};
  croak "set key not a hashref"
    unless ref $args{set} eq 'HASH';

=item user

which user in the Twitter friends graph is being considered

=cut

  croak "no user key defined to $class->new"
    unless defined $args{user};

=item links

whether this is a set of C<friends> (outbound) or C<followers>
(inbound) links between C<user> and other twitterers.

=cut

  croak "no links key provided to $class->new"
    unless defined $args{links};
  croak "links arg not friends or followers"
    unless $args{links} eq 'friends' or $args{links} eq 'followers';

=item interval

A C<DateTime::Duration> object that indicates the minimum time between
checks; further calls to C<check> at less than C<interval> will
harmlessly no-op, allowing different networks to be checked in the
same script at different intervals.

=cut

  croak "no interval key provided to $class->new"
    unless defined $args{interval};
  croak "interval not a DateTime::Duration"
    unless UNIVERSAL::isa($args{interval}, 'DateTime::Duration');

=back

=cut

  my $self = bless \%args, $class;

  return $self;
}


=back

=head1 INSTANCE METHODS

=over

=item check()

Does nothing if interval since last check not yet passed.

Otherwise checks given C<twitter> object on the C<user> and C<links>
(value C<friends> or C<followers>) specified at initialization, and
returns two listrefs (added and removed) for the set.

=cut

sub check {
  my $self = shift;
  my $class = ref $self;
  my %args = @_;

  # this bit is identical with Twitter::Bot::Timeline -- refactor into
  # an ABC?
  my $now = DateTime->now();
  if (defined $self->{state}{last_checked}) {
    return
      if $now < $self->{state}{last_checked} + $self->{interval};
  }
  croak "no twitter arg defined to $class->check()"
    unless defined $args{twitter};
  croak "twitter arg doesn't seem to be a Net::Twitter object"
    unless UNIVERSAL::isa($args{twitter}, 'Net::Twitter');

  my $method = $self->{links};

  # TO DO: include since argument?
  my $results =
    $args{twitter}->$method({id => $self->{user}});

  # bail out now if there's a twitter problem. Don't want to
  # try to update until Twitter gives back data.
  if (not defined $results) {
    croak "trouble from twitter->$method: ", $args{twitter}->get_error();
  }

  $self->{state}{last_checked} = $now;


  # TO DO: if #links > 100, might not get whole list. revise to
  # re-call with page => 2 etc?  deal with it later, when popular
  # enough that friendslist is >100.


  # go through results. Look for new matches.
  my @added;
  my %curr;
  for my $curr (@$results) {
    my $curr_id = $curr->{id};
    $curr{$curr_id} = 1;
    next if $self->{set}{$curr_id};
    $self->{set}{$curr_id} = $curr;
    push @added, $curr;
  }

  # go through old values. Look for dropouts
  my @removed;
  for my $old_id (keys %{$self->{set}})  {
    next if $curr{$old_id};
    my $old = $self->{set}{$old_id};
    delete $self->{set}{$old_id};
    push @removed, $old;
  }
  return \@added, \@removed;
}

=back

=head1 AUTHOR

Jeremy G. KAHN, C<< <kahn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-twitter-bot-set at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Twitter-Bot>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Twitter::Bot

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Twitter-Bot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Twitter-Bot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Twitter-Bot>

=item * Search CPAN

L<http://search.cpan.org/dist/Twitter-Bot>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeremy G. KAHN.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Twitter::Bot::Set

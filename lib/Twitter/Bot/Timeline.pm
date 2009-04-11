package Twitter::Bot::Timeline;

use warnings;
use strict;
use Carp;

=head1 NAME

Twitter::Bot::Timeline - session storage for watching a particular
  Twitter timeline

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Utility data class used by C<Twitter::Bot>. Stores seen entries from
the given timeline.  When asked to check the timeline, uses an
(externally-provided) live C<Net::Twitter> object to check for new
status entries on that timeline; returns the new ones encountered.

B<THIS IS A UTILITY CLASS>. It is explicitly designed to be called
entirely within C<Twitter::Bot>; even subclasses of C<Twitter::Bot>
need not use this interface.

=head1 CLASS METHODS

=over

=item new()

Constructs a new (possibly revived) object.

=cut

sub new {
  my $class = shift;
  my %args = @_;

=pod

Given keys:

=over

=item state

hashref representing state (last-checked info, etc); C<Twitter::Bot>
uses a tied MLDBM hash to populate this

=cut

  croak "no state defined to $class"
    unless defined $args{state};
  croak "state key not a hashref"
    unless ref $args{state} eq 'HASH';

=item statuses

hashref representing statuses (id => status hashref); C<Twitter::Bot>
uses a tied MLDBM hash to populate this

=cut

  croak "no statuses defined to $class"
    unless defined $args{statuses};
  croak "statuses key not a hashref"
    unless ref $args{state} eq 'HASH';

=item timeline

which timeline to check (C<public_timeline>, C<friends_timeline>,
C<user_timeline>)

=cut

  croak "no timeline argument defined to $class"
    unless defined $args{timeline};

=item user

which C<user_timeline> (or C<friends_timeline>) to check (ignored on
C<public_timeline>)

=cut

  croak "no user argument defined to $class"
    unless defined $args{user};

=item interval

a C<DateTime::Duration> object specifying minimum time between checks.

=cut

  croak "no interval defined to $class"
    unless defined $args{interval};

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

Otherwise checks given C<twitter> object on the user/timeline
specified at initialization, and returns C<status> hashrefs not
previously seen.

=cut

sub check {
  my $self = shift;
  my $class = ref $self;
  my %args = @_;

  my $now = DateTime->now();
  if (defined $self->{state}{last_checked}) {
    return
      if $now < $self->{state}{last_checked} + $self->{interval};
  }

  croak "no twitter arg defined to $class->check()"
    unless defined $args{twitter};
  croak "twitter arg doesn't seem to be a Net::Twitter object"
    unless UNIVERSAL::isa($args{twitter}, 'Net::Twitter');

  my $method = $self->{timeline};

  # TO DO: include since argument? or since_id? Twitter-end lag might
  # mean we miss some with since_id
  my $results =
    $args{twitter}->$method({user => $self->{user}, count => 200});

  if (not defined $results) {
    croak "trouble from twitter->$method: ", $args{twitter}->get_error();
  }

  $self->{state}{last_checked} = $now;


  # TO DO: retrieve more $results if count too large?  deal with it
  # later when traffic is heavy.

  # go through new statuses and discard those previously seen.
  my @new = grep { not $self->{statuses}{$_->{id}} } @$results;

  for my $status (@new) {
    $self->{statuses}{$status->{id}} = $status;
  }

  return \@new;
} # end check()

=back

=head1 AUTHOR

Jeremy G. KAHN, C<< <kahn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-twitter-bot-timeline at rt.cpan.org>, or through the web
interface at
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

Copyright 2009 Jeremy G. KAHN, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Twitter::Bot::Timeline

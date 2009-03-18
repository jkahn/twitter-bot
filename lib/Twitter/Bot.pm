package Twitter::Bot;

use warnings;
use strict;
use Carp;

=head1 NAME

Twitter::Bot - abstraction for a twitterbot. Subclasses are actual bots

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Other twitterbot classes can inherit from this class, register certain
methods as callbacks and have those methods invoked when certain
twitterish activities occur, e.g. a friend's status updates, the bot
receives a direct_message, or a new follower appears.

  ## in MyBotClass.pm
  use strict; use warnings;
  use base 'Twitter::Bot';
  sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);
    $self->timeline_callback(timeline => 'friends_timeline',
                             interval => {minutes => 5},
                             callback => 'handle_friends_update',
                             );
    $self->links_callback(links => 'inbound',
                          interval => {minutes => 60},
                          callback => 'handle_new_follower',
                         );
    return $self;
  }
  # ...
  sub handle_friends_update {
    my $self = shift; my $update = shift;
    # ....
  }
  sub handle_new_follower {
    my $self = shift; my $new_follower = shift;
    # ...  e.g. use the $self->twitter() Net::Twitter object to
    # auto-add the follower.
  }
  1;  # end of packagefile

then in a script (probably called from C<cron> every few minutes):

  #!perl
  use strict; use warnings;
  use MyBotClass;
  # ...
  my $bot = MyBotClass->new(password => $password,
                            username => $username);
  eval { $bot->check(); };

  if ($@) {
    die "problems with mybotclass: $@\n";
  }
  exit 0;

That's "all". The C<Twitter::Bot> base class handles the construction
of offline storage so that the C<$bot> only handles new information,
whether on a timeline or a link-set.

If no callbacks have been registered with the instance, C<check> will
C<carp>.

=head1 CLASS METHODS

=over

=item new()

=cut

sub new {
  my $class = shift;
  my %args = @_;


=pod

arguments for C<new> include the following mandatory keys:

=over

=item username

the username with which to log into the Twitter service.

=cut

  croak "no username key provided" unless defined $args{username};
  my $username = $args{username};
  delete $args{username};
  $args{__PACKAGE__ . "_username"} = $username;

=item password

The password with which to log into the Twitter service.

=cut

  croak "no password key provided" unless defined $args{password};
  my $password = $args{password};  delete $args{password};

=item directory

The directory in which to store state and memory files for the
bot. Must exist; the bot will write new files into that directory. At
first run, should probably be empty but this class does not check
that.

=cut

  croak "no directory key provided" unless defined $args{directory};
  croak "directory => $args{directory} not a readable, writable directory"
    unless -d $args{directory}
      and -w $args{directory} and -r $args{directory};
  $args{__PACKAGE__ . "_directory"} = $args{directory};
  delete $args{directory};

=back

=cut

  my $twitter =
    Net::Twitter->new(username => $username, password => $password);
  croak "something went wrong with twitter initialization"
    unless defined $twitter;
  $args{__PACKAGE__ . "_twitter"} = $twitter;

  my $self = bless \%args, $class;

  # all done with new()
  return $self;

} # end new()

=back

=head1 INITIALIZATION INSTANCE METHODS

Intended to be called on C<new()> initialization of the subclass. (see
the L</SYNOPSIS>.) You can modify them over the lifetime of the
object, but the design here works -- and is tested -- with invocation
at initialization.

=over

=item timeline_callback()

arguments for C<timeline_callback> include:

=over

=item timeline

=item user

=item interval

=item callback_method

=item callback_args

=back

=item links_callback()

arguments for C<links_callback> include:

=over

=item links

=item user

=item interval

=item callback_method

=item callback_args

=back

=back

=head1 INSTANCE METHODS

=over

=item check()

=item twitter()

=item username()

=item directory()

=back

=head1 AUTHOR

Jeremy G. KAHN, C<< <kahn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-twitter-bot at
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

The C<Net::Twitter> developers; C<Net::Twitter> provides a natural
Perlish interface to the Twitter API.

=head1 SEE ALSO

=over

=item L<Net::Twitter>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeremy G. KAHN.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Twitter::Bot

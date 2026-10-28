use v5.36;

package DBIx::Squirrel;

use experimental qw(try);

use Carp      qw(croak);
use DBI       qw();
use Ref::Util qw(is_coderef is_hashref);

use DBIx::Squirrel::Stop qw();

our @ISA     = 'DBI';
our $VERSION = 'v2.0.0';

# Return the handle of the connection to the requested data source.
sub connect ($class, @args) {
    return _connect_dbh($class, @args)
        if @args && $args[0] isa 'DBI::db';

    my($source, $username, $password) = splice @args, 0, 3;

    my $attrs = @args && is_hashref($args[0]) ? shift @args : {};

    my $dbh = $class->SUPER::connect(
        $source,
        $username,
        $password, {
            %$attrs,
            RootClass => ref($class) || $class,
        },
    );

    croak $DBI::errstr unless $dbh;

    return $dbh;
}

# Return the handle of a new connection using the same parameters as
# another connection.
sub _connect_dbh ($class, $dbh, @args) {
    my $attrs = @args && is_hashref($args[0]) ? shift @args : {};

    $dbh = $dbh->clone({
        %$attrs,
        RootClass => ref($class) || $class,
    });

    croak $DBI::errstr unless $dbh;

    return $dbh;
}


# Run a queue of closures against $self for their side-effects.
sub tap ($self, @stages) {
    my @queue = _pairs_of_named_stages(\@stages)->@*;
    while (@queue) {
        my($id, $stage) = splice @queue, 0, 2;
        try { $stage->($self) }
        catch ($e) {
            last if $e isa 'DBIx::Squirrel::Stop';
            croak "A tap stage ($id) failed: $e";
        }
    }
    return $self;
}

# Return a list of closures as a list of pairs of named closures.
sub _pairs_of_named_stages ($stages = []) {
    my @stages = @$stages;
    my @pairs;
    my $pos = 0;
    while (@stages) {
        my $next = shift @stages;
        $pos += 1;
        if (is_coderef($next)) {
            push @pairs, ("#$pos" => $next);
            next;
        }
        croak "Expected a code-reference or non-reference" if ref $next;
        croak "Expected a code-reference to follow a non-reference"
            unless @stages && is_coderef($stages[0]);
        push @pairs, ((length($next) ? "#$pos: $next" : "#$pos") => shift @stages);
    }
    return \@pairs;
}

sub Stop (@) { return DBIx::Squirrel::Stop::->throw() }

1;

__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel - DBI, minus the boilerplate, plus a pipeline

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut

=pod

=encoding utf-8

=head1 PURPOSE

Test that this sort of thing works:

   sub foo :ReturnType(Int) {
      ...;
   }

=head1 DEPENDENCIES

Requires L<Return::Type>; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	plan skip_all => "Test case fails with App::ForkProve"
		if exists $INC{"App/ForkProve.pm"};
};

use Test::Requires 'Return::Type';
use Types::Standard qw( HashRef Int );
use Test::Fatal;

if (0)
{
	require JSON;
	diag("\%ENV ".JSON->new->pretty(1)->canonical(1)->encode({%ENV}));
	diag("\%INC ".JSON->new->pretty(1)->canonical(1)->encode({%INC}));
}

sub foo :ReturnType(Int) {
	wantarray ? @_ : $_[0];
}

subtest "simple return type constraint" => sub
{
	subtest "scalar context" => sub
	{
		is( scalar(foo(42)), 42 );
		
		like(
			exception { scalar(foo(4.2)) },
			qr/^Value "4.2" did not pass type constraint "Int"/,
		);
		
		done_testing;
	};
	
	subtest "list context" => sub
	{
		is_deeply( [ foo(4, 2) ], [4, 2] );
		
		like(
			exception { [ foo(4, 2, 4.2) ] },
			qr/^Reference \[.+?\] did not pass type constraint "ArrayRef\[Int\]"/,
		);
		
		done_testing;
	};
	
	done_testing;
};

my $Even;
BEGIN {
	$Even = Int->create_child_type(
		name       => 'Even',
		constraint => sub { not($_[0] % 2) },
	);
};

sub bar :ReturnType(scalar => $Even, list => HashRef[Int]) {
	wantarray ? @_ : scalar(@_);
}

subtest "more complex return type constraint" => sub
{
	subtest "scalar context" => sub
	{
		is(
			scalar(bar(xxx => 1, yyy => 2)),
			4,
		);
		
		TODO: {
			local $TODO = 'this seems to fail: error in Return::Type??';
			
			like(
				exception { scalar(bar(xxx => 1, 2)) },
				qr/^Value "3" did not pass type constraint "Even"/,
			);
		}
		
		done_testing;
	};
	
	subtest "list context" => sub
	{
		is_deeply(
			[ bar(xxx => 1, yyy => 2) ],
			[ xxx => 1, yyy => 2 ],
		);
		
		like(
			exception { [ bar(xxx => 1, 2) ] },
			qr/^Odd number of elements in anonymous hash/,
		);
		
		done_testing;
	};
	
	done_testing;
};

done_testing;
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

use_ok( 'Black::Board::Message' );
use_ok( 'Black::Board::Publisher' );
use_ok( 'Black::Board::Subscriber' );
use_ok( 'Black::Board::Topic' );
use_ok( 'Black::Board::Trait::Traversable' );
use_ok( 'Black::Board::Types' );
use_ok( 'Black::Board' );

1;


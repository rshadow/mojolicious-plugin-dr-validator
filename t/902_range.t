#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 19;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::DR::Validator';
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('DR::I18n');
        $self->plugin('DR::Validator');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'range';
{
    $t->app->routes->post("/test/range")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        my $min = 100;
        my $max = 200;

        ok $v->required('range0')->range($min, $max), 'range0 валидация';
        ok $v->has_error('range0'),                   'range0 ошибка';
        is $v->param('range0'), undef,                'range0 пустая строка';

        ok $v->required('range1')->range($min, $max), 'range1 валидация';
        ok $v->has_error('range1'),                   'range1 ошибка';
        is $v->param('range1'), undef,                'range1 значение меньше';

        ok $v->required('range2')->range($min, $max), 'range2 валидация';
        ok ! $v->has_error('range2'),                 'range2 ошибки нет';
        is $v->param('range2'), 110,                  'range2 значение внутри';

        ok $v->required('range3')->range($min, $max), 'range3 валидация';
        ok $v->has_error('range3'),                   'range3 ошибка';
        is $v->param('range3'), undef,                'range3 значение больше';

        ok $v->required('range4')->range($min, $max), 'range4 валидация';
        ok $v->has_error('range4'),                   'range4 ошибка';
        is $v->param('range4'), undef,                'range4 буквы не сравнимы';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/range", form => {
        range0    => '',
        range1    => '10',
        range2    => '110',
        range3    => '210',
        range4    => 'aaa',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut


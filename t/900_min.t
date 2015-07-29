#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 16;
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

note 'min';
{
    $t->app->routes->post("/test/min")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        my $min = 100;

        ok $v->required('min0')->min($min),         'min0 валидация';
        ok $v->has_error('min0'),                   'min0 ошибка';
        is $v->param('min0'), undef,                'min0 пустая строка';

        ok $v->required('min1')->min($min),         'min1 валидация';
        ok $v->has_error('min1'),                   'min1 ошибка';
        is $v->param('min1'), undef,                'min1 значение меньше';

        ok $v->required('min2')->min($min),         'min2 валидация';
        ok ! $v->has_error('min2'),                 'min2 ошибки нет';
        is $v->param('min2'), 110,                  'min2 значение больше';

        ok $v->required('min3')->min($min),         'min3 валидация';
        ok $v->has_error('min3'),                   'min3 ошибка';
        is $v->param('min3'), undef,                'min3 буквы не сравнимы';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/min", form => {
        min0    => '',
        min1    => '10',
        min2    => '110',
        min3    => 'aaa',
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


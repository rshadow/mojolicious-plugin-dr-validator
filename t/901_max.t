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

note 'max';
{
    $t->app->routes->post("/test/max")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        my $max = 100;

        ok $v->required('max0')->max($max),         'max0 валидация';
        ok $v->has_error('max0'),                   'max0 ошибка';
        is $v->param('max0'), undef,                'max0 пустая строка';

        ok $v->required('max1')->max($max),         'max1 валидация';
        ok ! $v->has_error('max1'),                 'max1 ошибки нет';
        is $v->param('max1'), 10,                   'max1 значение меньше';

        ok $v->required('max2')->max($max),         'max2 валидация';
        ok $v->has_error('max2'),                   'max2 ошибка';
        is $v->param('max2'), undef,                'max2 значение больше';

        ok $v->required('max3')->max($max),         'max3 валидация';
        ok $v->has_error('max3'),                   'max3 ошибка';
        is $v->param('max3'), undef,                'max3 буквы не сравнимы';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/max", form => {
        max0    => '',
        max1    => '10',
        max2    => '110',
        max3    => 'aaa',
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


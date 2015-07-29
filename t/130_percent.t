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

note 'percent';
{
    $t->app->routes->post("/test/percent")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('percent0')->percent,   'percent0 валидация';
        ok ! $v->has_error('percent0'),         'percent0 ошибки нет';
        is $v->param('percent0'), 0,            'percent0 значение 0';

        ok $v->required('percent1')->percent,   'percent1 валидация';
        ok ! $v->has_error('percent1'),         'percent1 ошибки нет';
        is $v->param('percent1'), 100,          'percent1 значение 100';

        ok $v->required('percent2')->percent,   'percent2 валидация';
        ok ! $v->has_error('percent2'),         'percent2 ошибки нет';
        is $v->param('percent2'), 55.66,        'percent2 значение дробное';

        ok $v->required('percent3')->percent,   'percent3 валидация';
        ok $v->has_error('percent3'),           'percent3 ошибка';
        is $v->param('percent3'), undef,        'percent3 значение меньше 0';

        ok $v->required('percent4')->percent,   'percent4 валидация';
        ok $v->has_error('percent4'),           'percent4 ошибка';
        is $v->param('percent4'), undef,        'percent4 значение больше 100';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/percent", form => {

        # numeric не проверяем

        percent0    => 0,
        percent1    => 100,
        percent2    => 55.66,
        percent3    => -1,
        percent4    => 101,
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


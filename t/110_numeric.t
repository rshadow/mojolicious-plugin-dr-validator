#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 31;
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

note 'numeric';
{
    $t->app->routes->post("/test/numeric")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('numeric0')->numeric,   'numeric0 валидация';
        ok ! $v->has_error('numeric0'),         'numeric0 ошибки нет';
        is $v->param('numeric0'), 0,            'numeric0 значение 0';

        ok $v->required('numeric1')->numeric,   'numeric1 валидация';
        ok ! $v->has_error('numeric1'),         'numeric1 ошибки нет';
        is $v->param('numeric1'), 111.222,      'numeric1 дробное значение';

        ok $v->required('numeric2')->numeric,   'numeric2 валидация';
        ok ! $v->has_error('numeric2'),         'numeric2 ошибки нет';
        is $v->param('numeric2'), 222,          'numeric2 строка с числом';

        ok $v->required('numeric3')->numeric,   'numeric3 валидация';
        ok ! $v->has_error('numeric3'),         'numeric3 ошибки нет';
        is $v->param('numeric3'), 333.444,      'numeric3 строка с дробью';

        ok $v->required('numeric4')->numeric,   'numeric4 валидация';
        ok $v->has_error('numeric4'),           'numeric4 ошибка';
        is $v->param('numeric4'), undef,        'numeric4 строка без чисел';

        ok $v->required('numeric5')->numeric,   'numeric5 валидация';
        ok $v->has_error('numeric5'),           'numeric5 ошибка';
        is $v->param('numeric5'), undef,        'numeric5 пустая строка';

        ok $v->required('numeric6')->numeric,   'numeric6 валидация';
        ok ! $v->has_error('numeric6'),         'numeric6 ошибки нет';
        is $v->param('numeric6'), 333,          'numeric6 без дробной части';

        ok $v->required('numeric7')->numeric,   'numeric7 валидация';
        ok ! $v->has_error('numeric7'),         'numeric7 ошибки нет';
        is $v->param('numeric7'), -333.444,     'numeric7 отрицательная дробь';

        ok $v->required('numeric8')->numeric,   'numeric8 валидация';
        ok ! $v->has_error('numeric8'),         'numeric8 ошибки нет';
        is $v->param('numeric8'), 333.444,      'numeric8 положительная дробь';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/numeric", form => {

        numeric0    => 0,
        numeric1    => 111.222,
        numeric2    => '222aaa',
        numeric3    => 'bbb333.444bbb',
        numeric4    => 'ccc',
        numeric5    => '',
        numeric6    => ' 333. ',
        numeric7    => ' -333.444 ',
        numeric8    => ' +333.444 ',
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

